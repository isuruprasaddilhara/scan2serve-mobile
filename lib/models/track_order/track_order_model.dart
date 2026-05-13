class TrackStepModel {
  const TrackStepModel({required this.label});

  final String label;
}

class TrackOrderModel {
  const TrackOrderModel({
    required this.title,
    required this.dishName,
    required this.etaLabel,
    required this.steps,
    required this.activeStepIndex,
    required this.orderNumber,
    required this.customerName,
    this.imageUrl,
    this.apiOrderId,
    this.apiStatus,
    this.summaryDetailLines = const <String>[],
  });

  final String title;
  final String dishName;
  final String etaLabel;
  final String? imageUrl;
  /// Extra lines under the headline (from API: total, items, notes, placed time).
  final List<String> summaryDetailLines;
  final List<TrackStepModel> steps;
  /// Index of the step shown as active when [apiStatus] is null (mock UI).
  final int activeStepIndex;
  /// Shown in notifications copy, e.g. `#4521`.
  final String orderNumber;
  /// First name for greeting, e.g. `John`.
  final String customerName;
  /// When set, cancel uses `DELETE /orders/{id}/` on the backend.
  final int? apiOrderId;
  /// Django order status: `pending`, `preparing`, `served`, etc.
  final String? apiStatus;
}
