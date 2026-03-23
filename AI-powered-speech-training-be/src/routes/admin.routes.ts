import { Router } from 'express';
import { getStats } from '../controllers/admin.controller';
import { getExams, createExam, updateExam, deleteExam } from '../controllers/exam.controller';
import { verifyToken, requireAdmin } from '../middlewares/auth.middleware';
import { audioUpload } from '../utils/upload';

const router = Router();

// GET /api/admin/stats - Dashboard stats (Admin only)
router.get('/stats', verifyToken, requireAdmin, getStats);

// Các APIs quản lý IELTS Exams
router.get('/exams', verifyToken, getExams); // có thể để public cho User, nhưng tạm để auth. Lát sẽ gọi riêng
router.post('/exams', verifyToken, requireAdmin, audioUpload.any(), createExam);
router.put('/exams/:id', verifyToken, requireAdmin, audioUpload.any(), updateExam);
router.delete('/exams/:id', verifyToken, requireAdmin, deleteExam);

export default router;
