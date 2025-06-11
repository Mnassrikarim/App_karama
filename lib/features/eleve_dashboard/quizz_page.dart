import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

class QuizzPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const QuizzPage({super.key, required this.userData});

  @override
  State<QuizzPage> createState() => _QuizzPageState();
}

class _QuizzPageState extends State<QuizzPage> {
  final _storage = const FlutterSecureStorage();
  List<Quiz> _quizzes = [];
  bool _isLoading = true;
  String _error = '';

  // Individual 3D effect states for each difficulty section
  Map<String, bool> _sectionEffects = {
    'facile': true,
    'moyen': true,
    'difficile': true,
  };

  @override
  void initState() {
    super.initState();
    _fetchQuizzes();
  }

  Future<void> _fetchQuizzes() async {
    setState(() => _isLoading = true);
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      context.go('/login-eleve');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://kara-back.onrender.com/api/student/quizs'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> allQuizzes = [
          ...data['quizzes']['facile'] ?? [],
          ...data['quizzes']['moyen'] ?? [],
          ...data['quizzes']['difficile'] ?? [],
        ];
        setState(() {
          _quizzes = allQuizzes.map((json) => Quiz.fromJson(json)).toList()
            ..sort((a, b) {
              final aCompleted = a.completionStatus != null &&
                  a.completionStatus!['completed'];
              final bCompleted = b.completionStatus != null &&
                  b.completionStatus!['completed'];
              if (aCompleted && !bCompleted) return 1;
              if (!aCompleted && bCompleted) return -1;
              return a.difficulty.compareTo(b.difficulty);
            });
          _isLoading = false;
          _error = '';
        });
      } else if (response.statusCode == 401) {
        await _storage.delete(key: 'jwt_token');
        context.go('/login-eleve');
      } else {
        setState(() {
          _error = jsonDecode(response.body)['message'] ??
              'Erreur lors du chargement des quiz.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des quiz: $e';
        _isLoading = false;
      });
    }
  }

  List<Quiz> getQuizzesByDifficulty(String difficulty) {
    return _quizzes.where((quiz) => quiz.difficulty == difficulty).toList();
  }

  bool _canAccessDifficulty(String difficulty) {
    if (difficulty == 'facile') return true;

    if (difficulty == 'moyen') {
      final facileQuizzes = getQuizzesByDifficulty('facile');
      return facileQuizzes.any((quiz) =>
          quiz.completionStatus != null && quiz.completionStatus!['completed']);
    }

    if (difficulty == 'difficile') {
      final moyenQuizzes = getQuizzesByDifficulty('moyen');
      return moyenQuizzes.any((quiz) =>
          quiz.completionStatus != null && quiz.completionStatus!['completed']);
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Liste des Quiz',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.go('/home-eleve', extra: widget.userData),
                    icon: const Icon(Icons.home, size: 16),
                    label: const Text('Retour'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                  color: Colors.red[100],
                  border: Border.all(color: Colors.red[500]!, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _buildDifficultySection('facile', 'Quiz Facile', Colors.green),
              const SizedBox(height: 20),
              _buildDifficultySection('moyen', 'Quiz Moyen', Colors.orange),
              const SizedBox(height: 20),
              _buildDifficultySection(
                  'difficile', 'Quiz Difficile', Colors.red),
            ],
            const SizedBox(height: 100), // Space for bottom navigation
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: 1,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.blue,
        onTap: (index) {
          if (index == 0) context.go('/messages');
          if (index == 1) context.go('/home-eleve');
          if (index == 2) context.go('/settings');
        },
      ),
    );
  }

  Widget _buildDifficultySection(
      String difficulty, String sectionTitle, Color baseColor) {
    final quizzes = getQuizzesByDifficulty(difficulty);
    final canAccess = _canAccessDifficulty(difficulty);
    final isLocked = !canAccess;
    final apply3DEffect = _sectionEffects[difficulty] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Section Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: isLocked ? Colors.grey : baseColor,
              borderRadius: isLocked
                  ? BorderRadius.circular(12)
                  : const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
            ),
            child: Row(
              children: [
                Text(
                  sectionTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isLocked) ...[
                  const Spacer(),
                  const Text(
                    '(Verrouillé)',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Quiz Cards Container - Only show when NOT locked
          if (!isLocked)
            GestureDetector(
              onPanUpdate: (details) {
                // Detect horizontal pan gestures
                if (details.delta.dx > 0) {
                  // Swiping right - apply 3D effect
                  setState(() {
                    _sectionEffects[difficulty] = true;
                    print('Swiping right on $difficulty - 3D effect applied');
                  });
                } else if (details.delta.dx < -0) {
                  // Swiping left - remove 3D effect
                  setState(() {
                    _sectionEffects[difficulty] = false;
                    print('Swiping left on $difficulty - 3D effect removed');
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Transform(
                  transform: apply3DEffect
                      ? (Matrix4.identity()
                        ..setEntry(3, 2, 0.003) // Perspective depth
                        ..rotateY(0.7)) // 3D rotation effect
                      : Matrix4.identity(),
                  alignment: Alignment.center,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: apply3DEffect
                          ? LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.9),
                                Colors.grey[200]!,
                              ],
                              stops: const [0.0, 0.7],
                            )
                          : null,
                    ),
                    child: quizzes.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'Aucun quiz disponible pour ce niveau.',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : Column(
                            children: quizzes.asMap().entries.map((entry) {
                              final index = entry.key;
                              final quiz = entry.value;
                              final isLast = index == quizzes.length - 1;

                              return _buildQuizCard(quiz, isLast, canAccess);
                            }).toList(),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(Quiz quiz, bool isLast, bool canAccess) {
    final isCompleted =
        quiz.completionStatus != null && quiz.completionStatus!['completed'];
    final percentage = isCompleted
        ? quiz.completionStatus!['percentage'].toStringAsFixed(1)
        : '0.0';

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quiz.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green[100]
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isCompleted
                              ? 'Complété ($percentage%)'
                              : 'Non complété',
                          style: TextStyle(
                            fontSize: 12,
                            color: isCompleted
                                ? Colors.green[700]
                                : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: canAccess
                  ? () {
                      context.go('/quiz/${quiz.id}', extra: widget.userData);
                    }
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Veuillez compléter le niveau précédent.'),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: !canAccess
                    ? Colors.grey[400]
                    : (isCompleted ? Colors.blue[600] : Colors.blue),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 0,
              ),
              child: Text(
                isCompleted ? 'Voir/Réessayer' : 'Commencer',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Data models
class Quiz {
  final String id;
  final String title;
  final String difficulty;
  final Map<String, dynamic>? completionStatus;

  Quiz({
    required this.id,
    required this.title,
    required this.difficulty,
    this.completionStatus,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    final submissions = json['submissions'] as List?;
    final completionStatus = submissions != null && submissions.isNotEmpty
        ? {
            'completed': true,
            'percentage':
                (submissions.last['score'] / submissions.last['total'] * 100),
          }
        : null;
    return Quiz(
      id: json['_id'] ?? '',
      title: json['titre'] ?? 'Quiz sans titre',
      difficulty: json['difficulty'] ?? 'moyen',
      completionStatus: completionStatus,
    );
  }
}
