import 'dotenv/config'
import bcrypt from 'bcrypt'
import prisma from '../src/utils/prisma'

async function main() {
    const hashedPassword = await bcrypt.hash('admin123', 10)

    const admin = await prisma.user.upsert({
        where: { email: 'admin@app.com' },
        update: {},
        create: {
            email: 'admin@app.com',
            password: hashedPassword,
            role: 'admin',
        },
    })
    console.log({ admin })
}

main()
    .catch((e) => {
        console.error(e)
        process.exit(1)
    })
    .finally(async () => {
        await prisma.$disconnect()
    })
