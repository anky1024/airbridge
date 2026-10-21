import 'package:flutter/material.dart';

void main() {
  runApp(const AirBridgeApp());
}

class AirBridgeApp extends StatelessWidget {
  const AirBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AirBridge',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1220),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF20D6C7),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      home: const AirBridgeHomePage(),
    );
  }
}

class AirBridgeHomePage extends StatelessWidget {
  const AirBridgeHomePage({super.key});

  static const Color teal = Color(0xFF20D6C7);
  static const Color cardColor = Color(0xFF151F30);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),

              // App branding
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: teal.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: teal,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AirBridge',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Share freely. Connect instantly.',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 38),

              // Welcome section
              const Text(
                'Your files,',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const Text(
                'moving freely.',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: teal,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Transfer photos, videos and documents\nbetween devices on your local network.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.white60,
                ),
              ),

              const SizedBox(height: 28),

              // Connection status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.wifi_rounded,
                      color: teal,
                      size: 28,
                    ),
                    SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ready to connect',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Connect both devices to the same Wi-Fi',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.circle,
                      size: 9,
                      color: teal,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'GET STARTED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white54,
                ),
              ),

              const SizedBox(height: 14),

              // Send files
              _ActionCard(
                icon: Icons.upload_rounded,
                title: 'Send files',
                subtitle: 'Choose files to share with another device',
                color: teal,
                onTap: () {
                  _showComingSoon(context, 'Send files');
                },
              ),

              const SizedBox(height: 14),

              // Receive files
              _ActionCard(
                icon: Icons.download_rounded,
                title: 'Receive files',
                subtitle: 'Connect and receive files from another device',
                color: const Color(0xFF8EA9FF),
                onTap: () {
                  _showComingSoon(context, 'Receive files');
                },
              ),

              const SizedBox(height: 14),

              // QR connection
              _ActionCard(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Connect with QR',
                subtitle: 'Scan a code to connect devices quickly',
                color: const Color(0xFFFFC66D),
                onTap: () {
                  _showComingSoon(context, 'QR connection');
                },
              ),

              const SizedBox(height: 28),

              // Privacy information
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: teal.withValues(alpha: 0.18),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: teal,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your files. Your devices.',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'AirBridge is designed for direct transfers '
                            'over your local network.',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Center(
                child: Text(
                  'AIRBRIDGE  •  PRIVATE FILE SHARING',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  static void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be available in the next step.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF151F30),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 27,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}