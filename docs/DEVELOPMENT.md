# Hướng Dẫn Phát Triển - Sổ Hụi

## Yêu cầu hệ thống

- Flutter SDK ≥ 3.22.0
- Dart SDK ≥ 3.10.3
- Android Studio / VS Code (với Flutter extension)
- Xcode (cho iOS, chỉ trên macOS)

## Cài đặt môi trường

### 1. Cài đặt Flutter

Tham khảo hướng dẫn chính thức: https://flutter.dev/docs/get-started/install

### 2. Kiểm tra môi trường

```bash
flutter doctor
```

## Cài đặt dự án

### 1. Clone repository

```bash
git clone https://github.com/duybv18/so_hui.git
cd so_hui
```

### 2. Cài đặt dependencies

```bash
flutter pub get
```

### 3. Chạy code generation

Drift cần generate code từ database schema:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Hoặc để watch và tự động generate khi có thay đổi:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

### 4. Chạy ứng dụng

```bash
# Android
flutter run

# iOS (chỉ trên macOS)
flutter run -d ios

# Web
flutter run -d chrome

# Chọn device cụ thể
flutter devices
flutter run -d <device_id>
```

## Cấu trúc dự án

```
lib/
├── core/                   # Core functionality
│   ├── database/          # Drift database definition
│   │   └── database.dart  # Main database file
│   ├── providers/         # Riverpod providers
│   ├── router/           # GoRouter configuration
│   └── theme/            # App theme (Material 3)
├── common/               # Shared components
│   ├── utils/           # Utilities
│   │   ├── currency_formatter.dart
│   │   ├── date_formatter.dart
│   │   └── validators.dart
│   └── widgets/         # Reusable widgets
│       ├── empty_state.dart
│       ├── hui_card.dart
│       └── stats_card.dart
├── features/            # Feature modules
│   ├── hui/            # Hui management
│   │   ├── data/       # Repository
│   │   ├── domain/     # Business logic
│   │   └── presentation/  # UI screens
│   ├── contributions/  # Contribution tracking
│   ├── reports/       # Reports & analytics
│   └── settings/      # App settings
├── models/            # Data models
│   └── models.dart
└── main.dart         # App entry point
```

## Database Schema

### Tables

1. **hui_groups** - Dây hụi
   - Lưu thông tin cơ bản về dây hụi
   - Loại hụi: fixed (hụi chết) hoặc interest (hụi sống)
   - Tần suất: daily, weekly, monthly

2. **contributions** - Kỳ góp
   - Tự động sinh ra khi tạo dây hụi mới
   - Theo dõi trạng thái đã góp/chưa góp
   - Lưu số tiền thực góp

3. **hui_winners** - Người hốt
   - Chỉ dùng cho hụi sống (interest type)
   - Lưu thông tin lãi suất và số tiền nhận

### Migrations

Drift tự động tạo database và các bảng khi chạy lần đầu.
Để thêm migration mới, chỉnh sửa `schemaVersion` và thêm logic trong `onUpgrade`.

## Testing

### Chạy tất cả tests

```bash
flutter test
```

### Chạy test cụ thể

```bash
flutter test test/hui_calculation_test.dart
```

### Test coverage

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Build

### Android APK

```bash
flutter build apk --release
```

### Android App Bundle (cho Google Play)

```bash
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

## Linting & Formatting

### Chạy linter

```bash
flutter analyze
```

### Format code

```bash
dart format .
```

## Troubleshooting

### Code generation không hoạt động

```bash
# Xóa cache và build lại
flutter clean
flutter pub get
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Database không khởi tạo

- Kiểm tra xem đã chạy code generation chưa
- Xóa app và cài lại để tạo database mới
- Kiểm tra logs: `flutter logs`

### Import errors

- Chạy `flutter pub get`
- Restart IDE
- Invalidate caches (Android Studio)

## Debugging

### Debug mode

```bash
flutter run --debug
```

### Profile mode (để đo performance)

```bash
flutter run --profile
```

### DevTools

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

## Commit Convention

```
feat: Thêm tính năng mới
fix: Sửa bug
docs: Cập nhật documentation
style: Format code, không thay đổi logic
refactor: Refactor code
test: Thêm/sửa tests
chore: Cập nhật dependencies, config
```

## Useful Commands

```bash
# List devices
flutter devices

# Clear cache
flutter clean

# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated

# Run in release mode
flutter run --release

# Hot reload (r), hot restart (R), quit (q)
```

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Drift Documentation](https://drift.simonbinder.eu/)
- [Riverpod Documentation](https://riverpod.dev/)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Material 3 Design](https://m3.material.io/)

## FAQ

**Q: Tại sao dùng Drift thay vì sqflite?**
A: Drift cung cấp type-safe queries, migrations tốt hơn và DX tốt hơn với code generation.

**Q: Làm sao để thêm field mới vào database?**
A: 
1. Thêm column vào table trong `database.dart`
2. Tăng `schemaVersion`
3. Thêm migration logic trong `onUpgrade`
4. Chạy `dart run build_runner build`

**Q: Làm sao để reset database trong development?**
A: Xóa app và cài lại, hoặc clear app data trong settings.

**Q: App có hoạt động offline hoàn toàn không?**
A: Có, app không cần internet và lưu trữ 100% local bằng SQLite.
