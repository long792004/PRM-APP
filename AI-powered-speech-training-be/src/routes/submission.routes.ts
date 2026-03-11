import { Router } from 'express';
import { verifyToken } from '../middlewares/auth.middleware';
import { submitSpeaking, submitWriting, submitObjective } from '../controllers/submission.controller';
import { audioUpload } from '../utils/upload';

const router = Router();

// POST /api/submissions/speaking — nhận file audio (multipart/form-data)
router.post(
    '/speaking',
    verifyToken,
    audioUpload.single('audio'), // field name = 'audio'
    submitSpeaking,
);

// POST /api/submissions/writing — nhận JSON essay
router.post('/writing', verifyToken, submitWriting);

// POST /api/submissions/objective — nhận array answers cho Reading/Listening
router.post('/objective', verifyToken, submitObjective);

export default router;
