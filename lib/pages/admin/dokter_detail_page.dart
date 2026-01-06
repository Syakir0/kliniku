import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DokterDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const DokterDetailPage({super.key, required this.data});

  // ================= WARNA =================
  static const Color primaryCyan = Color(0xFF7BC9E3);
  static const Color mintGreen = Color(0xFF90EE90);
  static const Color bgColor = Color(0xFFF1FDFB);

  // ================= FORMATTER =================
  String formatTimestamp(dynamic ts) {
    if (ts == null) return '-';
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${d.day}-${d.month}-${d.year}';
    }
    return ts.toString();
  }

  String formatList(dynamic l) {
    if (l == null) return '-';
    if (l is List) return l.join(', ');
    return l.toString();
  }

  String formatValue(dynamic val) {
    if (val == null) return '-';
    if (val is String) return val;
    if (val is num) return val.toString();
    if (val is Timestamp) return formatTimestamp(val);
    if (val is List) return formatList(val);
    return val.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Detail Dokter'),
        backgroundColor: primaryCyan,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ================= HEADER =================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [primaryCyan, mintGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: primaryCyan,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatValue(data['nama']),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatValue(data['spesialis'])} • ${formatValue(data['poli'])}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ================= DATA SECTION =================
          buildSection('Informasi Umum', [
            buildItem('NIP', formatValue(data['NIP'])),
            buildItem('Email', formatValue(data['email'])),
            buildItem('No HP', formatValue(data['no_hp'])),
            buildItem('Alamat', formatValue(data['alamat'])),
          ]),

          buildSection('Data Profesional', [
            buildItem('Poli', formatValue(data['poli'])),
            buildItem('Spesialis', formatValue(data['spesialis'])),
            buildItem(
              'Pendidikan Terakhir',
              formatValue(data['pendidikan_terakhir']),
            ),
            buildItem('Status Kerja', formatValue(data['status_kerja'])),
          ]),

          buildSection('Data Pribadi', [
            buildItem('Tempat Lahir', formatValue(data['tempat_lahir'])),
            buildItem('Tanggal Lahir', formatValue(data['tanggal_lahir'])),
          ]),

          buildSection('Jadwal Praktek', [
            buildItem('Hari Praktek', formatValue(data['hari_praktek'])),
            buildItem('Jam Mulai', formatValue(data['jam_mulai'])),
            buildItem('Jam Selesai', formatValue(data['jam_selesai'])),
          ]),

          buildSection('Metadata', [
            buildItem('Dibuat', formatValue(data['created_at'])),
            buildItem('Terakhir Update', formatValue(data['updated_at'])),
          ]),
        ],
      ),
    );
  }

  // ================= UI HELPER =================
  Widget buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: primaryCyan,
            ),
          ),
          const Divider(),
          ...children,
        ],
      ),
    );
  }

  Widget buildItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
