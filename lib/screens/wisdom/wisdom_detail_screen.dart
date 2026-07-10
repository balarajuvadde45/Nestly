import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wisdom_provider.dart';
import '../../widgets/empty_state.dart';

class WisdomDetailScreen extends StatefulWidget {
  final String postId;

  const WisdomDetailScreen({super.key, required this.postId});

  @override
  State<WisdomDetailScreen> createState() => _WisdomDetailScreenState();
}

class _WisdomDetailScreenState extends State<WisdomDetailScreen> {
  final _answer = TextEditingController();
  bool _asElder = false;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wisdom = context.watch<WisdomProvider>();
    final auth = context.watch<AuthProvider>();
    final post = wisdom.getById(widget.postId);
    final pad = Responsive.contentPadding(context);

    if (post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post')),
        body: const EmptyState(
          icon: Icons.forum_outlined,
          title: 'Post not found',
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        title: Text(post.typeLabel),
        actions: [
          TextButton.icon(
            onPressed: () {
              wisdom.markHelpful(post.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Marked helpful. Thank you!')),
              );
            },
            icon: const Icon(Icons.thumb_up_outlined, size: 18),
            label: Text('${post.helpfulCount}'),
          ),
        ],
      ),
      body: Responsive.constrained(
        child: ListView(
          padding: EdgeInsets.fromLTRB(pad, 12, pad, 40),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Not medical advice. For emergencies or severe symptoms, contact a doctor.',
                style: TextStyle(fontSize: 13, height: 1.35),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.info.withValues(alpha: 0.15),
                          child: Text(
                            post.authorName[0],
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.info,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.authorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                [
                                  if (post.isElder) 'Elder',
                                  if (post.authorAge > 0) 'Age ${post.authorAge}',
                                  Formatters.relativeTime(post.createdAt),
                                ].join(' · '),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(post.topicLabel),
                      backgroundColor: AppColors.primaryLight,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      post.body,
                      style: const TextStyle(
                        fontSize: 16.5,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Answers (${post.answers.length})',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 10),
            if (post.answers.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No answers yet. Be the first to help kindly.',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              )
            else
              ...post.answers.map((a) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              a.authorName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            if (a.isFromElder) ...[
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
                            const Spacer(),
                            Text(
                              Formatters.relativeTime(a.createdAt),
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textHint),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          a.body,
                          style: const TextStyle(fontSize: 15.5, height: 1.5),
                        ),
                        if (a.helpfulCount > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${a.helpfulCount} found helpful',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 20),
            const Text(
              'Write an answer',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _answer,
              maxLines: 4,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'Share what worked for your family (kindly & clearly)…',
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'I am a grandparent / elder sharing experience',
                style: TextStyle(fontSize: 14),
              ),
              value: _asElder,
              onChanged: (v) => setState(() => _asElder = v),
            ),
            ElevatedButton(
              onPressed: () {
                final text = _answer.text.trim();
                if (text.length < 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please write a bit more (min 10 letters)')),
                  );
                  return;
                }
                wisdom.addAnswer(
                  postId: post.id,
                  authorName: auth.user?.name ?? 'Community member',
                  authorAge: _asElder ? 65 : 30,
                  isFromElder: _asElder,
                  body: text,
                );
                _answer.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Answer shared. Thank you!')),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.info,
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              child: const Text('Post answer'),
            ),
          ],
        ),
      ),
    );
  }
}
