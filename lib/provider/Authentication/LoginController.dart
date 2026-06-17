import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sams/provider/Authentication/AuthController.dart';

class LoginController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  AuthController authController;

  LoginController(this.authController);

  Future<bool> login(String userId, String password) async {
    authController.isLoading = true;
    authController.errorMessage = null;

    try {
      final email = authController.idToEmail(userId);
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await authController.fetchUserDetails(credential.user!.uid);
        authController.isLoading = false;
        return true;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        authController.errorMessage = "Invalid User ID or password.";
      } else {
        authController.errorMessage = e.message;
      }
    } catch (e) {
      authController.errorMessage = "Error: $e";
    }

    authController.isLoading = false;
    return false;
  }
}
