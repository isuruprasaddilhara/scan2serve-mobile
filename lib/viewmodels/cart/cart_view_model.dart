import 'package:flutter/material.dart';
import 'package:scan2serve/models/cart/cart_model.dart';
import 'package:scan2serve/services/cart_store.dart';

class CartViewModel extends ChangeNotifier {
  CartViewModel() {
    CartStore.instance.addListener(_onStore);
  }

  void _onStore() => notifyListeners();

  final CartScreenModel viewData = const CartScreenModel(
    title: 'My Cart',
    totalLabel: 'Total',
    checkoutLabel: 'Checkout',
  );

  List<CartItemModel> get items => CartStore.instance.items;

  int get totalRs => CartStore.instance.totalRs;

  String get formattedTotal => 'Rs $totalRs';

  bool get isEmpty => items.isEmpty;

  void incrementQuantity(String id) {
    CartStore.instance.incrementQuantity(id);
  }

  void decrementQuantity(String id) {
    CartStore.instance.decrementQuantity(id);
  }

  void onCheckoutTap() {
    debugPrint('Checkout tapped — total Rs $totalRs');
  }

  @override
  void dispose() {
    CartStore.instance.removeListener(_onStore);
    super.dispose();
  }
}
