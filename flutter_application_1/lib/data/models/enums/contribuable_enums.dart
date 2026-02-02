/// Type of NIF (Tax Identification Number)
enum TypeNif {
  dgi('DGI'),
  provisoire('PROVISOIRE');

  final String value;
  const TypeNif(this.value);

  static TypeNif? fromString(String? value) {
    if (value == null) return null;
    return TypeNif.values.firstWhere(
      (e) => e.value == value.toUpperCase(),
      orElse: () => TypeNif.dgi,
    );
  }
}

/// Type of taxpayer
enum TypeContribuable {
  physique('PHYSIQUE'),
  morale('MORALE'),
  informel('INFORMEL');

  final String value;
  const TypeContribuable(this.value);

  static TypeContribuable fromString(String value) {
    return TypeContribuable.values.firstWhere(
      (e) => e.value == value.toUpperCase(),
      orElse: () => TypeContribuable.physique,
    );
  }

  String get displayName {
    switch (this) {
      case TypeContribuable.physique:
        return 'Personne Physique';
      case TypeContribuable.morale:
        return 'Personne Morale';
      case TypeContribuable.informel:
        return 'Informel';
    }
  }
}

/// Origin of the taxpayer file
enum OrigineFiche {
  recensement('RECENSEMENT'),
  bureau('BUREAU'),
  import_('IMPORT');

  final String value;
  const OrigineFiche(this.value);

  static OrigineFiche fromString(String value) {
    return OrigineFiche.values.firstWhere(
      (e) => e.value == value.toUpperCase(),
      orElse: () => OrigineFiche.bureau,
    );
  }

  String get displayName {
    switch (this) {
      case OrigineFiche.recensement:
        return 'Recensement';
      case OrigineFiche.bureau:
        return 'Bureau';
      case OrigineFiche.import_:
        return 'Import';
    }
  }
}
