import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Mechanic Connect'**
  String get appTitle;

  /// No description provided for @splashTitle.
  ///
  /// In en, this message translates to:
  /// **'Madad Car'**
  String get splashTitle;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'SENTINEL OF THE ROAD'**
  String get splashTagline;

  /// No description provided for @splashPoweredBy.
  ///
  /// In en, this message translates to:
  /// **'POWERED BY'**
  String get splashPoweredBy;

  /// No description provided for @splashPoweredByBrand.
  ///
  /// In en, this message translates to:
  /// **'SafeRoad'**
  String get splashPoweredByBrand;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginWelcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to your account for quick access to help.'**
  String get loginSubtitle;

  /// No description provided for @loginBrand.
  ///
  /// In en, this message translates to:
  /// **'MADAD CAR'**
  String get loginBrand;

  /// No description provided for @loginHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get loginHelp;

  /// No description provided for @loginUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get loginUsernameHint;

  /// No description provided for @loginEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get loginEmailHint;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordHint;

  /// No description provided for @loginUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter email address to continue.'**
  String get loginUsernameRequired;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get loginForgotPassword;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @loginSecureAccess.
  ///
  /// In en, this message translates to:
  /// **'SECURE ACCESS'**
  String get loginSecureAccess;

  /// No description provided for @loginBiometric.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get loginBiometric;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get loginNoAccount;

  /// No description provided for @loginSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get loginSignUp;

  /// No description provided for @loginFeatureSoon.
  ///
  /// In en, this message translates to:
  /// **'This feature will be available soon.'**
  String get loginFeatureSoon;

  /// No description provided for @forgotPasswordAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Roadside Assistance'**
  String get forgotPasswordAppBarTitle;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered email and we\'ll send you instructions to reset your password.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'EMAIL ADDRESS'**
  String get forgotPasswordEmailLabel;

  /// No description provided for @forgotPasswordEmailHint.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get forgotPasswordEmailHint;

  /// No description provided for @forgotPasswordEmailNote.
  ///
  /// In en, this message translates to:
  /// **'We\'ll verify this email is linked to an account.'**
  String get forgotPasswordEmailNote;

  /// No description provided for @forgotPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get forgotPasswordButton;

  /// No description provided for @forgotPasswordRemember.
  ///
  /// In en, this message translates to:
  /// **'Remembered your password?'**
  String get forgotPasswordRemember;

  /// No description provided for @forgotPasswordLoginHere.
  ///
  /// In en, this message translates to:
  /// **'Log in here'**
  String get forgotPasswordLoginHere;

  /// No description provided for @forgotPasswordEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your registered email address.'**
  String get forgotPasswordEmailRequired;

  /// No description provided for @forgotPasswordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent. Please check your email.'**
  String get forgotPasswordResetSent;

  /// No description provided for @createAccountBrand.
  ///
  /// In en, this message translates to:
  /// **'Madad Car'**
  String get createAccountBrand;

  /// No description provided for @createAccountIdentityTab.
  ///
  /// In en, this message translates to:
  /// **'IDENTITY'**
  String get createAccountIdentityTab;

  /// No description provided for @createAccountVehicleTab.
  ///
  /// In en, this message translates to:
  /// **'VEHICLE'**
  String get createAccountVehicleTab;

  /// No description provided for @createAccountReviewTab.
  ///
  /// In en, this message translates to:
  /// **'REVIEW'**
  String get createAccountReviewTab;

  /// No description provided for @createAccountPasswordTab.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD'**
  String get createAccountPasswordTab;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountTitle;

  /// No description provided for @createAccountVehicleTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Your Vehicle'**
  String get createAccountVehicleTitle;

  /// No description provided for @createAccountReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s verify your identity & vehicle.'**
  String get createAccountReviewTitle;

  /// No description provided for @createAccountPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure Your Account'**
  String get createAccountPasswordTitle;

  /// No description provided for @createAccountIdentitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join Madad Car for reliable roadside support. We keep you moving when the road gets tough.'**
  String get createAccountIdentitySubtitle;

  /// No description provided for @createAccountVehicleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add accurate vehicle details for faster support and secure verification.'**
  String get createAccountVehicleSubtitle;

  /// No description provided for @createAccountReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please ensure all details match your official documents before continuing.'**
  String get createAccountReviewSubtitle;

  /// No description provided for @createAccountPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a strong password for your profile.'**
  String get createAccountPasswordSubtitle;

  /// No description provided for @createAccountContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get createAccountContinueButton;

  /// No description provided for @createAccountCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountCreateButton;

  /// No description provided for @createAccountDone.
  ///
  /// In en, this message translates to:
  /// **'Account flow completed successfully.'**
  String get createAccountDone;

  /// No description provided for @createAccountFullName.
  ///
  /// In en, this message translates to:
  /// **'FULL NAME'**
  String get createAccountFullName;

  /// No description provided for @createAccountFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get createAccountFullNameHint;

  /// No description provided for @createAccountEmail.
  ///
  /// In en, this message translates to:
  /// **'EMAIL ADDRESS'**
  String get createAccountEmail;

  /// No description provided for @createAccountEmailHint.
  ///
  /// In en, this message translates to:
  /// **'john@example.com'**
  String get createAccountEmailHint;

  /// No description provided for @createAccountIdentityNote.
  ///
  /// In en, this message translates to:
  /// **'Your information is encrypted and never shared. We use your email for service updates and SOS confirmations.'**
  String get createAccountIdentityNote;

  /// No description provided for @createAccountVehicleType.
  ///
  /// In en, this message translates to:
  /// **'VEHICLE TYPE'**
  String get createAccountVehicleType;

  /// No description provided for @createAccountVehicleTypeCar.
  ///
  /// In en, this message translates to:
  /// **'CAR'**
  String get createAccountVehicleTypeCar;

  /// No description provided for @createAccountVehicleTypeBike.
  ///
  /// In en, this message translates to:
  /// **'BIKE'**
  String get createAccountVehicleTypeBike;

  /// No description provided for @createAccountVehicleTypeVan.
  ///
  /// In en, this message translates to:
  /// **'VAN'**
  String get createAccountVehicleTypeVan;

  /// No description provided for @createAccountVehicleMake.
  ///
  /// In en, this message translates to:
  /// **'VEHICLE MAKE'**
  String get createAccountVehicleMake;

  /// No description provided for @createAccountVehicleMakeHint.
  ///
  /// In en, this message translates to:
  /// **'Select Make'**
  String get createAccountVehicleMakeHint;

  /// No description provided for @createAccountVehicleModel.
  ///
  /// In en, this message translates to:
  /// **'VEHICLE MODEL'**
  String get createAccountVehicleModel;

  /// No description provided for @createAccountVehicleModelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Corolla'**
  String get createAccountVehicleModelHint;

  /// No description provided for @createAccountVehicleNumber.
  ///
  /// In en, this message translates to:
  /// **'REGISTRATION NUMBER'**
  String get createAccountVehicleNumber;

  /// No description provided for @createAccountVehicleNumberHint.
  ///
  /// In en, this message translates to:
  /// **'ABC-1234'**
  String get createAccountVehicleNumberHint;

  /// No description provided for @createAccountVehicleColor.
  ///
  /// In en, this message translates to:
  /// **'VEHICLE COLOR'**
  String get createAccountVehicleColor;

  /// No description provided for @createAccountVehicleColorHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. White'**
  String get createAccountVehicleColorHint;

  /// No description provided for @createAccountVehicleYear.
  ///
  /// In en, this message translates to:
  /// **'VEHICLE YEAR'**
  String get createAccountVehicleYear;

  /// No description provided for @createAccountVehicleYearHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2022'**
  String get createAccountVehicleYearHint;

  /// No description provided for @createAccountVehicleManufacturer.
  ///
  /// In en, this message translates to:
  /// **'VEHICLE MANUFACTURER'**
  String get createAccountVehicleManufacturer;

  /// No description provided for @createAccountVehicleManufacturerHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Toyota Motors'**
  String get createAccountVehicleManufacturerHint;

  /// No description provided for @createAccountReviewIdentitySection.
  ///
  /// In en, this message translates to:
  /// **'USER PROFILE'**
  String get createAccountReviewIdentitySection;

  /// No description provided for @createAccountReviewVehicleSection.
  ///
  /// In en, this message translates to:
  /// **'VEHICLE DETAILS'**
  String get createAccountReviewVehicleSection;

  /// No description provided for @createAccountPasswordField.
  ///
  /// In en, this message translates to:
  /// **'CREATE PASSWORD'**
  String get createAccountPasswordField;

  /// No description provided for @createAccountPasswordFieldHint.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get createAccountPasswordFieldHint;

  /// No description provided for @createAccountConfirmPasswordField.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM PASSWORD'**
  String get createAccountConfirmPasswordField;

  /// No description provided for @createAccountPasswordRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Complex Characters'**
  String get createAccountPasswordRuleTitle;

  /// No description provided for @createAccountPasswordRuleBody.
  ///
  /// In en, this message translates to:
  /// **'Include a mix of symbols, numbers, and cases.'**
  String get createAccountPasswordRuleBody;

  /// No description provided for @createAccountPasswordSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety Lock'**
  String get createAccountPasswordSafetyTitle;

  /// No description provided for @createAccountPasswordSafetyBody.
  ///
  /// In en, this message translates to:
  /// **'We use AES-256 encryption to protect your data.'**
  String get createAccountPasswordSafetyBody;

  /// No description provided for @createAccountIdentityRequired.
  ///
  /// In en, this message translates to:
  /// **'Please complete full name and email first.'**
  String get createAccountIdentityRequired;

  /// No description provided for @createAccountVehicleRequired.
  ///
  /// In en, this message translates to:
  /// **'Please complete all vehicle details first.'**
  String get createAccountVehicleRequired;

  /// No description provided for @createAccountPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get createAccountPasswordTooShort;

  /// No description provided for @createAccountPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Password and confirm password do not match.'**
  String get createAccountPasswordMismatch;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get authInvalidEmail;

  /// No description provided for @authUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found for this email.'**
  String get authUserNotFound;

  /// No description provided for @authWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get authWrongPassword;

  /// No description provided for @authTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get authTooManyRequests;

  /// No description provided for @authEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get authEmailAlreadyInUse;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak.'**
  String get authWeakPassword;

  /// No description provided for @authNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your internet.'**
  String get authNetworkError;

  /// No description provided for @authFirebaseConfigMissing.
  ///
  /// In en, this message translates to:
  /// **'Firebase Android config missing. Add SHA-1/SHA-256 in Firebase app settings and download new google-services.json.'**
  String get authFirebaseConfigMissing;

  /// No description provided for @authFirestoreDisabled.
  ///
  /// In en, this message translates to:
  /// **'Cloud Firestore is disabled for this Firebase project. Enable Firestore API and retry.'**
  String get authFirestoreDisabled;

  /// No description provided for @authProfileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save profile details. Please try again.'**
  String get authProfileSaveFailed;

  /// No description provided for @authGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authGenericError;

  /// No description provided for @loginContinueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get loginContinueAsGuest;

  /// No description provided for @loginContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get loginContinueWith;

  /// No description provided for @introBrand.
  ///
  /// In en, this message translates to:
  /// **'MADAD CAR'**
  String get introBrand;

  /// No description provided for @introSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get introSkip;

  /// No description provided for @switchToEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get switchToEnglish;

  /// No description provided for @switchToUrdu.
  ///
  /// In en, this message translates to:
  /// **'اردو'**
  String get switchToUrdu;

  /// No description provided for @introWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Madad Car'**
  String get introWelcome;

  /// No description provided for @introWelcomeSupporting.
  ///
  /// In en, this message translates to:
  /// **'Smart roadside support, exactly when you need it.'**
  String get introWelcomeSupporting;

  /// No description provided for @introLogoTagline.
  ///
  /// In en, this message translates to:
  /// **'HELP IS COMING'**
  String get introLogoTagline;

  /// No description provided for @introHeading.
  ///
  /// In en, this message translates to:
  /// **'Help is Just a Tap Away'**
  String get introHeading;

  /// No description provided for @introDescription.
  ///
  /// In en, this message translates to:
  /// **'Quick and reliable roadside assistance for your car or bike across Pakistan.'**
  String get introDescription;

  /// No description provided for @introGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get introGetStarted;

  /// No description provided for @homeDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get homeDashboardTitle;

  /// No description provided for @homeDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track requests and access quick actions.'**
  String get homeDashboardSubtitle;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get homeSearchHint;

  /// No description provided for @homeActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get homeActionsTitle;

  /// No description provided for @homeQuickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get homeQuickActionsTitle;

  /// No description provided for @homePrimaryAction.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get homePrimaryAction;

  /// No description provided for @homeSecondaryAction.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get homeSecondaryAction;

  /// No description provided for @homeInvertedAction.
  ///
  /// In en, this message translates to:
  /// **'Inverted'**
  String get homeInvertedAction;

  /// No description provided for @homeOutlinedAction.
  ///
  /// In en, this message translates to:
  /// **'Outlined'**
  String get homeOutlinedAction;

  /// No description provided for @homeComingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get homeComingSoonTitle;

  /// No description provided for @homeComingSoonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your main dashboard is on the way.'**
  String get homeComingSoonSubtitle;

  /// No description provided for @homeLogoutButton.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get homeLogoutButton;

  /// No description provided for @homeLoggingOut.
  ///
  /// In en, this message translates to:
  /// **'Logging out...'**
  String get homeLoggingOut;

  /// No description provided for @homeLogoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to log out right now. Please try again.'**
  String get homeLogoutFailed;

  /// No description provided for @homeCurrentLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'CURRENT LOCATION'**
  String get homeCurrentLocationLabel;

  /// No description provided for @homeCurrentLocationValue.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get homeCurrentLocationValue;

  /// No description provided for @homeCurrentLocationFallback.
  ///
  /// In en, this message translates to:
  /// **'Current location unavailable'**
  String get homeCurrentLocationFallback;

  /// No description provided for @homeBrandTitle.
  ///
  /// In en, this message translates to:
  /// **'Madad Car'**
  String get homeBrandTitle;

  /// No description provided for @homePatrolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Patrols Nearby'**
  String get homePatrolsTitle;

  /// No description provided for @homePatrolsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'12 Madad Cars Active'**
  String get homePatrolsSubtitle;

  /// No description provided for @homeExpandMap.
  ///
  /// In en, this message translates to:
  /// **'Expand Map'**
  String get homeExpandMap;

  /// No description provided for @homeEmergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Roadside Assistance'**
  String get homeEmergencyTitle;

  /// No description provided for @homeEmergencySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Immediate help for accidents, fuel loss, or mechanical failure.'**
  String get homeEmergencySubtitle;

  /// No description provided for @homeRequestSos.
  ///
  /// In en, this message translates to:
  /// **'REQUEST SOS'**
  String get homeRequestSos;

  /// No description provided for @homeServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Our Services'**
  String get homeServicesTitle;

  /// No description provided for @homeServiceMechanic.
  ///
  /// In en, this message translates to:
  /// **'Mechanic'**
  String get homeServiceMechanic;

  /// No description provided for @homeServicePuncture.
  ///
  /// In en, this message translates to:
  /// **'Puncture Shop'**
  String get homeServicePuncture;

  /// No description provided for @homeServiceBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery Jumpstart'**
  String get homeServiceBattery;

  /// No description provided for @homeServiceTowing.
  ///
  /// In en, this message translates to:
  /// **'Towing'**
  String get homeServiceTowing;

  /// No description provided for @homeServiceFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel Delivery'**
  String get homeServiceFuel;

  /// No description provided for @homeServiceAccident.
  ///
  /// In en, this message translates to:
  /// **'Accident Recovery'**
  String get homeServiceAccident;

  /// No description provided for @homeNearbyMechanicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby Mechanics'**
  String get homeNearbyMechanicsTitle;

  /// No description provided for @homeSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get homeSortLabel;

  /// No description provided for @homeSortByDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get homeSortByDistance;

  /// No description provided for @homeSortByRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get homeSortByRating;

  /// No description provided for @homeSortByName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get homeSortByName;

  /// No description provided for @homeMechanicAwan.
  ///
  /// In en, this message translates to:
  /// **'Awan Auto'**
  String get homeMechanicAwan;

  /// No description provided for @homeMechanicArfan.
  ///
  /// In en, this message translates to:
  /// **'Arfan Auto'**
  String get homeMechanicArfan;

  /// No description provided for @homeMechanicEhsan.
  ///
  /// In en, this message translates to:
  /// **'Ehsan Auto'**
  String get homeMechanicEhsan;

  /// No description provided for @homeMechanicPakistan.
  ///
  /// In en, this message translates to:
  /// **'Pakistan Auto'**
  String get homeMechanicPakistan;

  /// No description provided for @homeMechanicAwami.
  ///
  /// In en, this message translates to:
  /// **'Awami Auto'**
  String get homeMechanicAwami;

  /// No description provided for @homeTabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTabHome;

  /// No description provided for @homeTabRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get homeTabRequests;

  /// No description provided for @homeTabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get homeTabHistory;

  /// No description provided for @homeTabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get homeTabProfile;

  /// No description provided for @homeRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get homeRequestsTitle;

  /// No description provided for @homeRequestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open your emergency request in one tap.'**
  String get homeRequestsSubtitle;

  /// No description provided for @homeRequestEmergencyNow.
  ///
  /// In en, this message translates to:
  /// **'Need Emergency Assistance?'**
  String get homeRequestEmergencyNow;

  /// No description provided for @homeSosRequestOpened.
  ///
  /// In en, this message translates to:
  /// **'SOS request opened successfully.'**
  String get homeSosRequestOpened;

  /// No description provided for @homeHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get homeHistoryTitle;

  /// No description provided for @homeHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'No request history available yet.'**
  String get homeHistorySubtitle;

  /// No description provided for @homeProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get homeProfileTitle;

  /// No description provided for @homeProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your account preferences.'**
  String get homeProfileSubtitle;

  /// No description provided for @homeMapScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get homeMapScreenTitle;

  /// No description provided for @homeOpenMapButton.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get homeOpenMapButton;

  /// No description provided for @homeOpenMapFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open maps right now.'**
  String get homeOpenMapFailed;

  /// No description provided for @homeMapLoading.
  ///
  /// In en, this message translates to:
  /// **'Fetching live location...'**
  String get homeMapLoading;

  /// No description provided for @homeMapPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Location permission is needed to show your live map.'**
  String get homeMapPermissionNeeded;

  /// No description provided for @homeMapRetry.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get homeMapRetry;

  /// No description provided for @homeMapLiveMarkerTitle.
  ///
  /// In en, this message translates to:
  /// **'You are here'**
  String get homeMapLiveMarkerTitle;

  /// No description provided for @homeMenuProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get homeMenuProfile;

  /// No description provided for @homeMenuLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get homeMenuLanguage;

  /// No description provided for @homeMenuContactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get homeMenuContactUs;

  /// No description provided for @homeMenuSetting.
  ///
  /// In en, this message translates to:
  /// **'Setting'**
  String get homeMenuSetting;

  /// No description provided for @homeMenuLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get homeMenuLogout;

  /// No description provided for @homeContactUsSoon.
  ///
  /// In en, this message translates to:
  /// **'Contact Us will be available soon.'**
  String get homeContactUsSoon;

  /// No description provided for @homeSettingsSoon.
  ///
  /// In en, this message translates to:
  /// **'Settings will be available soon.'**
  String get homeSettingsSoon;

  /// No description provided for @homeRequestsStatusSent.
  ///
  /// In en, this message translates to:
  /// **'REQUEST SENT'**
  String get homeRequestsStatusSent;

  /// No description provided for @homeRequestsStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'ACCEPTED'**
  String get homeRequestsStatusAccepted;

  /// No description provided for @homeRequestsStatusOnWay.
  ///
  /// In en, this message translates to:
  /// **'ON THE WAY'**
  String get homeRequestsStatusOnWay;

  /// No description provided for @homeRequestsStatusArrived.
  ///
  /// In en, this message translates to:
  /// **'ARRIVED'**
  String get homeRequestsStatusArrived;

  /// No description provided for @homeRequestsLiveUpdate.
  ///
  /// In en, this message translates to:
  /// **'LIVE UPDATE'**
  String get homeRequestsLiveUpdate;

  /// No description provided for @homeRequestsTapMarkerHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a mechanic marker'**
  String get homeRequestsTapMarkerHint;

  /// No description provided for @homeRequestsPendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Waiting for mechanic acceptance'**
  String get homeRequestsPendingStatus;

  /// No description provided for @homeRequestsCancelWarning.
  ///
  /// In en, this message translates to:
  /// **'Canceling this request will result in a 500 deduction.'**
  String get homeRequestsCancelWarning;

  /// No description provided for @homeRequestsCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get homeRequestsCancelRequest;

  /// No description provided for @homeRequestsKeepRequest.
  ///
  /// In en, this message translates to:
  /// **'Keep Request'**
  String get homeRequestsKeepRequest;

  /// No description provided for @homeRequestsConfirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel Anyway'**
  String get homeRequestsConfirmCancel;

  /// No description provided for @homeRequestsMechanicWarning.
  ///
  /// In en, this message translates to:
  /// **'Stay with your vehicle and keep your hazard lights on for better visibility.'**
  String get homeRequestsMechanicWarning;

  /// No description provided for @homeRequestsCallMechanic.
  ///
  /// In en, this message translates to:
  /// **'Call Mechanic'**
  String get homeRequestsCallMechanic;

  /// No description provided for @homeRequestsCallFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open dialer right now.'**
  String get homeRequestsCallFailed;

  /// No description provided for @homeRequestsArrivingIn.
  ///
  /// In en, this message translates to:
  /// **'Arriving in {minutes} mins'**
  String homeRequestsArrivingIn(int minutes);

  /// No description provided for @requestDetailsAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Madad Car Rescue'**
  String get requestDetailsAppTitle;

  /// No description provided for @requestDetailsUrgentPriority.
  ///
  /// In en, this message translates to:
  /// **'URGENT PRIORITY'**
  String get requestDetailsUrgentPriority;

  /// No description provided for @requestDetailsTitleLineOne.
  ///
  /// In en, this message translates to:
  /// **'Need Help'**
  String get requestDetailsTitleLineOne;

  /// No description provided for @requestDetailsTitleLineTwo.
  ///
  /// In en, this message translates to:
  /// **'Right Now?'**
  String get requestDetailsTitleLineTwo;

  /// No description provided for @requestDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us what\'s wrong. A technician will be dispatched to your GPS location immediately.'**
  String get requestDetailsSubtitle;

  /// No description provided for @requestDetailsSelectVehicle.
  ///
  /// In en, this message translates to:
  /// **'SELECT YOUR VEHICLE'**
  String get requestDetailsSelectVehicle;

  /// No description provided for @requestDetailsVehicleOneName.
  ///
  /// In en, this message translates to:
  /// **'Civic RS'**
  String get requestDetailsVehicleOneName;

  /// No description provided for @requestDetailsVehicleOneMeta.
  ///
  /// In en, this message translates to:
  /// **'BBR-1293 • White'**
  String get requestDetailsVehicleOneMeta;

  /// No description provided for @requestDetailsVehicleTwoName.
  ///
  /// In en, this message translates to:
  /// **'Sportage'**
  String get requestDetailsVehicleTwoName;

  /// No description provided for @requestDetailsVehicleTwoMeta.
  ///
  /// In en, this message translates to:
  /// **'AKL-0042 • Grey'**
  String get requestDetailsVehicleTwoMeta;

  /// No description provided for @requestDetailsPrimaryVehicle.
  ///
  /// In en, this message translates to:
  /// **'PRIMARY VEHICLE'**
  String get requestDetailsPrimaryVehicle;

  /// No description provided for @requestDetailsIssueSection.
  ///
  /// In en, this message translates to:
  /// **'WHAT\'S THE ISSUE?'**
  String get requestDetailsIssueSection;

  /// No description provided for @requestDetailsIssueEngine.
  ///
  /// In en, this message translates to:
  /// **'Engine'**
  String get requestDetailsIssueEngine;

  /// No description provided for @requestDetailsIssueFlatTire.
  ///
  /// In en, this message translates to:
  /// **'Flat Tire'**
  String get requestDetailsIssueFlatTire;

  /// No description provided for @requestDetailsIssueDeadBattery.
  ///
  /// In en, this message translates to:
  /// **'Dead Battery'**
  String get requestDetailsIssueDeadBattery;

  /// No description provided for @requestDetailsIssueOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get requestDetailsIssueOther;

  /// No description provided for @requestDetailsAdditionalNotes.
  ///
  /// In en, this message translates to:
  /// **'ADDITIONAL NOTES'**
  String get requestDetailsAdditionalNotes;

  /// No description provided for @requestDetailsOptional.
  ///
  /// In en, this message translates to:
  /// **'OPTIONAL'**
  String get requestDetailsOptional;

  /// No description provided for @requestDetailsNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us more (e.g., nearest landmark, smoke, strange noises)...'**
  String get requestDetailsNotesHint;

  /// No description provided for @requestDetailsDetectedLocation.
  ///
  /// In en, this message translates to:
  /// **'DETECTED LOCATION'**
  String get requestDetailsDetectedLocation;

  /// No description provided for @requestDetailsSubmit.
  ///
  /// In en, this message translates to:
  /// **'SUBMIT REQUEST'**
  String get requestDetailsSubmit;

  /// No description provided for @requestDetailsSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Request submitted successfully.'**
  String get requestDetailsSubmitted;

  /// No description provided for @contactSubjectLabel.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get contactSubjectLabel;

  /// No description provided for @contactMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get contactMessageLabel;

  /// No description provided for @contactValidation.
  ///
  /// In en, this message translates to:
  /// **'Please fill subject and message.'**
  String get contactValidation;

  /// No description provided for @contactSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Message sent successfully.'**
  String get contactSentSuccess;

  /// No description provided for @contactSendButton.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get contactSendButton;

  /// No description provided for @historyFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get historyFilterAll;

  /// No description provided for @historyFilterRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get historyFilterRequested;

  /// No description provided for @historyFilterAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get historyFilterAccepted;

  /// No description provided for @historyFilterCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get historyFilterCancelled;

  /// No description provided for @historyNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No request history found.'**
  String get historyNoRecords;

  /// No description provided for @commonSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get commonSaving;

  /// No description provided for @profileAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get profileAgeLabel;

  /// No description provided for @profilePhotoUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile Photo URL'**
  String get profilePhotoUrlLabel;

  /// No description provided for @profileCarsSection.
  ///
  /// In en, this message translates to:
  /// **'Car Details'**
  String get profileCarsSection;

  /// No description provided for @profileFleetSection.
  ///
  /// In en, this message translates to:
  /// **'MY FLEET'**
  String get profileFleetSection;

  /// No description provided for @profileCarTitle.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get profileCarTitle;

  /// No description provided for @profileAddCarButton.
  ///
  /// In en, this message translates to:
  /// **'Add another car'**
  String get profileAddCarButton;

  /// No description provided for @profileAddVehicleShort.
  ///
  /// In en, this message translates to:
  /// **'Add Vehicle'**
  String get profileAddVehicleShort;

  /// No description provided for @profileSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get profileSaveButton;

  /// No description provided for @profileSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully.'**
  String get profileSaveSuccess;

  /// No description provided for @profileSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not update profile right now.'**
  String get profileSaveError;

  /// No description provided for @profileContactEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Contact Information'**
  String get profileContactEditTitle;

  /// No description provided for @profileContactSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Contact'**
  String get profileContactSaveButton;

  /// No description provided for @profileImageUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile image updated.'**
  String get profileImageUploadSuccess;

  /// No description provided for @profileImageUploadError.
  ///
  /// In en, this message translates to:
  /// **'Image upload failed. Try again.'**
  String get profileImageUploadError;

  /// No description provided for @profileImageUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading image...'**
  String get profileImageUploading;

  /// No description provided for @profileVehicleEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Vehicle'**
  String get profileVehicleEditTitle;

  /// No description provided for @profileVehicleAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Vehicle'**
  String get profileVehicleAddTitle;

  /// No description provided for @profileVehicleValidation.
  ///
  /// In en, this message translates to:
  /// **'Vehicle model and number are required.'**
  String get profileVehicleValidation;

  /// No description provided for @profileVehicleSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Vehicle'**
  String get profileVehicleSaveButton;

  /// No description provided for @profileMemberType.
  ///
  /// In en, this message translates to:
  /// **'Premium Member'**
  String get profileMemberType;

  /// No description provided for @profileVerified.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED'**
  String get profileVerified;

  /// No description provided for @profileSinceYear.
  ///
  /// In en, this message translates to:
  /// **'SINCE {year}'**
  String profileSinceYear(String year);

  /// No description provided for @profileSafetyScoreTitle.
  ///
  /// In en, this message translates to:
  /// **'SAFETY SCORE'**
  String get profileSafetyScoreTitle;

  /// No description provided for @profileContactSection.
  ///
  /// In en, this message translates to:
  /// **'CONTACT INFORMATION'**
  String get profileContactSection;

  /// No description provided for @profileEditButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get profileEditButton;

  /// No description provided for @profileEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmailLabel;

  /// No description provided for @profilePhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profilePhoneLabel;

  /// No description provided for @profileVehicleEditButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get profileVehicleEditButton;

  /// No description provided for @profileVehicleInsured.
  ///
  /// In en, this message translates to:
  /// **'INSURED'**
  String get profileVehicleInsured;

  /// No description provided for @profileNoVehicles.
  ///
  /// In en, this message translates to:
  /// **'No vehicles added yet.'**
  String get profileNoVehicles;

  /// No description provided for @profileVehicleUnknown.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get profileVehicleUnknown;

  /// No description provided for @profileVehicleUntitled.
  ///
  /// In en, this message translates to:
  /// **'Car Details'**
  String get profileVehicleUntitled;

  /// No description provided for @profileVehicleLabelModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get profileVehicleLabelModel;

  /// No description provided for @profileVehicleLabelManufacturer.
  ///
  /// In en, this message translates to:
  /// **'Manufacturer'**
  String get profileVehicleLabelManufacturer;

  /// No description provided for @profileVehicleLabelColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get profileVehicleLabelColor;

  /// No description provided for @profileVehicleLabelNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get profileVehicleLabelNumber;

  /// No description provided for @profileVehicleLabelType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get profileVehicleLabelType;

  /// No description provided for @profileVehicleLabelYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get profileVehicleLabelYear;

  /// No description provided for @profileNaValue.
  ///
  /// In en, this message translates to:
  /// **'NA'**
  String get profileNaValue;

  /// No description provided for @profilePleaseUpdate.
  ///
  /// In en, this message translates to:
  /// **'Please update'**
  String get profilePleaseUpdate;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ur': return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
