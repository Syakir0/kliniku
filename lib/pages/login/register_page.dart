import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nikController = TextEditingController();
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
  bool showPassword = false;
  bool showConfirm = false;

  final genderList = ['Laki-laki', 'Perempuan'];
  final pekerjaanList = [
    'Mahasiswa',
    'Pelajar',
    'Karyawan',
    'Wiraswasta',
    'Lainnya',
  ];

  // ================= REGISTER (LOGIC ASLI - TIDAK DIUBAH) =================
  Future<void> register() async {
    if (nikController.text.length != 16) {
      snack('NIK harus 16 digit');
      return;
    }

    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmController.text.isEmpty ||
        namaController.text.isEmpty ||
        jenisKelamin == null ||
        tanggalLahir == null ||
        pekerjaan == null) {
      snack('Lengkapi semua data');
      return;
    }

    if (passwordController.text != confirmController.text) {
      snack('Password tidak sama');
      return;
    }

    if (pekerjaan == 'Lainnya' && pekerjaanLainController.text.isEmpty) {
      snack('Isi pekerjaan lainnya');
      return;
    }

    setState(() => isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text,
          );

      final user = userCredential.user!;
      await user.sendEmailVerification();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'NIK': int.parse(nikController.text),
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

      snack('Registrasi berhasil. Cek email untuk verifikasi.');
      Navigator.pop(context);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7BC9E3), Color(0xFFA2E5A2)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 10),

                const Text(
                  'DAFTAR AKUN',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 30),

                // ================= FORM CARD =================
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: Column(
                    children: [
                      input(
                        controller: nikController,
                        hint: 'NIK (16 digit)',
                        icon: Icons.badge_outlined,
                        type: TextInputType.number,
                        maxLength: 16,
                        formatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      input(
                        controller: emailController,
                        hint: 'Email',
                        icon: Icons.email_outlined,
                      ),
                      input(
                        controller: passwordController,
                        hint: 'Password',
                        icon: Icons.lock_outline,
                        obscure: !showPassword,
                        showEye: true,
                        toggle: () =>
                            setState(() => showPassword = !showPassword),
                      ),
                      input(
                        controller: confirmController,
                        hint: 'Konfirmasi Password',
                        icon: Icons.lock_reset_outlined,
                        obscure: !showConfirm,
                        showEye: true,
                        toggle: () =>
                            setState(() => showConfirm = !showConfirm),
                      ),
                      input(
                        controller: namaController,
                        hint: 'Nama Lengkap',
                        icon: Icons.person_outline,
                      ),
                      dropdown(
                        label: 'Jenis Kelamin',
                        value: jenisKelamin,
                        items: genderList,
                        onChanged: (v) => setState(() => jenisKelamin = v),
                      ),
                      datePicker(),
                      input(
                        controller: tempatLahirController,
                        hint: 'Tempat Lahir',
                        icon: Icons.location_on_outlined,
                      ),
                      dropdown(
                        label: 'Pekerjaan',
                        value: pekerjaan,
                        items: pekerjaanList,
                        onChanged: (v) => setState(() => pekerjaan = v),
                      ),
                      if (pekerjaan == 'Lainnya')
                        input(
                          controller: pekerjaanLainController,
                          hint: 'Pekerjaan Lainnya',
                          icon: Icons.work_outline,
                        ),
                      input(
                        controller: alamatController,
                        hint: 'Alamat',
                        icon: Icons.home_outlined,
                      ),
                      input(
                        controller: noHpController,
                        hint: 'Nomor HP',
                        icon: Icons.phone_outlined,
                        type: TextInputType.phone,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // ================= BUTTON =================
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7BC9E3), Color(0xFFA2E5A2)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Daftar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sudah punya akun? ',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= COMPONENT =================

  Widget input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    bool showEye = false,
    VoidCallback? toggle,
    TextInputType? type,
    List<TextInputFormatter>? formatters,
    int? maxLength,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        inputFormatters: formatters,
        maxLength: maxLength,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          counterText: '',
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black54),
          prefixIcon: Icon(icon, color: Colors.black54),
          suffixIcon: showEye
              ? IconButton(
                  icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: toggle,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget dropdown({
    required String label,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        iconEnabledColor: Colors.black54,
        decoration: InputDecoration(
          hintText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget datePicker() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime(2000),
            firstDate: DateTime(1950),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            setState(() => tanggalLahir = picked);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              const Icon(Icons.date_range, color: Colors.black54),
              const SizedBox(width: 12),
              Text(
                tanggalLahir == null
                    ? 'Pilih Tanggal Lahir'
                    : tanggalLahir!.toString().split(' ')[0],
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
