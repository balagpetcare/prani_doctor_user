import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/offline/network_errors.dart';
import '../../area/presentation/area_picker.dart';
import '../data/mobile_me_dto.dart';
import '../data/profile_repository.dart';
import 'profile_providers.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  String? _divisionId;
  String? _districtId;
  String? _upazilaId;
  String? _unionId;
  String? _villageId;
  bool _loading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _initFromProfile(MobileMeDto profile) {
    if (_initialized) return;
    _nameController.text = profile.name;
    _emailController.text = profile.email;
    _divisionId = profile.address?.divisionId;
    _districtId = profile.address?.districtId;
    _upazilaId = profile.address?.upazilaId;
    _unionId = profile.address?.unionId;
    _villageId = profile.address?.villageId;
    _initialized = true;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError(l10n.fieldRequired);
      return;
    }

    setState(() => _loading = true);
    final patch = PatchMobileMeInput(
      name: name,
      email: _emailController.text.trim(),
      address: MobileMeAddressDto(
        divisionId: _divisionId,
        districtId: _districtId,
        upazilaId: _upazilaId,
        unionId: _unionId,
        villageId: _villageId,
      ),
    );
    final result = await ref.read(profileRepositoryProvider).patchMe(patch);
    if (!mounted) return;
    setState(() => _loading = false);

    final offlineQueued = result.when(
      success: (_) => false,
      failure: (e) => e.code == offlineQueuedCode,
    );
    if (offlineQueued) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.savedOffline)),
      );
      context.pop();
      return;
    }

    final error = result.when(
      success: (_) => null,
      failure: (e) => e.message,
    );
    if (error != null) {
      _showError(error);
      return;
    }
    context.pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(mobileMeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileEditTitle)),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.profileLoadError)),
        data: (profile) {
          if (profile == null) {
            return Center(child: Text(l10n.profileLoadError));
          }
          _initFromProfile(profile);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.nameLabel),
                  enabled: !_loading,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: l10n.emailOptionalLabel),
                  enabled: !_loading,
                ),
                const SizedBox(height: 12),
                Text(
                  profile.phone,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.locationSectionTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (profile.area != null && profile.area!.isNotEmpty) ...[
                  Text(profile.area!, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                ],
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
