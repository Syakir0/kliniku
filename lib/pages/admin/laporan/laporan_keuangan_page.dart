import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class LaporanKeuanganPage extends StatelessWidget {
  const LaporanKeuanganPage({super.key});

  String safe(dynamic v) => v == null ? '-' : v.toString();

  String formatTanggal(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate();
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
  }

  String formatBulan(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate();
    return '${d.month.toString().padLeft(2, '0')}-${d.year}';
  }

  /// ================== CETAK PDF ==================
  Future<void> printPdf(List<QueryDocumentSnapshot> docs) async {
    final pdf = pw.Document();

    int totalPendapatan = 0;
    for (var d in docs) {
      totalPendapatan += (d['total_harga'] as int);
    }

    final font = await PdfGoogleFonts.robotoRegular();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => [
          pw.Center(
            child: pw.Text(
              'LAPORAN KEUANGAN',
              style: pw.TextStyle(
                fontSize: 26,
                fontWeight: pw.FontWeight.bold,
                font: font,
              ),
            ),
          ),
          pw.SizedBox(height: 24),

          pw.Text(
            'Total Pendapatan: Rp $totalPendapatan',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              font: font,
            ),
          ),
          pw.SizedBox(height: 16),

          pw.Table.fromTextArray(
            headers: [
              'Nama Pasien',
              'Dokter',
              'Metode Bayar',
              'Tanggal',
              'Bulan',
              'Total Harga',
            ],
            data: docs.map((e) {
              final d = e.data() as Map<String, dynamic>;
              final ts = d['tanggal'] as Timestamp?;
              return [
                safe(d['nama_pasien']),
                safe(d['nama_dokter']),
                safe(d['metode_pembayaran']),
                formatTanggal(ts),
                formatBulan(ts),
                'Rp ${safe(d['total_harga'])}',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
              font: font,
            ),
            cellStyle: pw.TextStyle(
              fontSize: 11,
              font: font,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.green100,
            ),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1.5),
              5: const pw.FlexColumnWidth(1.5),
            },
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  /// ================== UI ==================
  @override
  Widget build(BuildContext context) {
    final resepRef = FirebaseFirestore.instance
        .collection('resep')
        .where('status_resep', isEqualTo: 'selesai')
        .orderBy('tanggal', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada data keuangan',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          int totalPendapatan = 0;
          for (var d in docs) {
            totalPendapatan += (d['total_harga'] as int);
          }

          return Column(
            children: [
              // Ringkasan Pendapatan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Pendapatan',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rp $totalPendapatan',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // List Transaksi
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final d = docs[index].data() as Map<String, dynamic>;
                    final ts = d['tanggal'] as Timestamp?;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        title: Text(
                          d['nama_pasien'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dokter: ${d['nama_dokter']}'),
                            Text('Metode Bayar: ${d['metode_pembayaran']}'),
                            Text(
                              'Tanggal: ${formatTanggal(ts)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Bulan: ${formatBulan(ts)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Text(
                          'Rp ${d['total_harga']}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 14),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
