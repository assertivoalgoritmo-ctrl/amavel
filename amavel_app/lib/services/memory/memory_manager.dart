import 'dart:convert';
import 'package:amavel_app/data/repositories/memory_repository.dart';
import 'package:amavel_app/domain/models/memory_fact.dart';

/// Memory extraction and retrieval pipeline manager.
/// Phase 1: Expanded to 8 categories for richer personalization.
class MemoryManager {
  final MemoryRepository _repository;

  const MemoryManager(this._repository);

  /// Valid memory categories — Phase 1 expanded set
  static const validCategories = [
    'family',     // nomes, relações, idades, localização de familiares
    'health',     // condições, medicações, sono, mobilidade
    'interest',   // desporto, música, TV, hobbies, alimentação
    'routine',    // padrões diários, horários, passeios
    'history',    // histórias de vida, carreira, terra natal
    'social',     // frequência de contacto, visitas, chamadas
    'emotion',    // temas emocionais recorrentes
    'preference', // preferências de conversa, humor, tópicos a evitar
  ];

  /// Returns function calling tool definitions for OpenAI Realtime API.
  /// NOTE: Realtime API uses FLAT format (name/description/parameters at top level),
  /// NOT the nested Chat Completions format.
  List<Map<String, dynamic>> getMemoryTools() {
    return [
      {
        'type': 'function',
        'name': 'store_memory_fact',
        'description':
            'Armazena um facto importante sobre o utilizador para referências futuras. '
            'Usa sempre que o utilizador partilhar informação pessoal significativa: '
            'nomes de família, interesses, rotinas, histórias, emoções ou preferências. '
            'Guarda em português europeu.',
        'parameters': {
          'type': 'object',
          'properties': {
            'category': {
              'type': 'string',
              'enum': validCategories,
              'description':
                  'Categoria do facto: family (família), health (saúde), '
                  'interest (interesses/hobbies), routine (rotinas diárias), '
                  'history (história de vida), social (contacto social), '
                  'emotion (padrões emocionais), preference (preferências de conversa)'
            },
            'key': {
              'type': 'string',
              'description':
                  'Chave identificadora descritiva do facto. Exemplos: '
                  '"nome_filha", "equipa_futebol", "hora_almoco", '
                  '"terra_natal", "visita_filha_frequencia", '
                  '"sentimento_solidao_recorrente", "prefere_conversas_curtas"'
            },
            'value': {
              'type': 'string',
              'description': 'Valor descritivo do facto em português europeu'
            },
            'confidence': {
              'type': 'number',
              'description':
                  'Confiança na extração (0.0 a 1.0). '
                  'Usa 0.9+ para afirmações explícitas ("A minha filha chama-se Maria"). '
                  'Usa 0.7-0.9 para inferências razoáveis. '
                  'Apenas factos com confiança >= 0.7 serão armazenados.',
              'minimum': 0.0,
              'maximum': 1.0
            }
          },
          'required': ['category', 'key', 'value', 'confidence']
        }
      },
      {
        'type': 'function',
        'name': 'get_memory_facts',
        'description':
            'Recupera factos memorizados sobre o utilizador. '
            'Usa no início de cada conversa para personalizar a interação, '
            'e sempre que quiseres referir algo que o utilizador já partilhou.',
        'parameters': {
          'type': 'object',
          'properties': {
            'category': {
              'type': 'string',
              'enum': [...validCategories, 'all'],
              'description':
                  'Categoria de factos a recuperar, ou "all" para todos. '
                  'Default: "all"'
            }
          }
        }
      }
    ];
  }

  /// Processes function calls from the LLM
  Future<Map<String, dynamic>> handleFunctionCall(
    String name,
    String arguments,
  ) async {
    try {
      final args = jsonDecode(arguments) as Map<String, dynamic>;

      if (name == 'store_memory_fact') {
        return await _handleStoreMemoryFact(args);
      } else if (name == 'get_memory_facts') {
        return await _handleGetMemoryFacts(args);
      }

      return {
        'success': false,
        'error': 'Função desconhecida: $name'
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro ao processar função: $e'
      };
    }
  }

  /// Handles store_memory_fact function call
  Future<Map<String, dynamic>> _handleStoreMemoryFact(
      Map<String, dynamic> args) async {
    try {
      final category = args['category'] as String?;
      final key = args['key'] as String?;
      final value = args['value'] as String?;
      final confidence = (args['confidence'] as num?)?.toDouble() ?? 0.0;

      if (category == null || key == null || value == null) {
        return {
          'success': false,
          'error': 'Campos obrigatórios em falta: category, key, value'
        };
      }

      if (confidence < 0.7) {
        return {
          'success': false,
          'error':
              'Confiança insuficiente (${(confidence * 100).toStringAsFixed(0)}%). Limite mínimo: 70%'
        };
      }

      if (!validCategories.contains(category)) {
        return {
          'success': false,
          'error': 'Categoria inválida: $category'
        };
      }

      await _repository.storeFact(
        category: category,
        key: key,
        value: value,
        extractionConfidence: confidence,
      );

      return {
        'success': true,
        'message': 'Facto armazenado com sucesso: $key = $value'
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro ao armazenar facto: $e'
      };
    }
  }

  /// Handles get_memory_facts function call
  Future<Map<String, dynamic>> _handleGetMemoryFacts(
      Map<String, dynamic> args) async {
    try {
      final category = args['category'] as String? ?? 'all';

      final facts = await _repository.getFactsForUser(
        category: category != 'all' ? category : null,
      );

      if (facts.isEmpty) {
        return {
          'success': true,
          'facts': [],
          'message': 'Nenhum facto memorizado encontrado'
        };
      }

      final formattedFacts = facts
          .where((f) => f.isActive)
          .map((f) => {
                'category': f.category,
                'key': f.key,
                'value': f.value,
                'confidence': f.extractionConfidence,
                'lastUpdated': f.lastUpdatedAt.toIso8601String(),
              })
          .toList();

      return {
        'success': true,
        'count': formattedFacts.length,
        'facts': formattedFacts
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro ao recuperar factos: $e'
      };
    }
  }

  /// Retrieves facts for system prompt injection
  Future<List<MemoryFact>> getFactsForPrompt(String userId) async {
    try {
      return await _repository.getFactsForUser();
    } catch (e) {
      print('Erro ao recuperar factos para prompt: $e');
      return [];
    }
  }

  /// Stores a new fact with validation
  Future<void> storeFact(MemoryFact fact) async {
    if (fact.extractionConfidence < 0.7) {
      throw ArgumentError(
          'Confidence must be >= 0.7, got ${fact.extractionConfidence}');
    }

    if (!validCategories.contains(fact.category)) {
      throw ArgumentError('Invalid category: ${fact.category}');
    }

    await _repository.storeFact(
      category: fact.category,
      key: fact.key,
      value: fact.value,
      extractionConfidence: fact.extractionConfidence,
    );
  }
}
