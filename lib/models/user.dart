import 'order.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String role; // CUSTOMER | SELLER | ADMIN
  final List<Address> addresses;
  final List<String> favoriteVendorIds;
  final List<String> favoriteProductIds;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.role = 'CUSTOMER',
    this.addresses = const [],
    this.favoriteVendorIds = const [],
    this.favoriteProductIds = const [],
  });

  bool get isSeller => role == 'SELLER' || role == 'ADMIN';

  Address? get defaultAddress {
    if (addresses.isEmpty) return null;
    return addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => addresses.first,
    );
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? role,
    List<Address>? addresses,
    List<String>? favoriteVendorIds,
    List<String>? favoriteProductIds,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      addresses: addresses ?? this.addresses,
      favoriteVendorIds: favoriteVendorIds ?? this.favoriteVendorIds,
      favoriteProductIds: favoriteProductIds ?? this.favoriteProductIds,
    );
  }
}
