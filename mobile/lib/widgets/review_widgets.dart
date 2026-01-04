import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

/// Widget to display rating stars
class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;
  final bool showValue;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.color,
    this.showValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          if (index < rating.floor()) {
            return Icon(Icons.star, size: size, color: color ?? Colors.amber);
          } else if (index < rating) {
            return Icon(Icons.star_half,
                size: size, color: color ?? Colors.amber);
          } else {
            return Icon(Icons.star_border,
                size: size, color: color ?? Colors.amber);
          }
        }),
        if (showValue) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: size * 0.9,
            ),
          ),
        ],
      ],
    );
  }
}

/// Interactive star rating selector
class StarRatingInput extends StatefulWidget {
  final int initialRating;
  final Function(int) onRatingChanged;
  final double size;
  final String? label;

  const StarRatingInput({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.size = 32,
    this.label,
  });

  @override
  State<StarRatingInput> createState() => _StarRatingInputState();
}

class _StarRatingInputState extends State<StarRatingInput> {
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label!,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () {
                setState(() => _rating = index + 1);
                widget.onRatingChanged(index + 1);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  size: widget.size,
                  color: Colors.amber,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Review submission bottom sheet for hospitals
class SubmitReviewSheet extends StatefulWidget {
  final int hospitalId;
  final String hospitalName;
  final bool isDoctor;
  final int? doctorId;

  const SubmitReviewSheet({
    super.key,
    required this.hospitalId,
    required this.hospitalName,
    this.isDoctor = false,
    this.doctorId,
  });

  @override
  State<SubmitReviewSheet> createState() => _SubmitReviewSheetState();
}

class _SubmitReviewSheetState extends State<SubmitReviewSheet> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _titleController = TextEditingController();

  int _overallRating = 0;
  int _cleanlinessRating = 0;
  int _staffRating = 0;
  int _facilitiesRating = 0;
  int _waitTimeRating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide an overall rating')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final reviewData = {
        'rating': _overallRating,
        'title': _titleController.text.isEmpty ? null : _titleController.text,
        'content': _contentController.text,
        'cleanliness_rating':
            _cleanlinessRating > 0 ? _cleanlinessRating : null,
        'staff_rating': _staffRating > 0 ? _staffRating : null,
        'facilities_rating': _facilitiesRating > 0 ? _facilitiesRating : null,
        'wait_time_rating': _waitTimeRating > 0 ? _waitTimeRating : null,
      };

      if (widget.isDoctor && widget.doctorId != null) {
        await apiService.submitDoctorReview(widget.doctorId!, reviewData);
      } else {
        await apiService.submitHospitalReview(widget.hospitalId, reviewData);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    widget.isDoctor
                        ? 'Rate Doctor'
                        : 'Rate ${widget.hospitalName}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Overall Rating
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'Overall Rating',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        StarRatingInput(
                          size: 40,
                          onRatingChanged: (rating) =>
                              setState(() => _overallRating = rating),
                        ),
                        if (_overallRating > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _getRatingLabel(_overallRating),
                              style: TextStyle(
                                color: _getRatingColor(_overallRating),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Category Ratings
                  const Text(
                    'Rate by Category (Optional)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryRating(
                      'Cleanliness', (r) => _cleanlinessRating = r),
                  _buildCategoryRating('Staff', (r) => _staffRating = r),
                  _buildCategoryRating(
                      'Facilities', (r) => _facilitiesRating = r),
                  _buildCategoryRating('Wait Time', (r) => _waitTimeRating = r),
                  const SizedBox(height: 16),

                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Review Title (Optional)',
                      hintText: 'Summarize your experience',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Content
                  TextFormField(
                    controller: _contentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Your Review',
                      hintText: 'Share your experience with others...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please write your review';
                      }
                      if (value.trim().length < 10) {
                        return 'Review must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Submit Review',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryRating(String label, Function(int) onRating) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            flex: 3,
            child: StarRatingInput(
              size: 24,
              onRatingChanged: onRating,
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

/// Helper function to show review sheet
Future<bool?> showReviewSheet(
  BuildContext context, {
  required int hospitalId,
  required String hospitalName,
  bool isDoctor = false,
  int? doctorId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SubmitReviewSheet(
      hospitalId: hospitalId,
      hospitalName: hospitalName,
      isDoctor: isDoctor,
      doctorId: doctorId,
    ),
  );
}

/// Review card widget
class ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final VoidCallback? onHelpful;

  const ReviewCard({
    super.key,
    required this.review,
    this.onHelpful,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: review['user_image'] != null
                    ? NetworkImage(review['user_image'])
                    : null,
                child: review['user_image'] == null
                    ? Text(
                        (review['user_name'] ?? 'A')[0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review['user_name'] ?? 'Anonymous',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (review['is_verified'] == true) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified,
                              size: 14, color: Colors.blue),
                        ],
                      ],
                    ),
                    Text(
                      _formatDate(review['created_at']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              RatingStars(rating: (review['rating'] ?? 0).toDouble(), size: 14),
            ],
          ),

          // Title
          if (review['title'] != null) ...[
            const SizedBox(height: 12),
            Text(
              review['title'],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],

          // Content
          const SizedBox(height: 8),
          Text(
            review['content'] ?? '',
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),

          // Helpful
          if (onHelpful != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onHelpful,
                  icon: const Icon(Icons.thumb_up_outlined, size: 16),
                  label: Text('Helpful (${review['helpful_count'] ?? 0})'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}
