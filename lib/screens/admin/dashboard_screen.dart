import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/blog_post.dart';
import '../../models/circular.dart';
import '../../models/union_affair.dart';
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
    // Auth guard — redirect to /admin if user signs out or loses admin
    _authSub = _auth.authStateChanges.listen((user) async {
      if (user == null) {
        if (mounted) Navigator.pushReplacementNamed(context, '/admin');
        return;
      }
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
        bottom: TabBar(controller: _tabCtrl, indicatorColor: Colors.white,
          tabs: const [Tab(text: 'Blogs'), Tab(text: 'Circulars'), Tab(text: 'Union Affairs')]),
        actions: [IconButton(icon: const Icon(Icons.logout), tooltip: 'Logout', onPressed: _logout)],
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

  Future<void> _showEditor([BlogPost? blog]) async {
    final result = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _BlogEditor(fs: widget.fs, blog: blog),
    );
    if (result == true) _load();
  }

  Future<void> _delete(BlogPost b) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete Blog?'),
      content: Text('Delete "${b.title}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (ok == true) { await widget.fs.deleteBlog(b.id, b.coverImage); _load(); }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _blogs.isEmpty
              ? const Center(child: Text('No blogs'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _blogs.length,
                    itemBuilder: (_, i) {
                      final b = _blogs[i];
                      return Card(child: ListTile(
                        title: Text(b.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${b.category} · ${DateFormat('MMM d, yyyy').format(b.createdAt)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showEditor(b)),
                          IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _delete(b)),
                        ]),
                      ));
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryButton,
        onPressed: () => _showEditor(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// BLOG EDITOR BOTTOM SHEET
// ═══════════════════════════════════════════════
class _BlogEditor extends StatefulWidget {
  final FirestoreService fs;
  final BlogPost? blog;
  const _BlogEditor({required this.fs, this.blog});
  @override
  State<_BlogEditor> createState() => _BlogEditorState();
}

class _BlogEditorState extends State<_BlogEditor> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _metaTitleCtrl = TextEditingController();
  final _metaDescCtrl = TextEditingController();
  final _keywordsCtrl = TextEditingController();
  String _category = 'General';
  Uint8List? _imageBytes;
  String? _imageName;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.blog != null) {
      final b = widget.blog!;
      _titleCtrl.text = b.title;
      _contentCtrl.text = b.content;
      _category = b.category;
      _metaTitleCtrl.text = b.metaTitle ?? '';
      _metaDescCtrl.text = b.metaDescription ?? '';
      _keywordsCtrl.text = b.keywords ?? '';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _contentCtrl.dispose();
    _metaTitleCtrl.dispose(); _metaDescCtrl.dispose(); _keywordsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() { _imageBytes = bytes; _imageName = picked.name; });
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and content required')));
      return;
    }
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final blog = BlogPost(
        id: widget.blog?.id ?? '',
        title: _titleCtrl.text.trim(),
        slug: BlogPost.generateSlug(_titleCtrl.text.trim()),
        category: _category,
        content: _contentCtrl.text.trim(),
        coverImage: widget.blog?.coverImage ?? '',
        excerpt: _contentCtrl.text.trim().length > 150 ? '${_contentCtrl.text.trim().substring(0, 150)}...' : _contentCtrl.text.trim(),
        metaTitle: _metaTitleCtrl.text.trim().isEmpty ? null : _metaTitleCtrl.text.trim(),
        metaDescription: _metaDescCtrl.text.trim().isEmpty ? null : _metaDescCtrl.text.trim(),
        keywords: _keywordsCtrl.text.trim().isEmpty ? null : _keywordsCtrl.text.trim(),
        createdAt: widget.blog?.createdAt ?? now,
        updatedAt: now,
      );
      if (widget.blog != null) {
        await widget.fs.updateBlog(blog, coverImageBytes: _imageBytes, coverImageName: _imageName);
      } else {
        await widget.fs.createBlog(blog, coverImageBytes: _imageBytes, coverImageName: _imageName);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.blog != null;
    return DraggableScrollableSheet(
      initialChildSize: 0.92, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
      builder: (_, ctrl) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: ListView(controller: ctrl, children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          Text(isEdit ? 'Edit Blog' : 'Create Blog',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _field(_titleCtrl, 'Title'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
            items: AppConstants.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (String? v) { if (v != null) setState(() => _category = v); },
          ),
          const SizedBox(height: 12),
          _field(_contentCtrl, 'Content', maxLines: 10),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image),
            label: Text(_imageName ?? (isEdit ? 'Change Cover' : 'Pick Cover Image')),
          ),
          const SizedBox(height: 16),
          ExpansionTile(title: const Text('SEO Fields', style: TextStyle(fontSize: 14)), children: [
            _field(_metaTitleCtrl, 'Meta Title'),
            const SizedBox(height: 10),
            _field(_metaDescCtrl, 'Meta Description', maxLines: 2),
            const SizedBox(height: 10),
            _field(_keywordsCtrl, 'Keywords (comma-separated)'),
            const SizedBox(height: 8),
          ]),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(isEdit ? 'Update' : 'Publish'),
          )),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {int maxLines = 1}) => TextFormField(
    controller: ctrl, maxLines: maxLines,
    decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
  );
}

