import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _LegalPage(
      title: 'Privacy policy',
      body: _privacy,
    );
  }
}

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _LegalPage(
      title: 'Terms of service',
      body: _terms,
    );
  }
}

class _LegalPage extends StatelessWidget {
  final String title;
  final String body;

  const _LegalPage({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.contentPadding(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: Responsive.constrained(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pad, 16, pad, 40),
          child: Text(
            body,
            style: const TextStyle(
              height: 1.45,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

const _privacy = '''
Nestly Privacy Policy

Last updated: 22 July 2026

This policy applies to the Nestly website and Android app operated from India.

What we collect
• Account details you enter: name, email, phone number, and password (stored as a hash).
• Delivery addresses you save.
• Orders you place (items, amounts, Cash on Delivery status).
• Basic device and log data needed to run the service (for example API errors).

What we do not do in this version
• We do not take online card or UPI payments.
• We do not sell your personal data.
• We do not use Google Sign-In until you opt in after we enable it.

How we use data
• To create your account and keep you signed in.
• To deliver orders from home businesses you shop from.
• To let you open a seller account from the same login.
• To improve reliability and prevent abuse.

Sharing
We share order details with the seller fulfilling your order. We use hosting providers (database and API) to run Nestly. We will only share data if required by Indian law.

Retention
We keep account and order records while your account is active. You can ask us to delete your account by emailing help@nestly.app.

Your rights
You may request a copy or deletion of your data at help@nestly.app.

Contact
Nestly, Hyderabad, India
help@nestly.app
''';

const _terms = '''
Nestly Terms of Service

Last updated: 22 July 2026

By using Nestly you agree to these terms.

1. What Nestly is
Nestly is a marketplace that connects buyers with home businesses (food, pickles, clothes, and community wisdom). Nestly is not the seller of the goods unless we say so.

2. Accounts
You must provide accurate details. You are responsible for your login. Do not share your password.

3. Orders and payment
This version supports Cash on Delivery only. The amount shown at checkout is what you pay the delivery partner or seller in cash. Prices, availability, and delivery times are set by sellers and may change.

4. Sellers
If you open a business on Nestly you must follow food-safety, labelling, and other applicable Indian laws. Nestly may pause or remove listings that break the law or these terms.

5. Cancellations
You may cancel an order until the seller has confirmed it, unless the seller has already started preparation. Refunds for Cash on Delivery are not collected in-app.

6. Acceptable use
Do not misuse the app, scrape data, or post harmful content in Wisdom Circle.

7. Liability
Home-cooked food and handmade goods vary. Nestly is not liable for quality issues between you and a seller, except as required by consumer law. Our liability is limited to the order value.

8. Changes
We may update these terms. Continued use after an update means you accept the new terms.

9. Contact
help@nestly.app
Hyderabad, India
''';
