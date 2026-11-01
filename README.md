# API – Task Manager (Node.js, Express, MongoDB)

## Cài đặt & chạy
```bash
cd api
npm install
cp .env.example .env     # rồi sửa MONGODB_URI, JWT_SECRET, SMTP_*
npm run dev              # hoặc: npm start
```
API chạy tại `http://localhost:3000/api` (kiểm tra: `GET /api/health`).

> Không commit file `.env` (đã nằm trong `.gitignore`).

## Gửi email (SMTP)
Với Gmail: bật xác thực 2 bước → tạo **Mật khẩu ứng dụng** → điền vào `SMTP_PASS`.
Nếu chưa cấu hình SMTP, API vẫn chạy bình thường; email được ghi vào `email_logs` với trạng thái `failed`
và lý do "SMTP chưa được cấu hình" (có thể gửi lại sau bằng `POST /api/email-logs/:id/retry`).

## Phân quyền
| Vai trò trên công việc | Xem | Sửa / đổi trạng thái | Xóa | Giao việc & quản lý chia sẻ |
|---|---|---|---|---|
| Người tạo (owner) | ✔ | ✔ | ✔ | ✔ |
| Người được giao (assignee) | ✔ | ✔ | ✘ | ✘ |
| Editor (được chia sẻ) | ✔ | ✔ | ✘ | ✘ |
| Viewer (được chia sẻ) | ✔ | ✘ | ✘ | ✘ |

Nếu một người vừa được giao vừa được chia sẻ, hệ thống lấy **quyền cao nhất**. Người không có quyền xem nhận `404`.

## Danh sách endpoint
Các API (trừ register/login) cần header `Authorization: Bearer <token>`.

| Nhóm | Method & Endpoint |
|---|---|
| Auth | `POST /auth/register`, `POST /auth/login`, `GET /auth/me`, `PUT /auth/me`, `PUT /auth/change-password` |
| Users | `GET /users/search?q=`, `GET /users/:id` |
| Tasks | `GET /tasks`, `POST /tasks`, `GET/PUT/DELETE /tasks/:id`, `PATCH /tasks/:id/status`, `GET /tasks/:id/activities` |
| Assignees | `GET/POST /tasks/:id/assignees`, `PATCH/DELETE /tasks/:id/assignees/:userId` |
| Shares | `GET/POST /tasks/:id/shares`, `PATCH/DELETE /tasks/:id/shares/:shareId` |
| Notifications | `GET /notifications`, `GET /notifications/unread-count`, `PATCH /notifications/:id/read`, `PATCH /notifications/read-all` |
| Statistics | `GET /statistics/tasks`, `/statistics/assignments`, `/statistics/deadlines` |
| Email | `GET /tasks/:id/email-logs`, `POST /email-logs/:id/retry` |

Tham số `GET /tasks`: `scope=created|assigned|shared`, `status`, `priority`, `q`, `assigneeId`, `sortBy=dueDate|priority|createdAt`, `order=asc|desc`, `page`, `limit`.

## Ví dụ nhanh (curl)
```bash
curl -X POST localhost:3000/api/auth/register -H "Content-Type: application/json" \
  -d '{"fullName":"Nguyen Van A","email":"a@example.com","password":"123456"}'

TOKEN=<token nhận được>
curl -X POST localhost:3000/api/tasks -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"title":"Viết báo cáo","dueDate":"2026-12-31T10:00:00Z","priority":"high"}'
```

## Bảo mật đã áp dụng
- Mật khẩu băm bằng bcrypt, không bao giờ trả về trong response.
- JWT xác thực mọi API riêng tư; quyền được kiểm tra ở backend trên từng công việc.
- Biến môi trường cho MongoDB, JWT secret, SMTP.
- Validate đầu vào (express-validator), escape HTML trong email, thông báo lỗi 500 không lộ chi tiết.
- Email gửi từ backend, có log trạng thái; gửi lại dùng cập nhật nguyên tử và giới hạn số lần thử để tránh gửi trùng.

## Nhắc việc tự động
`src/jobs/reminderJob.js` chạy theo `REMINDER_CRON` (mặc định 15 phút/lần), nhắc các việc chưa hoàn thành có hạn trong `REMINDER_HOURS_BEFORE` giờ tới (mặc định 24). Mỗi việc chỉ nhắc một lần; đổi hạn thì nhắc lại.
