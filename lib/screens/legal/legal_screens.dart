import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_config.dart';

Future<void> openPublicPage(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  bool opened = false;
  try {
    if (uri != null && uri.scheme == 'https') {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } catch (_) {}
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to open this page. Please try later.'),
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      _LegalPage(title: 'Privacy policy', url: AppConfig.privacyUrl);
}

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      _LegalPage(title: 'Terms of service', url: AppConfig.termsUrl);
}

class _LegalPage extends StatelessWidget {
  final String title;
  final String url;
  const _LegalPage({required this.title, required this.url});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: TextButton.icon(
        icon: const Icon(Icons.open_in_new),
        label: Text(title),
        onPressed: () => openPublicPage(context, url),
      ),
    ),
  );
}
