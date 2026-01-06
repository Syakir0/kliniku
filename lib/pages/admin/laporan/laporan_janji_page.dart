import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class LaporanJanjiPage extends StatelessWidget {
  const LaporanJanjiPage({super.key});

  // ================= WARNA TEMA =================
  static const Color cyan = Color(0xFF7BC9E3);
  static const Color mint = Color(0xFF90EE90);
  static const Color bgColor = Color(0xFFF1FDFB);

  String safe(dynamic v) => v == null ? '-' : v.toString();

  /// ===================== PRINT PDF =====================
  Future<void> printPdf(List<QueryDocumentSnapshot> docs) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Text(
            'LAPORAN JANJI TEMU PASIEN',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Klinik',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: [
              'Pasien',
              'Dokter',
              'Hari',
              'Jam',
              'Status',
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 10),
            data: docs.map((e) {
              final j = e.data() as Map<String, dynamic>;
              return [
                safe(j['nama_pasien']),
                safe(j['nama_dokter']),
                safe(j['hari_praktek']),
                '${safe(j['jam_mulai'])} - ${safe(j['jam_selesai'])}',
                safe(j['status']),
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
    final janjiRef = FirebaseFirestore.instance
        .collection('janji')
        .orderBy('hari_praktek');

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Laporan Janji Temu'),
        centerTitle: true,
        backgroundColor: cyan,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Cetak PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final snap = await janjiRef.get();
              await printPdf(snap.docs);
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: janjiRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada data janji'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final j =
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
                            backgroundColor: mint.withOpacity(0.35),
                            child: const Icon(
                              Icons.event_available_rounded,
                              color: cyan,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              safe(j['nama_pasien']),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: j['status'] == 'selesai'
                                  ? Colors.green.withOpacity(0.15)
                                  : Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              safe(j['status']),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: j['status'] == 'selesai'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('Dokter        : ${safe(j['nama_dokter'])}'),
                      Text('Hari          : ${safe(j['hari_praktek'])}'),
                      Text(
                          'Jam           : ${safe(j['jam_mulai'])} - ${safe(j['jam_selesai'])}'),
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