// ═══════════════════════════════════════════════
// FILES TAB (Circulars & Union Affairs)
// ═══════════════════════════════════════════════
class _FilesTab extends StatefulWidget {
  final FirestoreService fs;
  final String collection;
  const _FilesTab({required this.fs, required this.collection});
  @override
  State<_FilesTab> createState() => _FilesTabState();
}

class _FilesTabState extends State<_FilesTab> with AutomaticKeepAliveClientMixin {
  List<dynamic> _items = [];
  bool _loading = true;
  @override
  bool get wantKeepAlive => true;
  bool get _isCirculars => widget.collection == 'circulars';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = _isCirculars ? await widget.fs.getCirculars() : await widget.fs.getUnionAffairs();
      if (mounted) setState(() { _items = list; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  String _title(dynamic item) => _isCirculars ? (item as Circular).title : (item as UnionAffair).title;
  String _date(dynamic item) => _isCirculars ? (item as Circular).date : (item as UnionAffair).date;
  String _id(dynamic item) => _isCirculars ? (item as Circular).id : (item as UnionAffair).id;
  String _url(dynamic item) => _isCirculars ? (item as Circular).fileUrl : (item as UnionAffair).fileUrl;
  String _type(dynamic item) => _isCirculars ? (item as Circular).fileType : (item as UnionAffair).fileType;

  Future<void> _upload() async {
    final titleCtrl = TextEditingController();
    Uint8List? bytes;
    String? fileName;
    bool uploading = false;
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) => AlertDialog(
        title: Text('Upload ${_isCirculars ? 'Circular' : 'Union Affair'}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.attach_file),
            label: Text(fileName ?? 'Pick File'),
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: _isCirculars
                    ? ['pdf', 'jpg', 'jpeg', 'png']
                    : ['pdf', 'jpg', 'jpeg', 'png', 'mp3', 'wav', 'aac', 'm4a'],
                withData: true,
              );
              if (result != null && result.files.single.bytes != null) {
                setSt(() { bytes = result.files.single.bytes; fileName = result.files.single.name; });
              }
            },
          ),
          if (uploading) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: uploading ? null : () async {
              if (titleCtrl.text.trim().isEmpty || bytes == null) return;
              setSt(() => uploading = true);
              try {
                if (_isCirculars) {
                  await widget.fs.createCircular(titleCtrl.text.trim(), bytes!, fileName!);
                } else {
                  await widget.fs.createUnionAffair(titleCtrl.text.trim(), bytes!, fileName!);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              } catch (e) { setSt(() => uploading = false); }
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    ));
    titleCtrl.dispose();
  }

  Future<void> _delete(dynamic item) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete?'),
      content: Text('Delete "${_title(item)}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (ok == true) {
      if (_isCirculars) {
        await widget.fs.deleteCircular(_id(item), _url(item));
      } else {
        await widget.fs.deleteUnionAffair(_id(item), _url(item));
      }
      _load();
    }
  }

  IconData _icon(String type) => switch (type) {
    'pdf' => Icons.picture_as_pdf,
    'image' => Icons.image,
    'audio' => Icons.audiotrack,
    _ => Icons.insert_drive_file,
  };

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text('No ${_isCirculars ? 'circulars' : 'union affairs'}'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      return Card(child: ListTile(
                        leading: Icon(_icon(_type(item)), color: _type(item) == 'audio' ? AppColors.audioPurple : AppColors.primaryButton),
                        title: Text(_title(item), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(_date(item), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        trailing: IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _delete(item)),
                      ));
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryButton,
        onPressed: _upload,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
