import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DetailResepPage extends StatefulWidget {
  final String resepId;
  const DetailResepPage({super.key, required this.resepId});

  @override
  State<DetailResepPage> createState() => _DetailResepPageState();
}

class _DetailResepPageState extends State<DetailResepPage> {
  String metodePembayaran = 'cash';
  bool loading = false;

  // ================= HITUNG TOTAL =================
  int hitungTotal(List obat) {
    int total = 0;
    for (var o in obat) {
      final int harga = (o['harga'] as num?)?.toInt() ?? 0;
      final int jumlah = (o['jumlah'] as num?)?.toInt() ?? 0;
      total += harga * jumlah;
    }
    return total;
  }

  // ================= BAYAR RESEP =================
  Future<void> bayarResep(int total) async {
    setState(() => loading = true);
    final resepDoc = FirebaseFirestore.instance.collection('resep').doc(widget.resepId);

    try {
      final docSnapshot = await resepDoc.get();
      final data = docSnapshot.data() as Map<String, dynamic>;
      final List obat = data['obat'] ?? [];

      for (var o in obat) {
        final String? obatId = o['id_obat'];
        final int jumlah = (o['jumlah'] as num?)?.toInt() ?? 0;

        if (obatId != null) {
          final obatRef = FirebaseFirestore.instance.collection('obat').doc(obatId);
          await FirebaseFirestore.instance.runTransaction((tx) async {
            final snapshot = await tx.get(obatRef);
            if (!snapshot.exists) return;
            final currentStock = (snapshot.data()?['stock'] as num?)?.toInt() ?? 0;
            final newStock = currentStock - jumlah;
            if (newStock < 0) throw Exception('Stok obat ${o['nama']} tidak cukup');
            tx.update(obatRef, {'stock': newStock, 'update_at': Timestamp.now()});
          });
        }
      }

      await resepDoc.update({
        'status_resep': 'selesai',
        'total_harga': total,
        'metode_pembayaran': metodePembayaran,
        'update_at': Timestamp.now(),
      });

      setState(() => loading = false);
      Navigator.pop(context);
    } catch (e) {
      setState(() => loading = false);
      _msg('Gagal memproses pembayaran: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA2E5A2),
      body: Stack(
        children: [
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('resep')
                .doc(widget.resepId)
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final List obat = data['obat'] ?? [];
              final total = hitungTotal(obat);

              return Container(
                margin: const EdgeInsets.only(top: 80), // space for back button
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: ListView(
                  children: [
                    _infoCard('Nama Pasien', data['nama_pasien']),
                    _infoCard('Nama Dokter', data['nama_dokter']),
                    _infoCard('Status Resep', data['status_resep']),

                    const SizedBox(height: 16),
                    const Text(
                      'Daftar Obat',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ...obat.map(
                      (o) => Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(o['nama']),
                          subtitle:
                              Text('Jumlah: ${o['jumlah']} × Rp${o['harga']}'),
                          trailing: Text(
                            'Rp${o['jumlah'] * o['harga']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 32, thickness: 1.2),
                    _infoCard('Total Bayar',
                        'Rp${NumberFormat('#,###').format(total)}'),

                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF7BC9E3)),
                      ),
                      child: DropdownButton<String>(
                        value: metodePembayaran,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'cash', child: Text('Cash')),
                          DropdownMenuItem(
                              value: 'transfer', child: Text('Transfer')),
                          DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                        ],
                        onChanged: (v) => setState(() => metodePembayaran = v!),
                      ),
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: loading ? null : () => bayarResep(total),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7BC9E3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          loading ? 'Memproses...' : 'Selesaikan Pembayaran',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ================= BACK BUTTON =================
          Positioned(
            top: 40,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF7BC9E3)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= WIDGET HELPER =================
  Widget _infoCard(String title, String? value) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value ?? '-'),
      ),
    );
  }

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
}
