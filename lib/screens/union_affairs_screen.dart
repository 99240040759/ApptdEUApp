import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shimmer/shimmer.dart';
import '../config/theme.dart';
import '../models/union_affair.dart';
import '../services/firestore_service.dart';

class UnionAffairsScreen extends StatefulWidget {
  const UnionAffairsScreen({super.key});
  @override
  State<UnionAffairsScreen> createState() => _UnionAffairsScreenState();
}

class _UnionAffairsScreenState extends State<UnionAffairsScreen> {
  List<UnionAffair>? _items;
  bool _loading = true;
  // Audio state
  final _player = AudioPlayer();
  String? _playingId;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _load();
    _player.onPositionChanged.listen((p) { if (mounted) setState(() => _position = p); });
    _player.onDurationChanged.listen((d) { if (mounted) setState(() => _duration = d); });
    _player.onPlayerComplete.listen((_) { if (mounted) setState(() { _playingId = null; _position = Duration.zero; }); });
  }

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await FirestoreService().getUnionAffairs();
      if (mounted) setState(() { _items = list; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  void _toggleAudio(UnionAffair item) async {
    if (_playingId == item.id) {
      await _player.pause();
      setState(() => _playingId = null);
    } else {
      await _player.stop();
      await _player.play(UrlSource(item.fileUrl));
      setState(() { _playingId = item.id; _position = Duration.zero; });
    }
  }

  void _openFile(UnionAffair item) {
    if (item.fileType == 'image') {
      showDialog(context: context, builder: (_) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(title: Text(item.title, overflow: TextOverflow.ellipsis)),
          backgroundColor: Colors.black,
          body: InteractiveViewer(child: Center(child: Image.network(item.fileUrl, fit: BoxFit.contain))),
        ),
      ));
    } else if (item.fileType == 'pdf') {
      launchUrl(Uri.parse(item.fileUrl), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary, onRefresh: _load,
      child: _loading
        ? ListView.builder(itemCount: 5, itemBuilder: (_, _) => _shimmer())
        : (_items == null || _items!.isEmpty)
          ? ListView(children: const [SizedBox(height: 120), Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.folder_open, size: 56, color: AppColors.textMuted),
              SizedBox(height: 8),
              Text('No union affairs yet', style: TextStyle(color: AppColors.textMuted)),
            ]))])
          : ListView.builder(
              itemCount: _items!.length,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemBuilder: (_, i) => _itemCard(_items![i]),
            ),
    );
  }

  Widget _itemCard(UnionAffair item) {
    final isAudio = item.fileType == 'audio';
    final isPdf = item.fileType == 'pdf';
    final isPlaying = _playingId == item.id;
    final iconData = isAudio ? Icons.audiotrack : isPdf ? Icons.picture_as_pdf : Icons.image;
    final iconColor = isAudio ? AppColors.audioPurple : isPdf ? AppColors.primary : AppColors.quickLink;
    final bgColor = isAudio ? Colors.purple.shade50 : isPdf ? Colors.red.shade50 : Colors.blue.shade50;

    return Card(child: Column(children: [
      ListTile(
        leading: CircleAvatar(backgroundColor: bgColor, child: Icon(iconData, color: iconColor, size: 22)),
        title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(item.date, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        trailing: isAudio
          ? IconButton(
              icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: AppColors.audioPurple, size: 32),
              onPressed: () => _toggleAudio(item))
          : Icon(isPdf ? Icons.open_in_new : Icons.zoom_in, size: 18, color: AppColors.textMuted),
        onTap: isAudio ? () => _toggleAudio(item) : () => _openFile(item),
      ),
      // Inline audio progress
      if (isPlaying) Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Row(children: [
          Text(_fmt(_position), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          Expanded(child: Slider(
            value: _duration.inMilliseconds > 0 ? _position.inMilliseconds / _duration.inMilliseconds : 0,
            activeColor: AppColors.audioPurple,
            onChanged: (v) => _player.seek(Duration(milliseconds: (v * _duration.inMilliseconds).toInt())),
          )),
          Text(_fmt(_duration), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
      ),
    ]));
  }

  String _fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  Widget _shimmer() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: Shimmer.fromColors(baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100,
      child: Card(child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.white),
        title: Container(height: 14, width: 200, color: Colors.white),
        subtitle: Container(height: 10, width: 80, color: Colors.white),
      ))),
  );
}
