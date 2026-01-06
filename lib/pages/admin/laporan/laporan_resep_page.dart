import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';

class LaporanResepPage extends StatelessWidget {
  const LaporanResepPage({super.key});

  // ================= WARNA TEMA =================
  static const Color cyan = Color(0xFF7BC9E3);
  static const Color mint = Color(0xFF90EE90);
  static const Color bgColor = Color(0xFFF1FDFB);

  String safe(dynamic v) => v == null ? '-' : v.toString();

  String bulanTahun(Timestamp ts) {
    final d = ts.toDate();
    return DateFormat('MMMM yyyy', 'id_ID').format(d);
  }

  /// ======================= PDF =======================
  Future<void> printPdf(List<QueryDocumentSnapshot> docs) async {
    final pdf = pw.Document();

    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var doc in docs) {
      final d = doc.data() as Map<String, dynamic>;
      if (d['tanggal'] == null) continue;

      final key = bulanTahun(d['tanggal']);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(d);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) {
          final List<pw.Widget> widgets = [];

          widgets.add(
            pw.Text(
              'LAPORAN RESEP',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          );

          widgets.add(pw.SizedBox(height: 16));

          grouped.forEach((bulan, data) {
            int totalBulan = 0;

            widgets.add(
              pw.Text(
                bulan.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );

            widgets.add(pw.SizedBox(height: 8));

            widgets.add(
              pw.Table.fromTextArray(
                headers: [
                  'Pasien',
                  'Dokter',
                  'Metode',
                  'Status',
                  'Total',
                ],
                data: data.map((r) {
                  final harga = (r['total_harga'] ?? 0) as int;
                  totalBulan += harga;

                  return [
                    safe(r['nama_pasien']),
                    safe(r['nama_dokter']),
                    safe(r['metode_pembayaran']),
                    safe(r['status_resep']),
                    'Rp $harga',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 10),
              ),
            );

            widgets.add(pw.SizedBox(height: 6));
            widgets.add(
              pw.Text(
                'Total Bulan Ini: Rp $totalBulan',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            );

            widgets.add(pw.SizedBox(height: 14));
          });

          return widgets;
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  /// ======================= UI =======================
  @override
  Widget build(BuildContext context) {
    final resepRef = FirebaseFirestore.instance
        .collection('resep')
        .orderBy('tanggal', descending: true);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Laporan Resep'),
        centerTitle: true,
        backgroundColor: cyan,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Cetak PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final snap = await resepRef.get();
              await printPdf(snap.docs);
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: resepRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          final Map<String, List<QueryDocumentSnapshot>> grouped = {};

          for (var doc in docs) {
            final d = doc.data() as Map<String, dynamic>;
            if (d['tanggal'] == null) continue;

            final key = bulanTahun(d['tanggal']);
            grouped.putIfAbsent(key, () => []);
            grouped[key]!.add(doc);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: grouped.entries.map((entry) {
              int totalBulan = 0;

              for (var d in entry.value) {
                final r = d.data() as Map<String, dynamic>;
                totalBulan += (r['total_harga'] ?? 0) as int;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== HEADER BULAN =====
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: cyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rp $totalBulan',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ===== LIST DATA =====
                  ...entry.value.map((doc) {
                    final r = doc.data() as Map<String, dynamic>;
                    return Card(
                      elevation: 4,
                      shadowColor: cyan.withOpacity(0.3),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: mint.withOpacity(0.3),
                              child: const Icon(
                                Icons.receipt_long,
                                color: cyan,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    safe(r['nama_pasien']),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                      'Dokter: ${safe(r['nama_dokter'])}'),
                                  Text(
                                      'Metode: ${safe(r['metode_pembayaran'])}'),
                                  Text(
                                      'Status: ${safe(r['status_resep'])}'),
                                ],
                              ),
                            ),
                            Text(
                              'Rp ${safe(r['total_harga'])}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
