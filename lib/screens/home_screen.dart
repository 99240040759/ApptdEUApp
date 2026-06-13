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

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final blogs = await FirestoreService().getBlogs();
      if (mounted) setState(() { _blogs = blogs; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: CustomScrollView(slivers: [
        // Collapsing banner
        SliverAppBar(
          expandedHeight: 160, floating: false, pinned: false,
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: Image.asset('assets/images/banner.png', fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(color: AppColors.primary)),
          ),
        ),
        // Section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Latest Posts', style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
        // Content
        if (_loading)
          SliverList(delegate: SliverChildBuilderDelegate(
            (_, i) => _shimmerCard(), childCount: 4,
          ))
        else if (_blogs == null || _blogs!.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.article_outlined, size: 64, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text('No posts yet', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
            ])),
          )
        else
          SliverList(delegate: SliverChildBuilderDelegate(
            (_, i) => _blogCard(_blogs![i]), childCount: _blogs!.length,
          )),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ]),
    );
  }

  Widget _blogCard(BlogPost blog) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => BlogDetailScreen(slug: blog.slug, blog: blog),
          )),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Cover image with hero
            if (blog.coverImage.isNotEmpty)
              Hero(
                tag: 'blog_${blog.slug}',
                child: CachedNetworkImage(
                  imageUrl: blog.coverImage, height: 180, width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(height: 180, color: Colors.grey.shade200),
                  errorWidget: (_, _, _) => Container(height: 180, color: Colors.grey.shade200,
                    child: const Icon(Icons.image_outlined, size: 40, color: Colors.grey)),
                ),
              ),
            Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 12), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Category chip + date row
                Row(children: [
                  Chip(
                    label: Text(blog.category, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    backgroundColor: AppColors.primaryButton,
                    padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide.none,
                  ),
                  const Spacer(),
                  Text(DateFormat('MMM d, yyyy').format(blog.createdAt),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ]),
                const SizedBox(height: 8),
                // Title
                Text(blog.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3)),
                const SizedBox(height: 6),
                // Excerpt
                Text(blog.displayExcerpt, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4)),
              ],
            )),
          ]),
        ),
      ),
    );
  }

  Widget _shimmerCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Card(clipBehavior: Clip.antiAlias, child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 180, color: Colors.white),
          Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 14, width: 80, color: Colors.white),
            const SizedBox(height: 10),
            Container(height: 16, width: double.infinity, color: Colors.white),
            const SizedBox(height: 8),
            Container(height: 12, width: 200, color: Colors.white),
          ])),
        ]),
      )),
    );
  }
}
