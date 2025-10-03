import 'package:cloud_firestore/cloud_firestore.dart';

class FeedEvent {
  final String authorId;
  final String authorUsername;
  final String? authorPhotoUrl;
  final String type;
  final Timestamp timestamp;
  
  final String? bookId;
  final String? bookTitle;
  final String? bookCoverUrl;
  final int? rating;
  final String? review;
  final String? followedUserId;
  final String? followedUsername;
  final int? currentPage; // <-- NOVO
  final int? pageCount;   // <-- NOVO

  FeedEvent({
    required this.authorId,
    required this.authorUsername,
    this.authorPhotoUrl,
    required this.type,
    required this.timestamp,
    this.bookId,
    this.bookTitle,
    this.bookCoverUrl,
    this.rating,
    this.review,
    this.followedUserId,
    this.followedUsername,
    this.currentPage, 
    this.pageCount,   
  });

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorUsername': authorUsername,
      'authorPhotoUrl': authorPhotoUrl,
      'type': type,
      'timestamp': timestamp,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'bookCoverUrl': bookCoverUrl,
      'rating': rating,
      'review': review,
      'followedUserId': followedUserId,
      'followedUsername': followedUsername,
      'currentPage': currentPage, 
      'pageCount': pageCount,     
    };
  }
}