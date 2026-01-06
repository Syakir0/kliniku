import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  final nikController = TextEditingController();
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

  Future<void> loadProfile() async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    final data = doc.data()!;
    nikController.text = data['NIK']?.toString() ?? '';
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

  Future<void> updateProfile() async {
    if (nikController.text.isEmpty ||
        nikController.text.length != 16 ||
        !RegExp(r'^[0-9]+$').hasMatch(nikController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan NIK yang valid (16 digit angka)')),
      );
      return;
    }

    if (namaController.text.isEmpty ||
        alamatController.text.isEmpty ||
        noHpController.text.isEmpty ||
        pekerjaanController.text.isEmpty ||
        jenisKelamin == null ||
        tanggalLahir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua data')),
      );
      return;
    }

    setState(() => isSaving = true);

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'NIK': int.parse(nikController.text),
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil berhasil diperbarui')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profil Pasien', style: TextStyle(color: Colors.white)),
        actions: [
          if (!isEditMode)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => setState(() => isEditMode = true),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF7BC9E3),
              Color(0xFFA2E5A2),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ================= FOTO PROFIL DEFAULT =================
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 50, color: Color(0xFF7BC9E3)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Profil Pasien',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // ================= FORM =================
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            buildTextField('NIK', nikController,
                                enabled: isEditMode,
                                maxLength: 16,
                                type: TextInputType.number),
                            buildTextField('Nama Lengkap', namaController, enabled: isEditMode),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: jenisKelamin,
                              decoration: const InputDecoration(
                                labelText: 'Jenis Kelamin',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: genderList
                                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                  .toList(),
                              onChanged: isEditMode ? (v) => setState(() => jenisKelamin = v) : null,
                            ),
                            const SizedBox(height: 12),
                            buildTextField('Tempat Lahir', tempatLahirController, enabled: isEditMode),
                            const SizedBox(height: 12),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Tanggal Lahir'),
                              subtitle: Text(
                                tanggalLahir == null
                                    ? '-'
                                    : '${tanggalLahir!.day}-${tanggalLahir!.month}-${tanggalLahir!.year}',
                              ),
                              trailing: isEditMode ? const Icon(Icons.date_range) : null,
                              onTap: pilihTanggal,
                            ),
                            const SizedBox(height: 12),
                            buildTextField('Pekerjaan', pekerjaanController, enabled: isEditMode),
                            buildTextField('Alamat', alamatController, enabled: isEditMode),
                            buildTextField('Nomor HP', noHpController, enabled: isEditMode, type: TextInputType.phone),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (isEditMode)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: isSaving
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Icon(Icons.save),
                                label: const Text('Simpan'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7BC9E3),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: isSaving ? null : updateProfile,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.close),
                                label: const Text('Batal'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
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
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      {bool enabled = true, int? maxLength, TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: type,
        maxLength: maxLength,
        inputFormatters: type == TextInputType.number ? [FilteringTextInputFormatter.digitsOnly] : [],
        decoration: InputDecoration(
          labelText: label,
          counterText: '',
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
