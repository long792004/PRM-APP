import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import prisma from '../utils/prisma';

const JWT_SECRET = process.env.JWT_SECRET || 'fallback_secret_key_for_dev';

export const registerUser = async (email: string, passwordRaw: string) => {
    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) {
        throw new Error('Email already exists');
    }

    const hashedPassword = await bcrypt.hash(passwordRaw, 10);

    const user = await prisma.user.create({
        data: {
            email,
            password: hashedPassword,
            role: 'user', // Forced role user based on requirements
        },
    });

    return { id: user.id, email: user.email, role: user.role };
};

export const loginUser = async (email: string, passwordRaw: string) => {
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
        throw new Error('Invalid email or password');
    }

    const isPasswordValid = await bcrypt.compare(passwordRaw, user.password);
    if (!isPasswordValid) {
        throw new Error('Invalid email or password');
    }

    const token = jwt.sign(
        { userId: user.id, role: user.role },
        JWT_SECRET,
        { expiresIn: '1d' }
    );

    return {
        token,
        user: { id: user.id, email: user.email, role: user.role }
    };
};
