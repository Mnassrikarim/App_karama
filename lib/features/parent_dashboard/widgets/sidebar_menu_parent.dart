import 'package:flutter/material.dart';
import 'package:edu_karama_app/services/api_service.dart';
import 'package:go_router/go_router.dart';

class SidebarMenuParent extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final String activePage;
  final Function(String) onPageSelected;

  const SidebarMenuParent({
    super.key,
    required this.userData,
    required this.activePage,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: userData?['imageUrl'] != null
                      ? NetworkImage(userData!['imageUrl'])
                      : null,
                  child: userData?['imageUrl'] == null
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  userData != null
                      ? '${userData!['prenom']} ${userData!['nom']}'
                      : 'Utilisateur',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  userData != null ? 'Rôle: Parent' : 'Aucun rôle',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.home,
            title: 'Accueil',
            page: 'accueil',
          ),
          _buildMenuItem(
            context,
            icon: Icons.bar_chart,
            title: 'Progrès',
            page: 'progres',
          ),
          _buildMenuItem(
            context,
            icon: Icons.notifications,
            title: 'Notifications',
            page: 'notifications',
          ),
          _buildMenuItem(
            context,
            icon: Icons.message,
            title: 'Messages',
            page: 'messages',
          ),
          _buildMenuItem(
            context,
            icon: Icons.info,
            title: 'Infos',
            page: 'infos',
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Déconnexion'),
            onTap: () async {
              await ApiService.storage.delete(key: 'jwt_token');
              await ApiService.storage.delete(key: 'user_role');
              await ApiService.storage.delete(key: 'user_nom');
              await ApiService.storage.delete(key: 'user_prenom');
              if (context.mounted) {
                context.go('/login-parent');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String page,
  }) {
    final isActive = activePage == page;
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      tileColor: isActive
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : null,
      onTap: () {
        onPageSelected(page);
        Navigator.pop(context);
      },
    );
  }
}
