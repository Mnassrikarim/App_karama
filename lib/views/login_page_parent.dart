import 'package:edu_karama_app/cors/constants.dart';
import 'package:edu_karama_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPageParent extends StatelessWidget {
  const LoginPageParent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: AppDefaults.padding * 2),
              const _AppLogoAndHeadline(),
              const SizedBox(height: AppDefaults.margin),
              const _LoginForm(),
              const SizedBox(height: AppDefaults.margin),
              const _Footer(),
              const SizedBox(height: AppDefaults.padding),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppLogoAndHeadline extends StatelessWidget {
  const _AppLogoAndHeadline();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.44,
          child: AspectRatio(
            aspectRatio: 1 / 1,
            child: Image.asset(
              AppImages.logo,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.image_not_supported,
                size: 100,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDefaults.padding),
      ],
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;
  bool _rememberMe = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();
      final result = await apiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (result['role'] != 'parent') {
        throw Exception('Vous devez utiliser la connexion élève.');
      }

      if (mounted) {
        context.go('/home-parent', extra: {
          'role': result['role'],
          'nom': result['nom'],
          'prenom': result['prenom'],
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[900]!, Color.fromARGB(255, 247, 231, 112)!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDefaults.padding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Connexion Parent',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: AppDefaults.margin),
                Text(
                  'Bienvenue cher parent !',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: AppDefaults.margin * 2),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Email ici',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.email, color: Colors.grey),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppDefaults.margin),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    hintText: 'Mot de passe ici',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                  ),
                  obscureText: true,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppDefaults.margin),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: AppDefaults.margin),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            activeColor: Colors.blue[900],
                          ),
                          const Text(
                            'Se souvenir de moi',
                            style: TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255),
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () => context.go('/reset-password'),
                        child: const Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(
                            color: Color.fromARGB(255, 6, 73, 128),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDefaults.margin),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Connexion',
                            style: TextStyle(color: Colors.white),
                          ),
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

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () => context.go('/signup-parent'),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Pas encore de compte ? ',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                TextSpan(
                  text: 'Inscrivez-vous !',
                  style: TextStyle(
                    color: Colors.blue[900],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDefaults.margin),
        TextButton(
          onPressed: () => context.go('/intro'),
          child: Text(
            'Retour',
            style: TextStyle(
              color: Colors.blue[900],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
