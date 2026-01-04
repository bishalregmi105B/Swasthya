import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ne.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ne')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Swasthya'**
  String get appName;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your AI-Powered Health Companion'**
  String get welcomeSubtitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @selectLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get selectLanguageSubtitle;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @nepali.
  ///
  /// In en, this message translates to:
  /// **'नेपाली'**
  String get nepali;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @termsAgree.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms of Service and Privacy Policy'**
  String get termsAgree;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @aiSathi.
  ///
  /// In en, this message translates to:
  /// **'AI Sathi'**
  String get aiSathi;

  /// No description provided for @aiSathiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your 24/7 AI Health Assistant'**
  String get aiSathiSubtitle;

  /// No description provided for @askAiSathi.
  ///
  /// In en, this message translates to:
  /// **'Ask AI Sathi'**
  String get askAiSathi;

  /// No description provided for @aiDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Content is for informational purposes only. Not a medical diagnosis. Always consult a real doctor.'**
  String get aiDisclaimer;

  /// No description provided for @typeSymptomsHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your symptoms...'**
  String get typeSymptomsHint;

  /// No description provided for @selectSpecialist.
  ///
  /// In en, this message translates to:
  /// **'Select a Specialist'**
  String get selectSpecialist;

  /// No description provided for @newConsultation.
  ///
  /// In en, this message translates to:
  /// **'New Consultation'**
  String get newConsultation;

  /// No description provided for @generalPhysician.
  ///
  /// In en, this message translates to:
  /// **'General Physician AI'**
  String get generalPhysician;

  /// No description provided for @mentalHealth.
  ///
  /// In en, this message translates to:
  /// **'Mental Health AI'**
  String get mentalHealth;

  /// No description provided for @dermatologist.
  ///
  /// In en, this message translates to:
  /// **'Dermatologist AI'**
  String get dermatologist;

  /// No description provided for @pediatrician.
  ///
  /// In en, this message translates to:
  /// **'Pediatrician AI'**
  String get pediatrician;

  /// No description provided for @nutritionist.
  ///
  /// In en, this message translates to:
  /// **'Nutrition & Diet AI'**
  String get nutritionist;

  /// No description provided for @cardiologist.
  ///
  /// In en, this message translates to:
  /// **'Heart Health AI'**
  String get cardiologist;

  /// No description provided for @howAreYouFeeling.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling today?'**
  String get howAreYouFeeling;

  /// No description provided for @talkToAIDoctor.
  ///
  /// In en, this message translates to:
  /// **'Talk to AI Doctor'**
  String get talkToAIDoctor;

  /// No description provided for @callAIDoctor.
  ///
  /// In en, this message translates to:
  /// **'Call AI Doctor'**
  String get callAIDoctor;

  /// No description provided for @chatWithAI.
  ///
  /// In en, this message translates to:
  /// **'Chat with AI'**
  String get chatWithAI;

  /// No description provided for @scanHealthImage.
  ///
  /// In en, this message translates to:
  /// **'Scan Health Image'**
  String get scanHealthImage;

  /// No description provided for @voiceCall.
  ///
  /// In en, this message translates to:
  /// **'Voice Call'**
  String get voiceCall;

  /// No description provided for @aiHealthConsultation.
  ///
  /// In en, this message translates to:
  /// **'AI Health Consultation'**
  String get aiHealthConsultation;

  /// No description provided for @aiHealthScan.
  ///
  /// In en, this message translates to:
  /// **'AI Health Scan'**
  String get aiHealthScan;

  /// No description provided for @uploadHealthImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Health Image'**
  String get uploadHealthImage;

  /// No description provided for @takePhotoOrGallery.
  ///
  /// In en, this message translates to:
  /// **'Take a photo or choose from gallery'**
  String get takePhotoOrGallery;

  /// No description provided for @skinConditionsHint.
  ///
  /// In en, this message translates to:
  /// **'Skin conditions, rashes, injuries, etc.'**
  String get skinConditionsHint;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @analyzingImage.
  ///
  /// In en, this message translates to:
  /// **'Analyzing image...'**
  String get analyzingImage;

  /// No description provided for @aiAnalysis.
  ///
  /// In en, this message translates to:
  /// **'AI Analysis'**
  String get aiAnalysis;

  /// No description provided for @askAboutImage.
  ///
  /// In en, this message translates to:
  /// **'Ask about this image...'**
  String get askAboutImage;

  /// No description provided for @uploadImageToStart.
  ///
  /// In en, this message translates to:
  /// **'Upload an image to get started'**
  String get uploadImageToStart;

  /// No description provided for @uploadHealthImageDesc.
  ///
  /// In en, this message translates to:
  /// **'Upload health images for analysis'**
  String get uploadHealthImageDesc;

  /// No description provided for @aiImageConsultation.
  ///
  /// In en, this message translates to:
  /// **'AI Image Consultation'**
  String get aiImageConsultation;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @upcomingAppointments.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Appointments'**
  String get upcomingAppointments;

  /// No description provided for @topHospitals.
  ///
  /// In en, this message translates to:
  /// **'Top Hospitals'**
  String get topHospitals;

  /// No description provided for @preventionTips.
  ///
  /// In en, this message translates to:
  /// **'Prevention Tips'**
  String get preventionTips;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @aiDoctor.
  ///
  /// In en, this message translates to:
  /// **'AI Doctor'**
  String get aiDoctor;

  /// No description provided for @listeningToYou.
  ///
  /// In en, this message translates to:
  /// **'Listening to you...'**
  String get listeningToYou;

  /// No description provided for @aiThinking.
  ///
  /// In en, this message translates to:
  /// **'AI is thinking...'**
  String get aiThinking;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @calibrating.
  ///
  /// In en, this message translates to:
  /// **'Calibrating microphone...'**
  String get calibrating;

  /// No description provided for @endCall.
  ///
  /// In en, this message translates to:
  /// **'End Call'**
  String get endCall;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @findDoctor.
  ///
  /// In en, this message translates to:
  /// **'Find a Specialist'**
  String get findDoctor;

  /// No description provided for @doctorProfile.
  ///
  /// In en, this message translates to:
  /// **'Doctor Profile'**
  String get doctorProfile;

  /// No description provided for @bookAppointment.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookAppointment;

  /// No description provided for @consultationType.
  ///
  /// In en, this message translates to:
  /// **'Consultation Type'**
  String get consultationType;

  /// No description provided for @videoCall.
  ///
  /// In en, this message translates to:
  /// **'Video Call'**
  String get videoCall;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @inPerson.
  ///
  /// In en, this message translates to:
  /// **'In Person'**
  String get inPerson;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @nextAvailable.
  ///
  /// In en, this message translates to:
  /// **'Next Available'**
  String get nextAvailable;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @patients.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get patients;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// No description provided for @startChat.
  ///
  /// In en, this message translates to:
  /// **'Start Chat'**
  String get startChat;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @myMedicines.
  ///
  /// In en, this message translates to:
  /// **'My Medicines'**
  String get myMedicines;

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'Add Reminder'**
  String get addReminder;

  /// No description provided for @medicineName.
  ///
  /// In en, this message translates to:
  /// **'Medicine Name'**
  String get medicineName;

  /// No description provided for @dosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosage;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get afternoon;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @markAsTaken.
  ///
  /// In en, this message translates to:
  /// **'Mark as Taken'**
  String get markAsTaken;

  /// No description provided for @refillReminder.
  ///
  /// In en, this message translates to:
  /// **'Refill Reminder'**
  String get refillReminder;

  /// No description provided for @criticalAlert.
  ///
  /// In en, this message translates to:
  /// **'Critical Alert'**
  String get criticalAlert;

  /// No description provided for @aiInsight.
  ///
  /// In en, this message translates to:
  /// **'AI Insight'**
  String get aiInsight;

  /// No description provided for @healthCalculators.
  ///
  /// In en, this message translates to:
  /// **'Health Calculators'**
  String get healthCalculators;

  /// No description provided for @bmiCalculator.
  ///
  /// In en, this message translates to:
  /// **'BMI Calculator'**
  String get bmiCalculator;

  /// No description provided for @ibwCalculator.
  ///
  /// In en, this message translates to:
  /// **'Ideal Body Weight'**
  String get ibwCalculator;

  /// No description provided for @heartRateCalculator.
  ///
  /// In en, this message translates to:
  /// **'Target Heart Rate'**
  String get heartRateCalculator;

  /// No description provided for @bloodVolumeCalculator.
  ///
  /// In en, this message translates to:
  /// **'Blood Volume'**
  String get bloodVolumeCalculator;

  /// No description provided for @calculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get calculate;

  /// No description provided for @result.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get result;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @healthAlerts.
  ///
  /// In en, this message translates to:
  /// **'Health Alerts'**
  String get healthAlerts;

  /// No description provided for @criticalAlerts.
  ///
  /// In en, this message translates to:
  /// **'Critical Alerts'**
  String get criticalAlerts;

  /// No description provided for @trendingNearYou.
  ///
  /// In en, this message translates to:
  /// **'Trending Near You'**
  String get trendingNearYou;

  /// No description provided for @aiSummary.
  ///
  /// In en, this message translates to:
  /// **'AI Summary'**
  String get aiSummary;

  /// No description provided for @riskLevel.
  ///
  /// In en, this message translates to:
  /// **'Risk Level'**
  String get riskLevel;

  /// No description provided for @lowRisk.
  ///
  /// In en, this message translates to:
  /// **'Low Risk'**
  String get lowRisk;

  /// No description provided for @moderateRisk.
  ///
  /// In en, this message translates to:
  /// **'Moderate Risk'**
  String get moderateRisk;

  /// No description provided for @highRisk.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get highRisk;

  /// No description provided for @bloodBanks.
  ///
  /// In en, this message translates to:
  /// **'Blood Banks'**
  String get bloodBanks;

  /// No description provided for @ngoDirectory.
  ///
  /// In en, this message translates to:
  /// **'NGO Directory'**
  String get ngoDirectory;

  /// No description provided for @bloodType.
  ///
  /// In en, this message translates to:
  /// **'Blood Type'**
  String get bloodType;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @callNow.
  ///
  /// In en, this message translates to:
  /// **'Call Now'**
  String get callNow;

  /// No description provided for @getDirections.
  ///
  /// In en, this message translates to:
  /// **'Get Directions'**
  String get getDirections;

  /// No description provided for @donate.
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get donate;

  /// No description provided for @emergencyServices.
  ///
  /// In en, this message translates to:
  /// **'Emergency Services'**
  String get emergencyServices;

  /// No description provided for @sos.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sos;

  /// No description provided for @callEmergency.
  ///
  /// In en, this message translates to:
  /// **'Call Emergency'**
  String get callEmergency;

  /// No description provided for @ambulance.
  ///
  /// In en, this message translates to:
  /// **'Ambulance'**
  String get ambulance;

  /// No description provided for @police.
  ///
  /// In en, this message translates to:
  /// **'Police'**
  String get police;

  /// No description provided for @fireDept.
  ///
  /// In en, this message translates to:
  /// **'Fire Dept'**
  String get fireDept;

  /// No description provided for @poisonControl.
  ///
  /// In en, this message translates to:
  /// **'Poison Control'**
  String get poisonControl;

  /// No description provided for @emergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get emergencyContacts;

  /// No description provided for @addContact.
  ///
  /// In en, this message translates to:
  /// **'Add Contact'**
  String get addContact;

  /// No description provided for @aiTriage.
  ///
  /// In en, this message translates to:
  /// **'AI Rapid Triage'**
  String get aiTriage;

  /// No description provided for @triageHint.
  ///
  /// In en, this message translates to:
  /// **'Describe symptoms for immediate AI guidance...'**
  String get triageHint;

  /// No description provided for @nearbyFacilities.
  ///
  /// In en, this message translates to:
  /// **'Nearby Facilities'**
  String get nearbyFacilities;

  /// No description provided for @hospitals.
  ///
  /// In en, this message translates to:
  /// **'Hospitals'**
  String get hospitals;

  /// No description provided for @pharmacies.
  ///
  /// In en, this message translates to:
  /// **'Pharmacies'**
  String get pharmacies;

  /// No description provided for @clinics.
  ///
  /// In en, this message translates to:
  /// **'Clinics'**
  String get clinics;

  /// No description provided for @open24Hours.
  ///
  /// In en, this message translates to:
  /// **'Open 24 Hours'**
  String get open24Hours;

  /// No description provided for @openNow.
  ///
  /// In en, this message translates to:
  /// **'Open Now'**
  String get openNow;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @cprSimulation.
  ///
  /// In en, this message translates to:
  /// **'CPR Simulation'**
  String get cprSimulation;

  /// No description provided for @startSimulation.
  ///
  /// In en, this message translates to:
  /// **'Start Simulation'**
  String get startSimulation;

  /// No description provided for @pauseSimulation.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseSimulation;

  /// No description provided for @resumeSimulation.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeSimulation;

  /// No description provided for @voiceGuidance.
  ///
  /// In en, this message translates to:
  /// **'Voice Guidance'**
  String get voiceGuidance;

  /// No description provided for @compressionRate.
  ///
  /// In en, this message translates to:
  /// **'Compression Rate'**
  String get compressionRate;

  /// No description provided for @compressionDepth.
  ///
  /// In en, this message translates to:
  /// **'Compression Depth'**
  String get compressionDepth;

  /// No description provided for @prevention.
  ///
  /// In en, this message translates to:
  /// **'Prevention'**
  String get prevention;

  /// No description provided for @dailyInsight.
  ///
  /// In en, this message translates to:
  /// **'Daily Insight'**
  String get dailyInsight;

  /// No description provided for @dailyGoals.
  ///
  /// In en, this message translates to:
  /// **'Daily Goals'**
  String get dailyGoals;

  /// No description provided for @drinkWater.
  ///
  /// In en, this message translates to:
  /// **'Drink Water'**
  String get drinkWater;

  /// No description provided for @takeVitamins.
  ///
  /// In en, this message translates to:
  /// **'Take Vitamins'**
  String get takeVitamins;

  /// No description provided for @sleepEarly.
  ///
  /// In en, this message translates to:
  /// **'Sleep Early'**
  String get sleepEarly;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @diseaseEncyclopedia.
  ///
  /// In en, this message translates to:
  /// **'Disease Encyclopedia'**
  String get diseaseEncyclopedia;

  /// No description provided for @searchDiseases.
  ///
  /// In en, this message translates to:
  /// **'Search diseases...'**
  String get searchDiseases;

  /// No description provided for @commonDiseases.
  ///
  /// In en, this message translates to:
  /// **'Common Diseases'**
  String get commonDiseases;

  /// No description provided for @searchOrSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Search for diseases or select a category'**
  String get searchOrSelectCategory;

  /// No description provided for @medicineDatabase.
  ///
  /// In en, this message translates to:
  /// **'Medicine Database'**
  String get medicineDatabase;

  /// No description provided for @searchMedicines.
  ///
  /// In en, this message translates to:
  /// **'Search medicines...'**
  String get searchMedicines;

  /// No description provided for @commonMedicines.
  ///
  /// In en, this message translates to:
  /// **'Common Medicines'**
  String get commonMedicines;

  /// No description provided for @drugInfo.
  ///
  /// In en, this message translates to:
  /// **'Drug Info'**
  String get drugInfo;

  /// No description provided for @diseases.
  ///
  /// In en, this message translates to:
  /// **'Diseases'**
  String get diseases;

  /// No description provided for @talkToAIPharmacist.
  ///
  /// In en, this message translates to:
  /// **'Talk to AI Pharmacist'**
  String get talkToAIPharmacist;

  /// No description provided for @askAI.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get askAI;

  /// No description provided for @startAICall.
  ///
  /// In en, this message translates to:
  /// **'Start AI Call'**
  String get startAICall;

  /// No description provided for @aiWillDiscuss.
  ///
  /// In en, this message translates to:
  /// **'AI will discuss:'**
  String get aiWillDiscuss;

  /// No description provided for @symptomsAndCauses.
  ///
  /// In en, this message translates to:
  /// **'Symptoms & Causes'**
  String get symptomsAndCauses;

  /// No description provided for @treatmentOptions.
  ///
  /// In en, this message translates to:
  /// **'Treatment Options'**
  String get treatmentOptions;

  /// No description provided for @usageAndDosage.
  ///
  /// In en, this message translates to:
  /// **'Usage & Dosage'**
  String get usageAndDosage;

  /// No description provided for @sideEffects.
  ///
  /// In en, this message translates to:
  /// **'Side Effects'**
  String get sideEffects;

  /// No description provided for @drugInteractions.
  ///
  /// In en, this message translates to:
  /// **'Drug Interactions'**
  String get drugInteractions;

  /// No description provided for @storageTips.
  ///
  /// In en, this message translates to:
  /// **'Storage Tips'**
  String get storageTips;

  /// No description provided for @fdaApprovedInfo.
  ///
  /// In en, this message translates to:
  /// **'FDA Approved Information'**
  String get fdaApprovedInfo;

  /// No description provided for @indications.
  ///
  /// In en, this message translates to:
  /// **'Indications'**
  String get indications;

  /// No description provided for @forInfoOnly.
  ///
  /// In en, this message translates to:
  /// **'For informational purposes only.'**
  String get forInfoOnly;

  /// No description provided for @consultHealthcare.
  ///
  /// In en, this message translates to:
  /// **'Consult a healthcare provider.'**
  String get consultHealthcare;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @deliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get deliveryFee;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get placeOrder;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @uploadPrescription.
  ///
  /// In en, this message translates to:
  /// **'Upload Prescription'**
  String get uploadPrescription;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @medicineDelivery.
  ///
  /// In en, this message translates to:
  /// **'Medicine Delivery'**
  String get medicineDelivery;

  /// No description provided for @onTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get onTheWay;

  /// No description provided for @arrivingIn.
  ///
  /// In en, this message translates to:
  /// **'Arriving in ~15 mins'**
  String get arrivingIn;

  /// No description provided for @askAIPharmacist.
  ///
  /// In en, this message translates to:
  /// **'Ask AI Pharmacist'**
  String get askAIPharmacist;

  /// No description provided for @popularProducts.
  ///
  /// In en, this message translates to:
  /// **'Popular Products'**
  String get popularProducts;

  /// No description provided for @partneredPharmacies.
  ///
  /// In en, this message translates to:
  /// **'Partnered Pharmacies'**
  String get partneredPharmacies;

  /// No description provided for @emergencyTraining.
  ///
  /// In en, this message translates to:
  /// **'Emergency Training'**
  String get emergencyTraining;

  /// No description provided for @practiceAgain.
  ///
  /// In en, this message translates to:
  /// **'Practice Again'**
  String get practiceAgain;

  /// No description provided for @simulationComplete.
  ///
  /// In en, this message translates to:
  /// **'Simulation Complete!'**
  String get simulationComplete;

  /// No description provided for @backToSimulations.
  ///
  /// In en, this message translates to:
  /// **'Back to Simulations'**
  String get backToSimulations;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get failedToLoad;

  /// No description provided for @noSimulationsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No simulations available'**
  String get noSimulationsAvailable;

  /// No description provided for @couldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load'**
  String get couldNotLoad;

  /// No description provided for @diseaseWatch.
  ///
  /// In en, this message translates to:
  /// **'Disease Watch'**
  String get diseaseWatch;

  /// No description provided for @nepalHealthStatus.
  ///
  /// In en, this message translates to:
  /// **'Nepal Health Status'**
  String get nepalHealthStatus;

  /// No description provided for @vaccinationCoverage.
  ///
  /// In en, this message translates to:
  /// **'Vaccination Coverage'**
  String get vaccinationCoverage;

  /// No description provided for @weatherAndAirQuality.
  ///
  /// In en, this message translates to:
  /// **'Weather & Air Quality'**
  String get weatherAndAirQuality;

  /// No description provided for @loadingPersonalizedTips.
  ///
  /// In en, this message translates to:
  /// **'Loading personalized tips...'**
  String get loadingPersonalizedTips;

  /// No description provided for @loadingHealthAlerts.
  ///
  /// In en, this message translates to:
  /// **'Loading health alerts...'**
  String get loadingHealthAlerts;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @medicalInformation.
  ///
  /// In en, this message translates to:
  /// **'Medical Information'**
  String get medicalInformation;

  /// No description provided for @drugInformation.
  ///
  /// In en, this message translates to:
  /// **'Drug Information'**
  String get drugInformation;

  /// No description provided for @aboutDisease.
  ///
  /// In en, this message translates to:
  /// **'About {name}'**
  String aboutDisease(Object name);

  /// No description provided for @aboutDrug.
  ///
  /// In en, this message translates to:
  /// **'About {name}'**
  String aboutDrug(Object name);

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get step;

  /// No description provided for @ofText.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get ofText;

  /// No description provided for @call102.
  ///
  /// In en, this message translates to:
  /// **'Call 102'**
  String get call102;

  /// No description provided for @greatJobCompleted.
  ///
  /// In en, this message translates to:
  /// **'Great job! You completed all steps of the training.'**
  String get greatJobCompleted;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get inStock;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @viewAllDiseases.
  ///
  /// In en, this message translates to:
  /// **'View All Diseases'**
  String get viewAllDiseases;

  /// No description provided for @viewAllMedicines.
  ///
  /// In en, this message translates to:
  /// **'View All Medicines'**
  String get viewAllMedicines;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearch;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @myAppointments.
  ///
  /// In en, this message translates to:
  /// **'My Appointments'**
  String get myAppointments;

  /// No description provided for @medicalHistory.
  ///
  /// In en, this message translates to:
  /// **'Medical History'**
  String get medicalHistory;

  /// No description provided for @addMedicalDocument.
  ///
  /// In en, this message translates to:
  /// **'Add Medical Document'**
  String get addMedicalDocument;

  /// No description provided for @markAsCritical.
  ///
  /// In en, this message translates to:
  /// **'Mark as Critical'**
  String get markAsCritical;

  /// No description provided for @flagAbnormalResults.
  ///
  /// In en, this message translates to:
  /// **'Flag abnormal or important results'**
  String get flagAbnormalResults;

  /// No description provided for @organDonor.
  ///
  /// In en, this message translates to:
  /// **'Organ Donor'**
  String get organDonor;

  /// No description provided for @aiChatHistory.
  ///
  /// In en, this message translates to:
  /// **'AI Chat History'**
  String get aiChatHistory;

  /// No description provided for @chatHistory.
  ///
  /// In en, this message translates to:
  /// **'Chat History'**
  String get chatHistory;

  /// No description provided for @deleteConversation.
  ///
  /// In en, this message translates to:
  /// **'Delete Conversation'**
  String get deleteConversation;

  /// No description provided for @clearAllHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear All History'**
  String get clearAllHistory;

  /// No description provided for @noConversationsYet.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsYet;

  /// No description provided for @startChattingWithAI.
  ///
  /// In en, this message translates to:
  /// **'Start chatting with AI Sathi'**
  String get startChattingWithAI;

  /// No description provided for @textChats.
  ///
  /// In en, this message translates to:
  /// **'Text Chats'**
  String get textChats;

  /// No description provided for @voiceCalls.
  ///
  /// In en, this message translates to:
  /// **'Voice Calls'**
  String get voiceCalls;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @ayurvedicDoctors.
  ///
  /// In en, this message translates to:
  /// **'Ayurvedic Doctors'**
  String get ayurvedicDoctors;

  /// No description provided for @ayurvedicVaidya.
  ///
  /// In en, this message translates to:
  /// **'Ayurvedic Vaidya'**
  String get ayurvedicVaidya;

  /// No description provided for @ayurvedicTraditional.
  ///
  /// In en, this message translates to:
  /// **'Ayurvedic / Traditional'**
  String get ayurvedicTraditional;

  /// No description provided for @healthApproach.
  ///
  /// In en, this message translates to:
  /// **'Health Approach'**
  String get healthApproach;

  /// No description provided for @scientificModern.
  ///
  /// In en, this message translates to:
  /// **'Scientific - Modern Medicine'**
  String get scientificModern;

  /// No description provided for @healthAnalyzers.
  ///
  /// In en, this message translates to:
  /// **'Health Analyzers'**
  String get healthAnalyzers;

  /// No description provided for @diseaseSurveillance.
  ///
  /// In en, this message translates to:
  /// **'Disease Surveillance'**
  String get diseaseSurveillance;

  /// No description provided for @weatherAirQuality.
  ///
  /// In en, this message translates to:
  /// **'Weather & Air Quality'**
  String get weatherAirQuality;

  /// No description provided for @detailedMetrics.
  ///
  /// In en, this message translates to:
  /// **'Detailed Metrics'**
  String get detailedMetrics;

  /// No description provided for @deleteReminder.
  ///
  /// In en, this message translates to:
  /// **'Delete Reminder'**
  String get deleteReminder;

  /// No description provided for @reminderActive.
  ///
  /// In en, this message translates to:
  /// **'Reminder Active'**
  String get reminderActive;

  /// No description provided for @cancelAppointment.
  ///
  /// In en, this message translates to:
  /// **'Cancel Appointment'**
  String get cancelAppointment;

  /// No description provided for @endCallQuestion.
  ///
  /// In en, this message translates to:
  /// **'End Call?'**
  String get endCallQuestion;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection Error'**
  String get connectionError;

  /// No description provided for @addEmergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Add Emergency Contact'**
  String get addEmergencyContact;

  /// No description provided for @bodyFatCalculator.
  ///
  /// In en, this message translates to:
  /// **'Body Fat Calculator'**
  String get bodyFatCalculator;

  /// No description provided for @calorieCalculator.
  ///
  /// In en, this message translates to:
  /// **'Calorie Calculator'**
  String get calorieCalculator;

  /// No description provided for @waterIntakeCalculator.
  ///
  /// In en, this message translates to:
  /// **'Water Intake Calculator'**
  String get waterIntakeCalculator;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete?'**
  String get confirmDelete;

  /// No description provided for @cannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get cannotBeUndone;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @conversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get conversations;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @voice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voice;

  /// No description provided for @text.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get text;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @noSurgicalHistory.
  ///
  /// In en, this message translates to:
  /// **'No surgical history recorded'**
  String get noSurgicalHistory;

  /// No description provided for @noVaccinations.
  ///
  /// In en, this message translates to:
  /// **'No vaccinations recorded'**
  String get noVaccinations;

  /// No description provided for @addCondition.
  ///
  /// In en, this message translates to:
  /// **'Add Condition'**
  String get addCondition;

  /// No description provided for @addAllergy.
  ///
  /// In en, this message translates to:
  /// **'Add Allergy'**
  String get addAllergy;

  /// No description provided for @addMedication.
  ///
  /// In en, this message translates to:
  /// **'Add Medication'**
  String get addMedication;

  /// No description provided for @addSurgery.
  ///
  /// In en, this message translates to:
  /// **'Add Surgery'**
  String get addSurgery;

  /// No description provided for @addVaccination.
  ///
  /// In en, this message translates to:
  /// **'Add Vaccination'**
  String get addVaccination;

  /// No description provided for @discussWithAI.
  ///
  /// In en, this message translates to:
  /// **'Discuss with AI'**
  String get discussWithAI;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @allergenRequired.
  ///
  /// In en, this message translates to:
  /// **'Allergen is required'**
  String get allergenRequired;

  /// No description provided for @procedureRequired.
  ///
  /// In en, this message translates to:
  /// **'Procedure name is required'**
  String get procedureRequired;

  /// No description provided for @vaccineRequired.
  ///
  /// In en, this message translates to:
  /// **'Vaccine name is required'**
  String get vaccineRequired;

  /// No description provided for @markTaken.
  ///
  /// In en, this message translates to:
  /// **'Mark Taken'**
  String get markTaken;

  /// No description provided for @reminderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Reminder not found'**
  String get reminderNotFound;

  /// No description provided for @reminderDeleted.
  ///
  /// In en, this message translates to:
  /// **'Reminder deleted'**
  String get reminderDeleted;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @addMedicine.
  ///
  /// In en, this message translates to:
  /// **'Add Medicine'**
  String get addMedicine;

  /// No description provided for @unableToLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load data'**
  String get unableToLoad;

  /// No description provided for @weatherUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Weather data unavailable'**
  String get weatherUnavailable;

  /// No description provided for @airQualityUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Air quality data unavailable'**
  String get airQualityUnavailable;

  /// No description provided for @noMedicinesFound.
  ///
  /// In en, this message translates to:
  /// **'No medicines found'**
  String get noMedicinesFound;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @detectGPS.
  ///
  /// In en, this message translates to:
  /// **'Detect GPS'**
  String get detectGPS;

  /// No description provided for @detecting.
  ///
  /// In en, this message translates to:
  /// **'Detecting...'**
  String get detecting;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @province.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get province;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdated;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @surgicalHistory.
  ///
  /// In en, this message translates to:
  /// **'Surgical History'**
  String get surgicalHistory;

  /// No description provided for @vaccinations.
  ///
  /// In en, this message translates to:
  /// **'Vaccinations'**
  String get vaccinations;

  /// No description provided for @medications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medications;

  /// No description provided for @allergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get allergies;

  /// No description provided for @conditions.
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get conditions;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get past;

  /// No description provided for @noUpcomingAppointments.
  ///
  /// In en, this message translates to:
  /// **'No upcoming appointments'**
  String get noUpcomingAppointments;

  /// No description provided for @noPastAppointments.
  ///
  /// In en, this message translates to:
  /// **'No past appointments'**
  String get noPastAppointments;

  /// No description provided for @bookAnAppointment.
  ///
  /// In en, this message translates to:
  /// **'Book an appointment'**
  String get bookAnAppointment;

  /// No description provided for @bookNew.
  ///
  /// In en, this message translates to:
  /// **'Book New'**
  String get bookNew;

  /// No description provided for @joinNow.
  ///
  /// In en, this message translates to:
  /// **'Join Now'**
  String get joinNow;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancel;

  /// No description provided for @appointmentCancelled.
  ///
  /// In en, this message translates to:
  /// **'Appointment cancelled'**
  String get appointmentCancelled;

  /// No description provided for @orderMedicines.
  ///
  /// In en, this message translates to:
  /// **'Order Medicines'**
  String get orderMedicines;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @aiConsultation.
  ///
  /// In en, this message translates to:
  /// **'AI Consultation'**
  String get aiConsultation;

  /// No description provided for @traditionalMedicine.
  ///
  /// In en, this message translates to:
  /// **'Traditional Medicine'**
  String get traditionalMedicine;

  /// No description provided for @aiHealthAnalysis.
  ///
  /// In en, this message translates to:
  /// **'AI Health Analysis'**
  String get aiHealthAnalysis;

  /// No description provided for @selectAnalysisType.
  ///
  /// In en, this message translates to:
  /// **'Select Analysis Type'**
  String get selectAnalysisType;

  /// No description provided for @labReport.
  ///
  /// In en, this message translates to:
  /// **'Lab Report'**
  String get labReport;

  /// No description provided for @prescription.
  ///
  /// In en, this message translates to:
  /// **'Prescription'**
  String get prescription;

  /// No description provided for @skinCondition.
  ///
  /// In en, this message translates to:
  /// **'Skin Condition'**
  String get skinCondition;

  /// No description provided for @xrayScan.
  ///
  /// In en, this message translates to:
  /// **'X-Ray / Scan'**
  String get xrayScan;

  /// No description provided for @ecgReport.
  ///
  /// In en, this message translates to:
  /// **'ECG Report'**
  String get ecgReport;

  /// No description provided for @generalHealth.
  ///
  /// In en, this message translates to:
  /// **'General Health'**
  String get generalHealth;

  /// No description provided for @google.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark All Read'**
  String get markAllRead;

  /// No description provided for @document.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get document;

  /// No description provided for @uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload Document'**
  String get uploadDocument;

  /// No description provided for @selectDocumentType.
  ///
  /// In en, this message translates to:
  /// **'Select Document Type'**
  String get selectDocumentType;

  /// No description provided for @reminderDetails.
  ///
  /// In en, this message translates to:
  /// **'Reminder Details'**
  String get reminderDetails;

  /// No description provided for @medicineTaken.
  ///
  /// In en, this message translates to:
  /// **'Medicine Taken'**
  String get medicineTaken;

  /// No description provided for @skipDose.
  ///
  /// In en, this message translates to:
  /// **'Skip Dose'**
  String get skipDose;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @relationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get relationship;

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Action'**
  String get confirmAction;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @aiAnalysisDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'AI analysis is for informational purposes only. Always consult a healthcare professional.'**
  String get aiAnalysisDisclaimer;

  /// No description provided for @consultAIPractitioner.
  ///
  /// In en, this message translates to:
  /// **'Consult with AI specialists in ancient healing practices'**
  String get consultAIPractitioner;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @audio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @dateTBD.
  ///
  /// In en, this message translates to:
  /// **'Date TBD'**
  String get dateTBD;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ne'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ne':
      return AppLocalizationsNe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
