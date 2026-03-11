const axios = require('axios');
async function test() {
    console.log("Login user...");
    const loginRes = await axios.post('http://localhost:3000/api/auth/login', {
        email: 'test_student4@app.com', password: '123'
    });
    const token = loginRes.data.token;
    const headers = { Authorization: `Bearer ${token}` };

    console.log("Fetching Exams...");
    const examsRes = await axios.get('http://localhost:3000/api/admin/exams', { headers });
    const exam = examsRes.data.find(e => e.title.includes("Full 4 Skills Demo"));
    const writingQuestion = exam.sections.find(s => s.skill === 'WRITING')?.questions[0];

    console.log("Testing Writing Submission (call to GPT)...");
    if (writingQuestion) {
        try {
            const wResult = await axios.post('http://localhost:3000/api/submissions/writing', {
                questionId: writingQuestion.id,
                essay: "I believe education should be accessible to everyone regardless of whether it leads to employment, because knowledge empowers individuals. Moreover, an educated society is a foundation for prosperity, leading to innovation and better living standards for all citizens."
            }, { headers });
            console.log("Writing Response:", wResult.data);
        } catch (e) {
            console.error("Writing Error Response:");
            console.error(e.response?.data || e.message);
        }
    } else {
        console.log("No writing question found");
    }
}
test();
