import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LaporanPage extends StatelessWidget {
  const LaporanPage({super.key});

  // ================= HITUNG DATA =================
  Future<Map<String, int>> getLaporan() async {
    final firestore = FirebaseFirestore.instance;

    final dokter = await firestore.collection('dokter').get();
    final pasien = await firestore.collection('users').get();
    final janji = await firestore.collection('janji').get();
    final pemeriksaan = await firestore.collection('pemeriksaan').get();
    final resep = await firestore.collection('resep').get();
    final obat = await firestore.collection('obat').get();

    return {
      'Dokter': dokter.size,
      'Pasien': pasien.size,
      'Janji': janji.size,
      'Pemeriksaan': pemeriksaan.size,
      'Resep': resep.size,
      'Obat': obat.size,
    };
  }

  // ================= CETAK PDF =================
  Future<void> cetakPdf(Map<String, int> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'LAPORAN KLINIK',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Tanggal: ${DateTime.now().toString().split(' ').first}'),
            pw.Divider(),
            pw.SizedBox(height: 10),

            ...data.entries.map(
              (e) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(e.key, style: const pw.TextStyle(fontSize: 16)),
                    pw.Text(
                      e.value.toString(),
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            pw.SizedBox(height: 30),
            pw.Text('Dicetak oleh Admin', style: pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // ================= CARD =================
  Widget laporanCard(String title, IconData icon, int value) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Klinik')),
      body: FutureBuilder<Map<String, int>>(
        future: getLaporan(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              laporanCard(
                'Total Dokter',
                Icons.medical_services,
                data['Dokter']!,
              ),
              laporanCard('Total Pasien', Icons.people, data['Pasien']!),
              laporanCard('Total Janji', Icons.event, data['Janji']!),
              laporanCard(
                'Total Pemeriksaan',
                Icons.assignment,
                data['Pemeriksaan']!,
              ),
              laporanCard('Total Resep', Icons.medication, data['Resep']!),
              laporanCard('Total Obat', Icons.inventory, data['Obat']!),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('Cetak Laporan PDF'),
                onPressed: () => cetakPdf(data),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
