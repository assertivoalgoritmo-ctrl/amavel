/// AMAVEL assistant identity configuration
class AssistantIdentity {
  final String name;
  final String pronunciation; // IPA or phonetic representation
  final String? futureHumanName; // Name if/when assistant becomes embodied
  final String description;
  final String language; // e.g., "pt-PT"

  const AssistantIdentity({
    this.name = 'AMAVEL',
    this.pronunciation = 'ɐ.mɐ.ˈvɛl',
    this.futureHumanName = 'Amélia',
    this.description = 'Assistant for meaningful conversations with elderly in Portugal',
    this.language = 'pt-PT',
  });

  /// Gets the full introduction in Portuguese
  String get introducationPortuguese {
    return 'Olá! Sou o AMAVEL, seu companheiro conversacional. Estou aqui para conversar consigo e proporcionar-lhe companhia significativa.';
  }

  /// Gets pronunciation guide
  String get pronunciationGuide {
    return 'Pronuncia-se: $pronunciation';
  }

  @override
  String toString() {
    return 'AssistantIdentity(name: $name, language: $language)';
  }
}

/// Default AMAVEL identity instance
const amavelIdentity = AssistantIdentity();
