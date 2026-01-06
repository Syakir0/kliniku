import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class LaporanDokterPage extends StatelessWidget {
  const LaporanDokterPage({super.key});

  // ===== TEMA WARNA =====
  static const Color cyan = Color(0xFF7BC9E3);
  static const Color mint = Color(0xFF90EE90);
  static const Color bgColor = Color(0xFFF1FDFB);

  String safe(dynamic v) => v == null ? '-' : v.toString();

  String formatBulan(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate();
    return '${d.month}-${d.year}';
  }

  /// ===================== PRINT PDF =====================
  Future<void> printPdf(List<QueryDocumentSnapshot> docs) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Text(
            'LAPORAN DATA DOKTER',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: [
              'Nama',
              'NIP',
              'Poli',
              'Spesialis',
              'Hari Praktek',
              'Jam',
              'Bulan',
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 10),
            data: docs.map((e) {
              final d = e.data() as Map<String, dynamic>;
              return [
                safe(d['nama']),
                safe(d['NIP']),
                safe(d['poli']),
                safe(d['spesialis']),
                (d['hari_praktek'] as List?)?.join(', ') ?? '-',
                '${safe(d['jam_mulai'])} - ${safe(d['jam_selesai'])}',
                formatBulan(d['created_at']),
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
    final dokterRef = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'dokter')
        .orderBy('created_at', descending: true);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Laporan Dokter'),
        centerTitle: true,
        backgroundColor: cyan,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Cetak PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final snap = await dokterRef.get();
              await printPdf(snap.docs);
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: dokterRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada data dokter'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final d =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;

              return Card(
                elevation: 5,
                shadowColor: cyan.withOpacity(0.25),
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== HEADER =====
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: mint.withOpacity(0.4),
                            child: const Icon(
                              Icons.medical_services,
                              color: cyan,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              safe(d['nama']),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ===== DETAIL =====
                      Text(
                        'NIP          : ${safe(d['NIP'])}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('Poli         : ${safe(d['poli'])}'),
                      Text('Spesialis    : ${safe(d['spesialis'])}'),
                      Text(
                        'Hari Praktek : ${(d['hari_praktek'] as List?)?.join(', ') ?? '-'}',
                      ),
                      Text(
                        'Jam Praktek  : ${safe(d['jam_mulai'])} - ${safe(d['jam_selesai'])}',
                      ),

                      const Divider(height: 20),

                      Text(
                        'Terdaftar: ${formatBulan(d['created_at'])}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
