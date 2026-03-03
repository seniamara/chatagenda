import 'package:chatboot/screens/auth/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/task_service.dart';
import 'controllers/auth_controller.dart';
import 'controllers/task_controller.dart';
import 'controllers/chat_controller.dart';
import 'core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    print('✅ Firebase inicializado');
  } catch (e) {
    print('❌ Erro Firebase: $e');
  }
  
  // Registrar serviços GetX
  Get.put(AuthService(), permanent: true);
  Get.put(TaskService(), permanent: true);
  
  // Registrar controllers GetX
  Get.put(AuthController(), permanent: true);
  Get.put(TaskController(), permanent: true);
  Get.put(ChatController(), permanent: true);
  
  runApp(
    // Provider DEVE envolver todo o app
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GetMaterialApp(
          title: 'ChatAgenda',
          theme: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              secondary: Colors.orange,
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            primaryColor: Colors.blue[700],
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              secondary: Colors.orange,
            ),
          ),
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
          defaultTransition: Transition.fade,
        );
      },
    );
  }
}