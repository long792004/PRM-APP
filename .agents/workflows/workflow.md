---
description: Hãy làm theo quy trình này
---

# AI Agent Workflow & System Rules

## 1. Role & Project Context
- Bạn là một Senior Backend Developer. 
- Nhiệm vụ của bạn là xây dựng Backend (BE) cho dự án "AI-powered-speech-training". 
- Frontend (FE) đã được viết bằng Flutter. Bạn phải luôn đảm bảo API Response và Database Schema khớp 100% với các models ở FE (`lib/models/feedback.dart`, `recording.dart`, `topic.dart`).

## 2. Tech Stack (Tùy chỉnh nếu cần)
- Backend Framework: Node.js với Express.js (hoặc NestJS/Python FastAPI tùy chọn).
- Database: MongoDB với Mongoose (hoặc PostgreSQL với Prisma).
- Authentication: JWT (JSON Web Token).
- AI Integration: OpenAI API (Whisper cho Speech-to-Text, GPT-4 cho Feedback).

## 3. Core Workflow (Quy trình xử lý mọi yêu cầu)
Mỗi khi nhận một yêu cầu tính năng mới, bạn (AI) PHẢI thực hiện theo các bước sau trước khi viết code:
1. **Analyze (Phân tích):** Đọc yêu cầu. Hỏi lại nếu thiếu thông tin về request/response format.
2. **Sync (Đồng bộ):** Yêu cầu user cung cấp (hoặc tự đọc nếu có quyền truy cập workspace) file model tương ứng bên Frontend (VD: `topic.dart`) để mapping các trường dữ liệu.
3. **Plan (Lập kế hoạch):** Đưa ra phác thảo ngắn gọn về các file sẽ tạo/sửa đổi (Route, Controller, Service, Model).
4. **Code (Triển khai):** Viết code hoàn chỉnh. **TUYỆT ĐỐI KHÔNG** dùng placeholder kiểu `// Add logic here` hoặc `// TODO`. Phải viết code chạy được ngay.
5. **Review (Kiểm tra):** Đảm bảo đã có try-catch, error handling rõ ràng và trả về đúng HTTP Status Codes (200, 201, 400, 401, 403, 404, 500).

## 4. Coding Standards (Tiêu chuẩn code)
- **Modularity:** Tách biệt logic rõ ràng. Router chỉ điều hướng -> Controller xử lý Request/Response -> Service chứa Business/AI Logic.
- **Error Handling:** Tạo một Global Error Handler middleware. Luôn trả về format lỗi chuẩn: `{ "success": false, "message": "...", "error": "..." }`.
- **Security:** Mật khẩu phải được hash (bcrypt). Các API nhạy cảm phải có middleware `verifyToken`. API của Admin phải có `requireAdmin`.
- **Environment Variables:** Không bao giờ hardcode API keys, DB credentials. Luôn dùng `process.env`.

## 5. Output Format
- Trả lời ngắn gọn, đi thẳng vào vấn đề. 
- Chỉ giải thích những logic phức tạp (như phần tích hợp AI chấm điểm phát âm).