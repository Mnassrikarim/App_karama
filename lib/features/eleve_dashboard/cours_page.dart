import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:advance_pdf_viewer_fork/advance_pdf_viewer_fork.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class CoursPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const CoursPage({super.key, required this.userData});

  @override
  State<CoursPage> createState() => _CoursPageState();
}

class _CoursPageState extends State<CoursPage> {
  final _storage = const FlutterSecureStorage();
  List<Lesson> _lessons = [];
  Lesson? _selectedLesson;
  String _progressStatus = 'not_started';
  String _notes = '';
  int _currentPage = 1;
  int _totalPages = 1;
  bool _lastPageReached = false;
  String _error = '';
  String _success = '';
  bool _isLoading = true;
  PDFDocument? _pdfDocument;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _fetchLessons();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _fetchLessons() async {
    setState(() => _isLoading = true);
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      context.go('/login-eleve');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://kara-back.onrender.com/api/student/lessons'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _lessons = data.map((json) => Lesson.fromJson(json)).toList();
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        await _storage.delete(key: 'jwt_token');
        context.go('/login-eleve');
      } else {
        setState(() {
          _error = jsonDecode(response.body)['message'] ??
              'Erreur lors du chargement des leçons.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des leçons: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPdf(String url) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        setState(() => _error = 'Token non trouvé.');
        return;
      }
      print('Loading PDF from: $url');
      final pdf = await PDFDocument.fromURL(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      print('PDF loaded, page count: ${await pdf.count}');
      setState(() {
        _pdfDocument = pdf;
        _totalPages = pdf.count ?? 1;
        _pageController = PageController(initialPage: _currentPage - 1);
        _error = '';
      });
    } catch (e) {
      print('PDF load error: $e');
      setState(() => _error = 'Erreur lors du chargement du PDF: $e');
    }
  }

  void _selectLesson(Lesson lesson) {
    setState(() {
      _selectedLesson = lesson;
      _progressStatus = lesson.progress.status;
      _notes = lesson.progress.notes ?? '';
      _currentPage = lesson.progress.currentPage ?? 1;
      _totalPages = lesson.totalPages ?? 1;
      _lastPageReached = _currentPage >= _totalPages;
      _error = '';
      _success = '';
      _pdfDocument = null;
      _pageController?.dispose();
      _pageController = null;
    });

    if (lesson.mediaFile != null && lesson.mediaFile!.endsWith('.pdf')) {
      _loadPdf('https://kara-back.onrender.com/Uploads/${lesson.mediaFile}');
    }
  }

  void _handlePageChange(int newPage) {
    setState(() {
      _currentPage = newPage;
      _lastPageReached = newPage >= _totalPages;
      if (_progressStatus == 'not_started') {
        _progressStatus = 'in_progress';
      }
    });
  }

  Future<void> _updateProgress() async {
    if (_progressStatus == 'completed' && !_lastPageReached) {
      setState(() {
        _error =
            'Vous devez atteindre la dernière page pour marquer la leçon comme terminée.';
      });
      return;
    }

    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      context.go('/login-eleve');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
            'https://kara-back.onrender.com/api/student/lessons/progress'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'lessonId': _selectedLesson!._id,
          'status': _progressStatus,
          'notes': _notes.trim(),
          'currentPage': _currentPage,
        }),
      );

      if (response.statusCode == 200) {
        final updatedProgress = Progress.fromJson(jsonDecode(response.body));
        setState(() {
          _lessons = _lessons
              .map((lesson) => lesson._id == _selectedLesson!._id
                  ? lesson.copyWith(progress: updatedProgress)
                  : lesson)
              .toList();
          _selectedLesson =
              _selectedLesson!.copyWith(progress: updatedProgress);
          _success = 'Progression mise à jour avec succès !';
          _error = '';
        });
      } else if (response.statusCode == 401) {
        await _storage.delete(key: 'jwt_token');
        context.go('/login-eleve');
      } else {
        setState(() {
          _error = jsonDecode(response.body)['message'] ??
              'Erreur lors de la mise à jour de la progression.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la mise à jour de la progression: $e';
      });
    }
  }

  Widget _buildLessonList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo, Colors.purple],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Text(
              'Liste des Leçons',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_lessons.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Aucune leçon disponible.',
                style:
                    TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _lessons.length,
              itemBuilder: (context, index) {
                final lesson = _lessons[index];
                return GestureDetector(
                  onTap: () => _selectLesson(lesson),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _selectedLesson?._id == lesson._id
                          ? Colors.purple.withOpacity(0.1)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedLesson?._id == lesson._id
                            ? Colors.purple.withOpacity(0.4)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            lesson.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: lesson.progress.status == 'not_started'
                                ? Colors.yellow[100]
                                : lesson.progress.status == 'in_progress'
                                    ? Colors.blue[100]
                                    : Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            lesson.progress.status == 'not_started'
                                ? 'Non commencé'
                                : lesson.progress.status == 'in_progress'
                                    ? 'En cours'
                                    : 'Terminé',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: lesson.progress.status == 'not_started'
                                  ? Colors.yellow[800]
                                  : lesson.progress.status == 'in_progress'
                                      ? Colors.blue[800]
                                      : Colors.green[800],
                            ),
                          ),
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
  }

  Widget _buildLessonDetails() {
    if (_selectedLesson == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.indigo],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              _selectedLesson!.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Programme and Unit
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Programme',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                            Text(
                              _selectedLesson!.programId?.title ?? 'N/A',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Unité',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple,
                              ),
                            ),
                            Text(
                              _selectedLesson!.unitId?.title ?? 'N/A',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Content (PDF or Text)
                if (_selectedLesson!.mediaFile != null &&
                    _selectedLesson!.mediaFile!.endsWith('.pdf'))
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!, width: 2),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: Column(
                      children: [
                        if (_pdfDocument != null && _pageController != null)
                          SizedBox(
                            height: 400,
                            child: PDFViewer(
                              document: _pdfDocument!,
                              scrollDirection: Axis.vertical,
                              showPicker: false,
                              showIndicator: false,
                              controller: _pageController,
                            ),
                          )
                        else
                          const Center(child: CircularProgressIndicator()),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                onPressed: _currentPage <= 1
                                    ? null
                                    : () {
                                        _pageController!.previousPage(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                        _handlePageChange(_currentPage - 1);
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _currentPage <= 1
                                      ? Colors.grey[200]
                                      : Colors.blue,
                                  foregroundColor: _currentPage <= 1
                                      ? Colors.grey[500]
                                      : Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('←'),
                              ),
                              Text(
                                'Page $_currentPage sur $_totalPages',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87),
                              ),
                              ElevatedButton(
                                onPressed: _currentPage >= _totalPages
                                    ? null
                                    : () {
                                        _pageController!.nextPage(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                        _handlePageChange(_currentPage + 1);
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _currentPage >= _totalPages
                                      ? Colors.grey[200]
                                      : Colors.blue,
                                  foregroundColor: _currentPage >= _totalPages
                                      ? Colors.grey[500]
                                      : Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('→'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!, width: 2),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contenu:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        if (_selectedLesson!.content != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Text(_selectedLesson!.content!),
                          )
                        else
                          const Text(
                            'Aucun contenu textuel',
                            style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic),
                          ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                onPressed: _currentPage <= 1
                                    ? null
                                    : () => _handlePageChange(_currentPage - 1),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _currentPage <= 1
                                      ? Colors.grey[200]
                                      : Colors.blue,
                                  foregroundColor: _currentPage <= 1
                                      ? Colors.grey[500]
                                      : Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('←'),
                              ),
                              Text(
                                'Page $_currentPage sur $_totalPages',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87),
                              ),
                              ElevatedButton(
                                onPressed: _currentPage >= _totalPages
                                    ? null
                                    : () => _handlePageChange(_currentPage + 1),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _currentPage >= _totalPages
                                      ? Colors.grey[200]
                                      : Colors.blue,
                                  foregroundColor: _currentPage >= _totalPages
                                      ? Colors.grey[500]
                                      : Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('→'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                // Media File Link
                if (_selectedLesson!.mediaFile != null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InkWell(
                      onTap: () async {
                        final url = Uri.parse(
                            'https://kara-back.onrender.com/Uploads/${_selectedLesson!.mediaFile}');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.file_download,
                              color: Colors.indigo, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Voir le fichier (${_selectedLesson!.mediaFile})',
                              style: const TextStyle(
                                color: Colors.indigo,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Progress Section
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF0FFF4), Color(0xFFE6F3FF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    border: Border.all(color: Colors.green[200]!, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Progression',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _progressStatus,
                        items: [
                          const DropdownMenuItem(
                            value: 'not_started',
                            child: Text('Non commencé'),
                          ),
                          const DropdownMenuItem(
                            value: 'in_progress',
                            child: Text('En cours'),
                          ),
                          DropdownMenuItem(
                            value: 'completed',
                            enabled: _lastPageReached,
                            child: Text(
                              'Terminé',
                              style: TextStyle(
                                color: _lastPageReached
                                    ? Colors.black87
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _progressStatus = value);
                          }
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.blue[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Colors.blue[400]!, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _notes,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Ajouter des notes...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.purple[200]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Colors.purple[400]!, width: 2),
                          ),
                        ),
                        onChanged: (value) => _notes = value,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _updateProgress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          'Mettre à jour',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text(
              'Cours',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
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
              child: Text(
                _error,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (_success.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[100],
                border: Border.all(color: Colors.green[500]!, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _success,
                style: const TextStyle(color: Colors.green),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                // Tablet/Desktop: Side-by-side
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 1, child: _buildLessonList()),
                    Expanded(flex: 2, child: _buildLessonDetails()),
                  ],
                );
              } else {
                // Mobile: Stacked
                return Column(
                  children: [
                    _buildLessonList(),
                    _buildLessonDetails(),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 100), // Space for bottom navigation
        ],
      ),
    );
  }
}

// Data models
class Lesson {
  final String _id;
  final String title;
  final String? mediaFile;
  final String? content;
  final int? totalPages;
  final Program? programId;
  final Unit? unitId;
  final Progress progress;

  Lesson({
    required String id,
    required this.title,
    this.mediaFile,
    this.content,
    this.totalPages,
    this.programId,
    this.unitId,
    required this.progress,
  }) : _id = id;

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['_id'],
      title: json['title'],
      mediaFile: json['mediaFile'],
      content: json['content'],
      totalPages: json['totalPages'],
      programId: json['programId'] != null
          ? Program.fromJson(json['programId'])
          : null,
      unitId: json['unitId'] != null ? Unit.fromJson(json['unitId']) : null,
      progress: Progress.fromJson(json['progress'] ?? {}),
    );
  }

  Lesson copyWith({Progress? progress}) {
    return Lesson(
      id: _id,
      title: title,
      mediaFile: mediaFile,
      content: content,
      totalPages: totalPages,
      programId: programId,
      unitId: unitId,
      progress: progress ?? this.progress,
    );
  }
}

class Program {
  final String title;

  Program({required this.title});

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(title: json['title']);
  }
}

class Unit {
  final String title;

  Unit({required this.title});

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(title: json['title']);
  }
}

class Progress {
  final String status;
  final String? notes;
  final int? currentPage;

  Progress({
    required this.status,
    this.notes,
    this.currentPage,
  });

  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      status: json['status'] ?? 'not_started',
      notes: json['notes'],
      currentPage: json['currentPage'],
    );
  }
}
