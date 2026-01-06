import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dokter_detail_page.dart';

class DokterCrudPage extends StatefulWidget {
  const DokterCrudPage({super.key});

  @override
  State<DokterCrudPage> createState() => _DokterCrudPageState();
}

class _DokterCrudPageState extends State<DokterCrudPage> {
  final _formKey = GlobalKey<FormState>();

  final nipController = TextEditingController();
  final namaController = TextEditingController();
  final emailController = TextEditingController();
  final noHpController = TextEditingController();
  final alamatController = TextEditingController();
  final poliController = TextEditingController();
  final spesialisController = TextEditingController();
  final pendidikanController = TextEditingController();
  final statusKerjaController = TextEditingController();
  final tempatLahirController = TextEditingController();
  final jamMulaiController = TextEditingController();
  final jamSelesaiController = TextEditingController();

  DateTime? tanggalLahir;
  List<String> hariPraktek = [];

  final CollectionReference usersRef =
      FirebaseFirestore.instance.collection('users');

  // ================= WARNA (Cyan → Mint, NO UNGU) =================
  static const Color primaryCyan = Color(0xFF7BC9E3); // soft cyan
  static const Color mintGreen = Color(0xFF90EE90);   // mint green
  static const Color bgColor = Color(0xFFF1FDFB);     // very soft cyan bg

  // ================= UPDATE =================
  Future<void> updateDokter(String id) async {
    if (!_formKey.currentState!.validate() || tanggalLahir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua data')),
      );
      return;
    }

    await usersRef.doc(id).update({
      'NIP': nipController.text.trim(),
      'nama': namaController.text,
      'email': emailController.text,
      'no_hp': noHpController.text,
      'alamat': alamatController.text,
      'poli': poliController.text,
      'spesialis': spesialisController.text,
      'pendidikan_terakhir': pendidikanController.text,
      'status_kerja': statusKerjaController.text,
      'tempat_lahir': tempatLahirController.text,
      'tanggal_lahir': Timestamp.fromDate(tanggalLahir!),
      'hari_praktek': hariPraktek,
      'jam_mulai': jamMulaiController.text,
      'jam_selesai': jamSelesaiController.text,
      'updated_at': Timestamp.now(),
    });

    clearForm();
    Navigator.pop(context);
  }

  void clearForm() {
    nipController.clear();
    namaController.clear();
    emailController.clear();
    noHpController.clear();
    alamatController.clear();
    poliController.clear();
    spesialisController.clear();
    pendidikanController.clear();
    statusKerjaController.clear();
    tempatLahirController.clear();
    jamMulaiController.clear();
    jamSelesaiController.clear();
    tanggalLahir = null;
    hariPraktek = [];
  }

  // ================= EDIT DIALOG =================
  void showEditDialog(String id, Map<String, dynamic> data) {
    nipController.text = data['NIP']?.toString() ?? '';
    namaController.text = data['nama'] ?? '';
    emailController.text = data['email'] ?? '';
    noHpController.text = data['no_hp'] ?? '';
    alamatController.text = data['alamat'] ?? '';
    poliController.text = data['poli'] ?? '';
    spesialisController.text = data['spesialis'] ?? '';
    pendidikanController.text = data['pendidikan_terakhir'] ?? '';
    statusKerjaController.text = data['status_kerja'] ?? '';
    tempatLahirController.text = data['tempat_lahir'] ?? '';
    jamMulaiController.text = data['jam_mulai'] ?? '';
    jamSelesaiController.text = data['jam_selesai'] ?? '';

    tanggalLahir = (data['tanggal_lahir'] as Timestamp?)?.toDate();
    hariPraktek = List<String>.from(data['hari_praktek'] ?? []);

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: bgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Edit Dokter',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      buildField(
                        controller: nipController,
                        label: 'NIP',
                        isNumber: true,
                      ),
                      buildField(controller: namaController, label: 'Nama Dokter'),
                      buildField(controller: emailController, label: 'Email'),
                      buildField(controller: noHpController, label: 'No HP'),
                      buildField(controller: alamatController, label: 'Alamat'),
                      buildField(controller: poliController, label: 'Poli'),
                      buildField(controller: spesialisController, label: 'Spesialis'),
                      buildField(
                        controller: pendidikanController,
                        label: 'Pendidikan Terakhir',
                      ),
                      buildField(
                        controller: statusKerjaController,
                        label: 'Status Kerja',
                      ),
                      buildField(
                        controller: tempatLahirController,
                        label: 'Tempat Lahir',
                      ),
                      buildField(controller: jamMulaiController, label: 'Jam Mulai'),
                      buildField(
                        controller: jamSelesaiController,
                        label: 'Jam Selesai',
                      ),

                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 6,
                        children: [
                          'Senin',
                          'Selasa',
                          'Rabu',
                          'Kamis',
                          'Jumat',
                          'Sabtu',
                          'Minggu',
                        ].map((h) {
                          return FilterChip(
                            label: Text(h),
                            selected: hariPraktek.contains(h),
                            selectedColor: mintGreen.withOpacity(0.35),
                            checkmarkColor: primaryCyan,
                            onSelected: (v) {
                              setDialogState(() {
                                v
                                    ? hariPraktek.add(h)
                                    : hariPraktek.remove(h);
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 14),

                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryCyan,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          tanggalLahir == null
                              ? 'Pilih Tanggal Lahir'
                              : tanggalLahir!.toString().split(' ')[0],
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tanggalLahir ?? DateTime(1995),
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => tanggalLahir = picked);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    clearForm();
                    Navigator.pop(context);
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mintGreen,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => updateDokter(id),
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget buildField({
    required TextEditingController controller,
    required String label,
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
      ),
    );
  }

  Future<void> hapusDokter(String id) async {
    await usersRef.doc(id).delete();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Kelola Dokter'),
        centerTitle: true,
        backgroundColor: primaryCyan,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.where('role', isEqualTo: 'dokter').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada dokter'));
          }

          return ListView(
            padding: const EdgeInsets.all(14),
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: mintGreen.withOpacity(0.3),
                    child: const Icon(Icons.person, color: primaryCyan),
                  ),
                  title: Text(
                    data['nama'] ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${data['spesialis']} • ${data['poli']}\n${data['email']}',
                  ),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DokterDetailPage(data: data),
                      ),
                    );
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: primaryCyan),
                        onPressed: () => showEditDialog(doc.id, data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => hapusDokter(doc.id),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
