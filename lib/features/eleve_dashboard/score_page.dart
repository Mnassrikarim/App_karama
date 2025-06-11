import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

class ScorePage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ScorePage({super.key, required this.userData});

  @override
  State<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  final _storage = const FlutterSecureStorage();
  List<Score> _scores = [];
  String _error = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchScores();
  }

  Future<void> _fetchScores() async {
    setState(() => _isLoading = true);
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      context.go('/login-eleve');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://kara-back.onrender.com/api/student/scores/user'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _scores = data.map((json) => Score.fromJson(json)).toList();
          _error = '';
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        await _storage.delete(key: 'jwt_token');
        context.go('/login-eleve');
      } else {
        setState(() {
          _error = jsonDecode(response.body)['message'] ??
              'Erreur lors du chargement des scores';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des scores: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: 100), // Reduced width
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/jeux'),
                    icon:
                        const Icon(Icons.arrow_back, size: 20), // Smaller icon
                    label: const Text('Retour',
                        style: TextStyle(fontSize: 14)), // Smaller text
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      foregroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8), // Tighter padding
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Mes Scores 🏆',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_error.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error, style: const TextStyle(color: Colors.red)),
            ),
          Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _scores.isEmpty
                      ? Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.purple.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  '😢',
                                  style: TextStyle(fontSize: 48),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Aucun score enregistré',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Jouez à des jeux pour voir vos scores apparaître ici !',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                                minWidth: 600), // Ensures space for all columns
                            child: DataTable(
                              columnSpacing:
                                  16, // Reduced from default for compact layout
                              columns: const [
                                DataColumn(
                                  label: Text('Jeu',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                DataColumn(
                                  label: Text('Capture d’écran',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                DataColumn(
                                  label: Text('Date',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                DataColumn(
                                  label: Text('Statut',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                              rows: _scores.map((score) {
                                return DataRow(cells: [
                                  DataCell(
                                    Text(
                                      score.game?.name ?? 'Jeu inconnu',
                                      style:
                                          const TextStyle(color: Colors.indigo),
                                    ),
                                  ),
                                  DataCell(
                                    InkWell(
                                      onTap: () => launchUrl(
                                        Uri.parse(
                                            'https://kara-back.onrender.com${score.screenshot}'),
                                        mode: LaunchMode.externalApplication,
                                      ),
                                      child: Image.network(
                                        'https://kara-back.onrender.com${score.screenshot}',
                                        width: 80,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      DateTime.parse(score.date)
                                          .toLocal()
                                          .toString()
                                          .split('.')[0],
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: score.reviewed
                                            ? Colors.green.withOpacity(0.2)
                                            : Colors.yellow.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: score.reviewed
                                                  ? Colors.green
                                                  : Colors.yellow,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            score.reviewed
                                                ? 'Revu ✅'
                                                : 'En attente ⏳',
                                            style: TextStyle(
                                              color: score.reviewed
                                                  ? Colors.green
                                                  : Colors.yellow,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ]);
                              }).toList(),
                            ),
                          ),
                        )),
          const SizedBox(height: 100), // Space for bottom navigation
        ],
      ),
    );
  }
}

// Data models
class Score {
  final String _id;
  final String screenshot;
  final String date;
  final bool reviewed;
  final Game? game;

  Score({
    required String id,
    required this.screenshot,
    required this.date,
    required this.reviewed,
    this.game,
  }) : _id = id;

  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      id: json['_id'] ?? '',
      screenshot: json['screenshot'] ?? '',
      date: json['date'] ?? '',
      reviewed: json['reviewed'] ?? false,
      game: json['game'] != null ? Game.fromJson(json['game']) : null,
    );
  }
}

class Game {
  final String _id;
  final String name;
  final String url;
  final String? image;

  Game({required String id, required this.name, required this.url, this.image})
      : _id = id;

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Jeu sans nom',
      url: json['url'] ?? '',
      image: json['image'],
    );
  }
}
