import 'package:flutter/material.dart';

class TrackingBottomBar extends StatelessWidget {
  final bool isTracking;
  final VoidCallback onToggleTracking;
  final double totalDistance;

  const TrackingBottomBar({
    super.key,
    required this.isTracking,
    required this.onToggleTracking,
    required this.totalDistance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), // Coins arrondis en haut
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1), // Bordure légère
        ),
      ),
      child: BottomAppBar(
        color: Colors.transparent, // Garde le style du Container
        elevation: 0,
        shape: const CircularNotchedRectangle(), // Effet de découpe circulaire
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundImage: AssetImage('assets/Avatar.png'), // Remplace par ton image
                radius: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Emplacement actuel",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    Text(
                      "Distance: ${totalDistance.toStringAsFixed(2)} km - Temps: 10 min",
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                backgroundColor: Colors.deepPurple[400],
                radius: 24,
                child: IconButton(
                  icon: Icon(
                    isTracking ? Icons.stop : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: onToggleTracking,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
