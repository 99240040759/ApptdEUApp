import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../config/theme.dart';

class UpdaterService {
  static final UpdaterService _instance = UpdaterService._();
  factory UpdaterService() => _instance;
  UpdaterService._();

  /// Call this from main app — checks for update and shows dialog if available.
  Future<void> checkForUpdate(BuildContext context) async {
    try {
      final release = await _fetchLatestRelease();
      if (release == null) return;
      final latestTag = release['tag_name'] as String? ?? '';
      final currentVersion = await _currentVersion();
      if (!_isNewer(latestTag, currentVersion)) return;
      final apkUrl = _extractApkUrl(release);
      if (apkUrl == null) return;
      if (context.mounted) {
        _showUpdateDialog(context, latestTag, apkUrl, release['body'] as String? ?? '');
      }
    } catch (_) {
      // Silently fail — don't interrupt the user if GitHub API is unreachable
    }
  }

  Future<Map<String, dynamic>?> _fetchLatestRelease() async {
    final res = await http.get(
      Uri.parse(AppConstants.githubReleasesUrl),
      headers: {'Accept': 'application/vnd.github+json'},
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<String> _currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return 'v${info.version}';
  }

  /// Compares semver strings — returns true if [latest] is newer than [current].
  bool _isNewer(String latest, String current) {
    try {
      final l = _parseVersion(latest);
      final c = _parseVersion(current);
      for (var i = 0; i < 3; i++) {
        if (l[i] > c[i]) return true;
        if (l[i] < c[i]) return false;
      }
      return false;
    } catch (_) { return false; }
  }

  List<int> _parseVersion(String v) {
    final clean = v.replaceAll(RegExp(r'[^0-9.]'), '');
    final parts = clean.split('.');
    return List.generate(3, (i) => i < parts.length ? int.tryParse(parts[i]) ?? 0 : 0);
  }

  String? _extractApkUrl(Map<String, dynamic> release) {
    final assets = release['assets'] as List<dynamic>? ?? [];
    for (final asset in assets) {
      final name = asset['name'] as String? ?? '';
      if (name.endsWith('.apk')) return asset['browser_download_url'] as String?;
    }
    return null;
  }

  void _showUpdateDialog(
    BuildContext context, String version, String apkUrl, String releaseNotes) {
    showDialog(
      context: context,
      barrierDismissible: false, // user MUST interact — no dismissal
      builder: (_) => _UpdateDialog(version: version, apkUrl: apkUrl, releaseNotes: releaseNotes),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Update Dialog — auto-downloads in background, shows progress, then Install
// ─────────────────────────────────────────────────────────────────────────────
class _UpdateDialog extends StatefulWidget {
  final String version, apkUrl, releaseNotes;
  const _UpdateDialog({required this.version, required this.apkUrl, required this.releaseNotes});
  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  double _progress = 0;
  bool _done = false;
  String? _apkPath;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final apkFile = File('${dir.path}/update.apk');
      if (await apkFile.exists()) await apkFile.delete();

      final req = http.Request('GET', Uri.parse(widget.apkUrl));
      final res = await req.send();
      final total = res.contentLength ?? 0;
      var received = 0;
      final sink = apkFile.openWrite();

      await for (final chunk in res.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0 && mounted) setState(() => _progress = received / total);
      }
      await sink.close();

      if (mounted) setState(() { _done = true; _apkPath = apkFile.path; });
    } catch (e) {
      if (mounted) setState(() => _error = 'Download failed. Please try again.');
    }
  }

  Future<void> _installApk() async {
    if (_apkPath == null) return;
    await OpenFilex.open(_apkPath!, type: 'application/vnd.android.package-archive');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // block back button
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.system_update_rounded, color: Color(0xFFB91C1C)),
          const SizedBox(width: 10),
          Text('Update Available', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFB91C1C), borderRadius: BorderRadius.circular(20)),
            child: Text(widget.version, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const SizedBox(height: 12),
          if (widget.releaseNotes.isNotEmpty) ...[
            Text('What\'s new:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 100),
              child: SingleChildScrollView(
                child: Text(widget.releaseNotes, style: const TextStyle(fontSize: 12, color: Colors.black87)),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ] else if (_done) ...[
            const Row(children: [
              Icon(Icons.check_circle, color: Colors.green, size: 18),
              SizedBox(width: 6),
              Text('Download complete', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ] else ...[
            Row(children: [
              const SizedBox(width: 2),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Downloading update...', style: TextStyle(fontSize: 12)),
                  Text('${(_progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFB91C1C))),
                ]),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  backgroundColor: Colors.grey.shade200,
                  color: const Color(0xFFB91C1C),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 6,
                ),
              ])),
            ]),
          ],
        ]),
        actions: [
          if (_done)
            SizedBox(width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _installApk,
                icon: const Icon(Icons.install_mobile_rounded),
                label: const Text('Install Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB91C1C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            )
          else if (_error != null)
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: () { setState(() { _error = null; _progress = 0; }); _startDownload(); },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB91C1C), foregroundColor: Colors.white),
                child: const Text('Retry'),
              ),
            )
          else
            const SizedBox.shrink(),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }
}
