import 'package:flutter/material.dart';

class DeviceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final String imageUrl;

  const DeviceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = status == "Activo";

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.network(
              imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(status),
                  ],
                ),
                const SizedBox(height: 5),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
