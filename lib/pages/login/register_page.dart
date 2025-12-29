import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final namaController = TextEditingController();
  final alamatController = TextEditingController();
  final noHpController = TextEditingController();
  final pekerjaanLainController = TextEditingController();
  final tempatLahirController = TextEditingController();

  DateTime? tanggalLahir;
  String? jenisKelamin;
  String? pekerjaan;

  bool isLoading = false;

  final genderList = ['Laki-laki', 'Perempuan'];
  final pekerjaanList = [
    'Mahasiswa',
    'Pelajar',
    'Karyawan',
    'Wiraswasta',
    'Lainnya',
  ];

  // ================= DATE PICKER =================
  Future<void> pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => tanggalLahir = picked);
    }
  }

  // ================= REGISTER =================
  Future<void> register() async {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmController.text.isEmpty ||
        namaController.text.isEmpty ||
        jenisKelamin == null ||
        tempatLahirController.text.isEmpty ||
        tanggalLahir == null ||
        pekerjaan == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lengkapi semua data')));
      return;
    }

    if (passwordController.text != confirmController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password tidak sama')));
      return;
    }

    if (pekerjaan == 'Lainnya' && pekerjaanLainController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Isi pekerjaan lainnya')));
      return;
    }

    setState(() => isLoading = true);

    try {
      // CREATE AUTH
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text,
          );

      final user = userCredential.user!;
      final uid = user.uid;

      // KIRIM EMAIL VERIFIKASI
      await user.sendEmailVerification();

      // SIMPAN DATA USER
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'role': 'pasien',
        'email': emailController.text.trim(),
        'email_verified': false,
        'nama_lengkap': namaController.text,
        'alamat': alamatController.text,
        'no_hp': noHpController.text,
        'jenis_kelamin': jenisKelamin,
        'tempat_lahir': tempatLahirController.text,
        'tanggal_lahir': Timestamp.fromDate(tanggalLahir!),
        'pekerjaan': pekerjaan == 'Lainnya'
            ? pekerjaanLainController.text
            : pekerjaan,
        'created_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registrasi berhasil. Silakan cek email untuk verifikasi.',
          ),
        ),
      );

      // KEMBALI KE LOGIN
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String msg = 'Registrasi gagal';
      if (e.code == 'email-already-in-use') {
        msg = 'Email sudah terdaftar';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun Pasien')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Konfirmasi Password',
              ),
            ),
            TextField(
              controller: namaController,
              decoration: const InputDecoration(labelText: 'Nama Lengkap'),
            ),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Jenis Kelamin'),
              items: genderList
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => jenisKelamin = v),
            ),

            ListTile(
              title: Text(
                tanggalLahir == null
                    ? 'Pilih Tanggal Lahir'
                    : tanggalLahir!.toString().split(' ')[0],
              ),
              trailing: const Icon(Icons.date_range),
              onTap: pilihTanggal,
            ),
            TextField(
              controller: tempatLahirController,
              decoration: const InputDecoration(labelText: 'Tempat Lahir'),
            ),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Pekerjaan'),
              items: pekerjaanList
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => pekerjaan = v),
            ),

            if (pekerjaan == 'Lainnya')
              TextField(
                controller: pekerjaanLainController,
                decoration: const InputDecoration(
                  labelText: 'Pekerjaan Lainnya',
                ),
              ),

            TextField(
              controller: alamatController,
              decoration: const InputDecoration(labelText: 'Alamat'),
            ),
            TextField(
              controller: noHpController,
              decoration: const InputDecoration(labelText: 'Nomor HP'),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : register,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Daftar'),
            ),
          ],
        ),
      ),
    );
  }
}
