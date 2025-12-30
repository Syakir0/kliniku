import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DokterDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const DokterDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Dokter')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            buildItem('Nama', data['nama']),
            buildItem('Email', data['email']),
            buildItem('No HP', data['no_hp']),
            buildItem('Alamat', data['alamat']),
            buildItem('Poli', data['poli']),
            buildItem('Spesialis', data['spesialis']),
            buildItem('Pendidikan Terakhir', data['pendidikan_terakhir']),
            buildItem('Status Kerja', data['status_kerja']),
            buildItem('Tempat Lahir', data['tempat_lahir']),
            buildItem(
              'Tanggal Lahir',
              (data['tanggal_lahir'] as Timestamp)
                  .toDate()
                  .toString()
                  .split(' ')[0],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildItem(String label, String value) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
