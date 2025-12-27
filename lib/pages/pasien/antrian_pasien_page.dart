import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AntrianPasienPage extends StatelessWidget {
  const AntrianPasienPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Antrian Saya')),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('janji')
            .where('id_pasien', isEqualTo: uid)
            .snapshots(),
        builder: (context, janjiSnapshot) {
          if (!janjiSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (janjiSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada antrian'));
          }

          return ListView(
            children: janjiSnapshot.data!.docs.map((janjiDoc) {
              final janjiData = janjiDoc.data() as Map<String, dynamic>;

              return StreamBuilder<QuerySnapshot>(
                stream: firestore
                    .collection('antrian')
                    .where('id_janji', isEqualTo: janjiDoc.id)
                    .snapshots(),
                builder: (context, antrianSnapshot) {
                  if (!antrianSnapshot.hasData) {
                    return const SizedBox();
                  }

                  if (antrianSnapshot.data!.docs.isEmpty) {
                    return const SizedBox();
                  }

                  final antrianDoc = antrianSnapshot.data!.docs.first;
                  final antrianData = antrianDoc.data() as Map<String, dynamic>;

                  return FutureBuilder<DocumentSnapshot>(
                    future: firestore
                        .collection('dokter')
                        .doc(janjiData['id_dokter'])
                        .get(),
                    builder: (context, dokterSnapshot) {
                      if (!dokterSnapshot.hasData) {
                        return const SizedBox();
                      }

                      final dokterData =
                          dokterSnapshot.data!.data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text(
                            'Dokter: ${dokterData['nama']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nomor Antrian: ${antrianData['nomor']}'),
                              Text('Status: ${antrianData['status']}'),
                              Text(
                                'Tanggal: ${(antrianData['tanggal'] as Timestamp).toDate().toString().split(' ')[0]}',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
