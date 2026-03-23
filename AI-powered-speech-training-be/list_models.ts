
import dotenv from 'dotenv';
dotenv.config();
import { GoogleGenerativeAI } from '@google/generative-ai';

async function listModels() {
    const key = process.env.GEMINI_API_KEY || "";
    const genAI = new GoogleGenerativeAI(key);
    try {
        // There is no easy listModels in the SDK directly sometimes, 
        // but we can try to access it or just try a different name.
        // Actually, the SDK doesn't expose listModels easily in newer versions without the management API.
        // Let's try gemini-1.5-flash-latest
        const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash-latest" });
        const result = await model.generateContent("test");
        console.log("SUCCESS with gemini-1.5-flash-latest:", result.response.text());
    } catch (e: any) {
        console.error("FAILED with gemini-1.5-flash-latest:", e.message);
        
        try {
            const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
            const result = await model.generateContent("test");
            console.log("SUCCESS with gemini-1.5-flash:", result.response.text());
        } catch (e2: any) {
            console.error("FAILED with gemini-1.5-flash:", e2.message);
        }
    }
}

listModels();
