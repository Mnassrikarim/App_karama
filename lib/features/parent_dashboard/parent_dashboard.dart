import 'package:animated_icon/animated_icon.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:edu_karama_app/services/api_service.dart';
import 'package:edu_karama_app/features/parent_dashboard/widgets/sidebar_menu_parent.dart';

class ParentDashboard extends StatefulWidget {
  final Widget body;
  final String title;
  final String activePage;

  const ParentDashboard({
    super.key,
    required this.body,
    required this.title,
    required this.activePage,
  });

  @override
  _ParentDashboardState createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard>
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
  void didUpdateWidget(ParentDashboard oldWidget) {
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

        if (userData != null && userData['role'] != 'parent') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login-parent');
          });
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          extendBody: true,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
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
                elevation: 0,
                backgroundColor: Colors.transparent,
                iconTheme: const IconThemeData(color: Colors.white),
                titleSpacing: 0,
                title: const AutoSizeText(
                  'Tableau de Bord Parent',
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
                      context.go('/messages-parent', extra: userData);
                    },
                    iconType: IconType.continueAnimation,
                    height: 25,
                    width: 25,
                    color: Colors.white,
                    animateIcon: AnimateIcons.mail,
                  ),
                  const SizedBox(width: 16),
                  AnimateIcon(
                    key: UniqueKey(),
                    onTap: () {
                      context.go('/notifications-parent', extra: userData);
                    },
                    iconType: IconType.continueAnimation,
                    height: 25,
                    width: 25,
                    color: Colors.white,
                    animateIcon: AnimateIcons.bell,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          drawer: SidebarMenuParent(
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
              TabItem(icon: Icons.bar_chart, title: 'Progrès'),
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
        return '/home-parent';
      case 'progres':
        return '/progres';
      case 'notifications':
        return '/notifications-parent';
      case 'messages':
        return '/messages-parent';
      case 'infos':
        return '/infos-parent';
      default:
        return '/home-parent';
    }
  }

  int _getBottomNavIndex(String page) {
    switch (page) {
      case 'messages':
        return 0;
      case 'accueil':
        return 1;
      case 'progres':
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
        return 'progres';
      default:
        return 'accueil';
    }
  }
}
