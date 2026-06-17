import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../models/blog_post.dart';
import '../../models/file_item.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl = TabController(length: 3, vsync: this);
  final _fs = FirestoreService();
  final _auth = AuthService();
  StreamSubscription<User?>? _authSub;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _authSub = _auth.authStateChanges.listen((user) async {
      if (user == null) { if (mounted) Navigator.pushReplacementNamed(context, '/admin'); return; }
      final admin = await _auth.checkIsAdmin();
      if (!admin && mounted) Navigator.pushReplacementNamed(context, '/admin');
      if (mounted) setState(() => _currentUser = user);
    });
  }

  @override
  void dispose() { _tabCtrl.dispose(); _authSub?.cancel(); super.dispose(); }

  Future<void> _logout() async {
    await _auth.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/admin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Admin Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          if (_currentUser?.email != null)
            Text(_currentUser!.email!, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white, labelColor: Colors.white,
          unselectedLabelColor: Colors.white60, indicatorWeight: 3,
          tabs: const [Tab(text: 'Blogs'), Tab(text: 'Circulars'), Tab(text: 'Union Affairs')],
        ),
        actions: [IconButton(icon: const Icon(Icons.logout_rounded), tooltip: 'Logout', onPressed: _logout)],
      ),
      body: TabBarView(controller: _tabCtrl, children: [
        _BlogsTab(fs: _fs),
        _FilesTab(fs: _fs, collection: 'circulars'),
        _FilesTab(fs: _fs, collection: 'union_affairs'),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════
// BLOGS TAB
// ═══════════════════════════════════════════════
class _BlogsTab extends StatefulWidget {
  final FirestoreService fs;
  const _BlogsTab({required this.fs});
  @override
  State<_BlogsTab> createState() => _BlogsTabState();
}

class _BlogsTabState extends State<_BlogsTab> with AutomaticKeepAliveClientMixin {
  List<BlogPost> _blogs = [];
  bool _loading = true;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await widget.fs.getBlogs();
      if (mounted) setState(() { _blogs = list; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _delete(BlogPost b) async {
    final ok = await _confirmDelete(context, b.title);
    if (ok != true || !mounted) return;
    await _runDelete(context, () => widget.fs.deleteBlog(b.id, b.coverImage));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: _loading
          ? _loadingShimmer()
          : _blogs.isEmpty
              ? _emptyState('No blogs yet', Icons.article_outlined)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: _blogs.length,
                    itemBuilder: (_, i) => _AdminBlogCard(
                      blog: _blogs[i], onDelete: () => _delete(_blogs[i])),
                  ),
                ),
    );
  }
}

class _AdminBlogCard extends StatelessWidget {
  final BlogPost blog;
  final VoidCallback onDelete;
  const _AdminBlogCard({required this.blog, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        leading: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(15), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.article_rounded, color: AppColors.primary, size: 22),
        ),
        title: Text(blog.title,
          style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 14),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${blog.category} · ${DateFormat('MMM d, yyyy').format(blog.createdAt)}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        trailing: IconButton(
          icon: Icon(Icons.delete_rounded, size: 20, color: Colors.red.shade400),
          onPressed: onDelete, tooltip: 'Delete',
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// FILES TAB (Circulars & Union Affairs)
// Uses unified FileItem model — no more List<dynamic> or cast helpers
// ═══════════════════════════════════════════════
class _FilesTab extends StatefulWidget {
  final FirestoreService fs;
  final String collection;
  const _FilesTab({required this.fs, required this.collection});
  @override
  State<_FilesTab> createState() => _FilesTabState();
}

class _FilesTabState extends State<_FilesTab> with AutomaticKeepAliveClientMixin {
  List<FileItem> _items = [];
  bool _loading = true;
  @override
  bool get wantKeepAlive => true;
  bool get _isCirculars => widget.collection == 'circulars';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = _isCirculars
          ? await widget.fs.getCirculars()
          : await widget.fs.getUnionAffairs();
      if (mounted) setState(() { _items = list; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _showUpload() async {
    final uploaded = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UploadSheet(fs: widget.fs, isCirculars: _isCirculars),
    );
    if (uploaded == true) _load();
  }

  Future<void> _delete(FileItem item) async {
    final ok = await _confirmDelete(context, item.title);
    if (ok != true || !mounted) return;
    await _runDelete(context, () => _isCirculars
        ? widget.fs.deleteCircular(item.id, item.fileUrl)
        : widget.fs.deleteUnionAffair(item.id, item.fileUrl));
    _load();
  }

  IconData _icon(String type) => switch (type) {
    'pdf' => Icons.picture_as_pdf_rounded,
    'image' => Icons.image_rounded,
    'audio' => Icons.audiotrack_rounded,
    _ => Icons.insert_drive_file_rounded,
  };
  Color _iconColor(String type) => switch (type) {
    'audio' => AppColors.audioPurple,
    'image' => AppColors.quickLink,
    _ => AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: _loading
          ? _loadingShimmer()
          : _items.isEmpty
              ? _emptyState('No ${_isCirculars ? 'circulars' : 'union affairs'}', Icons.folder_open_rounded)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      final color = _iconColor(item.fileType);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                          leading: Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: color.withAlpha(15), borderRadius: BorderRadius.circular(10)),
                            child: Icon(_icon(item.fileType), color: color, size: 22),
                          ),
                          title: Text(item.title,
                            style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 14),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            '${item.fileType.toUpperCase()} · ${item.date}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_rounded, size: 20, color: Colors.red.shade400),
                            onPressed: () => _delete(item), tooltip: 'Delete',
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryButton, foregroundColor: Colors.white,
        onPressed: _showUpload,
        icon: const Icon(Icons.upload_rounded),
        label: Text('Upload ${_isCirculars ? 'Circular' : 'File'}',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// UPLOAD BOTTOM SHEET WITH REAL PROGRESS
// ═══════════════════════════════════════════════
class _UploadSheet extends StatefulWidget {
  final FirestoreService fs;
  final bool isCirculars;
  const _UploadSheet({required this.fs, required this.isCirculars});
  @override
  State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> {
  final _titleCtrl = TextEditingController();
  Uint8List? _bytes;
  String? _fileName;
  String? _fileType;
  double? _progress;
  String? _error;

  @override
  void dispose() { _titleCtrl.dispose(); super.dispose(); }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: widget.isCirculars
          ? ['pdf', 'jpg', 'jpeg', 'png']
          : ['pdf', 'jpg', 'jpeg', 'png', 'mp3', 'wav', 'aac', 'm4a'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _bytes = result.files.single.bytes!;
        _fileName = result.files.single.name;
        _fileType = result.files.single.extension?.toLowerCase();
        _error = null;
      });
    }
  }

  Future<void> _upload() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a title.');
      return;
    }
    if (_bytes == null || _fileName == null) {
      setState(() => _error = 'Please pick a file first.');
      return;
    }
    setState(() { _progress = 0.0; _error = null; });
    try {
      if (widget.isCirculars) {
        await widget.fs.createCircularWithProgress(
          _titleCtrl.text.trim(), _bytes!, _fileName!,
          onProgress: (p) { if (mounted) setState(() => _progress = p); },
        );
      } else {
        await widget.fs.createUnionAffairWithProgress(
          _titleCtrl.text.trim(), _bytes!, _fileName!,
          onProgress: (p) { if (mounted) setState(() => _progress = p); },
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() { _progress = null; _error = e.toString(); });
    }
  }

  bool get _isUploading => _progress != null;

  @override
  Widget build(BuildContext context) {
    final sheetLabel = widget.isCirculars ? 'Circular' : 'Union Affairs File';
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20,
        20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text('Upload $sheetLabel',
          style: const TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 18),
        TextField(
          controller: _titleCtrl, enabled: !_isUploading,
          decoration: InputDecoration(
            labelText: 'Title', hintText: 'Enter title…',
            prefixIcon: const Icon(Icons.title_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true, fillColor: Colors.grey.shade50,
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: _isUploading ? null : _pickFile,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity, padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _bytes != null ? AppColors.primary.withAlpha(8) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _bytes != null ? AppColors.primary.withAlpha(80) : Colors.grey.shade300,
                width: _bytes != null ? 1.5 : 1,
              ),
            ),
            child: _bytes == null
                ? Column(children: [
                    Icon(Icons.upload_file_rounded, size: 36, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text('Tap to choose file',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Text(widget.isCirculars ? 'PDF, JPG, PNG' : 'PDF, JPG, PNG, MP3, WAV, AAC',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                  ])
                : Row(children: [
                    _fileTypeIcon(_fileType),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_fileName!, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(_fileType?.toUpperCase() ?? 'FILE',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ])),
                    if (!_isUploading)
                      TextButton(onPressed: _pickFile, child: const Text('Change')),
                  ]),
          ),
        ),
        const SizedBox(height: 14),
        if (_isUploading) ...[
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Uploading…', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text('${(_progress! * 100).toInt()}%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progress, minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            )),
          const SizedBox(height: 14),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12))),
            ]),
          ),
        SizedBox(
          width: double.infinity, height: 50,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryButton,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isUploading ? null : _upload,
            icon: _isUploading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.cloud_upload_rounded, size: 20),
            label: Text(
              _isUploading ? 'Uploading ${(_progress! * 100).toInt()}%…' : 'Upload',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _fileTypeIcon(String? ext) {
    final (icon, color) = switch (ext) {
      'pdf' => (Icons.picture_as_pdf_rounded, AppColors.primary),
      'jpg' || 'jpeg' || 'png' => (Icons.image_rounded, AppColors.quickLink),
      'mp3' || 'wav' || 'aac' || 'm4a' => (Icons.audiotrack_rounded, AppColors.audioPurple),
      _ => (Icons.insert_drive_file_rounded, AppColors.textMuted),
    };
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(color: color.withAlpha(18), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

// ═══════════════════════════════════════════════
// SHARED HELPERS
// ═══════════════════════════════════════════════
Future<bool?> _confirmDelete(BuildContext ctx, String title) => showDialog<bool>(
  context: ctx,
  builder: (dialogCtx) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: const Row(children: [
      Icon(Icons.delete_rounded, color: Colors.red, size: 22),
      SizedBox(width: 10),
      Text('Delete?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    ]),
    content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('This action cannot be undone.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel')),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        onPressed: () => Navigator.pop(dialogCtx, true),
        child: const Text('Delete'),
      ),
    ],
  ),
);

Future<void> _runDelete(BuildContext ctx, Future<void> Function() deleteFn) async {
  showDialog(context: ctx, barrierDismissible: false,
    builder: (_) => const AlertDialog(
      content: Row(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(strokeWidth: 2),
        SizedBox(width: 16),
        Text('Deleting…'),
      ]),
    ));
  try {
    await deleteFn();
    if (ctx.mounted) Navigator.pop(ctx);
  } catch (e) {
    if (ctx.mounted) {
      Navigator.pop(ctx);
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }
}

// FIX: actual Shimmer animation instead of static grey boxes
Widget _loadingShimmer() => Shimmer.fromColors(
  baseColor: Colors.grey.shade200, highlightColor: Colors.grey.shade50,
  child: ListView.builder(
    padding: const EdgeInsets.all(10),
    itemCount: 6,
    itemBuilder: (_, _) => Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(width: 42, height: 42,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
        title: Container(height: 14, width: 200, color: Colors.white),
        subtitle: Container(height: 11, width: 100, color: Colors.white),
      ),
    ),
  ),
);

Widget _emptyState(String msg, IconData icon) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
  Icon(icon, size: 64, color: AppColors.textMuted.withAlpha(100)),
  const SizedBox(height: 12),
  Text(msg, style: const TextStyle(color: AppColors.textMuted, fontSize: 15)),
  const SizedBox(height: 4),
  const Text('Tap + to add one', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
]));
