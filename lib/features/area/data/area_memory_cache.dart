import '../../../core/area/area_dto.dart';

/// In-session memory cache for area hierarchy lists.
class AreaMemoryCache {
  final Map<String, List<AreaNodeDto>> _lists = {};
  final Map<String, Future<AreaPage<AreaNodeDto>>> _inFlight = {};

  List<AreaNodeDto>? read(String key) => _lists[key];

  void write(String key, List<AreaNodeDto> nodes) {
    _lists[key] = nodes;
  }

  Future<AreaPage<AreaNodeDto>>? inFlight(String key) => _inFlight[key];

  void track(String key, Future<AreaPage<AreaNodeDto>> future) {
    _inFlight[key] = future;
    future.whenComplete(() => _inFlight.remove(key));
  }

  void warm(String key, List<AreaNodeDto> nodes) => write(key, nodes);
}
