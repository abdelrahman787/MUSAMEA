// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'di/app_providers.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تقييد الاتجاه إلى الرأسي فقط
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // تهيئة التبعيات
  await AppDependencies.instance.initialize();

  runApp(const MusaamiApp());
}

class MusaamiApp extends StatefulWidget {
  const MusaamiApp({super.key});

  @override
  State<MusaamiApp> createState() => _MusaamiAppState();
}

class _MusaamiAppState extends State<MusaamiApp> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مُسَمِّع',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: _showSplash
          ? SplashScreen(
              onComplete: () => setState(() => _showSplash = false),
            )
          : const HomeScreen(),
    );
  }
}
