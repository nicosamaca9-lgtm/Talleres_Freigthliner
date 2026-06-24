import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'providers/auth_provider.dart';
<<<<<<< HEAD
import 'providers/comment_provider.dart';
=======
import 'providers/vehicle_provider.dart';
>>>>>>> 68c622641bc79bfc97d4d433ac82183340865ef5

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
<<<<<<< HEAD
        ChangeNotifierProvider(create: (_) => CommentProvider()),
=======
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
>>>>>>> 68c622641bc79bfc97d4d433ac82183340865ef5
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return MaterialApp.router(
          title: 'TF Centro Automotriz',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          routerConfig: createAppRouter(authProvider),
        );
      },
    );
  }
}
