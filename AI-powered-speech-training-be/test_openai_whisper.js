const axios = require('axios');
const fs = require('fs');
const FormData = require('form-data');
require('dotenv').config();

const key = process.env.OPENAI_API_KEY;

async function testOpenAIWhisper() {
    const url = `https://api.openai.com/v1/audio/transcriptions`;
    const audioPath = 'uploads/upload_1774228701980_rsjhbk90tks.mp4';
    
    if (!fs.existsSync(audioPath)) {
         console.error("Audio file missing");
         return;
    }

    try {
        const formData = new FormData();
        formData.append('file', fs.createReadStream(audioPath));
        formData.append('model', 'whisper-1');

        const response = await axios.post(url, formData, {
            headers: { 
                'Authorization': `Bearer ${key}`,
                ...formData.getHeaders()
            }
        });
        console.log(`SUCCESS Whisper:`, response.data.text.substring(0, 50) + "...");
    } catch (e) {
        if (e.response) {
            console.error(`FAILED Whisper API:`, e.response.status, e.response.data.error.message);
        } else {
            console.error(`FAILED Whisper API:`, e.message);
        }
    }
}

testOpenAIWhisper();
