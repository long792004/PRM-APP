const axios = require('axios');
const fs = require('fs');
const FormData = require('form-data');
const path = require('path');

async function testUpload() {
    try {
        console.log("Login as admin...");
        const loginRes = await axios.post('http://localhost:3000/api/auth/login', {
            email: 'admin@app.com',
            password: 'admin123'
        });
        const token = loginRes.data.token;
        const headers = { Authorization: `Bearer ${token}` };

        console.log("Creating Exam with file upload...");
        const form = new FormData();
        
        const examData = {
            title: "Upload Test Exam",
            type: "PRACTICE",
            sections: [
                {
                    skill: "LISTENING",
                    content: {
                        audioFileName: "dummy_audio.mp3" // match by originalname
                    },
                    questions: [
                        {
                            questionText: "What is the dummy text?",
                            questionType: "FILL_BLANK",
                            correctAnswers: ["dummy"]
                        }
                    ]
                },
                {
                    skill: "READING",
                    content: {
                        readingPassage: "This is a reading test."
                    },
                    questions: []
                }
            ]
        };

        form.append('examData', JSON.stringify(examData));
        form.append('audio_0', fs.createReadStream(path.join(__dirname, 'dummy_audio.mp3')));

        const response = await axios.post('http://localhost:3000/api/admin/exams', form, {
            headers: {
                ...headers,
                ...form.getHeaders()
            }
        });

        console.log("Exam Created:", response.data.title);
        const examId = response.data.id;
        let listeningSection = response.data.sections.find(s => s.skill === 'LISTENING');
        console.log("Listening Audio URL:", listeningSection.content.audioUrl);

        if (listeningSection.content.audioUrl && listeningSection.content.audioUrl.includes('audio_')) {
            console.log("✅ SUCCESS: Audio URL was generated and stored.");
        } else {
            console.log("❌ FAILURE: Audio URL was NOT generated correctly.");
        }

        console.log("\nTesting Update Exam with NEW file upload...");
        const updateForm = new FormData();
        const updateData = {
            title: "Updated Upload Test Exam",
            sections: [
                {
                    skill: "LISTENING",
                    content: {
                        audioFileName: "dummy_audio_v2.mp3"
                    },
                    questions: []
                }
            ]
        };

        fs.writeFileSync(path.join(__dirname, 'dummy_audio_v2.mp3'), 'second dummy audio');
        updateForm.append('examData', JSON.stringify(updateData));
        updateForm.append('audio_v2', fs.createReadStream(path.join(__dirname, 'dummy_audio_v2.mp3')));

        const updateRes = await axios.put(`http://localhost:3000/api/admin/exams/${examId}`, updateForm, {
            headers: {
                ...headers,
                ...updateForm.getHeaders()
            }
        });

        console.log("Exam Updated:", updateRes.data.title);
        listeningSection = updateRes.data.sections.find(s => s.skill === 'LISTENING');
        console.log("New Listening Audio URL:", listeningSection.content.audioUrl);

        if (listeningSection.content.audioUrl && listeningSection.content.audioUrl.includes('audio_')) {
            console.log("✅ SUCCESS: New Audio URL was generated and stored.");
        } else {
            console.log("❌ FAILURE: New Audio URL was NOT generated correctly.");
        }

    } catch (error) {
        console.error("Error:", error.response?.data || error.message);
    }
}

testUpload();
