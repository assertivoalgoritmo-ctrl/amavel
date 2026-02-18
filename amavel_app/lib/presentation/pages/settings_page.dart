import 'package:flutter/material.dart';
import 'package:amavel_app/config/theme.dart';
import 'package:amavel_app/presentation/widgets/elder_nav_bar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _volumeLevel = 0.7;
  double _voiceSpeed = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AmavelTheme.backgroundColor,
      body: Column(
        children: [
          // Header with title
          Padding(
            padding: const EdgeInsets.only(top: 32, left: 20, right: 20, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Definições',
                  style: const TextStyle(
                    color: AmavelTheme.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AMAVEL v1.0.0',
                  style: const TextStyle(
                    color: AmavelTheme.textSecondary,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),

          // Settings content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Volume Setting
                    _buildSettingCard(
                      icon: Icons.volume_up,
                      title: 'Volume',
                      child: Column(
                        children: [
                          Slider(
                            value: _volumeLevel,
                            onChanged: (value) {
                              setState(() => _volumeLevel = value);
                            },
                            min: 0,
                            max: 1,
                            activeColor: AmavelTheme.primaryColor,
                            inactiveColor: AmavelTheme.primaryColor.withOpacity(0.3),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '${(_volumeLevel * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: AmavelTheme.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Voice Speed Setting
                    _buildSettingCard(
                      icon: Icons.speed,
                      title: 'Velocidade da voz',
                      child: Column(
                        children: [
                          Slider(
                            value: _voiceSpeed,
                            onChanged: (value) {
                              setState(() => _voiceSpeed = value);
                            },
                            min: 0.5,
                            max: 2.0,
                            activeColor: AmavelTheme.primaryColor,
                            inactiveColor: AmavelTheme.primaryColor.withOpacity(0.3),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              _getSpeedLabel(_voiceSpeed),
                              style: const TextStyle(
                                color: AmavelTheme.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pipeline Mode
                    _buildSettingCard(
                      icon: Icons.settings_suggest,
                      title: 'Modo Pipeline',
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Ativo',
                          style: const TextStyle(
                            color: AmavelTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // About AMAVEL
                    _buildSettingCard(
                      icon: Icons.info_outline,
                      title: 'Sobre a AMAVEL',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'AMAVEL v1.0.0 - A sua companheira de confiança',
                              style: TextStyle(fontSize: AmavelTheme.textSizeBody, color: Colors.white),
                            ),
                            backgroundColor: AmavelTheme.primaryColor,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Navigation Bar
          ElderNavBar(
            currentIndex: 2,
            onTap: (index) {
              // Navigation handling will be done at the router level
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    Widget? child,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AmavelTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AmavelTheme.textSecondary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: AmavelTheme.primaryColor,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: AmavelTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (child != null) ...[
              const SizedBox(height: 16),
              child,
            ],
          ],
        ),
      ),
    );
  }

  String _getSpeedLabel(double speed) {
    if (speed < 0.75) return 'Lenta';
    if (speed < 1.25) return 'Normal';
    return 'Rápida';
  }
}
