import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_karama_app/services/api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationsPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const NotificationsPage({super.key, required this.userData});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late String? token;
  List<dynamic> notifications = [];
  int page = 1;
  int totalPages = 1;
  bool loading = false;
  String? error;
  bool darkMode = false;
  String filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchNotifications();
  }

  Future<void> _loadTokenAndFetchNotifications() async {
    token = await ApiService.storage.read(key: 'jwt_token');
    if (token == null) {
      context.go('/login-eleve');
      return;
    }
    await _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    if (token == null) return;
    setState(() => loading = true);
    try {
      final config = {
        'Authorization': 'Bearer $token',
        'params': {'page': page, 'limit': 10}
      };
      final response = await http.get(
        Uri.parse(
            'https://kara-back.onrender.com/api/notifications?page=$page&limit=10'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          notifications = data['notifications'] ?? [];
          totalPages = data['pagination']?['totalPages'] ?? 1;
          loading = false;
        });
      } else if (response.statusCode == 401) {
        context.go('/login-eleve');
      } else {
        setState(() {
          error = 'Erreur lors du chargement des notifications.';
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Erreur lors du chargement des notifications.';
        loading = false;
      });
    }
  }

  Future<void> _markAsRead(String id) async {
    if (token == null) return;
    try {
      final config = {'Authorization': 'Bearer $token'};
      final response = await http.put(
        Uri.parse('https://kara-back.onrender.com/api/notifications/$id/read'),
        headers: config,
      );
      if (response.statusCode == 200) {
        setState(() {
          notifications = notifications
              .map((notif) =>
                  notif['_id'] == id ? {...notif, 'read': true} : notif)
              .toList();
        });
      } else {
        setState(
            () => error = 'Erreur lors de la mise à jour de la notification.');
      }
    } catch (e) {
      setState(
          () => error = 'Erreur lors de la mise à jour de la notification.');
    }
  }

  Future<void> _markAllAsRead() async {
    if (token == null) return;
    try {
      final config = {'Authorization': 'Bearer $token'};
      final response = await http.put(
        Uri.parse('https://kara-back.onrender.com/api/notifications/read-all'),
        headers: config,
      );
      if (response.statusCode == 200) {
        setState(() {
          notifications =
              notifications.map((notif) => ({...notif, 'read': true})).toList();
        });
      } else {
        setState(
            () => error = 'Erreur lors de la mise à jour des notifications.');
      }
    } catch (e) {
      setState(
          () => error = 'Erreur lors de la mise à jour des notifications.');
    }
  }

  Future<void> _deleteNotification(String id) async {
    if (token == null) return;
    try {
      final config = {'Authorization': 'Bearer $token'};
      final response = await http.delete(
        Uri.parse('https://kara-back.onrender.com/api/notifications/$id'),
        headers: config,
      );
      if (response.statusCode == 200) {
        setState(() {
          notifications.removeWhere((notif) => notif['_id'] == id);
        });
      } else {
        setState(
            () => error = 'Erreur lors de la suppression de la notification.');
      }
    } catch (e) {
      setState(
          () => error = 'Erreur lors de la suppression de la notification.');
    }
  }

  Future<void> _deleteAllNotifications() async {
    if (token == null) return;
    if (!await _showConfirmationDialog()) return;
    try {
      final config = {'Authorization': 'Bearer $token'};
      final response = await http.delete(
        Uri.parse('https://kara-back.onrender.com/api/notifications'),
        headers: config,
      );
      if (response.statusCode == 200) {
        setState(() {
          notifications = [];
          page = 1;
        });
      } else {
        setState(() => error =
            'Erreur lors de la suppression de toutes les notifications.');
      }
    } catch (e) {
      setState(() =>
          error = 'Erreur lors de la suppression de toutes les notifications.');
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmation'),
            content: const Text(
                'Voulez-vous vraiment supprimer toutes les notifications ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Oui'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _handlePageChange(int newPage) {
    if (newPage >= 1 && newPage <= totalPages) {
      setState(() => page = newPage);
      _fetchNotifications();
    }
  }

  List<dynamic> get filteredNotifications {
    if (filter == 'unread')
      return notifications.where((n) => !n['read']).toList();
    if (filter == 'read') return notifications.where((n) => n['read']).toList();
    return notifications;
  }

  int get unreadCount => notifications.where((n) => !n['read']).length;
  double get progress =>
      notifications.isNotEmpty ? (unreadCount / notifications.length) * 100 : 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE6F0FA), Color(0xFFDAD1E6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      offset: const Offset(0, 2),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notifications,
                            color: Color(0xFF800080), size: 30),
                        const SizedBox(width: 8),
                        const Text(
                          'Notifications Élève',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.go('/home-eleve', extra: widget.userData),
                  icon: const Icon(Icons.arrow_back, size: 20),
                  label: const Text('🏠 Retour'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[500],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$unreadCount notification(s) non lu(e)s sur ${notifications.length}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: progress / 100,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF800080), Color(0xFFFF69B4)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () => setState(() => filter = 'all'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: filter == 'all'
                                  ? const Color(0xFF800080)
                                  : Colors.purple[100],
                              foregroundColor: filter == 'all'
                                  ? Colors.white
                                  : Colors.black87,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('Toutes'),
                          ),
                          ElevatedButton(
                            onPressed: () => setState(() => filter = 'unread'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: filter == 'unread'
                                  ? const Color(0xFF800080)
                                  : Colors.purple[100],
                              foregroundColor: filter == 'unread'
                                  ? Colors.white
                                  : Colors.black87,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('Non lues'),
                          ),
                          ElevatedButton(
                            onPressed: () => setState(() => filter = 'read'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: filter == 'read'
                                  ? const Color(0xFF800080)
                                  : Colors.purple[100],
                              foregroundColor: filter == 'read'
                                  ? Colors.white
                                  : Colors.black87,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('Lues'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: unreadCount == 0 ? null : _markAllAsRead,
                            icon: const Icon(Icons.check_circle, size: 18),
                            label: const Text('Marquer tout lu'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: unreadCount == 0
                                  ? Colors.grey[300]
                                  : Colors.green[100],
                              foregroundColor: unreadCount == 0
                                  ? Colors.grey
                                  : Colors.green[800],
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              // enableFeedback: unreadCount > 0,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _deleteAllNotifications,
                            icon: const Icon(Icons.delete, size: 18),
                            label: const Text('Suppr. tout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[100],
                              foregroundColor: Colors.red[800],
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (filteredNotifications.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.notifications,
                                    color: Color(0xFF800080), size: 50),
                                SizedBox(height: 16),
                                Text(
                                  'Aucune notification disponible.',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Column(
                          children: filteredNotifications.map<Widget>((notif) {
                            final isUnread = !notif['read'];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: isUnread
                                    ? const BorderSide(
                                        color: Color(0xFF800080), width: 4)
                                    : BorderSide.none,
                              ),
                              elevation: 2,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  notif['message'] ?? '',
                                  style: TextStyle(
                                      fontWeight: isUnread
                                          ? FontWeight.bold
                                          : FontWeight.normal),
                                ),
                                subtitle: Text(
                                  notif['createdAt'] != null
                                      ? DateTime.parse(notif['createdAt'])
                                          .toLocal()
                                          .toString()
                                          .split('.')[0]
                                      : '',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isUnread)
                                      IconButton(
                                        icon: const Icon(Icons.check_circle,
                                            color: Colors.green),
                                        onPressed: () =>
                                            _markAsRead(notif['_id']),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _deleteNotification(notif['_id']),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: page == 1
                                ? null
                                : () => _handlePageChange(page - 1),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: page == 1
                                  ? Colors.grey[300]
                                  : Colors.purple[100],
                              foregroundColor: page == 1
                                  ? Colors.grey
                                  : const Color(0xFF800080),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Précédent'),
                          ),
                          Text('Page $page sur $totalPages',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          ElevatedButton(
                            onPressed: page == totalPages
                                ? null
                                : () => _handlePageChange(page + 1),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: page == totalPages
                                  ? Colors.grey[300]
                                  : Colors.purple[100],
                              foregroundColor: page == totalPages
                                  ? Colors.grey
                                  : const Color(0xFF800080),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Suivant'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
