import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import '../config/theme.dart';
import '../models/circular.dart';
import '../services/firestore_service.dart';

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
      showDialog(context: context, builder: (_) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(title: Text(c.title, overflow: TextOverflow.ellipsis)),
          backgroundColor: Colors.black,
          body: InteractiveViewer(
            child: Center(child: Image.network(c.fileUrl, fit: BoxFit.contain)),
          ),
        ),
      ));
    } else {
      launchUrl(Uri.parse(c.fileUrl), mode: LaunchMode.externalApplication);
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
            hintText: 'Search circulars...', prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); _filter(''); })
              : null,
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
      // List
      Expanded(child: RefreshIndicator(
        color: AppColors.primary, onRefresh: _load,
        child: _loading
          ? ListView.builder(itemCount: 6, itemBuilder: (_, _) => _shimmer())
          : _filtered.isEmpty
            ? ListView(children: const [SizedBox(height: 120), Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.search_off, size: 56, color: AppColors.textMuted),
                SizedBox(height: 8),
                Text('No circulars found', style: TextStyle(color: AppColors.textMuted)),
              ]))])
            : ListView.builder(
                itemCount: _filtered.length,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemBuilder: (_, i) {
                  final c = _filtered[i];
                  final isPdf = c.fileType == 'pdf';
                  return Card(child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPdf ? Colors.red.shade50 : Colors.blue.shade50,
                      child: Icon(isPdf ? Icons.picture_as_pdf : Icons.image, color: isPdf ? AppColors.primary : AppColors.quickLink, size: 22),
                    ),
                    title: Text(c.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: Text(c.date, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    trailing: Icon(isPdf ? Icons.open_in_new : Icons.zoom_in, size: 18, color: AppColors.textMuted),
                    onTap: () => _openFile(c),
                  ));
                },
              ),
      )),
    ]);
  }

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
