import 'package:edu_karama_app/cors/constants.dart';
import 'package:edu_karama_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPageEleve extends StatelessWidget {
  const LoginPageEleve({super.key});

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
          width: MediaQuery.of(context).size.width * 0.3,
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
        Text(
          'Connexion Élève',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
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

      if (result['role'] != 'eleve') {
        throw Exception('Vous devez utiliser la connexion parent.');
      }

      if (mounted) {
        // Navigate to home page with user data
        context.go('/home', extra: {
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDefaults.padding),
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppDefaults.margin),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Connexion'),
            ),
          ),
        ],
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
          onPressed: () => context.go('/signup-eleve'),
          child: const Text(
            'Vous pouvez créer un compte',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
