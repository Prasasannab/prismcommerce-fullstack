import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/storage/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/cart/bloc/cart_bloc.dart';
import 'features/cart/data/repositories/cart_repository.dart';
import 'features/catalog/bloc/catalog_bloc.dart';
import 'features/catalog/data/repositories/catalog_repository.dart';
import 'features/navigation/presentation/screens/main_navigation_shell.dart';
import 'features/orders/bloc/orders_bloc.dart';
import 'features/orders/data/repositories/orders_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive local persistence
  await StorageService.init();

  runApp(const PrismCommerceApp());
}

/// Root widget for the PrismCommerce Flutter Mobile Application.
/// Injects central repositories, ThemeCubit, and BLoC state providers.
class PrismCommerceApp extends StatelessWidget {
  final CatalogRepository? catalogRepository;
  final CartRepository? cartRepository;
  final AuthRepository? authRepository;
  final OrdersRepository? ordersRepository;
  final ThemeCubit? themeCubit;
  final AuthBloc? authBloc;
  final OrdersBloc? ordersBloc;

  const PrismCommerceApp({
    super.key,
    this.catalogRepository,
    this.cartRepository,
    this.authRepository,
    this.ordersRepository,
    this.themeCubit,
    this.authBloc,
    this.ordersBloc,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<CatalogRepository>(
          create: (context) => catalogRepository ?? CatalogRepository(),
        ),
        RepositoryProvider<CartRepository>(
          create: (context) => cartRepository ?? CartRepository(),
        ),
        RepositoryProvider<AuthRepository>(
          create: (context) => authRepository ?? AuthRepository(),
        ),
        RepositoryProvider<OrdersRepository>(
          create: (context) => ordersRepository ?? OrdersRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(
            create: (context) =>
                themeCubit ??
                ThemeCubit(storageService: StorageService.instance),
          ),
          BlocProvider<AuthBloc>(
            create: (context) =>
                authBloc ??
                (AuthBloc(
                  authRepository: context.read<AuthRepository>(),
                )..add(const AuthCheckRequested())),
          ),
          BlocProvider<CatalogBloc>(
            create: (context) => CatalogBloc(
              catalogRepository: context.read<CatalogRepository>(),
            )..add(const CatalogStarted()),
          ),
          BlocProvider<CartBloc>(
            create: (context) => CartBloc(
              cartRepository: context.read<CartRepository>(),
            )..add(const CartStarted()),
          ),
          BlocProvider<OrdersBloc>(
            create: (context) =>
                ordersBloc ??
                (OrdersBloc(
                  ordersRepository: context.read<OrdersRepository>(),
                )..add(const OrdersStarted())),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp(
              title: 'PrismCommerce',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              home: const MainNavigationShell(),
            );
          },
        ),
      ),
    );
  }
}
