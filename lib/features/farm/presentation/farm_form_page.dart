import 'dart:async';



import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:pranidoctor_user/l10n/app_localizations.dart';



import '../../../core/navigation/navigation_guard.dart';

import '../../../routing/app_routes.dart';

import '../../area/presentation/area_picker.dart';

import '../../profile/data/mobile_me_dto.dart';

import '../../profile/data/profile_repository.dart';

import '../../profile/presentation/profile_location_draft_provider.dart';

import '../../profile/presentation/profile_providers.dart';

import '../data/farm_dto.dart';

import '../data/farm_location.dart';

import '../data/farm_repository.dart';

import '../data/farm_validation.dart';

import 'farm_providers.dart';

import 'widgets/farm_feedback.dart';

import 'widgets/farm_image_upload.dart';



class FarmFormPage extends ConsumerStatefulWidget {

  const FarmFormPage({super.key, this.farmId});



  final String? farmId;



  @override

  ConsumerState<FarmFormPage> createState() => _FarmFormPageState();

}



class _FarmFormPageState extends ConsumerState<FarmFormPage> {

  final _nameController = TextEditingController();

  String? _divisionId;

  String? _districtId;

  String? _upazilaId;

  String? _unionId;

  String? _villageId;

  String? _villageName;

  String? _areaLabel;

  String? _coverUrl;

  bool _loading = false;

  bool _initialized = false;

  String? _error;

  Timer? _draftDebounce;



  @override

  void dispose() {

    _draftDebounce?.cancel();

    _nameController.dispose();

    super.dispose();

  }



  void _log(String message) {

    if (kDebugMode) debugPrint('[FARM_LOCATION] $message');

  }



  FarmLocation get _location => FarmLocation(

    divisionId: _divisionId,

    districtId: _districtId,

    upazilaId: _upazilaId,

    unionId: _unionId,

    villageId: _villageId,

    villageName: _villageName,

    displayAddress: _areaLabel,

  );



  Future<void> _initFromSources() async {

    if (_initialized) return;

    final repo = ref.read(farmRepositoryProvider);



    final draft = await repo.readDraft(farmId: widget.farmId);

    if (draft != null && mounted) {

      _log('restore draft union=${draft.address.unionId} village=${draft.address.villageId}');

      _applyInput(draft);

      _initialized = true;

      setState(() {});

      return;

    }



    final id = widget.farmId;

    if (id != null) {

      final detail = await ref.read(farmDetailProvider(id).future);

      final farm = detail.farm;

      _nameController.text = farm.name;

      _applyLocation(

        FarmLocation.fromAddress(farm.address, areaLabel: farm.locationLabel),

      );

      _coverUrl = farm.coverPhotoUrl;

      _log('restore edit farm union=${_unionId} village=${_villageId}');

      _initialized = true;

      if (mounted) setState(() {});

      return;

    }



    // Create mode — merge profile, cached profile, and location draft.

    MobileMeDto? profile = ref.read(mobileMeProvider).valueOrNull;

    profile ??= await ref.read(profileRepositoryProvider).readCachedProfile();

    final locationDraft = await ref.read(profileLocationDraftProvider.future);

    var resolved = const FarmLocation();

    if (profile != null) {

      resolved = FarmLocation.fromAddress(

        profile.address,

        areaLabel: profile.area,

      );

      _log(

        'restore profile union=${profile.address?.unionId} village=${profile.address?.villageId} villageName=${profile.address?.villageName}',

      );

    }

    if (locationDraft.hasUnion) {

      resolved = resolved.mergeWith(

        FarmLocation(

          divisionId: locationDraft.divisionId,

          districtId: locationDraft.districtId,

          upazilaId: locationDraft.upazilaId,

          unionId: locationDraft.unionId,

          villageId: locationDraft.villageId,

          villageName: locationDraft.villageName,

          displayAddress: locationDraft.areaLabel,

        ),

      );

      _log('merged location draft union=${locationDraft.unionId}');

    }

    if (resolved.hasHierarchy) {

      _applyLocation(resolved);

    }



    _initialized = true;

    if (mounted) setState(() {});

  }



  void _applyInput(FarmInput input) {

    _nameController.text = input.name;

    _applyLocation(FarmLocation.fromAddress(input.address, areaLabel: input.areaLabel));

    _coverUrl = input.coverPhotoUrl;

  }



  void _applyLocation(FarmLocation location) {

    _divisionId = location.divisionId;

    _districtId = location.districtId;

    _upazilaId = location.upazilaId;

    _unionId = location.unionId;

    _villageId = location.villageId;

    _villageName = location.villageName;

    _areaLabel = location.displayAddress;

  }



  FarmInput _currentInput() {

    final location = _location;

    return FarmInput(

      name: _nameController.text.trim(),

      areaLabel: location.fullAddress ?? _areaLabel ?? _nameController.text.trim(),

      coverPhotoUrl: _coverUrl,

      address: location.toAddressDto(),

    );

  }



