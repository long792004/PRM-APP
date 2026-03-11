import { Response } from 'express';
import { AuthRequest } from '../middlewares/auth.middleware';
import * as adminService from '../services/admin.service';

export const getStats = async (req: AuthRequest, res: Response) => {
    try {
        const stats = await adminService.getDashboardStats();
        res.status(200).json(stats);
    } catch (error) {
        console.error('getStats error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};
