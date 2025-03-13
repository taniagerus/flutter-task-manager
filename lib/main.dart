import 'package:flutter/material.dart';
import 'package:task_manager/features/tasks/presentation/pages/home_page.dart';
// import 'package:task_manager/features/auth/presentation/pages/welcome_page.dart'; // Comment this out

// Змінна для швидкого перемикання між сторінками під час розробки
const bool showHomePage = true; // змініть на false щоб побачити WelcomePage

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F80ED)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FF),
      ),
      home: const HomePage(),
    );
  }
}
