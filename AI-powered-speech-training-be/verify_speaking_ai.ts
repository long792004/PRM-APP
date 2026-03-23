
import dotenv from 'dotenv';
dotenv.config();
import * as AiService from './src/services/ai.service';
import * as path from 'path';
import * as fs from 'fs';

async function verify() {
    const audioPath = path.resolve(__dirname, 'uploads', 'upload_1774228701980_rsjhbk90tks.mp4');
    const prompt = "Describe a famous person you admire.";

    console.log("Testing with audio:", audioPath);
    if (!fs.existsSync(audioPath)) {
        console.error("File not found!");
        return;
    }

    try {
        console.log("Calling evaluateSpeakingWithAudio...");
        const result = await AiService.evaluateSpeakingWithAudio(audioPath, prompt);
        console.log("RESULT:", JSON.stringify(result, null, 2));
    } catch (e: any) {
        console.error("FAILED:", e.message);
    }
}

verify();
