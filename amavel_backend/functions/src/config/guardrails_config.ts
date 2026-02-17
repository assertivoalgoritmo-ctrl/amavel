/**
 * AMAVEL Guardrails Configuration
 * Keywords and thresholds for alert generation and safety monitoring
 */

export interface GuardrailsConfig {
  distressKeywords: {
    critical: string[];
    high: string[];
    medium: string[];
  };
  scamIndicators: string[];
  medicalRiskKeywords: string[];
  abuseIndicators: string[];
  alertThresholds: {
    criticalFrequency: number; // minutes - trigger alert immediately
    highFrequency: number; // minutes - trigger alert
    mediumFrequency: number; // hours - aggregate to report
  };
  responsePatterns: {
    suicidalThoughts: string;
    selfHarm: string;
    abuse: string;
    financialExploit: string;
  };
}

export const GUARDRAILS_CONFIG: GuardrailsConfig = {
  // Distress keywords in Portuguese
  distressKeywords: {
    critical: [
      "morrer",
      "suicídio",
      "matar a mim mesmo",
      "não quero viver",
      "dar fim",
      "arrancar a vida",
      "machucar a mim",
      "cortar",
      "envenenar",
      "pular",
      "desistir",
      "ninguém me ama",
      "melhor sem mim",
      "todos seriam melhor sem mim",
      "acho que vou morrer",
      "vou me matar",
      "não aguento mais",
      "não consigo respirar",
      "dor no peito",
      "convulsão",
      "derrame",
      "ataque cardíaco",
      "emergência",
      "ligar 190",
      "ligar 192",
      "ambulância agora",
      "estou morrendo",
      "parem de me bater",
      "me agredindo",
      "abuso sexual"
    ],
    high: [
      "deprimido",
      "depressão",
      "ansiedade extrema",
      "pânico",
      "triste demais",
      "desesperado",
      "desespero",
      "angústia",
      "sozinho demais",
      "abandonado",
      "sem esperança",
      "inútil",
      "fracasso",
      "ruim demais",
      "culpa",
      "culpado demais",
      "arrependimento",
      "tremendo",
      "suando frio",
      "tontura",
      "desmaio",
      "confuso",
      "desorientado",
      "esquecimento extremo",
      "queda",
      "ferido",
      "machucado",
      "dor severa",
      "febre alta",
      "vômito",
      "sem comer",
      "sem dormir",
      "pesadelo",
      "alucinação",
      "ouvindo vozes",
      "paranoia",
      "ameaça",
      "amedrontado",
      "assustado demais",
      "estranho em casa",
      "alguém invadiu",
      "robo",
      "roubo",
      "assalto"
    ],
    medium: [
      "triste",
      "choro",
      "chorando",
      "cansado",
      "esgotado",
      "isolado",
      "solitário",
      "aborrecido",
      "frustrado",
      "irritado",
      "raiva",
      "preocupado",
      "nervoso",
      "tenso",
      "estresse",
      "dor",
      "dolorido",
      "cansaço",
      "fraco",
      "dormindo mal",
      "insônia",
      "perdi a chave",
      "perdi os óculos",
      "perdi o dinheiro",
      "dor de cabeça",
      "tosse",
      "resfriado",
      "gripe",
      "febre",
      "infecção",
      "queda recente",
      "esqueci de tomar medicamento",
      "medicamento vencido",
      "confusão mental",
      "esquecer o dia",
      "desligar",
      "nublado",
      "neblina mental"
    ]
  },

  // Scam and exploitation indicators in Portuguese
  scamIndicators: [
    "você ganhou",
    "prêmio de loteria",
    "você foi selecionado",
    "clique aqui para reclamar",
    "confirme seu banco",
    "confirme sua conta",
    "confirme sua senha",
    "código de segurança",
    "número do cartão",
    "código CVC",
    "dados bancários",
    "transferência bancária",
    "conta bancária",
    "número da conta",
    "agência",
    "enviou dinheiro",
    "preciso de dinheiro urgente",
    "envie dinheiro para",
    "PIX para",
    "depósito em conta",
    "cartão de crédito",
    "empréstimo rápido",
    "juros baixíssimos",
    "oportunidade de ouro",
    "você deve dinheiro",
    "multa urgente",
    "pagamento imediato",
    "link para confirmar",
    "link suspeito",
    "anexo importante",
    "abra este arquivo",
    "instale este programa",
    "seu computador está infectado",
    "sua conta foi hackeada",
    "ativar conta",
    "ativar serviço",
    "apenas para você",
    "oferta expirada",
    "válido por 24 horas",
    "não conte a ninguém",
    "mantenha em segredo",
    "sua família precisa",
    "seu neto está em apuros",
    "é confidencial",
    "golpe do neto",
    "golpe da herança",
    "golpe da falsa autoridade"
  ],

  // Medical risk keywords in Portuguese
  medicalRiskKeywords: [
    "pressure alta",
    "hipertensão",
    "diabete",
    "diabetes",
    "açúcar alta",
    "colesterol alto",
    "infarto",
    "coração fraco",
    "artrite severa",
    "osteoporose avançada",
    "Parkinson",
    "Alzheimer",
    "demência",
    "derrame",
    "acidente vascular",
    "pulso irregular",
    "arritmia",
    "falta de ar",
    "asma severa",
    "DPOC",
    "tosse crônica",
    "sangue na urina",
    "sangue nas fezes",
    "sangue no escarro",
    "perda de consciência",
    "desmaio",
    "convulsão",
    "tremores",
    "visão turva",
    "perda de visão",
    "surdez súbita",
    "zumbido severo",
    "paralisia",
    "fraqueza muscular",
    "edema",
    "inchaço",
    "úlcera",
    "infecção severa",
    "ferida que não cicatriza",
    "sangramento",
    "dor abdominal severa",
    "dor torácica",
    "suor frio",
    "palidez",
    "cianose",
    "jã tentei suicídio",
    "estou com câncer",
    "diagnóstico terminal",
    "medicação errada",
    "reação alérgica",
    "anafilaxia"
  ],

  // Abuse and exploitation indicators in Portuguese
  abuseIndicators: [
    "me bate",
    "me empurra",
    "me agride",
    "violência",
    "xinga muito",
    "coloca na cama",
    "não deixa sair",
    "tranca a porta",
    "tira meu dinheiro",
    "pega minha pensão",
    "pega meu cartão",
    "me obriga",
    "me força",
    "sem consentimento",
    "toca sem permissão",
    "toca privado",
    "abuso sexual",
    "estupro",
    "incesto",
    "não deixa comer",
    "não deixa ir ao médico",
    "esconde medicamento",
    "insulto",
    "humilhação",
    "ameaça",
    "intimida",
    "controla tudo",
    "isolado",
    "não deixa ver gente",
    "não deixa falar",
    "não posso sair",
    "preso em casa",
    "refém",
    "escravizado",
    "trabalho forçado",
    "exploração",
    "negligência",
    "não cuida bem",
    "esquecimento proposital",
    "falta de higiene",
    "fome",
    "frio"
  ],

  // Alert thresholds
  alertThresholds: {
    criticalFrequency: 0, // Trigger immediately
    highFrequency: 60, // Within 1 hour
    mediumFrequency: 24 * 60 // Within 24 hours
  },

  // Response patterns for guardrail triggers
  responsePatterns: {
    suicidalThoughts: `Ouço que você está passando por um momento muito difícil. Sua vida é importante e valiosa.

Por favor, conte a alguém de confiança imediatamente - sua família, um amigo próximo ou um profissional.

Se está em perigo imediato:
- Ligue para 188 (Centro de Valorização da Vida) disponível 24/7
- Ou ligue para 192 (Ambulância/SAMU)
- Ou vá ao pronto-socorro mais próximo

Vou avisar imediatamente para sua família para que possam estar com você.`,

    selfHarm: `Percebo que você está pensando em se machucar. Isso preocupa muito comigo.

Você merece ajuda profissional e apoio:
- Fale com sua família imediatamente
- Ligue para 188 (disponível 24 horas)
- Procure o pronto-socorro se estiver em risco imediato

Vou avisar sua família agora mesmo. Você não está sozinho.`,

    abuse: `Estou muito preocupado com o que você está descrevendo. O que está acontecendo não é aceitável.

Você tem direito à segurança e proteção:
- Conte a alguém de confiança - família, amigo ou vizinho
- Ligue para 190 (Polícia) se está em perigo imediato
- Ligue para 180 (Disque Denúncia) para denunciar abuso
- Procure assistência social ou abrigo se necessário

Vou notificar sua família para que possam ajudar. Você não merece isso.`,

    financialExploit: `Estou preocupado que você possa estar sendo enganado ou manipulado financeiramente.

Antes de fazer qualquer transferência ou compartilhar dados:
- Converse com um membro da família de confiança
- Nunca compartilhe senhas, cartão ou dados bancários
- Se já foi enganado, procure orientação imediatamente

Vou informar sua família para que possam revisar e ajudar. Você não está sozinho.`
  }
};

