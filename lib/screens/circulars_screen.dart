import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../config/theme.dart';
import '../models/circular.dart';
import '../services/firestore_service.dart';
import '../utils/file_helpers.dart';

class CircularsScreen extends StatefulWidget {
  const CircularsScreen({super.key});
  @override
  State<CircularsScreen> createState() => _CircularsScreenState();
}

class _CircularsScreenState extends State<CircularsScreen> {
  List<Circular>? _all;
  List<Circular> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await FirestoreService().getCirculars();
      if (mounted) setState(() { _all = list; _filtered = list; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  void _filter(String q) {
    if (_all == null) return;
    setState(() => _filtered = q.isEmpty ? _all! :
      _all!.where((c) => c.title.toLowerCase().contains(q.toLowerCase())).toList());
  }

  void _openFile(Circular c) {
    if (c.fileType == 'image') {
      openImageViewer(context, c.fileUrl, c.title);
    } else {
      downloadAndOpenFile(context, c.fileUrl, c.title);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Search bar
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: TextField(
          controller: _searchCtrl, onChanged: _filter,
          decoration: InputDecoration(
            hintText: 'Search circulars...',
            prefixIcon: const Icon(Icons.search_rounded, size: 22),
            suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () { _searchCtrl.clear(); _filter(''); })
              : null,
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
      // List
      Expanded(child: RefreshIndicator(
        color: AppColors.primary, onRefresh: _load,
        child: _loading
          ? ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: 6, itemBuilder: (_, _) => _shimmer())
          : _filtered.isEmpty
            ? ListView(children: const [SizedBox(height: 120), Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.search_off_rounded, size: 56, color: AppColors.textMuted),
                SizedBox(height: 8),
                Text('No circulars found', style: TextStyle(color: AppColors.textMuted)),
              ]))])
            : ListView.builder(
                itemCount: _filtered.length,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                itemBuilder: (_, i) => _CircularCard(
                  circular: _filtered[i],
                  onTap: () => _openFile(_filtered[i]),
                ),
              ),
      )),
    ]);
  }

  Widget _shimmer() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Shimmer.fromColors(baseColor: Colors.grey.shade200, highlightColor: Colors.grey.shade50,
      child: Card(child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(width: 48, height: 48,
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

// ── Per-item card with press scale ──
class _CircularCard extends StatefulWidget {
  final Circular circular;
  final VoidCallback onTap;
  const _CircularCard({required this.circular, required this.onTap});
  @override
  State<_CircularCard> createState() => _CircularCardState();
}

class _CircularCardState extends State<_CircularCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.circular;
    final isPdf = c.fileType == 'pdf';
    final isImage = c.fileType == 'image';
    final (iconData, iconColor, bgColor) = isPdf
      ? (Icons.picture_as_pdf_rounded, AppColors.primary, const Color(0xFFFEF2F2))
      : isImage
        ? (Icons.image_rounded, AppColors.quickLink, const Color(0xFFEFF6FF))
        : (Icons.insert_drive_file_rounded, AppColors.textMuted, const Color(0xFFF9FAFB));
    final typeLabel = isPdf ? 'PDF' : isImage ? 'Image' : 'File';

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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(children: [
              // File type icon box
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                child: Icon(iconData, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3)),
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
                  Text(c.date, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ]),
              ])),
              // Arrow
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPdf ? Icons.open_in_new_rounded : Icons.open_in_full_rounded,
                  size: 16, color: iconColor),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

