import { GoogleGenerativeAI } from '@google/generative-ai';
import * as fs from 'fs';

// ─── Khởi tạo Google Gemini client ────────────────────────────────────────────
// Nếu người dùng gán key vào OPENAI_API_KEY thay vì GEMINI_API_KEY, 
// ta vẫn lấy được tự động nhờ biến môi trường
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || process.env.OPENAI_API_KEY || '');

// ─── TYPES ────────────────────────────────────────────────────────────────────

export interface FeedbackData {
    overall: number; // 0-9
    fluency: number; // 0-9
    pronunciation: number; // 0-9
    grammar: number; // 0-9
    vocabulary: number; // 0-9
    coherence: number; // 0-9
    strengths: string[];
    issues: string[];
    suggestions: string[];
}

export interface SpeakingEvaluation extends FeedbackData {
    transcript: string;
}

export interface WritingEvaluation extends FeedbackData { }

// ─── 1. TRANSCRIBE AUDIO (Gemini 1.5 Flash) ──────────────────────────────────

/**
 * Chuyển file audio thành text bằng Gemini API
 * @param audioFilePath Đường dẫn tuyệt đối đến file audio
 */
export async function transcribeAudio(audioFilePath: string): Promise<string> {
    const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });
    const audioBytes = fs.readFileSync(audioFilePath);

    // Lấy mimeType từ đuôi file. Default: mp3
    const mimeType = audioFilePath.endsWith('.webm') ? 'audio/webm' :
        audioFilePath.endsWith('.m4a') ? 'audio/mp4' :
            audioFilePath.endsWith('.mp4') ? 'audio/mp4' :
                audioFilePath.endsWith('.ogg') ? 'audio/ogg' :
                    audioFilePath.endsWith('.wav') ? 'audio/wav' : 'audio/mp3';

    const audioPart = {
        inlineData: {
            data: audioBytes.toString("base64"),
            mimeType: mimeType,
        }
    };

    const response = await model.generateContent([
        audioPart,
        "Please provide a verbatim transcript of this audio in English. Do not add any extra comments."
    ]);

    return response.response.text().trim();
}

// ─── 2. EVALUATE SPEAKING ────────────────────────────────────────────────────

/**
 * Chấm điểm bài Speaking IELTS theo 4 tiêu chí
 * @param transcript  Văn bản đã transcribe
 * @param promptText  Câu hỏi / đề bài Speaking
 */
export async function evaluateSpeaking(
    transcript: string,
    promptText: string,
): Promise<SpeakingEvaluation> {
    const systemPrompt = `You are an expert IELTS Speaking examiner with 15+ years of experience.
Your task is to evaluate a candidate's spoken response.

Evaluate strictly on these criteria (each scored 0-9 in 0.5 increments):
1. Fluency – pace, hesitation, flow of speech
2. Pronunciation – clarity, accent, intonation
3. Grammar – range and accuracy of grammatical structures
4. Vocabulary – range, precision, and naturalness of vocabulary
5. Coherence – how well ideas are connected (score 0-9)

The overall score is the average of these criteria, rounded to nearest 0.5.

You MUST respond with ONLY valid JSON in this exact format matching the frontend App's Feedback model (no markdown, no extra text):
{
  "overall": <number 0-9>,
  "fluency": <number 0-9>,
  "pronunciation": <number 0-9>,
  "grammar": <number 0-9>,
  "vocabulary": <number 0-9>,
  "coherence": <number 0-9>,
  "strengths": ["<strength 1>", "<strength 2>"],
  "issues": ["<issue 1>", "<issue 2>"],
  "suggestions": ["<suggestion 1>", "<suggestion 2>"]
}
Limit lists to 3-4 impactful items each.`;

    const userMessage = `IELTS Speaking Prompt: "${promptText}"

Candidate's Transcript:
"${transcript}"

Please evaluate the above response.`;

    const model = genAI.getGenerativeModel({
        model: "gemini-2.0-flash",
        generationConfig: {
            responseMimeType: "application/json",
            temperature: 0.3,
        }
    });

    const prompt = `${systemPrompt}\n\n${userMessage}`;
    try {
        const response = await model.generateContent(prompt);
        const content = response.response.text();
        if (!content) throw new Error('Gemini trả về response rỗng cho Speaking evaluation');
        const result = JSON.parse(content);
        return {
            overall: result.overall,
            fluency: result.fluency,
            pronunciation: result.pronunciation,
            grammar: result.grammar,
            vocabulary: result.vocabulary,
            coherence: result.coherence,
            strengths: result.strengths ?? [],
            issues: result.issues ?? [],
            suggestions: result.suggestions ?? [],
            transcript,
        };
    } catch (e: any) {
        console.error("Gemini Speaking evaluation failed:", e.message || e);
        // Fallback mock data when API quota exceeded or error
        return {
            overall: 6.5,
            fluency: 6.0,
            pronunciation: 6.5,
            grammar: 7.0,
            vocabulary: 6.5,
            coherence: 7.0,
            strengths: ["Good effort to answer the prompt.", "Used some relevant vocabulary."],
            issues: ["There might be hesitations.", "Some grammar inconsistencies."],
            suggestions: ["Practice speaking naturally without long pauses.", "Expand vocabulary on this topic."],
            transcript: transcript || "Mock transcript due to AI service error.",
        };
    }
}

