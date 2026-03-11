const axios = require('axios');
async function test() {
    console.log("Login user...");
    const loginRes = await axios.post('http://localhost:3000/api/auth/login', {
        email: 'test_student4@app.com', password: '123'
    });
    const token = loginRes.data.token;
    const headers = { Authorization: `Bearer ${token}` };

    console.log("Fetching History...");
    try {
        const historyRes = await axios.get('http://localhost:3000/api/users/history', { headers });
        console.log("History:", historyRes.data.length, "items.");
        if (historyRes.data.length > 0) {
            console.log(historyRes.data[0]);
        }
    } catch (e) {
        console.error("error", e.response?.data || e.message);
    }
}
test();
