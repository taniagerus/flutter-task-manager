import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
 Future<void> signup({
  required String email,
  required String password,
  required String name,
  required BuildContext context,
 }) async {
  try {
    // Створюємо користувача
    final UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
    
    // Оновлюємо профіль користувача з ім'ям
    await userCredential.user?.updateDisplayName(name);
    
  } on FirebaseAuthException catch (e) {
    String errorMessage;
    
    switch (e.code) {
      case 'weak-password':
        errorMessage = 'The password is too weak.';
        break;
      case 'email-already-in-use':
        errorMessage = 'The account already exists for that email.';
        break;
      case 'invalid-email':
        errorMessage = 'The email address is not valid.';
        break;
      default:
        errorMessage = e.message ?? 'An error occurred during registration.';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
      ),
    );
    
    throw Exception(errorMessage);
  } catch (e) {
    const errorMessage = 'An unexpected error occurred.';
    
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
    String errorMessage;
    
    switch (e.code) {
      case 'user-not-found':
        errorMessage = 'No user found for that email.';
        break;
      case 'wrong-password':
        errorMessage = 'Wrong password provided for that user.';
        break;
      case 'invalid-email':
        errorMessage = 'The email address is not valid.';
        break;
      case 'user-disabled':
        errorMessage = 'This user has been disabled.';
        break;
      default:
        errorMessage = e.message ?? 'An error occurred during sign in.';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
      ),
    );
    
    throw Exception(errorMessage);
  } catch (e) {
    const errorMessage = 'An unexpected error occurred.';
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
      ),
    );
    
    throw Exception(errorMessage);
  }
 }
}
