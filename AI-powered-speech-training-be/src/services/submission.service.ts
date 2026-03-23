import prisma from '../utils/prisma';
import * as AiService from './ai.service';
import * as fs from 'fs';

// ─── SPEAKING ─────────────────────────────────────────────────────────────────

export interface SpeakingSubmitInput {
    userId: string;
    questionId: string;
    audioFilePath: string; // đường dẫn file tạm từ multer
    audioUrl: string;      // URL public để FE phát lại
}

export async function submitSpeaking(input: SpeakingSubmitInput) {
    const { userId, questionId, audioFilePath, audioUrl } = input;

    // Lấy question để biết prompt
    const question = await prisma.question.findUnique({
        where: { id: questionId },
        include: { section: { include: { exam: true } } },
    });
    if (!question) throw new Error('Câu hỏi không tồn tại');

    try {
        // Combined AI Call: audio → transcript + evaluation
        const evaluation = await AiService.evaluateSpeakingWithAudio(
            audioFilePath,
            question.questionText,
        );

        // 3. Tìm hoặc tạo Submission cho exam này
        let submission = await prisma.submission.findFirst({
            where: { userId, examId: question.section.examId },
        });
        if (!submission) {
            submission = await prisma.submission.create({
                data: { userId, examId: question.section.examId },
            });
        } else {
            // Update timestamp to bring to top of history
            await prisma.submission.update({
                where: { id: submission.id },
                // @ts-ignore
                data: { updatedAt: new Date() }
            });
        }

        // 4. Tạo AnswerDetail
        // Lấy submission update time để đồng bộ FE
        const answerDetail = await prisma.answerDetail.create({
            include: { submission: true },
            data: {
                submissionId: submission.id,
                questionId,
                userAnswer: evaluation.transcript,
                audioUrl,
                isCorrect: null, // Speaking không có đúng/sai tuyệt đối
            },
        });

        // 5. Lưu AiEvaluation
        const aiEval = await prisma.aiEvaluation.create({
            data: {
                answerDetailId: answerDetail.id,
                bandScore: evaluation.overall,
                criteriaScores: {
                    fluency: evaluation.fluency,
                    pronunciation: evaluation.pronunciation,
                    grammar: evaluation.grammar,
                    vocabulary: evaluation.vocabulary,
                    coherence: evaluation.coherence,
                },
                feedback: JSON.stringify(evaluation.strengths), // Tạm lưu strengths
                corrections: {
                    issues: evaluation.issues,
                    suggestions: evaluation.suggestions,
                },
            },
        });

        // 6. Trả về format Khớp 100% với FE Model (Recording + Feedback)
        return {
            id: answerDetail.id,
            topicId: question.section.examId,
            topicTitle: question.section.exam.title,
            audioUrl: audioUrl,
            duration: 0, // Mock duration
            createdAt: answerDetail.submission.createdAt.toISOString(),
            transcript: evaluation.transcript,
            feedback: {
                overall: evaluation.overall,
                fluency: evaluation.fluency,
                pronunciation: evaluation.pronunciation,
                grammar: evaluation.grammar,
                vocabulary: evaluation.vocabulary,
                coherence: evaluation.coherence,
                strengths: evaluation.strengths,
                issues: evaluation.issues,
                suggestions: evaluation.suggestions,
            }
        };
    } finally {
        // Xóa file tạm sau khi xử lý xong
        if (fs.existsSync(audioFilePath)) {
            fs.unlinkSync(audioFilePath);
        }
    }
}

// ─── WRITING ──────────────────────────────────────────────────────────────────

export interface WritingSubmitInput {
    userId: string;
    questionId: string;
    essay: string;
}

