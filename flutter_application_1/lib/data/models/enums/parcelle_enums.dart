enum StatutParcelle {
  active(value: 'active'),
  fusionnee(value: 'fusionnée'),
  subdivisee(value: 'subdivisée'),
  archivee(value: 'archivée');

  final String value;
  const StatutParcelle({required this.value});

  static StatutParcelle fromString(String? value) {
    if (value == null) return StatutParcelle.active;
    return StatutParcelle.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => StatutParcelle.active,
    );
  }
}

enum TypeBatiment {
  maison(value: 'maison'),
  immeuble(value: 'immeuble'),
  entrepot(value: 'entrepôt'),
  commerce(value: 'commerce'),
  bureau(value: 'bureau'),
  autre(value: 'autre');

  final String value;
  const TypeBatiment({required this.value});

  static TypeBatiment fromString(String? value) {
    if (value == null) return TypeBatiment.autre;
    return TypeBatiment.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => TypeBatiment.autre,
    );
  }
}

enum UsagePrincipal {
  residentiel(value: 'résidentiel'),
  commercial(value: 'commercial'),
  mixte(value: 'mixte'),
  autre(value: 'autre');

  final String value;
  const UsagePrincipal({required this.value});

  static UsagePrincipal fromString(String? value) {
    if (value == null) return UsagePrincipal.autre;
    return UsagePrincipal.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => UsagePrincipal.autre,
    );
  }
}

enum StatutBatiment {
  enService(value: 'en service'),
  enRuine(value: 'en ruine'),
  enChantier(value: 'en chantier'),
  autre(value: 'autre');

  final String value;
  const StatutBatiment({required this.value});

  static StatutBatiment fromString(String? value) {
    if (value == null) return StatutBatiment.autre;
    return StatutBatiment.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => StatutBatiment.autre,
    );
  }
}

enum TypePersonne {
  physique(value: 'physique'),
  morale(value: 'morale');

  final String value;
  const TypePersonne({required this.value});

  static TypePersonne fromString(String? value) {
    if (value == null) return TypePersonne.physique;
    return TypePersonne.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => TypePersonne.physique,
    );
  }
}