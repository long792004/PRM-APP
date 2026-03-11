// prisma/seed.js — Tạo admin account mặc định cho IELTS App
const { PrismaClient } = require('@prisma/client');
const { PrismaPg } = require('@prisma/adapter-pg');
const { Pool } = require('pg');
const bcrypt = require('bcrypt');
require('dotenv').config();

async function main() {
    const pool = new Pool({ connectionString: process.env.DATABASE_URL });
    const adapter = new PrismaPg(pool);
    const prisma = new PrismaClient({ adapter });

    const adminEmail = 'admin@app.com';
    const existing = await prisma.user.findUnique({ where: { email: adminEmail } });

    if (!existing) {
        const hashed = await bcrypt.hash('admin123', 10);
        await prisma.user.create({
            data: {
                email: adminEmail,
                password: hashed,
                role: 'admin',
            },
        });
        console.log('✅ Admin seeded: admin@app.com / admin123');
    } else {
        console.log('ℹ️  Admin already exists, skipping.');
    }

    await prisma.$disconnect();
    await pool.end();
}

main().catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
});
