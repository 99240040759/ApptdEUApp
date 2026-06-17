import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
    // FIX: create client explicitly so it can be closed in finally (no socket leak)
    final client = http.Client();
    try {
      final req = http.Request('GET', Uri.parse(widget.url));
      final resp = await client.send(req);
      final total = resp.contentLength ?? 0;
      var received = 0;
      // FIX: stream directly to file instead of accumulating in List<int> RAM
      final rawName = widget.url.split('/').last.split('?').first;
      final ext = rawName.contains('.') ? rawName.split('.').last : 'pdf';
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.$ext');
      final sink = file.openWrite();
      await for (final chunk in resp.stream) {
        if (_cancelled) break;
        sink.add(chunk);
        received += chunk.length;
        if (mounted) setState(() => _progress = total > 0 ? received / total : null);
      }
      await sink.close();
      if (_cancelled || !mounted) return;
      if (mounted) Navigator.pop(context, file.path);
    } catch (_) {
      if (mounted) Navigator.pop(context, null);
    } finally {
      client.close(); // Always close — prevents socket leak
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

// ── Full-screen image viewer with share + download ───────────────────────────
class ImageViewerPage extends StatefulWidget {
  final String url, title;
  const ImageViewerPage({super.key, required this.url, required this.title});
  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  bool _downloading = false;

  Future<void> _download() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    // FIX: use explicit client with proper close
    final client = http.Client();
    try {
      final dir = await getTemporaryDirectory();
      final rawName = widget.url.split('/').last.split('?').first;
      final ext = rawName.contains('.') ? rawName.split('.').last : 'jpg';
      final file = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.$ext');
      final resp = await client.get(Uri.parse(widget.url));
      await file.writeAsBytes(resp.bodyBytes);
      if (mounted) { setState(() => _downloading = false); await OpenFilex.open(file.path); }
    } catch (e) {
      if (mounted) {
        setState(() => _downloading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    } finally {
      client.close();
    }
  }

  void _share() => Share.share('${widget.title}\n${widget.url}');

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      backgroundColor: Colors.black54, foregroundColor: Colors.white, elevation: 0,
      title: Text(widget.title, overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, color: Colors.white)),
    ),
    body: Stack(children: [
      InteractiveViewer(
        minScale: 0.5, maxScale: 4.0,
        child: Center(child: CachedNetworkImage(
          imageUrl: widget.url, fit: BoxFit.contain,
          placeholder: (_, _) => const Center(child: CircularProgressIndicator(color: Colors.white)),
          errorWidget: (_, _, _) => const Center(child: Icon(Icons.broken_image_rounded,
            color: Colors.white54, size: 64)),
        )),
      ),
      Positioned(bottom: 0, left: 0, right: 0,
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter, end: Alignment.topCenter,
              colors: [Colors.black.withAlpha(200), Colors.transparent])),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _ActionBtn(icon: Icons.share_rounded, label: 'Share', onTap: _share),
            const SizedBox(width: 24),
            _ActionBtn(
              icon: _downloading ? Icons.hourglass_top_rounded : Icons.download_rounded,
              label: _downloading ? 'Saving…' : 'Save',
              onTap: _downloading ? null : _download,
            ),
          ]),
        ),
      ),
    ]),
  );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ActionBtn({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white30),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    ),
  );
}
