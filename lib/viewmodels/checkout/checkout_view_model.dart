import 'package:flutter/foundation.dart';
import 'package:scan2serve/api/orders_api.dart';
import 'package:scan2serve/models/cart/cart_model.dart';
import 'package:scan2serve/services/cart_store.dart';
import 'package:scan2serve/session/session_table.dart';

class CheckoutSubmissionException implements Exception {
  CheckoutSubmissionException(this.message);
  final String message;

  @override
  String toString() => message;
}

class CheckoutViewModel extends ChangeNotifier {
  CheckoutViewModel() {
    CartStore.instance.addListener(_onCart);
  }

  void _onCart() => notifyListeners();

  List<CartItemModel> get items => CartStore.instance.items;

  int get subtotalRs =>
      items.fold<int>(0, (int sum, CartItemModel e) => sum + e.lineTotalRs);

  int get serviceChargeRs =>
      subtotalRs == 0 ? 0 : (subtotalRs * 0.05).round();

  int get taxRs => subtotalRs == 0 ? 0 : (subtotalRs * 0.08).round();

  int get appliedDiscountRs => 0;

  int get totalRs => subtotalRs + serviceChargeRs + taxRs;

  bool get isEmpty => items.isEmpty;

  bool _submitting = false;
  bool get isSubmitting => _submitting;

  void incrementQuantity(String id) {
    CartStore.instance.incrementQuantity(id);
  }

  void decrementQuantity(String id) {
    CartStore.instance.decrementQuantity(id);
  }

  void removeItem(String id) {
    CartStore.instance.removeLine(id);
  }

  /// Builds `POST /orders/` from the cart and session table. Throws
  /// [CheckoutSubmissionException] for invalid cart lines; [OrdersApiException] on HTTP errors.
  Future<CreateOrderResult> submitOrder(String notesRaw) async {
    if (items.isEmpty) {
      throw CheckoutSubmissionException('Your cart is empty.');
    }
    final List<Map<String, dynamic>> payload = <Map<String, dynamic>>[];
    for (final CartItemModel c in items) {
      final int? mid = c.menuItemId;
      if (mid == null) {
        throw CheckoutSubmissionException(
          '"${c.name}" cannot be ordered online. Remove it and add the item from the menu again.',
        );
      }
      if (c.quantity < 1) continue;
      payload.add(<String, dynamic>{'menu_item': mid, 'quantity': c.quantity});
    }
    if (payload.isEmpty) {
      throw CheckoutSubmissionException('No valid lines to submit.');
    }
    final int table = resolveTableIdForOrder();
    final String notes = notesRaw.trim();
    _submitting = true;
    notifyListeners();
    try {
      return await createOrder(
        table: table,
        items: payload,
        specialNotes: notes.isEmpty ? null : notes,
      );
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    CartStore.instance.removeListener(_onCart);
    super.dispose();
  }
}
