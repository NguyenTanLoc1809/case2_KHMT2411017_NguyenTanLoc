# API – Quản lý và giao công việc nhóm

Node.js • Express • MongoDB (Mongoose) • JWT

## Cài đặt & chạy

```bash
cd api
npm install
cp .env.example .env     # rồi điền mật khẩu MongoDB và JWT_SECRET vào .env
npm start                # hoặc: npm run dev
```

> Không commit file `.env`. Chuỗi kết nối, JWT secret đều lấy từ biến môi trường.

## Biến môi trường

| Biến | Ý nghĩa |
|------|---------|
| `PORT` | Cổng chạy server (mặc định 3000) |
| `MONGODB_URI` | Chuỗi kết nối MongoDB Atlas |
| `JWT_SECRET` | Chuỗi bí mật ký JWT |
| `JWT_EXPIRES_IN` | Thời hạn token (mặc định 7d) |

## Định dạng phản hồi

```json
{ "success": true, "message": "...", "data": { } }
{ "success": false, "message": "...", "errors": ["..."] }
```

## PHẦN A – Tài khoản & xác thực

| Method | Endpoint | Chức năng |
|--------|----------|-----------|
| POST | `/api/auth/register` | Đăng ký (fullName, email, password) |
| POST | `/api/auth/login` | Đăng nhập (email, password) → token |
| GET  | `/api/auth/me` | Thông tin người dùng hiện tại |
| PUT  | `/api/auth/me` | Cập nhật họ tên / avatarUrl |
| PUT  | `/api/auth/change-password` | Đổi mật khẩu |
| GET  | `/api/users/search?q=` | Tìm người dùng theo tên/email |
| GET  | `/api/users/:id` | Thông tin công khai của người dùng |

## PHẦN B – Quản lý công việc

| Method | Endpoint | Chức năng | Quyền cần có |
|--------|----------|-----------|--------------|
| GET    | `/api/tasks` | Danh sách công việc có quyền truy cập | đăng nhập |
| POST   | `/api/tasks` | Tạo công việc | đăng nhập |
| GET    | `/api/tasks/:id` | Chi tiết công việc | xem |
| PUT    | `/api/tasks/:id` | Cập nhật thông tin | owner / editor |
| PATCH  | `/api/tasks/:id/status` | Đổi trạng thái | owner / editor / người được giao |
| DELETE | `/api/tasks/:id` | Xóa công việc | chỉ owner (người tạo) |
| GET    | `/api/tasks/:id/activities` | Lịch sử hoạt động | xem |

Tham số lọc cho `GET /api/tasks`:
`scope=created|assigned|shared`, `status=todo|in_progress|completed`, `priority=low|medium|high`,
`q` (tìm theo tên), `assigneeId`, `sortBy=dueDate|priority|createdAt`, `order=asc|desc`.

Mỗi công việc trả về kèm `myRole` (owner/editor/assignee/viewer) và `permissions`
(`canEdit`, `canUpdateStatus`, `canDelete`, `canManageSharing`). Phân quyền kiểm tra ở backend
(viewer không sửa được; editor không xóa được công việc).

Các API riêng tư gửi kèm header `Authorization: Bearer <token>`.
Mật khẩu được băm bằng `bcryptjs`, không bao giờ trả về trong response.
