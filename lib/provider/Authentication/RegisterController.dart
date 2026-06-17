import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sams/domain/Authentication/UserModel.dart';
import 'package:sams/provider/Authentication/AuthController.dart';

class RegisterController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AuthController authController;

  RegisterController(this.authController);

  Future<bool> register({
    required String userId,
    required String password,
    required String username,
    required String role,
  }) async {
    authController.isLoading = true;
    authController.errorMessage = null;

    try {
      final email = authController.idToEmail(userId);

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final newUser = UserModel(
          userId: userId,
          username: username,
          role: role,
        );

        await _firestore.collection('users').doc(credential.user!.uid).set(newUser.toMap());
        
        await authController.fetchUserDetails(credential.user!.uid);
        
        authController.isLoading = false;
        return true;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        authController.errorMessage = "This User ID is already registered.";
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
