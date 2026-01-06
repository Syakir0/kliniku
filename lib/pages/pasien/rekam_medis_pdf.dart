import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RekamMedisPDF {
  static Future<void> generate(
    BuildContext context,
    String idPasien,
  ) async {
    final pdf = pw.Document();

    // ================= AMBIL DATA =================
    final pasienSnap = await FirebaseFirestore.instance
        .collection('rekam_medis')
        .doc(idPasien)
        .get();

    final pemeriksaanSnap = await FirebaseFirestore.instance
        .collection('pemeriksaan')
        .where('id_pasien', isEqualTo: idPasien)
        .orderBy('created_at', descending: true)
        .get();

    final pasien = pasienSnap.data() ?? {};

    // ================= PDF =================
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'REKAM MEDIS PASIEN',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF0097A7), // cyan
            ),
          ),
          pw.SizedBox(height: 16),

          pw.Text('NIK: ${pasien['nik'] ?? '-'}'),
          pw.Text('Golongan Darah: ${pasien['golongan_darah'] ?? '-'}'),
          pw.Text('Alergi: ${pasien['alergi'] ?? '-'}'),
          pw.Text('Penyakit Kronis: ${pasien['penyakit_kronis'] ?? '-'}'),
          pw.Text('Tinggi Badan: ${pasien['tinggi_badan'] ?? '-'}'),
          pw.Text('Berat Badan: ${pasien['berat_badan'] ?? '-'}'),
          pw.Text('Riwayat Operasi: ${pasien['riwayat_operasi'] ?? '-'}'),
          pw.Text('Catatan Umum: ${pasien['catatan_umum'] ?? '-'}'),

          pw.SizedBox(height: 24),
          pw.Divider(color: PdfColor.fromInt(0xFF0097A7), thickness: 2),
          pw.SizedBox(height: 12),

          pw.Text(
            'Riwayat Pemeriksaan',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF0097A7),
            ),
          ),
          pw.SizedBox(height: 12),

          ...pemeriksaanSnap.docs.map((doc) {
            final d = doc.data();
            final tanggal = d['tanggal'] != null
                ? (d['tanggal'] as Timestamp).toDate()
                : (d['created_at'] as Timestamp).toDate();
            final formattedTanggal =
                '${tanggal.day.toString().padLeft(2, '0')} '
                '${_monthName(tanggal.month)} ${tanggal.year}';

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 16),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromInt(0xFF0097A7)),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Tanggal: $formattedTanggal',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Diagnosa: ${d['diagnosa'] ?? '-'}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Text(
                    'Catatan: ${d['catatan'] ?? '-'}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );

    final Uint8List bytes = await pdf.save();

    // ================= PREVIEW =================
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'rekam_medis_$idPasien.pdf',
    );
  }

  // ================= UTILITY =================
  static String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return months[month];
  }
}
