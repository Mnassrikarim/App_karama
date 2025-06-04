import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://karama-backend.onrender.com/api';
  static const storage = FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await storage.write(key: 'jwt_token', value: data['token']);
      await storage.write(key: 'user_role', value: data['role']);
      await storage.write(key: 'user_nom', value: data['nom']);
      await storage.write(key: 'user_prenom', value: data['prenom']);
      return {
        'token': data['token'],
        'role': data['role'],
        'nom': data['nom'],
        'prenom': data['prenom'],
      };
    } else {
      final error =
          jsonDecode(response.body)['message'] ?? 'Erreur de connexion';
      throw Exception(error);
    }
  }

  Future<String> register({
    required String email,
    required String password,
    required String role,
    required String nom,
    required String prenom,
    String? numInscript,
    String? niveau,
    String? numTell,
  }) async {
    final body = {
      'email': email,
      'password': password,
      'role': role,
      'nom': nom,
      'prenom': prenom,
      if (numInscript != null) 'numInscript': numInscript,
      if (niveau != null) 'niveau': niveau,
      if (numTell != null) 'numTell': numTell,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['message'];
    } else {
      final error =
          jsonDecode(response.body)['message'] ?? 'Erreur d\'inscription';
      throw Exception(error);
    }
  }

  Future<String?> getToken() async {
    return await storage.read(key: 'jwt_token');
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final role = await storage.read(key: 'user_role');
    final nom = await storage.read(key: 'user_nom');
    final prenom = await storage.read(key: 'user_prenom');
    if (role != null && nom != null && prenom != null) {
      return {
        'role': role,
        'nom': nom,
        'prenom': prenom,
      };
    }
    return null;
  }
}
