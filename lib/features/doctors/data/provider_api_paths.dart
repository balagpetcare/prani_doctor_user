abstract final class ProviderApiPaths {
  ProviderApiPaths._();

  static const doctors = '/api/mobile/providers/doctors';
  static String doctor(String id) => '/api/mobile/providers/doctors/$id';
}
/// Matches backend `ServiceRequestType` for doctor flows.
abstract final class DoctorServiceTypes {
  DoctorServiceTypes._();

  static const homeVisit = 'DOCTOR_HOME_VISIT';
  static const emergency = 'EMERGENCY_DOCTOR';
  static const onlineConsultation = 'ONLINE_CONSULTATION_LATER';
}

abstract final class DoctorCategorySlugs {
  DoctorCategorySlugs._();

  static const homeVisit = 'doctor-visit';
  static const emergency = 'emergency';
  static const onlineConsultation = 'online-consultation';
}
