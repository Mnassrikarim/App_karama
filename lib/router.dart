import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../views/home_page.dart';
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
        builder: (BuildContext context, GoRouterState state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/intro',
        builder: (BuildContext context, GoRouterState state) => const IntroPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (BuildContext context, GoRouterState state) => const HomePage(),
      ),
      GoRoute(
        path: '/login-eleve',
        builder: (BuildContext context, GoRouterState state) => const LoginPageEleve(),
      ),
      GoRoute(
        path: '/login-parent',
        builder: (BuildContext context, GoRouterState state) => const LoginPageParent(),
      ),
      GoRoute(
        path: '/signup-eleve',
        builder: (BuildContext context, GoRouterState state) => const SignupPageEleve(),
      ),
      GoRoute(
        path: '/signup-parent',
        builder: (BuildContext context, GoRouterState state) => const SignupPageParent(),
      ),
    ],
  );
}