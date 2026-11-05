import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/upload/models/upload_purpose.dart';
import '../../../shared/upload/services/upload_service.dart';
import '../data/animal_weight_capture_draft.dart';
import '../data/animal_weight_method.dart';
import '../data/animal_weight_repository.dart';
import 'widgets/weight_method_selector.dart';

class AnimalWeightMetricsStep extends ConsumerStatefulWidget {
  const AnimalWeightMetricsStep({
    super.key,
    required this.animalType,
    required this.draft,
    required this.onDraftChanged,
    this.enabled = true,
  });

  final String animalType;
  final AnimalWeightCaptureDraft draft;
  final ValueChanged<AnimalWeightCaptureDraft> onDraftChanged;
  final bool enabled;

  @override
  ConsumerState<AnimalWeightMetricsStep> createState() =>
      _AnimalWeightMetricsStepState();
}

class _AnimalWeightMetricsStepState extends ConsumerState<AnimalWeightMetricsStep> {
  final _heartGirthController = TextEditingController();
  final _bodyLengthController = TextEditingController();
  final _scaleWeightController = TextEditingController();
  bool _previewLoading = false;

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant AnimalWeightMetricsStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft != widget.draft) _syncControllers();
  }

  void _syncControllers() {
    final d = widget.draft;
    _heartGirthController.text = d.heartGirthCm?.toString() ?? '';
    _bodyLengthController.text = d.bodyLengthCm?.toString() ?? '';
    _scaleWeightController.text = d.scaleWeightKg?.toString() ?? '';
  }

  @override
  void dispose() {
    _heartGirthController.dispose();
    _bodyLengthController.dispose();
    _scaleWeightController.dispose();
    super.dispose();
  }

  void _emit(AnimalWeightCaptureDraft next) {
    widget.onDraftChanged(next);
  }

  Future<void> _previewTape() async {
    final hg = double.tryParse(_heartGirthController.text.trim());
    final bl = double.tryParse(_bodyLengthController.text.trim());
    if (hg == null || bl == null) return;
    setState(() => _previewLoading = true);
    final result = await ref.read(animalWeightRepositoryProvider).previewTape(
      animalType: widget.animalType,
      heartGirthCm: hg,
      bodyLengthCm: bl,
    );
    if (!mounted) return;
    setState(() => _previewLoading = false);
    result.when(
      success: (kg) {
        _emit(
          widget.draft.copyWith(
            heartGirthCm: hg,
            bodyLengthCm: bl,
            tapeEstimatedKg: kg,
          ),
        );
      },
      failure: (_) {},
    );
  }

  Future<void> _pickScalePhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera);
    if (file == null) return;
    final upload = await ref.read(uploadServiceProvider).uploadWithPurpose(
      filePath: file.path,
      purpose: UploadPurpose.animalWeightScalePhoto,
    );
    upload.when(
      success: (r) {
        _emit(
          widget.draft.copyWith(
            scalePhotoLocalPath: file.path,
            scalePhotoUrl: r.url,
          ),
        );
      },
      failure: (_) {},
    );
  }

  Future<void> _pickAiImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera);
    if (file == null) return;
    final upload = await ref.read(uploadServiceProvider).uploadWithPurpose(
      filePath: file.path,
      purpose: UploadPurpose.animalWeightAiImage,
    );
    upload.when(
      success: (r) {
        final ids = [...widget.draft.aiUploadIds, r.fileId];
        final paths = [...widget.draft.aiLocalPaths, file.path];
        _emit(
          widget.draft.copyWith(aiUploadIds: ids, aiLocalPaths: paths),
        );
      },
      failure: (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final tapeSupported = AnimalWeightMethodX.supportsTape(widget.animalType);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Weight & age',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how to record weight. Tape and AI give estimates — confirm with a scale when possible.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          WeightMethodSelector(
            selected: draft.method,
            tapeEnabled: tapeSupported,
            onSelected: (m) => _emit(draft.copyWith(method: m)),
            enabled: widget.enabled,
          ),
          const SizedBox(height: 16),
          if (draft.method == AnimalWeightMethod.tape) ...[
            TextField(
              controller: _heartGirthController,
              decoration: const InputDecoration(
                labelText: 'Heart girth (cm)',
              ),
              keyboardType: TextInputType.number,
              enabled: widget.enabled,
              onChanged: (_) => _emit(
                draft.copyWith(
                  heartGirthCm: double.tryParse(_heartGirthController.text),
                  bodyLengthCm: double.tryParse(_bodyLengthController.text),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyLengthController,
              decoration: const InputDecoration(
                labelText: 'Body length (cm)',
              ),
              keyboardType: TextInputType.number,
              enabled: widget.enabled,
              onChanged: (_) => _emit(
                draft.copyWith(
                  heartGirthCm: double.tryParse(_heartGirthController.text),
                  bodyLengthCm: double.tryParse(_bodyLengthController.text),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _previewLoading || !widget.enabled ? null : _previewTape,
              child: _previewLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Estimate weight'),
            ),
            if (draft.tapeEstimatedKg != null) ...[
              const SizedBox(height: 12),
              Text(
                'Estimated: ${draft.tapeEstimatedKg!.toStringAsFixed(2)} kg',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ],
          if (draft.method == AnimalWeightMethod.scale) ...[
            TextField(
              controller: _scaleWeightController,
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
              keyboardType: TextInputType.number,
              enabled: widget.enabled,
              onChanged: (_) => _emit(
                draft.copyWith(
                  scaleWeightKg: double.tryParse(_scaleWeightController.text),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: widget.enabled ? _pickScalePhoto : null,
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(
                draft.scalePhotoUrl != null
                    ? 'Scale photo added'
                    : 'Add scale photo (optional)',
              ),
            ),
          ],
          if (draft.method == AnimalWeightMethod.aiCamera) ...[
            Text(
              'AI weight is an estimate only. Verify with a scale before health or sale decisions.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: draft.aiDisclaimerAck,
              onChanged: widget.enabled
                  ? (v) => _emit(draft.copyWith(aiDisclaimerAck: v ?? false))
                  : null,
              title: const Text('I understand this is an AI estimate'),
              contentPadding: EdgeInsets.zero,
            ),
            OutlinedButton.icon(
              onPressed: widget.enabled ? _pickAiImage : null,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text('Add photo (${draft.aiUploadIds.length})'),
            ),
            if (draft.aiResultKg != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'AI estimate: ${draft.aiResultKg!.toStringAsFixed(2)} kg'
                  '${draft.aiConfidence != null ? ' (${(draft.aiConfidence! * 100).toStringAsFixed(0)}% confidence)' : ''}',
                ),
              ),
          ],
        ],
      ),
    );
  }
}

extension _DraftCopy on AnimalWeightCaptureDraft {
  AnimalWeightCaptureDraft copyWith({
    AnimalWeightMethod? method,
    double? heartGirthCm,
    double? bodyLengthCm,
    double? tapeEstimatedKg,
    double? scaleWeightKg,
    String? scalePhotoLocalPath,
    String? scalePhotoUrl,
    List<String>? aiLocalPaths,
    List<String>? aiUploadIds,
    String? aiJobId,
    double? aiResultKg,
    double? aiConfidence,
    bool? aiDisclaimerAck,
    String? clientMeasurementId,
  }) {
    return AnimalWeightCaptureDraft(
      method: method ?? this.method,
      heartGirthCm: heartGirthCm ?? this.heartGirthCm,
      bodyLengthCm: bodyLengthCm ?? this.bodyLengthCm,
      tapeEstimatedKg: tapeEstimatedKg ?? this.tapeEstimatedKg,
      scaleWeightKg: scaleWeightKg ?? this.scaleWeightKg,
      scalePhotoLocalPath: scalePhotoLocalPath ?? this.scalePhotoLocalPath,
      scalePhotoUrl: scalePhotoUrl ?? this.scalePhotoUrl,
      aiLocalPaths: aiLocalPaths ?? this.aiLocalPaths,
      aiUploadIds: aiUploadIds ?? this.aiUploadIds,
      aiJobId: aiJobId ?? this.aiJobId,
      aiResultKg: aiResultKg ?? this.aiResultKg,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      aiDisclaimerAck: aiDisclaimerAck ?? this.aiDisclaimerAck,
      clientMeasurementId: clientMeasurementId ?? this.clientMeasurementId,
    );
  }
}
