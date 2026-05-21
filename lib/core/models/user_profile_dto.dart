import 'package:json_annotation/json_annotation.dart';

part 'user_profile_dto.g.dart';

/// Example DTO showing json_serializable wiring (run build_runner after edits).
@JsonSerializable()
class UserProfileDto {
  const UserProfileDto({
    required this.id,
    this.displayName,
  });

  final String id;
  final String? displayName;

  factory UserProfileDto.fromJson(Map<String, dynamic> json) =>
      _$UserProfileDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileDtoToJson(this);
}
