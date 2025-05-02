import 'package:flutter/material.dart';
import 'dart:math';
import '../../../domain_layer/coordinates/point.dart';

/// A reusable class to handle comment dropdowns with proper overlay management.
class CommentDropdown {
  OverlayEntry? overlayEntry;
  final LayerLink layerLink;

  CommentDropdown({required this.layerLink});

  /// Hide any active dropdown
  void hideDropdown() {
    overlayEntry?.remove();
    overlayEntry = null;
  }

  /// Show matching comments in a dropdown
  void showDropdown({
    required BuildContext context,
    required String query,
    required List<Point> points,
    required Function(Point) onSelected,
    Point? excludePoint,
    bool isSelectable = true,
  }) {
    // Hide any existing dropdown first
    hideDropdown();

    // Don't show for empty queries
    if (query.isEmpty) return;

    // Filter points based on query
    final filteredPoints = points.where((point) {
      if (excludePoint != null && point.id == excludePoint.id) return false;
      return point.comment.toLowerCase().contains(query.toLowerCase());
    }).toList();

    // Don't show if no matches
    if (filteredPoints.isEmpty) return;

    // Capture overlay before any potential async gap
    final overlay = Overlay.of(context);

    // Create and position the overlay
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 160,
        child: CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 40),
          child: Material(
            elevation: 4.0,
            child: Container(
              height: min(filteredPoints.length * 50.0, 200),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: filteredPoints.length,
                itemBuilder: (context, index) {
                  final point = filteredPoints[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      point.comment,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelectable ? Colors.black : Colors.grey[600],
                      ),
                    ),
                    onTap: isSelectable
                        ? () {
                            onSelected(point);
                            hideDropdown();
                          }
                        : null,
                    enabled: isSelectable,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    // Show the overlay
    overlay.insert(overlayEntry!);
  }

  /// Ensure disposal to prevent memory leaks
  void dispose() {
    hideDropdown();
  }
}
