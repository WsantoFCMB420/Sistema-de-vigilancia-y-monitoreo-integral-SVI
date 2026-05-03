import 'package:flutter/material.dart';

class AddDeviceCard extends StatelessWidget {
  const AddDeviceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey),
      ),
      child: const Center(child: Text("Añadir Cámara")),
    );
  }
}
