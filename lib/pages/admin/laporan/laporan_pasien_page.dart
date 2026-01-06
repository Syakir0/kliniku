import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class LaporanPasienPage extends StatelessWidget {
  const LaporanPasienPage({super.key});

  // ===== TEMA WARNA (ADMIN) =====
  static const Color cyan = Color(0xFF7BC9E3);
  static const Color mint = Color(0xFF90EE90);
  static const Color bgColor = Color(0xFFF1FDFB);

  String safe(dynamic v) => v == null ? '-' : v.toString();

  String formatTanggal(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate();
    return '${d.day}-${d.month}-${d.year}';
  }

  /// ===================== PRINT PDF =====================
  Future<void> printPdf(List<QueryDocumentSnapshot> docs) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Text(
            'LAPORAN DATA PASIEN',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: [
              'Nama',
              'NIK',
              'No HP',
              'Jenis Kelamin',
              'Tanggal Lahir',
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 10),
            data: docs.map((e) {
              final p = e.data() as Map<String, dynamic>;
              return [
                safe(p['nama_lengkap']),
                safe(p['NIK']),
                safe(p['no_hp']),
                safe(p['jenis_kelamin']),
                formatTanggal(p['tanggal_lahir']),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  /// ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    final pasienRef = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'pasien')
        .orderBy('tanggal_lahir', descending: true);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Laporan Pasien'),
        centerTitle: true,
        backgroundColor: cyan,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Cetak PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final snap = await pasienRef.get();
              await printPdf(snap.docs);
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: pasienRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada data pasien'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final p =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;

              return Card(
                elevation: 6,
                shadowColor: cyan.withOpacity(0.3),
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    /// ===== HEADER =====
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cyan.withOpacity(0.12),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: mint.withOpacity(0.5),
                            child: const Icon(
                              Icons.person,
                              color: cyan,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              safe(p['nama_lengkap']),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// ===== BODY =====
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          infoRow('NIK', safe(p['NIK'])),
                          infoRow('No HP', safe(p['no_hp'])),
                          infoRow(
                              'Jenis Kelamin', safe(p['jenis_kelamin'])),
                          const Divider(height: 22),
                          infoRow(
                            'Tanggal Lahir',
                            formatTanggal(p['tanggal_lahir']),
                            valueStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// ===================== HELPER ROW =====================
  Widget infoRow(
    String label,
    String value, {
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const Text(':  '),
          Expanded(
            child: Text(
              value,
              style: valueStyle ??
                  const TextStyle(
                    color: Colors.black87,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
