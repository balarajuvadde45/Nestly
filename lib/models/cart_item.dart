import 'product.dart';

class CartItem {
  final String id;
  final Product product;
  final int quantity;
  final String? selectedSize;
  final String? specialInstructions;

  const CartItem({
    required this.id,
    required this.product,
    this.quantity = 1,
    this.selectedSize,
    this.specialInstructions,
  });

  double get lineTotal => product.price * quantity;

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    String? selectedSize,
    String? specialInstructions,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedSize: selectedSize ?? this.selectedSize,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }
}
