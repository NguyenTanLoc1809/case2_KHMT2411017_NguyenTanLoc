 # HƯỚNG DẪN CHẠY & NỘP BÀI – CASE 2

> Tên repo GitHub: `case2_<mssv>_<hoten>` (viết thường, không dấu, ví dụ `case2_21110001_nguyenvana`).
> Trong repo có 2 thư mục: `api` (Node.js) và `TaskManager` (Flutter), cùng file `README.md` ở gốc ghi MSSV + Họ tên.

---
## 1. Chạy thử toàn bộ

### Backend
```bash
cd api
npm install
cp .env.example .env     # sửa MONGODB_URI, JWT_SECRET, SMTP_*
npm run dev
```
Cần MongoDB đang chạy (cài local hoặc dùng MongoDB Atlas, dán chuỗi kết nối vào `MONGODB_URI`).

### Flutter
Gói nộp **không chứa** thư mục `android/`, `ios/`... (do công cụ `flutter create` sinh ra), nên làm theo thứ tự:
```bash
# 1. Tạo project Flutter (tên package phải là chữ thường + gạch dưới)
flutter create --project-name task_manager TaskManager
# 2. Chép đè lib/, test/, pubspec.yaml, .gitignore, README.md, assets/ từ gói này vào TaskManager/
# 3. Cài thư viện và chạy
cd TaskManager
flutter pub get
flutter analyze          # kiểm tra lỗi/warning
flutter run
```
Sau đó sửa `android/app/src/main/AndroidManifest.xml` (thêm quyền INTERNET và `android:usesCleartextTraffic="true"` trong thẻ `<application>`), vì API dùng `http://`.
- Máy ảo Android: app tự dùng `http://10.0.2.2:3000/api`.
- Điện thoại thật: `flutter run --dart-define=API_BASE_URL=http://<IP-LAN-máy-tính>:3000/api`.

---
## 2. Quy trình Git theo yêu cầu đề

**Lần đầu (commit & push đầu tiên = khởi tạo repo):**
```bash
git clone https://github.com/<tai-khoan>/case2_<mssv>_<hoten>.git   # repo đã tạo trống trên GitHub
cd case2_<mssv>_<hoten>
# Chép README.md (đã điền MSSV, Họ tên) vào đây
git add README.md
git commit -m "Khởi tạo repo: thêm README thông tin cá nhân"
git push -u origin main
```
**Khởi tạo project (trên main):**
```bash
# Chép api/ vào repo (chỉ phần khung: package.json, .gitignore, .env.example, src/server.js, src/app.js, src/config, src/utils, src/middleware/errorMiddleware.js, validateMiddleware.js)
git add api && git commit -m "Khởi tạo project backend Node.js (api)" && git push
# Tạo Flutter project TaskManager (xem mục 1), chép các file khung: pubspec.yaml, lib/main.dart, app.dart, utils/, services/api_client.dart
git add TaskManager && git commit -m "Khởi tạo project Flutter (TaskManager)" && git push
```
**Mỗi chức năng lớn một nhánh; xong từng chức năng nhỏ thì commit + push:**
```bash
git checkout main && git pull
git checkout -b feature/A-auth
# ... làm xong "Đăng ký" ...
git add <các file> && git commit -m "Thêm chức năng đăng ký tài khoản" && git push -u origin feature/A-auth
# ... làm xong "Đăng nhập" ... commit, push tiếp
# Xong cả nhóm A: tạo Pull Request trên GitHub -> merge vào main, rồi sang nhánh B:
git checkout main && git pull && git checkout -b feature/B-tasks
```

### Gợi ý chia commit theo nhánh (đường dẫn trong `api/src/...` và `TaskManager/lib/...`)