  void _scheduleDraftSave() {

    _draftDebounce?.cancel();

    _draftDebounce = Timer(const Duration(milliseconds: 500), () async {

      if (!mounted) return;

      await ref

          .read(farmRepositoryProvider)

          .saveDraft(_currentInput(), farmId: widget.farmId);

      _log('draft autosaved union=$_unionId village=$_villageId name=$_villageName');

    });

  }



  Future<void> _persistLocationDraft() async {

    await ref.read(profileLocationDraftProvider.notifier).saveDraft(

      ProfileLocationDraft(

        divisionId: _divisionId,

        districtId: _districtId,

        upazilaId: _upazilaId,

        unionId: _unionId,

        villageId: _villageId,

        villageName: _villageName,

        areaLabel: _areaLabel,

      ),

    );

  }



  @override

  void initState() {

    super.initState();

    Future.microtask(_initFromSources);

  }



  Future<void> _saveDraft() async {

    await ref

        .read(farmRepositoryProvider)

        .saveDraft(_currentInput(), farmId: widget.farmId);

    await _persistLocationDraft();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(content: Text(AppLocalizations.of(context)!.farmDraftSaved)),

    );

  }



  Future<void> _save() async {

    if (_loading) return;

    final l10n = AppLocalizations.of(context)!;

    final input = _currentInput();

    final nameError = FarmValidation.validateName(

      _nameController.text,

      requiredMessage: l10n.fieldRequired,

    );

    final locationError = FarmValidation.validateLocation(

      input.address,

      hierarchyMessage: l10n.addressHierarchyRequired,

    );

    final validationError = nameError ?? locationError;

    if (validationError != null) {

      _log('validation failed: $validationError');

      setState(() => _error = validationError);

      return;

    }



    setState(() {

      _loading = true;

      _error = null;

    });



    _log(

      'save union=${input.address.unionId} villageId=${input.address.villageId} villageName=${input.address.villageName}',

    );



    try {

      final farm = await ref

          .read(farmListProvider.notifier)

          .saveOptimistic(input, farmId: widget.farmId);

      if (!mounted) return;

      setState(() => _loading = false);

      if (farm != null) {

        await _persistLocationDraft();

        context.go(AppRoutes.farmDetail(farm.id));

      }

    } catch (e) {

      if (!mounted) return;

      setState(() {

        _loading = false;

        _error = e.toString();

      });

    }

  }



  @override

  Widget build(BuildContext context) {

    final l10n = AppLocalizations.of(context)!;

    final isEdit = widget.farmId != null;



    return Scaffold(

      appBar: safeAppBar(

        context,

        title: Text(isEdit ? l10n.farmEditTitle : l10n.farmCreateTitle),

        actions: [

          TextButton(

            onPressed: _loading ? null : _saveDraft,

            child: Text(l10n.farmSaveDraft),

          ),

        ],

      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(24),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [

            FarmFeedback.banner(context, _error ?? ''),

            FarmImageUpload(

              currentUrl: _coverUrl,

              onUploaded: (url) {

                setState(() => _coverUrl = url);

                _scheduleDraftSave();

                ref.invalidate(farmListProvider);

                if (widget.farmId != null) {

                  ref.invalidate(farmDetailProvider(widget.farmId!));

                }

              },

            ),

            const SizedBox(height: 24),

            TextField(

              controller: _nameController,

              decoration: InputDecoration(labelText: l10n.farmNameLabel),

              enabled: !_loading,

              onChanged: (_) => _scheduleDraftSave(),

            ),

            const SizedBox(height: 16),

            Text(

              l10n.locationSectionTitle,

              style: Theme.of(context).textTheme.titleSmall,

            ),

            const SizedBox(height: 8),

            AreaPicker(

              divisionLabel: l10n.divisionLabel,

              districtLabel: l10n.districtLabel,

              upazilaLabel: l10n.upazilaLabel,

              unionLabel: l10n.unionLabel,

              villageLabel: l10n.villageLabel,

              initialDivisionId: _divisionId,

              initialDistrictId: _districtId,

              initialUpazilaId: _upazilaId,

              initialUnionId: _unionId,

              initialVillageId: _villageId,

              initialVillageName: _villageName,

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

                      _divisionId = divisionId;

                      _districtId = districtId;

                      _upazilaId = upazilaId;

                      _unionId = unionId;

                      _villageId = villageId;

                      _villageName = villageName;

                      if (selectedLabel != null && selectedLabel.isNotEmpty) {

                        _areaLabel = selectedLabel;

                      }

                    });

                    _log(

                      'picker union=$unionId villageId=$villageId villageName=$villageName',

                    );

                    _scheduleDraftSave();

                    _persistLocationDraft();

                  },

            ),

            const SizedBox(height: 24),

            FilledButton(

              onPressed: _loading ? null : _save,

              child: _loading

                  ? const SizedBox(

                      height: 20,

                      width: 20,

                      child: CircularProgressIndicator(strokeWidth: 2),

                    )

                  : Text(isEdit ? l10n.saveProfile : l10n.farmCreateTitle),

            ),

          ],

        ),

      ),

    );

  }

}


