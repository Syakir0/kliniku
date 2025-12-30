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

  final namaController = TextEditingController();
  final emailController = TextEditingController();
  final noHpController = TextEditingController();
  final alamatController = TextEditingController();
  final poliController = TextEditingController();
  final spesialisController = TextEditingController();
  final pendidikanController = TextEditingController();
  final statusKerjaController = TextEditingController();
  final tempatLahirController = TextEditingController();

  DateTime? tanggalLahir;

  final CollectionReference usersRef =
      FirebaseFirestore.instance.collection('users');

  // ===================== UPDATE =====================
  Future<void> updateDokter(String id) async {
    if (!_formKey.currentState!.validate() || tanggalLahir == null) return;

    await usersRef.doc(id).update({
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
      'updated_at': Timestamp.now(),
    });

    clearForm();
    Navigator.pop(context);
  }

  void clearForm() {
    namaController.clear();
    emailController.clear();
    noHpController.clear();
    alamatController.clear();
    poliController.clear();
    spesialisController.clear();
    pendidikanController.clear();
    statusKerjaController.clear();
    tempatLahirController.clear();
    tanggalLahir = null;
  }

  // ===================== FORM EDIT =====================
  void showEditDialog(String id, Map<String, dynamic> data) {
    namaController.text = data['nama'];
    emailController.text = data['email'];
    noHpController.text = data['no_hp'];
    alamatController.text = data['alamat'];
    poliController.text = data['poli'];
    spesialisController.text = data['spesialis'];
    pendidikanController.text = data['pendidikan_terakhir'];
    statusKerjaController.text = data['status_kerja'];
    tempatLahirController.text = data['tempat_lahir'];
    tanggalLahir = (data['tanggal_lahir'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Dokter'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                buildField(namaController, 'Nama'),
                buildField(emailController, 'Email'),
                buildField(noHpController, 'No HP'),
                buildField(alamatController, 'Alamat'),
                buildField(poliController, 'Poli'),
                buildField(spesialisController, 'Spesialis'),
                buildField(pendidikanController, 'Pendidikan Terakhir'),
                buildField(statusKerjaController, 'Status Kerja'),
                buildField(tempatLahirController, 'Tempat Lahir'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tanggalLahir ?? DateTime(1995),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => tanggalLahir = picked);
                    }
                  },
                  child: Text(
                    tanggalLahir == null
                        ? 'Pilih Tanggal Lahir'
                        : tanggalLahir!.toString().split(' ')[0],
                  ),
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
            onPressed: () => updateDokter(id),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget buildField(TextEditingController c, String label) {
    return TextFormField(
      controller: c,
      decoration: InputDecoration(labelText: label),
      validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
    );
  }

  // ===================== HAPUS =====================
  Future<void> hapusDokter(String id) async {
    await usersRef.doc(id).delete();
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Dokter')),
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
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DokterDetailPage(data: data),
                      ),
                    );
                  },
                  title: Text(data['nama']),
                  subtitle: Text(
                    '${data['spesialis']} • ${data['poli']}\n${data['email']}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
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
