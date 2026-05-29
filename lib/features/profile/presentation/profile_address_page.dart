import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';
import '../../area/data/area_validation.dart';
import '../../area/presentation/area_picker.dart';
import '../data/mobile_me_dto.dart';
import '../data/profile_validation.dart';
import 'profile_navigation.dart';
import 'profile_providers.dart';
import 'profile_location_draft_provider.dart';
import 'widgets/profile_feedback.dart';

class ProfileAddressPage extends ConsumerStatefulWidget {
  const ProfileAddressPage({super.key});

  @override
  ConsumerState<ProfileAddressPage> createState() => _ProfileAddressPageState();
}

class _ProfileAddressPageState extends ConsumerState<ProfileAddressPage> {
  final _line1Controller = TextEditingController();
  final _postalController = TextEditingController();

  String? _divisionId;
  String? _districtId;
  String? _upazilaId;
  String? _unionId;
  String? _villageId;
  String? _villageName;
  String? _areaLabel;
  bool _loading = false;
  bool _initialized = false;
  String? _error;

  bool get _canSaveHierarchy =>
      _divisionId != null &&
      _divisionId!.isNotEmpty &&
      _districtId != null &&
      _districtId!.isNotEmpty &&
      _upazilaId != null &&
      _upazilaId!.isNotEmpty &&
      _unionId != null &&
      _unionId!.isNotEmpty;

  @override
  void dispose() {
    _line1Controller.dispose();
    _postalController.dispose();
    super.dispose();
  }

  Future<void> _initFromSources(MobileMeDto profile) async {
    if (_initialized) return;
    final draft = await ref.read(profileLocationDraftProvider.future);
    final merged = draft.toAddressDto().mergeForPatch(profile.address);
    _divisionId = merged.divisionId;
    _districtId = merged.districtId;
    _upazilaId = merged.upazilaId;
    _unionId = merged.unionId;
    _villageId = merged.villageId;
    _villageName = merged.villageName;
    _line1Controller.text =
        merged.line1 ?? profile.address?.line1 ?? draft.line1 ?? '';
    _postalController.text = merged.postalCode ??
        profile.address?.postalCode ??
        draft.postalCode ??
        '';
    _areaLabel = draft.areaLabel ?? profile.area;
    _initialized = true;
    if (mounted) setState(() {});
  }

  Future<void> _persistDraft() async {
    await ref.read(profileLocationDraftProvider.notifier).saveDraft(
      ProfileLocationDraft(
        divisionId: _divisionId,
        districtId: _districtId,
        upazilaId: _upazilaId,
        unionId: _unionId,
        villageId: _villageId,
        villageName: _villageName,
        areaLabel: _areaLabel,
        line1: _line1Controller.text.trim().isEmpty
            ? null
            : _line1Controller.text.trim(),
        postalCode: _postalController.text.trim().isEmpty
            ? null
            : _postalController.text.trim(),
      ),
    );
  }

  String? _resolveAreaLabel() {
    if (_areaLabel != null && _areaLabel!.trim().isNotEmpty) {
      return _areaLabel!.trim();
    }
    if (_villageName != null && _villageName!.trim().isNotEmpty) {
      return _villageName!.trim();
    }
    return null;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final lineError = ProfileValidation.validateLine1(
      _line1Controller.text,
      tooLongMessage: l10n.profileAddressLineTooLong,
    );
    final postalError = ProfileValidation.validatePostalCode(
      _postalController.text,
      tooLongMessage: l10n.profilePostalTooLong,
    );
    final validationError = lineError ?? postalError;
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    final hierarchyError = AreaValidation.validateRequiredHierarchy(
      divisionId: _divisionId,
      districtId: _districtId,
      upazilaId: _upazilaId,
      unionId: _unionId,
      message: l10n.addressHierarchyRequired,
    );
    if (hierarchyError != null ||
        !AreaValidation.isValidParentChain(
          divisionId: _divisionId,
          districtId: _districtId,
          upazilaId: _upazilaId,
          unionId: _unionId,
          villageId: _villageId,
        )) {
      setState(() => _error = hierarchyError ?? l10n.addressHierarchyRequired);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final trimmedVillageName = _villageName?.trim();
    final patch = PatchMobileMeInput(
      area: _resolveAreaLabel(),
      address: MobileMeAddressDto(
        divisionId: _divisionId,
        districtId: _districtId,
        upazilaId: _upazilaId,
        unionId: _unionId,
        villageId: _villageId,
        villageName: trimmedVillageName != null && trimmedVillageName.isNotEmpty
            ? trimmedVillageName
            : null,
        line1: _line1Controller.text.trim().isEmpty
            ? null
            : _line1Controller.text.trim(),
        postalCode: _postalController.text.trim().isEmpty
            ? null
            : _postalController.text.trim(),
      ),
    );

    final error = await ref.read(mobileMeProvider.notifier).save(patch);
    if (!mounted) return;
    setState(() => _loading = false);

    if (error == null) {
      await navigateAfterProfileSave(context, ref, fromCompletionFlow: true);
      return;
    }

    if (error.contains('offline')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.savedOffline)));
      await navigateAfterProfileSave(context, ref, fromCompletionFlow: true);
      return;
    }

    setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(mobileMeProvider);
    final canSave = _canSaveHierarchy && !_loading;

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.addressTitle)),
      body: profileAsync.when(
        loading: ProfileFeedback.loading,
        error: (e, _) => ProfileFeedback.errorFromObject(
          context,
          failure: e,
          onRetry: () =>
              ref.read(mobileMeProvider.notifier).reload(forceRefresh: true),
        ),
        data: (profile) {
          if (profile == null) return ProfileFeedback.empty(context);
          if (!_initialized) {
            Future.microtask(() => _initFromSources(profile));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileFeedback.banner(context, _error ?? ''),
                if (_areaLabel != null && _areaLabel!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _areaLabel!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
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
                          if (selectedLabel != null &&
                              selectedLabel.isNotEmpty) {
                            _areaLabel = selectedLabel;
                          }
                        });
                        _persistDraft();
                      },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _line1Controller,
                  decoration: InputDecoration(labelText: l10n.addressLineLabel),
                  enabled: !_loading,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _postalController,
                  decoration: InputDecoration(labelText: l10n.postalCodeLabel),
                  enabled: !_loading,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: canSave ? _save : null,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.saveProfile),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
