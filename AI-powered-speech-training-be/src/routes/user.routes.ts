import { Router } from 'express';
import { getHistory } from '../controllers/user.controller';
import { verifyToken } from '../middlewares/auth.middleware';

const router = Router();

// GET /api/users/history - Lấy lịch sử làm bài (Submissions + Điểm)
router.get('/history', verifyToken, getHistory);

export default router;
