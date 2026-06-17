import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shimmer/shimmer.dart';
import '../config/theme.dart';
import '../models/file_item.dart';
import '../services/firestore_service.dart';
import '../utils/file_helpers.dart';

class UnionAffairsScreen extends StatefulWidget {
  const UnionAffairsScreen({super.key});
  @override
  State<UnionAffairsScreen> createState() => _UnionAffairsScreenState();
}

class _UnionAffairsScreenState extends State<UnionAffairsScreen> {
  List<FileItem>? _items;
  bool _loading = true;
  String? _error;
  final _player = AudioPlayer();
  String? _playingId;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  // FIX: store subscriptions so they can be properly cancelled in dispose
  StreamSubscription? _posSub, _durSub, _completeSub;

  @override
  void initState() {
    super.initState();
    _load();
    _posSub = _player.onPositionChanged.listen((p) { if (mounted) setState(() => _position = p); });
    _durSub = _player.onDurationChanged.listen((d) { if (mounted) setState(() => _duration = d); });
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _playingId = null; _position = Duration.zero; });
    });
  }

  @override
  void dispose() {
    // FIX: cancel all subscriptions before disposing player
    _posSub?.cancel(); _durSub?.cancel(); _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await FirestoreService().getUnionAffairs();
      if (mounted) setState(() { _items = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _toggleAudio(FileItem item) async {
    if (_playingId == item.id) {
      await _player.pause();
      setState(() => _playingId = null);
    } else {
      // FIX: reset both position and duration before switching tracks
      setState(() { _position = Duration.zero; _duration = Duration.zero; });
      await _player.stop();
      await _player.play(UrlSource(item.fileUrl));
      setState(() => _playingId = item.id);
    }
  }

  void _openFile(FileItem item) {
    if (item.fileType == 'image') {
      openImageViewer(context, item.fileUrl, item.title);
    } else if (item.fileType == 'pdf') {
      downloadAndOpenFile(context, item.fileUrl, item.title);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary, onRefresh: _load,
      child: _loading
        ? ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: 5, itemBuilder: (_, _) => _shimmer())
        : _error != null
          ? ListView(children: [
              const SizedBox(height: 80),
              Center(child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.textMuted),
                  const SizedBox(height: 10),
                  const Text('Failed to load', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ]),
              )),
            ])
          : (_items == null || _items!.isEmpty)
            ? ListView(children: const [SizedBox(height: 120), Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.folder_open_rounded, size: 56, color: AppColors.textMuted),
                SizedBox(height: 8),
                Text('No union affairs yet', style: TextStyle(color: AppColors.textMuted)),
              ]))])
            : ListView.builder(
                itemCount: _items!.length,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemBuilder: (_, i) => _UnionCard(
                  item: _items![i],
                  isPlaying: _playingId == _items![i].id,
                  position: _position,
                  duration: _duration,
                  onTap: () => _items![i].fileType == 'audio'
                      ? _toggleAudio(_items![i])
                      : _openFile(_items![i]),
                  // FIX: guard seek when duration not yet known
                  onSeek: (v) {
                    if (_duration > Duration.zero) {
                      _player.seek(Duration(milliseconds: (v * _duration.inMilliseconds).toInt()));
                    }
                  },
                ),
              ),
    );
  }

  Widget _shimmer() => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Shimmer.fromColors(baseColor: Colors.grey.shade200, highlightColor: Colors.grey.shade50,
      child: Card(child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(width: 50, height: 50,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 14, width: double.infinity, color: Colors.white),
            const SizedBox(height: 8),
            Container(height: 12, width: 100, color: Colors.white),
          ])),
        ]),
      ))),
  );
}

// ── Per-item card ──
class _UnionCard extends StatefulWidget {
  final FileItem item;
  final bool isPlaying;
  final Duration position, duration;
  final VoidCallback onTap;
  final ValueChanged<double> onSeek;
  const _UnionCard({
    required this.item, required this.isPlaying,
    required this.position, required this.duration,
    required this.onTap, required this.onSeek,
  });
  @override
  State<_UnionCard> createState() => _UnionCardState();
}

class _UnionCardState extends State<_UnionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isAudio = item.fileType == 'audio';
    final isPdf = item.fileType == 'pdf';
    final (iconData, iconColor, bgColor) = isAudio
      ? (Icons.audiotrack_rounded, AppColors.audioPurple, const Color(0xFFFAF5FF))
      : isPdf
        ? (Icons.picture_as_pdf_rounded, AppColors.primary, const Color(0xFFFEF2F2))
        : (Icons.image_rounded, AppColors.quickLink, const Color(0xFFEFF6FF));
    final typeLabel = isAudio ? 'Audio' : isPdf ? 'PDF' : 'Image';

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
          onTapCancel: () => setState(() => _pressed = false),
          splashColor: iconColor.withAlpha(20),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(children: [
                Container(width: 50, height: 50,
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                  child: Icon(iconData, color: iconColor, size: 26)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, height: 1.3)),
                  const SizedBox(height: 5),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: iconColor.withAlpha(18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: iconColor.withAlpha(50)),
                      ),
                      child: Text(typeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: iconColor)),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text(item.date, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ]),
                ])),
                if (isAudio)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      key: ValueKey(widget.isPlaying),
                      widget.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                      color: AppColors.audioPurple, size: 38),
                  )
                else
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(color: iconColor.withAlpha(15), borderRadius: BorderRadius.circular(10)),
                    child: Icon(isPdf ? Icons.open_in_new_rounded : Icons.open_in_full_rounded,
                      size: 16, color: iconColor),
                  ),
              ]),
            ),
            // ── Audio inline player ──
            if (isAudio && widget.isPlaying)
              Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                decoration: BoxDecoration(
                  color: AppColors.audioPurple.withAlpha(12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.audioPurple.withAlpha(40)),
                ),
                child: Column(children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: AppColors.audioPurple,
                      inactiveTrackColor: AppColors.audioPurple.withAlpha(40),
                      thumbColor: AppColors.audioPurple,
                    ),
                    child: Slider(
                      value: widget.duration.inMilliseconds > 0
                          ? (widget.position.inMilliseconds / widget.duration.inMilliseconds).clamp(0.0, 1.0)
                          : 0,
                      onChanged: widget.onSeek,
                    ),
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(_fmt(widget.position), style: TextStyle(fontSize: 11, color: AppColors.audioPurple.withAlpha(180))),
                    Text(_fmt(widget.duration), style: TextStyle(fontSize: 11, color: AppColors.audioPurple.withAlpha(180))),
                  ]),
                ]),
              ),
          ]),
        ),
      ),
    );
  }

  String _fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}
