import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';
import '../../area/presentation/area_picker.dart';
import '../../service_requests/data/service_request_dto.dart';
import '../../animals/data/animal_repository.dart';
import '../../service_requests/data/service_request_repository.dart';
import '../data/doctor_repository.dart';
import '../data/provider_api_paths.dart';
import '../data/provider_dto.dart';
import '../../../core/offline/network_errors.dart';
import '../../../routing/app_routes.dart';
import '../../offline/data/sync_coordinator.dart';
import '../../offline/offline_providers.dart';

enum ConsultationType { homeVisit, emergency, online }

class BookConsultationPage extends ConsumerStatefulWidget {
  const BookConsultationPage({super.key, required this.doctorId});

  final String doctorId;

  @override
  ConsumerState<BookConsultationPage> createState() =>
      _BookConsultationPageState();
}

class _BookConsultationPageState extends ConsumerState<BookConsultationPage> {
  ConsultationType _type = ConsultationType.homeVisit;
  String? _animalId;
  String? _villageId;
  String? _locationLabel;
  bool _loading = false;

  final _symptomController = TextEditingController();
  final _preferredTimeController = TextEditingController();

  @override
  void dispose() {
    _symptomController.dispose();
    _preferredTimeController.dispose();
    super.dispose();
  }

  String _serviceType() {
    switch (_type) {
      case ConsultationType.homeVisit:
        return DoctorServiceTypes.homeVisit;
      case ConsultationType.emergency:
        return DoctorServiceTypes.emergency;
      case ConsultationType.online:
        return DoctorServiceTypes.onlineConsultation;
    }
  }

  String _categorySlug() {
    switch (_type) {
      case ConsultationType.homeVisit:
        return DoctorCategorySlugs.homeVisit;
      case ConsultationType.emergency:
        return DoctorCategorySlugs.emergency;
      case ConsultationType.online:
        return DoctorCategorySlugs.onlineConsultation;
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final symptom = _symptomController.text.trim();
    if (_animalId == null || symptom.isEmpty) {
      _showError(l10n.fieldRequired);
      return;
    }
    if (_type == ConsultationType.online &&
        _preferredTimeController.text.trim().isEmpty) {
      _showError(l10n.preferredTimeRequired);
      return;
    }

    setState(() => _loading = true);
    try {
      final categories = await ref.read(serviceCategoriesProvider.future);
      ServiceCategoryDto? category;
      for (final c in categories) {
        if (c.slug == _categorySlug()) {
          category = c;
          break;
        }
      }
      if (category == null) {
        _showError(l10n.categoryMissing);
        return;
      }

      final doctor = await ref.read(
        doctorDetailProvider(widget.doctorId).future,
      );
      final result = await ref
          .read(serviceRequestRepositoryProvider)
          .createRequest(
            CreateServiceRequestInput(
              animalId: _animalId!,
              serviceCategoryId: category.id,
              serviceType: _serviceType(),
              problemOrSymptom: symptom,
              description: 'Preferred doctor: ${doctor.name} (${doctor.id})',
              villageId: _villageId,
              locationText: _locationLabel,
              preferredTime: _type == ConsultationType.online
                  ? _preferredTimeController.text.trim()
                  : null,
            ),
          );

      if (!mounted) return;
      result.when(
        success: (request) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.bookingSubmitted)));
          context.go(AppRoutes.serviceRequestDetail(request.id));
        },
        failure: (e) {
          if (e.code == offlineQueuedCode) {
            ref.invalidate(localOutboxCountProvider);
            ref.read(syncCoordinatorProvider).syncNow(background: true);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.savedOffline)));
            context.go(AppRoutes.inbox);
            return;
          }
          _showError(e.message);
        },
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  ConsultationType _resolveType(ProviderDoctorDetailDto doctor) {
    final available = <ConsultationType>[
      if (doctor.homeVisit) ConsultationType.homeVisit,
      if (doctor.emergency) ConsultationType.emergency,
      if (doctor.onlineConsultation) ConsultationType.online,
    ];
    if (available.isEmpty) return _type;
    return available.contains(_type) ? _type : available.first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final doctorAsync = ref.watch(doctorDetailProvider(widget.doctorId));
    final animalsAsync = ref.watch(animalsProvider);

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.bookConsultation)),
      body: doctorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (doctor) {
          final selectedType = _resolveType(doctor);
          if (selectedType != _type) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _type = selectedType);
            });
          }
          final segments = <ButtonSegment<ConsultationType>>[
            if (doctor.homeVisit)
              ButtonSegment(
                value: ConsultationType.homeVisit,
                label: Text(l10n.homeVisit),
              ),
            if (doctor.emergency)
              ButtonSegment(
                value: ConsultationType.emergency,
                label: Text(l10n.filterEmergency),
              ),
            if (doctor.onlineConsultation)
              ButtonSegment(
                value: ConsultationType.online,
                label: Text(l10n.onlineConsultation),
              ),
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  doctor.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SegmentedButton<ConsultationType>(
                  segments: segments,
                  selected: {selectedType},
                  onSelectionChanged: segments.isEmpty || _loading
                      ? null
                      : (value) {
                          setState(() => _type = value.first);
                        },
                ),
                const SizedBox(height: 16),
                animalsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text(e.toString()),
                  data: (animals) {
                    if (animals.isEmpty) {
                      return Text(l10n.addAnimalFirst);
                    }
                    return DropdownButtonFormField<String>(
                      initialValue: _animalId,
                      decoration: InputDecoration(labelText: l10n.selectAnimal),
                      items: animals
                          .map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(
                                '${a.name} (${a.animalType ?? a.species})',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _loading
                          ? null
                          : (v) => setState(() => _animalId = v),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _symptomController,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: l10n.symptomsLabel),
                  enabled: !_loading,
                ),
                if (_type == ConsultationType.online) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _preferredTimeController,
                    decoration: InputDecoration(
                      labelText: l10n.preferredTimeLabel,
                    ),
                    enabled: !_loading,
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  l10n.locationSectionTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                AreaPicker(
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
                          _villageId = villageId;
                          _locationLabel = selectedLabel;
                        });
                      },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.submitBooking),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
