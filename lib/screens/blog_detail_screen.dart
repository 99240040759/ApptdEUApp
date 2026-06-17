import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../models/blog_post.dart';
import '../services/firestore_service.dart';
import '../utils/file_helpers.dart';

class BlogDetailScreen extends StatefulWidget {
  final String slug;
  const BlogDetailScreen({super.key, required this.slug});
  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  BlogPost? _blog;
  bool _loading = true;
  String? _error;
  // FIX: cached once after load — not recomputed on every build
  String? _readTime;

  // Cached RegExps — compile once for all instances
  static final _wordRe = RegExp(r'<[^>]*>');
  static final _spaceRe = RegExp(r'\s+');

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final blog = await FirestoreService().getBlogBySlug(widget.slug);
      if (mounted) {
        setState(() {
          _blog = blog;
          _loading = false;
          if (blog != null) { _readTime = _computeReadTime(blog.content); }
        });
      }
    } catch (e) {
      if (mounted) { setState(() { _error = e.toString(); _loading = false; }); }
    }
  }

  String _computeReadTime(String html) {
    final words = html.replaceAll(_wordRe, ' ').split(_spaceRe).length;
    final mins = (words / 200).ceil();
    return '$mins min read';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) { return const Scaffold(body: Center(child: CircularProgressIndicator())); }
    if (_error != null || _blog == null) { return Scaffold(
      appBar: AppBar(title: const Text('Blog')),
      body: Center(child: Text(_error ?? 'Blog not found', style: const TextStyle(color: Colors.grey))),
    ); }
    final blog = _blog!;
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Share',
              onPressed: () => Share.share('${blog.title}\nhttps://apptd.org/blog/${blog.slug}'),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(fit: StackFit.expand, children: [
              blog.coverImage.isNotEmpty
                ? GestureDetector(
                    onTap: () => openImageViewer(context, blog.coverImage, blog.title),
                    child: Hero(
                      tag: 'blog_${blog.slug}',
                      child: CachedNetworkImage(
                        imageUrl: blog.coverImage, fit: BoxFit.cover, width: double.infinity,
                        placeholder: (_, _) => Container(color: AppColors.primary),
                        errorWidget: (_, _, _) => Container(color: AppColors.primary),
                      ),
                    ),
                  )
                : Container(decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, Color(0xFF7F1D1D)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                  )),
              Positioned(top: 0, left: 0, right: 0, height: 100,
                child: DecoratedBox(decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.black.withAlpha(140), Colors.transparent])))),
              Positioned(bottom: 0, left: 0, right: 0, height: 80,
                child: DecoratedBox(decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [Colors.black.withAlpha(100), Colors.transparent])))),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, runSpacing: 6, children: [
                Chip(
                  label: Text(blog.category, style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  backgroundColor: AppColors.primaryButton,
                  padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, side: BorderSide.none,
                ),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(DateFormat('MMMM d, yyyy').format(blog.createdAt),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ]),
                if (_readTime != null)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(_readTime!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ]),
              ]),
              const SizedBox(height: 14),
              Text(blog.title, style: const TextStyle(
                fontFamily: 'Inter', fontSize: 23, fontWeight: FontWeight.w800,
                height: 1.3, color: AppColors.textDark)),
              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade200, height: 1),
              const SizedBox(height: 12),
              if (blog.content.isEmpty)
                Text('No content available.', style: TextStyle(color: Colors.grey.shade500, fontSize: 15))
              else
                HtmlWidget(
                  blog.content,
                  textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 16, height: 1.8, color: Color(0xFF1F2937)),
                  customStylesBuilder: (el) => switch (el.localName) {
                    'h1' => {'font-size': '26px', 'font-weight': '800', 'margin-top': '20px', 'margin-bottom': '6px'},
                    'h2' => {'font-size': '21px', 'font-weight': '700', 'margin-top': '16px', 'margin-bottom': '6px'},
                    'h3' => {'font-size': '17px', 'font-weight': '600', 'margin-top': '14px', 'margin-bottom': '4px'},
                    'p'  => {'margin-bottom': '12px', 'line-height': '1.8'},
                    'a'  => {'color': '#B91C1C'},
                    'blockquote' => {'border-left': '4px solid #B91C1C', 'padding-left': '16px', 'font-style': 'italic', 'color': '#4B5563'},
                    'code' => {'background-color': '#F3F4F6', 'font-family': 'monospace', 'font-size': '13px', 'padding': '2px 4px'},
                    'pre'  => {'background-color': '#1E293B', 'color': '#E2E8F0', 'font-family': 'monospace', 'font-size': '13px', 'padding': '14px'},
                    'ul' || 'ol' => {'margin-bottom': '12px', 'padding-left': '20px'},
                    'li' => {'margin-bottom': '4px'},
                    _ => null,
                  },
                  onTapUrl: (url) async {
                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    return true;
                  },
                  renderMode: RenderMode.column,
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}
