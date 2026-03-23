const axios = require('axios');
require('dotenv').config();

const key = process.env.GEMINI_API_KEY || process.env.OPENAI_API_KEY;

async function testApi(version, model) {
    const url = `https://generativelanguage.googleapis.com/${version}/models/${model}:generateContent?key=${key}`;
    try {
        const response = await axios.post(url, {
            contents: [{ parts: [{ text: "Say hello" }] }]
        }, {
            headers: { 'Content-Type': 'application/json' }
        });
        console.log(`SUCCESS [${version}] ${model}:`, response.data.candidates[0].content.parts[0].text);
    } catch (e) {
        if (e.response) {
            console.error(`FAILED [${version}] ${model}:`, e.response.status, e.response.data.error.message);
        } else {
            console.error(`FAILED [${version}] ${model}:`, e.message);
        }
    }
}

async function run() {
    await testApi('v1beta', 'gemini-2.5-flash');
    await testApi('v1beta', 'gemini-flash-latest');
    await testApi('v1beta', 'gemini-2.0-flash-lite');
}

run();
