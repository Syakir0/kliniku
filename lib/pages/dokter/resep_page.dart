import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ResepPage extends StatefulWidget {
  final String idPemeriksaan;
  final String idPasien;
  final String idDokter;
  final String namaPasien;
  final String namaDokter;

  const ResepPage({
    super.key,
    required this.idPemeriksaan,
    required this.idPasien,
    required this.idDokter,
    required this.namaPasien,
    required this.namaDokter,
  });

  @override
  State<ResepPage> createState() => _ResepPageState();
}

class _ResepPageState extends State<ResepPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> obatList = [];
  List<Map<String, dynamic>> selectedObat = [];

  final searchController = TextEditingController();
  final catatanDokterController = TextEditingController();

  String searchQuery = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadObat();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    catatanDokterController.dispose();
    super.dispose();
  }

  String formatTanggal(Timestamp? ts) {
    if (ts == null) return '-';
    return DateFormat('dd MMM yyyy').format(ts.toDate());
  }

  // ================= LOAD OBAT =================
  Future<void> loadObat() async {
    final snapshot = await firestore.collection('obat').get();
    setState(() {
      obatList = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'nama': data['nama'],
          'harga': data['harga'],
          'expired': data['tanggal_expired'],
        };
      }).toList();
    });
  }

  // ================= TAMBAH OBAT =================
  void addObat(Map<String, dynamic> obat) async {
    final jumlahController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Tambah ${obat['nama']}'),
        content: TextField(
          controller: jumlahController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Jumlah',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final jumlah = int.tryParse(jumlahController.text);
              if (jumlah == null || jumlah <= 0) return;

              setState(() {
                selectedObat.add({
                  'id_obat': obat['id'],
                  'nama': obat['nama'],
                  'jumlah': jumlah,
                  'harga': obat['harga'],
                  'expired': obat['expired'],
                });
              });

              Navigator.pop(context);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  // ================= OBAT TERPILIH =================
  Widget selectedObatSection() {
    if (selectedObat.isEmpty) {
      return const Text(
        'Belum ada obat dipilih',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      children: selectedObat.map((obat) {
        final total = obat['harga'] * obat['jumlah'];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ListTile(
            title: Text(obat['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              'Jumlah: ${obat['jumlah']} • Harga: Rp ${obat['harga']}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Rp $total',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      selectedObat.remove(obat);
                    });
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ================= SIMPAN RESEP =================
  Future<void> simpanResep() async {
    if (selectedObat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu obat')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await firestore.collection('resep').add({
        'id_pemeriksaan': widget.idPemeriksaan,
        'id_pasien': widget.idPasien,
        'id_dokter': widget.idDokter,
        'nama_pasien': widget.namaPasien,
        'nama_dokter': widget.namaDokter,
        'obat': selectedObat,
        'catatan_dokter': catatanDokterController.text,
        'status_resep': 'menunggu_apotek',
        'status_pemeriksaan': 'selesai',
        'is_deleted': false,
        'created_at': Timestamp.now(),
        'tanggal': Timestamp.now(),
        'update_at': Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resep berhasil dikirim ke apotek')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan resep: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final filteredObat = obatList
        .where((o) => o['nama'].toLowerCase().contains(searchQuery))
        .toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Buat Resep'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7BC9E3), Color(0xFFA2E5A2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ===== SEARCH BAR =====
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Cari Obat',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ===== LIST OBAT =====
                Expanded(
                  child: ListView(
                    children: filteredObat.map((obat) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: ListTile(
                          title: Text(obat['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            'Harga: Rp ${obat['harga']} • Exp: ${formatTanggal(obat['expired'])}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.add, color: Colors.green),
                            onPressed: () => addObat(obat),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const Divider(thickness: 1, color: Colors.white),

                // ===== OBAT TERPILIH =====
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Obat yang Dipilih',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                selectedObatSection(),

                const SizedBox(height: 12),
                TextField(
                  controller: catatanDokterController,
                  decoration: InputDecoration(
                    labelText: 'Catatan Dokter',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7BC9E3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isLoading ? null : simpanResep,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Kirim ke Apotek'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
