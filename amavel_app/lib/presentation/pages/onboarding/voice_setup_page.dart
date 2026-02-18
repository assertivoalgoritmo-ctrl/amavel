import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amavel_app/config/theme.dart';
import 'package:amavel_app/core/constants.dart';

class VoiceSetupPage extends StatefulWidget {
  const VoiceSetupPage({Key? key}) : super(key: key);

  @override
  State<VoiceSetupPage> createState() => _VoiceSetupPageState();
}

class _VoiceSetupPageState extends State<VoiceSetupPage> {
  PermissionStatus? _micPermissionStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkMicPermission();
  }

  Future<void> _checkMicPermission() async {
    final status = await Permission.microphone.status;
    setState(() => _micPermissionStatus = status);
  }

  Future<void> _requestMicPermission() async {
    setState(() => _isLoading = true);

    try {
      final status = await Permission.microphone.request();
      setState(() => _micPermissionStatus = status);

      if (status.isGranted) {
        // Save onboarding as complete
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarding_complete', true);

        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppConstants.routeHome);
        }
      } else if (status.isDenied) {
        if (mounted) {
          _showPermissionDeniedDialog();
        }
      } else if (status.isPermanentlyDenied) {
        if (mounted) {
          _showPermissionPermanentlyDeniedDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao solicitar permissão. Por favor, tente novamente.',
              style: TextStyle(fontSize: AmavelTheme.textSizeBody, color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AmavelTheme.surfaceColor,
          title: const Text(
            'Microfone Necessário',
            style: TextStyle(
              color: AmavelTheme.textPrimary,
              fontSize: 22,
            ),
          ),
          content: const Text(
            'O microfone é essencial para que a AMAVEL possa ouvi-lo. Sem este, a aplicação não funcionará corretamente.',
            style: TextStyle(
              color: AmavelTheme.textPrimary,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: AmavelTheme.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _requestMicPermission();
              },
              child: const Text(
                'Tentar novamente',
                style: TextStyle(
                  color: AmavelTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AmavelTheme.surfaceColor,
          title: const Text(
            'Permissão Bloqueada',
            style: TextStyle(
              color: AmavelTheme.textPrimary,
              fontSize: 22,
            ),
          ),
          content: const Text(
            'A permissão do microfone foi bloqueada. Por favor, abra as configurações e ative o microfone para a AMAVEL.',
            style: TextStyle(
              color: AmavelTheme.textPrimary,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: AmavelTheme.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                openAppSettings();
              },
              child: const Text(
                'Abrir configurações',
                style: TextStyle(
                  color: AmavelTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMicGranted = _micPermissionStatus?.isGranted ?? false;

    return Scaffold(
      backgroundColor: AmavelTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top content
                Column(
                  children: [
                    const SizedBox(height: 40),

                    // Title
                    Text(
                      'Configuração de Voz',
                      style: const TextStyle(
                        color: AmavelTheme.textPrimary,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Description
                    Text(
                      'Vamos testar o seu microfone',
                      style: const TextStyle(
                        color: AmavelTheme.textSecondary,
                        fontSize: 20,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Microphone Button or Success Message
                    if (!isMicGranted) ...[
                      // Test Microphone Button
                      GestureDetector(
                        onTap: _isLoading ? null : _requestMicPermission,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AmavelTheme.primaryColor,
                            boxShadow: [
                              BoxShadow(
                                color: AmavelTheme.primaryColor.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 4,
                                )
                              : const Icon(
                                  Icons.mic,
                                  size: 80,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Toque para permitir acesso ao microfone',
                        style: const TextStyle(
                          color: AmavelTheme.textSecondary,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      // Success State
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 100,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Microfone configurado com sucesso!',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 48),
                  ],
                ),

                // Bottom button
                if (isMicGranted) ...[
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  setState(() => _isLoading = true);
                                  try {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setBool(
                                        'onboarding_complete', true);

                                    if (mounted) {
                                      Navigator.of(context)
                                          .pushReplacementNamed(
                                              AppConstants.routeHome);
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AmavelTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Continuar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  )
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
