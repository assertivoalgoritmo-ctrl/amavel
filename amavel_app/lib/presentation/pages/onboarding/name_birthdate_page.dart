import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amavel_app/config/theme.dart';
import 'package:amavel_app/core/constants.dart';

/// Onboarding page to collect user's name and optional birthdate.
/// Designed for elderly users: large text, simple layout, "você" treatment.
class NameBirthdatePage extends StatefulWidget {
  const NameBirthdatePage({Key? key}) : super(key: key);

  @override
  State<NameBirthdatePage> createState() => _NameBirthdatePageState();
}

class _NameBirthdatePageState extends State<NameBirthdatePage> {
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 70, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      locale: const Locale('pt', 'PT'),
      helpText: 'Selecione a sua data de nascimento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AmavelTheme.primaryColor,
              onPrimary: Colors.white,
              surface: AmavelTheme.surfaceColor,
              onSurface: AmavelTheme.textPrimary,
            ),
            textTheme: const TextTheme(
              headlineMedium: TextStyle(fontSize: 24),
              bodyLarge: TextStyle(fontSize: 18),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  Future<void> _handleContinue() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _nameError = 'Por favor, escreva o seu nome');
      return;
    }

    setState(() {
      _isLoading = true;
      _nameError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefUserName, name);

      if (_selectedDate != null) {
        await prefs.setString(
          AppConstants.prefUserBirthdate,
          _selectedDate!.toIso8601String(),
        );
      }

      if (mounted) {
        Navigator.of(context).pushNamed(AppConstants.routeVoiceSetup);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao guardar dados. Por favor, tente novamente.',
              style: const TextStyle(fontSize: 16),
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
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // Title
                    const Text(
                      'Vamos conhecer-nos!',
                      style: TextStyle(
                        color: AmavelTheme.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Subtitle
                    const Text(
                      'Como gostaria que a AMAVEL o/a tratasse?',
                      style: TextStyle(
                        color: AmavelTheme.textSecondary,
                        fontSize: 20,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Name label
                    const Text(
                      'O seu nome',
                      style: TextStyle(
                        color: AmavelTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Name text field
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(
                        fontSize: 22,
                        color: AmavelTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Escreva o seu nome aqui',
                        hintStyle: TextStyle(
                          fontSize: 20,
                          color: AmavelTheme.textSecondary.withOpacity(0.5),
                        ),
                        errorText: _nameError,
                        errorStyle: const TextStyle(fontSize: 16),
                        filled: true,
                        fillColor: AmavelTheme.surfaceColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AmavelTheme.textSecondary.withOpacity(0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AmavelTheme.textSecondary.withOpacity(0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AmavelTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) {
                        if (_nameError != null) {
                          setState(() => _nameError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 40),

                    // Birthdate label
                    const Text(
                      'Data de nascimento (opcional)',
                      style: TextStyle(
                        color: AmavelTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Isto ajuda a AMAVEL a lembrar-se do seu aniversário.',
                      style: TextStyle(
                        color: AmavelTheme.textSecondary,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date picker button
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: AmavelTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedDate != null
                                ? AmavelTheme.primaryColor
                                : AmavelTheme.textSecondary.withOpacity(0.2),
                            width: _selectedDate != null ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 28,
                              color: _selectedDate != null
                                  ? AmavelTheme.primaryColor
                                  : AmavelTheme.textSecondary,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _selectedDate != null
                                    ? _formatDate(_selectedDate!)
                                    : 'Toque para selecionar',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: _selectedDate != null
                                      ? AmavelTheme.textPrimary
                                      : AmavelTheme.textSecondary.withOpacity(0.5),
                                ),
                              ),
                            ),
                            if (_selectedDate != null)
                              GestureDetector(
                                onTap: () => setState(() => _selectedDate = null),
                                child: const Icon(
                                  Icons.close,
                                  size: 24,
                                  color: AmavelTheme.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),

                // Bottom button
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AmavelTheme.primaryColor,
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
                            : const Text(
                                'Continuar',
                                style: TextStyle(
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
      ),
    );
  }
}
