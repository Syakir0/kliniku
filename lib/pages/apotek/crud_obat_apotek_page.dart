import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CrudObatApotekPage extends StatefulWidget {
  const CrudObatApotekPage({super.key});

  @override
  State<CrudObatApotekPage> createState() => _CrudObatApotekPageState();
}

class _CrudObatApotekPageState extends State<CrudObatApotekPage> {
  final CollectionReference obatRef = FirebaseFirestore.instance.collection('obat');

  // ================= CONTROLLERS =================
  final namaC = TextEditingController();
  final hargaC = TextEditingController();
  final stokC = TextEditingController();
  final ketC = TextEditingController();

  String? jenisObat;
  String? usiaPemakaian;
  DateTime? tglMasuk;
  DateTime? tglExpired;

  // ================= DATE PICKER =================
  Future<void> pickDate(bool masuk) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        masuk ? tglMasuk = picked : tglExpired = picked;
      });
    }
  }

  // ================= RESET FORM =================
  void resetForm() {
    namaC.clear();
    hargaC.clear();
    stokC.clear();
    ketC.clear();
    jenisObat = null;
    usiaPemakaian = null;
    tglMasuk = null;
    tglExpired = null;
  }

  // ================= SIMPAN OBAT =================
  Future<void> simpanObat({String? id}) async {
    if (namaC.text.isEmpty ||
        hargaC.text.isEmpty ||
        stokC.text.isEmpty ||
        jenisObat == null ||
        usiaPemakaian == null ||
        tglMasuk == null ||
        tglExpired == null) {
      _msg('Lengkapi semua data');
      return;
    }

    if (tglExpired!.isBefore(tglMasuk!)) {
      _msg('Tanggal expired harus setelah tanggal masuk');
      return;
    }

    final harga = int.tryParse(hargaC.text);
    final stok = int.tryParse(stokC.text);

    if (harga == null || stok == null) {
      _msg('Harga dan stok harus angka');
      return;
    }

    final data = {
      'nama': namaC.text.trim(),
      'jenis_obat': jenisObat,
      'usia_pemakaian_obat': usiaPemakaian,
      'harga': harga,
      'stock': stok,
      'keterangan': ketC.text.trim(),
      'tanggal_masuk': Timestamp.fromDate(tglMasuk!),
      'tanggal_expired': Timestamp.fromDate(tglExpired!),
      'update_at': Timestamp.now(),
      if (id == null) 'created_at': Timestamp.now(),
    };

    try {
      id == null ? await obatRef.add(data) : await obatRef.doc(id).update(data);

      resetForm();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _msg('Gagal menyimpan obat: $e');
    }
  }

  // ================= FORM DIALOG =================
  void showForm({String? id, Map<String, dynamic>? data}) {
    resetForm();

    if (data != null) {
      namaC.text = data['nama'] ?? '';
      hargaC.text = (data['harga'] ?? '').toString();
      stokC.text = (data['stock'] ?? '').toString();
      ketC.text = data['keterangan'] ?? '';
      jenisObat = (data['jenis_obat'] as String?)?.toLowerCase();
      usiaPemakaian = data['usia_pemakaian_obat'];
      tglMasuk = (data['tanggal_masuk'] as Timestamp?)?.toDate();
      tglExpired = (data['tanggal_expired'] as Timestamp?)?.toDate();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(id == null ? 'Tambah Obat' : 'Edit Obat'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: namaC,
                decoration: const InputDecoration(labelText: 'Nama Obat'),
              ),
              dropdown(
                'Jenis Obat',
                ['tablet', 'kapsul', 'sirup', 'salep'],
                jenisObat,
                (v) => setState(() => jenisObat = v),
              ),
              dropdown(
                'Usia Pemakaian',
                ['Anak-anak', 'Dewasa', 'Semua Usia'],
                usiaPemakaian,
                (v) => setState(() => usiaPemakaian = v),
              ),
              TextField(
                controller: hargaC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Harga'),
              ),
              TextField(
                controller: stokC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stok'),
              ),
              TextField(
                controller: ketC,
                decoration: const InputDecoration(labelText: 'Keterangan'),
              ),
              const SizedBox(height: 8),
              dateTile('Tanggal Masuk', tglMasuk, () => pickDate(true)),
              dateTile('Tanggal Expired', tglExpired, () => pickDate(false)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => simpanObat(id: id),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ================= FORMAT TANGGAL =================
  String formatTanggal(Timestamp? t) {
    if (t == null) return '-';
    final dt = t.toDate();
    return DateFormat('dd MMMM yyyy').format(dt); // misal: 01 Desember 2025
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Obat (Apotek)'),
        backgroundColor: const Color(0xFF7BC9E3),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7BC9E3),
        onPressed: () => showForm(),
        child: const Icon(Icons.add),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF7BC9E3), // Soft Cyan
              Color(0xFFA2E5A2), // Light Mint
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: obatRef.orderBy('created_at', descending: true).snapshots(),
          builder: (_, s) {
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            if (s.data!.docs.isEmpty) return const Center(child: Text('Data obat kosong'));

            return ListView(
              padding: const EdgeInsets.all(12),
              children: s.data!.docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                d['nama'] ?? '-',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => showForm(id: doc.id, data: d),
                            ),
                          ],
                        ),
                        info('Jenis Obat', d['jenis_obat']),
                        info('Usia Pemakaian', d['usia_pemakaian_obat']),
                        info('Stok', '${d['stock'] ?? 0}'),
                        info('Harga', 'Rp ${d['harga'] ?? 0}'),
                        info('Tanggal Masuk', formatTanggal(d['tanggal_masuk'])),
                        info('Tanggal Expired', formatTanggal(d['tanggal_expired'])),
                        info('Created At', formatTanggal(d['created_at'])),
                        info('Update At', formatTanggal(d['update_at'])),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  // ================= HELPERS =================
  Widget dropdown(
    String label,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      decoration: InputDecoration(labelText: label),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e[0].toUpperCase() + e.substring(1)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget dateTile(String label, DateTime? date, VoidCallback onTap) {
    return ListTile(
      title: Text(date == null ? label : '$label: ${DateFormat('dd MMM yyyy').format(date)}'),
      trailing: const Icon(Icons.date_range),
      onTap: onTap,
    );
  }

  Widget info(String l, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text('$l: $v'),
      );

  void _msg(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  @override
  void dispose() {
    namaC.dispose();
    hargaC.dispose();
    stokC.dispose();
    ketC.dispose();
    super.dispose();
  }
}

