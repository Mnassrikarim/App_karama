import 'package:edu_karama_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Extract user data from go_router's extra parameter
    final Map<String, dynamic>? userDataFromRoute = GoRouterState.of(context).extra as Map<String, dynamic>?;

    // Use FutureBuilder to load stored user data if route data is null
    return FutureBuilder<Map<String, dynamic>?>(
      future: userDataFromRoute != null ? Future.value(userDataFromRoute) : ApiService().getUserData(),
      builder: (context, snapshot) {
        final Map<String, dynamic>? userData = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Accueil'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  userData != null
                      ? 'Bienvenue, ${userData['prenom']} ${userData['nom']}'
                      : 'Bienvenue',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  userData != null ? 'Rôle: ${userData['role']}' : 'Aucun rôle',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}