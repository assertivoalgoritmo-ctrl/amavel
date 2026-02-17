import 'package:amavel_app/domain/models/memory_fact.dart';
import 'package:amavel_app/domain/models/user_profile.dart';

class SystemPromptBuilder {
  static const String _basePrompt = '''Tu és o AMAVEL, um assistente de voz dedicado à conversa significativa com pessoas idosas em Portugal.

PERSONALIDADE E PROPÓSITO:
- Nome: AMAVEL (pronuncia-se "A-MA-VEL")
- Papel: Companheiro conversacional atento e empático
- Língua: Português Europeu
- Tom: Caloroso, respeitoso, genuinamente interessado
- Objetivo: Proporcionar companhia, suporte emocional e conversas enriquecedoras

PRINCÍPIOS DE INTERAÇÃO:
1. Empatia Genuína: Compreender emoções subjacentes, não apenas palavras ditas
2. Autenticidade: Ser honesto sobre limitações; não fingir capacidades humanas
3. Respeito Pela Memória: Reconhecer histórias pessoais e valorizá-las
4. Paciência: Deixar conversas desenrolarem-se naturalmente, sem pressa
5. Segurança: Identificar sinais de sofrimento e propor apoio apropriado

PROTOCOLOS DE CONVERSA:
- Cumprimentar pelo nome sempre que possível
- Recordar factos pessoais relevantes de forma natural
- Fazer perguntas abertas que encorajem reflexão
- Validar emoções mesmo quando não se concorda com perspectivas
- Oferecer sugestões úteis (contactar família, atividades, recursos)
- Evitar julgamentos morais

TÓPICOS A ABORDAR COM SENSIBILIDADE:
- Saúde e bem-estar físico
- Histórias de vida e legado
- Relações familiares e amizades
- Preocupações financeiras e práticas
- Espiritualidade e significado de vida
- Atividades prazerosas e passatempos

TÓPICOS A EVITAR:
- Política partidária
- Crítica religiosa
- Conselhos médicos específicos (apenas sugerir consulta profissional)
- Informações financeiras/de investimento
- Recomendações para medicamentos sem receita

QUANDO DETETAR SOFRIMENTO:
1. Escutar atentamente para sinais de depressão, isolamento extremo ou pensamentos suicidas
2. Validar os sentimentos: "Percebo que está a sentir-se muito mal"
3. Nunca minimizar: "Não diga isso, tem tudo para viver"
4. Sugerir contactos úteis (SOS Voz Amiga, família, médico)
5. Oferecer continuar a conversa para apoio imediato

ESTRUTURA DE RESPOSTA:
- Responder em frases naturais, como um amigo
- Usar pronomes pessoais (tu/você conforme preferência)
- Manter conversas fluidas e contextuais
- Reconhecer o que foi dito anteriormente
- Oferecer acompanhamento emocional genuíno

LIMITAÇÕES A COMUNICAR:
- "Não sou um profissional de saúde, mas posso ouvir-vos"
- "Não tenho acesso a serviços de emergência, mas posso-vos ajudar a contactar alguém"
- "A minha memória está limitada, mas estou sempre aqui para conversar"
- "Posso estar errado/a, por isso sempre verificar com pessoas de confiança"

RECURSOS ÚTEIS EM PORTUGAL:
- SOS Voz Amiga (TelefoneAmigo): 213 544 848
- INEM (Emergência): 112
- Centro de Saúde ou Médico Pessoal
- Polícia: 112
- Bombeiros: 112''';

  /// Builds the complete system prompt by injecting user context
  static String buildPrompt({
    UserProfile? user,
    List<MemoryFact>? facts,
  }) {
    final buffer = StringBuffer(_basePrompt);

    // Add user context section if user profile exists
    if (user != null) {
      buffer.writeln('\n\n--- CONTEXTO DO UTILIZADOR ---');
      buffer.writeln('Nome: ${user.displayName ?? "Utilizador"}');

      if (user.dateOfBirth != null) {
        buffer.writeln('Data de Nascimento: ${_formatDate(user.dateOfBirth!)}');
      }

      buffer.writeln('Linguagem Preferida: ${user.language}');
      buffer.writeln(
          'Nome Preferido para o Assistente: ${user.assistantName}');

      // Voice preferences
      buffer.writeln('\nPreferências de Voz:');
      buffer.writeln(
          '- Velocidade: ${user.voicePreferences.speed.toStringAsFixed(1)}x');
      buffer.writeln(
          '- Volume: ${(user.voicePreferences.volume * 100).toStringAsFixed(0)}%');
      buffer.writeln('- Género da Voz: ${user.voicePreferences.voiceGender}');

      // Family members
      if (user.familyMemberIds.isNotEmpty) {
        buffer.writeln('\nMembros da Família Conhecidos:');
        for (int i = 0; i < user.familyMemberIds.length; i++) {
          buffer.writeln('- Contacto ${i + 1}: ${user.familyMemberIds[i]}');
        }
      }
    }

    // Add memory facts section if facts exist
    if (facts != null && facts.isNotEmpty) {
      _addMemoryFactsSection(buffer, facts);
    }

    // Add today's date for awareness
    buffer.writeln('\n\n--- CONTEXTO ATUAL ---');
    buffer.writeln('Data de Hoje: ${_formatDate(DateTime.now())}');
    buffer.writeln('Dia da Semana: ${_getDayOfWeek(DateTime.now())}');

    return buffer.toString();
  }

  /// Adds formatted memory facts to the system prompt
  static void _addMemoryFactsSection(
      StringBuffer buffer, List<MemoryFact> facts) {
    if (facts.isEmpty) return;

    buffer.writeln('\n\n--- FACTOS MEMORÁVEIS SOBRE O UTILIZADOR ---');

    // Group facts by category
    final factsByCategory = <String, List<MemoryFact>>{};
    for (final fact in facts.where((f) => f.isActive)) {
      final category = fact.category;
      factsByCategory.putIfAbsent(category, () => []).add(fact);
    }

    // Format by category with Portuguese labels
    final categoryLabels = {
      'family': 'Família',
      'health': 'Saúde',
      'preference': 'Preferências',
      'schedule': 'Rotina',
      'history': 'História de Vida',
    };

    for (final category in factsByCategory.keys) {
      final label = categoryLabels[category] ?? category;
      buffer.writeln('\n$label:');

      for (final fact in factsByCategory[category]!) {
        final confidence =
            (fact.extractionConfidence * 100).toStringAsFixed(0);
        buffer.writeln('- ${fact.key}: ${fact.value} (confiança: $confidence%)');
      }
    }

    buffer.writeln(
        '\nNota: Use estes factos para personalizar conversas e demonstrar que se importa.');
  }

  /// Formats date in Portuguese format
  static String _formatDate(DateTime date) {
    final monthNames = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro'
    ];

    final day = date.day;
    final month = monthNames[date.month - 1];
    final year = date.year;

    return '$day de $month de $year';
  }

  /// Gets Portuguese day of week name
  static String _getDayOfWeek(DateTime date) {
    const dayNames = [
      'segunda-feira',
      'terça-feira',
      'quarta-feira',
      'quinta-feira',
      'sexta-feira',
      'sábado',
      'domingo'
    ];

    return dayNames[date.weekday - 1];
  }
}
