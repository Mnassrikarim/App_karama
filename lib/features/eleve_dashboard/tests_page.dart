import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:url_launcher/url_launcher.dart';

class TestsPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const TestsPage({super.key, required this.userData});

  @override
  State<TestsPage> createState() => _TestsPageState();
}

class _TestsPageState extends State<TestsPage>
    with SingleTickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();
  List<Test> _tests = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String _error = '';
  String _success = '';
  Map<String, SubmissionForm> _submissionForms = {};
  late AnimationController _animationController;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cardAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _fetchTests();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchTests() async {
    setState(() => _isLoading = true);
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      context.go('/login-eleve');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://kara-back.onrender.com/api/student/tests'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> testsData = jsonDecode(response.body);
        setState(() {
          _tests = testsData.map((json) => Test.fromJson(json)).toList();
          _submissionForms = {
            for (var test in _tests)
              test.id: SubmissionForm(
                testId: test.id,
                submittedFile: null,
                submissionId: test.submission?.id ?? '',
                isEditing: test.submission != null,
              )
          };
          _isLoading = false;
          _error = '';
        });
      } else if (response.statusCode == 401) {
        await _storage.delete(key: 'jwt_token');
        context.go('/login-eleve');
      } else {
        setState(() {
          _error = jsonDecode(response.body)['message'] ??
              'Erreur lors du chargement des tests.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des tests: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleFileChange(String testId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'mp3', 'wav', 'ogg'],
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        print(
            'Picked File: name=${file.name}, bytes=${file.bytes != null}, path=${file.path != null}, size=${file.size}');
        setState(() {
          _submissionForms[testId] = SubmissionForm(
            testId: testId,
            submittedFile: file,
            submissionId: _submissionForms[testId]?.submissionId ?? '',
            isEditing: _submissionForms[testId]?.isEditing ?? false,
          );
          _error = '';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la sélection du fichier: $e';
      });
    }
  }

  Future<void> _handleSubmit(String testId, String? submissionId) async {
    setState(() {
      _error = '';
      _success = '';
      _isSubmitting = true;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        context.go('/login-eleve');
        return;
      }

      final formData = http.MultipartRequest(
        submissionId != null && _submissionForms[testId]!.isEditing
            ? 'PUT'
            : 'POST',
        Uri.parse(
          submissionId != null && _submissionForms[testId]!.isEditing
              ? 'https://kara-back.onrender.com/api/student/tests/submission/$submissionId'
              : 'https://kara-back.onrender.com/api/student/tests/submit',
        ),
      );
      formData.headers['Authorization'] = 'Bearer $token';
      formData.fields['testId'] = testId;

      if (_submissionForms[testId]?.submittedFile == null) {
        throw Exception('Aucun fichier sélectionné.');
      }

      final file = _submissionForms[testId]!.submittedFile!;
      print(
          'Attaching File: name=${file.name}, bytes=${file.bytes != null}, path=${file.path != null}, size=${file.size}');

      if (kIsWeb) {
        // Web platform: use bytes
        if (file.bytes == null) {
          throw Exception(
              'Fichier invalide: données binaires manquantes sur le web.');
        }
        formData.files.add(http.MultipartFile.fromBytes(
          'submittedFile',
          file.bytes!,
          filename: file.name,
          contentType: MediaType.parse(_getContentType(file.name)),
        ));
      } else {
        // Non-web platforms: use path
        if (file.path == null) {
          throw Exception(
              'Fichier invalide: chemin manquant sur une plateforme non-web.');
        }
        formData.files.add(await http.MultipartFile.fromPath(
          'submittedFile',
          file.path!,
          filename: file.name,
          contentType: MediaType.parse(_getContentType(file.name)),
        ));
      }

      print('Form Data Fields: ${formData.fields}');
      print(
          'Form Data Files: ${formData.files.map((f) => f.filename).toList()}');
      final streamedResponse = await formData.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _tests = _tests.map((test) {
            if (test.id == testId) {
              return Test(
                id: test.id,
                title: test.title,
                lessonId: test.lessonId,
                programId: test.programId,
                unitId: test.unitId,
                content: test.content,
                mediaFile: test.mediaFile,
                submission: Submission.fromJson(responseData),
              );
            }
            return test;
          }).toList();
          _submissionForms[testId] = SubmissionForm(
            testId: testId,
            submittedFile: null,
            submissionId: responseData['_id'] ?? '',
            isEditing: true,
          );
          _success = submissionId != null && _submissionForms[testId]!.isEditing
              ? 'Soumission mise à jour avec succès.'
              : 'Soumission envoyée avec succès.';
        });
      } else if (response.statusCode == 401) {
        await _storage.delete(key: 'jwt_token');
        context.go('/login-eleve');
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _error =
              'Erreur: ${errorData['message'] ?? 'Statut ${response.statusCode}'}';
        });
      }
    } catch (e) {
      print('Error in _handleSubmit: $e');
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // Helper method to infer content type (no change needed, just ensure it returns a valid MIME type)
  String _getContentType(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _handleDeleteSubmission(
      String submissionId, String testId) async {
    if (submissionId.isEmpty) {
      setState(() {
        _error = 'ID de soumission manquant ou invalide.';
      });
      return;
    }

    setState(() {
      _error = '';
      _success = '';
      _isSubmitting = true;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        context.go('/login-eleve');
        return;
      }

      final response = await http.delete(
        Uri.parse(
            'https://kara-back.onrender.com/api/student/tests/submission/$submissionId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _tests = _tests.map((test) {
            if (test.id == testId) {
              return Test(
                id: test.id,
                title: test.title,
                lessonId: test.lessonId,
                programId: test.programId,
                unitId: test.unitId,
                content: test.content,
                mediaFile: test.mediaFile,
                submission: null,
              );
            }
            return test;
          }).toList();
          _submissionForms[testId] = SubmissionForm(
            testId: testId,
            submittedFile: null,
            submissionId: '',
            isEditing: false,
          );
          _success = 'Soumission supprimée avec succès.';
        });
      } else if (response.statusCode == 401) {
        await _storage.delete(key: 'jwt_token');
        context.go('/login-eleve');
      } else {
        setState(() {
          _error = jsonDecode(response.body)['message'] ??
              'Erreur lors de la suppression de la soumission.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la suppression: $e';
      });
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _downloadFile(String url) async {
    final fullUrl = 'https://kara-back.onrender.com/Uploads/$url';
    if (await canLaunch(fullUrl)) {
      await launch(fullUrl);
    } else {
      setState(() {
        _error = 'Impossible d\'ouvrir le fichier: $fullUrl';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              // decoration: BoxDecoration(
              //   gradient: LinearGradient(
              //     colors: [
              //       Colors.indigo[600]!,
              //       Color.fromARGB(255, 255, 255, 255)!
              //     ],
              //     begin: Alignment.topLeft,
              //     end: Alignment.bottomRight,
              //   ),
              //   borderRadius:
              //       const BorderRadius.vertical(bottom: Radius.circular(20)),
              // ),
              // child: Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Text(
              //       'Mes Tests',
              //       style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              //             color: Colors.white,
              //             fontWeight: FontWeight.bold,
              //             fontSize: 24, // Optimized for 360px width
              //           ),
              //     ),
              //     IconButton(
              //       icon: const Icon(Icons.arrow_back,
              //           color: Colors.white, size: 28),
              //       onPressed: () =>
              //           context.go('/home-eleve', extra: widget.userData),
              //       tooltip: 'Retour',
              //     ),
              //   ],
              // ),
            ),

            // Loading Indicator
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.purple),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Chargement...',
                        style: TextStyle(fontSize: 16, color: Colors.purple),
                      ),
                    ],
                  ),
                ),
              ),

            // Error Message
            if (_error.isNotEmpty)
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[400]!, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error,
                        style: TextStyle(color: Colors.red[700], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

            // Success Message
            if (_success.isNotEmpty)
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green[400]!, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: Colors.green[700], size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _success,
                        style:
                            TextStyle(color: Colors.green[700], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

            // Tests List Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Tests Disponibles',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..shader = LinearGradient(
                      colors: [Colors.indigo[600]!, Colors.pink[600]!],
                    ).createShader(Rect.fromLTWH(0, 0, 200, 24)),
                ),
              ),
            ),

            // Tests List
            _tests.isEmpty && !_isLoading
                ? Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.sentiment_dissatisfied,
                          color: Colors.grey[400],
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aucun test trouvé',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: _tests.asMap().entries.map((entry) {
                      final index = entry.key;
                      final test = entry.value;
                      return FadeTransition(
                        opacity: _cardAnimation,
                        child: _buildTestCard(test, index),
                      );
                    }).toList(),
                  ),

            const SizedBox(height: 80), // Space for bottom navigation
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Paramètres'),
        ],
        currentIndex: 1,
        selectedItemColor: Colors.indigo[700],
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        elevation: 8,
        onTap: (index) {
          if (index == 0) context.go('/messages');
          if (index == 1) context.go('/home-eleve');
          if (index == 2) context.go('/settings');
        },
      ),
    );
  }

  Widget _buildTestCard(Test test, int index) {
    final submission = test.submission;
    final form = _submissionForms[test.id] ?? SubmissionForm(testId: test.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test Title
            Text(
              test.title,
              style: const TextStyle(
                fontSize: 18, // Optimized for 360px
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Test Details
            _buildDetailChip(
                'Leçon', test.lessonId?.title ?? 'N/A', Colors.blue[100]!),
            const SizedBox(height: 4),
            _buildDetailChip('Programme', test.programId?.title ?? 'N/A',
                Colors.purple[100]!),
            const SizedBox(height: 4),
            _buildDetailChip(
                'Unité', test.unitId?.title ?? 'N/A', Colors.pink[100]!),
            const SizedBox(height: 4),
            _buildDetailChip(
                'Contenu', test.content ?? 'Aucun contenu', Colors.green[100]!),
            const SizedBox(height: 12),

            // Media File Download
            if (test.mediaFile != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextButton.icon(
                  icon:
                      const Icon(Icons.download, color: Colors.blue, size: 20),
                  label: const Text(
                    'Télécharger le test',
                    style: TextStyle(color: Colors.blue, fontSize: 14),
                  ),
                  onPressed: () => _downloadFile(test.mediaFile!),
                ),
              ),

            // Submission Status
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: submission?.status == 'pending'
                    ? Colors.yellow[100]
                    : submission?.status == 'corrected'
                        ? Colors.green[100]
                        : submission?.status == 'submitted'
                            ? Colors.blue[100]
                            : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Statut: ${submission?.status ?? 'Non soumis'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: submission?.status == 'pending'
                      ? Colors.yellow[800]
                      : submission?.status == 'corrected'
                          ? Colors.green[800]
                          : submission?.status == 'submitted'
                              ? Colors.blue[800]
                              : Colors.grey[800],
                  fontSize: 13,
                ),
              ),
            ),

            // Submission File Download
            if (submission?.submittedFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: TextButton.icon(
                  icon: const Icon(Icons.download,
                      color: Colors.purple, size: 20),
                  label: const Text(
                    'Voir ma soumission',
                    style: TextStyle(color: Colors.purple, fontSize: 14),
                  ),
                  onPressed: () => _downloadFile(submission!.submittedFile!),
                ),
              ),

            // Feedback
            if (submission?.feedback != null)
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Feedback: ${submission!.feedback}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[700],
                    fontSize: 13,
                  ),
                ),
              ),

            // Correction File Download
            if (submission?.correctionFile != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextButton.icon(
                  icon:
                      const Icon(Icons.download, color: Colors.green, size: 20),
                  label: const Text(
                    'Télécharger la correction',
                    style: TextStyle(color: Colors.green, fontSize: 14),
                  ),
                  onPressed: () => _downloadFile(submission!.correctionFile!),
                ),
              ),

            // Submission Form
            if (submission == null || submission.status != 'corrected')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      submission != null
                          ? 'Modifier la soumission'
                          : 'Soumettre le test complété',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => _handleFileChange(test.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[50],
                        foregroundColor: Colors.blue[700],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.blue[200]!),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.upload, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Choisir un fichier',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    if (_submissionForms[test.id]?.submittedFile != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Fichier: ${_submissionForms[test.id]!.submittedFile!.name}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isSubmitting ||
                              _submissionForms[test.id]?.submittedFile == null
                          ? null
                          : () => _handleSubmit(test.id, submission?.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: _isSubmitting ||
                                _submissionForms[test.id]?.submittedFile == null
                            ? 0
                            : 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.upload, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _isSubmitting
                                ? 'Soumission en cours...'
                                : submission != null
                                    ? 'Mettre à jour'
                                    : 'Soumettre',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Delete Submission Button
            if (submission != null &&
                submission.id != null &&
                submission.status != 'corrected')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _handleDeleteSubmission(submission.id!, test.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[500],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: _isSubmitting ? 0 : 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.delete, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Supprimer la soumission',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label, String value, Color backgroundColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: backgroundColor == Colors.blue[100]
                  ? Colors.blue[800]
                  : backgroundColor == Colors.purple[100]
                      ? Colors.purple[800]
                      : backgroundColor == Colors.pink[100]
                          ? Colors.pink[800]
                          : Colors.green[800],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// Data models
class Test {
  final String id;
  final String title;
  final LessonId? lessonId;
  final ProgramId? programId;
  final UnitId? unitId;
  final String? content;
  final String? mediaFile;
  final Submission? submission;

  Test({
    required this.id,
    required this.title,
    this.lessonId,
    this.programId,
    this.unitId,
    this.content,
    this.mediaFile,
    this.submission,
  });

  factory Test.fromJson(Map<String, dynamic> json) {
    return Test(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'Test sans titre',
      lessonId:
          json['lessonId'] != null ? LessonId.fromJson(json['lessonId']) : null,
      programId: json['programId'] != null
          ? ProgramId.fromJson(json['programId'])
          : null,
      unitId: json['unitId'] != null ? UnitId.fromJson(json['unitId']) : null,
      content: json['content'],
      mediaFile: json['mediaFile'],
      submission: json['submission'] != null
          ? Submission.fromJson(json['submission'])
          : null,
    );
  }
}

class LessonId {
  final String title;

  LessonId({required this.title});

  factory LessonId.fromJson(Map<String, dynamic> json) {
    return LessonId(title: json['title'] ?? 'N/A');
  }
}

class ProgramId {
  final String title;

  ProgramId({required this.title});

  factory ProgramId.fromJson(Map<String, dynamic> json) {
    return ProgramId(title: json['title'] ?? 'N/A');
  }
}

class UnitId {
  final String title;

  UnitId({required this.title});

  factory UnitId.fromJson(Map<String, dynamic> json) {
    return UnitId(title: json['title'] ?? 'N/A');
  }
}

class Submission {
  final String? id; // Changed from _id to id
  final String? status;
  final String? submittedFile;
  final String? feedback;
  final String? correctionFile;

  Submission({
    this.id, // Changed from this.id to this.id
    this.status,
    this.submittedFile,
    this.feedback,
    this.correctionFile,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json[
          '_id'], // Keep this as json['_id'] since that's the JSON field name
      status: json['status'],
      submittedFile: json['submittedFile'],
      feedback: json['feedback'],
      correctionFile: json['correctionFile'],
    );
  }
}

class SubmissionForm {
  final String testId;
  final PlatformFile? submittedFile;
  final String submissionId;
  final bool isEditing;

  SubmissionForm({
    required this.testId,
    this.submittedFile,
    this.submissionId = '',
    this.isEditing = false,
  });
}