// Helper function to check alert severity
export function checkAlertSeverity(message: string): 'critical' | 'high' | 'medium' | 'low' {
  const lowerMessage = message.toLowerCase();

  const criticalMatches = GUARDRAILS_CONFIG.distressKeywords.critical.filter(
    keyword => lowerMessage.includes(keyword)
  );
  if (criticalMatches.length > 0) {
    return 'critical';
  }

  const highMatches = GUARDRAILS_CONFIG.distressKeywords.high.filter(
    keyword => lowerMessage.includes(keyword)
  );
  if (highMatches.length > 0) {
    return 'high';
  }

  const mediumMatches = GUARDRAILS_CONFIG.distressKeywords.medium.filter(
    keyword => lowerMessage.includes(keyword)
  );
  if (mediumMatches.length > 0) {
    return 'medium';
  }

  return 'low';
}

// Helper function to check for scam indicators
export function detectScamIndicators(message: string): boolean {
  const lowerMessage = message.toLowerCase();
  return GUARDRAILS_CONFIG.scamIndicators.some(indicator =>
    lowerMessage.includes(indicator)
  );
}

// Helper function to check for medical risks
export function detectMedicalRisks(message: string): boolean {
  const lowerMessage = message.toLowerCase();
  return GUARDRAILS_CONFIG.medicalRiskKeywords.some(keyword =>
    lowerMessage.includes(keyword)
  );
}

// Helper function to check for abuse indicators
export function detectAbuseIndicators(message: string): boolean {
  const lowerMessage = message.toLowerCase();
  return GUARDRAILS_CONFIG.abuseIndicators.some(indicator =>
    lowerMessage.includes(indicator)
  );
}

export default GUARDRAILS_CONFIG;
