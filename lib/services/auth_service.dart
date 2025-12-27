import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> login(String email, String password) async {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    String uid = userCredential.user!.uid;

    DocumentSnapshot userDoc = await _firestore
        .collection('users')
        .doc(uid)
        .get();

    if (!userDoc.exists) {
      throw Exception('Role user tidak ditemukan');
    }

    return userDoc['role'];
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> registerPasien(String email, String password) async {
    // 1. Buat akun di Firebase Auth
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    String uid = userCredential.user!.uid;

    // 2. Simpan data user ke Firestore
    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'role': 'pasien',
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
