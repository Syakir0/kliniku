import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResepPage extends StatefulWidget {
  final String idPemeriksaan;

  const ResepPage({super.key, required this.idPemeriksaan});

  @override
  State<ResepPage> createState() => _ResepPageState();
}

class _ResepPageState extends State<ResepPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String? selectedObatId;
  String? selectedObatNama;
  final TextEditingController jumlahController = TextEditingController();

  bool isLoading = false;

  List<Map<String, dynamic>> obatList = [];

  @override
  void initState() {
    super.initState();
    loadObat();
  }

  @override
  void dispose() {
    jumlahController.dispose();
    super.dispose();
  }

  Future<void> loadObat() async {
    try {
      final snapshot = await firestore.collection('obat').get();
      setState(() {
        obatList = snapshot.docs
            .map((e) => {'id': e.id, 'nama': e['nama']})
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat obat: $e')));
    }
  }

  Future<void> simpanResep() async {
    if (selectedObatId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih obat terlebih dahulu')),
      );
      return;
    }

    if (jumlahController.text.isEmpty ||
        int.tryParse(jumlahController.text) == null ||
        int.parse(jumlahController.text) <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Jumlah obat tidak valid')));
      return;
    }

    setState(() => isLoading = true);

    try {
      await firestore.collection('resep').add({
        'id_pemeriksaan': widget.idPemeriksaan,
        'obat': [
          {
            'id_obat': selectedObatId,
            'nama': selectedObatNama,
            'jumlah': int.parse(jumlahController.text),
          },
        ],
        'created_at': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resep berhasil disimpan')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan resep: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Resep')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedObatId,
              hint: const Text('Pilih Obat'),
              items: obatList
                  .map(
                    (obat) => DropdownMenuItem<String>(
                      value: obat['id'],
                      child: Text(obat['nama']),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                final obat = obatList.firstWhere((o) => o['id'] == value);
                setState(() {
                  selectedObatId = obat['id'];
                  selectedObatNama = obat['nama'];
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: jumlahController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah Obat',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: isLoading ? null : simpanResep,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Simpan Resep'),
            ),
          ],
        ),
      ),
    );
  }
}
