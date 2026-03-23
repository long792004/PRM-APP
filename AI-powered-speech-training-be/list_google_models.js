const axios = require('axios');
require('dotenv').config();

const key = process.env.GEMINI_API_KEY || process.env.OPENAI_API_KEY;

async function listModels() {
    const url = `https://generativelanguage.googleapis.com/v1beta/models?key=${key}`;
    try {
        const response = await axios.get(url);
        console.log("Supported Models:");
        response.data.models.forEach(m => {
            console.log(`- ${m.name} (Methods: ${m.supportedGenerationMethods.join(', ')})`);
        });
    } catch (e) {
        if (e.response) {
            console.error(`FAILED:`, e.response.status, e.response.data.error.message);
        } else {
            console.error(`FAILED:`, e.message);
        }
    }
}

listModels();
