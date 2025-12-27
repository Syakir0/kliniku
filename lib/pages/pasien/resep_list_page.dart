import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResepListPage extends StatelessWidget {
  final String idPemeriksaan;

  const ResepListPage({
    super.key,
    required this.idPemeriksaan,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resep Obat')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('resep')
            .where('id_pemeriksaan', isEqualTo: idPemeriksaan)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada resep'));
          }

          final resepData =
              snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final List obatList = resepData['obat'];

          return ListView.builder(
            itemCount: obatList.length,
            itemBuilder: (context, index) {
              final obat = obatList[index];

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const Icon(Icons.medical_services),
                  title: Text(obat['nama']),
                  subtitle: Text('Jumlah: ${obat['jumlah']}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
