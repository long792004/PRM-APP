import prisma from '../utils/prisma';

export const getDashboardStats = async () => {
    const [totalUsers, totalExams, totalSubmissions, totalEvaluations] =
        await prisma.$transaction([
            prisma.user.count({ where: { role: 'user' } }),
            prisma.ieltsExam.count(),
            prisma.submission.count(),
            prisma.aiEvaluation.count(),
        ]);

    // Tính band score trung bình từ tất cả AiEvaluation
    const avgResult = await prisma.aiEvaluation.aggregate({
        _avg: { bandScore: true },
    });

    return {
        totalUsers,
        totalExams,
        totalSubmissions,
        totalEvaluations,
        averageBandScore: avgResult._avg.bandScore
            ? Math.round(avgResult._avg.bandScore * 10) / 10
            : null,
    };
};
