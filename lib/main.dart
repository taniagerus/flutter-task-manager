import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:task_manager/features/tasks/presentation/pages/home_page.dart';
import 'package:task_manager/features/auth/presentation/pages/welcome_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:task_manager/features/auth/domain/usecases/sign_in.dart';
import 'package:task_manager/features/auth/domain/usecases/sign_up.dart';
import 'package:task_manager/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:task_manager/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:task_manager/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:task_manager/features/auth/presentation/pages/login_page.dart';
import 'package:task_manager/features/auth/wrapper.dart';

// Змінна для швидкого перемикання між сторінками під час розробки
const bool showHomePage = true; // змініть на false щоб побачити WelcomePage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Додаємо опції для Android
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyCjappXHCj9kZQ5bbAgR-ncZEDjFlx2TXg',
      appId: '1:943717936587:android:e10abf14f973ec9377da4e',
      messagingSenderId: '943717936587',
      projectId: 'flutter-task-6ae23',
      storageBucket: 'flutter-task-6ae23.firebasestorage.app',
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSourceImpl(),
    );

    return BlocProvider(
      create: (context) => AuthBloc(
        signIn: SignIn(authRepository),
        signUp: SignUp(authRepository),
        signInWithGoogle: SignInWithGoogle(authRepository),
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Task Manager',
        navigatorObservers: [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F80ED)),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF5F7FF),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2F80ED), width: 1.5),
            ),
          ),
        ),
        home: const Wrapper(),
      ),
    );
  }
}
