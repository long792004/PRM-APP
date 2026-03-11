import { Response } from 'express';
import { AuthRequest } from '../middlewares/auth.middleware';
import * as SubmissionService from '../services/submission.service';
import { getAudioPublicUrl } from '../utils/upload';
import * as path from 'path';

// ─── POST /api/submissions/speaking ──────────────────────────────────────────
/**
 * Body (multipart/form-data):
 *   - audio: File (required)
 *   - questionId: string (required)
 */
export const submitSpeaking = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const userId = req.user?.userId;
        if (!userId) {
            res.status(401).json({ error: 'Unauthorized' });
            return;
        }

        const { questionId } = req.body;
        if (!questionId) {
            res.status(400).json({ error: 'questionId là bắt buộc.' });
            return;
        }

        // File audio từ multer
        const audioFile = req.file;
        if (!audioFile) {
            res.status(400).json({ error: 'File audio là bắt buộc.' });
            return;
        }

        const audioUrl = getAudioPublicUrl(audioFile.filename);
        const audioFilePath = audioFile.path;

        const result = await SubmissionService.submitSpeaking({
            userId,
            questionId,
            audioFilePath,
            audioUrl,
        });

        res.status(201).json({
            message: 'Chấm điểm Speaking thành công',
            data: result,
        });
    } catch (error: any) {
        console.error('[SubmissionController] submitSpeaking error:', error);

        // Phân biệt lỗi logic vs lỗi hệ thống
        if (error.message?.includes('không tồn tại')) {
            res.status(404).json({ error: error.message });
        } else if (error.status === 401 || error.message?.includes('API key')) {
            res.status(500).json({ error: 'Lỗi cấu hình AI. Vui lòng liên hệ admin.' });
        } else {
            res.status(500).json({ error: 'Lỗi chấm điểm Speaking. Vui lòng thử lại.' });
        }
    }
};

// ─── POST /api/submissions/writing ───────────────────────────────────────────
/**
 * Body (application/json):
 *   - questionId: string (required)
 *   - essay: string (required)
 */
export const submitWriting = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const userId = req.user?.userId;
        if (!userId) {
            res.status(401).json({ error: 'Unauthorized' });
            return;
        }

        const { questionId, essay } = req.body;

        if (!questionId || !essay) {
            res.status(400).json({ error: 'questionId và essay là bắt buộc.' });
            return;
        }

        if (essay.trim().length < 50) {
            res.status(400).json({ error: 'Bài viết quá ngắn. Cần ít nhất 50 ký tự.' });
            return;
        }

        const result = await SubmissionService.submitWriting({
            userId,
            questionId,
            essay: essay.trim(),
        });

        res.status(201).json({
            message: 'Chấm điểm Writing thành công',
            data: result,
        });
    } catch (error: any) {
        console.error('[SubmissionController] submitWriting error:', error);

        if (error.message?.includes('không tồn tại')) {
            res.status(404).json({ error: error.message });
        } else if (error.status === 401 || error.message?.includes('API key')) {
            res.status(500).json({ error: 'Lỗi cấu hình AI. Vui lòng liên hệ admin.' });
        } else {
            res.status(500).json({ error: 'Lỗi chấm điểm Writing. Vui lòng thử lại.' });
        }
    }
};

// ─── POST /api/submissions/objective ─────────────────────────────────────────
/**
 * Body (application/json):
 *   - examId: string (required)
 *   - answers: Array<{ questionId: string, userAnswer: string }> (required)
 */
export const submitObjective = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const userId = req.user?.userId;
        if (!userId) {
            res.status(401).json({ error: 'Unauthorized' });
            return;
        }

        const { examId, answers } = req.body;

        if (!examId || !Array.isArray(answers)) {
            res.status(400).json({ error: 'examId và answers (mảng câu trả lời) là bắt buộc.' });
            return;
        }

        const result = await SubmissionService.submitObjective({
            userId,
            examId,
            answers,
        });

        res.status(201).json({
            message: 'Chấm điểm Reading/Listening thành công',
            data: result,
        });
    } catch (error: any) {
        console.error('[SubmissionController] submitObjective error:', error);

        if (error.message?.includes('tồn tại')) {
            res.status(404).json({ error: error.message });
        } else {
            res.status(500).json({ error: 'Lỗi chấm điểm Reading/Listening. Vui lòng thử lại.' });
        }
    }
};
