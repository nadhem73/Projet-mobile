import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/modules/feature_module.dart';
import 'package:medilink/core/navigation/app_routes.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/pharmacy/presentation/screens/add_payment_screen.dart';
import 'package:medilink/features/pharmacy/presentation/screens/add_to_cart_screen.dart';
import 'package:medilink/features/pharmacy/presentation/screens/add_voucher_screen.dart';
import 'package:medilink/features/pharmacy/presentation/screens/confirm_order_screen.dart';
import 'package:medilink/features/pharmacy/presentation/screens/create_medicine_screen.dart';
import 'package:medilink/features/pharmacy/presentation/screens/medicine_screen.dart';
import 'package:medilink/features/pharmacy/presentation/screens/online_pharmacy_screen.dart';
import 'package:medilink/features/pharmacy/presentation/screens/order_detail_screen.dart';
import 'package:medilink/features/pharmacy/presentation/screens/pharmacist_dashboard_screen.dart';
import 'package:medilink/features/pharmacy/presentation/screens/pharmacy_detail_screen.dart';
import 'package:medilink/features/pharmacy/presentation/screens/product_detail_screen.dart';
import 'package:medilink/features/pharmacy/presentation/screens/product_more_detail_screen.dart';

/// Module PHARMACIE — Membre 4.
/// Catalogue des médicaments (dataset PostgreSQL), commandes, rappels de prise.
abstract final class PharmacyRoutes {
  /// Panel du pharmacien (espace réservé au rôle PHARMACIST).
  static const dashboard = AppRoutes.pharmacistHome;

  static const home = '/pharmacy';
  static const detail = '/pharmacy-detail';
  static const product = '/product-detail';
  static const productMore = '/product-more-detail';
  static const medicines = '/medicine';
  static const createMedicine = '/create-medicine';
  static const cart = '/add-to-cart';
  static const confirmOrder = '/confirm-order';
  static const orderDetail = '/order-detail';
  static const addVoucher = '/add-voucher';
  static const addPayment = '/add-payment';
}

class PharmacyModule extends FeatureModule {
  const PharmacyModule();

  @override
  String get name => 'Pharmacie';

  @override
  void registerDependencies(GetIt getIt) {
    // TODO(pharmacy): enregistrer MedicamentRepository (API PostgreSQL), OrderRepository...
  }

  @override
  List<RouteBase> get routes => [
    GoRoute(path: PharmacyRoutes.dashboard, builder: (_, _) => const PharmacistDashboardScreen()),
    GoRoute(path: PharmacyRoutes.home, builder: (_, _) => const MLOnlinePharmacyScreen()),
    GoRoute(path: PharmacyRoutes.detail, builder: (_, _) => const MLOnlinePharmacyDetailScreen()),
    GoRoute(path: PharmacyRoutes.product, builder: (_, _) => const MLProductDetailScreen()),
    GoRoute(path: PharmacyRoutes.productMore, builder: (_, _) => const MLProductMoreDetailScreen()),
    GoRoute(path: PharmacyRoutes.medicines, builder: (_, _) => const MLMedicineScreen()),
    GoRoute(path: PharmacyRoutes.createMedicine, builder: (_, _) => const MLCreateNewMedicine()),
    GoRoute(path: PharmacyRoutes.cart, builder: (_, _) => const MLAddToCartScreen()),
    GoRoute(path: PharmacyRoutes.confirmOrder, builder: (_, _) => const MLConfirmOrderScreen()),
    GoRoute(path: PharmacyRoutes.orderDetail, builder: (_, _) => const MLOrderDetailScreen()),
    GoRoute(path: PharmacyRoutes.addVoucher, builder: (_, _) => const MLAddVoucherScreen()),
    GoRoute(path: PharmacyRoutes.addPayment, builder: (_, _) => const MLAddPaymentScreen()),
  ];

  @override
  List<ModuleShortcut> get patientShortcuts => const [
    ModuleShortcut(
      label: 'Pharmacie',
      icon: Icons.local_pharmacy_rounded,
      route: PharmacyRoutes.home,
      color: AppColors.modulePharmacy,
      order: 50,
    ),
  ];
}
