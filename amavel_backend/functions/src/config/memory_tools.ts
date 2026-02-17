/**
 * Memory Tools Configuration
 * Tool schemas for Claude to store and retrieve memory facts
 */

export interface ToolDefinition {
  name: string;
  description: string;
  input_schema: {
    type: string;
    properties: Record<string, any>;
    required: string[];
  };
}

export const MEMORY_TOOLS: ToolDefinition[] = [
  {
    name: 'store_memory_fact',
    description: `Armazena um fato importante sobre a pessoa para memória futura. Use esta ferramenta quando a pessoa mencionar algo que você deve lembrar, como:
    - Nomes de familiares, amigos ou pets
    - Datas importantes (aniversários, casamentos, eventos)
    - Preferências e gostos (comida, cores, atividades)
    - Histórias pessoais e experiências
    - Medicamentos e condições de saúde
    - Rotinas e horários
    - Preocupações e medos
    - Alegrias e momentos felizes

    Exemplos: "Sua filha se chama Maria", "Você ama xadrez", "Toma pressão alta"`,

    input_schema: {
      type: 'object',
      properties: {
        category: {
          type: 'string',
          enum: [
            'family',
            'health',
            'preferences',
            'stories',
            'important_dates',
            'routines',
            'concerns',
            'likes',
            'dislikes',
            'skills',
            'interests',
            'living_situation',
            'other'
          ],
          description: 'Categoria do fato a armazenar'
        },
        fact: {
          type: 'string',
          description: 'O fato em si, em linguagem clara e direta'
        },
        context: {
          type: 'string',
          description: 'Contexto adicional sobre como você aprendeu este fato (opcional)'
        },
        importance: {
          type: 'string',
          enum: ['high', 'medium', 'low'],
          description: 'Quão importante é este fato para as próximas conversas'
        }
      },
      required: ['category', 'fact', 'importance']
    }
  },

  {
    name: 'get_memory_facts',
    description: `Recupera fatos armazenados sobre a pessoa de categorias específicas. Use isto para contextualizar conversas e mostrar que você lembra de informações prévias.

    Exemplos de uso:
    - Recuperar nomes de familiares quando a pessoa menciona "minha filha"
    - Recuperar medicamentos quando perguntam sobre saúde
    - Recuperar datas importantes para aniversários próximos
    - Recuperar histórias pessoais para continuar conversas anteriores`,

    input_schema: {
      type: 'object',
      properties: {
        categories: {
          type: 'array',
          items: {
            type: 'string',
            enum: [
              'family',
              'health',
              'preferences',
              'stories',
              'important_dates',
              'routines',
              'concerns',
              'likes',
              'dislikes',
              'skills',
              'interests',
              'living_situation',
              'other'
            ]
          },
          description: 'Categorias de fatos a recuperar'
        },
        limit: {
          type: 'number',
          description: 'Número máximo de fatos a retornar (padrão: 10)'
        }
      },
      required: ['categories']
    }
  }
];

/**
 * Memory fact structure stored in Firestore
 */
export interface MemoryFact {
  id?: string;
  category:
    | 'family'
    | 'health'
    | 'preferences'
    | 'stories'
    | 'important_dates'
    | 'routines'
    | 'concerns'
    | 'likes'
    | 'dislikes'
    | 'skills'
    | 'interests'
    | 'living_situation'
    | 'other';
  fact: string;
  context?: string;
  importance: 'high' | 'medium' | 'low';
  createdAt?: Date;
  updatedAt?: Date;
  conversationId?: string;
}

/**
 * Helper to format memory facts for Claude context
 */
export function formatMemoryFacts(facts: MemoryFact[]): string {
  if (facts.length === 0) {
    return 'Nenhum fato memorizado ainda.';
  }

  const grouped: Record<string, MemoryFact[]> = {};
  facts.forEach(fact => {
    if (!grouped[fact.category]) {
      grouped[fact.category] = [];
    }
    grouped[fact.category].push(fact);
  });

  let formatted = 'Fatos memorados sobre a pessoa:\n\n';

  const categoryLabels: Record<string, string> = {
    family: 'Família',
    health: 'Saúde',
    preferences: 'Preferências',
    stories: 'Histórias Pessoais',
    important_dates: 'Datas Importantes',
    routines: 'Rotinas',
    concerns: 'Preocupações',
    likes: 'Gostos',
    dislikes: 'Desgostos',
    skills: 'Habilidades',
    interests: 'Interesses',
    living_situation: 'Situação de Vida',
    other: 'Outros'
  };

  Object.keys(grouped).forEach(category => {
    const label = categoryLabels[category] || category;
    formatted += `${label}:\n`;
    grouped[category].forEach(fact => {
      formatted += `  - ${fact.fact}\n`;
    });
    formatted += '\n';
  });

  return formatted;
}

export default MEMORY_TOOLS;
