import 'package:edu_karama_app/features/eleve_dashboard/conversation_page.dart';
import 'package:edu_karama_app/features/eleve_dashboard/cours_page.dart';
import 'package:edu_karama_app/features/eleve_dashboard/eleve_dashboard.dart';
import 'package:edu_karama_app/features/eleve_dashboard/infos_page.dart';
import 'package:edu_karama_app/features/eleve_dashboard/jeux_page.dart';
import 'package:edu_karama_app/features/eleve_dashboard/messages_page.dart';
import 'package:edu_karama_app/features/eleve_dashboard/notif_page.dart';
import 'package:edu_karama_app/features/eleve_dashboard/quizz_page.dart';
import 'package:edu_karama_app/features/eleve_dashboard/quizz_player_page.dart';
import 'package:edu_karama_app/features/eleve_dashboard/resultats_page.dart';
import 'package:edu_karama_app/features/eleve_dashboard/score_page.dart';
import 'package:edu_karama_app/features/eleve_dashboard/settings_page.dart';
import 'package:edu_karama_app/features/eleve_dashboard/tests_page.dart';
import 'package:edu_karama_app/features/eleve_dashboard/vocabulaire_details_page.dart';
import 'package:edu_karama_app/features/eleve_dashboard/vocabulaire_page.dart';
import 'package:edu_karama_app/features/parent_dashboard/parent_dashboard.dart';

import 'package:edu_karama_app/features/parent_dashboard/home_pagepp.dart';
import 'package:edu_karama_app/features/parent_dashboard/progres_page.dart';
import 'package:edu_karama_app/views/reset-password.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/eleve_dashboard/home_page_ee.dart';
import '../views/intro_page.dart';
import '../views/login_page_eleve.dart';
import '../views/login_page_parent.dart';
import '../views/onboarding_page.dart';
import '../views/signup_page_eleve.dart';
import '../views/signup_page_parent.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (BuildContext context, GoRouterState state) =>
            const OnboardingPage(),
      ),
      GoRoute(
        path: '/intro',
        builder: (BuildContext context, GoRouterState state) =>
            const IntroPage(),
      ),
      GoRoute(
        path: '/home-eleve',
        builder: (context, state) => EleveDashboard(
          body: HomePageEleve(userData: state.extra as Map<String, dynamic>?),
          title: 'Accueil',
          activePage: 'accueil',
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => EleveDashboard(
          body:
              NotificationsPage(userData: state.extra as Map<String, dynamic>?),
          title: 'Notifications',
          activePage: 'notifications',
        ),
      ),
      GoRoute(
        path: '/cours',
        builder: (context, state) => EleveDashboard(
          body: CoursPage(userData: state.extra as Map<String, dynamic>?),
          title: 'Cours',
          activePage: 'cours',
        ),
      ),
      GoRoute(
        path: '/tests',
        builder: (context, state) => EleveDashboard(
          body: TestsPage(userData: state.extra as Map<String, dynamic>?),
          title: 'Tests',
          activePage: 'tests',
        ),
      ),
      GoRoute(
        path: '/vocabulaire',
        builder: (context, state) => EleveDashboard(
          body: VocabulairePage(userData: state.extra as Map<String, dynamic>?),
          title: 'Le Vocabulaire',
          activePage: 'vocabulaire',
        ),
      ),
      GoRoute(
        path: '/vocabulaire-details/:categoryId',
        builder: (context, state) => EleveDashboard(
          body: VocabulaireDetailsPage(
            categoryId: state.pathParameters['categoryId']!,
            userData: state.extra as Map<String, dynamic>?,
          ),
          title: 'Vocabulaire - ${state.pathParameters['categoryId']}',
          activePage: 'vocabulaire',
        ),
      ),
      GoRoute(
        path: '/quizz',
        builder: (context, state) => EleveDashboard(
          body: QuizzPage(userData: state.extra as Map<String, dynamic>?),
          title: 'Le Quizz',
          activePage: 'quizz',
        ),
      ),
      GoRoute(
        path: '/quiz/:quizId',
        builder: (context, state) => EleveDashboard(
          body: QuizPlayerPage(
            userData: state.extra as Map<String, dynamic>?,
            quizId: state.pathParameters['quizId']!,
          ),
          title: 'Passer un Quiz',
          activePage: 'quizz',
        ),
      ),
      GoRoute(
        path: '/resultats',
        builder: (context, state) => EleveDashboard(
          body: ResultatsPage(userData: state.extra as Map<String, dynamic>?),
          title: 'Les Résultats',
          activePage: 'resultats',
        ),
      ),
      GoRoute(
        path: '/jeux',
        builder: (context, state) => EleveDashboard(
          body: JeuxPage(userData: state.extra as Map<String, dynamic>?),
          title: 'Les Jeux',
          activePage: 'jeux',
        ),
      ),
      GoRoute(
        path: '/scores',
        builder: (context, state) => EleveDashboard(
          body: ScorePage(userData: state.extra as Map<String, dynamic>?),
          title: 'Mes Scores',
          activePage: '',
        ),
      ),
      GoRoute(
        path: '/messages',
        builder: (context, state) => EleveDashboard(
          body: MessagesPage(userData: state.extra as Map<String, dynamic>?),
          title: 'Messages',
          activePage: 'messages',
        ),
      ),
      GoRoute(
        path: '/infos',
        builder: (context, state) => EleveDashboard(
          body: InfosPage(userData: state.extra as Map<String, dynamic>?),
          title: 'Infos',
          activePage: 'infos',
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => EleveDashboard(
          body: SettingsPage(userData: state.extra as Map<String, dynamic>?),
          title: 'Settings',
          activePage: 'settings',
        ),
      ),
      GoRoute(
        path: '/conversation/:id',
        builder: (context, state) => ConversationPage(
          userData: state.extra as Map<String, dynamic>?,
          id: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/home-parent',
        builder: (context, state) => ParentDashboard(
          body: HomePageParent(userData: state.extra as Map<String, dynamic>?),
          title: 'Accueil',
          activePage: 'accueil',
        ),
      ),
      GoRoute(
        path: '/progres',
        builder: (context, state) => ParentDashboard(
          body: ProgresPage(userData: state.extra as Map<String, dynamic>?),
          title: 'Progrès',
          activePage: 'progres',
        ),
      ),
      GoRoute(
        path: '/notifications-parent',
        builder: (context, state) => ParentDashboard(
          body:
              NotificationsPage(userData: state.extra as Map<String, dynamic>?),
          title: 'Notifications',
          activePage: 'notifications',
        ),
      ),
      GoRoute(
        path: '/messages-parent',
        builder: (context, state) => ParentDashboard(
          body: MessagesPage(userData: state.extra as Map<String, dynamic>?),
          title: 'Messages',
          activePage: 'messages',
        ),
      ),
      GoRoute(
        path: '/infos-parent',
        builder: (context, state) => ParentDashboard(
          body: InfosPage(userData: state.extra as Map<String, dynamic>?),
          title: 'Infos',
          activePage: 'infos',
        ),
      ),
      GoRoute(
        path: '/login-eleve',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginPageEleve(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (BuildContext context, GoRouterState state) =>
            const ResetPasswordPage(),
      ),
      GoRoute(
        path: '/login-parent',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginPageParent(),
      ),
      GoRoute(
        path: '/signup-eleve',
        builder: (BuildContext context, GoRouterState state) =>
            const SignupPageEleve(),
      ),
      GoRoute(
        path: '/signup-parent',
        builder: (BuildContext context, GoRouterState state) =>
            const SignupPageParent(),
      ),
    ],
  );
}
