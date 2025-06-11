import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePageEleve extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const HomePageEleve({Key? key, required this.userData}) : super(key: key);

  @override
  State<HomePageEleve> createState() => _HomePageEleveState();
}

class _HomePageEleveState extends State<HomePageEleve> {
  Map<String, dynamic>? quizData;
  List<dynamic>? categories;
  List<VocabularyData> vocabularyChartData = [];
  final _storage = const FlutterSecureStorage();
  bool isLoading = true;
  bool isLoadingVocabulary = true;
  String? error;
  int totalWordsLearned = 0;

  // Sample data for other charts (non-quiz)
  static final List<ChartData> _sampleJeuxData = [
    ChartData(1, 10),
    ChartData(2, 40),
    ChartData(3, 80),
  ];

  static final List<ChartData> _sampleTestsData = [
    ChartData(1, 50),
    ChartData(2, 65),
    ChartData(3, 90),
  ];

  // Color palette for categories
  static final List<Color> _categoryColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
    Colors.lime,
    Colors.deepOrange,
  ];

  @override
  void initState() {
    super.initState();
    _fetchQuizData();
    _fetchVocabularyData();
  }

  Future<void> _fetchQuizData() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      context.go('/login-eleve');
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('https://kara-back.onrender.com/api/student/quizs'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          quizData = data;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load quiz data: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error fetching quiz data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchVocabularyData() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      context.go('/login-eleve');
      return;
    }

    try {
      // First, fetch categories
      final categoriesResponse = await http.get(
        Uri.parse('https://kara-back.onrender.com/api/student/categories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (categoriesResponse.statusCode == 200) {
        final categoriesData = json.decode(categoriesResponse.body) as List;

        // Fetch vocabulary data for each category
        List<VocabularyData> vocabData = [];
        int totalWords = 0;

        for (int i = 0; i < categoriesData.length; i++) {
          final category = categoriesData[i];
          final categoryId = category['_id'];
          final categoryName = category['nom'];

          try {
            final vocabResponse = await http.get(
              Uri.parse(
                  'https://kara-back.onrender.com/api/student/vocab?categorieId=$categoryId'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
            );

            if (vocabResponse.statusCode == 200) {
              final vocabList = json.decode(vocabResponse.body) as List;
              final wordCount = vocabList.length;
              totalWords += wordCount;

              // Assign color from the palette (cycle through if more categories than colors)
              final color = _categoryColors[i % _categoryColors.length];

              if (wordCount > 0) {
                vocabData.add(
                    VocabularyData(categoryName, wordCount.toDouble(), color));
              }
            }
          } catch (e) {
            print('Error fetching vocabulary for category $categoryName: $e');
          }
        }

        setState(() {
          categories = categoriesData;
          vocabularyChartData = vocabData;
          totalWordsLearned = totalWords;
          isLoadingVocabulary = false;
        });
      } else {
        setState(() {
          error = 'Failed to load categories: ${categoriesResponse.statusCode}';
          isLoadingVocabulary = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error fetching vocabulary data: $e';
        isLoadingVocabulary = false;
      });
    }
  }

  // Calculate quiz statistics
  Map<String, dynamic> _calculateQuizStats() {
    if (quizData == null) {
      return {
        'totalQuizzes': 0,
        'completedQuizzes': 0,
        'facileCount': 0,
        'moyenCount': 0,
        'difficileCount': 0,
        'facileCompleted': 0,
        'moyenCompleted': 0,
        'difficileCompleted': 0,
      };
    }

    final quizzes = quizData!['quizzes'];

    // Count total quizzes by difficulty
    final facileCount = (quizzes['facile'] as List).length;
    final moyenCount = (quizzes['moyen'] as List).length;
    final difficileCount = (quizzes['difficile'] as List).length;
    final totalQuizzes = facileCount + moyenCount + difficileCount;

    // Count completed quizzes (those with submissions)
    int facileCompleted = 0;
    int moyenCompleted = 0;
    int difficileCompleted = 0;

    for (var quiz in quizzes['facile']) {
      if (quiz['submissions'] != null &&
          (quiz['submissions'] as List).isNotEmpty) {
        facileCompleted++;
      }
    }

    for (var quiz in quizzes['moyen']) {
      if (quiz['submissions'] != null &&
          (quiz['submissions'] as List).isNotEmpty) {
        moyenCompleted++;
      }
    }

    for (var quiz in quizzes['difficile']) {
      if (quiz['submissions'] != null &&
          (quiz['submissions'] as List).isNotEmpty) {
        difficileCompleted++;
      }
    }

    final completedQuizzes =
        facileCompleted + moyenCompleted + difficileCompleted;

    return {
      'totalQuizzes': totalQuizzes,
      'completedQuizzes': completedQuizzes,
      'facileCount': facileCount,
      'moyenCount': moyenCount,
      'difficileCount': difficileCount,
      'facileCompleted': facileCompleted,
      'moyenCompleted': moyenCompleted,
      'difficileCompleted': difficileCompleted,
    };
  }

  // Generate dynamic quiz performance data
  List<ChartData> _generateQuizChartData() {
    final stats = _calculateQuizStats();

    // Calculate completion percentages for each difficulty
    double facilePercentage = stats['facileCount'] > 0
        ? (stats['facileCompleted'] / stats['facileCount']) * 100
        : 0;
    double moyenPercentage = stats['moyenCount'] > 0
        ? (stats['moyenCompleted'] / stats['moyenCount']) * 100
        : 0;
    double difficilePercentage = stats['difficileCount'] > 0
        ? (stats['difficileCompleted'] / stats['difficileCount']) * 100
        : 0;

    return [
      ChartData(1, facilePercentage), // Facile
      ChartData(2, moyenPercentage), // Moyen
      ChartData(3, difficilePercentage), // Difficile
    ];
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, List<ChartData> data, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: NumericAxis(
                  minimum: 1,
                  maximum: 3,
                  interval: 1,
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLabelFormatter: (AxisLabelRenderDetails details) {
                    String label = '';
                    switch (details.value.toInt()) {
                      case 1:
                        label = 'Facile';
                        break;
                      case 2:
                        label = 'Moyen';
                        break;
                      case 3:
                        label = 'Difficile';
                        break;
                    }
                    return ChartAxisLabel(label, const TextStyle(fontSize: 10));
                  },
                ),
                primaryYAxis: NumericAxis(
                  minimum: 0,
                  maximum: 100,
                  interval: 20,
                  majorGridLines: const MajorGridLines(width: 0.5),
                ),
                plotAreaBorderWidth: 0,
                series: [
                  LineSeries<ChartData, num>(
                    dataSource: data,
                    color: color,
                    width: 3,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    markerSettings: MarkerSettings(
                      isVisible: true,
                      height: 8,
                      width: 8,
                      color: color,
                      borderColor: Colors.white,
                      borderWidth: 2,
                    ),
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelAlignment: ChartDataLabelAlignment.top,
                      textStyle: TextStyle(fontSize: 10),
                    ),
                  ),
                ],
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'point.x: point.y%',
                ),
              ),
            ),
            // Add difficulty breakdown
            const SizedBox(height: 8),
            _buildDifficultyBreakdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyBreakdown() {
    final stats = _calculateQuizStats();

    return Column(
      children: [
        const Divider(),
        const Text(
          'Détail par difficulté:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildDifficultyItem('Facile', stats['facileCompleted'],
                stats['facileCount'], Colors.green),
            _buildDifficultyItem('Moyen', stats['moyenCompleted'],
                stats['moyenCount'], Colors.orange),
            _buildDifficultyItem('Difficile', stats['difficileCompleted'],
                stats['difficileCount'], Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultyItem(
      String difficulty, int completed, int total, Color color) {
    return Column(
      children: [
        Text(
          difficulty,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600),
        ),
        Text(
          '$completed/$total',
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDynamicDoughnutChartCard(
      String title, List<VocabularyData> data) {
    if (isLoadingVocabulary) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 50),
              const Center(
                child: CircularProgressIndicator(),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      );
    }

    if (data.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 50),
              const Center(
                child: Text(
                  'Aucune donnée de vocabulaire disponible',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SfCircularChart(
                      legend: Legend(isVisible: false),
                      series: [
                        DoughnutSeries<VocabularyData, String>(
                          dataSource: data,
                          xValueMapper: (VocabularyData data, _) =>
                              data.category,
                          yValueMapper: (VocabularyData data, _) => data.value,
                          pointColorMapper: (VocabularyData data, _) =>
                              data.color,
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                            labelPosition: ChartDataLabelPosition.outside,
                            textStyle: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold),
                            labelIntersectAction: LabelIntersectAction.shift,
                          ),
                          innerRadius: '60%',
                          radius: '80%',
                          strokeColor: Colors.white,
                          strokeWidth: 2,
                        ),
                      ],
                      tooltipBehavior: TooltipBehavior(
                        enable: true,
                        format: 'point.x: point.y mots',
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: data
                            .map((item) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: item.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.category,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '${item.value.toInt()} mots',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardGroup(
      {required Widget summaryCard, required Widget chartCard}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          summaryCard,
          chartCard,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  isLoadingVocabulary = true;
                  error = null;
                });
                _fetchQuizData();
                _fetchVocabularyData();
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final stats = _calculateQuizStats();
    final quizChartData = _generateQuizChartData();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text(
              widget.userData != null
                  ? 'Bienvenue, ${widget.userData!['nom']} ${widget.userData!['prenom']} !'
                  : 'Bienvenue !',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          // Vocabulary Progress Section - NOW DYNAMIC
          _buildCardGroup(
            summaryCard: _buildSummaryCard(
                'Mots appris', totalWordsLearned.toString(), Colors.blue),
            chartCard: _buildDynamicDoughnutChartCard(
                'Progrès du Vocabulaire par Catégorie', vocabularyChartData),
          ),
          // Quiz Performance Section - DYNAMIC
          _buildCardGroup(
            summaryCard: _buildSummaryCard(
                'Quizzes complétés',
                '${stats['completedQuizzes']} / ${stats['totalQuizzes']}',
                Colors.orange),
            chartCard: _buildChartCard(
                'Performances aux Quiz', quizChartData, Colors.orange),
          ),
          // Games Progress Section
          // _buildCardGroup(
          //   summaryCard: _buildSummaryCard('Jeux complétés', '0', Colors.green),
          //   chartCard: _buildChartCard(
          //       'Progrès des Jeux', _sampleJeuxData, Colors.green),
          // ),
          // Tests Results Section
          // _buildCardGroup(
          //   summaryCard:
          //       _buildSummaryCard('Tests réussis', '0 / 2', Colors.purple),
          //   chartCard: _buildChartCard(
          //       'Résultats des Tests', _sampleTestsData, Colors.purple),
          // ),
          const SizedBox(height: 100), // Extra space for bottom navigation
        ],
      ),
    );
  }
}

// Data model for charts
class ChartData {
  ChartData(this.x, this.y);
  final int x;
  final double y;
}

// Data model for vocabulary progress (doughnut chart)
class VocabularyData {
  VocabularyData(this.category, this.value, this.color);
  final String category;
  final double value;
  final Color color;
}
