# 📱 Travel Buddy - Ứng dụng Quản lý & Lên lịch trình Du lịch Nhóm

Một ứng dụng mobile được phát triển bằng Flutter giúp các nhóm bạn bè và gia đình cùng nhau lên kế hoạch đi chơi, chia sẻ vị trí và quản lý chi phí chung một cách dễ dàng và minh bạch.

## 📖 Mô tả dự án
**Travel Buddy** là đồ án/dự án nhóm (4 thành viên) nhằm giải quyết vấn đề quản lý thông tin và tài chính rời rạc khi đi du lịch chung. Ứng dụng cung cấp giao diện thân thiện, mượt mà trên cả hai nền tảng Android và iOS nhờ sức mạnh của Flutter.

### ✨ Các tính năng chính:
* **Quản lý Nhóm & Tài khoản:** Đăng nhập an toàn với Firebase, cho phép tạo chuyến đi và mời bạn bè tham gia nhóm nhanh chóng qua link/mã QR.
* **Lên lịch trình (Itinerary):** Hiển thị danh sách các điểm đến, chuyến bay và lên lịch trình chi tiết (timeline) theo từng ngày.
* **Bản đồ & Vị trí:** Tích hợp Google Maps để theo dõi vị trí trực tiếp (realtime) của các thành viên và cảnh báo SOS khi đi lạc.
* **Tài chính & Giao tiếp:** Ghi chép chi phí chung, thuật toán tự động tính toán chia tiền (ai nợ ai) và tích hợp khung chat nhóm.

### 🛠 Công nghệ sử dụng:
* **Framework:** Flutter
* **Ngôn ngữ:** Dart
* **Backend/Database:** Firebase (Authentication, Firestore, Realtime Database, Cloud Storage)
* **State Management:** Riverpod
* **Routing:** GoRouter
* **Data Models:** Freezed, JSON Serializable

---

## 🚀 Hướng dẫn cài đặt

Để chạy ứng dụng này trên máy cá nhân, vui lòng làm theo các bước sau:

### Yêu cầu hệ thống (Prerequisites)
1. Đã cài đặt [Flutter SDK](https://docs.flutter.dev/get-started/install) (phiên bản >= 3.10.0).
2. Đã cài đặt Dart SDK.
3. IDE: [Android Studio](https://developer.android.com/studio) hoặc [Visual Studio Code](https://code.visualstudio.com/) có cài sẵn Flutter & Dart plugins.
4. Máy ảo Android/iOS (Emulator/Simulator) hoặc thiết bị thật đã bật chế độ gỡ lỗi (USB Debugging).
5. Đã cài đặt [Firebase CLI](https://firebase.google.com/docs/cli) để cấu hình kết nối backend.

### Các bước chạy dự án
**Bước 1:** Clone repository này về máy:
```bash
git clone [https://github.com/](https://github.com/)[tên-tài-khoản-github]/travel-buddy.git
cd travel-buddy