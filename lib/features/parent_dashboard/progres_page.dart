import 'package:flutter/material.dart';

class ProgresPage extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const ProgresPage({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Page Progrès',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Suivez les progrès de votre enfant ici.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (userData != null) ...[
              const SizedBox(height: 16),
              Text(
                'Utilisateur: ${userData!['prenom']} ${userData!['nom']}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
