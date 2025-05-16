import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/language_provider.dart';
import 'home_screen.dart';
import 'main_navigation_screen.dart';
import 'dart:ui';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                // Decorative top element
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Circular background with blur effect
                      Container(
                        height: screenSize.height * 0.35,
                        width: screenSize.height * 0.35,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.withOpacity(0.1),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                      // Animation
                      SizedBox(
                        height: screenSize.height * 0.4,
                        width: screenSize.width * 0.8,
                        child: Lottie.asset(
                          'assets/animations/plant_animation.json',
                          fit: BoxFit.contain,
                          repeat: true,
                          animate: true,
                          errorBuilder: (context, error, stackTrace) {
                            print('Lottie error: $error');
                            return Container(
                              child: const Center(
                                child: Icon(
                                  Icons.local_florist,
                                  size: 100,
                                  color: Colors.green,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Welcome text with shadow
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: const Text(
                    'Welcome to BioScout Islamabad',
                    style: TextStyle(
                      fontSize: 32, 
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Color.fromRGBO(0, 150, 0, 0.3),
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Subtitle with custom styling
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: const Text(
                    'Please select your preferred language',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // English button
                _buildLanguageButton(
                  context,
                  'English',
                  const Locale('en', ''),
                  Icons.language,
                ).animate()
                  .fadeIn(duration: 600.ms, delay: 300.ms)
                  .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOutQuad),
                
                const SizedBox(height: 20),
                
                // Urdu button
                _buildLanguageButton(
                  context,
                  'اردو (Urdu)',
                  const Locale('ur', ''),
                  Icons.language,
                ).animate()
                  .fadeIn(duration: 600.ms, delay: 500.ms)
                  .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOutQuad),
                
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildLanguageButton(
    BuildContext context, 
    String language, 
    Locale locale,
    IconData icon,
  ) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(isHovered ? 0.35 : 0.25),
                  spreadRadius: isHovered ? 3 : 2,
                  blurRadius: isHovered ? 20 : 15,
                  offset: Offset(0, isHovered ? 8 : 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                splashColor: Colors.white.withOpacity(0.1),
                highlightColor: Colors.white.withOpacity(0.05),
                onTap: () async {
                  // Set the selected language
                  await languageProvider.setLocale(locale);
                  
                  // Navigate to main navigation screen
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (ctx) => const MainNavigationScreen()),
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        isHovered ? Colors.green.shade400 : Colors.green.shade500,
                        isHovered ? Colors.green.shade600 : Colors.green.shade700,
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(isHovered ? 0.3 : 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(isHovered ? 0.3 : 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        language,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
