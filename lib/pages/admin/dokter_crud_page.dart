import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DokterCrudPage extends StatefulWidget {
  const DokterCrudPage({super.key});

  @override
  State<DokterCrudPage> createState() => _DokterCrudPageState();
}

class _DokterCrudPageState extends State<DokterCrudPage> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController spesialisController = TextEditingController();
  final TextEditingController jadwalController = TextEditingController();

  final CollectionReference dokterCollection = FirebaseFirestore.instance
      .collection('dokter');

  // ================= TAMBAH DOKTER =================
  Future<void> tambahDokter() async {
    if (namaController.text.isEmpty ||
        spesialisController.text.isEmpty ||
        jadwalController.text.isEmpty) {
      return;
    }

    await dokterCollection.add({
      'nama': namaController.text,
      'spesialis': spesialisController.text,
      'jadwal': jadwalController.text,
      'aktif': true,
      'created_at': Timestamp.now(),
    });

    namaController.clear();
    spesialisController.clear();
    jadwalController.clear();

    Navigator.pop(context);
  }

  Future<void> updateDokter(String id) async {
    if (namaController.text.isEmpty ||
        spesialisController.text.isEmpty ||
        jadwalController.text.isEmpty) {
      return;
    }

    await dokterCollection.doc(id).update({
      'nama': namaController.text,
      'spesialis': spesialisController.text,
      'jadwal': jadwalController.text,
      'updated_at': Timestamp.now(),
    });

    namaController.clear();
    spesialisController.clear();
    jadwalController.clear();

    Navigator.pop(context);
  }

  // ================= DIALOG TAMBAH =================
  void showTambahDokterDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Dokter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(labelText: 'Nama Dokter'),
            ),
            TextField(
              controller: spesialisController,
              decoration: const InputDecoration(labelText: 'Spesialis'),
            ),
            TextField(
              controller: jadwalController,
              decoration: const InputDecoration(labelText: 'Jadwal'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(onPressed: tambahDokter, child: const Text('Simpan')),
        ],
      ),
    );
  }

  void showEditDokterDialog(String id, Map<String, dynamic> data) {
    namaController.text = data['nama'];
    spesialisController.text = data['spesialis'];
    jadwalController.text = data['jadwal'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Dokter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(labelText: 'Nama Dokter'),
            ),
            TextField(
              controller: spesialisController,
              decoration: const InputDecoration(labelText: 'Spesialis'),
            ),
            TextField(
              controller: jadwalController,
              decoration: const InputDecoration(labelText: 'Jadwal'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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

  // ================= HAPUS =================
  Future<void> hapusDokter(String id) async {
    await dokterCollection.doc(id).delete();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Dokter')),
      floatingActionButton: FloatingActionButton(
        onPressed: showTambahDokterDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: dokterCollection.orderBy('created_at').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada data dokter'));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(data['nama']),
                  subtitle: Text('${data['spesialis']} | ${data['jadwal']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => showEditDokterDialog(doc.id, data),
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
