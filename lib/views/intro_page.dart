import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _loopingAnimationController;
  late Animation<double> _underlineAnimation;
  late AnimationController _zoomAnimationController;
  late Animation<double> _zoomAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize video controller
    _videoController =
        VideoPlayerController.asset('assets/vedio/intro_video.mp4')
          ..initialize().then((_) {
            setState(() {});
            _videoController.setLooping(true);
            _videoController.play();
          });

    // Animation controller for looping underline
    _loopingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Underline fade animation
    _underlineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loopingAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Animation controller for zoom-in/zoom-out
    _zoomAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Zoom animation for "Êtes-vous ?"
    _zoomAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _zoomAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    _loopingAnimationController.dispose();
    _zoomAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background video
          _videoController.value.isInitialized
              ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  ),
                )
              : const Center(child: CircularProgressIndicator()),
          // Overlay with text and cards
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // "Êtes-vous ?" with zoom-in/zoom-out animation

              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: AnimatedBuilder(
                  animation: _zoomAnimationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _zoomAnimation.value,
                      child: Text(
                        'Êtes-vous ?',
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),
              // Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCard(
                    context,
                    imagePath: 'assets/images/eee.png',
                    label: 'Élève',
                    route: '/login-eleve',
                  ),
                  const SizedBox(width: 16),
                  _buildCard(
                    context,
                    imagePath: 'assets/images/ppp.png',
                    label: 'Parent',
                    route: '/login-parent',
                  ),
                ],
              ),
            ],
          ),
          // "Bienvenu dans" and "KaraScolaire" in top-left with looping underline
          Positioned(
            top: 40,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenu dans',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 36, // Increased size
                      ),
                  textAlign: TextAlign.left,
                ),
                FadeTransition(
                  opacity: _underlineAnimation,
                  child: Container(
                    width: 250,
                    height: 2,
                    color: Colors.blue[900],
                    margin: const EdgeInsets.only(top: 4, bottom: 8),
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Kara',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.yellow,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      TextSpan(
                        text: 'Scolaire',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.blue[900],
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.left,
                ),
                FadeTransition(
                  opacity: _underlineAnimation,
                  child: Container(
                    width: 200,
                    height: 2,
                    color: Colors.yellow,
                    margin: const EdgeInsets.only(top: 4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context,
      {required String imagePath,
      required String label,
      required String route}) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: Colors.yellow, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: 150,
              height: 100,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.image_not_supported,
                size: 100,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
