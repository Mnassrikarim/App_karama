import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

class VocabulaireDetailsPage extends StatefulWidget {
  final String categoryId;
  final Map<String, dynamic>? userData;

  const VocabulaireDetailsPage({
    super.key,
    required this.categoryId,
    required this.userData,
  });

  @override
  State<VocabulaireDetailsPage> createState() => _VocabulaireDetailsPageState();
}

class _VocabulaireDetailsPageState extends State<VocabulaireDetailsPage> {
  final _storage = const FlutterSecureStorage();
  List<VocabItem> _vocabItems = [];
  List<VocabItem> _filteredVocabItems = [];
  String _categoryName = '';
  String _error = '';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _categoryName = widget.userData?['categoryName'] ?? 'Catégorie';
    print('Initialized with categoryName: $_categoryName');
    print('Initialized with categoryId: ${widget.categoryId}');
    print('Initialized with userData: ${widget.userData}');
    _fetchVocabItems();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchVocabItems() async {
    // if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final token = await _storage.read(key: 'jwt_token');
    print('Token in VocabulaireDetailsPage before fetch: $token');

    // if (token == null) {
    //   context.go('/login-eleve');
    //   return;
    // }

    try {
      final response = await http.get(
        Uri.parse(
            'https://kara-back.onrender.com/api/student/vocab?categorieId=${widget.categoryId}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      // print('Fetching vocab from URL: $url');

      // final response = await http.get(
      //   Uri.parse(url),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Content-Type': 'application/json',
      //   },
      // );

      print('Vocab API response status: ${response.statusCode}');
      print('Vocab API response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Successfully decoded ${data.length} vocab items');

        if (mounted) {
          setState(() {
            _vocabItems = data.map((json) => VocabItem.fromJson(json)).toList();
            _filteredVocabItems = List.from(_vocabItems);
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        print('Token invalid, clearing storage');
        await _storage.delete(key: 'jwt_token');
        if (mounted) {
          setState(() {
            _error = 'Authentification requise.';
            _isLoading = false;
          });
          await Future.delayed(const Duration(seconds: 2));
          // context.go('/login-eleve');
        }
      } else {
        print('API error: ${response.statusCode} - ${response.body}');
        if (mounted) {
          setState(() {
            _error = 'Erreur lors du chargement: ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Exception in _fetchVocabItems: $e');
      if (mounted) {
        setState(() {
          _error = 'Erreur réseau: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _handleSearch(String query) {
    if (!mounted) return;
    setState(() {
      if (query.isEmpty) {
        _filteredVocabItems = List.from(_vocabItems);
      } else {
        _filteredVocabItems = _vocabItems
            .where(
                (item) => item.mot.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _playAudio(String? audioUrl) async {
    if (!mounted || audioUrl == null || audioUrl.isEmpty) return;

    try {
      final fullUrl = 'https://kara-back.onrender.com/uploads/$audioUrl';
      print('Playing audio from: $fullUrl');
      await _audioPlayer.setUrl(fullUrl);
      await _audioPlayer.play();
    } catch (e) {
      print('Audio playback error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de lecture audio: $e')),
        );
      }
    }
  }

  // void _navigateBack() {
  //   if (mounted) context.go('/vocabulaire');
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ElevatedButton.icon(
                //   onPressed: () => context.go('/vocabulaire'),
                //   icon: const Icon(Icons.arrow_back, size: 20),
                //   label: const Text('Retour', style: TextStyle(fontSize: 14)),
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.blue,
                //     foregroundColor: Colors.white,
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //     padding:
                //         const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                //   ),
                // ),
                Expanded(
                  child: Text(
                    'Vocabulaire - $_categoryName',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 100),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _handleSearch,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                hintText: 'Rechercher un mot...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
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
              child: Text(
                _error,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVocabItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _vocabItems.isEmpty
                                  ? 'Aucun mot disponible dans cette catégorie.'
                                  : 'Aucun mot trouvé pour votre recherche.',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _filteredVocabItems.length,
                        itemBuilder: (context, index) {
                          final vocab = _filteredVocabItems[index];
                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => _playAudio(vocab.audioUrl),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          'https://kara-back.onrender.com/uploads/${vocab.imageUrl ?? 'placeholder.png'}',
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.broken_image,
                                              size: 40,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        vocab.mot,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (vocab.audioUrl != null &&
                                        vocab.audioUrl!.isNotEmpty)
                                      Icon(
                                        Icons.volume_up,
                                        color: Colors.purple[400],
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// Data models
class Category {
  final String _id;
  final String nom;
  final String? imageUrl;
  final String? audioUrl;

  Category({
    required String id,
    required this.nom,
    this.imageUrl,
    this.audioUrl,
  }) : _id = id;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? '',
      nom: json['nom'] ?? 'Catégorie sans nom',
      imageUrl: json['imageUrl'],
      audioUrl: json['audioUrl'],
    );
  }
}

class VocabItem {
  final String _id;
  final String mot;
  final String? imageUrl;
  final String? audioUrl;
  final Map<String, dynamic>? categorieId;

  VocabItem({
    required String id,
    required this.mot,
    this.imageUrl,
    this.audioUrl,
    this.categorieId,
  }) : _id = id;

  factory VocabItem.fromJson(Map<String, dynamic> json) {
    return VocabItem(
      id: json['_id'] ?? '',
      mot: json['mot'] ?? 'Mot inconnu',
      imageUrl: json['imageUrl'],
      audioUrl: json['audioUrl'],
      categorieId: json['categorieId'],
    );
  }
}
