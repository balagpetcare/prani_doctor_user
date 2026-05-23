import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';

import 'package:url_launcher/url_launcher.dart';

class SupportAttachmentViewerPage extends StatelessWidget {
  const SupportAttachmentViewerPage({
    super.key,
    required this.url,
    required this.fileName,
    required this.mimeType,
  });

  final String url;
  final String fileName;
  final String mimeType;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isImage = mimeType.startsWith('image/');

    return Scaffold(
      appBar: safeAppBar(context, title: Text(fileName)),
      body: isImage
          ? InteractiveViewer(
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => _FallbackBody(
                    l10n: l10n,
                    fileName: fileName,
                    onOpen: () => _openExternal(url),
                  ),
                ),
              ),
            )
          : _FallbackBody(
              l10n: l10n,
              fileName: fileName,
              onOpen: () => _openExternal(url),
            ),
    );
  }

  Future<void> _openExternal(String target) async {
    await launchUrl(Uri.parse(target), mode: LaunchMode.externalApplication);
  }
}

class _FallbackBody extends StatelessWidget {
  const _FallbackBody({
    required this.l10n,
    required this.fileName,
    required this.onOpen,
  });

  final AppLocalizations l10n;
  final String fileName;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file_outlined, size: 64),
            const SizedBox(height: 16),
            Text(fileName, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onOpen,
              child: Text(l10n.supportOpenAttachment),
            ),
          ],
        ),
      ),
    );
  }
}

SupportAttachmentViewerPage? supportAttachmentViewerFromState(
  GoRouterState state,
) {
  final url = state.uri.queryParameters['url'];
  if (url == null || url.isEmpty) return null;
  return SupportAttachmentViewerPage(
    url: url,
    fileName: state.uri.queryParameters['name'] ?? 'attachment',
    mimeType: state.uri.queryParameters['mime'] ?? 'application/octet-stream',
  );
}
