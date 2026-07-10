import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../services/socket_service.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String orderId;

  const LiveTrackingScreen({super.key, required this.orderId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  GoogleMapController? _mapController;
  Timer? _pollTimer;
  late final SocketService _socket;

  @override
  void initState() {
    super.initState();
    _socket = context.read<SocketService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orders = context.read<OrderProvider>();
      orders.refreshOrder(widget.orderId);
      _socket.connect();
      _socket.subscribeOrder(widget.orderId);
      _socket.onOrderUpdated((data) {
        if (data['id'] == widget.orderId) {
          // OrderProvider also listens; force refresh
          orders.refreshOrder(widget.orderId);
        }
      });
      _socket.onTrackingLocation((data) {
        if (data['orderId'] != widget.orderId) return;
        final lat = (data['lat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();
        if (lat != null && lng != null && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(LatLng(lat, lng)),
          );
        }
        orders.refreshOrder(widget.orderId);
      });
      // Poll every 12s as backup when sockets fail
      _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
        orders.refreshOrder(widget.orderId);
      });
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _socket.unsubscribeOrder(widget.orderId);
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>().getById(widget.orderId);

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live tracking')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final vendorLat = order.vendorLat ?? 17.4486;
    final vendorLng = order.vendorLng ?? 78.3908;
    final dropLat = order.address.lat ?? 17.44;
    final dropLng = order.address.lng ?? 78.39;
    final riderLat = order.riderLat ?? vendorLat;
    final riderLng = order.riderLng ?? vendorLng;

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('vendor'),
        position: LatLng(vendorLat, vendorLng),
        infoWindow: InfoWindow(title: order.vendorName, snippet: 'Pickup'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
      Marker(
        markerId: const MarkerId('drop'),
        position: LatLng(dropLat, dropLng),
        infoWindow: InfoWindow(
          title: order.address.label,
          snippet: order.address.short,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
      if (order.status == OrderStatus.outForDelivery ||
          order.riderLat != null)
        Marker(
          markerId: const MarkerId('rider'),
          position: LatLng(riderLat, riderLng),
          infoWindow: InfoWindow(
            title: order.deliveryPartner ?? 'Delivery partner',
            snippet: 'On the way',
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
    };

    final polylines = <Polyline>{
      Polyline(
        polylineId: const PolylineId('route'),
        color: AppColors.primary,
        width: 4,
        points: [
          LatLng(vendorLat, vendorLng),
          if (order.riderLat != null) LatLng(riderLat, riderLng),
          LatLng(dropLat, dropLng),
        ],
      ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                context.read<OrderProvider>().refreshOrder(widget.orderId),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: AppConfig.hasMapsKey
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(riderLat, riderLng),
                      zoom: 14,
                    ),
                    markers: markers,
                    polylines: polylines,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    onMapCreated: (c) {
                      _mapController = c;
                      _fitBounds(c, vendorLat, vendorLng, dropLat, dropLng);
                    },
                  )
                : _MapFallback(
                    order: order,
                    riderLat: riderLat,
                    riderLng: riderLng,
                    vendorLat: vendorLat,
                    vendorLng: vendorLng,
                    dropLat: dropLat,
                    dropLng: dropLng,
                  ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          order.statusLabel,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        Formatters.orderId(order.id),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    order.vendorName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  if (order.deliveryPartner != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.delivery_dining_rounded,
                            size: 18, color: AppColors.info),
                        const SizedBox(width: 6),
                        Text(
                          '${order.deliveryPartner} is delivering your order',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                  if (order.estimatedDelivery != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'ETA ${Formatters.dateTime(order.estimatedDelivery!)}',
                      style: const TextStyle(
                        color: AppColors.info,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Drop: ${order.address.fullAddress}, ${order.address.area}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  if (!AppConfig.hasMapsKey) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Add GOOGLE_MAPS_API_KEY to enable interactive maps. '
                      'Live coordinates still update via the backend.',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textHint, height: 1.3),
                    ),
                  ],
                  const Spacer(),
                  _statusDots(order.status),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _fitBounds(
    GoogleMapController c,
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final sw = LatLng(
      lat1 < lat2 ? lat1 : lat2,
      lng1 < lng2 ? lng1 : lng2,
    );
    final ne = LatLng(
      lat1 > lat2 ? lat1 : lat2,
      lng1 > lng2 ? lng1 : lng2,
    );
    c.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: sw, northeast: ne),
        60,
      ),
    );
  }

  Widget _statusDots(OrderStatus status) {
    final steps = [
      OrderStatus.placed,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
    ];
    final idx = steps.indexOf(status);
    return Row(
      children: List.generate(steps.length, (i) {
        final done = idx >= i;
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: done ? AppColors.success : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _MapFallback extends StatelessWidget {
  final Order order;
  final double riderLat;
  final double riderLng;
  final double vendorLat;
  final double vendorLng;
  final double dropLat;
  final double dropLng;

  const _MapFallback({
    required this.order,
    required this.riderLat,
    required this.riderLng,
    required this.vendorLat,
    required this.vendorLng,
    required this.dropLat,
    required this.dropLng,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFE8F5E9),
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _RoutePainter(),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.map_outlined,
                    size: 48, color: AppColors.primary),
                const SizedBox(height: 12),
                Text(
                  order.status == OrderStatus.outForDelivery
                      ? 'Rider en route'
                      : order.statusLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pickup: ${vendorLat.toStringAsFixed(4)}, ${vendorLng.toStringAsFixed(4)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  'Rider: ${riderLat.toStringAsFixed(4)}, ${riderLng.toStringAsFixed(4)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.info),
                ),
                Text(
                  'Drop: ${dropLat.toStringAsFixed(4)}, ${dropLng.toStringAsFixed(4)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.25)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.2,
        size.width * 0.8,
        size.height * 0.55,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
