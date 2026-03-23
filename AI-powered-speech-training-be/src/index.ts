import dotenv from 'dotenv';
dotenv.config(); // PHẢI gọi trước khi import Prisma để DATABASE_URL có sẵn

import express from 'express';
import cors from 'cors';
import path from 'path';

// Routes
import authRoutes from './routes/auth.routes';
import submissionRoutes from './routes/submission.routes';
import adminRoutes from './routes/admin.routes';
import userRoutes from './routes/user.routes';

const app = express();

// ─── Middlewares ───────────────────────────────────────────────────────────────
app.use(cors()); // Global CORS
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// ─── Static files (audio uploads) ─────────────────────────────────────────────
// Đảm bảo CORS cho phép tải audio từ domain khác (FE port)
app.use('/uploads', cors(), express.static(path.resolve(process.cwd(), 'uploads')));

// ─── API Routes ───────────────────────────────────────────────────────────────
app.use('/api/auth', authRoutes);
app.use('/api/submissions', submissionRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/users', userRoutes);

// ─── Health check ─────────────────────────────────────────────────────────────
app.get('/health', (_req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// ─── Global error handler ─────────────────────────────────────────────────────
app.use((err: any, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
    console.error('[GlobalError]', err);
    const status = err.status || 500;
    res.status(status).json({ error: err.message || 'Internal Server Error' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`🚀 IELTS Training Server running on port ${PORT}`);
});
