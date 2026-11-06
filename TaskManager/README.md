# TaskManager – Flutter

Ứng dụng quản lý và giao công việc nhóm (Flutter + Provider + http).

## Chạy ứng dụng

Repo chỉ chứa mã nguồn `lib/` và `pubspec.yaml`. Lần đầu, sinh các thư mục nền tảng (android, ios…):

```bash
cd TaskManager
flutter create --project-name task_manager .
flutter pub get
flutter run
```

### Cấu hình địa chỉ API

Sửa `lib/utils/constants.dart` → `kBaseUrl`:

- Android emulator: `http://10.0.2.2:3000/api` (mặc định)
- Máy thật: `http://<IP-máy-chạy-backend>:3000/api`

Android chặn HTTP thường. Với môi trường dev, thêm vào `android/app/src/main/AndroidManifest.xml`,
thẻ `<application ...>`:

```xml
android:usesCleartextTraffic="true"
```

Nhớ chạy backend (`api/`) trước khi mở app.

## PHẦN B – Quản lý công việc

- Danh sách công việc: phân loại Tất cả / Của tôi / Được giao cho tôi / Được chia sẻ
- Tìm kiếm theo tên; lọc theo trạng thái, mức độ ưu tiên; sắp xếp theo hạn, ưu tiên, thời gian tạo
- Chi tiết công việc, thêm, chỉnh sửa, xóa (có hộp thoại xác nhận)
- Đổi trạng thái: chưa thực hiện / đang thực hiện / đã hoàn thành
- Nút Sửa / Xóa / đổi trạng thái chỉ hiện theo quyền (backend vẫn kiểm tra quyền)
- Hiển thị trạng thái tải dữ liệu, lỗi và nút thử lại

## PHẦN A – Tài khoản & xác thực

- Đăng nhập, đăng ký (họ tên, email, mật khẩu, xác nhận mật khẩu)
- Lưu token bằng `shared_preferences`, tự đăng nhập lại khi mở app
- Màn hình Cá nhân: xem/cập nhật họ tên, đổi mật khẩu, đăng xuất
