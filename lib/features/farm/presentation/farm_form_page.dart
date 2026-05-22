import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../../area/presentation/area_picker.dart';
import '../../profile/data/mobile_me_dto.dart';
import '../data/farm_dto.dart';
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
  String? _areaLabel;
  String? _coverUrl;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _initFromDetail() async {
    final id = widget.farmId;
    if (id == null) return;
    final detail = await ref.read(farmDetailProvider(id).future);
    final farm = detail.farm;
    _nameController.text = farm.name;
    _divisionId = farm.address?.divisionId;
    _districtId = farm.address?.districtId;
    _upazilaId = farm.address?.upazilaId;
    _unionId = farm.address?.unionId;
    _villageId = farm.address?.villageId;
    _areaLabel = farm.locationLabel;
    _coverUrl = farm.coverPhotoUrl;
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    if (widget.farmId != null) {
      Future.microtask(_initFromDetail);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final nameError = FarmValidation.validateName(
      _nameController.text,
      requiredMessage: l10n.fieldRequired,
    );
    final villageError = FarmValidation.validateVillage(
      _villageId,
      requiredMessage: l10n.farmLocationRequired,
    );
    final validationError = nameError ?? villageError;
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final input = FarmInput(
      name: _nameController.text.trim(),
      areaLabel: _areaLabel ?? _nameController.text.trim(),
      address: MobileMeAddressDto(
        divisionId: _divisionId,
        districtId: _districtId,
        upazilaId: _upazilaId,
        unionId: _unionId,
        villageId: _villageId,
      ),
    );

    try {
      final farm = await ref.read(farmListProvider.notifier).saveOptimistic(
            input,
            farmId: widget.farmId,
          );
      if (!mounted) return;
      setState(() => _loading = false);
      if (farm != null) {
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
      appBar: AppBar(
        title: Text(isEdit ? l10n.farmEditTitle : l10n.farmCreateTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FarmFeedback.banner(context, _error ?? ''),
            FarmImageUpload(
              currentUrl: _coverUrl,
              onUploaded: (url) => setState(() => _coverUrl = url),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.farmNameLabel),
              enabled: !_loading,
            ),
            const SizedBox(height: 16),
            Text(l10n.locationSectionTitle, style: Theme.of(context).textTheme.titleSmall),
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
              onChanged: ({
                divisionId,
                districtId,
                upazilaId,
                unionId,
                villageId,
                selectedLabel,
              }) {
                setState(() {
                  _divisionId = divisionId;
                  _districtId = districtId;
                  _upazilaId = upazilaId;
                  _unionId = unionId;
                  _villageId = villageId;
                  _areaLabel = selectedLabel ?? _areaLabel;
                });
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
