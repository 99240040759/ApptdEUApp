import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/blog_post.dart';
import '../../services/firestore_service.dart';

// ── Custom image embed builder (no flutter_quill_extensions needed) ──
class _ImageEmbedBuilder extends EmbedBuilder {
  const _ImageEmbedBuilder();
  @override
  String get key => BlockEmbed.imageType;
  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final url = embedContext.node.value.data as String;
    if (url.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          placeholder: (_, _) => Container(height: 160, color: Colors.grey.shade100,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
          errorWidget: (_, _, _) => Container(height: 80, color: Colors.grey.shade100,
            child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey))),
        ),
      ),
    );
  }
}

const _embedBuilders = [_ImageEmbedBuilder()];

class BlogEditorScreen extends StatefulWidget {
  final BlogPost? blog;
  const BlogEditorScreen({super.key, this.blog});
  @override
  State<BlogEditorScreen> createState() => _BlogEditorScreenState();
}

class _BlogEditorScreenState extends State<BlogEditorScreen> {
  final _fs = FirestoreService();
  final _titleCtrl = TextEditingController();
  final _metaTitleCtrl = TextEditingController();
  final _metaDescCtrl = TextEditingController();
  final _keywordsCtrl = TextEditingController();
  late final QuillController _quill;
  final _editorFocus = FocusNode();
  final _editorScroll = ScrollController();

  String _category = 'General';
  Uint8List? _imageBytes;
  String? _imageName;
  bool _saving = false;
  bool _preview = false;
  bool _insertingImage = false;

  @override
  void initState() {
    super.initState();
    final b = widget.blog;
    _quill = b?.contentDelta != null
        ? QuillController(
            document: Document.fromJson(jsonDecode(b!.contentDelta!)),
            selection: const TextSelection.collapsed(offset: 0))
        : QuillController.basic();
    if (b != null) {
      _titleCtrl.text = b.title;
      _category = b.category;
      _metaTitleCtrl.text = b.metaTitle ?? '';
      _metaDescCtrl.text = b.metaDescription ?? '';
      _keywordsCtrl.text = b.keywords ?? '';
    }
  }

