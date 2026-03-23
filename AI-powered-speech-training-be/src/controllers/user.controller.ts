import { Request, Response } from 'express';
import { AuthRequest } from '../middlewares/auth.middleware';
import prisma from '../utils/prisma';

export const getHistory = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const userId = req.user?.userId;
        if (!userId) {
            res.status(401).json({ error: 'Unauthorized' });
            return;
        }

        const answerDetails = await prisma.answerDetail.findMany({
            where: {
                submission: { userId: userId },
                aiEvaluation: { isNot: null }
            },
            include: {
                submission: {
                    include: {
                        exam: true
                    }
                },
                question: {
                    include: {
                        section: true
                    }
                },
                aiEvaluation: true
            },
            // @ts-ignore
            orderBy: { submission: { updatedAt: 'desc' } }
        });

        // Map về mảng Recordings / Submissions cho HistoryScreen
        const history = answerDetails.map((ad: any) => {
            const ai = ad.aiEvaluation;
            let strengths = [];
            try {
                if (ai?.feedback) strengths = JSON.parse(ai.feedback);
            } catch (e) { }

            return {
                id: ad.id,
                topicId: ad.submission.exam.id,
                topicTitle: ad.submission.exam.title + (ad.question.section.skill ? ` (${ad.question.section.skill})` : ''),
                audioUrl: ad.audioUrl || '',
                duration: 60, // Mock duration
                createdAt: ad.submission.createdAt.toISOString(),
                transcript: ad.userAnswer || '',
                feedback: {
                    overall: ai?.bandScore || 0,
                    fluency: (ai?.criteriaScores as any)?.fluency || 0,
                    pronunciation: (ai?.criteriaScores as any)?.pronunciation || 0,
                    grammar: (ai?.criteriaScores as any)?.grammar || 0,
                    vocabulary: (ai?.criteriaScores as any)?.vocabulary || 0,
                    coherence: (ai?.criteriaScores as any)?.coherence || 0,
                    strengths: strengths,
                    issues: (ai?.corrections as any)?.issues || [],
                    suggestions: (ai?.corrections as any)?.suggestions || []
                }
            };
        });

        res.json(history);
    } catch (error: any) {
        console.error('getHistory error:', error);
        res.status(500).json({ error: 'Lỗi tải lịch sử' });
    }
};
