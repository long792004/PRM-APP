const axios = require('axios');
require('dotenv').config();

const key = process.env.OPENAI_API_KEY;

async function testOpenAI() {
    const url = `https://api.openai.com/v1/models`;
    try {
        const response = await axios.get(url, {
            headers: { 'Authorization': `Bearer ${key}` }
        });
        console.log(`SUCCESS: OpenAI models fetched. Found ${response.data.data.length} models.`);
    } catch (e) {
        if (e.response) {
            console.error(`FAILED OpenAI API:`, e.response.status, e.response.data.error.message);
        } else {
            console.error(`FAILED OpenAI API:`, e.message);
        }
    }
}

testOpenAI();
