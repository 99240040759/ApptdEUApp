import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/blog_post.dart';
import '../models/file_item.dart';

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

  // DELETE ORDER: Firestore doc FIRST, Storage file SECOND — matches website
  Future<void> deleteBlog(String id, String? coverImageUrl) async {
    await _db.collection('blogs').doc(id).delete();
    if (coverImageUrl != null && coverImageUrl.isNotEmpty) await _deleteStorageFile(coverImageUrl);
  }

  // ── Circulars ──
  Future<List<FileItem>> getCirculars() async {
    final snap = await _db.collection('circulars').orderBy('date', descending: true).get();
    return snap.docs.map(FileItem.fromFirestore).toList();
  }

  // Progress-enabled upload — onProgress(0.0 → 1.0) fired during Storage upload
  Future<void> createCircularWithProgress(
    String title, Uint8List fileBytes, String fileName,
    {void Function(double)? onProgress}
  ) async {
    final ref = _storage.ref('circulars/${DateTime.now().millisecondsSinceEpoch}-$fileName');
    final task = ref.putData(fileBytes);
    final sub = task.snapshotEvents.listen((snap) {
      if (snap.totalBytes > 0) onProgress?.call(snap.bytesTransferred / snap.totalBytes);
    });
    await task;
    await sub.cancel();
    final url = await ref.getDownloadURL();
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
  Future<List<FileItem>> getUnionAffairs() async {
    final snap = await _db.collection('union_affairs').orderBy('date', descending: true).get();
    return snap.docs.map(FileItem.fromFirestore).toList();
  }

  // Progress-enabled upload
  Future<void> createUnionAffairWithProgress(
    String title, Uint8List fileBytes, String fileName,
    {void Function(double)? onProgress}
  ) async {
    final ref = _storage.ref('union_affairs/${DateTime.now().millisecondsSinceEpoch}-$fileName');
    final task = ref.putData(fileBytes);
    final sub = task.snapshotEvents.listen((snap) {
      if (snap.totalBytes > 0) onProgress?.call(snap.bytesTransferred / snap.totalBytes);
    });
    await task;
    await sub.cancel();
    final url = await ref.getDownloadURL();
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
