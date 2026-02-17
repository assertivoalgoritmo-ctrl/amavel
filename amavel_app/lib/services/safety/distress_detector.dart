import 'package:diacritic/diacritic.dart';

/// Result of distress detection analysis
class DetectedDistress {
  final bool isCritical;
  final bool isHighSeverity;
  final bool isMediumSeverity;
  final List<String> matchedPatterns;
  final double confidence;
  final String? detectionCategory; // "suicidal", "isolation", "health", "scam"

  DetectedDistress({
    required this.isCritical,
    required this.isHighSeverity,
    required this.isMediumSeverity,
    required this.matchedPatterns,
    required this.confidence,
    this.detectionCategory,
  });

  @override
  String toString() {
    return 'DetectedDistress(critical: $isCritical, high: $isHighSeverity, medium: $isMediumSeverity, patterns: $matchedPatterns)';
  }
}

/// Portuguese keyword and pattern-based distress detection
class DistressDetector {
  // Critical keywords indicating suicidal ideation
  static const List<String> _criticalKeywords = [
    'quero morrer',
    'vou-me matar',
    'não vale a pena viver',
    'acabar com tudo',
    'suicídio',
    'matar-me',
    'matava-me',
    'desaparecer',
    'estar morto',
    'melhor estar morto',
    'ninguém precisa de mim',
  ];

  // High severity keywords indicating significant distress
  static const List<String> _highKeywords = [
    'muito sozinho',
    'muito sozinha',
    'ninguém se importa',
    'ninguém liga',
    'não aguento mais',
    'não posso mais',
    'estou desesperado',
    'estou desesperada',
    'completamente perdido',
    'completamente perdida',
    'ninguém gosta de mim',
    'sem razão para viver',
    'vazio',
    'inútil',
    'peso para os outros',
  ];

  // Medium severity keywords indicating sadness and isolation
  static const List<String> _mediumKeywords = [
    'estou triste',
    'sinto-me triste',
    'estou deprimido',
    'estou deprimida',
    'sinto-me só',
    'muito sozinho',
    'muito sozinha',
    'não durmo bem',
    'insónia',
    'perdi o apetite',
    'sem esperança',
    'tudo é cinzento',
    'saudade da minha vida',
    'não vale a pena',
  ];

  // Scam indicators
  static const List<String> _scamIndicators = [
    'transferir dinheiro',
    'dados bancários',
    'número de cartão',
    'prémio',
    'herança',
    'código de segurança',
    'pin',
    'confirmação de conta',
    'urgente',
    'ganhou',
    'sorteio',
    'clique aqui',
  ];

  // Medical risk indicators
  static const List<String> _medicalRiskKeywords = [
    'dói-me muito',
    'dor intensa',
    'não consigo respirar',
    'dificuldade respiratória',
    'caí',
    'fractura',
    'desmaiei',
    'desmaiada',
    'peito aperta',
    'coração bate mal',
    'vomito',
    'sangue',
  ];

  /// Detects distress in a transcript
  DetectedDistress detectDistress(String transcript) {
    if (transcript.isEmpty) {
      return DetectedDistress(
        isCritical: false,
        isHighSeverity: false,
        isMediumSeverity: false,
        matchedPatterns: [],
        confidence: 0.0,
      );
    }

    // Normalize text for matching
    final normalizedText = _normalizeText(transcript);
    final matchedPatterns = <String>[];

    // Check for critical keywords
    final hasCriticalMatch =
        _checkKeywords(normalizedText, _criticalKeywords, matchedPatterns);

    // Check for high severity
    final hasHighMatch =
        _checkKeywords(normalizedText, _highKeywords, matchedPatterns);

    // Check for medium severity
    final hasMediumMatch =
        _checkKeywords(normalizedText, _mediumKeywords, matchedPatterns);

    // Check for scam indicators
    final hasScamMatch =
        _checkKeywords(normalizedText, _scamIndicators, matchedPatterns);

    // Check for medical risk
    final hasMedicalMatch =
        _checkKeywords(normalizedText, _medicalRiskKeywords, matchedPatterns);

    // Determine severity
    final isCritical = hasCriticalMatch || (hasHighMatch && hasHighMatch);
    final isHighSeverity = hasHighMatch || hasMedicalMatch;
    final isMediumSeverity = hasMediumMatch;

    // Calculate confidence based on number of matches and severity
    double confidence = 0.0;
    if (hasCriticalMatch) confidence = 0.95;
    else if (hasHighMatch && matchedPatterns.length >= 2) confidence = 0.85;
    else if (hasHighMatch) confidence = 0.7;
    else if (isMediumSeverity) confidence = 0.6;
    else if (hasScamMatch) confidence = 0.5;

    // Determine detection category
    String? category;
    if (hasCriticalMatch || hasHighMatch) {
      category = 'suicidal';
    } else if (hasMedicalMatch) {
      category = 'health';
    } else if (hasScamMatch) {
      category = 'scam';
    } else if (isMediumSeverity) {
      category = 'isolation';
    }

    return DetectedDistress(
      isCritical: isCritical,
      isHighSeverity: isHighSeverity,
      isMediumSeverity: isMediumSeverity,
      matchedPatterns: matchedPatterns,
      confidence: confidence,
      detectionCategory: category,
    );
  }

