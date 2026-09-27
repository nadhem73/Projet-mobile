import 'package:go_router/go_router.dart';
import 'package:medilab_prokit/features/auth/presentation/screens/login_screen.dart';
import 'package:medilab_prokit/features/auth/presentation/screens/registration_screen.dart';
import 'package:medilab_prokit/features/auth/presentation/screens/forget_password_screen.dart';
import 'package:medilab_prokit/features/auth/presentation/screens/confirm_phone_screen.dart';
import 'package:medilab_prokit/features/auth/presentation/screens/authentication_screen.dart';
import 'package:medilab_prokit/features/patient/presentation/screens/medicine_screen.dart';
import 'package:medilab_prokit/features/patient/presentation/screens/chat_screen.dart';
import 'package:medilab_prokit/features/patient/presentation/screens/order_detail_screen.dart';
import 'package:medilab_prokit/features/patient/presentation/screens/profile_screen.dart';
import 'package:medilab_prokit/features/patient/presentation/screens/add_dependent_screen.dart';
import 'package:medilab_prokit/features/doctor/presentation/screens/doctor_detail_screen.dart';
import 'package:medilab_prokit/features/doctor/presentation/screens/specialist_screen.dart';
import 'package:medilab_prokit/features/doctor/presentation/screens/video_consult_screen.dart';
import 'package:medilab_prokit/features/appointment/presentation/screens/book_appointment_screen.dart';
import 'package:medilab_prokit/features/appointment/presentation/screens/appointment_detail_screen.dart';
import 'package:medilab_prokit/features/pharmacy/presentation/screens/online_pharmacy_screen.dart';
import 'package:medilab_prokit/features/pharmacy/presentation/screens/pharmacy_detail_screen.dart';
import 'package:medilab_prokit/features/pharmacy/presentation/screens/product_detail_screen.dart';
import 'package:medilab_prokit/features/pharmacy/presentation/screens/product_more_detail_screen.dart';
import 'package:medilab_prokit/features/pharmacy/presentation/screens/create_medicine_screen.dart';
import 'package:medilab_prokit/features/pharmacy/presentation/screens/add_to_cart_screen.dart';
import 'package:medilab_prokit/features/pharmacy/presentation/screens/confirm_order_screen.dart';
import 'package:medilab_prokit/features/pharmacy/presentation/screens/add_voucher_screen.dart';
import 'package:medilab_prokit/features/pharmacy/presentation/screens/add_payment_screen.dart';
import 'package:medilab_prokit/features/home/presentation/screens/dashboard_screen.dart';
import 'package:medilab_prokit/features/home/presentation/screens/splash_screen.dart';
import 'package:medilab_prokit/features/home/presentation/screens/walkthrough_screen.dart';
import 'package:medilab_prokit/features/home/presentation/screens/bot_screen.dart';
import 'package:medilab_prokit/features/patient/presentation/screens/rendez_vous_screen.dart';
import 'package:medilab_prokit/features/patient/presentation/screens/medical_record_screen.dart';
import 'package:medilab_prokit/features/patient/presentation/screens/lab_scan_screen.dart';
import 'package:medilab_prokit/features/patient/presentation/screens/ai_assistant_screen.dart';
import 'package:medilab_prokit/features/patient/presentation/screens/prescription_screen.dart';
import 'package:medilab_prokit/core/widgets/purchase_button.dart';
import 'package:medilab_prokit/core/widgets/purchase_more_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const MLSplashScreen(),
    ),
    GoRoute(
      path: '/walkthrough',
      builder: (context, state) => const MLWalkThroughScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const MLLoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const MLRegistrationScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const MLForgetPasswordScreen(),
    ),
    GoRoute(
      path: '/confirm-phone',
      builder: (context, state) => const MLConfirmPhoneNumberScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const MLAuthenticationScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const MLDashboardScreen(),
    ),
    GoRoute(
      path: '/medicine',
      builder: (context, state) => const MLMedicineScreen(),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) => const MLChatScreen(),
    ),
    GoRoute(
      path: '/order-detail',
      builder: (context, state) => const MLOrderDetailScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const MLUpdateProfileScreen(),
    ),
    GoRoute(
      path: '/add-dependent',
      builder: (context, state) => const MLAddDependentScreen(),
    ),
    GoRoute(
      path: '/doctor-detail',
      builder: (context, state) => const MLDoctorDetailScreen(),
    ),
    GoRoute(
      path: '/specialist',
      builder: (context, state) => const MLSpecialistScreen(),
    ),
    GoRoute(
      path: '/video-consult',
      builder: (context, state) => const MLVideoConsultScreen(),
    ),
    GoRoute(
      path: '/book-appointment',
      builder: (context, state) => const MLBookAppointmentScreen(),
    ),
    GoRoute(
      path: '/appointment-detail',
      builder: (context, state) => const MLAppointmentDetailScreen(),
    ),
    GoRoute(
      path: '/pharmacy',
      builder: (context, state) => const MLOnlinePharmacyScreen(),
    ),
    GoRoute(
      path: '/pharmacy-detail',
      builder: (context, state) => const MLOnlinePharmacyDetailScreen(),
    ),
    GoRoute(
      path: '/product-detail',
      builder: (context, state) => const MLProductDetailScreen(),
    ),
    GoRoute(
      path: '/product-more-detail',
      builder: (context, state) => const MLProductMoreDetailScreen(),
    ),
    GoRoute(
      path: '/create-medicine',
      builder: (context, state) => const MLCreateNewMedicine(),
    ),
    GoRoute(
      path: '/add-to-cart',
      builder: (context, state) => const MLAddToCartScreen(),
    ),
    GoRoute(
      path: '/confirm-order',
      builder: (context, state) => const MLConfirmOrderScreen(),
    ),
    GoRoute(
      path: '/add-voucher',
      builder: (context, state) => const MLAddVoucherScreen(),
    ),
    GoRoute(
      path: '/add-payment',
      builder: (context, state) => const MLAddPaymentScreen(),
    ),
    GoRoute(
      path: '/bot',
      builder: (context, state) => const MLBotScreen(),
    ),
    GoRoute(
      path: '/rendez-vous',
      builder: (context, state) => const MLRendezVousScreen(),
    ),
    GoRoute(
      path: '/medical-record',
      builder: (context, state) => const MLMedicalRecordScreen(),
    ),
    GoRoute(
      path: '/lab-scan',
      builder: (context, state) => const MLLabScanScreen(),
    ),
    GoRoute(
      path: '/ai-assistant',
      builder: (context, state) => const MLAiAssistantScreen(),
    ),
    GoRoute(
      path: '/prescriptions',
      builder: (context, state) => const MLPrescriptionScreen(),
    ),
    GoRoute(
      path: '/purchase-button',
      builder: (context, state) => const PurchaseButton(),
    ),
    GoRoute(
      path: '/purchase-more',
      builder: (context, state) => const PurchaseMoreScreen(),
    ),
  ],
);