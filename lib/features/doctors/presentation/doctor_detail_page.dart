import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';
import '../../emergency_limitation/data/emergency_limitation_dto.dart';
import '../../emergency_limitation/presentation/emergency_limitation_providers.dart';
import '../../emergency_limitation/presentation/widgets/emergency_limitation_banner.dart';
import '../../vet_disclaimer/data/vet_disclaimer_dto.dart';
import '../../vet_disclaimer/presentation/vet_disclaimer_providers.dart';
import '../../vet_disclaimer/presentation/widgets/vet_disclaimer_banner.dart';
import '../data/doctor_repository.dart';
import '../../../routing/app_routes.dart';

class DoctorDetailPage extends ConsumerWidget {
  const DoctorDetailPage({super.key, required this.doctorId});

  final String doctorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final doctorAsync = ref.watch(doctorDetailProvider(doctorId));

    ref.watch(emergencyLimitationProvider);
    ref.watch(vetDisclaimerProvider);

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.doctorDetails)),
      body: doctorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (doctor) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                doctor.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (doctor.degreeOrQualification != null) ...[
                const SizedBox(height: 8),
                Text(doctor.degreeOrQualification!),
              ],
              const SizedBox(height: 8),
              Text(doctor.serviceType),
              const SizedBox(height: 8),
              Text(doctor.areaText),
              if (doctor.fee != null) ...[
                const SizedBox(height: 8),
                Text('${l10n.consultationFee}: ${doctor.fee} BDT'),
              ],
              const SizedBox(height: 16),
              Text(
                l10n.availability,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(doctor.availability),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  if (doctor.emergency)
                    Chip(
                      avatar: const Icon(
                        Icons.emergency,
                        size: 16,
                        color: Colors.red,
                      ),
                      label: Text(l10n.emergencyAvailable),
                    ),
                  if (doctor.onlineConsultation)
                    Chip(
                      avatar: const Icon(Icons.video_call, size: 16),
                      label: Text(l10n.onlineConsultation),
                    ),
                  if (doctor.homeVisit)
                    Chip(
                      avatar: const Icon(Icons.home, size: 16),
                      label: Text(l10n.homeVisit),
                    ),
                ],
              ),
              if (doctor.bio != null && doctor.bio!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.aboutDoctor,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(doctor.bio!),
              ],
              if (doctor.experienceYears != null) ...[
                const SizedBox(height: 8),
                Text('${l10n.experienceYears}: ${doctor.experienceYears}'),
              ],
              if (doctor.serviceCategories.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.servicesOffered,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ...doctor.serviceCategories.map(
                  (c) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(c.name),
                  ),
                ),
              ],
              if (doctor.emergency) ...[
                const SizedBox(height: 16),
                const EmergencyLimitationBanner(
                  context: EmergencyLimitationContext.discoveryEmergency,
                ),
                const VetDisclaimerBanner(
                  context: VetDisclaimerContext.bookingEmergency,
                  emergency: true,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () =>
                    context.go(AppRoutes.bookConsultation(doctorId)),
                child: Text(l10n.bookConsultation),
              ),
            ],
          );
        },
      ),
    );
  }
}
