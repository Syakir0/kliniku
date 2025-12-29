import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// PAGES
import 'pages/login/login_page.dart';
import 'pages/admin/admin_page.dart';
import 'pages/dokter/dokter_page.dart';
import 'pages/pasien/pasien_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kliniku',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/admin': (context) => AdminPage(), // ❗ TANPA const
        '/dokter': (context) => DokterPage(),
        '/pasien': (context) => PasienPage(),
      },
    );
  }
}
