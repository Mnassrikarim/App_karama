import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:edu_karama_app/services/api_service.dart'; // Assuming this exists

class MessagesPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const MessagesPage({super.key, required this.userData});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final ApiService _apiService = ApiService();
  late String? token;
  List<dynamic> users = [];
  List<dynamic> unreadSenders = [];
  String searchQuery = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTokenAndData();
  }

  Future<void> _loadTokenAndData() async {
    token = await ApiService.storage.read(key: 'jwt_token');
    if (token == null) {
      context.go('/login-eleve');
      return;
    }
    await _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      setState(() => isLoading = true);
      final config = {'Authorization': 'Bearer $token'};
      final unreadResponse = await http.get(
        Uri.parse('https://kara-back.onrender.com/api/messages/unread-senders'),
        headers: config,
      );
      if (unreadResponse.statusCode == 200) {
        setState(() {
          unreadSenders = jsonDecode(unreadResponse.body);
        });
      }

      final role = widget.userData?['role'];
      final userId = widget.userData?['_id'];
      List<dynamic> filteredUsers = [];

      if (role == 'enseignant') {
        final usersResponse = await http.get(
          Uri.parse('https://kara-back.onrender.com/api/users'),
          headers: config,
        );
        if (usersResponse.statusCode == 200) {
          final allUsers = jsonDecode(usersResponse.body);
          filteredUsers = allUsers
              .where((u) => u['role'] == 'eleve' || u['role'] == 'parent')
              .toList();
        }
      } else {
        final usersResponse = await http.get(
          Uri.parse('https://kara-back.onrender.com/api/messages/teachers'),
          headers: config,
        );
        if (usersResponse.statusCode == 200) {
          filteredUsers = jsonDecode(usersResponse.body);
        }
      }

      filteredUsers = filteredUsers.map((u) {
        final unreadCount = unreadSenders.firstWhere(
            (s) => s['_id'] == u['_id'],
            orElse: () => {'unreadCount': 0})['unreadCount'];
        return {
          ...u,
          'imageUrl': u['imageUrl']?.startsWith('http') ?? false
              ? u['imageUrl']
              : 'https://kara-back.onrender.com/Uploads/${u['imageUrl'] ?? ''}',
          'unreadCount': unreadCount,
        };
      }).toList();

      if (unreadSenders.isNotEmpty && mounted) {
        setState(() {
          users = filteredUsers;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = users
        .where((user) => '${user['prenom']} ${user['nom']}'
            .toLowerCase()
            .contains(searchQuery.toLowerCase()))
        .toList();

    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Text(
                    'Messagerie',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(user['imageUrl'] ??
                            'https://via.placeholder.com/40'),
                      ),
                      title: Text('${user['prenom']} ${user['nom']}'),
                      subtitle: Text(
                          'Message preview text...'), // Replace with actual preview if available
                      trailing: Text(user['unreadCount'] > 0
                          ? '${user['unreadCount']} new'
                          : ''),
                      onTap: () {
                        context.go('/conversation/${user['_id']}',
                            extra: widget.userData);
                      },
                    );
                  },
                ),
              ],
            ),
          );
  }
}