  /// Normalizes text for matching (lowercase, removes accents)
  String _normalizeText(String text) {
    // Remove accents using diacritic package
    final noAccents = removeDiacritics(text);
    return noAccents.toLowerCase();
  }

  /// Checks if any keywords match in text with fuzzy matching
  bool _checkKeywords(
    String text,
    List<String> keywords,
    List<String> matchedPatterns,
  ) {
    bool found = false;

    for (final keyword in keywords) {
      final normalizedKeyword = _normalizeText(keyword);

      // Exact phrase match
      if (text.contains(normalizedKeyword)) {
        matchedPatterns.add(keyword);
        found = true;
        continue;
      }

      // Fuzzy match: check if most characters are present in order
      if (_fuzzyMatch(text, normalizedKeyword)) {
        matchedPatterns.add(keyword);
        found = true;
      }
    }

    return found;
  }

  /// Performs fuzzy matching of keyword in text
  /// Checks if keyword characters appear in order in text
  bool _fuzzyMatch(String text, String keyword) {
    int textIdx = 0;
    int keywordIdx = 0;

    while (textIdx < text.length && keywordIdx < keyword.length) {
      if (text[textIdx] == keyword[keywordIdx]) {
        keywordIdx++;
      }
      textIdx++;
    }

    // Match only if at least 70% of keyword characters are found
    return (keywordIdx / keyword.length) >= 0.7;
  }

  /// Gets distress severity percentage (0-100)
  int getSeverityPercentage(DetectedDistress distress) {
    if (distress.isCritical) {
      return 100;
    }
    if (distress.isHighSeverity) {
      return 75;
    }
    if (distress.isMediumSeverity) {
      return 50;
    }
    return 0;
  }

  /// Gets a summary of detected issues
  String getSummary(DetectedDistress distress) {
    if (distress.matchedPatterns.isEmpty) {
      return 'Nenhum problema detectado';
    }

    final count = distress.matchedPatterns.length;
    final severity = distress.detectionCategory ?? 'desconhecido';

    return '$count indicador(es) de ${_getCategoryLabel(severity)} detectado(s)';
  }

  /// Gets Portuguese label for detection category
  String _getCategoryLabel(String category) {
    switch (category) {
      case 'suicidal':
        return 'risco suicida';
      case 'isolation':
        return 'isolamento';
      case 'health':
        return 'risco de saúde';
      case 'scam':
        return 'possível fraude';
      default:
        return 'risco desconhecido';
    }
  }

  /// Gets recommended immediate response
  String getRecommendedResponse(DetectedDistress distress) {
    if (distress.isCritical) {
      return 'Contacte o 112 (emergência) ou SOS Voz Amiga (213 544 848) imediatamente.';
    }

    if (distress.isHighSeverity) {
      switch (distress.detectionCategory) {
        case 'health':
          return 'Recomendo que fale com o seu médico ou dirija-se a um serviço de urgência.';
        case 'suicidal':
          return 'Percebo que está a sofrer muito. Posso estar aqui para conversar, mas recomendo que fale com SOS Voz Amiga (213 544 848) ou com alguém de confiança.';
        default:
          return 'Está preocupado/a e sozinho/a. Considere contactar a sua família ou amigos.';
      }
    }

    if (distress.isMediumSeverity) {
      switch (distress.detectionCategory) {
        case 'isolation':
          return 'Parece estar triste e isolado/a. Talvez uma conversa com família ou amigos ajudasse.';
        default:
          return 'Estou aqui para conversar consigo sobre o que está a sentir.';
      }
    }

    if (distress.detectionCategory == 'scam') {
      return 'Isto parece uma possível fraude. Não responda a contactos não solicitados e verifique com pessoa de confiança.';
    }

    return '';
  }
}