  @override
  void dispose() {
    _quill.dispose(); _editorFocus.dispose(); _editorScroll.dispose();
    _titleCtrl.dispose(); _metaTitleCtrl.dispose();
    _metaDescCtrl.dispose(); _keywordsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() { _imageBytes = bytes; _imageName = picked.name; });
    }
  }

  Future<void> _insertImageInEditor() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (picked == null) return;
    setState(() => _insertingImage = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await _fs.uploadBlogImage(bytes, picked.name);
      final index = _quill.selection.baseOffset;
      final length = _quill.selection.extentOffset - index;
      _quill.replaceText(index, length, BlockEmbed.image(url), null);
    } catch (e) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image upload failed: $e'))); }
    } finally {
      if (mounted) { setState(() => _insertingImage = false); }
    }
  }

  String _plainText() => _quill.document.toPlainText().trim();

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }
    if (_plainText().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Content cannot be empty')));
      return;
    }
    setState(() => _saving = true);
    try {
      final plain = _plainText();
      final delta = jsonEncode(_quill.document.toDelta().toJson());
      final now = DateTime.now();
      final blog = BlogPost(
        id: widget.blog?.id ?? '',
        title: _titleCtrl.text.trim(),
        slug: BlogPost.generateSlug(_titleCtrl.text.trim()),
        category: _category,
        content: plain,
        contentDelta: delta,
        coverImage: widget.blog?.coverImage ?? '',
        excerpt: plain.length > 150 ? '${plain.substring(0, 150)}...' : plain,
        metaTitle: _metaTitleCtrl.text.trim().isEmpty ? null : _metaTitleCtrl.text.trim(),
        metaDescription: _metaDescCtrl.text.trim().isEmpty ? null : _metaDescCtrl.text.trim(),
        keywords: _keywordsCtrl.text.trim().isEmpty ? null : _keywordsCtrl.text.trim(),
        createdAt: widget.blog?.createdAt ?? now,
        updatedAt: now,
      );
      if (widget.blog != null) {
        await _fs.updateBlog(blog, coverImageBytes: _imageBytes, coverImageName: _imageName);
      } else {
        await _fs.createBlog(blog, coverImageBytes: _imageBytes, coverImageName: _imageName);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(isEdit ? 'Edit Post' : 'New Post',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(_preview ? Icons.edit_rounded : Icons.preview_rounded),
            tooltip: _preview ? 'Edit' : 'Preview',
            onPressed: () => setState(() => _preview = !_preview),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _saving
                ? const SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _save,
                    icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                    label: Text(isEdit ? 'Update' : 'Publish',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
          ),
        ],
      ),
      body: _preview ? _buildPreview() : _buildEditor(),
    );
  }

  Widget _buildEditor() {
    return Column(children: [
      // ── Title + Category + Cover ──
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: _titleCtrl,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'Post title…',
              hintStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700,
                color: Colors.grey.shade400),
              border: InputBorder.none,
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category', border: OutlineInputBorder(),
                  isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: AppConstants.categories
                    .map((c) => DropdownMenuItem(value: c,
                        child: Text(c, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) { if (v != null) setState(() => _category = v); },
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: _pickCover,
              icon: _imageBytes != null
                  ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16)
                  : const Icon(Icons.image_rounded, size: 16),
              label: Text(
                _imageBytes != null ? 'Cover set'
                  : (widget.blog?.coverImage.isNotEmpty == true ? 'Change cover' : 'Cover'),
                style: const TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                side: BorderSide(color: _imageBytes != null ? Colors.green : Colors.grey.shade400),
              ),
            ),
          ]),
          const SizedBox(height: 10),
        ]),
      ),

      // ── Quill Toolbar + Insert Image button ──
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4,
            offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          QuillSimpleToolbar(
            controller: _quill,
            config: QuillSimpleToolbarConfig(
              showFontFamily: false,
              showFontSize: true,
              showBoldButton: true,
              showItalicButton: true,
              showUnderLineButton: true,
              showStrikeThrough: true,
              showColorButton: true,
              showBackgroundColorButton: true,
              showClearFormat: true,
              showAlignmentButtons: true,
              showLeftAlignment: true,
              showCenterAlignment: true,
              showRightAlignment: true,
              showJustifyAlignment: false,
              showHeaderStyle: true,
              showListNumbers: true,
              showListBullets: true,
              showListCheck: false,
              showCodeBlock: true,
              showQuote: true,
              showIndent: true,
              showLink: true,
              showUndo: true,
              showRedo: true,
              showSearchButton: false,
              showSubscript: false,
              showSuperscript: false,
              showInlineCode: true,
              embedButtons: const [],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: _insertingImage
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : TextButton.icon(
                    onPressed: _insertImageInEditor,
                    icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
                    label: const Text('Insert Image', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      foregroundColor: AppColors.primary,
                    ),
                  ),
          ),
        ]),
      ),

      // ── Quill Editor ──
      Expanded(
        child: Container(
          color: Colors.white,
          margin: const EdgeInsets.only(top: 4),
          child: QuillEditor(
            controller: _quill,
            focusNode: _editorFocus,
            scrollController: _editorScroll,
            config: QuillEditorConfig(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              placeholder: 'Start writing your post…',
              embedBuilders: _embedBuilders,
              customStyles: DefaultStyles(
                paragraph: DefaultTextBlockStyle(
                  GoogleFonts.inter(fontSize: 15, height: 1.7, color: const Color(0xFF1A1A1A)),
                  HorizontalSpacing.zero, VerticalSpacing.zero, VerticalSpacing.zero, null,
                ),
                h1: DefaultTextBlockStyle(
                  GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A1A)),
                  HorizontalSpacing.zero, const VerticalSpacing(16, 4), VerticalSpacing.zero, null,
                ),
                h2: DefaultTextBlockStyle(
                  GoogleFonts.inter(fontSize: 21, fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A)),
                  HorizontalSpacing.zero, const VerticalSpacing(14, 4), VerticalSpacing.zero, null,
                ),
                h3: DefaultTextBlockStyle(
                  GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A)),
                  HorizontalSpacing.zero, const VerticalSpacing(12, 4), VerticalSpacing.zero, null,
                ),
              ),
            ),
          ),
        ),
      ),

      // ── SEO fields ──
      Material(
        color: Colors.white,
        child: ExpansionTile(
          title: const Text('SEO Fields',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(children: [
                _seoField(_metaTitleCtrl, 'Meta Title'),
                const SizedBox(height: 10),
                _seoField(_metaDescCtrl, 'Meta Description', maxLines: 2),
                const SizedBox(height: 10),
                _seoField(_keywordsCtrl, 'Keywords (comma-separated)'),
              ]),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_imageBytes != null)
          ClipRRect(borderRadius: BorderRadius.circular(12),
            child: Image.memory(_imageBytes!, width: double.infinity, height: 200, fit: BoxFit.cover))
        else if (widget.blog?.coverImage.isNotEmpty == true)
          ClipRRect(borderRadius: BorderRadius.circular(12),
            child: Image.network(widget.blog!.coverImage,
              width: double.infinity, height: 200, fit: BoxFit.cover)),
        const SizedBox(height: 16),
        if (_titleCtrl.text.isNotEmpty)
          Text(_titleCtrl.text,
            style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, height: 1.3)),
        const SizedBox(height: 8),
        Chip(
          label: Text(_category,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.primaryButton,
          padding: EdgeInsets.zero, visualDensity: VisualDensity.compact, side: BorderSide.none,
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        IgnorePointer(
          child: QuillEditor(
            controller: _quill,
            focusNode: FocusNode(canRequestFocus: false),
            scrollController: ScrollController(),
            config: QuillEditorConfig(
              padding: EdgeInsets.zero,
              expands: false,
              scrollable: false,
              embedBuilders: _embedBuilders,
              customStyles: DefaultStyles(
                paragraph: DefaultTextBlockStyle(
                  GoogleFonts.inter(fontSize: 15, height: 1.7, color: const Color(0xFF1A1A1A)),
                  HorizontalSpacing.zero, VerticalSpacing.zero, VerticalSpacing.zero, null,
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _seoField(TextEditingController ctrl, String label, {int maxLines = 1}) =>
      TextField(
        controller: ctrl, maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label, border: const OutlineInputBorder(),
          isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        style: const TextStyle(fontSize: 13),
      );
}
