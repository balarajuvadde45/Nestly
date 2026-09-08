import 'package:flutter_test/flutter_test.dart';
import 'package:nestly/models/product.dart';
import 'package:nestly/models/cart_item.dart';
import 'package:nestly/services/api_mappers.dart';

Product item({
  int min = 1,
  int? pack,
  int? stock,
  List<WholesaleTier> tiers = const [],
}) => Product(
  id: 'item',
  vendorId: 'seller',
  name: 'Item',
  description: '',
  price: 118,
  imageUrl: '',
  type: ProductType.fmcg,
  minOrderQuantity: min,
  casePackQuantity: pack,
  stockQuantity: stock,
  wholesaleTiers: tiers,
);
void main() {
  test('MOQ rounds to a complete case and never offers an incomplete case', () {
    final product = item(min: 5, pack: 6, stock: 13);
    expect(product.minCartQuantity, 6);
    expect(product.normalizeQuantity(7), 12);
    expect(product.normalizeQuantity(18), 12);
    expect(item(min: 5, pack: 6, stock: 5).canOrder, false);
  });
  test('selects the correct slab even when API tiers arrive unsorted', () {
    final product = item(
      tiers: [
        const WholesaleTier(minQuantity: 12, unitPrice: 90),
        const WholesaleTier(minQuantity: 6, unitPrice: 100),
      ],
    );
    expect(product.unitPriceForQuantity(12), 90);
    expect(
      CartItem(id: 'cart', product: product, quantity: 12).lineTotal,
      1080,
    );
  });
  test('retains approval and persistent favourites from API data', () {
    final user = userFromJson({
      'id': 'user',
      'favoriteVendorIds': ['seller'],
    });
    expect(user.favoriteVendorIds, ['seller']);
    final vendor = vendorFromJson({'id': 'seller', 'isApproved': true});
    expect(vendor.isApproved, true);
  });
}
