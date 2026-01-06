import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ObatCrudPage extends StatefulWidget {
  const ObatCrudPage({super.key});

  @override
  State<ObatCrudPage> createState() => _ObatCrudPageState();
}

class _ObatCrudPageState extends State<ObatCrudPage> {
  final CollectionReference obatRef =
      FirebaseFirestore.instance.collection('obat');

  // ================= WARNA =================
  static const Color cyan = Color(0xFF7BC9E3);
  static const Color bgColor = Color(0xFFF1FDFB);

  // ================= CONTROLLER =================
  final namaC = TextEditingController();
  final hargaC = TextEditingController();
  final stokC = TextEditingController();
  final ketC = TextEditingController();

  String? jenisObat;
  String? usiaPemakaian;
  DateTime? tglMasuk;
  DateTime? tglExpired;

  // ================= FORMAT TANGGAL =================
  String formatDate(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  // ================= DATE PICKER =================
  Future<void> pickDate(bool masuk) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() => masuk ? tglMasuk = picked : tglExpired = picked);
    }
  }

  // ================= RESET =================
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

  // ================= SIMPAN =================
  Future<void> simpanObat({String? id}) async {
    final harga = int.tryParse(hargaC.text);
    final stok = int.tryParse(stokC.text);

    if (namaC.text.isEmpty ||
        harga == null ||
        stok == null ||
        jenisObat == null ||
        usiaPemakaian == null ||
        tglMasuk == null ||
        tglExpired == null) {
      _msg('Lengkapi semua data dengan benar');
      return;
    }

    if (tglExpired!.isBefore(tglMasuk!)) {
      _msg('Tanggal expired harus setelah tanggal masuk');
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

    id == null ? await obatRef.add(data) : await obatRef.doc(id).update(data);

    resetForm();
    if (mounted) Navigator.pop(context);
  }

  // ================= FORM =================
  void showForm({String? id, Map<String, dynamic>? data}) {
    resetForm();

    if (data != null) {
      namaC.text = data['nama'] ?? '';
      hargaC.text = data['harga'].toString();
      stokC.text = data['stock'].toString();
      ketC.text = data['keterangan'] ?? '';
      jenisObat = data['jenis_obat'];
      usiaPemakaian = data['usia_pemakaian_obat'];
      tglMasuk = (data['tanggal_masuk'] as Timestamp?)?.toDate();
      tglExpired = (data['tanggal_expired'] as Timestamp?)?.toDate();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(id == null ? 'Tambah Obat' : 'Edit Obat'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              field(namaC, 'Nama Obat'),
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
              field(hargaC, 'Harga', number: true),
              field(stokC, 'Stok', number: true),
              field(ketC, 'Keterangan'),
              dateTile('Tanggal Masuk', tglMasuk, () => pickDate(true)),
              dateTile('Tanggal Expired', tglExpired, () => pickDate(false)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cyan),
            onPressed: () => simpanObat(id: id),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Data Obat'),
        backgroundColor: cyan,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: cyan,
        onPressed: () => showForm(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: obatRef.orderBy('created_at', descending: true).snapshots(),
        builder: (_, s) {
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (s.data!.docs.isEmpty) {
            return const Center(child: Text('Data obat masih kosong'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: s.data!.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d['nama'] ?? '-',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      info('Jenis Obat', d['jenis_obat']),
                      info('Usia Pemakaian', d['usia_pemakaian_obat']),
                      info('Stok', d['stock'].toString()),
                      info('Harga', 'Rp ${d['harga']}'),
                      info('Tanggal Masuk', formatDate(d['tanggal_masuk'])),
                      info('Tanggal Expired', formatDate(d['tanggal_expired'])),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // ================= HELPER =================
  Widget field(TextEditingController c, String l, {bool number = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            labelText: l,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );

  Widget dropdown(
    String label,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          value: items.contains(value) ? value : null,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      );

  Widget dateTile(String label, DateTime? date, VoidCallback onTap) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          date == null ? label : '$label : ${date.toString().split(' ').first}',
        ),
        trailing: const Icon(Icons.date_range),
        onTap: onTap,
      );

  Widget info(String l, String v) =>
      Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('$l: $v'));

  void _msg(String t) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  @override
  void dispose() {
    namaC.dispose();
    hargaC.dispose();
    stokC.dispose();
    ketC.dispose();
    super.dispose();
  }
}
