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
  // ===== PEMERIKSAAN =====
  final diagnosaController = TextEditingController();
  final catatanController = TextEditingController();

  // ===== REKAM MEDIS =====
  final alergiController = TextEditingController();
  final penyakitKronisController = TextEditingController();
  final catatanUmumController = TextEditingController();
  final tinggiBadanController = TextEditingController();
  final beratBadanController = TextEditingController();
  final golonganDarahController = TextEditingController();
  final riwayatOperasiController = TextEditingController();

  bool isLoading = false;
  String? pemeriksaanId;
  Map<String, dynamic>? dataJanji;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    diagnosaController.dispose();
    catatanController.dispose();
    alergiController.dispose();
    penyakitKronisController.dispose();
    catatanUmumController.dispose();
    tinggiBadanController.dispose();
    beratBadanController.dispose();
    golonganDarahController.dispose();
    riwayatOperasiController.dispose();
    super.dispose();
  }

  // ================= LOAD DATA =================
  Future<void> loadData() async {
    final firestore = FirebaseFirestore.instance;

    final janjiSnap =
        await firestore.collection('janji').doc(widget.idJanji).get();

    final rekamSnap =
        await firestore.collection('rekam_medis').doc(widget.idPasien).get();

    dataJanji = janjiSnap.data();

    if (rekamSnap.exists) {
      final rm = rekamSnap.data()!;
      alergiController.text = rm['alergi'] ?? '';
      penyakitKronisController.text = rm['penyakit_kronis'] ?? '';
      catatanUmumController.text = rm['catatan_umum'] ?? '';
      tinggiBadanController.text = rm['tinggi_badan'] ?? '';
      beratBadanController.text = rm['berat_badan'] ?? '';
      golonganDarahController.text = rm['golongan_darah'] ?? '';
      riwayatOperasiController.text = rm['riwayat_operasi'] ?? '';
    }

    setState(() {});
  }

  // ================= SIMPAN PEMERIKSAAN =================
  Future<void> simpanPemeriksaan() async {
    if (diagnosaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diagnosa wajib diisi')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;

      // 🔹 SIMPAN PEMERIKSAAN
      final ref = await firestore.collection('pemeriksaan').add({
        'id_pasien': widget.idPasien,
        'id_dokter': widget.idDokter,
        'id_janji': widget.idJanji,
        'nik': dataJanji?['nik'],
        'diagnosa': diagnosaController.text.trim(),
        'catatan': catatanController.text.trim(),
        'status_pemeriksaan': 'selesai',
        'tanggal': Timestamp.now(),
        'created_at': Timestamp.now(),
      });

      pemeriksaanId = ref.id;

      // 🔹 UPDATE / CREATE REKAM MEDIS
      await firestore.collection('rekam_medis').doc(widget.idPasien).set({
        'id_pasien': widget.idPasien,
        'nik': dataJanji?['nik'],
        'alergi': alergiController.text.trim(),
        'penyakit_kronis': penyakitKronisController.text.trim(),
        'tinggi_badan': tinggiBadanController.text.trim(),
        'berat_badan': beratBadanController.text.trim(),
        'golongan_darah': golonganDarahController.text.trim(),
        'riwayat_operasi': riwayatOperasiController.text.trim(),
        'catatan_umum': catatanUmumController.text.trim(),
        'update_at': Timestamp.now(),
        'created_at': Timestamp.now(),
      }, SetOptions(merge: true));

      await firestore.collection('janji').doc(widget.idJanji).update({
        'status': 'selesai',
        'update_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pemeriksaan berhasil disimpan')),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (dataJanji == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Pemeriksaan Pasien'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7BC9E3), Color(0xFFA2E5A2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ===== DATA PASIEN =====
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nama Pasien: ${dataJanji!['nama_pasien']}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('NIK: ${dataJanji!['nik']}'),
                        Text('Keluhan: ${dataJanji!['keterangan']}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ===== REKAM MEDIS =====
                const Text('Rekam Medis',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                const SizedBox(height: 8),
                _styledField('Alergi', alergiController),
                _styledField('Penyakit Kronis', penyakitKronisController),
                _styledField('Tinggi Badan', tinggiBadanController),
                _styledField('Berat Badan', beratBadanController),
                _styledField('Golongan Darah', golonganDarahController),
                _styledField('Riwayat Operasi', riwayatOperasiController),
                _styledField('Catatan Umum', catatanUmumController),

                const SizedBox(height: 20),

                // ===== PEMERIKSAAN =====
                _styledField('Diagnosa', diagnosaController, maxLines: 2),
                const SizedBox(height: 12),
                _styledField('Catatan Dokter', catatanController, maxLines: 3),

                const SizedBox(height: 24),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7BC9E3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isLoading ? null : simpanPemeriksaan,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Simpan Pemeriksaan'),
                ),

                const SizedBox(height: 12),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
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
                                namaPasien: dataJanji!['nama_pasien'],
                                namaDokter: dataJanji!['nama_dokter'],
                              ),
                            ),
                          );
                        },
                  child: const Text('Buat Resep'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _styledField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
