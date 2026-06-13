import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../config/theme.dart';
import '../models/blog_post.dart';
import '../services/firestore_service.dart';

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
    if (widget.blog != null) {
      _blog = widget.blog; _loading = false;
    } else {
      _fetchBlog();
    }
  }

  Future<void> _fetchBlog() async {
    try {
      final blog = await FirestoreService().getBlogBySlug(widget.slug);
      if (mounted) setState(() { _blog = blog; _loading = false; });
    } catch (_) { if (mounted) { setState(() => _loading = false); } }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator(color: AppColors.primary)));
    if (_blog == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Post not found')));
    final blog = _blog!;
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 260, pinned: true,
          backgroundColor: AppColors.primary,
          actions: [
            IconButton(icon: const Icon(Icons.share_rounded), onPressed: () {
              SharePlus.instance.share(ShareParams(text: '${blog.title}\nhttps://apptd.org/blog/${blog.slug}'));
            }),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: blog.coverImage.isNotEmpty
              ? Hero(tag: 'blog_${blog.slug}', child: CachedNetworkImage(
                  imageUrl: blog.coverImage, fit: BoxFit.cover, width: double.infinity,
                  errorWidget: (_, _, _) => Container(color: AppColors.primary)))
              : Container(color: AppColors.primary),
          ),
        ),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Chip(
                label: Text(blog.category, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                backgroundColor: AppColors.primaryButton, padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: BorderSide.none,
              ),
              const SizedBox(width: 12),
              Icon(Icons.calendar_today, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(DateFormat('MMMM d, yyyy').format(blog.createdAt),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ]),
            const SizedBox(height: 14),
            Text(blog.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.3)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 4),
            // Renders plain text with newlines preserved — matches website's whitespace-pre-wrap
            SelectableText(
              blog.content,
              style: const TextStyle(fontSize: 15, height: 1.7, color: AppColors.textDark),
            ),
            const SizedBox(height: 32),
          ]),
        )),
      ]),
    );
  }
}
