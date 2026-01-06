import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class LaporanObatPage extends StatefulWidget {
  const LaporanObatPage({super.key});

  @override
  State<LaporanObatPage> createState() => _LaporanObatPageState();
}

class _LaporanObatPageState extends State<LaporanObatPage> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  // ===== TEMA WARNA =====
  static const Color cyan = Color(0xFF7BC9E3);
  static const Color mint = Color(0xFF90EE90);
  static const Color bgColor = Color(0xFFF1FDFB);

  String safe(dynamic v) => v == null ? '-' : v.toString();

  String formatDate(dynamic ts) {
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${d.day}-${d.month}-${d.year}';
    }
    return '-';
  }

  bool isSameMonth(Timestamp? ts) {
    if (ts == null) return false;
    final d = ts.toDate();
    return d.month == selectedMonth && d.year == selectedYear;
  }

  /// ================== CETAK PDF ==================
  Future<void> printPdf(List<QueryDocumentSnapshot> docs) async {
    final pdf = pw.Document();

    final filtered = docs.where((e) {
      final d = e.data() as Map<String, dynamic>;
      return isSameMonth(d['tanggal_masuk']);
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Text(
            'LAPORAN DATA OBAT',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            'Periode: $selectedMonth-$selectedYear',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: [
              'Nama',
              'Jenis',
              'Harga',
              'Stok',
              'Usia',
              'Expired',
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 10),
            data: filtered.map((e) {
              final d = e.data() as Map<String, dynamic>;
              return [
                safe(d['nama']),
                safe(d['jenis_obat']),
                safe(d['harga']),
                safe(d['stock']),
                safe(d['usia_pemakaian_obat']),
                formatDate(d['tanggal_expired']),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  /// ================== UI ==================
  @override
  Widget build(BuildContext context) {
    final obatRef = FirebaseFirestore.instance.collection('obat');

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Laporan Obat'),
        centerTitle: true,
        backgroundColor: cyan,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Cetak PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final snap = await obatRef.get();
              await printPdf(snap.docs);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          /// ===== FILTER BULAN =====
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            shadowColor: cyan.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: selectedMonth,
                      decoration: const InputDecoration(
                        labelText: 'Bulan',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(12, (i) {
                        final m = i + 1;
                        return DropdownMenuItem(
                          value: m,
                          child: Text('Bulan $m'),
                        );
                      }),
                      onChanged: (v) => setState(() => selectedMonth = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: selectedYear,
                      decoration: const InputDecoration(
                        labelText: 'Tahun',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(5, (i) {
                        final y = DateTime.now().year - i;
                        return DropdownMenuItem(
                          value: y,
                          child: Text('$y'),
                        );
                      }),
                      onChanged: (v) => setState(() => selectedYear = v!),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// ===== LIST DATA =====
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: obatRef
                  .orderBy('tanggal_masuk', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Data obat belum tersedia'));
                }

                final docs = snapshot.data!.docs.where((e) {
                  final d = e.data() as Map<String, dynamic>;
                  return isSameMonth(d['tanggal_masuk']);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada data obat di periode ini'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final d = docs[index].data() as Map<String, dynamic>;

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
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: mint.withOpacity(0.3),
                                  child: const Icon(
                                    Icons.medication,
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
                            const SizedBox(height: 10),
                            Text('Jenis Obat : ${safe(d['jenis_obat'])}'),
                            Text('Harga     : Rp ${safe(d['harga'])}'),
                            Text('Stok      : ${safe(d['stock'])}'),
                            Text(
                                'Usia Pakai: ${safe(d['usia_pemakaian_obat'])}'),
                            Text('Keterangan: ${safe(d['keterangan'])}'),
                            const Divider(height: 20),
                            Text(
                              'Tanggal Masuk  : ${formatDate(d['tanggal_masuk'])}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Tanggal Expired: ${formatDate(d['tanggal_expired'])}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
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
          ),
        ],
      ),
    );
  }
}
