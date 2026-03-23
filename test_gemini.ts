
import dotenv from 'dotenv';
dotenv.config();
import { GoogleGenerativeAI } from '@google/generative-ai';
import * as fs from 'fs';

async function testGemini() {
    const key = process.env.GEMINI_API_KEY || "";
    console.log("Using key:", key.substring(0, 5) + "...");
    const genAI = new GoogleGenerativeAI(key);
    try {
        const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
        const result = await model.generateContent("Say hello");
        console.log("Success:", result.response.text());
    } catch (e: any) {
        console.error("Failed:", e.message);
    }
}

testGemini();
