import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:el_asli/core/theme/app_theme.dart';
import 'package:el_asli/core/utils/router.dart';
import 'package:el_asli/data/models/product_model.dart';
import 'package:el_asli/data/providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait uniquement
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar transparente
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Hive
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ProductModelAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ScanResultAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(ScanTypeAdapter());

  await Hive.openBox('settings');
  await Hive.openBox<ScanResult>('scan_history');
  await Hive.openBox('cache');

  runApp(const ProviderScope(child: ElAsliApp()));
}

class ElAsliApp extends ConsumerWidget {
  const ElAsliApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'El Asli —فيري ميد',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('ar', 'TN'),
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
    );
  }
}
