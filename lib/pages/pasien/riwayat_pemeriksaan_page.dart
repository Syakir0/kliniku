import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'resep_list_page.dart';
import 'rekam_medis_detail_page.dart';
import 'rekam_medis_pdf.dart';

class RiwayatPemeriksaanPage extends StatefulWidget {
  final String idPasien;

  const RiwayatPemeriksaanPage({super.key, required this.idPasien});

  @override
  State<RiwayatPemeriksaanPage> createState() =>
      _RiwayatPemeriksaanPageState();
}

class _RiwayatPemeriksaanPageState extends State<RiwayatPemeriksaanPage> {
  DateTime? selectedDate;

  String formatTanggal(Timestamp? ts) {
    if (ts == null) return '-';
    return DateFormat('dd MMM yyyy', 'id_ID').format(ts.toDate());
  }

  bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pemeriksaan'),
        backgroundColor: const Color(0xFF7BC9E3),
        actions: [
          // ================= REKAM MEDIS =================
          IconButton(
            tooltip: 'Lihat Rekam Medis',
            icon: const Icon(Icons.folder_shared),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      RekamMedisDetailPage(idPasien: widget.idPasien),
                ),
              );
            },
          ),

          // ================= PDF =================
          IconButton(
            tooltip: 'Cetak Rekam Medis PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              await RekamMedisPDF.generate(context, widget.idPasien);
            },
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
        child: Column(
          children: [
            // ================= FILTER TANGGAL =================
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        selectedDate == null
                            ? 'Semua Tanggal'
                            : DateFormat('dd MMM yyyy', 'id_ID')
                                .format(selectedDate!),
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.transparent,
                      ),
                      onPressed: pilihTanggal,
                    ),
                  ),
                  if (selectedDate != null)
                    IconButton(
                      tooltip: 'Reset Filter',
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() => selectedDate = null);
                      },
                    ),
                ],
              ),
            ),

            const Divider(height: 1, color: Colors.white54),

            // ================= LIST RIWAYAT =================
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('pemeriksaan')
                    .where('id_pasien', isEqualTo: widget.idPasien)
                    .orderBy('created_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Belum ada pemeriksaan',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    if (selectedDate == null) return true;

                    final data = doc.data() as Map<String, dynamic>;
                    final ts = data['tanggal'] ?? data['created_at'];

                    if (ts == null) return false;

                    return isSameDate((ts as Timestamp).toDate(), selectedDate!);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Tidak ada pemeriksaan di tanggal ini',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final diagnosa = data['diagnosa'] ?? '-';
                      final catatan = data['catatan'] ?? '';
                      final tanggal = data['tanggal'] ?? data['created_at'];

                      return Card(
                        color: Colors.white,
                        elevation: 4,
                        shadowColor: Colors.black26,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(
                            diagnosa,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Tanggal: ${formatTanggal(tanggal)}'),
                              if (catatan.toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Catatan: $catatan',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.medication_outlined,
                                color: Color(0xFF7BC9E3)),
                            tooltip: 'Lihat Resep',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ResepListPage(
                                      idPemeriksaan: doc.id),
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
    );
  }
}
