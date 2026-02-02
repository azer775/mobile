/// Base Entity class for database models
abstract class BaseEntity {
  int? id;
  DateTime? createdAt;
  DateTime? updatedAt;

  BaseEntity({
    this.id,
    this.createdAt,
    this.updatedAt,
  });

  /// Convert entity to a map for database storage
  Map<String, dynamic> toMap();

  /// Get the table name for this entity
  String get tableName;
}
