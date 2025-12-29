import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileDokterPage extends StatefulWidget {
  const ProfileDokterPage({super.key});

  @override
  State<ProfileDokterPage> createState() => _ProfileDokterPageState();
}

class _ProfileDokterPageState extends State<ProfileDokterPage> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  bool isEdit = false;
  bool isLoading = true;

  final namaController = TextEditingController();
  final alamatController = TextEditingController();
  final noHpController = TextEditingController();
  final poliController = TextEditingController();
  final spesialisController = TextEditingController();
  final pendidikanController = TextEditingController();
  final statusKerjaController = TextEditingController();
  final tempatLahirController = TextEditingController();

  DateTime? tanggalLahir;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = doc.data()!;
    namaController.text = data['nama'] ?? '';
    alamatController.text = data['alamat'] ?? '';
    noHpController.text = data['no_hp'] ?? '';
    poliController.text = data['poli'] ?? '';
    spesialisController.text = data['spesialis'] ?? '';
    pendidikanController.text = data['pendidikan_terakhir'] ?? '';
    statusKerjaController.text = data['status_kerja'] ?? '';
    tempatLahirController.text = data['tempat_lahir'] ?? '';

    if (data['tanggal_lahir'] != null) {
      tanggalLahir = (data['tanggal_lahir'] as Timestamp).toDate();
    }

    setState(() => isLoading = false);
  }

  Future<void> pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: tanggalLahir ?? DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => tanggalLahir = picked);
    }
  }

  Future<void> simpan() async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'nama': namaController.text,
      'alamat': alamatController.text,
      'no_hp': noHpController.text,
      'poli': poliController.text,
      'spesialis': spesialisController.text,
      'pendidikan_terakhir': pendidikanController.text,
      'status_kerja': statusKerjaController.text,
      'tempat_lahir': tempatLahirController.text,
      'tanggal_lahir': tanggalLahir != null
          ? Timestamp.fromDate(tanggalLahir!)
          : null,
      'update_at': Timestamp.now(),
    });

    setState(() => isEdit = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil berhasil diperbarui')),
    );
  }

  Widget field(String label, TextEditingController c) {
    return TextField(
      controller: c,
      enabled: isEdit,
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Dokter'),
        actions: [
          IconButton(
            icon: Icon(isEdit ? Icons.save : Icons.edit),
            onPressed: () {
              if (isEdit) {
                simpan();
              } else {
                setState(() => isEdit = true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            field('Nama Dokter', namaController),
            field('Tempat Lahir', tempatLahirController),

            ListTile(
              title: Text(
                tanggalLahir == null
                    ? 'Tanggal Lahir'
                    : tanggalLahir!.toString().split(' ')[0],
              ),
              trailing: isEdit ? const Icon(Icons.date_range) : null,
              onTap: isEdit ? pilihTanggal : null,
            ),

            field('Alamat', alamatController),
            field('Nomor HP', noHpController),
            field('Poli', poliController),
            field('Spesialis', spesialisController),
            field('Pendidikan Terakhir', pendidikanController),
            field('Status Kerja', statusKerjaController),
          ],
        ),
      ),
    );
  }
}
