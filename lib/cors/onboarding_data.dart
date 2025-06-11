import 'onboarding_model.dart';

class OnboardingData {
  static final List<OnboardingModel> items = [
    OnboardingModel(
      imageUrl: 'assets/images/gif/out.gif',
      headline: 'Bienvenue dans notre application !',
      description:
          'Une plateforme amusante pour les enfants et les parents afin de suivre les cours et l’apprentissage scolaire.',
    ),
    OnboardingModel(
      imageUrl: 'assets/images/gif/fff2.gif',
      headline: 'Apprentissage interactif',
      description:
          'Découvrez des cours, tests et quiz conçus pour rendre l’apprentissage scolaire passionnant.',
    ),
    OnboardingModel(
      imageUrl: 'assets/images/gif/hhh2.gif',
      headline: 'Commencez maintenant !',
      description:
          'Rejoignez-nous pour gérer les cours et suivre les progrès de vos enfants dès aujourd’hui !',
    ),
  ];
}
