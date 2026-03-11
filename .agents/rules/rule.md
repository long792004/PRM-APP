---
trigger: always_on
---

# AI Agent Workflow & System Rules

## 1. Project Context
- Backend (BE) cho dự án "AI-powered-speech-training".
- Frontend (FE) viết bằng Flutter đã có sẵn. API Response và DB Schema PHẢI khớp 100% với FE models (`feedback.dart`, `recording.dart`, `topic.dart`).

## 2. Tech Stack
- Framework: Node.js + Express.js
- Database: PostgreSQL + Prisma ORM
- Auth: JWT, bcrypt
- AI: OpenAI API (Whisper cho STT, GPT cho feedback)

## 3. Core Rules
- **Chỉ 1 Admin duy nhất:** Không có API tạo admin. Dùng Prisma Seed để tạo sẵn 1 tài khoản admin. API Register chỉ tạo role 'user'.
- **Code chuẩn:** KHÔNG dùng `// TODO` hay placeholder. Code phải chạy được ngay, có try-catch và Error Handler chuẩn.
- **RESTful:** Tuân thủ cấu trúc Router -> Controller -> Service.