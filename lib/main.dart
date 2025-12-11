import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_hui_app/core/router/app_router.dart';
import 'package:so_hui_app/core/theme/app_theme.dart';
import 'package:so_hui_app/core/providers/providers.dart';
import 'package:so_hui_app/common/utils/seed_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Optional: Seed sample data for demo
    // Uncomment the lines below to add sample data on first run
    /*
    try {
      final huiRepo = ref.read(huiRepositoryProvider);
      final contributionRepo = ref.read(contributionRepositoryProvider);
      final calcService = ref.read(huiCalculationServiceProvider);
      
      final seedService = SeedDataService(
        huiRepo: huiRepo,
        contributionRepo: contributionRepo,
        calcService: calcService,
      );
      
      await seedService.seedSampleData();
    } catch (e) {
      debugPrint('Error seeding data: $e');
    }
    */

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Đang khởi tạo...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Sổ Hụi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      routerConfig: AppRouter.router,
    );
  }
}
