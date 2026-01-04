import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/onboarding/language_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/main_shell.dart';
import '../screens/ai_sathi/ai_categories_screen.dart';
import '../screens/ai_sathi/ai_chat_screen.dart';
import '../screens/ai_sathi/live_ai_call_screen.dart';
import '../screens/ai_sathi/ai_scan_screen.dart';
import '../screens/ai_sathi/health_analyzers_screen.dart';
import '../screens/ai_sathi/ayurvedic_doctors_screen.dart';
import '../screens/ai_sathi/ai_history_screen.dart';
import '../screens/doctors/doctor_search_screen.dart';
import '../screens/doctors/doctor_profile_screen.dart';
import '../screens/appointments/appointments_screen.dart';
import '../screens/appointments/video_call_screen.dart';
import '../screens/reminders/reminders_screen.dart';
import '../screens/reminders/add_reminder_screen.dart';
import '../screens/reminders/medicine_alarm_screen.dart';
import '../screens/reminders/reminder_detail_screen.dart';
import '../screens/calculators/calculators_screen.dart';
import '../screens/health_alerts/health_alerts_screen.dart';
import '../screens/emergency/emergency_screen.dart';
import '../screens/blood_banks/blood_banks_screen.dart';
import '../screens/nearby/nearby_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/consultation/consultation_room_screen.dart';
import '../screens/medicine_delivery/medicine_delivery_screen.dart';
import '../screens/medicine_delivery/cart_screen.dart';
import '../screens/hospitals/hospital_performance_screen.dart';
import '../screens/simulation/simulation_screen.dart';
import '../screens/simulation/simulations_list_screen.dart';
import '../screens/prevention/prevention_hub_screen.dart';
import '../screens/disease_surveillance/disease_surveillance_screen.dart';
import '../screens/medical_history/medical_history_screen.dart';
import '../screens/medical_history/add_document_screen.dart';
import '../screens/weather/weather_climate_screen.dart';
import '../screens/disease_surveillance/disease_detail_screen.dart';
import '../screens/diseases/disease_search_screen.dart';
import '../screens/diseases/disease_detail_screen.dart' as disease_enc;
import '../screens/drug_info/drug_search_screen.dart';
import '../screens/drug_info/drug_detail_screen.dart';
import '../screens/pharmacies/pharmacy_detail_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/language',
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/chats',
            builder: (context, state) => const AICategoriesScreen(),
          ),
          GoRoute(
            path: '/bookings',
            builder: (context, state) => const DoctorSearchScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/edit-profile',
            builder: (context, state) => const EditProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/ai-chat/:category',
        builder: (context, state) => AIChatScreen(
          category: state.pathParameters['category'] ?? 'physician',
        ),
      ),
      GoRoute(
        path: '/ai-voice/:specialist',
        builder: (context, state) => LiveAICallScreen(
          specialist: state.pathParameters['specialist'] ?? 'physician',
        ),
      ),
      GoRoute(
        path: '/health-analyzers',
        builder: (context, state) => const HealthAnalyzersScreen(),
      ),
      GoRoute(
        path: '/ayurvedic-doctors',
        builder: (context, state) => const AyurvedicDoctorsScreen(),
      ),
      GoRoute(
        path: '/ai-history',
        builder: (context, state) => const AIHistoryScreen(),
      ),
      GoRoute(
        path: '/ai-scan',
        builder: (context, state) => const AIScanScreen(),
      ),
      GoRoute(
        path: '/ai-scan/:type',
        builder: (context, state) => AIScanScreen(
          analyzerType: state.pathParameters['type'] ?? 'general',
        ),
      ),
      GoRoute(
        path: '/doctor/:id',
        builder: (context, state) => DoctorProfileScreen(
          doctorId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
      ),
      GoRoute(
        path: '/reminders',
        builder: (context, state) => const RemindersScreen(),
      ),
      GoRoute(
        path: '/reminders/add',
        builder: (context, state) {
          final editId = state.uri.queryParameters['edit'];
          return AddReminderScreen(
            editReminderId: editId != null ? int.tryParse(editId) : null,
          );
        },
      ),
      GoRoute(
        path: '/reminders/alarm',
        builder: (context, state) {
          final params = state.uri.queryParameters;
          return MedicineAlarmScreen(
            reminderId: int.tryParse(params['id'] ?? '0') ?? 0,
            medicineName: params['name'] ?? 'Medicine',
            dosage: params['dosage'] ?? '1 dose',
            instructions: params['instructions'],
          );
        },
      ),
      GoRoute(
        path: '/doctors',
        builder: (context, state) => const DoctorSearchScreen(),
      ),
      GoRoute(
        path: '/doctors/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return DoctorProfileScreen(doctorId: id);
        },
      ),
      GoRoute(
        path: '/appointments',
        builder: (context, state) => const AppointmentsScreen(),
      ),
      GoRoute(
        path: '/video-call',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return VideoCallScreen(
            appointmentId: extra['appointmentId'] ?? 0,
            roomId: extra['roomId'] ?? '',
            domain: extra['domain'],
            consultationType: extra['consultationType'] ?? 'video',
            doctorName: extra['doctorName'],
            doctorImage: extra['doctorImage'],
          );
        },
      ),
      GoRoute(
        path: '/reminders/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return ReminderDetailScreen(reminderId: id);
        },
      ),
      GoRoute(
        path: '/calculators',
        builder: (context, state) => const CalculatorsScreen(),
      ),
      GoRoute(
        path: '/health-alerts',
        builder: (context, state) => const HealthAlertsScreen(),
      ),
      GoRoute(
        path: '/disease-surveillance',
        builder: (context, state) => const DiseaseSurveillanceScreen(),
      ),
      GoRoute(
        path: '/disease-detail/:name',
        builder: (context, state) {
          final name =
              Uri.decodeComponent(state.pathParameters['name'] ?? 'Unknown');
          return DiseaseDetailScreen(diseaseName: name);
        },
      ),
      GoRoute(
        path: '/weather-climate',
        builder: (context, state) => const WeatherClimateScreen(),
      ),
      GoRoute(
        path: '/emergency',
        builder: (context, state) => const EmergencyScreen(),
      ),
      GoRoute(
        path: '/blood-banks',
        builder: (context, state) => const BloodBanksScreen(),
      ),
      GoRoute(
        path: '/nearby',
        builder: (context, state) => const NearbyScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/consultation/:roomId',
        builder: (context, state) => ConsultationRoomScreen(
          roomId: state.pathParameters['roomId'] ?? '',
          doctorName: state.uri.queryParameters['doctor'] ?? 'Doctor',
        ),
      ),
      GoRoute(
        path: '/medicine-delivery',
        builder: (context, state) => const MedicineDeliveryScreen(),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/hospital/:id',
        builder: (context, state) => HospitalPerformanceScreen(
          hospitalId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
      ),
      GoRoute(
        path: '/pharmacy/:id',
        builder: (context, state) => PharmacyDetailScreen(
          pharmacyId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
      ),
      GoRoute(
        path: '/cpr-simulation',
        builder: (context, state) =>
            const SimulationScreen(simulationType: 'adult-cpr'),
      ),
      GoRoute(
        path: '/simulation/:type',
        builder: (context, state) => SimulationScreen(
          simulationType: state.pathParameters['type'] ?? 'adult-cpr',
        ),
      ),
      GoRoute(
        path: '/simulations',
        builder: (context, state) => const SimulationsListScreen(),
      ),
      GoRoute(
        path: '/prevention',
        builder: (context, state) => const PreventionHubScreen(),
      ),
      GoRoute(
        path: '/medical-history',
        builder: (context, state) => const MedicalHistoryScreen(),
      ),
      GoRoute(
        path: '/medical-history/add-document',
        builder: (context, state) => const AddDocumentScreen(),
      ),
      // Disease Encyclopedia routes
      GoRoute(
        path: '/diseases',
        builder: (context, state) => const DiseaseSearchScreen(),
      ),
      GoRoute(
        path: '/disease-info/:name',
        builder: (context, state) => disease_enc.DiseaseDetailScreen(
          diseaseName: Uri.decodeComponent(state.pathParameters['name'] ?? ''),
        ),
      ),
      // Drug Info routes
      GoRoute(
        path: '/drugs',
        builder: (context, state) => const DrugSearchScreen(),
      ),
      GoRoute(
        path: '/drug-detail/:name',
        builder: (context, state) => DrugDetailScreen(
          drugName: Uri.decodeComponent(state.pathParameters['name'] ?? ''),
        ),
      ),
    ],
    redirect: (context, state) {
      final authProvider = context.read<AuthProvider>();
      final isLoggedIn = authProvider.isAuthenticated;
      final isOnboarded = authProvider.isOnboarded;

      final isOnSplash = state.matchedLocation == '/splash';
      final isOnLanguage = state.matchedLocation == '/language';
      final isOnWelcome = state.matchedLocation == '/welcome';
      final isOnAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (isOnSplash) return null;

      if (!isOnboarded && !isOnLanguage && !isOnWelcome) {
        return '/language';
      }

      if (isOnboarded && !isLoggedIn && !isOnAuth) {
        return '/login';
      }

      if (isLoggedIn && (isOnAuth || isOnLanguage || isOnWelcome)) {
        return '/home';
      }

      return null;
    },
  );
}
