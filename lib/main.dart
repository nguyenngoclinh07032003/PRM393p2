import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'app_routes.dart';
import 'backend/config/app_constants.dart';
import 'backend/services/auth_service.dart';
import 'backend/services/cart_service.dart';
import 'backend/services/group_buy_service.dart';
import 'frontend/auth/login_screen.dart';
import 'frontend/auth/signup_screen.dart';
import 'frontend/user/home/home_screen.dart';
import 'frontend/user/cart/cart_screen.dart';
import 'frontend/user/checkout/checkout_screen.dart';
import 'frontend/user/orders/order_history_screen.dart';
import 'frontend/user/flash_sale/flash_sale_screen.dart';
import 'frontend/user/group_buy/group_buy_invite_screen.dart';
import 'frontend/user/group_buy/group_buy_screen.dart';
import 'frontend/user/rebuy/rebuy_screen.dart';
import 'frontend/user/quality_commitment/quality_commitment_screen.dart';
import 'frontend/admin/admin_root.dart';
import 'frontend/seller/seller_dashboard.dart';
import 'utils/seed_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  try {
    await SeedData.repairProductImages();
  } catch (_) {}
  runApp(const MyApp());
}

const _primaryColor = Color(0xFF24C7E8);
const _pageBackgroundColor = Color(0xFFF7F8FB);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => GroupBuyService()),
      ],
      child: MaterialApp(
        title: 'SmartDeal Shop',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          platform: TargetPlatform.android,
          colorScheme: ColorScheme.fromSeed(
            seedColor: _primaryColor,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: _pageBackgroundColor,
          visualDensity: VisualDensity.standard,
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 2,
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 1,
            margin: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE1E5EA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _primaryColor, width: 2),
            ),
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
        ),
        initialRoute: AppRoutes.auth,
        onGenerateRoute: (settings) {
          final name = settings.name ?? '';
          final invitePrefix = '${AppRoutes.groupBuyInvite}/';
          if (name.startsWith(invitePrefix)) {
            final token = name.substring(invitePrefix.length);
            if (token.isNotEmpty) {
              return MaterialPageRoute(
                builder: (_) => _AuthRequiredRoute(
                  child: GroupBuyInviteScreen(shareToken: token),
                ),
              );
            }
          }
          return null;
        },
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Không tìm thấy trang: ${settings.name}'),
            ),
          ),
        ),
        routes: {
          AppRoutes.auth: (_) => const AuthWrapper(),
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.signup: (_) => const SignupScreen(),
          AppRoutes.home: (_) => const _AuthRequiredRoute(child: HomeScreen()),
          AppRoutes.cart: (_) => const _AuthRequiredRoute(child: CartScreen()),
          AppRoutes.checkout: (_) =>
              const _AuthRequiredRoute(child: CheckoutScreen()),
          AppRoutes.orders: (_) =>
              const _AuthRequiredRoute(child: OrderHistoryScreen()),
          AppRoutes.flashSale: (_) =>
              const _AuthRequiredRoute(child: FlashSaleScreen()),
          AppRoutes.groupBuy: (_) =>
              const _AuthRequiredRoute(child: GroupBuyScreen()),
          AppRoutes.rebuy: (_) =>
              const _AuthRequiredRoute(child: RebuyScreen()),
          AppRoutes.qualityCommitment: (_) =>
              const _AuthRequiredRoute(child: QualityCommitmentScreen()),
          AppRoutes.admin: (_) => const _RoleProtectedRoute(
                allowedRoles: [AppConstants.roleAdmin],
                child: AdminRoot(),
              ),
          AppRoutes.adminProducts: (_) => const _RoleProtectedRoute(
                allowedRoles: [AppConstants.roleAdmin],
                child: AdminRoot(initialRoute: AppRoutes.adminProducts),
              ),
          AppRoutes.adminAddProduct: (_) => const _RoleProtectedRoute(
                allowedRoles: [AppConstants.roleAdmin],
                child: AdminRoot(initialRoute: AppRoutes.adminAddProduct),
              ),
          AppRoutes.adminOrders: (_) => const _RoleProtectedRoute(
                allowedRoles: [AppConstants.roleAdmin],
                child: AdminRoot(initialRoute: AppRoutes.adminOrders),
              ),
          AppRoutes.adminUsers: (_) => const _RoleProtectedRoute(
                allowedRoles: [AppConstants.roleAdmin],
                child: AdminRoot(initialRoute: AppRoutes.adminUsers),
              ),
          AppRoutes.adminFlashSale: (_) => const _RoleProtectedRoute(
                allowedRoles: [AppConstants.roleAdmin],
                child: AdminRoot(initialRoute: AppRoutes.adminFlashSale),
              ),
          AppRoutes.adminAnalytics: (_) => const _RoleProtectedRoute(
                allowedRoles: [AppConstants.roleAdmin],
                child: AdminRoot(initialRoute: AppRoutes.adminAnalytics),
              ),
          AppRoutes.adminSettings: (_) => const _RoleProtectedRoute(
                allowedRoles: [AppConstants.roleAdmin],
                child: AdminRoot(initialRoute: AppRoutes.adminSettings),
              ),
          AppRoutes.seedData: (_) => const _RoleProtectedRoute(
                allowedRoles: [AppConstants.roleAdmin],
                child: AdminRoot(initialRoute: AppRoutes.seedData),
              ),
          AppRoutes.seller: (_) => const _RoleProtectedRoute(
                allowedRoles: [AppConstants.roleSeller],
                child: SellerDashboard(),
              ),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const _RoleLandingScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

class _RoleLandingScreen extends StatefulWidget {
  const _RoleLandingScreen();

  @override
  State<_RoleLandingScreen> createState() => _RoleLandingScreenState();
}

class _RoleLandingScreenState extends State<_RoleLandingScreen> {
  late final Future<String?> _roleFuture;

  @override
  void initState() {
    super.initState();
    _roleFuture = Provider.of<AuthService>(context, listen: false).getUserRole();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        switch (snapshot.data) {
          case AppConstants.roleAdmin:
            return const AdminRoot();
          case AppConstants.roleSeller:
            return const SellerDashboard();
          default:
            return const HomeScreen();
        }
      },
    );
  }
}

class _RoleProtectedRoute extends StatefulWidget {
  const _RoleProtectedRoute({
    required this.allowedRoles,
    required this.child,
  });

  final List<String> allowedRoles;
  final Widget child;

  @override
  State<_RoleProtectedRoute> createState() => _RoleProtectedRouteState();
}

class _RoleProtectedRouteState extends State<_RoleProtectedRoute> {
  late final Future<String?> _roleFuture;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _roleFuture = authService.getUserRole();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.currentUser == null) {
      return const LoginScreen();
    }

    return FutureBuilder<String?>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (widget.allowedRoles.contains(snapshot.data)) {
          return widget.child;
        }

        return const HomeScreen();
      },
    );
  }
}

class _AuthRequiredRoute extends StatelessWidget {
  const _AuthRequiredRoute({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        return child;
      },
    );
  }
}
