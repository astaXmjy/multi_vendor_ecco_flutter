import 'package:flutter/foundation.dart';
import '../api/services/review_service.dart';
import '../core/models/review_model.dart';

class ReviewProvider extends ChangeNotifier {
  final ReviewService _reviewService = ReviewService();
  List<ReviewModel> _reviews = [];
  bool _isLoading = false;
  String? _error;

  List<ReviewModel> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> getProductReviews(String productSlug) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _reviewService.getProductReviews(productSlug);

      if (result['success']) {
        _reviews = result['data'];
        _error = null;
      } else {
        _error = result['message'];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createReview({
    required String productSlug,
    required int rating,
    required String title,
    required String comment,
  }) async {
    try {
      final result = await _reviewService.createReview(
        productSlug: productSlug,
        rating: rating,
        title: title,
        comment: comment,
      );

      if (result['success']) {
        final newReview = result['data'];
        _reviews.add(newReview);
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateReview({
    required int reviewId,
    required int rating,
    required String title,
    required String comment,
  }) async {
    try {
      final result = await _reviewService.updateReview(
        reviewId: reviewId,
        rating: rating,
        title: title,
        comment: comment,
      );

      if (result['success']) {
        final updatedReview = result['data'];
        final index = _reviews.indexWhere((r) => r.id == reviewId);
        if (index != -1) {
          _reviews[index] = updatedReview;
          notifyListeners();
        }
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteReview(int reviewId) async {
    try {
      final result = await _reviewService.deleteReview(reviewId);

      if (result['success']) {
        _reviews.removeWhere((r) => r.id == reviewId);
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}