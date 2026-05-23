import '../../profile/data/mobile_me_dto.dart';
import 'farm_location.dart';

class FarmValidation {
  FarmValidation._();

  static String? validateName(String value, {required String requiredMessage}) {
    if (value.trim().isEmpty) return requiredMessage;
    if (value.trim().length < 2) return requiredMessage;
    return null;
  }

  /// Requires full hierarchy through union. Village id or name is optional.
  static String? validateLocation(
    MobileMeAddressDto? address, {
    required String hierarchyMessage,
  }) {
    final location = FarmLocation.fromAddress(address);
    if (!location.canSaveFarm) return hierarchyMessage;
    return null;
  }

  @Deprecated('Use validateLocation — union required, village optional')
  static String? validateVillage(
    String? villageId, {
    required String requiredMessage,
  }) {
    if (villageId == null || villageId.trim().isEmpty) return requiredMessage;
    return null;
  }
}