export async function submitWriting(input: WritingSubmitInput) {
    const { userId, questionId, essay } = input;

    // Lấy question để biết prompt
    const question = await prisma.question.findUnique({
        where: { id: questionId },
        include: { section: { include: { exam: true } } },
    });
    if (!question) throw new Error('Câu hỏi không tồn tại');

    // 1. GPT-4: chấm điểm Writing
    const evaluation = await AiService.evaluateWriting(essay, question.questionText);

    // 2. Tìm hoặc tạo Submission cho exam này
    let submission = await prisma.submission.findFirst({
        where: { userId, examId: question.section.examId },
    });
    if (!submission) {
        submission = await prisma.submission.create({
            data: { userId, examId: question.section.examId },
        });
    } else {
        await prisma.submission.update({
            where: { id: submission.id },
            // @ts-ignore
            data: { updatedAt: new Date() }
        });
    }

    // 3. Tạo AnswerDetail
    const answerDetail = await prisma.answerDetail.create({
        include: { submission: true },
        data: {
            submissionId: submission.id,
            questionId,
            userAnswer: essay,
            isCorrect: null, // Writing không có đúng/sai tuyệt đối
        },
    });

    // 4. Lưu AiEvaluation
    await prisma.aiEvaluation.create({
        data: {
            answerDetailId: answerDetail.id,
            bandScore: evaluation.overall,
            criteriaScores: {
                fluency: evaluation.fluency,
                pronunciation: evaluation.pronunciation,
                grammar: evaluation.grammar,
                vocabulary: evaluation.vocabulary,
                coherence: evaluation.coherence,
            },
            feedback: JSON.stringify(evaluation.strengths),
            corrections: {
                issues: evaluation.issues,
                suggestions: evaluation.suggestions,
            },
        },
    });

    // 5. Trả về format Khớp 100% với FE Model
    return {
        id: answerDetail.id,
        topicId: question.section.examId,
        topicTitle: question.section.exam.title,
        audioUrl: '', // Writing doesn't have audio
        duration: 0,
        createdAt: answerDetail.submission.createdAt.toISOString(),
        transcript: essay,
        feedback: {
            overall: evaluation.overall,
            fluency: evaluation.fluency,
            pronunciation: evaluation.pronunciation,
            grammar: evaluation.grammar,
            vocabulary: evaluation.vocabulary,
            coherence: evaluation.coherence,
            strengths: evaluation.strengths,
            issues: evaluation.issues,
            suggestions: evaluation.suggestions,
        }
    };
}

// ─── OBJECTIVE (READING / LISTENING) ──────────────────────────────────────────

export interface ObjectiveAnswer {
    questionId: string;
    userAnswer: string;
}

export interface ObjectiveSubmitInput {
    userId: string;
    examId: string;
    answers: ObjectiveAnswer[];
}

function calculateBandScore(correctCount: number, totalQuestions: number): number {
    if (totalQuestions === 0) return 0;
    // Map to a 40-question scale
    const scaledScore = Math.round((correctCount / totalQuestions) * 40);

    if (scaledScore >= 39) return 9.0;
    if (scaledScore >= 37) return 8.5;
    if (scaledScore >= 35) return 8.0;
    if (scaledScore >= 32) return 7.5;
    if (scaledScore >= 30) return 7.0;
    if (scaledScore >= 26) return 6.5;
    if (scaledScore >= 23) return 6.0;
    if (scaledScore >= 20) return 5.5;
    if (scaledScore >= 16) return 5.0;
    if (scaledScore >= 13) return 4.5;
    if (scaledScore >= 10) return 4.0;
    if (scaledScore >= 7) return 3.5;
    if (scaledScore >= 4) return 3.0;
    if (scaledScore >= 2) return 2.5;
    if (scaledScore >= 1) return 2.0;
    return 0.0;
}

