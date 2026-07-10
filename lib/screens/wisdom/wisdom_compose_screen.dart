import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/wisdom_post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wisdom_provider.dart';

class WisdomComposeScreen extends StatefulWidget {
  const WisdomComposeScreen({super.key});

  @override
  State<WisdomComposeScreen> createState() => _WisdomComposeScreenState();
}

class _WisdomComposeScreenState extends State<WisdomComposeScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _age = TextEditingController();
  WisdomPostType _type = WisdomPostType.tip;
  WisdomTopic _topic = WisdomTopic.coldFlu;
  bool _isElder = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _age.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.contentPadding(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share with community'),
      ),
      body: Responsive.constrained(
        child: ListView(
          padding: EdgeInsets.all(pad),
          children: [
            const Text(
              'Write clearly. Use simple language so grandparents and young parents both understand.',
              style: TextStyle(fontSize: 15, height: 1.4, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text('What are you sharing?',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: WisdomPostType.values.map((t) {
                final labels = {
                  WisdomPostType.tip: 'Health tip',
                  WisdomPostType.remedy: 'Home remedy',
                  WisdomPostType.question: 'Ask a question',
                  WisdomPostType.story: 'Life story',
                };
                return ChoiceChip(
                  label: Text(labels[t]!),
                  selected: _type == t,
                  onSelected: (_) => setState(() => _type = t),
                  selectedColor: AppColors.info.withValues(alpha: 0.2),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<WisdomTopic>(
              initialValue: _topic,
              decoration: const InputDecoration(
                labelText: 'Topic',
                filled: true,
                fillColor: Colors.white,
              ),
              items: WisdomTopic.values
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(_topicLabel(t)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _topic = v ?? _topic),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Warm kadha for mild cold',
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _body,
              maxLines: 8,
              style: const TextStyle(fontSize: 16, height: 1.45),
              decoration: const InputDecoration(
                labelText: 'Your message',
                hintText:
                    'Explain step by step. Mention when to see a doctor.',
                alignLabelWithHint: true,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'I am a grandparent / elder',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Your post will show an ELDER badge — builds trust',
              ),
              value: _isElder,
              onChanged: (v) => setState(() => _isElder = v),
            ),
            if (_isElder)
              TextField(
                controller: _age,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Your age (optional)',
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_title.text.trim().length < 5 ||
                    _body.text.trim().length < 20) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Please add a clear title and a fuller message'),
                    ),
                  );
                  return;
                }
                final age = int.tryParse(_age.text) ?? (_isElder ? 65 : 0);
                context.read<WisdomProvider>().addPost(
                      authorName: auth.user?.name ??
                          (_isElder ? 'Elder friend' : 'Community member'),
                      authorAge: age,
                      isElder: _isElder,
                      title: _title.text.trim(),
                      body: _body.text.trim(),
                      type: _type,
                      topic: _topic,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Shared with Wisdom Circle!')),
                );
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: AppColors.info,
                textStyle: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700),
              ),
              child: const Text('Publish'),
            ),
            const SizedBox(height: 12),
            const Text(
              'By posting you agree to be kind, avoid diagnosing serious disease, and never replace professional care.',
              style: TextStyle(fontSize: 12, color: AppColors.textHint, height: 1.35),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _topicLabel(WisdomTopic t) {
    switch (t) {
      case WisdomTopic.coldFlu:
        return 'Cold & Flu';
      case WisdomTopic.digestion:
        return 'Digestion';
      case WisdomTopic.joints:
        return 'Joints & Pain';
      case WisdomTopic.diabetesCare:
        return 'Diabetes Care';
      case WisdomTopic.kidsCare:
        return 'Kids Care';
      case WisdomTopic.womenHealth:
        return 'Women\'s Wellness';
      case WisdomTopic.recoveryFood:
        return 'Food for Recovery';
      case WisdomTopic.lifeWisdom:
        return 'Life Wisdom';
      case WisdomTopic.other:
        return 'General';
    }
  }
}
