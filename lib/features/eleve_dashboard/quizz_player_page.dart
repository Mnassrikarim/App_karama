import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

class QuizPlayerPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String quizId;

  const QuizPlayerPage(
      {super.key, required this.userData, required this.quizId});

  @override
  State<QuizPlayerPage> createState() => _QuizPlayerPageState();
}

class _QuizPlayerPageState extends State<QuizPlayerPage>
    with SingleTickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();
  Quiz? _selectedQuiz;
  int _currentQuestionIndex = 0;
  List<List<dynamic>> _answers = [];
  List<Map<String, dynamic>?> _results = [];
  String _error = '';
  String _warning = '';
  List<Map<String, dynamic>> _selectedPairs = [];
  Map<String, dynamic>? _drawingPair;
  Map<String, dynamic>? _showResults;
  bool _isSubmitting = false;
  bool _isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fetchQuiz(false);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchQuiz(bool isRetake) async {
    setState(() => _isLoading = true);
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      context.go('/login-eleve');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://kara-back.onrender.com/api/quizs/${widget.quizId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final quizData = jsonDecode(response.body);
        // Validate matching questions
        for (var question in quizData['questions'] ?? []) {
          if (question['type'] == 'matching') {
            print('Matching question responses: ${question['reponses']}');
            for (var response in question['reponses'] ?? []) {
              if (response['texte'] == null &&
                  response['imageUrl'] == null &&
                  response['audioUrl'] == null) {
                setState(() {
                  _error =
                      'Invalid matching question: no text, image, or audio.';
                  _isLoading = false;
                });
                return;
              }
            }
          }
        }
        setState(() {
          _selectedQuiz = Quiz.fromJson(quizData);
          _answers = List.generate(quizData['questions'].length, (_) => []);
          _results = List.generate(quizData['questions'].length, (_) => null);
          _selectedPairs = [];
          _currentQuestionIndex = 0;
          _error = '';
          _warning = '';
          _drawingPair = null;
          _isLoading = false;
        });

        if (!isRetake) {
          final quizResponse = await http.get(
            Uri.parse('https://kara-back.onrender.com/api/student/quizs'),
            headers: {'Authorization': 'Bearer $token'},
          );
          if (quizResponse.statusCode == 200) {
            final quizListData = jsonDecode(quizResponse.body);
            final allQuizzes = [
              ...quizListData['quizzes']['facile'],
              ...quizListData['quizzes']['moyen'],
              ...quizListData['quizzes']['difficile'],
            ];
            final quiz = allQuizzes.firstWhere((q) => q['_id'] == widget.quizId,
                orElse: () => null);
            if (quiz != null &&
                quiz['submissions'] != null &&
                quiz['submissions'].isNotEmpty) {
              setState(() {
                _showResults = quiz['submissions'].last;
              });
            } else {
              setState(() => _showResults = null);
            }
          }
        } else {
          setState(() => _showResults = null);
        }
      } else if (response.statusCode == 401) {
        await _storage.delete(key: 'jwt_token');
        context.go('/login-eleve');
      } else {
        setState(() {
          _error = jsonDecode(response.body)['message'] ??
              'Erreur lors du chargement du quiz.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement du quiz: $e';
        _isLoading = false;
      });
    }
  }

  void _retakeQuiz() {
    _fetchQuiz(true);
  }

  void _handleAnswerChange(int qIndex, String value) {
    setState(() {
      _answers[qIndex] = [value];
    });
  }

  void _handleStartPair(int leftIndex) {
    if (_drawingPair == null && !_isSubmitting) {
      setState(() {
        _drawingPair = {'left': leftIndex};
      });
    }
  }

  void _handleEndPair(int rightIndex) {
    if (_drawingPair != null && !_isSubmitting) {
      final leftIndex = _drawingPair!['left'];
      final leftResponse = _selectedQuiz!
          .questions[_currentQuestionIndex].responses[leftIndex * 2];
      final rightResponse = _selectedQuiz!
          .questions[_currentQuestionIndex].responses[rightIndex * 2 + 1];
      final pair = {
        'left': leftIndex,
        'right': rightIndex,
        'leftId': leftResponse.id,
        'rightId': rightResponse.id,
        'leftText':
            leftResponse.text.isNotEmpty ? leftResponse.text : 'No text',
        'rightText':
            rightResponse.text.isNotEmpty ? rightResponse.text : 'No text',
      };

      if (!_selectedPairs
          .any((p) => p['left'] == leftIndex || p['right'] == rightIndex)) {
        setState(() {
          _selectedPairs = [..._selectedPairs, pair];
          _answers[_currentQuestionIndex] = _selectedPairs
              .map((p) => {
                    'leftId': p['leftId'],
                    'rightId': p['rightId'],
                  })
              .toList();
          _drawingPair = null;
        });
      } else {
        setState(() => _drawingPair = null);
      }
    }
  }

  void _handleRemovePair(int index) {
    if (!_isSubmitting) {
      setState(() {
        _selectedPairs = _selectedPairs
            .asMap()
            .entries
            .where((entry) => entry.key != index)
            .map((entry) => entry.value)
            .toList();
        _answers[_currentQuestionIndex] = _selectedPairs
            .map((p) => {
                  'leftId': p['leftId'],
                  'rightId': p['rightId'],
                })
            .toList();
      });
    }
  }

  Future<void> _submitAnswer() async {
    final currentQuestion = _selectedQuiz!.questions[_currentQuestionIndex];

    // Validate answers
    if (currentQuestion.type == 'matching' && _selectedPairs.isEmpty) {
      setState(
          () => _error = 'Veuillez sélectionner au moins une correspondance.');
      return;
    }
    if (['multiple_choice', 'true_false'].contains(currentQuestion.type) &&
        (_answers[_currentQuestionIndex].isEmpty)) {
      setState(() => _error = 'Veuillez sélectionner une réponse.');
      return;
    }

    // Move to next question
    if (_currentQuestionIndex < _selectedQuiz!.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedPairs = [];
        _drawingPair = null;
        _error = '';
        _animationController.forward(from: 0);
      });
      return;
    }

    // Submit quiz with retry logic
    const maxRetries = 3;
    int retryCount = 0;
    bool success = false;

    while (retryCount < maxRetries && !success) {
      try {
        setState(() => _isSubmitting = true);
        final token = await _storage.read(key: 'jwt_token');
        if (token == null) {
          context.go('/login-eleve');
          return;
        }

        final submissionData = {
          'quizId': _selectedQuiz!.id,
          'responses': _selectedQuiz!.questions.asMap().entries.map((entry) {
            final i = entry.key;
            final q = entry.value;
            return {
              'questionId': q.id,
              'selectedResponseIds': q.type != 'matching' ? _answers[i] : [],
              'matchingPairs': q.type == 'matching'
                  ? (_answers[i]
                      .map((p) => {
                            'leftId': p['leftId'],
                            'rightId': p['rightId'],
                          })
                      .toList())
                  : [],
            };
          }).toList(),
        };

        final response = await http.post(
          Uri.parse('https://kara-back.onrender.com/api/student/quizs/submit'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(submissionData),
        );

        if (response.statusCode == 200) {
          success = true;
          context.go('/quizz', extra: widget.userData);
        } else if (response.statusCode == 401) {
          await _storage.delete(key: 'jwt_token');
          context.go('/login-eleve');
        } else if (response.statusCode == 502 && retryCount < maxRetries - 1) {
          setState(() {
            _error =
                'Erreur de serveur détectée (502). Nouvelle tentative en cours...';
          });
          await Future.delayed(Duration(seconds: 2)); // Wait before retry
        } else {
          setState(() {
            _error =
                'Erreur lors de la soumission du quiz (Code: ${response.statusCode}): ${response.reasonPhrase ?? 'Erreur inconnue'}';
          });
        }
      } catch (e) {
        if (retryCount < maxRetries - 1 && e.toString().contains('502')) {
          setState(() {
            _error =
                'Erreur de connexion (502). Nouvelle tentative en cours...';
          });
          await Future.delayed(Duration(seconds: 2)); // Wait before retry
        } else {
          setState(() {
            _error =
                'Impossible de soumettre le quiz. Vérifiez votre connexion ou réessayez plus tard: $e';
          });
        }
      } finally {
        if (!success && retryCount < maxRetries - 1) {
          retryCount++;
        } else {
          setState(() => _isSubmitting = false);
        }
      }
    }

    if (!success) {
      setState(() => _isSubmitting = false);
    }
  }

  void _resetQuiz() {
    context.go('/quizz', extra: widget.userData);
  }

  List<Map<String, dynamic>> _shuffleArray(List<Map<String, dynamic>> array) {
    final shuffled = [...array];
    for (int i = shuffled.length - 1; i > 0; i--) {
      final j = Random().nextInt(i + 1);
      final temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }
    return shuffled;
  }

  Map<String, List<Map<String, dynamic>>> get _shuffledMatchingResponses {
    if (_selectedQuiz == null ||
        _currentQuestionIndex >= _selectedQuiz!.questions.length) {
      return {'left': [], 'right': []};
    }
    final responses = _selectedQuiz!.questions[_currentQuestionIndex].responses;
    final leftItems = responses
        .asMap()
        .entries
        .where((e) => e.key % 2 == 0)
        .map((e) => {
              ...e.value.toJson(),
              'text': e.value.text, // Add 'text' key explicitly
              'originalIndex': e.key ~/ 2
            })
        .toList();
    final rightItems = responses
        .asMap()
        .entries
        .where((e) => e.key % 2 != 0)
        .map((e) => {
              ...e.value.toJson(),
              'text': e.value.text, // Add 'text' key explicitly
              'originalIndex': (e.key - 1) ~/ 2
            })
        .toList();

    final shuffledLeft = _shuffleArray(leftItems);
    final shuffledRight = _shuffleArray(rightItems);
    bool validShuffle = false;
    int attempts = 0;
    const maxAttempts = 100;

    while (!validShuffle && attempts < maxAttempts) {
      final tempRight = _shuffleArray([...shuffledRight]);
      validShuffle = shuffledLeft.asMap().entries.every((entry) {
        final leftItem = entry.value;
        final rightItem = tempRight[entry.key];
        return rightItem['originalIndex'] != leftItem['originalIndex'];
      });
      if (validShuffle) {
        return {'left': shuffledLeft, 'right': tempRight};
      }
      attempts++;
    }

    final offsetRight = [...shuffledRight.skip(1), shuffledRight.first];
    return {'left': shuffledLeft, 'right': offsetRight};
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _selectedQuiz == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Container(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Passer un Quiz',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.go('/quizz', extra: widget.userData),
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
            if (_warning.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  border: Border.all(color: Colors.yellow[500]!, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_warning,
                    style: const TextStyle(color: Colors.yellow)),
              ),
            if (_isSubmitting)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  border: Border.all(color: Colors.blue[500]!, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 8),
                    Text('Soumission en cours...',
                        style: TextStyle(color: Colors.blue)),
                  ],
                ),
              ),
            if (_showResults != null)
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
                child: Column(
                  children: [
                    Text(
                      'Résultats du Quiz: ${_selectedQuiz!.title}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.green, Colors.blue],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Score: ${_showResults!['score']} / ${_showResults!['total']}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '(${(_showResults!['percentage']).toStringAsFixed(2)}%)',
                            style: const TextStyle(
                                fontSize: 18, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Niveau suivant recommandé: ${_showResults!['nextLevel']}',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...(_showResults!['results'] as List)
                        .asMap()
                        .entries
                        .map((entry) {
                      final result = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: result['isCorrect']
                              ? Colors.green[50]
                              : Colors.red[50],
                          border: Border(
                              left: BorderSide(
                                  color: result['isCorrect']
                                      ? Colors.green
                                      : Colors.red,
                                  width: 4)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Question: ${result['question']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('Votre réponse: ${result['selectedAnswer']}'),
                            Text(
                              'Statut: ${result['isCorrect'] ? 'Correcte ✓' : 'Incorrecte ✗'}',
                              style: TextStyle(
                                color: result['isCorrect']
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _resetQuiz,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          child: const Text('Retour aux quiz'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _retakeQuiz,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          child: const Text('Recommencer'),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _selectedQuiz!.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _selectedQuiz!.difficulty == 'Facile'
                                ? Colors.green[100]
                                : _selectedQuiz!.difficulty == 'Moyen'
                                    ? Colors.yellow[100]
                                    : Colors.red[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _selectedQuiz!.difficulty,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _selectedQuiz!.difficulty == 'Facile'
                                  ? Colors.green[800]
                                  : _selectedQuiz!.difficulty == 'Moyen'
                                      ? Colors.yellow[800]
                                      : Colors.red[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Question ${_currentQuestionIndex + 1}: ${_selectedQuiz!.questions[_currentQuestionIndex].statement}',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          if (_selectedQuiz!
                                  .questions[_currentQuestionIndex].imageUrl !=
                              null)
                            Image.network(
                              'https://kara-back.onrender.com/Uploads/${_selectedQuiz!.questions[_currentQuestionIndex].imageUrl}',
                              width: 360,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image),
                            ),
                          if (_selectedQuiz!
                                  .questions[_currentQuestionIndex].audioUrl !=
                              null)
                            AudioPlayerWidget(
                              url:
                                  'https://kara-back.onrender.com/Uploads/${_selectedQuiz!.questions[_currentQuestionIndex].audioUrl}',
                            ),
                          const SizedBox(height: 16),
                          if (['multiple_choice', 'true_false'].contains(
                              _selectedQuiz!
                                  .questions[_currentQuestionIndex].type))
                            ..._selectedQuiz!
                                .questions[_currentQuestionIndex].responses
                                .map((r) {
                              return GestureDetector(
                                onTap: () => _handleAnswerChange(
                                    _currentQuestionIndex, r.id),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _answers[_currentQuestionIndex]
                                            .contains(r.id)
                                        ? Colors.purple[100]
                                        : Colors.white,
                                    border: Border.all(
                                      color: _answers[_currentQuestionIndex]
                                              .contains(r.id)
                                          ? Colors.purple
                                          : Colors.grey[200]!,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Radio<String>(
                                        value: r.id,
                                        groupValue: _answers[
                                                    _currentQuestionIndex]
                                                .isNotEmpty
                                            ? _answers[_currentQuestionIndex][0]
                                            : null,
                                        onChanged: (value) =>
                                            _handleAnswerChange(
                                                _currentQuestionIndex, value!),
                                        activeColor: Colors.purple,
                                      ),
                                      Expanded(child: Text(r.text)),
                                      if (r.imageUrl != null)
                                        Image.network(
                                          'https://kara-back.onrender.com/Uploads/${r.imageUrl}',
                                          width: 100,
                                          errorBuilder: (context, error,
                                                  stackTrace) =>
                                              const Icon(Icons.broken_image),
                                        ),
                                      if (r.audioUrl != null)
                                        AudioPlayerWidget(
                                            url:
                                                'https://kara-back.onrender.com/Uploads/${r.audioUrl}'),
                                    ],
                                  ),
                                ),
                              );
                            })
                          else
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          const Text(
                                            'Éléments à relier',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue),
                                          ),
                                          ..._shuffledMatchingResponses['left']!
                                              .map((r) {
                                            return GestureDetector(
                                              onTap: () => _handleStartPair(
                                                  r['originalIndex']),
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                    milliseconds: 200),
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 4),
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color:
                                                      _drawingPair?['left'] ==
                                                              r['originalIndex']
                                                          ? Colors.purple[200]
                                                          : Colors.white,
                                                  border: Border.all(
                                                    color: _drawingPair?[
                                                                'left'] ==
                                                            r['originalIndex']
                                                        ? Colors.purple
                                                        : Colors.grey[200]!,
                                                    width: 2,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Text(r['text'] ??
                                                        'No text available'), // Use 'text' key with fallback
                                                    if (r['imageUrl'] != null)
                                                      Image.network(
                                                        'https://kara-back.onrender.com/Uploads/${r['imageUrl']}',
                                                        width: 100,
                                                        errorBuilder: (context,
                                                                error,
                                                                stackTrace) =>
                                                            const Icon(Icons
                                                                .broken_image),
                                                      ),
                                                    if (r['audioUrl'] != null)
                                                      AudioPlayerWidget(
                                                          url:
                                                              'https://kara-back.onrender.com/Uploads/${r['audioUrl']}'),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          const Text(
                                            'Correspondances',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green),
                                          ),
                                          ..._shuffledMatchingResponses[
                                                  'right']!
                                              .map((r) {
                                            return GestureDetector(
                                              onTap: () => _handleEndPair(
                                                  r['originalIndex']),
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                    milliseconds: 200),
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 4),
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: _selectedPairs.any(
                                                          (p) =>
                                                              p['right'] ==
                                                              r['originalIndex'])
                                                      ? Colors.green[100]
                                                      : Colors.white,
                                                  border: Border.all(
                                                      color: Colors.grey[200]!,
                                                      width: 2),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Text(r['text'] ??
                                                        'No text available'), // Use 'text' key with fallback
                                                    if (r['imageUrl'] != null)
                                                      Image.network(
                                                        'https://kara-back.onrender.com/Uploads/${r['imageUrl']}',
                                                        width: 100,
                                                        errorBuilder: (context,
                                                                error,
                                                                stackTrace) =>
                                                            const Icon(Icons
                                                                .broken_image),
                                                      ),
                                                    if (r['audioUrl'] != null)
                                                      AudioPlayerWidget(
                                                          url:
                                                              'https://kara-back.onrender.com/Uploads/${r['audioUrl']}'),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: const Text(
                                              'Paires sélectionnées :',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.yellow,
                                              ),
                                              textAlign: TextAlign
                                                  .center, // Optional: Centers the text horizontally
                                            ),
                                          ),
                                        ],
                                      ),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _selectedPairs
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          final pair = entry.value;
                                          final displayText = (pair['leftText']
                                                          ?.isNotEmpty ??
                                                      false) &&
                                                  (pair['rightText']
                                                          ?.isNotEmpty ??
                                                      false) &&
                                                  pair['leftText'] !=
                                                      'No text' &&
                                                  pair['rightText'] != 'No text'
                                              ? '${pair['leftText']} → ${pair['rightText']}'
                                              : 'Image/Audio Pair'; // Fallback for non-text content
                                          return Chip(
                                            label: Text(displayText),
                                            deleteIcon: const Icon(Icons.close,
                                                size: 18),
                                            onDeleted: () =>
                                                _handleRemovePair(entry.key),
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              side: const BorderSide(
                                                  color: Colors.yellow),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          if (_results[_currentQuestionIndex] != null)
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _results[_currentQuestionIndex]![
                                        'isCorrect']
                                    ? Colors.green[100]
                                    : Colors.red[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _results[_currentQuestionIndex]!['isCorrect']
                                    ? 'Correcte! 🎉'
                                    : 'Incorrecte! 😢',
                                style: TextStyle(
                                  color: _results[_currentQuestionIndex]![
                                          'isCorrect']
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: Tween(begin: 1.0, end: 1.05)
                              .animate(_animationController),
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitAnswer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _currentQuestionIndex ==
                                      _selectedQuiz!.questions.length - 1
                                  ? Colors.green
                                  : Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            child: Text(
                              _currentQuestionIndex ==
                                      _selectedQuiz!.questions.length - 1
                                  ? 'Terminer 🏁'
                                  : 'Suivant ➡️',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _resetQuiz,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.grey[800],
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          child: const Text('Annuler'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 100), // Space for bottom navigation
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
  final List<Question> questions;

  Quiz(
      {required this.id,
      required this.title,
      required this.difficulty,
      required this.questions});

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['_id'] ?? '',
      title: json['titre'] ?? 'Quiz sans titre',
      difficulty: json['difficulty'] ?? 'Moyen',
      questions: (json['questions'] as List? ?? [])
          .map((q) => Question.fromJson(q))
          .toList(),
    );
  }
}

class Question {
  final String id;
  final String statement;
  final String type;
  final String? imageUrl;
  final String? audioUrl;
  final List<Response> responses;

  Question({
    required this.id,
    required this.statement,
    required this.type,
    this.imageUrl,
    this.audioUrl,
    required this.responses,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['_id'] ?? '',
      statement: json['enonce'] ?? '',
      type: json['type'] ?? 'multiple_choice',
      imageUrl: json['imageUrl'],
      audioUrl: json['audioUrl'],
      responses: (json['reponses'] as List? ?? [])
          .map((r) => Response.fromJson(r))
          .toList(),
    );
  }
}

class Response {
  final String id;
  final String text;
  final String? imageUrl;
  final String? audioUrl;

  Response({
    required this.id,
    required this.text,
    this.imageUrl,
    this.audioUrl,
  });

  factory Response.fromJson(Map<String, dynamic> json) {
    return Response(
      id: json['_id'] ?? '',
      text: json['texte'] ?? 'No text available', // Fallback for null
      imageUrl: json['imageUrl'],
      audioUrl: json['audioUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'texte': text,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
    };
  }
}

// Placeholder audio player widget
class AudioPlayerWidget extends StatelessWidget {
  final String url;

  const AudioPlayerWidget({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Text('Audio: $url (Implement audio player here)'),
    );
  }
}
