import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================= LOGIN =================
  Future<String> login(String email, String password) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;

      if (user == null) {
        throw Exception('Login gagal, user tidak ditemukan');
      }

      final DocumentSnapshot<Map<String, dynamic>> snap = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!snap.exists) {
        throw Exception('Data user tidak ditemukan di database');
      }

      final data = snap.data();

      if (data == null || !data.containsKey('role')) {
        throw Exception('Role user belum diatur');
      }

      return data['role'] as String;
    } on FirebaseAuthException catch (e) {
      throw Exception(_firebaseAuthError(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ================= RESET PASSWORD =================
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_firebaseAuthError(e));
    }
  }

  // ================= HELPER ERROR MESSAGE =================
  String _firebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Email tidak terdaftar';
      case 'wrong-password':
        return 'Password salah';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'user-disabled':
        return 'Akun telah dinonaktifkan';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan, coba lagi nanti';
      default:
        return 'Terjadi kesalahan autentikasi';
    }
  }
}
