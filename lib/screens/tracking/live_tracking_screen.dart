import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../core/utils/formatters.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String orderId;
  const LiveTrackingScreen({super.key, required this.orderId});
  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  Timer? _timer;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refresh();
      _timer = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
    });
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    await context.read<OrderProvider>().refreshOrder(widget.orderId);
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>().getById(widget.orderId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order status'),
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : order == null
          ? const Center(child: Text('Order unavailable'))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      order.vendorName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      order.statusLabel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(order.address.fullAddress),
                    if (order.estimatedDelivery != null)
                      Text(
                        'Estimated delivery: ${Formatters.dateTime(order.estimatedDelivery!)}',
                      ),
                    const Divider(height: 32),
                    for (final event in order.events)
                      ListTile(
                        leading: const Icon(Icons.check_circle_outline),
                        title: Text(event.message),
                        subtitle: Text(Formatters.dateTime(event.time)),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
