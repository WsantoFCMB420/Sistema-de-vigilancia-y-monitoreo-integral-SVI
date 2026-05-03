import 'package:flutter/material.dart';
import '../widgets/device_card.dart';
import '../widgets/add_device_card.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Sentinel Surveillance",
          style: TextStyle(color: Colors.black),
        ),
        actions: const [
          CircleAvatar(
            backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=5"),
          ),
          SizedBox(width: 10),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "SISTEMAS ACTIVOS",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 5),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Mis Dispositivos",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                FloatingActionButton(
                  mini: true,
                  onPressed: () {},
                  child: const Icon(Icons.add),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Expanded(
              child: ListView(
                children: const [
                  DeviceCard(
                    title: "Entrada Principal",
                    subtitle: "Edificio Norte - Planta Baja",
                    status: "Activo",
                    imageUrl:
                        "https://images.unsplash.com/photo-1593642532400-2682810df593",
                  ),
                  DeviceCard(
                    title: "Parking B2",
                    subtitle: "Sótano - Acceso Sur",
                    status: "Inactivo",
                    imageUrl:
                        "https://images.unsplash.com/photo-1502920917128-1aa500764b6b",
                  ),
                  DeviceCard(
                    title: "Zona Coworking",
                    subtitle: "Edificio Central - Ala Este",
                    status: "Activo",
                    imageUrl:
                        "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70",
                  ),
                  AddDeviceCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
