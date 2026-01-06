import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class ProfileDokterPage extends StatefulWidget {
  const ProfileDokterPage({super.key});

  @override
  State<ProfileDokterPage> createState() => _ProfileDokterPageState();
}

class _ProfileDokterPageState extends State<ProfileDokterPage> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  bool isLoading = true;
  bool isSaving = false;
  bool isEditMode = false;

  // Controllers
  final nipController = TextEditingController();
  final namaController = TextEditingController();
  final tempatLahirController = TextEditingController();
  final alamatController = TextEditingController();
  final noHpController = TextEditingController();
  final poliController = TextEditingController();
  final spesialisController = TextEditingController();
  final pendidikanController = TextEditingController();
  final statusKerjaController = TextEditingController();
  final jamMulaiController = TextEditingController();
  final jamSelesaiController = TextEditingController();

  DateTime? tanggalLahir;
  List<String> hariPraktek = [];
  final List<String> semuaHari = ['senin', 'selasa', 'rabu', 'khamis', 'jumat'];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    final data = doc.data()!;
    nipController.text = data['NIP']?.toString() ?? '';
    namaController.text = data['nama'] ?? '';
    tempatLahirController.text = data['tempat_lahir'] ?? '';
    alamatController.text = data['alamat'] ?? '';
    noHpController.text = data['no_hp'] ?? '';
    poliController.text = data['poli'] ?? '';
    spesialisController.text = data['spesialis'] ?? '';
    pendidikanController.text = data['pendidikan_terakhir'] ?? '';
    statusKerjaController.text = data['status_kerja'] ?? '';
    jamMulaiController.text = data['jam_mulai'] ?? '';
    jamSelesaiController.text = data['jam_selesai'] ?? '';
    hariPraktek = List<String>.from(data['hari_praktek'] ?? []);

    if (data['tanggal_lahir'] != null) {
      tanggalLahir = (data['tanggal_lahir'] as Timestamp).toDate();
    }

    setState(() => isLoading = false);
  }

  Future<void> pilihTanggal() async {
    if (!isEditMode) return;

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
    setState(() => isSaving = true);

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'NIP': nipController.text.trim(),
      'nama': namaController.text.trim(),
      'tempat_lahir': tempatLahirController.text.trim(),
      'alamat': alamatController.text.trim(),
      'no_hp': noHpController.text.trim(),
      'poli': poliController.text.trim(),
      'spesialis': spesialisController.text.trim(),
      'pendidikan_terakhir': pendidikanController.text.trim(),
      'status_kerja': statusKerjaController.text.trim(),
      'jam_mulai': jamMulaiController.text.trim(),
      'jam_selesai': jamSelesaiController.text.trim(),
      'hari_praktek': hariPraktek,
      'tanggal_lahir':
          tanggalLahir != null ? Timestamp.fromDate(tanggalLahir!) : null,
      'update_at': Timestamp.now(),
    });

    setState(() {
      isSaving = false;
      isEditMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil dokter berhasil diperbarui')),
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      {bool enabled = true, TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: type,
        inputFormatters: type == TextInputType.number
            ? [FilteringTextInputFormatter.digitsOnly]
            : [],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
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
        title: const Text('Profil Dokter', style: TextStyle(color: Colors.white)),
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
            colors: [Color(0xFF7BC9E3), Color(0xFFA2E5A2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ================= AVATAR =================
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 50, color: Color(0xFF7BC9E3)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Profil Dokter',
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
                            buildTextField('NIP', nipController,
                                enabled: isEditMode, type: TextInputType.number),
                            buildTextField('Nama Dokter', namaController,
                                enabled: isEditMode),
                            buildTextField('Tempat Lahir', tempatLahirController,
                                enabled: isEditMode),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Tanggal Lahir'),
                              subtitle: Text(tanggalLahir == null
                                  ? '-'
                                  : '${tanggalLahir!.day}-${tanggalLahir!.month}-${tanggalLahir!.year}'),
                              trailing: isEditMode
                                  ? const Icon(Icons.date_range)
                                  : null,
                              onTap: pilihTanggal,
                            ),
                            buildTextField('Alamat', alamatController,
                                enabled: isEditMode),
                            buildTextField('Nomor HP', noHpController,
                                enabled: isEditMode,
                                type: TextInputType.phone),
                            buildTextField('Poli', poliController,
                                enabled: isEditMode),
                            buildTextField('Spesialis', spesialisController,
                                enabled: isEditMode),
                            buildTextField('Pendidikan Terakhir', pendidikanController,
                                enabled: isEditMode),
                            buildTextField('Status Kerja', statusKerjaController,
                                enabled: isEditMode),
                            buildTextField('Jam Mulai', jamMulaiController,
                                enabled: isEditMode),
                            buildTextField('Jam Selesai', jamSelesaiController,
                                enabled: isEditMode),

                            const SizedBox(height: 12),
                            const Text('Hari Praktek',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Wrap(
                              children: semuaHari.map((h) {
                                return CheckboxListTile(
                                  title: Text(h.toUpperCase()),
                                  value: hariPraktek.contains(h),
                                  onChanged: !isEditMode
                                      ? null
                                      : (v) {
                                          setState(() {
                                            v == true
                                                ? hariPraktek.add(h)
                                                : hariPraktek.remove(h);
                                          });
                                        },
                                );
                              }).toList(),
                            ),
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
                                onPressed: isSaving ? null : simpan,
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
                                  loadData();
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
}
