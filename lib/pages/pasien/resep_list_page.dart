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
      appBar: AppBar(
        title: const Text('Resep & Catatan Dokter'),
        backgroundColor: const Color(0xFF0097A7), // cyan
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('resep')
            .where('id_pemeriksaan', isEqualTo: idPemeriksaan)
            .where('is_deleted', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          // ===== LOADING =====
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ===== EMPTY =====
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Resep belum tersedia',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          // ===== DATA =====
          final Map<String, dynamic> resep =
              snapshot.data!.docs.first.data() as Map<String, dynamic>;

          final List<dynamic> obatList = resep['obat'] ?? [];
          final int totalHarga = (resep['total_harga'] ?? 0).toInt();
          final String catatanDokter =
              resep['catatan_dokter'] ?? 'Tidak ada catatan dokter';

          return Column(
            children: [
              // ================= CATATAN DOKTER =================
              Padding(
                padding: const EdgeInsets.all(12),
                child: Card(
                  color: const Color(0xFFE0F7FA), // soft cyan
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.note_alt,
                      color: Color(0xFF0097A7),
                    ),
                    title: const Text(
                      'Catatan Dokter',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0097A7),
                      ),
                    ),
                    subtitle: Text(catatanDokter),
                  ),
                ),
              ),

              // ================= DAFTAR OBAT =================
              Expanded(
                child: obatList.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada obat',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: obatList.length,
                        itemBuilder: (context, index) {
                          final Map<String, dynamic> obat =
                              Map<String, dynamic>.from(obatList[index]);

                          final String nama = obat['nama'] ?? '-';
                          final int jumlah = (obat['jumlah'] ?? 0).toInt();
                          final int harga = (obat['harga'] ?? 0).toInt();
                          final int subtotal = jumlah * harga;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(
                                  color: Color(0xFF0097A7), width: 1),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.medication,
                                color: Color(0xFF0097A7),
                              ),
                              title: Text(
                                nama,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Jumlah: $jumlah\nHarga: Rp $harga',
                              ),
                              trailing: Text(
                                'Rp $subtotal',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0097A7),
                                ),
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
              ),

              // ================= TOTAL HARGA =================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA),
                  border: const Border(
                    top: BorderSide(color: Color(0xFF0097A7), width: 2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Harga',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0097A7),
                      ),
                    ),
                    Text(
                      'Rp $totalHarga',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0097A7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
