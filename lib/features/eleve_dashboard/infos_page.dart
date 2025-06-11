import 'package:flutter/material.dart';

class InfosPage extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const InfosPage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Logo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/logo1.png',
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'À propos de karaScolaire',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'KaraLearn - Une plateforme éducative innovante pour les élèves, parents et enseignants.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                ],
              ),
            ),
            // About Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Libérer le potentiel, un élève à la fois',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'karaScolaire est une plateforme éducative innovante conçue pour offrir un apprentissage personnalisé à chaque élève. Nos outils interactifs et multimédias créent une expérience d’apprentissage engageante et dynamique, permettant aux élèves de progresser à leur propre rythme, de renforcer leur autonomie et d’améliorer leur mémorisation des informations.',
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Accréditation karaScolaire',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'karaScolaire est une plateforme reconnue pour son engagement envers l’excellence éducative, offrant des ressources de qualité et une approche pédagogique validée par des professionnels de l’éducation.',
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement navigation to quote page or form
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'Obtenir un devis',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            // Purpose Section: Focus on French Learning
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              color: Colors.blue[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Le chemin vers la réussite passe par l’apprentissage du français',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Chez karaScolaire, nous croyons que la maîtrise du français ouvre les portes de la réussite. Notre plateforme éducative intuitive permet aux élèves d’apprendre le français de manière ludique et personnalisée. Guidés par Karama Mighri, Professeur des Écoles Primaires, les élèves bénéficient d’un accompagnement sur mesure qui transforme l’apprentissage en une expérience motivante et enrichissante. Que ce soit à travers des activités interactives, des leçons multimédias ou des exercices adaptés, karaScolaire rend l’apprentissage du français accessible, engageant et efficace pour tous.',
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      // TODO: Implement navigation to learn more page
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'En savoir plus',
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            // Contact Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contactez-nous',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Dirigé par Karama Mighri, Professeur des Écoles Primaires',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Adresse: 3114 Menzel Mhiri, Kairouan, Tunisie',
                    style: TextStyle(fontSize: 16),
                  ),
                  const Text(
                    'Email: karamamighry@gmail.com',
                    style: TextStyle(fontSize: 16),
                  ),
                  const Text(
                    'Téléphone: +216 56 255 380',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: const Text(
                '© karaScolaire 2025 | Tous droits réservés',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
