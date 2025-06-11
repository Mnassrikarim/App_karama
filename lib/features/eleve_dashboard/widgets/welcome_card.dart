import 'package:flutter/material.dart';

class WelcomeCard extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const WelcomeCard({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              userData != null
                  ? 'Bienvenue, ${userData!['prenom']} ${userData!['nom']}'
                  : 'Bienvenue',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              userData != null ? 'Rôle: Élève' : 'Aucun rôle',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
