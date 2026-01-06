import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'pemeriksaan_page.dart';

class AntrianDokterPage extends StatefulWidget {
  const AntrianDokterPage({super.key});

  @override
  State<AntrianDokterPage> createState() => _AntrianDokterPageState();
}

class _AntrianDokterPageState extends State<AntrianDokterPage> {
  final String uidDokter = FirebaseAuth.instance.currentUser!.uid;
  DateTime? selectedDate;

  String formatTanggal(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    return DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(timestamp.toDate());
  }

  Stream<QuerySnapshot> getAntrianStream() {
    Query query = FirebaseFirestore.instance
        .collection('janji')
        .where('id_dokter', isEqualTo: uidDokter);

    if (selectedDate != null) {
      final startOfDay =
          DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
      query = query.where('tanggal', isEqualTo: Timestamp.fromDate(startOfDay));
    }

    return query.orderBy('status').orderBy('nomer_antrian').snapshots();
  }

  Future<void> pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      locale: const Locale('id', 'ID'),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrian Pasien'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Pilih Tanggal',
            onPressed: pilihTanggal,
          ),
          if (selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Reset Filter',
              onPressed: () => setState(() => selectedDate = null),
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7BC9E3), Color(0xFFA2E5A2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (selectedDate != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Tanggal dipilih: ${DateFormat('dd MMM yyyy', 'id_ID').format(selectedDate!)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: getAntrianStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Gagal memuat data'),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'Tidak ada antrian',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;

                        final nomor = data['nomer_antrian'] ?? 0;
                        final namaPasien = data['nama_pasien'] ?? '-';
                        final nik = (data['nik'] ?? data['NIK'])?.toString() ?? '-';
                        final noHp = data['no_hp_pasien'] ?? '-';
                        final poli = data['poli'] ?? '-';
                        final jam =
                            '${data['jam_mulai'] ?? '-'} - ${data['jam_selesai'] ?? '-'}';
                        final status = data['status'] ?? 'menunggu';
                        final tanggal = formatTanggal(data['tanggal'] as Timestamp?);

                        Color statusColor = status == 'selesai'
                            ? Colors.green
                            : status == 'batal'
                                ? Colors.red
                                : Colors.orange;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: statusColor,
                              child: Text(
                                nomor.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              namaPasien,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('NIK: $nik'),
                                Text('Tanggal: $tanggal'),
                                Text('Jam: $jam'),
                                Text('Poli: $poli'),
                                Text('No HP: $noHp'),
                                Text(
                                  'Status: ${status.toUpperCase()}',
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7BC9E3),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Periksa'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PemeriksaanPage(
                                      idJanji: docs[index].id,
                                      idPasien: data['id_pasien'],
                                      idDokter: uidDokter,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
