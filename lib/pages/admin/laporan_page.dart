import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LaporanPage extends StatelessWidget {
  const LaporanPage({super.key});

  Future<int> getCount(String collection) async {
    final snapshot =
        await FirebaseFirestore.instance.collection(collection).get();
    return snapshot.docs.length;
  }

  Widget laporanCard(String title, IconData icon, Future<int> future) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FutureBuilder<int>(
                  future: future,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Text('Loading...');
                    }
                    return Text(
                      snapshot.data.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Klinik')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          laporanCard('Total Dokter', Icons.medical_services, getCount('dokter')),
          laporanCard('Total Pasien', Icons.people, getCount('users')),
          laporanCard('Total Janji', Icons.event, getCount('janji')),
          laporanCard(
              'Total Pemeriksaan', Icons.assignment, getCount('pemeriksaan')),
          laporanCard('Total Resep', Icons.medication, getCount('resep')),
        ],
      ),
    );
  }
}
