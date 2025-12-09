# Quick Start Guide - Sổ Hụi

## 🚀 Get Started in 5 Minutes

### Prerequisites
- Flutter SDK ≥ 3.22
- Dart SDK ≥ 3.10

### Installation

```bash
# 1. Clone and navigate
git clone https://github.com/duybv18/so_hui.git
cd so_hui

# 2. Install dependencies
flutter pub get

# 3. Generate database code
dart run build_runner build --delete-conflicting-outputs

# 4. Run the app
flutter run
```

### First Launch

The app will start with an empty dashboard. You have two options:

#### Option 1: Create Your Own Hui
1. Tap the **"Tạo dây hụi"** button
2. Fill in the form
3. Start tracking your contributions

#### Option 2: Load Sample Data
1. Open `lib/main.dart`
2. Uncomment lines 15-30 (the seed data section)
3. Hot restart the app
4. You'll see 3 sample hui groups with data

## 📱 App Navigation

```
Dashboard (Home)
├── Tạo dây hụi → Hui Form (Create)
├── Xem tất cả → Hui List
│   └── [Hui Card] → Hui Detail
│       ├── Edit → Hui Form (Edit)
│       ├── [Period] → Contribution Detail
│       └── Báo cáo → Reports
└── Cài đặt → Settings
```

## 🎯 Common Tasks

### Create a Hui
```
Dashboard → [+] Button → Fill Form → Save
```

### Mark a Period as Paid
```
Dashboard → [Hui Card] → [Period] → Toggle "Đã góp" → Save
```

### View Reports
```
Dashboard → [Hui Card] → "Báo cáo" Button
```

### Add Interest Winner (for Hụi sống)
```
Contribution Detail → Enter Winner Name → Enter Interest % → Save
```

## 🔧 Development Commands

```bash
# Watch mode for code generation
dart run build_runner watch

# Run tests
flutter test

# Run specific test
flutter test test/hui_calculation_test.dart

# Analyze code
flutter analyze

# Format code
dart format .

# Clean and rebuild
flutter clean && flutter pub get
```

## 📁 Key Files

```
lib/
├── main.dart                          # App entry point
├── core/
│   ├── database/database.dart         # Database schema
│   ├── router/app_router.dart         # Navigation routes
│   └── theme/app_theme.dart           # UI theme
├── features/
│   ├── hui/presentation/
│   │   ├── dashboard_screen.dart      # Home screen
│   │   ├── hui_list_screen.dart       # List all hui
│   │   ├── hui_form_screen.dart       # Create/edit hui
│   │   └── hui_detail_screen.dart     # Hui details
│   ├── contributions/presentation/
│   │   └── contribution_detail_screen.dart  # Period details
│   └── reports/presentation/
│       └── reports_screen.dart        # Analytics
└── models/models.dart                 # Data models
```

## 🎨 UI Customization

### Change Theme Color
Edit `lib/core/theme/app_theme.dart`:
```dart
ColorScheme.fromSeed(
  seedColor: Colors.teal,  // Change this color
  brightness: Brightness.light,
)
```

### Change App Title
Edit `lib/main.dart`:
```dart
MaterialApp.router(
  title: 'Sổ Hụi',  // Change this
  ...
)
```

## 📊 Database

### Location
```
Android: /data/data/com.example.so_hui_app/databases/so_hui.sqlite
iOS: ~/Library/Application Support/so_hui.sqlite
```

### View Database (Android)
```bash
adb exec-out run-as com.example.so_hui_app cat databases/so_hui.sqlite > so_hui.db
sqlite3 so_hui.db
```

### Reset Database
- Uninstall and reinstall the app
- Or clear app data in device settings

## 🐛 Troubleshooting

### Error: "dart:ffi" not found
```bash
# Solution: Run code generation
dart run build_runner build --delete-conflicting-outputs
```

### Error: "Table not found"
```bash
# Solution: Clean and rebuild
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### UI not updating
```bash
# Solution: Hot restart (Shift + R in terminal)
# Or restart the app completely
```

### Tests failing
```bash
# Make sure all dependencies are installed
flutter pub get
# Run tests with verbose output
flutter test --verbose
```

## 🎓 Learning Path

1. **Start Here**: Read `README.md`
2. **Setup**: Follow `docs/DEVELOPMENT.md`
3. **Understand Business**: Read `docs/BUSINESS_RULES.md`
4. **Explore Code**: Check `docs/IMPLEMENTATION_SUMMARY.md`
5. **Run Tests**: `flutter test`
6. **Modify & Experiment**: Make changes and see results

## 💡 Pro Tips

1. **Use Hot Reload**: Press `r` after code changes
2. **Use Hot Restart**: Press `R` to restart app with state reset
3. **Enable Seed Data**: Uncomment seed code for quick testing
4. **Dark Mode**: Change in Settings or use system setting
5. **Watch Mode**: Use `build_runner watch` for auto code gen

## 🔗 Quick Links

- [Flutter Docs](https://flutter.dev/docs)
- [Drift Docs](https://drift.simonbinder.eu/)
- [Riverpod Docs](https://riverpod.dev/)
- [Material 3](https://m3.material.io/)

## 📞 Need Help?

1. Check error messages carefully
2. Review documentation files
3. Look at test files for examples
4. Check inline code comments
5. Search Flutter/Drift documentation

---

**Happy Coding! 🚀**
