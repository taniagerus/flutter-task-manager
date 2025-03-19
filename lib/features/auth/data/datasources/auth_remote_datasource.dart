import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/entities/user.dart';

abstract class AuthRemoteDataSource {
  Future<User> signIn(String email, String password);
  Future<User> signUp(String email, String password, String name);
  Future<void> signOut();
  Future<User> signInWithGoogle();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDataSourceImpl({
    firebase_auth.FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  Future<User> signIn(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    return User(
      id: userCredential.user!.uid,
      email: userCredential.user!.email!,
      name: userCredential.user!.displayName,
    );
  }

  @override
  Future<User> signUp(String email, String password, String name) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update the user profile with the name
      await userCredential.user?.updateDisplayName(name);
      
      // Force reload the user to get updated data
      await userCredential.user?.reload();
      
      // Get the updated user data
      final updatedUser = _auth.currentUser;
      if (updatedUser == null) throw Exception('User not found after registration');

      return User(
        id: updatedUser.uid,
        email: updatedUser.email!,
        name: name, // Use the provided name directly
      );
    } catch (e) {
      throw Exception('Failed to sign up: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<User> signInWithGoogle() async {
    try {
      // Діалог вибору акаунта Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google sign in aborted');

      // Отримуємо автентифікаційні дані
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Створюємо обліковий запис Firebase
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Авторизуємось в Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      
      if (firebaseUser == null) throw Exception('Google sign in failed');

      return User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName,
      );
    } catch (e) {
      if (e.toString().contains('12500')) {
        throw Exception('Перевірте наявність та актуальність Google Play Services на вашому пристрої');
      } else {
        throw Exception('Помилка входу через Google: ${e.toString()}');
      }
    }
  }
} 