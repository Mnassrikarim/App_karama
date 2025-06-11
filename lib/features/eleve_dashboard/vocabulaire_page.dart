import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:mime/mime.dart';

class VocabulairePage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const VocabulairePage({super.key, required this.userData});

  @override
  State<VocabulairePage> createState() => _VocabulairePageState();
}

class _VocabulairePageState extends State<VocabulairePage> {
  final _storage = const FlutterSecureStorage();
  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  String _searchQuery = '';
  String _error = '';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    final token = await _storage.read(key: 'jwt_token');
    print('Token in VocabulairePage: $token'); // Debug token

    if (token == null) {
      print('No token found, redirecting to login');
      // if (mounted) context.go('/login-eleve'); // Uncomment if redirect is desired
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://kara-back.onrender.com/api/student/categories'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Categories API response status: ${response.statusCode}');
      print('Categories API response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _categories = data.map((json) => Category.fromJson(json)).toList();
          _filteredCategories = _categories;
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        print('Token expired, clearing storage and redirecting');
        await _storage.delete(key: 'jwt_token');
        // if (mounted) context.go('/login-eleve'); // Uncomment if redirect is desired
      } else {
        setState(() {
          _error =
              'Erreur lors du chargement des catégories: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() {
        _error = 'Erreur lors du chargement des catégories: $e';
        _isLoading = false;
      });
    }
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      _filteredCategories = _categories
          .where((category) =>
              category.nom.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _navigateToDetails(String categoryId, String categoryName) {
    print(
        'Navigating to /vocabulaire-details/$categoryId with categoryName: $categoryName'); // Debug navigation
    final navigationData = {
      'categoryName': categoryName,
      ...?widget.userData, // Spread existing userData if it exists
    };
    context.push('/vocabulaire-details/$categoryId', extra: navigationData);
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
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/home-eleve'),
                    icon: const Icon(Icons.arrow_back, size: 20),
                    label: const Text('Retour', style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      foregroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
                Text(
                  'Le Vocabulaire',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _handleSearch,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                hintText: 'Rechercher une catégorie...',
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
          const SizedBox(height: 16),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredCategories.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Aucune catégorie trouvée.',
                        style: TextStyle(
                            color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shrinkWrap:
                          true, // Allows the GridView to size to its content
                      physics:
                          const NeverScrollableScrollPhysics(), // Disable internal scrolling
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1, // Stack cards vertically
                        childAspectRatio:
                            2.5, // Adjust height relative to width
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _filteredCategories.length,
                      itemBuilder: (context, index) {
                        final category = _filteredCategories[index];
                        print('Rendering category: ${category.nom}');
                        return GestureDetector(
                          onTap: () =>
                              _navigateToDetails(category._id, category.nom),
                          child: Card(
                            elevation: 8, // Shadow effect
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    'https://kara-back.onrender.com/uploads/${category.imageUrl}',
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(color: Colors.grey[300]),
                                  ),
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
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          category.nom,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 20,
                                          ),
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Clique pour explorer',
                                          style: TextStyle(
                                            color: Colors.purple,
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          textAlign: TextAlign.end,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// Data model for categories
class Category {
  final String _id;
  final String nom;
  final String? imageUrl;
  final String? audioUrl;

  Category(
      {required String id, required this.nom, this.imageUrl, this.audioUrl})
      : _id = id;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? '',
      nom: json['nom'] ?? 'Catégorie sans nom',
      imageUrl: json['imageUrl'],
      audioUrl: json['audioUrl'],
    );
  }
}
