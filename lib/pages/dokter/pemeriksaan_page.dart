import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'resep_page.dart';

class PemeriksaanPage extends StatefulWidget {
  final String idJanji;
  final String idPasien;
  final String idDokter;

  const PemeriksaanPage({
    super.key,
    required this.idJanji,
    required this.idPasien,
    required this.idDokter,
  });

  @override
  State<PemeriksaanPage> createState() => _PemeriksaanPageState();
}

class _PemeriksaanPageState extends State<PemeriksaanPage> {
  final diagnosaController = TextEditingController();
  final catatanController = TextEditingController();

  bool isLoading = false;
  String? pemeriksaanId; // 🔑 INI KUNCI UTAMA

  @override
  void dispose() {
    diagnosaController.dispose();
    catatanController.dispose();
    super.dispose();
  }

  Future<void> simpanPemeriksaan() async {
    if (diagnosaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diagnosa wajib diisi')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final ref =
          await FirebaseFirestore.instance.collection('pemeriksaan').add({
        'id_pasien': widget.idPasien,
        'id_dokter': widget.idDokter,
        'id_janji': widget.idJanji,
        'diagnosa': diagnosaController.text,
        'catatan': catatanController.text,
        'tanggal': Timestamp.now(),
        'created_at': Timestamp.now(),
      });

      pemeriksaanId = ref.id;

      // update status antrian
      final antrianQuery = await FirebaseFirestore.instance
          .collection('antrian')
          .where('id_janji', isEqualTo: widget.idJanji)
          .get();

      for (var doc in antrianQuery.docs) {
        await doc.reference.update({'status': 'selesai'});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pemeriksaan berhasil disimpan')),
        );
        setState(() {}); // refresh UI
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pemeriksaan Pasien')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: diagnosaController,
              decoration: const InputDecoration(
                labelText: 'Diagnosa',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: catatanController,
              decoration: const InputDecoration(
                labelText: 'Catatan',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // SIMPAN PEMERIKSAAN
            ElevatedButton(
              onPressed: isLoading ? null : simpanPemeriksaan,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Simpan Pemeriksaan'),
            ),

            const SizedBox(height: 12),

            // BUAT RESEP (MUNCUL SETELAH ADA ID)
            if (pemeriksaanId != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ResepPage(
                        idPemeriksaan: pemeriksaanId!,
                      ),
                    ),
                  );
                },
                child: const Text('Buat Resep'),
              ),
          ],
        ),
      ),
    );
  }
}
