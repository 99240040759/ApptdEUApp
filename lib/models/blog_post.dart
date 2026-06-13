import 'package:cloud_firestore/cloud_firestore.dart';

class BlogPost {
  final String id, title, slug, category, content, coverImage;
  final String? excerpt, metaTitle, metaDescription, keywords;
  final DateTime createdAt, updatedAt;

  const BlogPost({
    required this.id, required this.title, required this.slug,
    required this.category, required this.content, required this.coverImage,
    this.excerpt, this.metaTitle, this.metaDescription, this.keywords,
    required this.createdAt, required this.updatedAt,
  });

  // Exact match to website: replace all non-alphanumeric sequences with hyphens,
  // strip leading/trailing hyphens. Fallback to 'post-{timestamp}' if empty.
  static String generateSlug(String title) {
    final slug = title.toLowerCase().trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'post-${DateTime.now().millisecondsSinceEpoch}' : slug;
  }

  String get displayExcerpt =>
      excerpt ?? (content.length > 150 ? '${content.substring(0, 150)}...' : content);

  factory BlogPost.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BlogPost(
      id: doc.id,
      title: d['title'] ?? '',
      slug: d['slug'] ?? generateSlug(d['title'] ?? ''),
      category: d['category'] ?? 'General',
      content: d['content'] ?? '',
      // CRITICAL: website uses 'cover_image' (snake_case)
      coverImage: d['cover_image'] ?? '',
      excerpt: d['excerpt'],
      metaTitle: d['meta_title'],
      metaDescription: d['meta_description'],
      keywords: d['keywords'],
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title, 'slug': slug, 'category': category,
    'content': content,
    // CRITICAL: website uses 'cover_image' (snake_case)
    'cover_image': coverImage,
    'excerpt': excerpt, 'meta_title': metaTitle,
    'meta_description': metaDescription, 'keywords': keywords,
    'created_at': Timestamp.fromDate(createdAt),
    'updated_at': Timestamp.fromDate(updatedAt),
  };

  BlogPost copyWith({
    String? id, String? title, String? slug, String? category,
    String? content, String? coverImage, String? excerpt,
    String? metaTitle, String? metaDescription, String? keywords,
    DateTime? createdAt, DateTime? updatedAt,
  }) => BlogPost(
    id: id ?? this.id, title: title ?? this.title,
    slug: slug ?? this.slug, category: category ?? this.category,
    content: content ?? this.content, coverImage: coverImage ?? this.coverImage,
    excerpt: excerpt ?? this.excerpt, metaTitle: metaTitle ?? this.metaTitle,
    metaDescription: metaDescription ?? this.metaDescription,
    keywords: keywords ?? this.keywords,
    createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
  );
}
