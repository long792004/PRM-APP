import { GoogleGenerativeAI } from '@google/generative-ai';
import * as fs from 'fs';

// ─── Khởi tạo Google Gemini client ────────────────────────────────────────────
// Nếu người dùng gán key vào OPENAI_API_KEY thay vì GEMINI_API_KEY, 
// ta vẫn lấy được tự động nhờ biến môi trường
const apiKey = process.env.GEMINI_API_KEY || process.env.OPENAI_API_KEY;
if (!apiKey) {
    console.error('❌ Error: GEMINI_API_KEY or OPENAI_API_KEY is not defined in environment variables.');
    // Don't exit immediately, but the service will fail when called
}

const genAI = new GoogleGenerativeAI(apiKey || '');

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

// ─── 1. EVALUATE SPEAKING WITH AUDIO (Gemini 2.5 Flash) ────────────────────

/**
 * Chấm điểm bài Speaking IELTS trực tiếp từ file audio (Multimodal)
 * @param audioFilePath Đường dẫn tuyệt đối đến file audio
 * @param promptText    Câu hỏi / đề bài Speaking
 */
export async function evaluateSpeakingWithAudio(
    audioFilePath: string,
    promptText: string,
): Promise<SpeakingEvaluation> {
    const model = genAI.getGenerativeModel({ 
        model: "gemini-2.5-flash",
        generationConfig: {
            responseMimeType: "application/json",
            temperature: 0.2,
        }
    });

    const audioBytes = fs.readFileSync(audioFilePath);
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

    const systemPrompt = `You are an expert IELTS Speaking examiner.
Evaluate the candidate's spoken response based on the audio provided.

Evaluate strictly on these criteria (each scored 0-9 in 0.5 increments):
1. Fluency – pace, hesitation, flow of speech
2. Pronunciation – Is the pronunciation standard, clear, and accurate? (cách phát âm có chuẩn không)
3. Grammar – Are the grammatical structures correct? Pay strict attention to grammatical errors. (ngữ pháp đúng chưa)
4. Vocabulary – Is the vocabulary used grammatically correct in context? (từ vựng sử dụng đã đúng với ngữ pháp chưa)
5. Coherence – how well ideas are connected

CRITICAL INSTRUCTION: Be extremely strict. If the audio is very short, off-topic, or nonsensical, you MUST give a very low score (0 to 3) across all criteria. Do NOT give a default or middle score like 6.0 for poor, meaningless, or extremely short responses.

The overall score is the average of these criteria, rounded to nearest 0.5.

You MUST respond with ONLY valid JSON in this exact format:
{
  "transcript": "<verbatim transcription of the audio>",
  "overall": <number 0-9>,
  "fluency": <number 0-9>,
  "pronunciation": <number 0-9>,
  "grammar": <number 0-9>,
  "vocabulary": <number 0-9>,
  "coherence": <number 0-9>,
  "strengths": ["<strength 1>", "<strength 2>"],
  "issues": ["<issue 1>", "<issue 2>"],
  "suggestions": ["<suggestion 1>", "<suggestion 2>"]
}`;

    const userMessage = `IELTS Speaking Prompt: "${promptText}"
Please transcribe and evaluate the attached audio.`;

    try {
        const response = await model.generateContent([
            audioPart,
            `${systemPrompt}\n\n${userMessage}`
        ]);
        const content = response.response.text();
        if (!content) throw new Error('Gemini returned empty response for Speaking evaluation');
        
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
            transcript: result.transcript || "Transcription not available",
        };
    } catch (e: any) {
        console.error("Gemini Speaking evaluation failed:", e.message || e);
        throw new Error("API call failed: " + (e.message || "Unknown error"));
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
        model: "gemini-2.5-flash",
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
        throw new Error("API call failed: " + (e.message || "Unknown error"));
    }
}
