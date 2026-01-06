import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AntrianPasienPage extends StatelessWidget {
  const AntrianPasienPage({super.key});

  int statusPriority(String? status) {
    final s = status?.toLowerCase().trim() ?? '';

    if (s == 'menunggu') return 0;
    if (s == 'selesai') return 1;
    if (s == 'batal') return 2;
    return 3;
  }

  Color statusColor(String status) {
    switch (status.toLowerCase().trim()) {
      case 'batal':
        return Colors.redAccent;
      case 'selesai':
        return Colors.green;
      default:
        return Colors.orangeAccent;
    }
  }

  IconData statusIcon(String status) {
    switch (status.toLowerCase().trim()) {
      case 'batal':
        return Icons.cancel;
      case 'selesai':
        return Icons.check_circle;
      default:
        return Icons.access_time;
    }
  }

  String statusText(String status) {
    switch (status.toLowerCase().trim()) {
      case 'batal':
        return 'Dibatalkan';
      case 'selesai':
        return 'Selesai';
      default:
        return 'Menunggu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrian Saya'),
        backgroundColor: const Color(0xFF7BC9E3),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7BC9E3), Color(0xFFA2E5A2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: firestore
              .collection('janji')
              .where('id_pasien', isEqualTo: uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Center(
                  child: Text(
                'Belum ada antrian',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ));
            }

            // ================= SORT ANTRIAN =================
            final sortedDocs = docs.toList()
              ..sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;

                final statusCompare = statusPriority(aData['status'])
                    .compareTo(statusPriority(bData['status']));

                if (statusCompare != 0) return statusCompare;

                final aDate = (aData['tanggal'] as Timestamp?)?.toDate() ??
                    DateTime(2000);
                final bDate = (bData['tanggal'] as Timestamp?)?.toDate() ??
                    DateTime(2000);

                return bDate.compareTo(aDate); // terbaru di atas
              });

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: sortedDocs.length,
              itemBuilder: (context, index) {
                final doc = sortedDocs[index];
                final data = doc.data() as Map<String, dynamic>;
                final s = data['status'] ?? 'menunggu';
                final color = statusColor(s);
                final icon = statusIcon(s);
                final text = statusText(s);

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.2),
                      child: Icon(icon, color: color),
                    ),
                    title: Text(
                      'Dr. ${data['nama_dokter']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Poli: ${data['poli']}'),
                        Text('Nomor Antrian: ${data['nomer_antrian']}'),
                        Text(
                          'Tanggal: ${(data['tanggal'] as Timestamp).toDate().toString().split(' ')[0]}',
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Status: $text',
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    trailing: s.toLowerCase().trim() == 'menunggu'
                        ? IconButton(
                            icon: Icon(Icons.close, color: Colors.redAccent),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Batalkan Janji'),
                                  content: const Text(
                                      'Apakah Anda yakin ingin membatalkan janji ini?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context),
                                      child: const Text('Tidak'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent),
                                      onPressed: () async {
                                        await firestore
                                            .collection('janji')
                                            .doc(doc.id)
                                            .update({
                                          'status': 'batal',
                                          'update_at': Timestamp.now(),
                                        });
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Ya, Batalkan'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : null,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
