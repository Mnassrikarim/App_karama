import 'package:edu_karama_app/cors/onboarding_data.dart';
import 'package:edu_karama_app/cors/onboarding_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/onboarding_slide.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  final List<OnboardingModel> _items = OnboardingData.items;

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }
  void _gotoNextPage() {
    if (_currentPage < _items.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      context.go('/intro');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Expanded(
              flex: 8,
              child: PageView.builder(
                controller: _controller,
                onPageChanged: _onPageChanged,
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return OnboardingSlide(data: _items[index]);
                },
              ),
            ),
            const Spacer(),
            Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 300),
                  tween: Tween<double>(
                    begin: 0,
                    end: (_currentPage + 1) / _items.length,
                  ),
                  curve: Curves.easeInOut,
                  builder: (context, double value, _) => SizedBox(
                    height: 70,
                    width: 70,
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey[300],
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _gotoNextPage,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Color.fromARGB(255, 28, 9, 171),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _items.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 12 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
