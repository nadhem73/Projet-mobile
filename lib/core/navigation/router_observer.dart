// ignore_for_file: avoid_print
import 'package:flutter/widgets.dart';

class ScreenObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logCurrentScreen(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logCurrentScreen(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _logCurrentScreen(newRoute);
    }
  }

  void _logCurrentScreen(Route<dynamic> route) {
    final location = route.settings.name ?? 'unknown';
    final screenClass = _getScreenClass(location);
    final filePath = _getFilePath(location);

    print('═══════════════════════════════════════════');
    print('📍 Interface  : $screenClass');
    print('📄 Fichier   : $filePath');
    print('🔗 Route     : $location');
    print('═══════════════════════════════════════════');
  }

  String _getScreenClass(String location) {
    switch (location) {
      case '/splash':
        return 'MLSplashScreen';
      case '/walkthrough':
        return 'MLWalkThroughScreen';
      case '/login':
        return 'MLLoginScreen';
      case '/register':
        return 'MLRegistrationScreen';
      case '/forgot-password':
        return 'MLForgetPasswordScreen';
      case '/confirm-phone':
        return 'MLConfirmPhoneNumberScreen';
      case '/auth':
        return 'MLAuthenticationScreen';
      case '/dashboard':
        return 'MLDashboardScreen';
      case '/medicine':
        return 'MLMedicineScreen';
      case '/chat':
        return 'MLChatScreen';
      case '/order-detail':
        return 'MLOrderDetailScreen';
      case '/profile':
        return 'MLUpdateProfileScreen';
      case '/add-dependent':
        return 'MLAddDependentScreen';
      case '/doctor-detail':
        return 'MLDoctorDetailScreen';
      case '/specialist':
        return 'MLSpecialistScreen';
      case '/video-consult':
        return 'MLVideoConsultScreen';
      case '/book-appointment':
        return 'MLBookAppointmentScreen';
      case '/appointment-detail':
        return 'MLAppointmentDetailScreen';
      case '/pharmacy':
        return 'MLOnlinePharmacyScreen';
      case '/pharmacy-detail':
        return 'MLOnlinePharmacyDetailScreen';
      case '/product-detail':
        return 'MLProductDetailScreen';
      case '/product-more-detail':
        return 'MLProductMoreDetailScreen';
      case '/create-medicine':
        return 'MLCreateNewMedicine';
      case '/add-to-cart':
        return 'MLAddToCartScreen';
      case '/confirm-order':
        return 'MLConfirmOrderScreen';
      case '/add-voucher':
        return 'MLAddVoucherScreen';
      case '/add-payment':
        return 'MLAddPaymentScreen';
      case '/bot':
        return 'MLBotScreen';
      case '/rendez-vous':
        return 'MLRendezVousScreen';
      case '/medical-record':
        return 'MLMedicalRecordScreen';
      case '/lab-scan':
        return 'MLLabScanScreen';
      case '/ai-assistant':
        return 'MLAiAssistantScreen';
      case '/prescriptions':
        return 'MLPrescriptionScreen';
      case '/purchase-button':
        return 'PurchaseButton';
      case '/purchase-more':
        return 'PurchaseMoreScreen';
      default:
        return location.split('/').last;
    }
  }

  String _getFilePath(String location) {
    final map = {
      '/splash': 'features/home/presentation/screens/splash_screen.dart',
      '/walkthrough': 'features/home/presentation/screens/walkthrough_screen.dart',
      '/login': 'features/auth/presentation/screens/login_screen.dart',
      '/register': 'features/auth/presentation/screens/registration_screen.dart',
      '/forgot-password': 'features/auth/presentation/screens/forget_password_screen.dart',
      '/confirm-phone': 'features/auth/presentation/screens/confirm_phone_screen.dart',
      '/auth': 'features/auth/presentation/screens/authentication_screen.dart',
      '/dashboard': 'features/home/presentation/screens/dashboard_screen.dart',
      '/medicine': 'features/patient/presentation/screens/medicine_screen.dart',
      '/chat': 'features/patient/presentation/screens/chat_screen.dart',
      '/order-detail': 'features/patient/presentation/screens/order_detail_screen.dart',
      '/profile': 'features/patient/presentation/screens/profile_screen.dart',
      '/add-dependent': 'features/patient/presentation/screens/add_dependent_screen.dart',
      '/doctor-detail': 'features/doctor/presentation/screens/doctor_detail_screen.dart',
      '/specialist': 'features/doctor/presentation/screens/specialist_screen.dart',
      '/video-consult': 'features/doctor/presentation/screens/video_consult_screen.dart',
      '/book-appointment': 'features/appointment/presentation/screens/book_appointment_screen.dart',
      '/appointment-detail': 'features/appointment/presentation/screens/appointment_detail_screen.dart',
      '/pharmacy': 'features/pharmacy/presentation/screens/online_pharmacy_screen.dart',
      '/pharmacy-detail': 'features/pharmacy/presentation/screens/pharmacy_detail_screen.dart',
      '/product-detail': 'features/pharmacy/presentation/screens/product_detail_screen.dart',
      '/product-more-detail': 'features/pharmacy/presentation/screens/product_more_detail_screen.dart',
      '/create-medicine': 'features/pharmacy/presentation/screens/create_medicine_screen.dart',
      '/add-to-cart': 'features/pharmacy/presentation/screens/add_to_cart_screen.dart',
      '/confirm-order': 'features/pharmacy/presentation/screens/confirm_order_screen.dart',
      '/add-voucher': 'features/pharmacy/presentation/screens/add_voucher_screen.dart',
      '/add-payment': 'features/pharmacy/presentation/screens/add_payment_screen.dart',
      '/bot': 'features/home/presentation/screens/bot_screen.dart',
      '/rendez-vous': 'features/patient/presentation/screens/rendez_vous_screen.dart',
      '/medical-record': 'features/patient/presentation/screens/medical_record_screen.dart',
      '/lab-scan': 'features/patient/presentation/screens/lab_scan_screen.dart',
      '/ai-assistant': 'features/patient/presentation/screens/ai_assistant_screen.dart',
      '/prescriptions': 'features/patient/presentation/screens/prescription_screen.dart',
      '/purchase-button': 'core/widgets/purchase_button.dart',
      '/purchase-more': 'core/widgets/purchase_more_screen.dart',
    };
    return map[location] ?? 'unknown';
  }
}
