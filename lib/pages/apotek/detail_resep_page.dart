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

  int hitungTotal(List obat) {
    int total = 0;

    for (var o in obat) {
      final int harga = (o['harga'] as num?)?.toInt() ?? 0;
      final int jumlah = (o['jumlah'] as num?)?.toInt() ?? 0;

      total += harga * jumlah;
    }

    return total;
  }

  Future<void> bayarResep(int total) async {
    setState(() => loading = true);

    await FirebaseFirestore.instance
        .collection('resep')
        .doc(widget.resepId)
        .update({
          'status_resep': 'selesai',
          'total_harga': total,
          'metode_pembayaran': metodePembayaran,
          'update_at': Timestamp.now(),
        });

    setState(() => loading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Resep & Pembayaran')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('resep')
            .doc(widget.resepId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List obat = data['obat'] ?? [];
          final total = hitungTotal(obat);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _info('Nama Pasien', data['nama_pasien']),
              _info('Nama Dokter', data['nama_dokter']),
              _info('Status Resep', data['status_resep']),

              const SizedBox(height: 16),
              const Text(
                'Daftar Obat',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              ...obat.map(
                (o) => Card(
                  child: ListTile(
                    title: Text(o['nama']),
                    subtitle: Text('Jumlah: ${o['jumlah']} × Rp${o['harga']}'),
                    trailing: Text(
                      'Rp${o['jumlah'] * o['harga']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),

              const Divider(height: 32),
              _info('Total Bayar', 'Rp${NumberFormat('#,###').format(total)}'),

              const SizedBox(height: 12),
              DropdownButton<String>(
                value: metodePembayaran,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                  DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                ],
                onChanged: (v) => setState(() => metodePembayaran = v!),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: loading ? null : () => bayarResep(total),
                child: Text(loading ? 'Memproses...' : 'Selesaikan Pembayaran'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _info(String title, String? value) {
    return Card(
      child: ListTile(title: Text(title), subtitle: Text(value ?? '-')),
    );
  }
}
