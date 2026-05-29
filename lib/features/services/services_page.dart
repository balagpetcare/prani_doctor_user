import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/layout/shell_page_padding.dart';
import '../../../core/branding/brand_assets.dart';
import '../../../core/branding/brand_image.dart';
import '../area/presentation/area_picker.dart';
import '../doctors/data/doctor_repository.dart';
import '../doctors/data/provider_dto.dart';
import '../../../routing/app_routes.dart';
import '../emergency_limitation/data/emergency_limitation_dto.dart';
import '../emergency_limitation/presentation/emergency_limitation_providers.dart';
import '../emergency_limitation/presentation/widgets/emergency_limitation_banner.dart';

class ServicesPage extends ConsumerStatefulWidget {
  const ServicesPage({super.key});

  @override
  ConsumerState<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends ConsumerState<ServicesPage> {
  String? _locationLabel;

  void _applyFilters(DoctorDiscoveryFilters filters) {
    ref.read(doctorDiscoveryFiltersProvider.notifier).state = filters;
    ref.invalidate(doctorListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filters = ref.watch(doctorDiscoveryFiltersProvider);
    final doctorsAsync = ref.watch(doctorListProvider);

    ref.watch(emergencyLimitationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: ShellPagePadding.page(context),
          child: Text(
            l10n.findDoctors,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        if (filters.emergencyOnly) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: EmergencyLimitationBanner(
              context: EmergencyLimitationContext.discoveryEmergency,
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: Text(l10n.filterEmergency),
                selected: filters.emergencyOnly,
                onSelected: (v) =>
                    _applyFilters(filters.copyWith(emergencyOnly: v)),
              ),
              FilterChip(
                label: Text(l10n.filterOnline),
                selected: filters.onlineOnly,
                onSelected: (v) =>
                    _applyFilters(filters.copyWith(onlineOnly: v)),
              ),
              FilterChip(
                label: Text(l10n.filterHomeVisit),
                selected: filters.homeVisitOnly,
                onSelected: (v) =>
                    _applyFilters(filters.copyWith(homeVisitOnly: v)),
              ),
            ],
          ),
        ),
        ExpansionTile(
          title: Text(l10n.filterByArea),
          subtitle: _locationLabel != null ? Text(_locationLabel!) : null,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: AreaPicker(
                divisionLabel: l10n.divisionLabel,
                districtLabel: l10n.districtLabel,
                upazilaLabel: l10n.upazilaLabel,
                unionLabel: l10n.unionLabel,
                villageLabel: l10n.villageLabel,
                onChanged:
                    ({
                      divisionId,
                      districtId,
                      upazilaId,
                      unionId,
                      villageId,
                      villageName,
                      selectedLabel,
                    }) {
                      setState(() {
                        _locationLabel = selectedLabel;
                      });
                      _applyFilters(
                        filters.copyWith(
                          villageId: villageId,
                          locationLabel: selectedLabel,
                          clearLocation: selectedLabel == null,
                        ),
                      );
                    },
              ),
            ),
          ],
        ),
        Expanded(
          child: doctorsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (result) {
              if (result.doctors.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const BrandImage(
                          asset: BrandAssets.homeEmptyDoctors,
                          height: 160,
                          fit: BoxFit.contain,
                          fallbackIcon: Icons.person_search_outlined,
                        ),
                        const SizedBox(height: 16),
                        Text(l10n.noDoctorsFound, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(doctorListProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: result.doctors.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doctor = result.doctors[index];
                    return _DoctorCard(
                      doctor: doctor,
                      onTap: () =>
                          context.go(AppRoutes.doctorDetail(doctor.id)),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({required this.doctor, required this.onTap});

  final ProviderDoctorListItemDto doctor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(doctor.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (doctor.degreeOrQualification != null)
              Text(doctor.degreeOrQualification!),
            Text(doctor.serviceType),
            Text(doctor.areaText),
            if (doctor.fee != null) Text('Fee: ${doctor.fee} BDT'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (doctor.emergency)
              const Icon(Icons.emergency, color: Colors.red, size: 18),
            if (doctor.onlineConsultation)
              const Icon(Icons.video_call, size: 18),
            if (doctor.homeVisit) const Icon(Icons.home, size: 18),
          ],
        ),
      ),
    );
  }
}
