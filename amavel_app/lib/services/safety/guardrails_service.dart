import 'package:amavel_app/services/safety/distress_detector.dart';

/// Safety analysis result
class SafetyResult {
  final bool isSafe;
  final String severity; // "critical", "high", "medium", "low", "safe"
  final List<String> detectedPatterns;
  final String suggestedAction;
  final List<String> suggestedResources;

  SafetyResult({
    required this.isSafe,
    required this.severity,
    required this.detectedPatterns,
    required this.suggestedAction,
    this.suggestedResources = const [],
  });

  @override
  String toString() {
    return 'SafetyResult(isSafe: $isSafe, severity: $severity, patterns: ${detectedPatterns.length})';
  }
}

/// Main safety service that coordinates topic filtering and distress detection
class GuardrailsService {
  final DistressDetector _distressDetector = DistressDetector();

  /// Analyzes user transcript for safety issues
  SafetyResult analyzeTranscript(String transcript) {
    if (transcript.isEmpty) {
      return SafetyResult(
        isSafe: true,
        severity: 'safe',
        detectedPatterns: [],
        suggestedAction: 'Sem problemas detetados',
      );
    }

    // Run distress detection
    final detectedDistress = _distressDetector.detectDistress(transcript);

    // Evaluate severity and determine response
    final severity = _determineSeverity(detectedDistress);
    final isSafe = severity == 'safe';
    final suggestedAction = _getSuggestedAction(severity, detectedDistress);
    final resources = _getRecommendedResources(severity);

    return SafetyResult(
      isSafe: isSafe,
      severity: severity,
      detectedPatterns: detectedDistress.matchedPatterns,
      suggestedAction: suggestedAction,
      suggestedResources: resources,
    );
  }

  /// Gets the guardrail system prompt section for the LLM
  String getGuardrailSystemPromptSection() {
    return '''

--- PROTOCOLOS DE SEGURANÇA ---

RESPOSTA A SOFRIMENTO:
1. Se o utilizador manifestar ideias suicidas, isolamento extremo, ou desesperança:
   - NUNCA minimize os sentimentos
   - Valide: "Percebo que está a sentir-se muito mal"
   - Sugira: contacto com SOS Voz Amiga (213 544 848), médico, ou família
   - Ofereça: continuar disponível para conversação imediata
   - Mantenha tom empático e sem julgamento

2. Se o utilizador referir sintomas graves (dor intensa, dificuldade respiratória, queda):
   - Recomende contactar 112 (emergência médica)
   - Sugira falar com médico ou ir a urgência
   - Claramente: "Não sou um profissional de saúde"

3. Se o utilizador reclamar isolamento extremo ou falta de apoio:
   - Ofereça conversação regular
   - Sugira contactar família/amigos
   - Recomende atividades sociais se possível
   - Mencione recursos comunitários

SINAIS DE ALERTA A REPORTAR:
- Menção repetida de morte, suicídio, ou "não vale a pena"
- Descrição de isolamento total ("ninguém me liga", "estou sozinho há meses")
- Desesperança profunda ("tudo é sem sentido")
- Mudanças drásticas de comportamento

SCAMS E EXPLORAÇÃO:
- NUNCA solicite ou repita números de cartão de crédito
- NUNCA peça informações bancárias
- Se o utilizador mencionar "prémio", "herança", ou "transferir dinheiro":
  - Avise: "Isto parece uma fraude"
  - Sugira: não responda a contactos não solicitados
  - Recomende: verificar com família ou polícia

LIMITAÇÕES A MANTER:
- Clarificar que não é substituto de profissional de saúde
- Recomendar sempre médico para questões clínicas
- Recomendar psicólogo/psiquiatra para saúde mental
- Alertar para limites de confidencialidade em emergências

TOM SEMPRE:
- Respeitoso e não-julgador
- Empático com sentimentos
- Útil com recursos práticos
- Honesto sobre limitações''';
  }

  /// Determines severity level
  String _determineSeverity(DetectedDistress distress) {
    if (distress.isCritical) {
      return 'critical';
    }
    if (distress.isHighSeverity) {
      return 'high';
    }
    if (distress.isMediumSeverity) {
      return 'medium';
    }
    return 'safe';
  }

  /// Gets suggested action based on severity
  String _getSuggestedAction(
    String severity,
    DetectedDistress distress,
  ) {
    switch (severity) {
      case 'critical':
        return 'ALERTA CRÍTICO: Sinais de pensamento suicida. Contate 112 (emergência) ou SOS Voz Amiga (213 544 848) imediatamente. Mantenha conversa atenta e empática.';
      case 'high':
        return 'Alerta elevado: Sinais de sofrimento significativo. Valide emoções, sugira apoio (SOS Voz Amiga, médico, família). Mantenha disponibilidade para conversa.';
      case 'medium':
        return 'Alerta moderado: Tristeza, isolamento, ou preocupações detectadas. Responda com empatia, sugira atividades ou contacto com rede de apoio.';
      default:
        return 'Sem alertas de segurança detectados. Continue conversa normalmente.';
    }
  }

  /// Gets recommended resources
  List<String> _getRecommendedResources(String severity) {
    final baseResources = [
      'SOS Voz Amiga (TelefoneAmigo): 213 544 848',
      'Linha Nacional de Prevenção do Suicídio: 1 844 (diariamente)',
      'Centro de Saúde local ou Médico pessoal',
    ];

    if (severity == 'critical') {
      return [
        'INEM (Emergência): 112',
        'Polícia Nacional: 112',
        ...baseResources,
      ];
    }

    if (severity == 'high' || severity == 'medium') {
      return baseResources;
    }

    return [];
  }
}
