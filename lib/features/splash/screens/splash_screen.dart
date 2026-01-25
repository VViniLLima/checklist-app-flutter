import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/widgets/login_bottom_sheet.dart';
import '../../auth/widgets/signup_bottom_sheet.dart';
import '../../shopping_list/screens/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _gridAnimations;
  late List<Animation<double>> _shapeAnimations;
  late Animation<double> _contentOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Grid animations (4 tiles)
    _gridAnimations = List.generate(4, (index) {
      final start = 0.2 + (index * 0.1);
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, start + 0.3, curve: Curves.easeOutBack),
      );
    });

    // Decorative shape animations (4 shapes)
    _shapeAnimations = List.generate(4, (index) {
      final start = 0.5 + (index * 0.08);
      final end = (start + 0.3).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });

    // Content opacity (buttons and text)
    _contentOpacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset('assets/Images/Asset 1.png', fit: BoxFit.cover),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Center Animated Section
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Decorative Shapes behind
                      _buildDecorativeShapes(),

                      // Central Rounded Container
                      _buildCentralGrid(),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Title and Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: FadeTransition(
                    opacity: _contentOpacityAnimation,
                    child: Column(
                      children: [
                        const Text(
                          'Organiza',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'BwHelderW1',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Transforme qualquer lista em uma compra organizada em segundos',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // Bottom Buttons
                _buildBottomButtons(),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCentralGrid() {
    return Container(
      width: 200,
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildGridTile(0, AppColors.success, Icons.check_rounded),
          _buildGridTile(1, AppColors.warning, Icons.inventory_2_outlined),
          _buildGridTile(2, AppColors.accent, Icons.shopping_bag_outlined),
          _buildGridTile(
            3,
            AppColors.blueSecondary,
            Icons.shopping_cart_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildGridTile(int index, Color color, IconData icon) {
    return ScaleTransition(
      scale: _gridAnimations[index],
      child: FadeTransition(
        opacity: _gridAnimations[index],
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  Widget _buildDecorativeShapes() {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        children: [
          // Top Left Small Shape
          Positioned(
            top: 40,
            left: 20,
            child: _buildShape(
              0,
              30,
              30,
              const Color(0xFF00C9BD).withOpacity(0.4),
            ),
          ),
          // Top Right Medium Shape
          Positioned(
            top: 20,
            right: 40,
            child: _buildShape(
              1,
              45,
              45,
              const Color(0xFF179BE6).withOpacity(0.3),
            ),
          ),
          // Bottom Left Shape
          Positioned(
            bottom: 40,
            left: 30,
            child: _buildShape(
              2,
              40,
              40,
              const Color(0xFF00C9BD).withOpacity(0.2),
            ),
          ),
          // Bottom Right Large Shape
          Positioned(
            bottom: 20,
            right: 20,
            child: _buildShape(
              3,
              55,
              55,
              const Color(0xFF179BE6).withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShape(int index, double width, double height, Color color) {
    return ScaleTransition(
      scale: _shapeAnimations[index],
      child: FadeTransition(
        opacity: _shapeAnimations[index],
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: FadeTransition(
        opacity: _contentOpacityAnimation,
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => showLoginBottomSheet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Entrar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => showSignupBottomSheet(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 2),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Criar conta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                );
              },
              child: Text(
                'Continuar sem conta',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
