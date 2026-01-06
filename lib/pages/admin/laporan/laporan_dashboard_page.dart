import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class LaporanDashboardPage extends StatefulWidget {
  const LaporanDashboardPage({super.key});

  @override
  State<LaporanDashboardPage> createState() => _LaporanDashboardPageState();
}

class _LaporanDashboardPageState extends State<LaporanDashboardPage> {
  String safe(dynamic v) => v == null ? '-' : v.toString();

  /// ===================== BRAND GRADIENT =====================
  static const LinearGradient adminGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF87CEEB), // Soft Cyan
      Color(0xFF7BC9E3),
      Color(0xFF90EE90), // Light Mint
      Color(0xFFA2E5A2),
    ],
  );

  /// ===================== SECTION TITLE =====================
  Widget sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4FAFA3)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4FAFA3),
            ),
          ),
        ],
      ),
    );
  }

  /// ===================== CARD STYLE =====================
  Widget infoCard({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF87CEEB),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing,
      ),
    );
  }

  /// ===================== PDF (TIDAK DIUBAH) =====================
  Future<void> printPdf(
    List<QueryDocumentSnapshot> dokter,
    List<QueryDocumentSnapshot> pasien,
    List<QueryDocumentSnapshot> janji,
    List<QueryDocumentSnapshot> pemeriksaan,
    List<QueryDocumentSnapshot> resep,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Text(
            'LAPORAN DASHBOARD KLINIK',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),

          pw.Text('DATA DOKTER'),
          ...dokter.map((e) {
            final d = e.data() as Map<String, dynamic>;
            return pw.Text('- ${safe(d['nama'])} | ${safe(d['poli'])}');
          }),

          pw.SizedBox(height: 12),
          pw.Text('DATA PASIEN'),
          ...pasien.map((e) {
            final p = e.data() as Map<String, dynamic>;
            return pw.Text('- ${safe(p['nama_lengkap'])} | ${safe(p['NIK'])}');
          }),

          pw.SizedBox(height: 12),
          pw.Text('DATA JANJI'),
          ...janji.map((e) {
            final j = e.data() as Map<String, dynamic>;
            return pw.Text('- ${safe(j['nama_pasien'])} (${safe(j['status'])})');
          }),

          pw.SizedBox(height: 12),
          pw.Text('DATA PEMERIKSAAN'),
          ...pemeriksaan.map((e) {
            final p = e.data() as Map<String, dynamic>;
            return pw.Text('- ${safe(p['nik'])} | ${safe(p['diagnosa'])}');
          }),

          pw.SizedBox(height: 12),
          pw.Text('DATA KEUANGAN'),
          ...resep.map((e) {
            final r = e.data() as Map<String, dynamic>;
            return pw.Text('- ${safe(r['nama_pasien'])} | Rp ${safe(r['total_harga'])}');
          }),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  /// ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    final users = FirebaseFirestore.instance.collection('users');
    final janji = FirebaseFirestore.instance.collection('janji');
    final pemeriksaan = FirebaseFirestore.instance.collection('pemeriksaan');
    final resep = FirebaseFirestore.instance.collection('resep');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan Dashboard Klinik',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: adminGradient),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final dokter = await users.where('role', isEqualTo: 'dokter').get();
              final pasien = await users.where('role', isEqualTo: 'pasien').get();
              final j = await janji.get();
              final p = await pemeriksaan.get();
              final r = await resep.get();

              await printPdf(
                dokter.docs,
                pasien.docs,
                j.docs,
                p.docs,
                r.docs,
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            sectionTitle('Dokter', Icons.medical_services),
            StreamBuilder<QuerySnapshot>(
              stream: users.where('role', isEqualTo: 'dokter').snapshots(),
              builder: (_, s) => s.hasData
                  ? Column(
                      children: s.data!.docs.map((e) {
                        final d = e.data() as Map<String, dynamic>;
                        return infoCard(
                          icon: Icons.person,
                          title: safe(d['nama']),
                          subtitle: safe(d['poli']),
                        );
                      }).toList(),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),

            sectionTitle('Pasien', Icons.people),
            StreamBuilder<QuerySnapshot>(
              stream: users.where('role', isEqualTo: 'pasien').snapshots(),
              builder: (_, s) => s.hasData
                  ? Column(
                      children: s.data!.docs.map((e) {
                        final p = e.data() as Map<String, dynamic>;
                        return infoCard(
                          icon: Icons.badge,
                          title: safe(p['nama_lengkap']),
                          subtitle: 'NIK: ${safe(p['NIK'])}',
                        );
                      }).toList(),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),

            sectionTitle('Janji', Icons.event),
            StreamBuilder<QuerySnapshot>(
              stream: janji.snapshots(),
              builder: (_, s) => s.hasData
                  ? Column(
                      children: s.data!.docs.map((e) {
                        final j = e.data() as Map<String, dynamic>;
                        return infoCard(
                          icon: Icons.schedule,
                          title: safe(j['nama_pasien']),
                          subtitle: safe(j['status']),
                        );
                      }).toList(),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),

            sectionTitle('Pemeriksaan', Icons.assignment),
            StreamBuilder<QuerySnapshot>(
              stream: pemeriksaan.snapshots(),
              builder: (_, s) => s.hasData
                  ? Column(
                      children: s.data!.docs.map((e) {
                        final p = e.data() as Map<String, dynamic>;
                        return infoCard(
                          icon: Icons.description,
                          title: 'NIK: ${safe(p['nik'])}',
                          subtitle: safe(p['diagnosa']),
                        );
                      }).toList(),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),

            sectionTitle('Keuangan', Icons.payments),
            StreamBuilder<QuerySnapshot>(
              stream: resep.where('status_resep', isEqualTo: 'selesai').snapshots(),
              builder: (_, s) => s.hasData
                  ? Column(
                      children: s.data!.docs.map((e) {
                        final r = e.data() as Map<String, dynamic>;
                        return infoCard(
                          icon: Icons.attach_money,
                          title: safe(r['nama_pasien']),
                          trailing: Text(
                            'Rp ${safe(r['total_harga'])}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4FAFA3),
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }
}
