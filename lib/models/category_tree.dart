import 'package:flutter/material.dart';

/// Top-level marketplace hubs shown in header (web) and home (mobile).
/// Research-backed for women home businesses: food, pickles/spices,
/// clothing/boutiques, plus Wisdom Circle for elders.
class HubCategory {
  final String id;
  final String name;
  final String shortLabel;
  final String description;
  final IconData icon;
  final Color color;
  final String imageUrl;
  final List<HubSubCategory> children;
  /// If set, navigates to a special experience (e.g. community).
  final String? routeOverride;

  const HubCategory({
    required this.id,
    required this.name,
    required this.shortLabel,
    required this.description,
    required this.icon,
    required this.color,
    required this.imageUrl,
    this.children = const [],
    this.routeOverride,
  });

  bool get hasChildren => children.isNotEmpty;
}

class HubSubCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String? catalogCategoryId;

  const HubSubCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.catalogCategoryId,
  });
}

/// Canonical navigation tree for Nestly.
class CategoryTree {
  CategoryTree._();

  static const hubs = <HubCategory>[
    HubCategory(
      id: 'hub_food',
      name: 'Food',
      shortLabel: 'Food',
      description:
          'Home kitchens, tiffin, cloud kitchens & homemade meals from women cooks',
      icon: Icons.restaurant_menu_rounded,
      color: Color(0xFFFFE0B2),
      imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
      children: [
        HubSubCategory(
          id: 'sub_home_food',
          name: 'Home Food',
          description: 'Daily thalis & home-style curries',
          icon: Icons.soup_kitchen_rounded,
          catalogCategoryId: 'cat_food',
        ),
        HubSubCategory(
          id: 'sub_cloud',
          name: 'Cloud Kitchen',
          description: 'Pro kitchens run from home setups',
          icon: Icons.storefront_rounded,
          catalogCategoryId: 'cat_cloud',
        ),
        HubSubCategory(
          id: 'sub_tiffin',
          name: 'Tiffin Service',
          description: 'Weekly lunch & dinner plans',
          icon: Icons.lunch_dining_rounded,
          catalogCategoryId: 'cat_tiffin',
        ),
        HubSubCategory(
          id: 'sub_healthy',
          name: 'Healthy & Diet',
          description: 'Clean bowls, salads, low-cal meals',
          icon: Icons.favorite_rounded,
          catalogCategoryId: 'cat_healthy',
        ),
        HubSubCategory(
          id: 'sub_bakery',
          name: 'Home Bakery',
          description: 'Cakes, cookies & celebration bakes',
          icon: Icons.bakery_dining_rounded,
          catalogCategoryId: 'cat_bakery',
        ),
        HubSubCategory(
          id: 'sub_sweets',
          name: 'Sweets & Snacks',
          description: 'Mithai, mixture & festival packs',
          icon: Icons.cake_rounded,
          catalogCategoryId: 'cat_sweets',
        ),
      ],
    ),
    HubCategory(
      id: 'hub_pickles',
      name: 'Pickles',
      shortLabel: 'Pickles',
      description:
          'Grandma-style pickles, podis, spices & homemade masalas',
      icon: Icons.spa_rounded,
      color: Color(0xFFC8E6C9),
      imageUrl:
          'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400',
      children: [
        HubSubCategory(
          id: 'sub_mango_pickle',
          name: 'Pickles',
          description: 'Avakaya, lemon, gongura & more',
          icon: Icons.eco_rounded,
          catalogCategoryId: 'cat_pickle',
        ),
        HubSubCategory(
          id: 'sub_podi',
          name: 'Podis & Powders',
          description: 'Idli karam, gunpowder, spice mixes',
          icon: Icons.grain_rounded,
          catalogCategoryId: 'cat_pickle',
        ),
        HubSubCategory(
          id: 'sub_organic',
          name: 'Organic Spices',
          description: 'Home-ground pure masalas',
          icon: Icons.yard_rounded,
          catalogCategoryId: 'cat_pickle',
        ),
      ],
    ),
    HubCategory(
      id: 'hub_clothes',
      name: 'Clothes',
      shortLabel: 'Clothes',
      description:
          'Home boutiques, ethnic wear, handloom & stitched fashion by women entrepreneurs',
      icon: Icons.checkroom_rounded,
      color: Color(0xFFE1BEE7),
      imageUrl:
          'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=400',
      children: [
        HubSubCategory(
          id: 'sub_boutiques',
          name: 'Boutiques',
          description: 'Home boutiques & designer ethnic',
          icon: Icons.store_mall_directory_rounded,
          catalogCategoryId: 'cat_clothes',
        ),
        HubSubCategory(
          id: 'sub_kurtis',
          name: 'Kurtis & Sets',
          description: 'Daily wear & festive kurtis',
          icon: Icons.woman_rounded,
          catalogCategoryId: 'cat_clothes',
        ),
        HubSubCategory(
          id: 'sub_saree',
          name: 'Sarees & Handloom',
          description: 'Handloom, block print & organic',
          icon: Icons.texture_rounded,
          catalogCategoryId: 'cat_clothes',
        ),
        HubSubCategory(
          id: 'sub_kids',
          name: 'Kids Ethnic',
          description: 'Festive wear for little ones',
          icon: Icons.child_care_rounded,
          catalogCategoryId: 'cat_clothes',
        ),
        HubSubCategory(
          id: 'sub_accessories',
          name: 'Accessories',
          description: 'Dupattas, bags & stoles',
          icon: Icons.shopping_bag_outlined,
          catalogCategoryId: 'cat_clothes',
        ),
        HubSubCategory(
          id: 'sub_custom',
          name: 'Custom Stitching',
          description: 'Made-to-order home tailoring',
          icon: Icons.content_cut_rounded,
          catalogCategoryId: 'cat_clothes',
        ),
      ],
    ),
    HubCategory(
      id: 'hub_wisdom',
      name: 'Wisdom Circle',
      shortLabel: 'Wisdom',
      description:
          'Grandparents share life experience, home remedies & health tips. Community answers with care.',
      icon: Icons.diversity_3_rounded,
      color: Color(0xFFBBDEFB),
      imageUrl:
          'https://images.unsplash.com/photo-1511895426328-dc8714191300?w=400',
      routeOverride: '/wisdom',
      children: [
        HubSubCategory(
          id: 'wis_health',
          name: 'Health Tips',
          description: 'Home care when under the weather',
          icon: Icons.health_and_safety_outlined,
        ),
        HubSubCategory(
          id: 'wis_remedies',
          name: 'Home Remedies',
          description: 'Traditional remedies from elders',
          icon: Icons.local_florist_outlined,
        ),
        HubSubCategory(
          id: 'wis_qa',
          name: 'Ask & Answer',
          description: 'Ask a question — community helps',
          icon: Icons.forum_outlined,
        ),
        HubSubCategory(
          id: 'wis_stories',
          name: 'Life Stories',
          description: 'Experiences from grandparents',
          icon: Icons.auto_stories_outlined,
        ),
      ],
    ),
  ];

  static HubCategory? byId(String id) {
    try {
      return hubs.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  static HubSubCategory? subById(String id) {
    for (final h in hubs) {
      for (final s in h.children) {
        if (s.id == id) return s;
      }
    }
    return null;
  }
}
