/// Base DTO class for API data transfer objects
abstract class BaseDto {
  /// Convert DTO to JSON
  Map<String, dynamic> toJson();

  /// Create DTO from JSON - implement in subclasses
  /// Example: factory UserDto.fromJson(Map<String, dynamic> json) => ...
}
