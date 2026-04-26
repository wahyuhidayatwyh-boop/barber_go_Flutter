import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'notification_service.dart'; // Import service notifikasi

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Notifikasi saat aplikasi pertama kali jalan
  await NotificationService.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Barber Go',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFFDFBF7), 
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFD4AF37),
              primary: const Color(0xFFD4AF37),
              surface: const Color(0xFFFFFFFF),
              onSurface: const Color(0xFF2C2C2C),
            ),
          ),

          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.dark,
              seedColor: const Color(0xFFD4AF37),
              primary: const Color(0xFFD4AF37),
              surface: const Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          
          home: const SplashScreen(),
        );
      },
    );
  }
}
