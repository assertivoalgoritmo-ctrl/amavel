import 'dart:convert';
import 'package:amavel_app/data/repositories/memory_repository.dart';
import 'package:amavel_app/domain/models/memory_fact.dart';

/// Memory extraction and retrieval pipeline manager
class MemoryManager {
  final MemoryRepository _repository;

  const MemoryManager(this._repository);

  /// Returns function calling tool definitions for LLM
  List<Map<String, dynamic>> getMemoryTools() {
    return [
      {
        'type': 'function',
        'function': {
          'name': 'store_memory_fact',
          'description':
              'Armazena um facto importante sobre o utilizador para referências futuras em português europeu.',
          'parameters': {
            'type': 'object',
            'properties': {
              'category': {
                'type': 'string',
                'enum': ['family', 'health', 'preference', 'schedule', 'history'],
                'description': 'Categoria do facto (família, saúde, preferência, rotina, história)'
              },
              'key': {
                'type': 'string',
                'description':
                    'Chave identificadora do facto (ex: "nome_filha", "alergia_amendoim")'
              },
              'value': {
                'type': 'string',
                'description': 'Valor descritivo do facto em português'
              },
              'confidence': {
                'type': 'number',
                'description':
                    'Confiança na extração (0.0 a 1.0). Apenas factos com confiança >= 0.7 serão armazenados.',
                'minimum': 0.0,
                'maximum': 1.0
              }
            },
            'required': ['category', 'key', 'value', 'confidence']
          }
        }
      },
      {
        'type': 'function',
        'function': {
          'name': 'get_memory_facts',
          'description':
              'Recupera factos memorizados sobre o utilizador, opcionalmente filtrados por categoria.',
          'parameters': {
            'type': 'object',
            'properties': {
              'category': {
                'type': 'string',
                'enum': ['family', 'health', 'preference', 'schedule', 'history', 'all'],
                'description':
                    'Categoria de factos a recuperar, ou "all" para todos (padrão: all)'
              }
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

      // Validate required fields
      if (category == null || key == null || value == null) {
        return {
          'success': false,
          'error': 'Campos obrigatórios em falta: category, key, value'
        };
      }

      // Validate confidence threshold
      if (confidence < 0.7) {
        return {
          'success': false,
          'error':
              'Confiança insuficiente (${(confidence * 100).toStringAsFixed(0)}%). Limite mínimo: 70%'
        };
      }

      // Validate category
      const validCategories = ['family', 'health', 'preference', 'schedule', 'history'];
      if (!validCategories.contains(category)) {
        return {
          'success': false,
          'error': 'Categoria inválida: $category'
        };
      }

      // Store the fact
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

      // Retrieve facts
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

      // Format facts for response
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
    // Validate confidence threshold
    if (fact.extractionConfidence < 0.7) {
      throw ArgumentError(
          'Confidence must be >= 0.7, got ${fact.extractionConfidence}');
    }

    // Validate category
    const validCategories = ['family', 'health', 'preference', 'schedule', 'history'];
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