export async function submitObjective(input: ObjectiveSubmitInput) {
    const { userId, examId, answers } = input;

    // Retrieve the exam and its questions
    const exam = await prisma.ieltsExam.findUnique({
        where: { id: examId },
        include: {
            sections: {
                include: {
                    questions: true,
                },
            },
        },
    });

    if (!exam) throw new Error('Bài thi (Exam) không tồn tại');

    // Gather objective questions for reading/listening
    const objectiveQuestions = exam.sections
        .filter(s => s.skill === 'READING' || s.skill === 'LISTENING')
        .flatMap(s => s.questions.map(q => ({ ...q, sectionSkill: s.skill })));

    let correctCount = 0;
    // We evaluate against the provided answers or all objective ones
    // Usually, the Band Score is based on the number of questions in the section.
    // If the client only submitted part of it we still scale based on provided length or total length.
    // Assuming totalQuestions refers to the number of objective questions in this exam.
    const totalQuestions = objectiveQuestions.length;

    // Create or find submission
    let submission = await prisma.submission.findFirst({
        where: { userId, examId },
    });
    if (!submission) {
        submission = await prisma.submission.create({
            data: { userId, examId },
        });
    } else {
        await prisma.submission.update({
            where: { id: submission.id },
            // @ts-ignore
            data: { updatedAt: new Date() }
        });
    }

    const answerDetailsData = [];

    for (const answer of answers) {
        const question = objectiveQuestions.find(q => q.id === answer.questionId);
        if (!question) continue;

        let isCorrect = false;
        if (question.correctAnswers) {
            const correctIdsOrTexts = question.correctAnswers as string[];
            if (Array.isArray(correctIdsOrTexts)) {
                // Normalize string: trim and lowercase
                const normalizedUserAnswer = answer.userAnswer.trim().toLowerCase();
                isCorrect = correctIdsOrTexts.some(correct =>
                    correct.trim().toLowerCase() === normalizedUserAnswer
                );
            }
        }

        if (isCorrect) correctCount++;

        answerDetailsData.push({
            questionId: question.id,
            userAnswer: answer.userAnswer.trim(),
            isCorrect,
            skill: question.sectionSkill,
        });
    }

    // Calculate band score
    // If the frontend only sends answers for one skill, we might want to scale by answers.length
    // For simplicity, we scale based on the answers submitted
    const scaleTotal = answers.length > 0 ? answers.length : totalQuestions;
    const bandScore = calculateBandScore(correctCount, scaleTotal);

    // Save logic
    const results: any[] = [];
    for (const adData of answerDetailsData) {
        const ad = await prisma.answerDetail.create({
            data: {
                submissionId: submission.id,
                questionId: adData.questionId,
                userAnswer: adData.userAnswer,
                isCorrect: adData.isCorrect,
            },
        });

        // Mock AiEvaluation for consistency
        await prisma.aiEvaluation.create({
            data: {
                answerDetailId: ad.id,
                bandScore: bandScore,
                criteriaScores: { isCorrect: adData.isCorrect, skill: adData.skill },
                feedback: adData.isCorrect ? 'Correct answer' : 'Incorrect answer',
                corrections: {},
            },
        });

        results.push({
            id: ad.id,
            questionId: ad.questionId,
            userAnswer: ad.userAnswer,
            isCorrect: ad.isCorrect,
        });
    }

    // Update Submission with total band score
    await prisma.submission.update({
        where: { id: submission.id },
        data: { totalBandScore: bandScore, status: 'GRADED' },
    });

    // Return format matching Speaking/Writing for FE consistency
    return {
        id: submission.id, // Using submission ID as result ID for objective
        topicId: examId,
        topicTitle: exam.title,
        audioUrl: '', 
        duration: 0,
        createdAt: submission.createdAt.toISOString(),
        transcript: `Bạn đã trả lời đúng ${correctCount}/${scaleTotal} câu hỏi.`,
        feedback: {
            overall: bandScore,
            fluency: 0,
            pronunciation: 0,
            grammar: 0,
            vocabulary: 0,
            coherence: 0,
            strengths: [`Đúng ${correctCount} câu`, `Tổng ${scaleTotal} câu`],
            issues: results.filter(r => !r.isCorrect).map(r => `Câu ${results.indexOf(r) + 1} chưa chính xác`),
            suggestions: [`Band Score ước tính: ${bandScore}`],
            objectiveDetails: results // Trao thêm thông tin chi tiết cho FE
        }
    };
}
