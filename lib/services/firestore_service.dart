import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/blog_post.dart';
import '../models/circular.dart';
import '../models/union_affair.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._();
  factory FirestoreService() => _instance;
  FirestoreService._();

  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  static String _detectFileType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (ext == 'pdf') return 'pdf';
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) return 'image';
    if (['mp3', 'wav', 'aac', 'm4a'].contains(ext)) return 'audio';
    return 'pdf';
  }

  // Storage path uses HYPHEN separator: {path}/{timestamp}-{filename}
  // Matches website: `${path}/${Date.now()}-${file.name}`
  Future<String> _uploadFile(String path, Uint8List bytes, String fileName) async {
    final ref = _storage.ref('$path/${DateTime.now().millisecondsSinceEpoch}-$fileName');
    await ref.putData(bytes);
    return ref.getDownloadURL();
  }

  // Silently ignore if file is already gone
  Future<void> _deleteStorageFile(String url) async {
    try { await _storage.refFromURL(url).delete(); } catch (_) {}
  }

  // ── Blogs ──
  Future<List<BlogPost>> getBlogs() async {
    final snap = await _db.collection('blogs').orderBy('created_at', descending: true).get();
    return snap.docs.map(BlogPost.fromFirestore).toList();
  }

  Future<BlogPost?> getBlogBySlug(String slug) async {
    final snap = await _db.collection('blogs').where('slug', isEqualTo: slug).limit(1).get();
    return snap.docs.isEmpty ? null : BlogPost.fromFirestore(snap.docs.first);
  }

  Future<List<BlogPost>> getBlogsByCategory(String category) async {
    final snap = await _db.collection('blogs')
        .where('category', isEqualTo: category)
        .orderBy('created_at', descending: true).get();
    return snap.docs.map(BlogPost.fromFirestore).toList();
  }

  Future<void> createBlog(BlogPost blog, {Uint8List? coverImageBytes, String? coverImageName}) async {
    final now = DateTime.now();
    var data = blog.copyWith(createdAt: now, updatedAt: now).toFirestore();
    if (coverImageBytes != null && coverImageName != null) {
      data['cover_image'] = await _uploadFile('covers', coverImageBytes, coverImageName);
    }
    await _db.collection('blogs').add(data);
  }

  Future<void> updateBlog(BlogPost blog, {Uint8List? coverImageBytes, String? coverImageName}) async {
    var data = blog.copyWith(updatedAt: DateTime.now()).toFirestore();
    if (coverImageBytes != null && coverImageName != null) {
      // Website does NOT delete old cover on update — only on blog delete
      data['cover_image'] = await _uploadFile('covers', coverImageBytes, coverImageName);
    }
    await _db.collection('blogs').doc(blog.id).update(data);
  }

  // DELETE ORDER: Firestore doc FIRST, Storage file SECOND — matches website
  Future<void> deleteBlog(String id, String? coverImageUrl) async {
    await _db.collection('blogs').doc(id).delete();
    if (coverImageUrl != null && coverImageUrl.isNotEmpty) await _deleteStorageFile(coverImageUrl);
  }

  // ── Circulars ──
  Future<List<Circular>> getCirculars() async {
    final snap = await _db.collection('circulars').orderBy('date', descending: true).get();
    return snap.docs.map(Circular.fromFirestore).toList();
  }

  Future<void> createCircular(String title, Uint8List fileBytes, String fileName) async {
    final url = await _uploadFile('circulars', fileBytes, fileName);
    await _db.collection('circulars').add({
      'title': title, 'date': DateTime.now().toIso8601String().substring(0, 10),
      'fileUrl': url, 'fileType': _detectFileType(fileName),
      'created_at': Timestamp.now(),
    });
  }

  // DELETE ORDER: Firestore doc FIRST, Storage file SECOND — matches website
  Future<void> deleteCircular(String id, String fileUrl) async {
    await _db.collection('circulars').doc(id).delete();
    await _deleteStorageFile(fileUrl);
  }

  // ── Union Affairs ──
  Future<List<UnionAffair>> getUnionAffairs() async {
    final snap = await _db.collection('union_affairs').orderBy('date', descending: true).get();
    return snap.docs.map(UnionAffair.fromFirestore).toList();
  }

  Future<void> createUnionAffair(String title, Uint8List fileBytes, String fileName) async {
    final url = await _uploadFile('union_affairs', fileBytes, fileName);
    await _db.collection('union_affairs').add({
      'title': title, 'date': DateTime.now().toIso8601String().substring(0, 10),
      'fileUrl': url, 'fileType': _detectFileType(fileName),
      'created_at': Timestamp.now(),
    });
  }

  // DELETE ORDER: Firestore doc FIRST, Storage file SECOND — matches website
  Future<void> deleteUnionAffair(String id, String fileUrl) async {
    await _db.collection('union_affairs').doc(id).delete();
    await _deleteStorageFile(fileUrl);
  }
}
