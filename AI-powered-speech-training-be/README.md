# IELTS AI Speaking Training - Backend Setup

Dự án này sử dụng Node.js, Express, Prisma (v7) và PostgreSQL (Neon).

## Các bước thiết lập trên máy mới

1. **Cài đặt Node.js**: Đảm bảo máy đã cài Node.js (loại LTS).
2. **Cấu hình Môi trường**:
   - Copy file `.env.example` thành `.env`.
   - Dán `DATABASE_URL` (lấy từ Neon console) vào file `.env`.
   - Các API Key (Gemini, OpenAI) và `JWT_SECRET` cũng cần được cấu hình.
3. **Chạy Lệnh Thiết Lập Tự Động**:
   ```bash
   npm run setup
   ```
   Lệnh này sẽ thực hiện:
   - `npm install`: Cài đặt dependencies.
   - `npx prisma generate`: Tạo Prisma Client cho máy hiện tại.
   - `npx ts-node prisma/seed.ts`: Tạo tài khoản admin mặc định (`admin@app.com` / `admin123`).

4. **Chạy Server**:
   ```bash
   npm run dev
   ```

## Kiểm tra
- Truy cập `http://localhost:3000/health` để kiểm tra trạng thái server.
- Đăng nhập với tài khoản admin đã được seed.

## Lưu ý
- Nếu thay đổi `schema.prisma`, hãy chạy `npx prisma db push` để cập nhật database.
- Không được xóa file `prisma.config.ts` vì Prisma 7 cần nó để đọc config từ `.env`.
