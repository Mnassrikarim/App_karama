import 'dart:convert';
import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:edu_karama_app/features/eleve_dashboard/score_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

class JeuxPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const JeuxPage({super.key, required this.userData});

  @override
  State<JeuxPage> createState() => _JeuxPageState();
}

class _JeuxPageState extends State<JeuxPage> {
  final _storage = const FlutterSecureStorage();
  final _picker = ImagePicker();
  List<Section> _sections = [];
  List<Game> _games = [];
  String? _selectedSection;
  Game? _selectedGame;
  XFile? _screenshot;
  String _error = '';
  String _success = '';
  bool _isLoading = true;
  List<Score> _scores = [];

  @override
  void initState() {
    super.initState();
    _fetchSections();
  }

  Future<void> _fetchSections() async {
    setState(() => _isLoading = true);
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      context.go('/login-eleve');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://kara-back.onrender.com/api/student/game/sections'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _sections = data.map((json) => Section.fromJson(json)).toList();
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        await _storage.delete(key: 'jwt_token');
        context.go('/login-eleve');
      } else {
        setState(() {
          _error = jsonDecode(response.body)['message'] ??
              'Erreur lors du chargement des sections';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des sections: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchGames(String sectionId) async {
    setState(() => _isLoading = true);
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      context.go('/login-eleve');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://kara-back.onrender.com/api/student/games/section/$sectionId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _games = data.map((json) => Game.fromJson(json)).toList();
          _error = '';
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        await _storage.delete(key: 'jwt_token');
        context.go('/login-eleve');
      } else {
        setState(() {
          _error = jsonDecode(response.body)['message'] ??
              'Erreur lors du chargement des jeux';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des jeux: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchScores(String gameId) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      context.go('/login-eleve');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://kara-back.onrender.com/api/student/scores/user')
            .replace(queryParameters: {'gameId': gameId}),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _scores = data.map((json) => Score.fromJson(json)).toList();
          _error = '';
        });
      } else if (response.statusCode == 401) {
        await _storage.delete(key: 'jwt_token');
        context.go('/login-eleve');
      } else {
        setState(() {
          _error = jsonDecode(response.body)['message'] ??
              'Erreur lors du chargement des scores';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des scores: $e';
      });
    }
  }

  Future<void> _uploadScreenshot() async {
    if (_screenshot == null || _selectedGame == null) {
      setState(() {
        _error = 'Veuillez sélectionner une capture d’écran et un jeu';
      });
      return;
    }

    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      context.go('/login-eleve');
      return;
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://kara-back.onrender.com/api/student/game/score'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['gameId'] = _selectedGame!._id;

      if (kIsWeb) {
        final bytes = await _screenshot!.readAsBytes();
        final mimeType =
            lookupMimeType(_screenshot!.name) ?? 'application/octet-stream';
        final mediaType = MediaType.parse(mimeType);
        request.files.add(http.MultipartFile.fromBytes(
          'screenshot',
          bytes,
          filename: _screenshot!.name,
          contentType: mediaType,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'screenshot',
          _screenshot!.path,
        ));
      }

      // Debug logging
      print('Request fields: ${request.fields}');
      print(
          'Request files: ${request.files.length} files, names: ${request.files.map((f) => f.filename)}');

      int retryCount = 0;
      const maxRetries = 3;
      while (retryCount < maxRetries) {
        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        if (response.statusCode == 200 || response.statusCode == 201) {
          setState(() {
            _screenshot = null;
            _selectedGame = null;
            _success = 'Capture de score soumise avec succès';
            _error = '';
          });
          // Refresh scores after successful upload
          if (_selectedGame != null) {
            await _fetchScores(_selectedGame!._id);
          }
          break;
        } else if (response.statusCode == 401) {
          await _storage.delete(key: 'jwt_token');
          context.go('/login-eleve');
          break;
        } else {
          setState(() {
            _error =
                'Erreur lors de l’envoi de la capture: ${jsonDecode(responseBody)['error'] ?? response.statusCode}';
          });
          if (response.statusCode == 400 && retryCount < maxRetries - 1) {
            await Future.delayed(Duration(seconds: 1)); // Wait before retry
            retryCount++;
            continue;
          }
          break;
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de l’envoi de la capture: $e';
      });
    }
  }

  void _handleSectionClick(String sectionId) {
    setState(() {
      _selectedSection = sectionId;
      _selectedGame = null;
      _screenshot = null;
      _error = '';
    });
    _fetchGames(sectionId);
  }

  void _handlePlayGame(Game game) {
    launchUrl(
      Uri.parse(game.url),
      mode: LaunchMode.externalApplication,
    );
    setState(() {
      _selectedGame = game;
      _screenshot = null;
      _scores = []; // Reset scores before fetching
    });
    _fetchScores(game._id);
  }

  Widget _buildSections() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choisis une catégorie :',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 12),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _sections.isEmpty
                  ? const Text(
                      'Aucune catégorie disponible.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : CarouselSlider(
                      options: CarouselOptions(
                        height: 120,
                        viewportFraction: 0.9, // 90% of page width
                        enableInfiniteScroll: _sections.length > 1,
                        autoPlay: false, // Set to true if you want auto-play
                        enlargeCenterPage: true,
                        enlargeFactor: 0.1,
                        scrollDirection: Axis.horizontal,
                      ),
                      items: _sections.map((section) {
                        return Builder(
                          builder: (BuildContext context) {
                            return GestureDetector(
                              onTap: () => _handleSectionClick(section._id),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 5.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.3),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        // Background image
                                        Image.network(
                                          'https://kara-back.onrender.com${section.image}',
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                                      color: Colors.grey[300]),
                                        ),
                                        // Overlay for text readability
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.black.withOpacity(0.4),
                                                Colors.black.withOpacity(0.1),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Content
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              if (section.image != null)
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                  ),
                                                  child: Image.network(
                                                    'https://kara-back.onrender.com${section.image}',
                                                    width: 40,
                                                    height: 40,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                            error,
                                                            stackTrace) =>
                                                        const Icon(
                                                            Icons.broken_image),
                                                  ),
                                                ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  section.name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: _selectedSection ==
                                                            section._id
                                                        ? Colors.yellow
                                                        : Colors.white,
                                                    fontSize: 16,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
        ],
      ),
    );
  }

  Widget _buildGames() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choisis ton jeu :',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 12),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _games.isEmpty
                  ? const Text(
                      'Aucun jeu disponible.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 300,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _games.length,
                      itemBuilder: (context, index) {
                        final game = _games[index];
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                  child: Image.network(
                                    'https://kara-back.onrender.com${game.image}',
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.broken_image,
                                                size: 48),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      game.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () => _handlePlayGame(game),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.pink,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Jouer'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }

  Widget _buildScreenshotUpload() {
    if (_selectedGame == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Soumettre une capture d’écran pour ${_selectedGame!.name}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              GestureDetector(
                onTap: () async {
                  final pickedFile = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  setState(() {
                    _screenshot = pickedFile;
                    _error = '';
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.blue.shade400,
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.upload_file, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        _screenshot != null
                            ? _screenshot!.name
                            : 'Choisir une image',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _uploadScreenshot,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(double.infinity, 48), // Full width
                ),
                child: const Text('Soumettre'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScores() {
    if (_selectedGame == null || _scores.isEmpty)
      return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.purple, Colors.pink],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mes scores pour ${_selectedGame!.name}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 600),
              child: DataTable(
                columnSpacing: 16,
                columns: const [
                  DataColumn(
                    label: Text('Capture d’écran',
                        style: TextStyle(color: Colors.white)),
                  ),
                  DataColumn(
                    label: Text('Date', style: TextStyle(color: Colors.white)),
                  ),
                  DataColumn(
                    label:
                        Text('Statut', style: TextStyle(color: Colors.white)),
                  ),
                ],
                rows: _scores.map((score) {
                  return DataRow(cells: [
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
                          errorBuilder: (context, error, stackTrace) =>
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
                        style: const TextStyle(color: Colors.white),
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
                        child: Text(
                          score.reviewed ? 'Revu ✓' : 'En attente...',
                          style: TextStyle(
                            color:
                                score.reviewed ? Colors.green : Colors.yellow,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ElevatedButton.icon(
                //   onPressed: () => context.go('/home-eleve'),
                //   icon: const Icon(Icons.arrow_back),
                //   label: const Text('Retour'),
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.yellow,
                //     foregroundColor: Colors.purple,
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //   ),
                // ),
                Text(
                  'Jeux Éducatifs',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                ElevatedButton(
                  onPressed: () => context.go('/scores'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Voir mes scores'),
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
          if (_success.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  Text(_success, style: const TextStyle(color: Colors.green)),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 1, child: _buildSections()),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildGames(),
                          _buildScreenshotUpload(),
                          _buildScores(),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildSections(),
                    _buildGames(),
                    _buildScreenshotUpload(),
                    _buildScores(),
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
class Section {
  final String _id;
  final String name;
  final String? image;

  Section({required String id, required this.name, this.image}) : _id = id;

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Section sans nom',
      image: json['image'],
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
