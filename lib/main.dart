import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

// PAGES
import 'pages/login/login_page.dart';
import 'pages/admin/admin_page.dart';
import 'pages/dokter/dokter_page.dart';
import 'pages/pasien/pasien_page.dart';
import 'pages/apotek/apotek_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 INIT FIREBASE
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🇮🇩 INIT LOCALE INDONESIA
  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kliniku',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),

      // ROUTING
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/admin': (context) => AdminPage(),
        '/dokter': (context) => DokterPage(),
        '/pasien': (context) => PasienPage(),

        // ❌ JANGAN CONST (pakai Firestore & Stream)
        '/apotek': (context) => ApotekPage(),
      },
    );
  }
}
