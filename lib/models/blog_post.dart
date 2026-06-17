import 'package:cloud_firestore/cloud_firestore.dart';

class BlogPost {
  final String id, title, slug, category, content, coverImage;
  final String? excerpt, metaTitle, metaDescription, keywords, contentDelta;
  final DateTime createdAt, updatedAt;

  const BlogPost({
    required this.id, required this.title, required this.slug,
    required this.category, required this.content, required this.coverImage,
    this.excerpt, this.metaTitle, this.metaDescription, this.keywords,
    this.contentDelta, required this.createdAt, required this.updatedAt,
  });

  // Cached RegExp — compiled once, not per call
  static final _tagRe = RegExp(r'<[^>]+>');
  static final _spaceRe = RegExp(r'\s{2,}');

  static String generateSlug(String title) {
    final slug = title.toLowerCase().trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'post-${DateTime.now().millisecondsSinceEpoch}' : slug;
  }

  static String _stripHtml(String html) =>
      html.replaceAll(_tagRe, ' ').replaceAll(_spaceRe, ' ').trim();

  String get displayExcerpt {
    final src = excerpt ?? content;
    final plain = src.contains('<') ? _stripHtml(src) : src;
    return plain.length > 150 ? '${plain.substring(0, 150)}...' : plain;
  }

  factory BlogPost.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BlogPost(
      id: doc.id, title: d['title'] ?? '',
      slug: d['slug'] ?? generateSlug(d['title'] ?? ''),
      category: d['category'] ?? 'General',
      content: d['content'] ?? '', coverImage: d['cover_image'] ?? '',
      excerpt: d['excerpt'], metaTitle: d['meta_title'],
      metaDescription: d['meta_description'], keywords: d['keywords'],
      contentDelta: d['content_delta'],
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title, 'slug': slug, 'category': category,
    'content': content, 'cover_image': coverImage,
    'excerpt': excerpt, 'meta_title': metaTitle,
    'meta_description': metaDescription, 'keywords': keywords,
    if (contentDelta != null) 'content_delta': contentDelta,
    'created_at': Timestamp.fromDate(createdAt),
    'updated_at': Timestamp.fromDate(updatedAt),
  };

  BlogPost copyWith({
    String? id, String? title, String? slug, String? category,
    String? content, String? coverImage, String? excerpt,
    String? metaTitle, String? metaDescription, String? keywords,
    String? contentDelta, DateTime? createdAt, DateTime? updatedAt,
  }) => BlogPost(
    id: id ?? this.id, title: title ?? this.title,
    slug: slug ?? this.slug, category: category ?? this.category,
    content: content ?? this.content, coverImage: coverImage ?? this.coverImage,
    excerpt: excerpt ?? this.excerpt, metaTitle: metaTitle ?? this.metaTitle,
    metaDescription: metaDescription ?? this.metaDescription,
    keywords: keywords ?? this.keywords,
    contentDelta: contentDelta ?? this.contentDelta,
    createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
  );
}
