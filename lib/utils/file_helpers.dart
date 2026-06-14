import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../config/theme.dart';

// ── Shared: download + open a file (PDF) ─────────────────────────────────────
Future<void> downloadAndOpenFile(BuildContext ctx, String url, String title) async {
  final path = await showDialog<String?>(
    context: ctx, barrierDismissible: false,
    builder: (_) => _DownloadDialog(url: url, title: title),
  );
  if (path != null && ctx.mounted) {
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Could not open file: ${result.message}')));
    }
  }
}

// ── Shared: push full-screen image viewer ────────────────────────────────────
void openImageViewer(BuildContext ctx, String url, String title) {
  Navigator.push(ctx, MaterialPageRoute(builder: (_) => ImageViewerPage(url: url, title: title)));
}

// ── Download dialog with progress ────────────────────────────────────────────
class _DownloadDialog extends StatefulWidget {
  final String url, title;
  const _DownloadDialog({required this.url, required this.title});
  @override
  State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  double? _progress;
  bool _cancelled = false;

  @override
  void initState() { super.initState(); _download(); }

  Future<void> _download() async {
    try {
      final req = http.Request('GET', Uri.parse(widget.url));
      final resp = await http.Client().send(req);
      final total = resp.contentLength ?? 0;
      var received = 0;
      final chunks = <int>[];
      await for (final chunk in resp.stream) {
        if (_cancelled) break;
        chunks.addAll(chunk);
        received += chunk.length;
        if (mounted) setState(() => _progress = total > 0 ? received / total : null);
      }
      if (_cancelled || !mounted) return;
      final rawName = widget.url.split('/').last.split('?').first;
      final ext = rawName.contains('.') ? rawName.split('.').last : 'pdf';
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.$ext');
      await file.writeAsBytes(chunks);
      if (mounted) Navigator.pop(context, file.path);
    } catch (_) {
      if (mounted) Navigator.pop(context, null);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: const Row(children: [
      Icon(Icons.download_rounded, color: AppColors.primary, size: 22),
      SizedBox(width: 10),
      Text('Opening file', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
    ]),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(widget.title, maxLines: 2, overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      const SizedBox(height: 16),
      ClipRRect(borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: _progress, minHeight: 6,
          backgroundColor: Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary))),
      const SizedBox(height: 8),
      Text(_progress == null ? 'Connecting…' : '${(_progress! * 100).toInt()}%',
        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
    ]),
    actions: [TextButton(
      onPressed: () { _cancelled = true; Navigator.pop(context, null); },
      child: const Text('Cancel'))],
  );
}

// ── Full-screen image viewer ──────────────────────────────────────────────────
class ImageViewerPage extends StatelessWidget {
  final String url, title;
  const ImageViewerPage({super.key, required this.url, required this.title});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black, foregroundColor: Colors.white,
      title: Text(title, overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14)),
    ),
    body: InteractiveViewer(
      minScale: 0.5, maxScale: 4.0,
      child: Center(child: CachedNetworkImage(
        imageUrl: url, fit: BoxFit.contain,
        placeholder: (_, _) => const Center(child: CircularProgressIndicator(color: Colors.white)),
        errorWidget: (_, _, _) => const Center(child: Icon(Icons.broken_image_rounded,
          color: Colors.white54, size: 64)),
      )),
    ),
  );
}
