import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Ініціалізуємо Google Sign In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'profile',
        ],
      );

      // Показуємо діалог вибору акаунта Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      // Якщо користувач скасував вхід
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'sign_in_canceled',
          message: 'Вхід скасовано користувачем',
        );
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
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _handleAuthException(e),
      );
    } catch (e) {
      throw FirebaseAuthException(
        code: 'google_sign_in_failed',
        message: 'Помилка входу через Google: ${e.toString()}',
      );
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
      final isSignedIn = await googleSignIn.isSignedIn();
      
      // Спочатку виходимо з Firebase
      await _auth.signOut();
      
      // Якщо користувач був увійшовший через Google, виходимо з Google
      if (isSignedIn) {
        await googleSignIn.signOut();
      }
    } on FirebaseAuthException catch (e) {
      final errorMessage = _handleAuthException(e);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Не вдалося вийти з системи. Спробуйте ще раз.');
    }
  }
}
