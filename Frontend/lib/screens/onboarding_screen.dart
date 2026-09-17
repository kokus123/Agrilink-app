import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class _Slide {
  final String image;
  final String titre;
  final String description;

  const _Slide({
    required this.image,
    required this.titre,
    required this.description,
  });
}

/// Onboarding visiteur — 3 slides plein écran, affiché à chaque lancement
/// tant que l'utilisateur n'est pas connecté (pas de mémorisation "déjà
/// vu", volontairement, façon carrousel promo).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  static const List<_Slide> _slides = [
    _Slide(
      image: 'assets/images/onboarding_1.jpg',
      titre: 'Achète frais, directement des producteurs',
      description:
          'Parcours le catalogue et commande des produits fraîchement récoltés, sans intermédiaire.',
    ),
    _Slide(
      image: 'assets/images/onboarding_2.jpg',
      titre: 'Une agriculture connectée',
      description:
          "Les producteurs gèrent leurs stocks et suivent leurs ventes directement depuis l'application.",
    ),
    _Slide(
      image: 'assets/images/onboarding_3.jpg',
      titre: 'Suis ta livraison en temps réel',
      description:
          'Un transporteur prend en charge ta commande et tu peux suivre sa position sur la carte, en direct.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _allerVersLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _suivant() {
    if (_page < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _allerVersLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dernierSlide = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fond plein écran — une image par slide, avec dégradé sombre
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) => _SlideBackground(slide: _slides[index]),
          ),

          // "Passer" — raccourci direct vers Login, toujours visible
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 4),
                child: TextButton(
                  onPressed: _allerVersLogin,
                  child: const Text(
                    'Passer',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 6)],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Texte + points + bouton, collés en bas, par-dessus le dégradé
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _slides[_page].titre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _slides[_page].description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: List.generate(
                        _slides.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(right: 6),
                          width: i == _page ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page ? Colors.white : Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Center(
                      child: SizedBox(
                        width: 220,
                        child: ElevatedButton(
                          onPressed: _suivant,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4ECDA0),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 0,
                          ),
                          child: Text(
                            dernierSlide ? 'COMMENCER' : 'SUIVANT',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideBackground extends StatelessWidget {
  final _Slide slide;
  const _SlideBackground({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(slide.image, fit: BoxFit.cover),
        // Dégradé sombre du bas vers le haut — garde le texte blanc
        // lisible quelle que soit la photo derrière.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.15),
                Colors.black.withValues(alpha: 0.85),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
