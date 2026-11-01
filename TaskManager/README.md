# TaskManager (Flutter)

Ứng dụng quản lý và giao công việc nhóm – giao diện Flutter, kết nối REST API Node.js/Express + MongoDB (thư mục `api`).

## Yêu cầu
- Flutter SDK >= 3.10 (Dart >= 3.0)
- API đang chạy (xem `api/README.md`)

## Chạy ứng dụng
```bash
flutter pub get
flutter run                                  # máy ảo Android dùng sẵn http://10.0.2.2:3000/api
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api   # điện thoại thật: dùng IP LAN của máy chạy API
```

## Cấu hình Android (bắt buộc để gọi API http://)
Trong `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<application
    android:usesCleartextTraffic="true"
    ... >
```
(`usesCleartextTraffic` chỉ dùng khi phát triển; khi triển khai thật phải dùng HTTPS.)

## Cấu trúc `lib/`
`models/` · `services/` (gọi API) · `providers/` (auth, thông báo) · `screens/` · `widgets/` · `utils/`
