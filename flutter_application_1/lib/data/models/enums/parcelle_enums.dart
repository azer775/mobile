enum StatutParcelle {
  bati(value: 'Bâti'),
  nonBati(value: 'Non bâti');

  final String value;
  const StatutParcelle({required this.value});

  static StatutParcelle fromString(String? value) {
    if (value == null) return StatutParcelle.bati;
    return StatutParcelle.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => StatutParcelle.bati,
    );
  }
}

enum RangParcelle {
  premier(value: '1er'),
  deuxieme(value: '2ème'),
  troisieme(value: '3ème'),
  quatrieme(value: '4ème');

  final String value;
  const RangParcelle({required this.value});

  static RangParcelle fromString(String? value) {
    if (value == null) return RangParcelle.premier;
    return RangParcelle.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => RangParcelle.premier,
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
  publique(value: 'publique'),
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

enum TypeContribuable {
  physique(value: 'physique'),
  morale(value: 'morale');

  final String value;
  const TypeContribuable({required this.value});

  static TypeContribuable fromString(String? value) {
    if (value == null) return TypeContribuable.physique;
    return TypeContribuable.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => TypeContribuable.physique,
    );
  }
}

enum TypeUnite {
  appartement(value: 'Appartement'),
  bureau(value: 'Bureau'),
  commerce(value: 'Commerce'),
  entrepot(value: 'Entrepôt');

  final String value;
  const TypeUnite({required this.value});

  static TypeUnite fromString(String? value) {
    if (value == null) return TypeUnite.appartement;
    return TypeUnite.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => TypeUnite.appartement,
    );
  }
}