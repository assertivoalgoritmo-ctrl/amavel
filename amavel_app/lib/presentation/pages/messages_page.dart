import 'package:flutter/material.dart';
import 'package:amavel_app/config/theme.dart';
import 'package:amavel_app/core/constants.dart';
import 'package:amavel_app/presentation/widgets/elder_nav_bar.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AmavelTheme.backgroundColor,
      body: Column(
        children: [
          // Header with title
          Padding(
            padding: const EdgeInsets.only(top: 32, left: 20, right: 20, bottom: 20),
            child: Text(
              'Mensagens',
              style: const TextStyle(
                color: AmavelTheme.textPrimary,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Main content area
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Message Icon
                  Icon(
                    Icons.mail_outline,
                    size: 80,
                    color: AmavelTheme.primaryColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 24),

                  // Placeholder text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'As suas mensagens aparecerão aqui',
                      style: const TextStyle(
                        color: AmavelTheme.textSecondary,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Navigation Bar
          ElderNavBar(
            currentIndex: 1,
            onTap: (index) {
              if (index == 0) {
                Navigator.of(context).pushReplacementNamed(AppConstants.routeHome);
              } else if (index == 2) {
                Navigator.of(context).pushReplacementNamed(AppConstants.routeSettings);
              }
            },
          ),
        ],
      ),
    );
  }
}
