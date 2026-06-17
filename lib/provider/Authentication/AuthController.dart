import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sams/domain/Authentication/UserModel.dart';

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  set errorMessage(String? value) {
    _errorMessage = value;
    notifyListeners();
  }

  String idToEmail(String userId) {
    return "${userId.trim().toLowerCase()}@sams.app";
  }

  AuthController() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        await fetchUserDetails(user.uid);
      } else {
        _currentUser = null;
      }
      _isInitialized = true;
      notifyListeners();
    });
  }

  Future<void> fetchUserDetails(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        _currentUser = UserModel.fromFirestore(doc.data()!);
        _errorMessage = null;
      } else {
        _currentUser = null;
        if (_auth.currentUser != null) {
          _errorMessage = "User profile not found in Firestore. Please register again.";
        }
      }
    } catch (e) {
      _errorMessage = "Failed to load user details: $e";
      _currentUser = null;
    }
    notifyListeners();
  }

  bool checkSession() => isLoggedIn;
  UserModel? getCurrentUser() => _currentUser;
  bool hasRole(String role) => _currentUser?.role == role;

  void logout() async {
    await _auth.signOut();
    _currentUser = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
