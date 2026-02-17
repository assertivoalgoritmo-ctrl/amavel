import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amavel_app/config/theme.dart';
import 'package:amavel_app/core/constants.dart';

class ConsentPage extends StatefulWidget {
  const ConsentPage({Key? key}) : super(key: key);

  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  bool _consentGiven = false;
  bool _isLoading = false;

  Future<void> _handleContinue() async {
    if (!_consentGiven) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('consent_given', true);

      if (mounted) {
        Navigator.of(context).pushNamed(AppConstants.voiceSetupRoute);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao guardar consentimento. Por favor, tente novamente.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AmavelTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            minHeight: MediaQuery.of(context).size.height,
            children: [
              // Top spacing and header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  Text(
                    'Consentimento e Privacidade',
                    style: AmavelTheme.displayLarge.copyWith(
                      color: AmavelTheme.textColorPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Consent Text Box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AmavelTheme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AmavelTheme.borderColor,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _buildConsentText(),
                      style: AmavelTheme.bodyMedium.copyWith(
                        color: AmavelTheme.textColorPrimary,
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Consent Checkbox
                  GestureDetector(
                    onTap: () {
                      setState(() => _consentGiven = !_consentGiven);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AmavelTheme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _consentGiven
                              ? AmavelTheme.primaryColor
                              : AmavelTheme.borderColor,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _consentGiven
                                  ? AmavelTheme.primaryColor
                                  : Colors.transparent,
                              border: Border.all(
                                color: _consentGiven
                                    ? AmavelTheme.primaryColor
                                    : AmavelTheme.borderColor,
                                width: 2,
                              ),
                            ),
                            child: _consentGiven
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Concordo com o processamento dos meus dados',
                              style: AmavelTheme.bodyLarge.copyWith(
                                color: AmavelTheme.textColorPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom section with button
              Column(
                children: [
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: _consentGiven && !_isLoading
                          ? _handleContinue
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _consentGiven
                            ? AmavelTheme.primaryColor
                            : AmavelTheme.primaryColor.withOpacity(0.5),
                        disabledBackgroundColor:
                            AmavelTheme.primaryColor.withOpacity(0.3),
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
                              'Aceitar e continuar',
                              style: AmavelTheme.headlineSmall.copyWith(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildConsentText() {
    return '''A AMAVEL recolhe e processa os seus dados para fornecer serviços personalizados de acompanhamento e suporte.

Dados Recolhidos:
• Registos de voz e transcrições
• Histórico de conversas
• Preferências pessoais
• Informações de conta

Os seus dados são:
• Processados com segurança
• Nunca partilhados sem consentimento
• Protegidos de acordo com GDPR
• Utilizados apenas para melhorar a experiência

Tem o direito de aceder, modificar ou eliminar os seus dados a qualquer momento.''';
  }
}
