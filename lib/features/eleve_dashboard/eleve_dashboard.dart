import 'package:animated_icon/animated_icon.dart'; // Import animated_icon
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math; // For Random (though not used now)
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:edu_karama_app/services/api_service.dart';
import 'package:edu_karama_app/features/eleve_dashboard/widgets/sidebar_menu.dart';

class EleveDashboard extends StatefulWidget {
  final Widget body;
  final String title;
  final String activePage;

  const EleveDashboard({
    super.key,
    required this.body,
    required this.title,
    required this.activePage,
  });

  @override
  _EleveDashboardState createState() => _EleveDashboardState();
}

class _EleveDashboardState extends State<EleveDashboard>
    with TickerProviderStateMixin {
  late AnimationController _hideBottomBarAnimationController;
  final autoSizeGroup = AutoSizeGroup();
  late int _bottomNavIndex;

  @override
  void initState() {
    super.initState();
    _bottomNavIndex = _getBottomNavIndex(widget.activePage);

    _hideBottomBarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(EleveDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activePage != widget.activePage) {
      setState(() {
        _bottomNavIndex = _getBottomNavIndex(widget.activePage);
      });
    }
  }

  @override
  void dispose() {
    _hideBottomBarAnimationController.dispose();
    super.dispose();
  }

  bool onScrollNotification(ScrollNotification notification) {
    if (notification is UserScrollNotification &&
        notification.metrics.axis == Axis.vertical) {
      if (notification.direction == ScrollDirection.forward) {
        _hideBottomBarAnimationController.reverse();
      } else if (notification.direction == ScrollDirection.reverse) {
        _hideBottomBarAnimationController.forward();
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    final Map<String, dynamic>? userDataFromRoute =
        extra is Map<String, dynamic> ? extra : null;

    return FutureBuilder<Map<String, dynamic>?>(
      future: userDataFromRoute != null
          ? Future.value(userDataFromRoute)
          : ApiService().getUserData(),
      builder: (context, snapshot) {
        final userData = snapshot.data;

        if (userData != null && userData['role'] != 'eleve') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login-eleve');
          });
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          extendBody: true,
          appBar: PreferredSize(
            preferredSize:
                const Size.fromHeight(kToolbarHeight), // Default height
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    offset: const Offset(0, 2),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: AppBar(
                elevation: 0, // Remove default shadow
                backgroundColor: Colors.transparent,
                iconTheme: const IconThemeData(
                    color: Colors.white), // Makes the auto drawer icon white
                titleSpacing: 0, // Reduces space between menu icon and title
                title: const AutoSizeText(
                  'Tableau de Bord Élève',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                ),
                actions: [
                  AnimateIcon(
                    key: UniqueKey(),
                    onTap: () {
                      context.go('/messages', extra: userData);
                    },
                    iconType: IconType.continueAnimation,
                    height: 30,
                    width: 30,
                    color: Colors.white,
                    animateIcon: AnimateIcons.mail,
                  ),
                  const SizedBox(width: 16),
                  AnimateIcon(
                    key: UniqueKey(),
                    onTap: () {
                      context.go('/notifications', extra: userData);
                    },
                    iconType: IconType.continueAnimation,
                    height: 30,
                    width: 30,
                    color: Colors.white,
                    animateIcon: AnimateIcons.bell,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          drawer: SidebarMenu(
            userData: userData,
            activePage: widget.activePage,
            onPageSelected: (page) =>
                context.go(_getRouteForPage(page), extra: userData),
          ),
          drawerEnableOpenDragGesture: true,
          body: NotificationListener<ScrollNotification>(
            onNotification: onScrollNotification,
            child: widget.body,
          ),
          bottomNavigationBar: ConvexAppBar(
            style: TabStyle.react,
            backgroundColor: Theme.of(context).colorScheme.primary,
            color: Colors.white70,
            activeColor: Colors.white,
            initialActiveIndex: _bottomNavIndex,
            items: const [
              TabItem(icon: Icons.message, title: 'Messages'),
              TabItem(icon: Icons.home, title: 'Accueil'),
              TabItem(icon: Icons.bar_chart, title: 'Resultats'),
            ],
            onTap: (index) {
              setState(() => _bottomNavIndex = index);
              String page = _getPageForBottomNavIndex(index);
              context.go(_getRouteForPage(page), extra: userData);
            },
          ),
        );
      },
    );
  }

  String _getRouteForPage(String page) {
    switch (page) {
      case 'accueil':
        return '/home-eleve';
      case 'cours':
        return '/cours';
      case 'tests':
        return '/tests';
      case 'vocabulaire':
        return '/vocabulaire';
      case 'quizz':
        return '/quizz';
      case 'resultats':
        return '/resultats';
      case 'jeux':
        return '/jeux';
      case 'messages':
        return '/messages';
      case 'infos':
        return '/infos';
      case 'resultats':
        return '/resultats';
      default:
        return '/home-eleve';
    }
  }

  int _getBottomNavIndex(String page) {
    switch (page) {
      case 'messages':
        return 0;
      case 'accueil':
        return 1;
      case 'resultats':
        return 2;
      default:
        return 1;
    }
  }

  String _getPageForBottomNavIndex(int index) {
    switch (index) {
      case 0:
        return 'messages';
      case 1:
        return 'accueil';
      case 2:
        return 'resultats';
      default:
        return 'accueil';
    }
  }
}
