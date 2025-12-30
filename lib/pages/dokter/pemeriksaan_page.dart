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
  String? pemeriksaanId;

  String namaPasien = '';
  String namaDokter = '';

  @override
  void dispose() {
    diagnosaController.dispose();
    catatanController.dispose();
    super.dispose();
  }

  // ================= SIMPAN PEMERIKSAAN =================
  Future<void> simpanPemeriksaan() async {
    if (diagnosaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Diagnosa wajib diisi')));
      return;
    }

    setState(() => isLoading = true);

    try {
      // Simpan pemeriksaan
      final ref = await FirebaseFirestore.instance
          .collection('pemeriksaan')
          .add({
            'id_pasien': widget.idPasien,
            'id_dokter': widget.idDokter,
            'id_janji': widget.idJanji,
            'diagnosa': diagnosaController.text,
            'catatan': catatanController.text,
            'status_pemeriksaan': 'selesai',
            'tanggal': Timestamp.now(),
            'created_at': Timestamp.now(),
          });

      pemeriksaanId = ref.id;

      // Update status janji
      await FirebaseFirestore.instance
          .collection('janji')
          .doc(widget.idJanji)
          .update({'status': 'selesai', 'update_at': Timestamp.now()});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pemeriksaan berhasil disimpan')),
        );
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan pemeriksaan: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pemeriksaan Pasien')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('janji')
            .doc(widget.idJanji)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // Simpan nama (sekali saja)
          namaPasien = data['nama_pasien'] ?? '';
          namaDokter = data['nama_dokter'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= DATA PASIEN =================
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nama Pasien: $namaPasien',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text('No HP: ${data['no_hp_pasien'] ?? '-'}'),
                        const SizedBox(height: 6),
                        Text('Keluhan: ${data['keterangan'] ?? '-'}'),
                        const SizedBox(height: 6),
                        Text(
                          'Status: ${data['status']}',
                          style: TextStyle(
                            color: data['status'] == 'selesai'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ================= FORM PEMERIKSAAN =================
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
                    labelText: 'Catatan Dokter',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: isLoading ? null : simpanPemeriksaan,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Simpan Pemeriksaan'),
                ),

                const SizedBox(height: 12),

                // ================= BUAT RESEP =================
                ElevatedButton(
                  onPressed: pemeriksaanId == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ResepPage(
                                idPemeriksaan: pemeriksaanId!,
                                idPasien: widget.idPasien,
                                idDokter: widget.idDokter,
                                namaPasien: namaPasien,
                                namaDokter: namaDokter,
                              ),
                            ),
                          );
                        },
                  child: const Text('Buat Resep'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
