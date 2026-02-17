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
          Navigator.of(context).pushReplacementNamed(AppConstants.homeRoute);
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
              style: AmavelTheme.bodyMedium,
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
          backgroundColor: AmavelTheme.cardColor,
          title: Text(
            'Microfone Necessário',
            style: AmavelTheme.headlineSmall.copyWith(
              color: AmavelTheme.textColorPrimary,
              fontSize: 22,
            ),
          ),
          content: Text(
            'O microfone é essencial para que a AMAVEL possa ouvi-lo. Sem este, a aplicação não funcionará corretamente.',
            style: AmavelTheme.bodyMedium.copyWith(
              color: AmavelTheme.textColorPrimary,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: AmavelTheme.labelLarge.copyWith(
                  color: AmavelTheme.textColorSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _requestMicPermission();
              },
              child: Text(
                'Tentar novamente',
                style: AmavelTheme.labelLarge.copyWith(
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
          backgroundColor: AmavelTheme.cardColor,
          title: Text(
            'Permissão Bloqueada',
            style: AmavelTheme.headlineSmall.copyWith(
              color: AmavelTheme.textColorPrimary,
              fontSize: 22,
            ),
          ),
          content: Text(
            'A permissão do microfone foi bloqueada. Por favor, abra as configurações e ative o microfone para a AMAVEL.',
            style: AmavelTheme.bodyMedium.copyWith(
              color: AmavelTheme.textColorPrimary,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: AmavelTheme.labelLarge.copyWith(
                  color: AmavelTheme.textColorSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                openAppSettings();
              },
              child: Text(
                'Abrir configurações',
                style: AmavelTheme.labelLarge.copyWith(
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            minHeight: MediaQuery.of(context).size.height,
            children: [
              // Top content
              Column(
                children: [
                  const SizedBox(height: 40),

                  // Title
                  Text(
                    'Configuração de Voz',
                    style: AmavelTheme.displayLarge.copyWith(
                      color: AmavelTheme.textColorPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Description
                  Text(
                    'Vamos testar o seu microfone',
                    style: AmavelTheme.bodyLarge.copyWith(
                      color: AmavelTheme.textColorSecondary,
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
                            : Icon(
                                Icons.mic,
                                size: 80,
                                color: Colors.white,
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Toque para permitir acesso ao microfone',
                      style: AmavelTheme.bodyMedium.copyWith(
                        color: AmavelTheme.textColorSecondary,
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
                      child: Icon(
                        Icons.check,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Microfone configurado com sucesso!',
                      style: AmavelTheme.bodyLarge.copyWith(
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
                                            AppConstants.homeRoute);
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
                            : Text(
                                'Continuar',
                                style: AmavelTheme.headlineSmall.copyWith(
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
    );
  }
}
