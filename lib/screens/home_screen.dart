import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../config/theme.dart';
import '../models/blog_post.dart';
import '../services/firestore_service.dart';
import 'blog_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<BlogPost>? _blogs;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final blogs = await FirestoreService().getBlogs();
      if (mounted) setState(() { _blogs = blogs; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: CustomScrollView(slivers: [
        // ── Full-width banner ──
        SliverToBoxAdapter(
          child: Container(
            color: AppColors.primary,
            width: double.infinity,
            child: Image.asset(
              'assets/images/banner.png',
              width: double.infinity, fit: BoxFit.fitWidth,
              errorBuilder: (_, _, _) => Container(height: 120, color: AppColors.primary),
            ),
          ),
        ),
        // ── Section header ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
            child: Row(children: [
              Container(width: 4, height: 20,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text('Latest Posts', style: TextStyle(fontFamily: 'Inter',
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            ]),
          ),
        ),
        // ── Content ──
        if (_loading)
          SliverList(delegate: SliverChildBuilderDelegate(
            (_, i) => _shimmerCard(), childCount: 4))
        else if (_error != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.textMuted),
                const SizedBox(height: 10),
                const Text('Failed to load posts', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
                const SizedBox(height: 4),
                Text(_error!, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ]),
            )),
          )
        else if (_blogs == null || _blogs!.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.article_outlined, size: 72, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text('No posts yet', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
            ])),
          )
        else
          SliverList(delegate: SliverChildBuilderDelegate(
            (_, i) => _BlogCard(blog: _blogs![i]), childCount: _blogs!.length)),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ]),
    );
  }

  Widget _shimmerCard() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Card(clipBehavior: Clip.antiAlias, child: Shimmer.fromColors(
      baseColor: Colors.grey.shade200, highlightColor: Colors.grey.shade50,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 190, color: Colors.white),
        Padding(padding: const EdgeInsets.all(14), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(height: 22, width: 70, decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(20))),
              const Spacer(),
              Container(height: 12, width: 80, color: Colors.white),
            ]),
            const SizedBox(height: 12),
            Container(height: 16, width: double.infinity, color: Colors.white),
            const SizedBox(height: 6),
            Container(height: 16, width: 220, color: Colors.white),
            const SizedBox(height: 10),
            Container(height: 12, width: double.infinity, color: Colors.white),
            const SizedBox(height: 4),
            Container(height: 12, width: 180, color: Colors.white),
          ])),
      ]),
    )),
  );
}

// ── Per-card StatefulWidget for press-scale animation ──
class _BlogCard extends StatefulWidget {
  final BlogPost blog;
  const _BlogCard({required this.blog});
  @override
  State<_BlogCard> createState() => _BlogCardState();
}

class _BlogCardState extends State<_BlogCard> {
  bool _pressed = false;

  void _open() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BlogDetailScreen(slug: widget.blog.slug),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final blog = widget.blog;
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) { setState(() => _pressed = false); _open(); },
            onTapCancel: () => setState(() => _pressed = false),
            splashColor: AppColors.primary.withAlpha(15),
            highlightColor: AppColors.primary.withAlpha(8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Cover image with Hero ──
              if (blog.coverImage.isNotEmpty)
                Hero(
                  tag: 'blog_${blog.slug}',
                  child: CachedNetworkImage(
                    imageUrl: blog.coverImage,
                    height: 195, width: double.infinity, fit: BoxFit.cover,
                    placeholder: (_, _) => _shimmerPlaceholder(195),
                    errorWidget: (_, _, _) => _shimmerPlaceholder(195),
                  ),
                )
              else
                Container(
                  height: 6,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryButton])),
                ),
              // ── Content ──
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryButton.withAlpha(18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryButton.withAlpha(60)),
                      ),
                      child: Text(blog.category, style: const TextStyle(
                        color: AppColors.primaryButton, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    const Spacer(),
                    Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(DateFormat('MMM d, yyyy').format(blog.createdAt),
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ]),
                  const SizedBox(height: 10),
                  Text(blog.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: 'Inter',
                      fontSize: 16, fontWeight: FontWeight.w700, height: 1.35,
                      color: AppColors.textDark)),
                  const SizedBox(height: 6),
                  Text(blog.displayExcerpt, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Text('Read more', style: TextStyle(
                      color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // Static shimmer placeholder — created once, not per-build
  static Widget _shimmerPlaceholder(double height) => Shimmer.fromColors(
    baseColor: Colors.grey.shade200, highlightColor: Colors.grey.shade50,
    child: Container(height: height, color: Colors.white),
  );
}
