require('dotenv').config();
const { GoogleGenerativeAI } = require('@google/generative-ai');

async function testGemini() {
    const genAI = new GoogleGenerativeAI(process.env.OPENAI_API_KEY || '');
    try {
        console.log("Trying gemini-2.0-flash");
        const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });
        const result = await model.generateContent("Hello!");
        console.log("Success with gemini-2.0-flash");
        console.log(result.response.text());
    } catch (e) {
        console.log("Failed. Full error:", e);
    }
}
testGemini();
