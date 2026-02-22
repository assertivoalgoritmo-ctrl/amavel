/// Result of distress detection analysis
class DetectedDistress {
  final bool isCritical;
  final bool isHighSeverity;
  final bool isMediumSeverity;
  final List<String> matchedPatterns;
  final double confidence;
  final String? detectionCategory;

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
    return 'DetectedDistress(critical: $isCritical, high: $isHighSeverity, '
        'medium: $isMediumSeverity, category: $detectionCategory, '
        'patterns: $matchedPatterns)';
  }
}

/// Portuguese keyword and pattern-based distress detection.
/// Phase 1: Expanded with grief, cognitive decline, and proportional detection.
class DistressDetector {
  // ============================================================
  // Critical keywords — suicidal ideation (immediate alert)
  // ============================================================
  static const List<String> _criticalKeywords = [
    'quero morrer',
    'vou-me matar',
    'não vale a pena viver',
    'acabar com tudo',
    'suicídio',
    'matar-me',
    'matava-me',
    'desaparecer para sempre',
    'estar morto',
    'melhor estar morto',
    'ninguém precisa de mim',
    'queria não ter nascido',
    'já não quero estar cá',
    'não quero acordar amanhã',
    'vou fazer uma asneira',
  ];

  // ============================================================
  // High severity — significant emotional distress
  // ============================================================
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
    'vazio por dentro',
    'inútil',
    'peso para os outros',
    'sou um fardo',
    'ninguém vem ver-me',
    'abandonaram-me',
    'estou sempre sozinho',
    'estou sempre sozinha',
    'já não tenho ninguém',
  ];

  // ============================================================
  // Medium severity — sadness and isolation patterns
  // ============================================================
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
    'falta-me energia',
    'já não me apetece nada',
    'não saio de casa',
    'estou cansado de tudo',
    'estou cansada de tudo',
    'dias são todos iguais',
    'não tenho vontade',
  ];

  // ============================================================
  // Grief indicators — recent bereavement
  // ============================================================
  static const List<String> _griefKeywords = [
    'faleceu',
    'morreu',
    'perdi o meu marido',
    'perdi a minha mulher',
    'perdi a minha esposa',
    'ficou viúvo',
    'ficou viúva',
    'faz falta',
    'saudades dele',
    'saudades dela',
    'desde que partiu',
    'desde que morreu',
    'enterro',
    'funeral',
    'não consigo aceitar',
    'a casa está vazia sem',
  ];

  // ============================================================
  // Scam indicators — financial fraud attempts
  // ============================================================
  static const List<String> _scamIndicators = [
    'transferir dinheiro',
    'dados bancários',
    'número de cartão',
    'prémio',
    'herança inesperada',
    'código de segurança',
    'pin do cartão',
    'confirmação de conta',
    'muito urgente',
    'ganhou um prémio',
    'sorteio',
    'clique aqui',
    'príncipe nigeriano',
    'pagamento pendente',
    'conta bloqueada',
    'multibanco',
    'referência de pagamento',
    'enviar código',
    'alguém ligou a pedir',
    'disseram que devo dinheiro',
    'deram-me um número para ligar',
  ];

  // ============================================================
  // Medical risk — urgent health situations
  // ============================================================
  static const List<String> _medicalRiskKeywords = [
    'dói-me muito',
    'dor intensa',
    'não consigo respirar',
    'dificuldade respiratória',
    'caí no chão',
    'caí e não me consigo levantar',
    'fractura',
    'desmaiei',
    'desmaiada',
    'peito aperta',
    'peito dói',
    'coração bate mal',
    'vomito sangue',
    'sangue',
    'tonto',
    'tonta',
    'confuso',
    'confusa',
    'não me lembro de nada',
    'perdi os sentidos',
    'braço dormente',
    'boca torta',
    'não consigo falar bem',
  ];

  // ============================================================
  // Cognitive decline indicators — tracked over time
  // ============================================================
  static const List<String> _cognitiveKeywords = [
    'não me lembro',
    'esqueço-me de tudo',
    'perco-me em casa',
    'não sei que dia é',
    'onde é que eu estou',
    'quem é você',
    'já perguntei isto',
    'como é que vim aqui',
    'não reconheço',
    'esqueci o fogão ligado',
    'deixei a porta aberta',
    'perdi as chaves outra vez',
    'não sei onde pus',
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

    final normalizedText = _normalizeText(transcript);
    final matchedPatterns = <String>[];

    // Check all categories
    final hasCriticalMatch =
        _checkKeywords(normalizedText, _criticalKeywords, matchedPatterns);
    final hasHighMatch =
        _checkKeywords(normalizedText, _highKeywords, matchedPatterns);
    final hasMediumMatch =
        _checkKeywords(normalizedText, _mediumKeywords, matchedPatterns);
    final hasGriefMatch =
        _checkKeywords(normalizedText, _griefKeywords, matchedPatterns);
    final hasScamMatch =
        _checkKeywords(normalizedText, _scamIndicators, matchedPatterns);
    final hasMedicalMatch =
        _checkKeywords(normalizedText, _medicalRiskKeywords, matchedPatterns);
    final hasCognitiveMatch =
        _checkKeywords(normalizedText, _cognitiveKeywords, matchedPatterns);

    // Determine severity levels
    final isCritical = hasCriticalMatch;
    final isHighSeverity = hasHighMatch || hasMedicalMatch;
    final isMediumSeverity = hasMediumMatch || hasGriefMatch || hasCognitiveMatch;

    // Calculate confidence
    double confidence = 0.0;
    if (hasCriticalMatch) {
      confidence = 0.95;
    } else if (hasHighMatch && matchedPatterns.length >= 2) {
      confidence = 0.85;
    } else if (hasMedicalMatch) {
      confidence = 0.85;
    } else if (hasHighMatch) {
      confidence = 0.7;
    } else if (hasScamMatch && matchedPatterns.length >= 2) {
      confidence = 0.8;
    } else if (hasScamMatch) {
      confidence = 0.6;
    } else if (hasGriefMatch) {
      confidence = 0.65;
    } else if (hasCognitiveMatch) {
      confidence = 0.55;
    } else if (isMediumSeverity) {
      confidence = 0.5;
    }

    // Determine primary detection category
    String? category;
    if (hasCriticalMatch) {
      category = 'suicidal';
    } else if (hasMedicalMatch) {
      category = 'health';
    } else if (hasScamMatch) {
      category = 'scam';
    } else if (hasGriefMatch) {
      category = 'grief';
    } else if (hasCognitiveMatch) {
      category = 'cognitive';
    } else if (hasHighMatch || hasMediumMatch) {
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
    return _removeDiacritics(text.toLowerCase());
  }

  /// Removes common Portuguese diacritics without external dependency
  static String _removeDiacritics(String text) {
    const diacritics =
        'àáâãäåèéêëìíîïòóôõöùúûüýñçÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÝÑÇ';
    const replacements =
        'aaaaaaeeeeiiiiooooouuuuyncAAAAAAEEEEIIIIOOOOOUUUUYNC';
    var result = text;
    for (int i = 0; i < diacritics.length; i++) {
      result = result.replaceAll(diacritics[i], replacements[i]);
    }
    return result;
  }

  /// Checks if any keywords match in text
  bool _checkKeywords(
    String text,
    List<String> keywords,
    List<String> matchedPatterns,
  ) {
    bool found = false;

    for (final keyword in keywords) {
      final normalizedKeyword = _normalizeText(keyword);

      // Exact phrase match (primary)
      if (text.contains(normalizedKeyword)) {
        matchedPatterns.add(keyword);
        found = true;
        continue;
      }

      // Fuzzy match for speech-to-text transcription errors
      if (normalizedKeyword.length >= 8 &&
          _fuzzyMatch(text, normalizedKeyword)) {
        matchedPatterns.add(keyword);
        found = true;
      }
    }

    return found;
  }

  /// Performs fuzzy matching — only for longer keywords to reduce false positives
  bool _fuzzyMatch(String text, String keyword) {
    // Split keyword into words and check if most words appear in text
    final keywordWords = keyword.split(' ');
    if (keywordWords.length <= 1) return false;

    int matchedWords = 0;
    for (final word in keywordWords) {
      if (word.length >= 3 && text.contains(word)) {
        matchedWords++;
      }
    }

    // At least 70% of words must match
    return (matchedWords / keywordWords.length) >= 0.7;
  }

  /// Gets distress severity percentage (0-100)
  int getSeverityPercentage(DetectedDistress distress) {
    if (distress.isCritical) return 100;
    if (distress.isHighSeverity) return 75;
    if (distress.isMediumSeverity) return 50;
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
      case 'grief':
        return 'luto recente';
      case 'cognitive':
        return 'possível declínio cognitivo';
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
          return 'Percebo que está a sofrer muito. Posso estar aqui para conversar, '
              'mas recomendo que fale com SOS Voz Amiga (213 544 848) ou com alguém de confiança.';
        default:
          return 'Está preocupado/a. Considere contactar a sua família ou amigos.';
      }
    }

    if (distress.isMediumSeverity) {
      switch (distress.detectionCategory) {
        case 'isolation':
          return 'Parece estar triste e isolado/a. Talvez uma conversa com família ou amigos ajudasse.';
        case 'grief':
          return 'Sei que é uma perda muito difícil. Estou aqui para ouvir.';
        case 'cognitive':
          return 'Não se preocupe, toda a gente se esquece de coisas. Estou aqui para ajudar.';
        default:
          return 'Estou aqui para conversar consigo sobre o que está a sentir.';
      }
    }

    if (distress.detectionCategory == 'scam') {
      return 'Isto parece uma possível fraude. Nunca partilhe dados bancários por telefone. '
          'Fale primeiro com alguém de confiança.';
    }

    return '';
  }
}
