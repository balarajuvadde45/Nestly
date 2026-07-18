import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/order_provider.dart';
import 'providers/seller_provider.dart';
import 'providers/wisdom_provider.dart';
import 'router/app_router.dart';
import 'services/api_client.dart';
import 'services/socket_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const NestlyApp());
}

class NestlyApp extends StatefulWidget {
  const NestlyApp({super.key});

  @override
  State<NestlyApp> createState() => _NestlyAppState();
}

class _NestlyAppState extends State<NestlyApp> {
  late final ApiClient _api = ApiClient();
  late final SocketService _socket = SocketService();
  late final _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: _api),
        Provider<SocketService>.value(value: _socket),
        ChangeNotifierProvider(
          create: (_) => CatalogProvider(_api)..loadHome(),
        ),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(_api, _socket)..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => OrderProvider(_api, _socket),
        ),
        ChangeNotifierProvider(
          create: (_) => SellerProvider(_api, _socket),
        ),
        ChangeNotifierProvider(
          create: (_) => WisdomProvider(_api)..loadFromApi(),
        ),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
