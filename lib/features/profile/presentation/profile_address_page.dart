import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../area/presentation/area_picker.dart';
import '../data/mobile_me_dto.dart';
import '../data/profile_validation.dart';
import 'profile_providers.dart';
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
  String? _areaLabel;
  bool _loading = false;
  bool _initialized = false;
  String? _error;

  @override
  void dispose() {
    _line1Controller.dispose();
    _postalController.dispose();
    super.dispose();
  }

  void _initFromProfile(MobileMeDto profile) {
    if (_initialized) return;
    _divisionId = profile.address?.divisionId;
    _districtId = profile.address?.districtId;
    _upazilaId = profile.address?.upazilaId;
    _unionId = profile.address?.unionId;
    _villageId = profile.address?.villageId;
    _line1Controller.text = profile.address?.line1 ?? '';
    _postalController.text = profile.address?.postalCode ?? '';
    _areaLabel = profile.area;
    _initialized = true;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final lineError = ProfileValidation.validateLine1(_line1Controller.text);
    final postalError = ProfileValidation.validatePostalCode(_postalController.text);
    final validationError = lineError ?? postalError;
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    if (_villageId == null || _villageId!.isEmpty) {
      setState(() => _error = l10n.addressRequired);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final patch = PatchMobileMeInput(
      area: _areaLabel,
      address: MobileMeAddressDto(
        divisionId: _divisionId,
        districtId: _districtId,
        upazilaId: _upazilaId,
        unionId: _unionId,
        villageId: _villageId,
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
      context.pop();
      return;
    }

    if (error.contains('offline')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.savedOffline)),
      );
      context.pop();
      return;
    }

    setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(mobileMeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addressTitle)),
      body: profileAsync.when(
        loading: () => ProfileFeedback.loading(),
        error: (_, __) => ProfileFeedback.error(
          context,
          onRetry: () => ref.read(mobileMeProvider.notifier).reload(forceRefresh: true),
        ),
        data: (profile) {
          if (profile == null) return ProfileFeedback.empty(context);
          _initFromProfile(profile);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileFeedback.banner(context, _error ?? ''),
                if (_areaLabel != null && _areaLabel!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_areaLabel!, style: Theme.of(context).textTheme.bodySmall),
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
                  onPressed: _loading ? null : _save,
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
