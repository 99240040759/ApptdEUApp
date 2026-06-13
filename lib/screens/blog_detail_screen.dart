import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../config/theme.dart';
import '../models/blog_post.dart';
import '../services/firestore_service.dart';

// ── Custom image embed builder ──
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
          imageUrl: url, fit: BoxFit.contain,
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

String _readTime(String text) {
  final words = text.trim().split(RegExp(r'\s+')).length;
  final mins = (words / 200).ceil().clamp(1, 999);
  return '$mins min read';
}

class BlogDetailScreen extends StatefulWidget {
  final String slug;
  final BlogPost? blog;
  const BlogDetailScreen({super.key, required this.slug, this.blog});
  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  BlogPost? _blog;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.blog != null) { _blog = widget.blog; _loading = false; }
    else { _fetchBlog(); }
  }

  Future<void> _fetchBlog() async {
    try {
      final blog = await FirestoreService().getBlogBySlug(widget.slug);
      if (mounted) setState(() { _blog = blog; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (_blog == null) {
      return Scaffold(appBar: AppBar(),
        body: const Center(child: Text('Post not found')));
    }
    final blog = _blog!;
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 280, pinned: true,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: () => Share.share('${blog.title}\nhttps://apptd.org/blog/${blog.slug}'),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(fit: StackFit.expand, children: [
              // Cover image with Hero
              blog.coverImage.isNotEmpty
                ? Hero(
                    tag: 'blog_${blog.slug}',
                    child: CachedNetworkImage(
                      imageUrl: blog.coverImage, fit: BoxFit.cover, width: double.infinity,
                      placeholder: (_, _) => Container(color: AppColors.primary),
                      errorWidget: (_, _, _) => Container(color: AppColors.primary),
                    ),
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, Color(0xFF7F1D1D)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                    ),
                  ),
              // ── Status-bar shadow so OS icons stay readable ──
              Positioned(
                top: 0, left: 0, right: 0, height: 100,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.black.withAlpha(140), Colors.transparent],
                    ),
                  ),
                ),
              ),
              // Bottom gradient for title area readability
              Positioned(
                bottom: 0, left: 0, right: 0, height: 80,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [Colors.black.withAlpha(100), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Category + date + read time
              Wrap(spacing: 8, runSpacing: 6, children: [
                Chip(
                  label: Text(blog.category, style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  backgroundColor: AppColors.primaryButton,
                  padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: BorderSide.none,
                ),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(DateFormat('MMMM d, yyyy').format(blog.createdAt),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ]),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(_readTime(blog.content),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ]),
              ]),
              const SizedBox(height: 14),
              // Title
              Text(blog.title, style: GoogleFonts.inter(
                fontSize: 23, fontWeight: FontWeight.w800, height: 1.3,
                color: AppColors.textDark)),
              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade200, height: 1),
              const SizedBox(height: 16),
              // Rich content
              _BlogContent(blog: blog),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _BlogContent extends StatefulWidget {
  final BlogPost blog;
  const _BlogContent({required this.blog});
  @override
  State<_BlogContent> createState() => _BlogContentState();
}

class _BlogContentState extends State<_BlogContent> {
  late final QuillController _ctrl;
  final _focus = FocusNode(canRequestFocus: false);
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.blog.contentDelta != null && widget.blog.contentDelta!.isNotEmpty) {
      try {
        _ctrl = QuillController(
          document: Document.fromJson(jsonDecode(widget.blog.contentDelta!)),
          selection: const TextSelection.collapsed(offset: 0));
        return;
      } catch (_) {}
    }
    final doc = Document();
    if (widget.blog.content.isNotEmpty) { doc.insert(0, widget.blog.content); }
    _ctrl = QuillController(document: doc, selection: const TextSelection.collapsed(offset: 0));
  }

  @override
  void dispose() { _ctrl.dispose(); _focus.dispose(); _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: QuillEditor(
        controller: _ctrl,
        focusNode: _focus,
        scrollController: _scroll,
        config: QuillEditorConfig(
          padding: EdgeInsets.zero,
          expands: false,
          scrollable: false,
          embedBuilders: _embedBuilders,
          customStyles: DefaultStyles(
            paragraph: DefaultTextBlockStyle(
              GoogleFonts.inter(fontSize: 16, height: 1.8, color: const Color(0xFF1F2937)),
              HorizontalSpacing.zero, const VerticalSpacing(2, 2), VerticalSpacing.zero, null,
            ),
            h1: DefaultTextBlockStyle(
              GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textDark),
              HorizontalSpacing.zero, const VerticalSpacing(20, 6), VerticalSpacing.zero, null,
            ),
            h2: DefaultTextBlockStyle(
              GoogleFonts.inter(fontSize: 21, fontWeight: FontWeight.w700, color: AppColors.textDark),
              HorizontalSpacing.zero, const VerticalSpacing(16, 6), VerticalSpacing.zero, null,
            ),
            h3: DefaultTextBlockStyle(
              GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textDark),
              HorizontalSpacing.zero, const VerticalSpacing(14, 4), VerticalSpacing.zero, null,
            ),
            bold: const TextStyle(fontWeight: FontWeight.w700),
            italic: const TextStyle(fontStyle: FontStyle.italic),
            underline: const TextStyle(decoration: TextDecoration.underline),
          ),
        ),
      ),
    );
  }
}
