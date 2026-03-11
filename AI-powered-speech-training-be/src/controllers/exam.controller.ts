import { Request, Response } from 'express';
import prisma from '../utils/prisma';

export const getExams = async (req: Request, res: Response) => {
    try {
        const exams = await prisma.ieltsExam.findMany({
            include: {
                sections: {
                    include: {
                        questions: true
                    }
                }
            },
            orderBy: { createdAt: 'desc' }
        });
        res.json(exams);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

export const createExam = async (req: Request, res: Response) => {
    try {
        const { title, type, sections } = req.body;

        // Cấu trúc sections dự kiến từ FE: 
        // [ { skill, content: { audioUrl, readingPassage }, questions: [ { questionText, questionType, correctAnswers, content } ] } ]

        const newExam = await prisma.ieltsExam.create({
            data: {
                title,
                type: type || 'MOCK_TEST',
                sections: {
                    create: sections?.map((sec: any) => ({
                        skill: sec.skill,
                        content: sec.content || {},
                        questions: {
                            create: sec.questions?.map((q: any) => ({
                                questionText: q.questionText,
                                questionType: q.questionType,
                                correctAnswers: q.correctAnswers || null,
                                content: q.content || null
                            })) || []
                        }
                    })) || []
                }
            },
            include: {
                sections: { include: { questions: true } }
            }
        });

        res.status(201).json(newExam);
    } catch (error: any) {
        console.error('Create Exam Error:', error);
        res.status(500).json({ error: error.message });
    }
};

export const updateExam = async (req: Request, res: Response) => {
    try {
        const id = req.params.id as string;
        const { title, type, sections } = req.body;

        // Xóa sections cũ (cascade sẽ xóa cả questions)
        await prisma.examSection.deleteMany({
            where: { examId: id }
        });

        // Cập nhật exam và tạo lại sections
        const updatedExam = await prisma.ieltsExam.update({
            where: { id },
            data: {
                title,
                type: type || 'MOCK_TEST',
                sections: {
                    create: sections?.map((sec: any) => ({
                        skill: sec.skill,
                        content: sec.content || {},
                        questions: {
                            create: sec.questions?.map((q: any) => ({
                                questionText: q.questionText,
                                questionType: q.questionType,
                                correctAnswers: q.correctAnswers || null,
                                content: q.content || null
                            })) || []
                        }
                    })) || []
                }
            },
            include: {
                sections: { include: { questions: true } }
            }
        });

        res.json(updatedExam);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

export const deleteExam = async (req: Request, res: Response) => {
    try {
        const id = req.params.id as string;
        await prisma.ieltsExam.delete({
            where: { id }
        });
        res.json({ message: 'Deleted successfully' });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};
