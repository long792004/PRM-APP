
import dotenv from 'dotenv';
dotenv.config();
import { GoogleGenerativeAI } from '@google/generative-ai';

async function testPro() {
    const key = process.env.GEMINI_API_KEY || "";
    const genAI = new GoogleGenerativeAI(key);
    try {
        const model = genAI.getGenerativeModel({ model: "gemini-pro" });
        const result = await model.generateContent("test");
        console.log("SUCCESS with gemini-pro:", result.response.text());
    } catch (e: any) {
        console.error("FAILED with gemini-pro:", e.message);
    }
}

testPro();