| Nhánh | Commit (chức năng nhỏ) | File chính |
|---|---|---|
| `feature/A-auth` | Đăng ký | `models/User.js`, `validators/authValidator.js`, `controllers/authController.js` (register), `routes/authRoutes.js` · Flutter: `models/user.dart`, `services/auth_service.dart`, `providers/auth_provider.dart`, `screens/auth/register_screen.dart` |
| | Đăng nhập + xác thực token | `middleware/authMiddleware.js`, `authController.login/getMe` · `screens/auth/login_screen.dart`, `app.dart`, `screens/home_screen.dart` |
| | Đăng xuất | `AuthProvider.logout`, nút ở `profile_screen.dart` |
| | Xem/cập nhật hồ sơ | `authController.updateMe` · `profile_screen.dart` (phần hồ sơ) |
| | Đổi mật khẩu | `authController.changePassword` · dialog đổi mật khẩu |
| `feature/B-tasks` | Xem danh sách + chi tiết | `models/Task.js`, `services/taskService.js`, `middleware/permissionMiddleware.js`, `controllers/taskController.js` (list/get), `routes/taskRoutes.js` · `models/task.dart`, `services/task_service.dart`, `task_list_screen.dart`, `task_detail_screen.dart`, `task_card.dart`, badges |
| | Thêm / sửa / xóa | `taskController` create/update/delete, `validators/taskValidator.js` · `task_form.dart`, `task_create_screen.dart`, `task_edit_screen.dart` |
| | Đổi trạng thái, ưu tiên, ngày | `taskController.updateStatus` · thanh chọn trạng thái ở màn chi tiết |
| | Tìm kiếm, lọc, sắp xếp | `listTasks` + `listQuery` · `_FilterSheet` trong `task_list_screen.dart` |
| `feature/C-assign-share` | Tìm người dùng | `controllers/userController.js`, `routes/userRoutes.js` · `user_service.dart`, `user_selector.dart` |
| | Giao việc nhiều người + phụ trách chính | `controllers/assignmentController.js`, `routes/assignmentRoutes.js` · `assign_task_screen.dart` |
| | Chia sẻ + phân quyền viewer/editor | `models/TaskShare.js`, `controllers/taskShareController.js`, `routes/taskShareRoutes.js` · `task_share.dart`, `task_share_service.dart`, `task_sharing_screen.dart` |
| | Lịch sử hoạt động | `models/TaskActivity.js`, `logActivity`, `getActivities` · `task_activity.dart` |
| `feature/D-notification-email` | Thông báo trong app | `models/Notification.js`, `services/notificationService.js`, `controllers/notificationController.js` · `notification.dart`, `notification_service.dart`, `notification_provider.dart`, `notification_screen.dart` |
| | Email giao việc / chia sẻ / đổi hạn / hoàn thành | `config/email.js`, `models/EmailLog.js`, `services/emailService.js`, `utils/emailTemplates.js` |
| | Lịch sử email + gửi lại | `controllers/emailLogController.js`, `routes/emailLogRoutes.js` · `email_log.dart`, phần email ở màn chi tiết |
| | Nhắc việc trước hạn 24h | `jobs/reminderJob.js` |
| `feature/E-statistics` | Thống kê | `controllers/statisticsController.js`, `routes/statisticsRoutes.js` · `statistics_service.dart`, phần thống kê trong `profile_screen.dart` |

> Lưu ý: vì code được viết liền mạch, một số file tham chiếu sang chức năng ở nhánh sau (ví dụ `taskController` gọi `notificationService`, `app.js` mount đủ route – các dòng đã gắn nhãn `[A]`…`[E]`). Khi commit từng nhánh, bạn có thể comment tạm các dòng của nhánh chưa làm; sau khi merge hết, chạy lại toàn bộ để kiểm thử tích hợp.

---
## 3. Danh sách kiểm thử (Buổi 3)
1. Đăng ký 3 tài khoản A, B, C → đăng nhập → đăng xuất.
2. A tạo công việc → B, C không thấy (đúng).
3. A giao việc cho B (phụ trách chính) và C → B, C thấy trong tab "Được giao cho tôi", có thông báo trong app + email.
4. A tạo việc khác, chia sẻ cho B (viewer), C (editor): B không sửa được (403), C sửa/đổi trạng thái được nhưng không xóa/chia sẻ lại được.
5. A đổi hạn → B, C nhận thông báo + email; đổi trạng thái hoàn thành → email "hoàn thành".
6. Thu hồi quyền của B → B không còn thấy công việc.
7. Tìm kiếm, lọc theo trạng thái/ưu tiên/người phụ trách, sắp xếp theo hạn/ưu tiên/ngày tạo.
8. Màn "Cá nhân": số liệu thống kê, việc sắp đến hạn / quá hạn.
9. Tắt SMTP / sai mật khẩu SMTP → email ghi `failed`; sửa lại cấu hình rồi bấm "Gửi lại" ở màn chi tiết.

## 4. Những gì mình CHƯA kiểm chạy được
Môi trường soạn bài không có Flutter SDK, MongoDB và internet, nên: backend đã được kiểm tra cú pháp và test riêng phần phân quyền/escape email; **Flutter chưa được biên dịch**. Hãy chạy `flutter analyze` và `npm run dev` ở máy bạn; nếu có lỗi/cảnh báo, gửi nội dung lỗi để mình sửa tiếp.
