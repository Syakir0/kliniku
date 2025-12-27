import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService authService = AuthService();
  final confirmPasswordController = TextEditingController();

  bool isConfirmVisible = false;
  bool isLoading = false;
  bool isPasswordVisible = false;

  void handleRegister() async {
    setState(() => isLoading = true);

    try {
      await authService.registerPasien(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Akun berhasil dibuat')));

      Navigator.pop(context); // balik ke login
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Pasien')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: !isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            TextField(
              controller: confirmPasswordController,
              obscureText: !isConfirmVisible,
              decoration: InputDecoration(
                labelText: 'Konfirmasi Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    isConfirmVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      isConfirmVisible = !isConfirmVisible;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : handleRegister,
              child: Text(isLoading ? 'Loading...' : 'Daftar'),
            ),
          ],
        ),
      ),
    );
  }
}
