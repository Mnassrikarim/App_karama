import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const SettingsPage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          // Placeholder for additional content
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Contenu des paramètres à venir...',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}