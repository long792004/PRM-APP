const axios = require('axios');
const fs = require('fs');

async function testAllAPI() {
    try {
        console.log("Registering test user...");
        try {
            await axios.post('http://localhost:3000/api/auth/register', {
                email: 'test_student4@app.com', password: '123'
            });
        } catch (e) { }

        console.log("Login user...");
        const loginRes = await axios.post('http://localhost:3000/api/auth/login', {
            email: 'test_student4@app.com', password: '123'
        });
        const token = loginRes.data.token;
        const headers = { Authorization: `Bearer ${token}` };

        console.log("Fetching Exams...");
        const examsRes = await axios.get('http://localhost:3000/api/admin/exams', { headers });
        const exam = examsRes.data.find(e => e.title.includes("Full 4 Skills Demo"));

        if (!exam) {
            console.error("Exam not found!");
            return;
        }

        console.log("Found Exam:", exam.title);

        const readingQuestion = exam.sections.find(s => s.skill === 'READING')?.questions[0];
        const writingQuestion = exam.sections.find(s => s.skill === 'WRITING')?.questions[0];
        const listeningQuestion = exam.sections.find(s => s.skill === 'LISTENING')?.questions[0];

        console.log("Testing Objective Submission...");
        if (readingQuestion && listeningQuestion) {
            const result = await axios.post('http://localhost:3000/api/submissions/objective', {
                examId: exam.id,
                answers: [
                    { questionId: readingQuestion.id, userAnswer: 'False' },
                    { questionId: listeningQuestion.id, userAnswer: 'The weather' },
                ]
            }, { headers });
            console.log("Objective Score:", result.data.data.bandScore);
        }

        console.log("Testing Writing Submission (call to GPT)...");
        if (writingQuestion) {
            try {
                const wResult = await axios.post('http://localhost:3000/api/submissions/writing', {
                    questionId: writingQuestion.id,
                    essay: "I believe education should be accessible to everyone regardless of whether it leads to employment, because knowledge empowers individuals..."
                }, { headers });
                console.log("Writing Feedback:", wResult.data.data.feedback.substring(0, 100));
            } catch (e) {
                console.log("Writing Error:", e.response?.data || e.message);
            }
        }
    } catch (err) {
        console.error("Fatal Error:", err.response?.data || err.message);
    }
}
testAllAPI();
