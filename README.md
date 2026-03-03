# Sổ Hụi - Ứng Dụng Quản Lý Dây Hụi

Ứng dụng di động giúp quản lý các dây hụi cá nhân (ROSCA - Rotating Savings and Credit Association), theo dõi kỳ góp, tiền góp và dòng tiền một cách dễ dàng. Hoàn toàn offline, không cần kết nối internet.

## ✨ Tính năng chính

### 🎯 Quản lý dây hụi
- Tạo, chỉnh sửa, xóa dây hụi
- Hỗ trợ 2 loại hụi:
  - **Hụi chết** (không lãi): Góp đều, không đấu giá
  - **Hụi sống** (có lãi): Đấu giá, có lãi suất
- Tự động sinh các kỳ góp theo tần suất (ngày/tuần/tháng)

### 💰 Theo dõi kỳ góp
- Đánh dấu đã góp/chưa góp
- Nhập số tiền thực góp
- Ghi chú cho từng kỳ
- Theo dõi kỳ trễ hạn

### 📊 Báo cáo & thống kê
- Tổng đã góp / còn phải góp
- Tiến độ hoàn thành
- Danh sách kỳ trễ hạn
- Biểu đồ dòng tiền
- Dự báo ngày kết thúc

### 🎨 Giao diện
- Material Design 3
- Hỗ trợ chế độ sáng/tối
- Responsive, tối ưu cho mobile
- Animation mượt mà

## 🏗️ Kiến trúc

### Tech Stack
- **Flutter** ≥ 3.22
- **Riverpod** - State management
- **Drift** - SQLite ORM cho local database
- **GoRouter** - Navigation
- **Material 3** - UI framework

### Cấu trúc dự án
```
lib/
  ├── core/
  │   ├── database/      # Drift database definition
  │   ├── providers/     # Riverpod providers
  │   ├── router/        # GoRouter configuration
  │   └── theme/         # Material 3 theme
  ├── common/
  │   ├── widgets/       # Reusable widgets
  │   └── utils/         # Utilities (formatters, validators)
  ├── features/
  │   ├── hui/           # Hui management
  │   │   ├── data/      # Repository
  │   │   ├── domain/    # Business logic
  │   │   └── presentation/  # Screens
  │   ├── contributions/ # Contribution tracking
  │   ├── reports/       # Reports & analytics
  │   └── settings/      # App settings
  └── models/            # Data models
```

### MVVM + Repository Pattern
```
View (Screen) 
  ↓ 
ViewModel (Riverpod Provider) 
  ↓ 
Repository 
  ↓ 
Database (Drift)
```

## 🗄️ Database Schema

### Tables
1. **hui_groups** - Thông tin dây hụi
   - id, name, total_periods, num_members
   - contribution_amount, type (fixed/interest)
   - start_date, frequency, notes

2. **contributions** - Kỳ góp
   - id, hui_group_id, period_number
   - due_date, is_paid, actual_amount, notes

3. **hui_winners** - Người hốt (cho hụi sống)
   - id, contribution_id, winner_name
   - interest_rate, amount_received

## 🚀 Bắt đầu

### Yêu cầu
- Flutter SDK ≥ 3.22
- Dart SDK ≥ 3.10.3

### Cài đặt

1. Clone repository:
```bash
git clone https://github.com/duybv18/so_hui.git
cd so_hui
```

2. Cài đặt dependencies:
```bash
flutter pub get
````

3. Chạy code generation cho Drift:
```bash
dart run build_runner build
```

4. Chạy ứng dụng:
```bash
flutter run
```

### Chạy tests
```bash
flutter test
```

## 📱 Screenshots

*(Screenshots will be added after app is running)*

## 🔄 Quy trình nghiệp vụ

### Hụi chết (Fixed)
```
Mỗi kỳ: Tất cả góp X đồng
Người hốt nhận: X × số thành viên
Không có lãi suất
```

### Hụi sống (Interest)
```
Mỗi kỳ: Đấu giá lãi suất
Người hốt trả lãi Y%
Người hốt nhận: (X × số thành viên) - lãi
Lãi chia cho các thành viên còn lại
```

## 📝 TODO / Tính năng tương lai

- [ ] Export dữ liệu ra CSV/Excel
- [ ] Cloud backup
- [ ] Push notifications cho kỳ sắp đến hạn
- [ ] Quản lý nhiều người trong dây hụi
- [ ] Chia sẻ thông tin dây hụi
- [ ] In báo cáo

## 🤝 Đóng góp

Contributions, issues và feature requests đều được chào đón!

## 📄 License

This project is licensed under the MIT License.

## 👤 Tác giả

**duybv18**

---

Made with ❤️ using Flutter

