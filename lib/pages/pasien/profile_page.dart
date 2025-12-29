import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  final namaController = TextEditingController();
  final alamatController = TextEditingController();
  final noHpController = TextEditingController();
  final pekerjaanController = TextEditingController();
  final tempatLahirController = TextEditingController();

  String? jenisKelamin;
  DateTime? tanggalLahir;

  bool isLoading = true;
  bool isSaving = false;
  bool isEditMode = false;

  final genderList = ['Laki-laki', 'Perempuan'];

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  // ================= LOAD DATA =================
  Future<void> loadProfile() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = doc.data()!;
    namaController.text = data['nama_lengkap'] ?? '';
    alamatController.text = data['alamat'] ?? '';
    noHpController.text = data['no_hp'] ?? '';
    pekerjaanController.text = data['pekerjaan'] ?? '';
    jenisKelamin = data['jenis_kelamin'];
    tempatLahirController.text = data['tempat_lahir'] ?? '';

    if (data['tanggal_lahir'] != null) {
      tanggalLahir = (data['tanggal_lahir'] as Timestamp).toDate();
    }

    setState(() => isLoading = false);
  }

  // ================= DATE PICKER =================
  Future<void> pilihTanggal() async {
    if (!isEditMode) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: tanggalLahir ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => tanggalLahir = picked);
    }
  }

  // ================= UPDATE DATA =================
  Future<void> updateProfile() async {
    if (namaController.text.isEmpty ||
        alamatController.text.isEmpty ||
        noHpController.text.isEmpty ||
        pekerjaanController.text.isEmpty ||
        jenisKelamin == null ||
        tanggalLahir == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lengkapi semua data')));
      return;
    }

    setState(() => isSaving = true);

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'nama_lengkap': namaController.text,
      'alamat': alamatController.text,
      'no_hp': noHpController.text,
      'pekerjaan': pekerjaanController.text,
      'jenis_kelamin': jenisKelamin,
      'tempat_lahir': tempatLahirController.text,
      'tanggal_lahir': Timestamp.fromDate(tanggalLahir!),
    });

    setState(() {
      isSaving = false;
      isEditMode = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profil berhasil diperbarui')));
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pasien'),
        actions: [
          if (!isEditMode)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => isEditMode = true),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.account_circle, size: 100),
                  const SizedBox(height: 20),

                  TextField(
                    controller: namaController,
                    enabled: isEditMode,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                    ),
                  ),

                  DropdownButtonFormField<String>(
                    value: jenisKelamin,
                    decoration: const InputDecoration(
                      labelText: 'Jenis Kelamin',
                    ),
                    items: genderList
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: isEditMode
                        ? (v) => setState(() => jenisKelamin = v)
                        : null,
                  ),
                  TextField(
                    controller: tempatLahirController,
                    enabled: isEditMode,
                    decoration: const InputDecoration(
                      labelText: 'Tempat Lahir',
                    ),
                  ),

                  ListTile(
                    title: const Text('Tanggal Lahir'),
                    subtitle: Text(
                      tanggalLahir == null
                          ? '-'
                          : tanggalLahir!.toString().split(' ')[0],
                    ),
                    trailing: isEditMode ? const Icon(Icons.date_range) : null,
                    onTap: pilihTanggal,
                  ),

                  TextField(
                    controller: pekerjaanController,
                    enabled: isEditMode,
                    decoration: const InputDecoration(labelText: 'Pekerjaan'),
                  ),

                  TextField(
                    controller: alamatController,
                    enabled: isEditMode,
                    decoration: const InputDecoration(labelText: 'Alamat'),
                  ),

                  TextField(
                    controller: noHpController,
                    enabled: isEditMode,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Nomor HP'),
                  ),

                  const SizedBox(height: 24),

                  if (isEditMode)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: isSaving
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Icon(Icons.save),
                            label: const Text('Simpan'),
                            onPressed: isSaving ? null : updateProfile,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.close),
                            label: const Text('Batal'),
                            onPressed: () {
                              setState(() => isEditMode = false);
                              loadProfile();
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}
