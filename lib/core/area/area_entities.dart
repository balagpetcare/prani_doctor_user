import 'area_dto.dart';
import 'area_repository_contract.dart';

/// Domain entity aliases — immutable DTOs shared across hierarchy levels.
typedef Division = AreaNodeDto;
typedef District = AreaNodeDto;
typedef Upazila = AreaNodeDto;
typedef Union = AreaNodeDto;
typedef Village = AreaNodeDto;

/// Repository alias for location module documentation.
typedef LocationRepositoryContract = AreaRepositoryContract;

/// Result wrapper for hierarchy fetches (data + cache metadata).
class AreaLevelResult {
  const AreaLevelResult({
    required this.nodes,
    this.fromCache = false,
    this.isEmpty = false,
  });

  final List<AreaNodeDto> nodes;
  final bool fromCache;
  final bool isEmpty;

  static const empty = AreaLevelResult(nodes: [], isEmpty: true);
}
