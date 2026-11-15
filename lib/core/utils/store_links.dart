import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';

/// The customer and partner experiences ship as two separate apps. In-app
/// CTAs cross-promote the companion app through its store listing.
Future<void> openPartnerAppStore(BuildContext context) =>
    _openStore(context, AppConstants.partnerAppStoreUrl);

Future<void> openCustomerAppStore(BuildContext context) =>
    _openStore(context, AppConstants.customerAppStoreUrl);

/// Explains the two-app model before opening the store listing, so tapping
/// "Sell" never dumps the user on an unfamiliar external page unexplained.
Future<void> showSellDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Sell on Tamarin'),
      content: const Text(
        'Selling happens in the Tamarin Partner app — a separate app for '
        'sellers with your storefront, products, orders and store tools.\n\n'
        'Download it from the Play Store and sign in with the same account.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Maybe later'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            openPartnerAppStore(context);
          },
          icon: const Icon(Icons.storefront_rounded),
          label: const Text('Get the Partner app'),
        ),
      ],
    ),
  );
}

Future<void> _openStore(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) _toast(context);
  } catch (_) {
    if (context.mounted) _toast(context);
  }
}

void _toast(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Open your app store and search for Tamarin')),
  );
}
