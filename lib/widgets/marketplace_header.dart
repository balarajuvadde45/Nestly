import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/responsive.dart';
import '../models/category_tree.dart';
import '../providers/cart_provider.dart';

/// Web-style top header: logo + Food | Pickles | Clothes (mega) | Wisdom | Sell
class MarketplaceHeader extends StatelessWidget {
  final String? activeHubId;

  const MarketplaceHeader({super.key, this.activeHubId});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final wide = Responsive.isWide(context);
    final pad = Responsive.contentPadding(context);

    if (!wide) {
      return _MobileHubBar(activeHubId: activeHubId);
    }

    return Material(
      color: Colors.white,
      elevation: 0.5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Brand row
          Container(
            constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
            padding: EdgeInsets.symmetric(horizontal: pad, vertical: 10),
            child: Row(
              children: [
                InkWell(
                  onTap: () => context.go('/home'),
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.home_work_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.appName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          const Text(
                            'Women-led homes · Food · Fashion · Wisdom',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => context.push('/become-seller'),
                  icon: const Icon(Icons.storefront_outlined, size: 18),
                  label: const Text('Sell from home'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.secondary),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => context.go('/search'),
                  icon: const Icon(Icons.search_rounded),
                  tooltip: 'Search',
                ),
                IconButton(
                  onPressed: () => context.push('/cart'),
                  icon: Badge(
                    isLabelVisible: cart.itemCount > 0,
                    label: Text('${cart.itemCount}'),
                    child: const Icon(Icons.shopping_bag_outlined),
                  ),
                  tooltip: 'Cart',
                ),
              ],
            ),
          ),
          // Nav hubs
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.divider),
                bottom: BorderSide(color: AppColors.divider),
              ),
              color: Color(0xFFFAFAFA),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  child: Row(
                    children: [
                      for (final hub in CategoryTree.hubs) ...[
                        if (hub.id == 'hub_clothes' || hub.id == 'hub_food')
                          _HubMenuButton(hub: hub, active: activeHubId == hub.id)
                        else
                          _HubLink(
                            hub: hub,
                            active: activeHubId == hub.id,
                          ),
                        const SizedBox(width: 4),
                      ],
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.push('/seller'),
                        child: const Text('Seller dashboard'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HubLink extends StatelessWidget {
  final HubCategory hub;
  final bool active;

  const _HubLink({required this.hub, required this.active});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        if (hub.routeOverride != null) {
          context.go(hub.routeOverride!);
        } else {
          context.push('/hub/${hub.id}');
        }
      },
      style: TextButton.styleFrom(
        foregroundColor: active ? AppColors.primary : AppColors.textPrimary,
        textStyle: TextStyle(
          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          fontSize: 14,
        ),
      ),
      child: Row(
        children: [
          Icon(hub.icon, size: 18),
          const SizedBox(width: 6),
          Text(hub.shortLabel),
        ],
      ),
    );
  }
}

class _HubMenuButton extends StatefulWidget {
  final HubCategory hub;
  final bool active;

  const _HubMenuButton({required this.hub, required this.active});

  @override
  State<_HubMenuButton> createState() => _HubMenuButtonState();
}

class _HubMenuButtonState extends State<_HubMenuButton> {
  final _key = GlobalKey();

  void _openMenu() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height,
        offset.dx + 280,
        offset.dy,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          enabled: false,
          child: Text(
            widget.hub.name.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 11,
              color: AppColors.primary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'all',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(widget.hub.icon, color: AppColors.primary),
            title: Text('All ${widget.hub.name}'),
            subtitle: Text(widget.hub.description, maxLines: 1),
          ),
        ),
        ...widget.hub.children.map(
          (s) => PopupMenuItem(
            value: s.id,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(s.icon, size: 22),
              title: Text(s.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(s.description, maxLines: 1),
            ),
          ),
        ),
      ],
    ).then((value) {
      if (value == null || !mounted) return;
      if (value == 'all') {
        context.push('/hub/${widget.hub.id}');
      } else {
        final sub = CategoryTree.subById(value);
        if (sub?.catalogCategoryId != null) {
          context.push('/category/${sub!.catalogCategoryId}');
        } else {
          context.push('/hub/${widget.hub.id}');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      key: _key,
      onPressed: _openMenu,
      style: TextButton.styleFrom(
        foregroundColor:
            widget.active ? AppColors.primary : AppColors.textPrimary,
        textStyle: TextStyle(
          fontWeight: widget.active ? FontWeight.w800 : FontWeight.w600,
          fontSize: 14,
        ),
      ),
      child: Row(
        children: [
          Icon(widget.hub.icon, size: 18),
          const SizedBox(width: 6),
          Text(widget.hub.shortLabel),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
        ],
      ),
    );
  }
}

/// Horizontal hub chips for mobile/tablet.
class _MobileHubBar extends StatelessWidget {
  final String? activeHubId;

  const _MobileHubBar({this.activeHubId});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: CategoryTree.hubs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final hub = CategoryTree.hubs[i];
          final active = activeHubId == hub.id;
          return ChoiceChip(
            avatar: Icon(hub.icon, size: 16,
                color: active ? AppColors.primary : AppColors.textSecondary),
            label: Text(hub.shortLabel),
            selected: active,
            onSelected: (_) {
              if (hub.routeOverride != null) {
                context.go(hub.routeOverride!);
              } else {
                context.push('/hub/${hub.id}');
              }
            },
            selectedColor: AppColors.primaryLight,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: active ? AppColors.primary : AppColors.textPrimary,
            ),
          );
        },
      ),
    );
  }
}

/// Large hub grid for home page (all users incl. women sellers browsing).
class HubShowcase extends StatelessWidget {
  const HubShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = Responsive.isWide(context);
    final pad = Responsive.contentPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shop by world',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 4),
          const Text(
            'Food · Pickles · Clothes (Boutiques) · Wisdom from elders',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, c) {
              final cols = wide ? 4 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: CategoryTree.hubs.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: wide ? 1.35 : 1.15,
                ),
                itemBuilder: (context, i) {
                  final hub = CategoryTree.hubs[i];
                  return _HubCard(hub: hub);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final HubCategory hub;

  const _HubCard({required this.hub});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (hub.routeOverride != null) {
            context.go(hub.routeOverride!);
          } else {
            context.push('/hub/${hub.id}');
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: hub.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(hub.icon, size: 24),
              ),
              const Spacer(),
              Text(
                hub.name,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                hub.children.isEmpty
                    ? hub.description
                    : hub.children.map((c) => c.name).take(3).join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
              if (hub.id == 'hub_clothes') ...[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Boutiques inside →',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
