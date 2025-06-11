import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart'; // Add this import at the top

class ResultatsPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ResultatsPage({super.key, required this.userData});

  @override
  _ResultatsPageState createState() => _ResultatsPageState();
}

class _ResultatsPageState extends State<ResultatsPage> {
  late String? token;
  List<dynamic> quizResults = [];
  List<dynamic> lessonProgress = [];
  List<dynamic> gameScores = [];
  List<dynamic> testSubmissions = [];
  dynamic modalContent;
  String? error;
  bool isLoading = false;
  bool isModalVisible = false; // Track modal visibility for animation

  final FlutterSecureStorage storage = const FlutterSecureStorage();
  @override
  void initState() {
    super.initState();
    _initializeDateFormatting().then((_) => _loadTokenAndFetchResults());
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('fr_FR', null);
  }

  // Future<void> _loadTokenAndFetchResults() async {
  //   token = await storage.read(key: 'jwt_token');
  //   if (token == null) {
  //     context.go('/login-eleve');
  //     return;
  //   }
  //   await _fetchResults();
  // }

  Future<void> _loadTokenAndFetchResults() async {
    token = await storage.read(key: 'jwt_token');
    if (token == null) {
      context.go('/login-eleve');
      return;
    }
    await _fetchResults();
  }

  Future<void> _fetchResults() async {
    if (token == null) return;
    setState(() => isLoading = true);
    try {
      final config = {'Authorization': 'Bearer $token'};

      final quizResponse = await http.get(
        Uri.parse('https://kara-back.onrender.com/api/student/quizs'),
        headers: config,
      );
      if (quizResponse.statusCode == 200) {
        final data = jsonDecode(quizResponse.body);
        final quizzes = [
          ...(data['quizzes']?['facile'] ?? []),
          ...(data['quizzes']?['moyen'] ?? []),
          ...(data['quizzes']?['difficile'] ?? []),
        ].where((quiz) => quiz['submissions']?.isNotEmpty ?? false).toList();
        setState(() => quizResults = quizzes);
      }

      final lessonResponse = await http.get(
        Uri.parse('https://kara-back.onrender.com/api/student/lessons'),
        headers: config,
      );
      if (lessonResponse.statusCode == 200) {
        setState(() => lessonProgress = jsonDecode(lessonResponse.body));
      }

      final scoreResponse = await http.get(
        Uri.parse('https://kara-back.onrender.com/api/student/scores/user'),
        headers: config,
      );
      if (scoreResponse.statusCode == 200) {
        setState(() => gameScores = jsonDecode(scoreResponse.body));
      }

      final testResponse = await http.get(
        Uri.parse('https://kara-back.onrender.com/api/student/tests'),
        headers: config,
      );
      if (testResponse.statusCode == 200) {
        setState(() => testSubmissions = jsonDecode(testResponse.body)
            .where((test) => test['submission'] != null)
            .toList());
      }

      setState(() => error = null);
    } catch (e) {
      setState(() => error = 'Erreur lors du chargement des résultats.');
      if (e.toString().contains('401')) {
        context.go('/login-eleve');
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void openModal(String type, dynamic data) {
    setState(() {
      modalContent = {'type': type, 'data': data};
      isModalVisible = true;
    });
  }

  void closeModal() {
    setState(() {
      isModalVisible = false;
    });
    // Delay to allow fade-out animation before clearing content
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => modalContent = null);
      }
    });
  }

  Widget renderModalContent() {
    if (modalContent == null) return const SizedBox.shrink();

    switch (modalContent['type']) {
      case 'quiz':
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Résultats des Quiz',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              modalContent['data'].isEmpty
                  ? const Text(
                      'Aucun résultat de quiz disponible.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: modalContent['data'].length,
                      itemBuilder: (context, index) {
                        final quiz = modalContent['data'][index];
                        final latestSubmission =
                            quiz['submissions']?.last ?? {};
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              quiz['titre'] ?? 'Quiz inconnu',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Difficulté: ${quiz['difficulty']}'),
                                Text(
                                    'Score: ${latestSubmission['score'] ?? 0}/${latestSubmission['total'] ?? 0} (${latestSubmission['percentage']?.toStringAsFixed(2) ?? '0.00'}%)'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        );
      case 'test':
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Soumissions des Tests',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              modalContent['data'].isEmpty
                  ? const Text(
                      'Aucune soumission de test disponible.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: modalContent['data'].length,
                      itemBuilder: (context, index) {
                        final test = modalContent['data'][index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              test['title'] ?? 'Test inconnu',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Statut: ${test['submission']?['status'] ?? 'Non soumis'}'),
                                if (test['submission']?['submittedFile'] !=
                                    null)
                                  TextButton(
                                    onPressed: () {
                                      // Placeholder for file link
                                    },
                                    child: const Text('Voir la soumission'),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        );
      case 'lesson':
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Avancement des Cours',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              modalContent['data'].isEmpty
                  ? const Text(
                      'Aucun progrès de leçon disponible.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: modalContent['data'].length,
                      itemBuilder: (context, index) {
                        final lesson = modalContent['data'][index];
                        final progress = lesson['progress'] ?? {};
                        String status = progress['status'] ?? 'Non commencé';
                        if (status == 'not_started') status = 'Non commencé';
                        if (status == 'in_progress') status = 'En cours';
                        if (status == 'completed') status = 'Terminé';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              lesson['title'] ?? 'Cours inconnu',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Statut: $status'),
                                Text(
                                    'Page: ${progress['currentPage'] ?? 1}/${lesson['totalPages'] ?? 1}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        );
      case 'score':
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scores des Jeux',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              modalContent['data'].isEmpty
                  ? const Text(
                      'Aucun score de jeu disponible.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: modalContent['data'].length,
                      itemBuilder: (context, index) {
                        final score = modalContent['data'][index];
                        String status = score['reviewed'] == true
                            ? 'Revu ✅'
                            : 'En attente ⏳';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              score['game']?['name'] ?? 'Jeu inconnu',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Date: ${DateFormat('EEEE, d MMMM yyyy', 'fr_FR').format(DateTime.parse(score['date'] ?? DateTime.now().toIso8601String()))}'),
                                Text('Statut: $status'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE6F0FA), Color(0xFFDAD1E6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mes Résultats',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                        ),
                        // IconButton(
                        //   icon: const Icon(Icons.arrow_back),
                        //   onPressed: goBack,
                        //   tooltip: 'Retour',
                        // ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    else ...[
                      _buildResultCard(
                        title: 'Résultats des Quiz',
                        description:
                            'Consultez vos scores et performances dans les quiz.',
                        count: quizResults.length,
                        color: Colors.green,
                        onTap: () => openModal('quiz', quizResults),
                      ),
                      const SizedBox(height: 16),
                      _buildResultCard(
                        title: 'Avancement des Cours',
                        description:
                            'Suivez votre progression dans les leçons.',
                        count: lessonProgress.length,
                        color: Colors.blue,
                        onTap: () => openModal('lesson', lessonProgress),
                      ),
                      const SizedBox(height: 16),
                      _buildResultCard(
                        title: 'Scores des Jeux',
                        description:
                            'Découvrez vos scores dans les jeux éducatifs.',
                        count: gameScores.length,
                        color: Colors.purple,
                        onTap: () => openModal('score', gameScores),
                      ),
                      const SizedBox(height: 16),
                      _buildResultCard(
                        title: 'Soumissions des Tests',
                        description:
                            'Vérifiez l\'état de vos soumissions de tests.',
                        count: testSubmissions.length,
                        color: Colors.red,
                        onTap: () => openModal('test', testSubmissions),
                      ),
                    ],
                  ],
                ),
              ),
              // Modal with fade animation
              AnimatedOpacity(
                opacity: isModalVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: !isModalVisible,
                  child: GestureDetector(
                    onTap: closeModal,
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Détails',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(color: Colors.purple),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: closeModal,
                                  ),
                                ],
                              ),
                              renderModalContent(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required String title,
    required String description,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Text(
                  '$count ${title.contains('Quiz') ? 'quiz complétés' : title.contains('Cours') ? 'leçons' : title.contains('Jeux') ? 'scores' : 'soumissions'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
