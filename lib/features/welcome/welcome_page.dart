import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, required this.onLogin, required this.onCta});

  final VoidCallback onLogin;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topPad = media.padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      body: Stack(
        children: [
          // ===== Background header (dark gradient) =====
          Positioned.fill(
            child: Column(
              children: [
                Container(
                  height: 210 + topPad,
                  padding: EdgeInsets.only(top: topPad),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF2A1A12), Color(0xFF3A261B)],
                    ),
                  ),
                  child: _TopBar(onLogin: onLogin),
                ),

                // ✅ Hero image area (FIXED height so it doesn't get huge)
                SizedBox(
                  height: media.size.height * 0.48, // tweak: 0.42 - 0.55
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/welcome_couple.jpg',
                          fit: BoxFit.cover,
                          // ✅ Better framing for tall photos (keeps faces higher)
                          alignment: const Alignment(0, -0.35),
                        ),
                      ),

                      // Curved white wave overlay at the top of the hero image
                      Positioned(
                        top: -1,
                        left: 0,
                        right: 0,
                        child: ClipPath(
                          clipper: _TopWaveClipper(),
                          child: Container(height: 130, color: Colors.white),
                        ),
                      ),

                      // Slight dark fade near bottom for readability (optional)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.25),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // CTA panel space
                const SizedBox(height: 200),
              ],
            ),
          ),

          // ===== Bottom CTA panel =====
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
              decoration: const BoxDecoration(color: Color(0xFFE8E8E8)),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Meet Orthodox Singles',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: onCta,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB35C2E),
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        child: const Text(
                          'View Singles Now',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onLogin});
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left "Back" placeholder area (like iOS top left)
              const SizedBox(width: 60),
              TextButton(
                onPressed: onLogin,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text(
                  'Login',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Simple heart mark (replace with your SVG/logo)
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: Icon(
                  Icons.favorite,
                  color: const Color(0xFFE3C36A),
                  size: 34,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'EtOrthodox Dating',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

/// Creates the curved "white wave" that cuts into the hero image.
class _TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.lineTo(0, 0);
    p.lineTo(0, size.height * 0.55);

    p.quadraticBezierTo(
      size.width * 0.50,
      size.height * 1.05,
      size.width,
      size.height * 0.55,
    );

    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
