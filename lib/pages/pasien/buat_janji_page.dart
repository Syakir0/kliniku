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
  DateTime? selectedDate;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================= PILIH TANGGAL =================
  Future<void> pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // ================= SIMPAN JANJI =================
  Future<void> simpanJanji() async {
    if (selectedDokterId == null || selectedDate == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    // 1. Simpan janji
    final janjiRef = await _firestore.collection('janji').add({
      'id_pasien': user.uid,
      'id_dokter': selectedDokterId,
      'tanggal': Timestamp.fromDate(selectedDate!),
      'status': 'menunggu',
      'created_at': Timestamp.now(),
    });

    // 2. Hitung nomor antrian
    final antrianSnapshot = await _firestore
        .collection('antrian')
        .where('id_dokter', isEqualTo: selectedDokterId)
        .where('tanggal', isEqualTo: Timestamp.fromDate(selectedDate!))
        .get();

    final nomorAntrian = antrianSnapshot.docs.length + 1;

    // 3. Simpan antrian
    await _firestore.collection('antrian').add({
      'id_janji': janjiRef.id,
      'id_dokter': selectedDokterId,
      'nomor': nomorAntrian,
      'tanggal': Timestamp.fromDate(selectedDate!),
      'status': 'menunggu',
      'created_at': Timestamp.now(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Janji berhasil dibuat')));

    Navigator.pop(context);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Janji')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pilih Dokter',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // ===== DROPDOWN DOKTER =====
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('dokter').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                return DropdownButtonFormField<String>(
                  value: selectedDokterId,
                  hint: const Text('Pilih Dokter'),
                  items: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(data['nama']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDokterId = value;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            // ===== PILIH TANGGAL =====
            ElevatedButton(
              onPressed: pilihTanggal,
              child: Text(
                selectedDate == null
                    ? 'Pilih Tanggal'
                    : selectedDate!.toLocal().toString().split(' ')[0],
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: simpanJanji,
              child: const Text('Simpan Janji'),
            ),
          ],
        ),
      ),
    );
  }
}
