import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Ініціалізуємо Google Sign In з мінімальними налаштуваннями
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Показуємо діалог вибору акаунта Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      // Якщо користувач скасував вхід
      if (googleUser == null) {
        return null;
      }

      // Отримуємо дані автентифікації
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Створюємо обліковий запис Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Входимо в Firebase
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print('Google Sign-In error: ${e.toString()}');
      
      // Handle specific error codes
      if (e.toString().contains('12500')) {
        throw Exception('Перевірте наявність та актуальність Google Play Services на вашому пристрої');
      } else {
        throw Exception('Помилка входу через Google: ${e.toString()}');
      }
    }
  }
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      // Реєстрація
      case 'weak-password':
        return 'Пароль занадто слабкий. Використовуйте мінімум 6 символів.';
      case 'email-already-in-use':
        return 'Обліковий запис з цією електронною поштою вже існує.';
      case 'invalid-email':
        return 'Недійсна адреса електронної пошти.';
      case 'operation-not-allowed':
        return 'Реєстрація з електронною поштою та паролем вимкнена.';
      
      // Вхід
      case 'user-not-found':
        return 'Користувача з такою електронною поштою не знайдено.';
      case 'wrong-password':
        return 'Неправильний пароль.';
      case 'user-disabled':
        return 'Цей обліковий запис було вимкнено.';
      case 'too-many-requests':
        return 'Забагато невдалих спроб. Спробуйте пізніше.';
      
      // Загальні помилки
      case 'network-request-failed':
        return 'Помилка мережі. Перевірте підключення до Інтернету.';
      case 'invalid-credential':
        return 'Надані облікові дані недійсні.';
      case 'account-exists-with-different-credential':
        return 'Обліковий запис вже існує з іншим методом входу.';
      case 'requires-recent-login':
        return 'Ця операція чутлива до безпеки. Увійдіть знову та повторіть спробу.';
      
      default:
        return e.message ?? 'Сталася невідома помилка.';
    }
  }

  Future<void> signup({
    required String email,
    required String password,
    required String name,
    required BuildContext context,
  }) async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      
      await userCredential.user?.updateDisplayName(name);
      
    } on FirebaseAuthException catch (e) {
      final errorMessage = _handleAuthException(e);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
      
      throw Exception(errorMessage);
    } catch (e) {
      const errorMessage = 'Сталася неочікувана помилка.';
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
      
      throw Exception(errorMessage);
    }
  }
  
  Future<void> signin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      final errorMessage = _handleAuthException(e);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
      
      throw Exception(errorMessage);
    } catch (e) {
      const errorMessage = 'Сталася неочікувана помилка.';
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
      
      throw Exception(errorMessage);
    }
  }

  Future<void> signOut() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      
      // Спочатку виходимо з Firebase
      await _auth.signOut();
      
      // Перевіряємо, чи користувач увійшов через Google
      final isSignedIn = await googleSignIn.isSignedIn();
      if (isSignedIn) {
        await googleSignIn.signOut();
      }
    } catch (e) {
      print('Sign out error: ${e.toString()}');
      throw Exception('Не вдалося вийти з системи. Спробуйте ще раз.');
    }
  }
  
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      final errorMessage = _handleAuthException(e);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Не вдалося відправити лист для скидання пароля. Спробуйте ще раз.');
    }
  }
}
