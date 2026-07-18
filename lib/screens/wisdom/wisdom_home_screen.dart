import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../models/wisdom_post.dart';
import '../../providers/wisdom_provider.dart';
import '../../widgets/marketplace_header.dart';

/// Wisdom Circle — senior-friendly community for tips, remedies & Q&A.
/// UX: large type, high contrast, simple cards, medical disclaimer.
class WisdomHomeScreen extends StatefulWidget {
  const WisdomHomeScreen({super.key});

  @override
  State<WisdomHomeScreen> createState() => _WisdomHomeScreenState();
}

class _WisdomHomeScreenState extends State<WisdomHomeScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WisdomProvider>().loadFromApi();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wisdom = context.watch<WisdomProvider>();
    final pad = Responsive.contentPadding(context);
    final wide = Responsive.isWide(context);
    final posts = wisdom.posts;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      body: CustomScrollView(
        slivers: [
          if (wide)
            const SliverToBoxAdapter(
              child: MarketplaceHeader(activeHubId: 'hub_wisdom'),
            )
          else
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.white,
              title: const Text(
                'Wisdom Circle',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              actions: [
                IconButton(
                  tooltip: 'Share a tip',
                  onPressed: () => context.push('/wisdom/compose'),
                  icon: const Icon(Icons.edit_note_rounded),
                ),
              ],
            ),
          SliverToBoxAdapter(
            child: Responsive.constrained(
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, wide ? 16 : 8, pad, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Intro banner — large readable
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.diversity_3_rounded,
                                    color: AppColors.info, size: 28),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Learn from grandparents.\nHelp your community.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Share experiences, home care tips when someone is unwell, and answer questions with kindness. This is not a substitute for a doctor.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _statChip('${wisdom.elderPostCount}', 'Elder posts'),
                              const SizedBox(width: 10),
                              _statChip('${wisdom.openQuestions}', 'Questions'),
                              const SizedBox(width: 10),
                              _statChip('${posts.length}', 'Stories & tips'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Disclaimer
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Community wisdom only. For serious illness, fever with breathing trouble, chest pain, or child under 1 year — visit a doctor or hospital immediately.',
                              style: TextStyle(fontSize: 12.5, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Search large
                    TextField(
                      controller: _search,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Search tips, cold, joints, recipes…',
                        prefixIcon: const Icon(Icons.search, size: 26),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                      onChanged: wisdom.setQuery,
                    ),
                    const SizedBox(height: 14),
                    // Type filters
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _typeChip(context, null, 'All', wisdom),
                          _typeChip(context, WisdomPostType.tip, 'Health Tips', wisdom),
                          _typeChip(
                              context, WisdomPostType.remedy, 'Remedies', wisdom),
                          _typeChip(
                              context, WisdomPostType.question, 'Questions', wisdom),
                          _typeChip(
                              context, WisdomPostType.story, 'Life Stories', wisdom),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Topic filters
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _topicChip(context, null, 'All topics', wisdom),
                          ...WisdomTopic.values.map(
                            (t) => _topicChip(
                              context,
                              t,
                              _topicName(t),
                              wisdom,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/wisdom/compose'),
                            icon: const Icon(Icons.add_comment_outlined),
                            label: const Text('Share tip or ask'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              textStyle: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${posts.length} posts',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (posts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No posts match. Try another topic.',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      )
                    else
                      ...posts.map((p) => _PostCard(post: p)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: wide
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/wisdom/compose'),
              backgroundColor: AppColors.info,
              icon: const Icon(Icons.edit),
              label: const Text('Write'),
            ),
    );
  }

  Widget _statChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _typeChip(
    BuildContext context,
    WisdomPostType? type,
    String label,
    WisdomProvider wisdom,
  ) {
    final selected = wisdom.typeFilter == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 13)),
        selected: selected,
        onSelected: (_) => wisdom.setType(type),
        selectedColor: AppColors.info.withValues(alpha: 0.2),
        checkmarkColor: AppColors.info,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
    );
  }

  Widget _topicChip(
    BuildContext context,
    WisdomTopic? topic,
    String label,
    WisdomProvider wisdom,
  ) {
    final selected = wisdom.topicFilter == topic;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => wisdom.setTopic(topic),
        selectedColor: AppColors.primaryLight,
      ),
    );
  }

  String _topicName(WisdomTopic t) {
    switch (t) {
      case WisdomTopic.coldFlu:
        return 'Cold & Flu';
      case WisdomTopic.digestion:
        return 'Digestion';
      case WisdomTopic.joints:
        return 'Joints';
      case WisdomTopic.diabetesCare:
        return 'Diabetes';
      case WisdomTopic.kidsCare:
        return 'Kids';
      case WisdomTopic.womenHealth:
        return 'Women';
      case WisdomTopic.recoveryFood:
        return 'Recovery food';
      case WisdomTopic.lifeWisdom:
        return 'Life stories';
      case WisdomTopic.other:
        return 'Other';
    }
  }
}

class _PostCard extends StatelessWidget {
  final WisdomPost post;

  const _PostCard({required this.post});

  Color get _typeColor {
    switch (post.type) {
      case WisdomPostType.tip:
        return AppColors.success;
      case WisdomPostType.remedy:
        return AppColors.secondary;
      case WisdomPostType.question:
        return AppColors.info;
      case WisdomPostType.story:
        return const Color(0xFF6A1B9A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/wisdom/post/${post.id}'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: post.isElder
                          ? AppColors.info.withValues(alpha: 0.15)
                          : AppColors.primaryLight,
                      child: Text(
                        post.authorName.isNotEmpty
                            ? post.authorName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: post.isElder ? AppColors.info : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  post.authorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (post.isElder) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'ELDER',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.info,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            post.authorAge > 0
                                ? 'Age ${post.authorAge} · ${Formatters.relativeTime(post.createdAt)}'
                                : Formatters.relativeTime(post.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        post.typeLabel,
                        style: TextStyle(
                          color: _typeColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  post.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.favorite_border,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${post.helpfulCount} helpful',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.chat_bubble_outline,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${post.replyCount} answers',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      post.topicLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
