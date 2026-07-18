import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/empty_state.dart';

/// Platform admin view — see "Sell from Home" applications stored in Postgres.
class AdminApplicationsScreen extends StatefulWidget {
  const AdminApplicationsScreen({super.key});

  @override
  State<AdminApplicationsScreen> createState() =>
      _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState extends State<AdminApplicationsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _apps = [];
  int _pendingCount = 0;
  String? _filter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.user?.role != 'ADMIN') {
      setState(() {
        _loading = false;
        _error = 'Admin login required (admin@nestly.app)';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiClient>();
      final query = <String, String>{};
      if (_filter != null) query['status'] = _filter!;
      final res = await api.get('/api/seller-applications', query: query);
      final list = (res['applications'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      setState(() {
        _apps = list;
        _pendingCount = (res['pendingCount'] as num?)?.toInt() ??
            list.where((a) => a['status'] == 'PENDING').length;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _setStatus(String id, String status) async {
    try {
      final api = context.read<ApiClient>();
      await api.patch('/api/seller-applications/$id/status', body: {
        'status': status,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked $status')),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'APPROVED':
        return AppColors.success;
      case 'REJECTED':
        return AppColors.error;
      case 'CONTACTED':
        return AppColors.info;
      default:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.contentPadding(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seller applications'),
            Text(
              _pendingCount > 0
                  ? '$_pendingCount pending review'
                  : 'Sell from Home inbox',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: !auth.isLoggedIn || auth.user?.role != 'ADMIN'
          ? EmptyState(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Admin access only',
              subtitle:
                  'Login as admin@nestly.app / password123 to review applications saved in PostgreSQL table SellerApplication.',
              actionLabel: 'Admin login',
              onAction: () => context.push('/login'),
            )
          : Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.fromLTRB(pad, 12, pad, 0),
                  child: Row(
                    children: [
                      _chip(null, 'All'),
                      _chip('PENDING', 'Pending'),
                      _chip('CONTACTED', 'Contacted'),
                      _chip('APPROVED', 'Approved'),
                      _chip('REJECTED', 'Rejected'),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? EmptyState(
                              icon: Icons.error_outline,
                              title: 'Could not load',
                              subtitle: _error,
                              actionLabel: 'Retry',
                              onAction: _load,
                            )
                          : _apps.isEmpty
                              ? EmptyState(
                                  icon: Icons.inbox_outlined,
                                  title: 'No applications yet',
                                  subtitle:
                                      'When someone taps Sell from Home and submits the form, it appears here and in table "SellerApplication".',
                                  actionLabel: 'Refresh',
                                  onAction: _load,
                                )
                              : RefreshIndicator(
                                  onRefresh: _load,
                                  child: ListView.separated(
                                    padding: EdgeInsets.all(pad),
                                    itemCount: _apps.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, i) {
                                      final a = _apps[i];
                                      final status =
                                          a['status'] as String? ?? 'PENDING';
                                      final created = DateTime.tryParse(
                                          a['createdAt'] as String? ?? '');
                                      return Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      a['businessName']
                                                              as String? ??
                                                          '',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: _statusColor(status)
                                                          .withValues(
                                                              alpha: 0.12),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    child: Text(
                                                      status,
                                                      style: TextStyle(
                                                        color: _statusColor(
                                                            status),
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '${a['applicantName']} · ${a['businessType']}',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Phone: ${a['phone']}',
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              ),
                                              if (a['email'] != null)
                                                Text(
                                                  'Email: ${a['email']}',
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                ),
                                              Text(
                                                [
                                                  a['city'],
                                                  if (a['area'] != null)
                                                    a['area'],
                                                ].join(' · '),
                                                style: const TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              if (a['message'] != null &&
                                                  (a['message'] as String)
                                                      .isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                Text(
                                                  a['message'] as String,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    height: 1.35,
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 8),
                                              Text(
                                                created != null
                                                    ? 'Submitted ${Formatters.dateTime(created)}'
                                                    : 'Submitted recently',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textHint,
                                                ),
                                              ),
                                              Text(
                                                'DB id: ${a['id']}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textHint,
                                                ),
                                              ),
                                              if (status == 'PENDING' ||
                                                  status == 'CONTACTED') ...[
                                                const SizedBox(height: 12),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: [
                                                    OutlinedButton(
                                                      onPressed: () =>
                                                          _setStatus(
                                                              a['id'] as String,
                                                              'CONTACTED'),
                                                      child: const Text(
                                                          'Mark contacted'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () =>
                                                          _setStatus(
                                                              a['id'] as String,
                                                              'APPROVED'),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            AppColors.success,
                                                      ),
                                                      child: const Text(
                                                          'Approve'),
                                                    ),
                                                    OutlinedButton(
                                                      onPressed: () =>
                                                          _setStatus(
                                                              a['id'] as String,
                                                              'REJECTED'),
                                                      style: OutlinedButton
                                                          .styleFrom(
                                                        foregroundColor:
                                                            AppColors.error,
                                                      ),
                                                      child: const Text(
                                                          'Reject'),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                ),
              ],
            ),
    );
  }

  Widget _chip(String? value, String label) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _filter = value);
          _load();
        },
        selectedColor: AppColors.primaryLight,
      ),
    );
  }
}
