import 'package:flutter/material.dart';

import 'laporan_dashboard_page.dart';
import 'laporan_pemeriksaan_page.dart';
import 'laporan_resep_page.dart';
import 'laporan_pasien_page.dart';
import 'laporan_dokter_page.dart';
import 'laporan_keuangan_page.dart';
import 'laporan_obat_page.dart';
import 'laporan_janji_page.dart';

class LaporanPage extends StatelessWidget {
  const LaporanPage({super.key});

  // ================= WARNA TEMA =================
  static const Color cyan = Color(0xFF7BC9E3);
  static const Color mint = Color(0xFF90EE90);
  static const Color bgColor = Color(0xFFF1FDFB);

  Widget menuItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget page,
    bool highlight = false,
  }) {
    return Card(
      elevation: highlight ? 6 : 3,
      shadowColor: cyan.withOpacity(0.3),
      color: highlight ? cyan.withOpacity(0.12) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: highlight
              ? cyan.withOpacity(0.25)
              : mint.withOpacity(0.25),
          child: Icon(icon, color: cyan, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: highlight ? 16 : 15,
            color: Colors.grey[800],
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Laporan Klinik'),
        centerTitle: true,
        backgroundColor: cyan,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ================= DASHBOARD =================
          menuItem(
            context: context,
            title: 'Laporan Keseluruhan',
            icon: Icons.dashboard_rounded,
            page: const LaporanDashboardPage(),
            highlight: true,
          ),

          const SizedBox(height: 6),

          // ================= DETAIL LAPORAN =================
          menuItem(
            context: context,
            title: 'Laporan Pemeriksaan',
            icon: Icons.assignment_rounded,
            page: const LaporanPemeriksaanPage(),
          ),
          menuItem(
            context: context,
            title: 'Laporan Resep',
            icon: Icons.receipt_long_rounded,
            page: const LaporanResepPage(),
          ),
          menuItem(
            context: context,
            title: 'Laporan Obat',
            icon: Icons.medication_outlined,
            page: const LaporanObatPage(),
          ),
          menuItem(
            context: context,
            title: 'Laporan Pasien',
            icon: Icons.people_alt_rounded,
            page: const LaporanPasienPage(),
          ),
          menuItem(
            context: context,
            title: 'Laporan Dokter',
            icon: Icons.medical_services_rounded,
            page: const LaporanDokterPage(),
          ),
          menuItem(
            context: context,
            title: 'Laporan Janji Temu',
            icon: Icons.event_available_rounded,
            page: const LaporanJanjiPage(),
          ),
          menuItem(
            context: context,
            title: 'Laporan Keuangan',
            icon: Icons.attach_money_rounded,
            page: const LaporanKeuanganPage(),
          ),
        ],
      ),
    );
  }
}
