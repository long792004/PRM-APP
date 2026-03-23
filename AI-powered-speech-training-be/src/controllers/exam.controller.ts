import { Request, Response } from 'express';
import prisma from '../utils/prisma';
import { getAudioPublicUrl } from '../utils/upload';

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

/**
 * Helper để map file upload vào các section Listening
 */
const mapFilesToSections = (sections: any[], files: any[]) => {
    if (!files || files.length === 0) return sections;

    let listeningFileIndex = 0;
    return sections.map((sec: any) => {
        if (sec.skill === 'LISTENING') {
            // Ưu tiên tìm theo audioFieldName nếu FE có gửi
            const audioFileName = sec.content?.audioFileName;
            let file = null;

            if (audioFileName) {
                file = files.find(f => f.originalname === audioFileName || f.fieldname === audioFileName);
            }

            // Nếu không tìm thấy hoặc không gửi audioFileName, lấy theo thứ tự
            if (!file && listeningFileIndex < files.length) {
                file = files[listeningFileIndex];
                listeningFileIndex++;
            }

            if (file) {
                sec.content = {
                    ...(sec.content || {}),
                    audioUrl: getAudioPublicUrl(file.filename)
                };
            }
        }
        return sec;
    });
};

export const createExam = async (req: Request, res: Response) => {
    try {
        let { title, type, sections } = req.body;

        // Nếu gửi qua multipart/form-data, JSON có thể nằm trong field 'examData'
        if (req.body.examData) {
            const data = JSON.parse(req.body.examData);
            title = data.title;
            type = data.type;
            sections = data.sections;
        }

        // Map files vào sections
        const files = req.files as any[];
        const processedSections = mapFilesToSections(sections || [], files || []);

        const newExam = await prisma.ieltsExam.create({
            data: {
                title,
                type: type || 'MOCK_TEST',
                sections: {
                    create: processedSections.map((sec: any) => ({
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
        let { title, type, sections } = req.body;

        // Nếu gửi qua multipart/form-data
        if (req.body.examData) {
            const data = JSON.parse(req.body.examData);
            title = data.title;
            type = data.type;
            sections = data.sections;
        }

        // Map files vào sections
        const files = req.files as any[];
        const processedSections = mapFilesToSections(sections || [], files || []);

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
                    create: processedSections.map((sec: any) => ({
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
        console.error('Update Exam Error:', error);
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
