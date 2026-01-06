import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BuatJanjiPage extends StatefulWidget {
  const BuatJanjiPage({super.key});

  @override
  State<BuatJanjiPage> createState() => _BuatJanjiPageState();
}

class _BuatJanjiPageState extends State<BuatJanjiPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String? selectedDokterId;
  String? selectedHari;
  DateTime? selectedTanggal;
  Map<String, dynamic>? dokterData;

  bool isLoading = false;
  bool isLoadingPasien = true;

  final nikController = TextEditingController();
  final namaController = TextEditingController();
  final noHpController = TextEditingController();
  final keteranganController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadDataPasien();
  }

  @override
  void dispose() {
    nikController.dispose();
    namaController.dispose();
    noHpController.dispose();
    keteranganController.dispose();
    super.dispose();
  }

  Future<void> loadDataPasien() async {
    final uid = _auth.currentUser!.uid;
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();

    if (data != null) {
      namaController.text = data['nama_lengkap'] ?? '';
      noHpController.text = data['no_hp'] ?? '';
      nikController.text =
          data['NIK'] != null ? data['NIK'].toString() : '';
    }

    setState(() => isLoadingPasien = false);
  }

  int hariKeInt(String hari) {
    switch (hari.toLowerCase()) {
      case 'senin':
        return DateTime.monday;
      case 'selasa':
        return DateTime.tuesday;
      case 'rabu':
        return DateTime.wednesday;
      case 'kamis':
      case 'khamis':
        return DateTime.thursday;
      case 'jumat':
        return DateTime.friday;
      default:
        return -1;
    }
  }

  Future<void> pilihTanggal() async {
    if (selectedHari == null) return;

    final targetHari = hariKeInt(selectedHari!);
    DateTime date = DateTime.now();

    while (date.weekday != targetHari) {
      date = date.add(const Duration(days: 1));
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: date,
      lastDate: date.add(const Duration(days: 30)),
      selectableDayPredicate: (d) => d.weekday == targetHari,
    );

    if (picked != null) {
      setState(() => selectedTanggal = picked);
    }
  }

  Future<void> simpanJanji() async {
    if (selectedDokterId == null ||
        selectedHari == null ||
        selectedTanggal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua data')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final uid = _auth.currentUser!.uid;

      final tanggalFix = DateTime(
        selectedTanggal!.year,
        selectedTanggal!.month,
        selectedTanggal!.day,
      );

      final counterRef = _firestore
          .collection('antrian_counter')
          .doc('${selectedDokterId}_${tanggalFix.toIso8601String()}');

      final janjiRef = _firestore.collection('janji').doc();

      await _firestore.runTransaction((transaction) async {
        final counterSnap = await transaction.get(counterRef);

        int nomorAntrian = 1;
        if (counterSnap.exists) {
          nomorAntrian = (counterSnap['last'] ?? 0) + 1;
          transaction.update(counterRef, {'last': nomorAntrian});
        } else {
          transaction.set(counterRef, {'last': 1});
        }

        transaction.set(janjiRef, {
          'id_pasien': uid,
          'id_dokter': selectedDokterId,
          'nama_pasien': namaController.text,
          'nik': int.tryParse(nikController.text),
          'no_hp_pasien': noHpController.text,
          'nama_dokter': dokterData!['nama'],
          'nip_dokter': dokterData!['NIP'],
          'poli': dokterData!['poli'],
          'spesialis': dokterData!['spesialis'],
          'hari_praktek': selectedHari,
          'jam_mulai': dokterData!['jam_mulai'],
          'jam_selesai': dokterData!['jam_selesai'],
          'tanggal': Timestamp.fromDate(tanggalFix),
          'keterangan': keteranganController.text.trim(),
          'status': 'menunggu',
          'nomer_antrian': nomorAntrian,
          'created_at': Timestamp.now(),
          'update_at': Timestamp.now(),
        });
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Janji berhasil dibuat')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan janji: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Janji Dokter'),
        backgroundColor: const Color(0xFF7BC9E3),
      ),
      body: isLoadingPasien
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7BC9E3)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ===== FORM PASIEN =====
                  buildTextField('Nama Pasien', namaController, readOnly: true),
                  const SizedBox(height: 12),
                  buildTextField('NIK', nikController, type: TextInputType.number, maxLength: 16),
                  const SizedBox(height: 12),
                  buildTextField('Nomor HP', noHpController, readOnly: true),
                  const SizedBox(height: 16),

                  // ===== PILIH DOKTER =====
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('users').where('role', isEqualTo: 'dokter').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Pilih Dokter',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        value: selectedDokterId,
                        items: snapshot.data!.docs.map((doc) {
                          return DropdownMenuItem(
                            value: doc.id,
                            child: Text(doc['nama']),
                          );
                        }).toList(),
                        onChanged: (v) {
                          final doc = snapshot.data!.docs.firstWhere((d) => d.id == v);
                          setState(() {
                            selectedDokterId = v;
                            dokterData = doc.data() as Map<String, dynamic>;
                            selectedHari = null;
                            selectedTanggal = null;
                          });
                        },
                      );
                    },
                  ),

                  if (dokterData != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dokterData!['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('NIP: ${dokterData!['NIP']}'),
                            Text('Poli: ${dokterData!['poli']}'),
                            Text('Spesialis: ${dokterData!['spesialis']}'),
                            Text('Jam Praktek: ${dokterData!['jam_mulai']} - ${dokterData!['jam_selesai']}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Hari Praktek',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      value: selectedHari,
                      items: List<String>.from(dokterData!['hari_praktek'] ?? []).map((h) {
                        return DropdownMenuItem(value: h, child: Text(h.toUpperCase()));
                      }).toList(),
                      onChanged: (v) {
                        setState(() {
                          selectedHari = v;
                          selectedTanggal = null;
                        });
                      },
                    ),
                  ],

                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(selectedTanggal == null ? 'Pilih Tanggal' : '${selectedTanggal!.day}-${selectedTanggal!.month}-${selectedTanggal!.year}'),
                    trailing: const Icon(Icons.date_range),
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: selectedHari == null ? null : pilihTanggal,
                  ),

                  const SizedBox(height: 12),
                  buildTextField('Keluhan', keteranganController, maxLines: 3),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading ? null : simpanJanji,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7BC9E3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Simpan Janji', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      {bool readOnly = false, int? maxLength, TextInputType type = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: type,
      maxLength: maxLength,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
