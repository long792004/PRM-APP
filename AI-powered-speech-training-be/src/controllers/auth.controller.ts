import { Request, Response } from 'express';
import * as authService from '../services/auth.service';

export const register = async (req: Request, res: Response) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            res.status(400).json({ error: 'Email and password are required' });
            return;
        }

        const result = await authService.registerUser(email, password);
        res.status(201).json({ message: 'User registered successfully', user: result });
    } catch (error: any) {
        if (error.message === 'Email already exists') {
            res.status(409).json({ error: error.message });
            return;
        }
        console.error('Register error:', error);
        res.status(500).json({ 
            error: 'Internal server error', 
            details: error.message,
            stack: error.stack
        });
    }
};

export const login = async (req: Request, res: Response) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            res.status(400).json({ error: 'Email and password are required' });
            return;
        }

        const result = await authService.loginUser(email, password);
        res.status(200).json(result);
    } catch (error: any) {
        if (error.message === 'Invalid email or password') {
            res.status(401).json({ error: error.message });
            return;
        }
        console.error('Login error:', error);
        res.status(500).json({ 
            error: 'Internal server error', 
            details: error.message,
            stack: error.stack 
        });
    }
};
