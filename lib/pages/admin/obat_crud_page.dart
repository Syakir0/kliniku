import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ObatCrudPage extends StatefulWidget {
  const ObatCrudPage({super.key});

  @override
  State<ObatCrudPage> createState() => _ObatCrudPageState();
}

class _ObatCrudPageState extends State<ObatCrudPage> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController stokController = TextEditingController();
  final TextEditingController hargaController = TextEditingController();

  final CollectionReference obatCollection = FirebaseFirestore.instance
      .collection('obat');

  // ================= TAMBAH OBAT =================
  Future<void> tambahObat() async {
    if (namaController.text.isEmpty ||
        stokController.text.isEmpty ||
        hargaController.text.isEmpty) {
      return;
    }

    await obatCollection.add({
      'nama': namaController.text,
      'stok': int.parse(stokController.text),
      'harga': int.parse(hargaController.text),
      'created_at': Timestamp.now(),
    });

    namaController.clear();
    stokController.clear();
    hargaController.clear();

    Navigator.pop(context);
  }

  Future<void> updateObat(String id) async {
    if (namaController.text.isEmpty ||
        stokController.text.isEmpty ||
        hargaController.text.isEmpty) {
      return;
    }

    await obatCollection.doc(id).update({
      'nama': namaController.text,
      'stok': int.parse(stokController.text),
      'harga': int.parse(hargaController.text),
      'updated_at': Timestamp.now(),
    });

    namaController.clear();
    stokController.clear();
    hargaController.clear();

    Navigator.pop(context);
  }

  // ================= DIALOG TAMBAH =================
  void showTambahObatDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Obat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(labelText: 'Nama Obat'),
            ),
            TextField(
              controller: stokController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stok'),
            ),
            TextField(
              controller: hargaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Harga'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(onPressed: tambahObat, child: const Text('Simpan')),
        ],
      ),
    );
  }

  void showEditObatDialog(String id, Map<String, dynamic> data) {
    namaController.text = data['nama'].toString();
    stokController.text = data['stok'].toString();
    hargaController.text = data['harga'].toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Obat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(labelText: 'Nama Obat'),
            ),
            TextField(
              controller: stokController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stok'),
            ),
            TextField(
              controller: hargaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Harga'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => updateObat(id),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // ================= HAPUS OBAT =================
  Future<void> hapusObat(String id) async {
    await obatCollection.doc(id).delete();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Obat')),
      floatingActionButton: FloatingActionButton(
        onPressed: showTambahObatDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: obatCollection.orderBy('created_at').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada data obat'));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(data['nama']),
                  subtitle: Text(
                    'Stok: ${data['stok']} | Harga: Rp ${data['harga']}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => showEditObatDialog(doc.id, data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => hapusObat(doc.id),
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