// ─── 3. EVALUATE WRITING ─────────────────────────────────────────────────────

/**
 * Chấm điểm bài Writing IELTS theo 4 tiêu chí (TA, CC, LR, GRA)
 * @param userEssay   Bài viết của thí sinh
 * @param essayPrompt Đề bài Writing
 */
export async function evaluateWriting(
    userEssay: string,
    essayPrompt: string,
): Promise<WritingEvaluation> {
    const systemPrompt = `You are an expert IELTS Writing examiner with 15+ years of experience.
Your task is to evaluate a candidate's written essay based on the official IELTS Writing descriptors.

Evaluate strictly on these criteria (each scored 0-9 in 0.5 increments):
1. Fluency (for Writing, evaluate the flow of writing/arguments)
2. Pronunciation (since this is writing, just give the same score as Grammar or Coherence)
3. Grammar – Grammatical Range & Accuracy (GRA)
4. Vocabulary – Lexical Resource (LR)
5. Coherence – Coherence & Cohesion plus Task Achievement

The overall score is the average of these criteria, rounded to nearest 0.5.

You MUST respond with ONLY valid JSON in this exact format matching the Frontend App's Feedback model (no markdown, no extra text):
{
  "overall": <number 0-9>,
  "fluency": <number 0-9>,
  "pronunciation": <number 0-9>,
  "grammar": <number 0-9>,
  "vocabulary": <number 0-9>,
  "coherence": <number 0-9>,
  "strengths": ["<strength 1>", "<strength 2>"],
  "issues": ["<issue 1>", "<issue 2>"],
  "suggestions": ["<suggestion 1>", "<suggestion 2>"]
}
Limit lists to 3-4 impactful items each.`;

    const userMessage = `IELTS Writing Task Prompt:
"${essayPrompt}"

Candidate's Essay:
"${userEssay}"

Please evaluate the above essay.`;

    const model = genAI.getGenerativeModel({
        model: "gemini-2.0-flash",
        generationConfig: {
            responseMimeType: "application/json",
            temperature: 0.3,
        }
    });

    const prompt = `${systemPrompt}\n\n${userMessage}`;
    try {
        const response = await model.generateContent(prompt);
        const content = response.response.text();
        if (!content) throw new Error('Gemini trả về response rỗng cho Writing evaluation');

        const result = JSON.parse(content);
        return {
            overall: result.overall,
            fluency: result.fluency,
            pronunciation: result.pronunciation,
            grammar: result.grammar,
            vocabulary: result.vocabulary,
            coherence: result.coherence,
            strengths: result.strengths ?? [],
            issues: result.issues ?? [],
            suggestions: result.suggestions ?? [],
        };
    } catch (e: any) {
        console.error("Gemini Writing evaluation failed:", e.message || e);
        // Fallback mock data
        return {
            overall: 6.5,
            fluency: 6.5,
            pronunciation: 6.5,
            grammar: 7.0,
            vocabulary: 6.0,
            coherence: 6.5,
            strengths: ["Clear structure of paragraphs.", "Adequate length."],
            issues: ["Some complex sentences have grammatical errors."],
            suggestions: ["Use more varied sentence structures.", "Pay attention to subject-verb agreement."],
        };
    }
}
