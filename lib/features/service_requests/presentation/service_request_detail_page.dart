import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';

import '../../../routing/app_routes.dart';
import '../data/service_request_dto.dart';
import '../data/service_request_repository.dart';
import 'service_request_status_chip.dart';

class ServiceRequestDetailPage extends ConsumerStatefulWidget {
  const ServiceRequestDetailPage({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<ServiceRequestDetailPage> createState() =>
      _ServiceRequestDetailPageState();
}

class _ServiceRequestDetailPageState
    extends ConsumerState<ServiceRequestDetailPage> {
  bool _cancelling = false;

  Future<void> _cancel(ServiceRequestDto request) async {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelAppointment),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(labelText: l10n.cancelReasonLabel),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.keepAppointment),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.confirmCancel),
          ),
        ],
      ),
    );
    final cancelReason = reasonController.text.trim();
    reasonController.dispose();
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      final result = await ref
          .read(serviceRequestRepositoryProvider)
          .cancelRequest(
            widget.requestId,
            cancelReason: cancelReason.isEmpty ? null : cancelReason,
          );
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(serviceRequestDetailProvider(widget.requestId));
          ref.invalidate(serviceRequestTimelineProvider(widget.requestId));
          ref.invalidate(serviceRequestListProvider);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.appointmentCancelled)));
        },
        failure: (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.message)));
        },
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final requestAsync = ref.watch(
      serviceRequestDetailProvider(widget.requestId),
    );

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.appointmentDetails)),
      body: requestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (request) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ServiceRequestStatusChip(status: request.status),
              const SizedBox(height: 16),
              _Section(
                title: l10n.appointmentSummary,
                children: [
                  _Row(
                    label: l10n.serviceTypeLabel,
                    value: serviceTypeLabel(l10n, request.serviceType),
                  ),
                  if (request.serviceCategory != null)
                    _Row(
                      label: l10n.categoryLabel,
                      value: request.serviceCategory!.name,
                    ),
                  if (request.animal != null)
                    _Row(label: l10n.selectAnimal, value: request.animal!.name),
                  _Row(
                    label: l10n.symptomsLabel,
                    value: request.problemOrSymptom,
                  ),
                  if (request.locationText != null &&
                      request.locationText!.isNotEmpty)
                    _Row(
                      label: l10n.locationSectionTitle,
                      value: request.locationText!,
                    ),
                  if (request.preferredTime != null &&
                      request.preferredTime!.isNotEmpty)
                    _Row(
                      label: l10n.preferredTimeLabel,
                      value: request.preferredTime!,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: l10n.assignedDoctor,
                children: [
                  _Row(
                    label: l10n.providerLabel,
                    value: request.assigneeName ?? l10n.awaitingAssignment,
                  ),
                  if (request.assignedAt != null)
                    _Row(
                      label: l10n.assignedAtLabel,
                      value: formatTimestamp(request.assignedAt),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: l10n.trackStatus,
                children: [
                  _Row(
                    label: l10n.submittedAtLabel,
                    value: formatTimestamp(request.submittedAt),
                  ),
                  _Row(
                    label: l10n.startedAtLabel,
                    value: formatTimestamp(request.startedAt),
                  ),
                  _Row(
                    label: l10n.completedAtLabel,
                    value: formatTimestamp(request.completedAt),
                  ),
                  if (request.cancelledAt != null)
                    _Row(
                      label: l10n.cancelledAtLabel,
                      value: formatTimestamp(request.cancelledAt),
                    ),
                  if (request.cancelReason != null &&
                      request.cancelReason!.isNotEmpty)
                    _Row(
                      label: l10n.cancelReasonLabel,
                      value: request.cancelReason!,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.go(
                  AppRoutes.serviceRequestHistory(widget.requestId),
                ),
                icon: const Icon(Icons.history),
                label: Text(l10n.viewHistory),
              ),
              if (request.status.isCustomerCancellable) ...[
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: _cancelling ? null : () => _cancel(request),
                  child: _cancelling
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.cancelAppointment),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
