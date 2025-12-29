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

  // ===== INPUT PASIEN =====
  final namaController = TextEditingController();
  final noHpController = TextEditingController();
  final keteranganController = TextEditingController();

  // ===== JAM PRAKTEK PERMANEN =====
  final String jamMulai = '08:00';
  final String jamSelesai = '12:00';

  // ================= KONVERSI HARI =================
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
        return 0;
    }
  }

  // ================= PILIH TANGGAL =================
  Future<void> pilihTanggal() async {
    if (selectedHari == null) return;

    final targetHari = hariKeInt(selectedHari!);

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      selectableDayPredicate: (date) => date.weekday == targetHari,
    );

    if (picked != null) {
      setState(() => selectedTanggal = picked);
    }
  }

  // ================= SIMPAN JANJI =================
  Future<void> simpanJanji() async {
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

      // ===== HITUNG NOMOR ANTRIAN =====
      final antrianSnapshot = await _firestore
          .collection('janji')
          .where('id_dokter', isEqualTo: selectedDokterId)
          .where('tanggal', isEqualTo: Timestamp.fromDate(tanggalFix))
          .get();

      final int nomorAntrian = antrianSnapshot.docs.length + 1;

      // ===== SIMPAN JANJI =====
      await _firestore.collection('janji').add({
        'id_pasien': uid,
        'id_dokter': selectedDokterId,

        'nama_pasien': namaController.text.trim(),
        'no_hp_pasien': noHpController.text.trim(),

        'nama_dokter': dokterData!['nama'],
        'poli': dokterData!['poli'],
        'spesialis': dokterData!['spesialis'],

        'hari_praktek': selectedHari,
        'tanggal': Timestamp.fromDate(tanggalFix),

        // JAM PERMANEN
        'jam_mulai': jamMulai,
        'jam_selesai': jamSelesai,

        'keterangan': keteranganController.text.trim(),
        'status': 'menunggu',
        'nomer_antrian': nomorAntrian, // INTEGER

        'created_at': Timestamp.now(),
        'update_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Janji berhasil dibuat')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isLoading = false);
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
            // ===== NAMA PASIEN =====
            TextField(
              controller: namaController,
              decoration: const InputDecoration(labelText: 'Nama Lengkap'),
            ),

            const SizedBox(height: 12),

            // ===== NO HP =====
            TextField(
              controller: noHpController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Nomor HP'),
            ),

            const SizedBox(height: 12),

            // ===== PILIH DOKTER =====
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
                  value: snapshot.data!.docs.any((d) => d.id == selectedDokterId)
                      ? selectedDokterId
                      : null,
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

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Poli: ${dokterData!['poli']}'),
                      Text('Jam Praktek: $jamMulai - $jamSelesai'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Hari Praktek'),
                items: ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat']
                    .map((h) =>
                        DropdownMenuItem(value: h, child: Text(h)))
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

            // ===== KELUHAN =====
            TextField(
              controller: keteranganController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Keluhan'),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : simpanJanji,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Simpan Janji'),
            ),
          ],
        ),
      ),
    );
  }
}
