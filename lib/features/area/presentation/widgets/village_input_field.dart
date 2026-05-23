import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../core/area/area_dto.dart';
import '../area_providers.dart';
import 'area_feedback.dart';

/// Optional village: searchable list when available, free text otherwise.
class VillageInputField extends ConsumerStatefulWidget {
  const VillageInputField({
    super.key,
    required this.label,
    required this.unionId,
    this.initialVillageId,
    this.initialVillageName,
    required this.onChanged,
  });

  final String label;
  final String? unionId;
  final String? initialVillageId;
  final String? initialVillageName;
  final void Function({String? villageId, String? villageName, String? label})
  onChanged;

  @override
  ConsumerState<VillageInputField> createState() => _VillageInputFieldState();
}

class _VillageInputFieldState extends ConsumerState<VillageInputField> {
  late final TextEditingController _textController;
  String? _selectedVillageId;

  @override
  void initState() {
    super.initState();
    _selectedVillageId = widget.initialVillageId;
    _textController = TextEditingController(
      text: widget.initialVillageName ?? '',
    );
  }

  @override
  void didUpdateWidget(VillageInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.unionId != widget.unionId) {
      _selectedVillageId = null;
      _textController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onChanged(villageId: null, villageName: null, label: null);
        }
      });
      return;
    }
    if (oldWidget.initialVillageId != widget.initialVillageId ||
        oldWidget.initialVillageName != widget.initialVillageName) {
      _selectedVillageId = widget.initialVillageId;
      final name = widget.initialVillageName ?? '';
      if (_textController.text != name) {
        _textController.text = name;
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _applyCustomText(String text) {
    final trimmed = text.trim();
    _selectedVillageId = null;
    widget.onChanged(
      villageId: null,
      villageName: trimmed.isEmpty ? null : trimmed,
      label: trimmed.isEmpty ? null : trimmed,
    );
  }

  void _applySelection(AreaNodeDto node) {
    _selectedVillageId = node.id;
    _textController.text = node.label;
    widget.onChanged(
      villageId: node.id,
      villageName: node.label,
      label: node.label,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unionId = widget.unionId;

    if (unionId == null || unionId.isEmpty) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          helperText: l10n.areaVillageOptionalHelper,
        ),
        child: Text(
          widget.label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor),
        ),
      );
    }

    final villagesAsync = ref.watch(villageProvider(unionId));

    return InputDecorator(
      decoration: InputDecoration(
        labelText: '${widget.label} (${l10n.profileCompletionOptional})',
        border: const OutlineInputBorder(),
        helperText: l10n.areaVillageOptionalHelper,
      ),
      child: villagesAsync.when(
        loading: AreaFeedback.loading,
        error: (error, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AreaFeedback.error(
              context,
              message: error.toString(),
              onRetry: () => ref.invalidate(villageProvider(unionId)),
            ),
            const SizedBox(height: 8),
            _freeTextField(l10n),
          ],
        ),
        data: (result) {
          if (result.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.areaVillageNotFoundOptional,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                _freeTextField(l10n),
              ],
            );
          }
          return _autocompleteField(l10n, result.nodes);
        },
      ),
    );
  }

  Widget _freeTextField(AppLocalizations l10n) {
    return TextField(
      controller: _textController,
      decoration: InputDecoration(
        hintText: l10n.areaVillageManualHint,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      onChanged: _applyCustomText,
    );
  }

  Widget _autocompleteField(AppLocalizations l10n, List<AreaNodeDto> nodes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Autocomplete<AreaNodeDto>(
          initialValue: TextEditingValue(text: _textController.text),
          displayStringForOption: (node) => node.label,
          optionsBuilder: (query) {
            final q = query.text.trim().toLowerCase();
            if (q.isEmpty) return nodes;
            return nodes.where(
              (n) =>
                  n.label.toLowerCase().contains(q) ||
                  n.nameBn.toLowerCase().contains(q) ||
                  n.nameEn.toLowerCase().contains(q),
            );
          },
          onSelected: _applySelection,
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            if (controller.text != _textController.text) {
              controller.text = _textController.text;
            }
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: l10n.areaVillageManualHint,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                _textController.text = value;
                final match = nodes
                    .where((n) => n.label == value.trim())
                    .firstOrNull;
                if (match != null && match.id == _selectedVillageId) return;
                _applyCustomText(value);
              },
            );
          },
        ),
        if (_selectedVillageId != null) ...[
          const SizedBox(height: 4),
          Text(
            l10n.areaSelectedLocation,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ],
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
