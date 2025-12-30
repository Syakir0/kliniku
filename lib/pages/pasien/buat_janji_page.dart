import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BuatJanjiPage extends StatefulWidget {
  const BuatJanjiPage({super.key});

  @override
  State<BuatJanjiPage> createState() => _BuatJanjiPageState();
}

class _BuatJanjiPageState extends State<BuatJanjiPage> {
  String? selectedDokterId;
  String? selectedHari;
  DateTime? selectedTanggal;
  Map<String, dynamic>? dokterData;

  bool isLoading = false;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final namaController = TextEditingController();
  final noHpController = TextEditingController();
  final keteranganController = TextEditingController();

  final String jamMulai = '08:00';
  final String jamSelesai = '12:00';

  @override
  void dispose() {
    namaController.dispose();
    noHpController.dispose();
    keteranganController.dispose();
    super.dispose();
  }

  int hariKeInt(String hari) {
    switch (hari) {
      case 'Senin':
        return DateTime.monday;
      case 'Selasa':
        return DateTime.tuesday;
      case 'Rabu':
        return DateTime.wednesday;
      case 'Kamis':
        return DateTime.thursday;
      case 'Jumat':
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

    if (!mounted) return;
    if (picked != null) {
      setState(() => selectedTanggal = picked);
    }
  }

  // ================= SIMPAN JANJI =================
  Future<void> simpanJanji() async {
    if (isLoading) return;

    if (selectedDokterId == null ||
        selectedHari == null ||
        selectedTanggal == null ||
        namaController.text.isEmpty ||
        noHpController.text.isEmpty) {
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
          'nama_pasien': namaController.text.trim(),
          'no_hp_pasien': noHpController.text.trim(),
          'nama_dokter': dokterData!['nama'],
          'poli': dokterData!['poli'],
          'spesialis': dokterData!['spesialis'],
          'hari_praktek': selectedHari,
          'tanggal': Timestamp.fromDate(tanggalFix),
          'jam_mulai': jamMulai,
          'jam_selesai': jamSelesai,
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan janji: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Janji Dokter')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(labelText: 'Nama Lengkap'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: noHpController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Nomor HP'),
            ),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .where('role', isEqualTo: 'dokter')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Pilih Dokter'),
                  value: selectedDokterId,
                  items: snapshot.data!.docs.map((doc) {
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(doc['nama']),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedDokterId = v;
                      dokterData = snapshot.data!.docs
                          .firstWhere((d) => d.id == v)
                          .data() as Map<String, dynamic>;
                      selectedHari = null;
                      selectedTanggal = null;
                    });
                  },
                );
              },
            ),

            if (dokterData != null) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Hari Praktek'),
                items: ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat']
                    .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                    .toList(),
                onChanged: (v) => setState(() {
                  selectedHari = v;
                  selectedTanggal = null;
                }),
              ),
            ],

            const SizedBox(height: 12),
            ListTile(
              title: Text(
                selectedTanggal == null
                    ? 'Pilih Tanggal'
                    : selectedTanggal!.toString().split(' ')[0],
              ),
              trailing: const Icon(Icons.date_range),
              onTap: selectedHari == null ? null : pilihTanggal,
            ),

            const SizedBox(height: 12),
            TextField(
              controller: keteranganController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Keluhan'),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : simpanJanji,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan Janji'),
            ),
          ],
        ),
      ),
    );
  }
}
