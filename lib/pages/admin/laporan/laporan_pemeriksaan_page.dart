import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class LaporanPemeriksaanPage extends StatelessWidget {
  const LaporanPemeriksaanPage({super.key});

  // ================= WARNA TEMA =================
  static const Color cyan = Color(0xFF7BC9E3);
  static const Color mint = Color(0xFF90EE90);
  static const Color bgColor = Color(0xFFF1FDFB);

  String safe(dynamic value) {
    if (value == null) return '-';
    return value.toString();
  }

  String formatTanggal(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate();
    return '${d.day.toString().padLeft(2, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.year}';
  }

  // ================= PDF =================
  Future<void> printPdf(List<QueryDocumentSnapshot> docs) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Text(
            'LAPORAN PEMERIKSAAN',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: ['NIK', 'Diagnosa', 'Catatan', 'Tanggal'],
            data: docs.map((e) {
              final d = e.data() as Map<String, dynamic>;
              return [
                safe(d['nik']),
                safe(d['diagnosa']),
                safe(d['catatan']),
                formatTanggal(d['tanggal']),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('pemeriksaan')
        .where('status_pemeriksaan', isEqualTo: 'selesai')
        .orderBy('tanggal', descending: true);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Laporan Pemeriksaan'),
        centerTitle: true,
        backgroundColor: cyan,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Cetak PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final snap = await query.get();
              await printPdf(snap.docs);
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Gagal memuat data'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada data pemeriksaan'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final raw = docs[index].data();
              if (raw == null || raw is! Map<String, dynamic>) {
                return const SizedBox.shrink();
              }

              final nik = safe(raw['nik']);
              final diagnosa = safe(raw['diagnosa']);
              final catatan = safe(raw['catatan']);
              final tanggal = raw['tanggal'] as Timestamp?;

              return Card(
                elevation: 4,
                shadowColor: cyan.withOpacity(0.3),
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: cyan.withOpacity(0.2),
                        child: const Icon(
                          Icons.assignment_rounded,
                          color: cyan,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NIK: $nik',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('Diagnosa: $diagnosa'),
                            Text('Catatan: $catatan'),
                            const SizedBox(height: 6),
                            Text(
                              'Tanggal: ${formatTanggal(tanggal)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
