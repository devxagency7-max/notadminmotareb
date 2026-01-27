import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Motareb'**
  String get appName;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

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

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @myBookings.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get myBookings;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @verification.
  ///
  /// In en, this message translates to:
  /// **'Account Verification'**
  String get verification;

  /// No description provided for @verificationDetail.
  ///
  /// In en, this message translates to:
  /// **'Verify your account to enjoy all features'**
  String get verificationDetail;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @loginNow.
  ///
  /// In en, this message translates to:
  /// **'Login Now'**
  String get loginNow;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Where do you want to live?'**
  String get searchHint;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @university.
  ///
  /// In en, this message translates to:
  /// **'University'**
  String get university;

  /// No description provided for @youth.
  ///
  /// In en, this message translates to:
  /// **'Youth'**
  String get youth;

  /// No description provided for @girls.
  ///
  /// In en, this message translates to:
  /// **'Girls'**
  String get girls;

  /// No description provided for @bed.
  ///
  /// In en, this message translates to:
  /// **'Bed'**
  String get bed;

  /// No description provided for @room.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get room;

  /// No description provided for @featuredForYou.
  ///
  /// In en, this message translates to:
  /// **'Featured for you ✨'**
  String get featuredForYou;

  /// No description provided for @recentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently added 🆕'**
  String get recentlyAdded;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newLabel;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @noPropertiesFound.
  ///
  /// In en, this message translates to:
  /// **'No properties added yet'**
  String get noPropertiesFound;

  /// No description provided for @noUniversitiesFound.
  ///
  /// In en, this message translates to:
  /// **'No universities associated with available properties'**
  String get noUniversitiesFound;

  /// No description provided for @noCategoryProperties.
  ///
  /// In en, this message translates to:
  /// **'No properties available in this category currently'**
  String get noCategoryProperties;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @techSupport.
  ///
  /// In en, this message translates to:
  /// **'Technical Support'**
  String get techSupport;

  /// No description provided for @available247.
  ///
  /// In en, this message translates to:
  /// **'Available 24/7'**
  String get available247;

  /// No description provided for @jumpToPinned.
  ///
  /// In en, this message translates to:
  /// **'Jump to pinned messages'**
  String get jumpToPinned;

  /// No description provided for @chatWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome 👋\nHow can we help you today?'**
  String get chatWelcome;

  /// No description provided for @pinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinned;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeMessage;

  /// No description provided for @availableApartments.
  ///
  /// In en, this message translates to:
  /// **'Available Apartments'**
  String get availableApartments;

  /// No description provided for @propertiesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} properties available'**
  String propertiesCount(int count);

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading data'**
  String get errorLoadingData;

  /// No description provided for @noPropertiesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No properties available currently'**
  String get noPropertiesAvailable;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @availableNow.
  ///
  /// In en, this message translates to:
  /// **'Available now'**
  String get availableNow;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Logged in successfully!'**
  String get loginSuccess;

  /// No description provided for @googleLoginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully logged in with Google!'**
  String get googleLoginSuccess;

  /// No description provided for @facebookLoginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully logged in with Facebook!'**
  String get facebookLoginSuccess;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @loginToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue searching for your home'**
  String get loginToContinue;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get enterEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get enterPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @loginAction.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginAction;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithFacebook.
  ///
  /// In en, this message translates to:
  /// **'Continue with Facebook'**
  String get continueWithFacebook;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create New Account'**
  String get createAccount;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @intro1Title.
  ///
  /// In en, this message translates to:
  /// **'Your home, safely'**
  String get intro1Title;

  /// No description provided for @intro1Desc.
  ///
  /// In en, this message translates to:
  /// **'Verified and equipped apartments for expats. Book online securely.'**
  String get intro1Desc;

  /// No description provided for @intro2Title.
  ///
  /// In en, this message translates to:
  /// **'See your future home\nwhere you are'**
  String get intro2Title;

  /// No description provided for @intro2Desc.
  ///
  /// In en, this message translates to:
  /// **'360 virtual tours let you see every corner before you book.'**
  String get intro2Desc;

  /// No description provided for @intro3Title.
  ///
  /// In en, this message translates to:
  /// **'Pay comfortably'**
  String get intro3Title;

  /// No description provided for @intro3Desc.
  ///
  /// In en, this message translates to:
  /// **'Secure and multiple payment methods. Start your journey with us now.'**
  String get intro3Desc;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'EGP'**
  String get currency;

  /// No description provided for @features.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// No description provided for @propertyVideo.
  ///
  /// In en, this message translates to:
  /// **'Property Video'**
  String get propertyVideo;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @noNumbersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No numbers available currently'**
  String get noNumbersAvailable;

  /// No description provided for @aboutPlace.
  ///
  /// In en, this message translates to:
  /// **'About the Place'**
  String get aboutPlace;

  /// No description provided for @selectNeed.
  ///
  /// In en, this message translates to:
  /// **'(Select your need)'**
  String get selectNeed;

  /// No description provided for @bookApartmentFull.
  ///
  /// In en, this message translates to:
  /// **'Book full apartment'**
  String get bookApartmentFull;

  /// No description provided for @fullApartmentPrice.
  ///
  /// In en, this message translates to:
  /// **'Full apartment price'**
  String get fullApartmentPrice;

  /// No description provided for @selectUnitsFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select apartment or rooms first'**
  String get selectUnitsFirst;

  /// No description provided for @totalChoices.
  ///
  /// In en, this message translates to:
  /// **'Total choices'**
  String get totalChoices;

  /// No description provided for @apartmentPrice.
  ///
  /// In en, this message translates to:
  /// **'Apartment price'**
  String get apartmentPrice;

  /// No description provided for @bedsSelectionError.
  ///
  /// In en, this message translates to:
  /// **'Please select a unit (full apartment or room/bed) before booking'**
  String get bedsSelectionError;

  /// No description provided for @bookBeds.
  ///
  /// In en, this message translates to:
  /// **'Book Beds'**
  String get bookBeds;

  /// No description provided for @roomType.
  ///
  /// In en, this message translates to:
  /// **'Room Type: {type}'**
  String roomType(String type);

  /// No description provided for @shared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get shared;

  /// No description provided for @requestedBedsCount.
  ///
  /// In en, this message translates to:
  /// **'Number of beds required'**
  String get requestedBedsCount;

  /// No description provided for @remainingBeds.
  ///
  /// In en, this message translates to:
  /// **'{remaining} beds remaining out of {total}'**
  String remainingBeds(int remaining, int total);

  /// No description provided for @includesComponents.
  ///
  /// In en, this message translates to:
  /// **'The apartment includes the following components:'**
  String get includesComponents;

  /// No description provided for @bathrooms.
  ///
  /// In en, this message translates to:
  /// **'Bathrooms'**
  String get bathrooms;

  /// No description provided for @rooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get rooms;

  /// No description provided for @beds.
  ///
  /// In en, this message translates to:
  /// **'Beds'**
  String get beds;

  /// No description provided for @single.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get single;

  /// No description provided for @double.
  ///
  /// In en, this message translates to:
  /// **'Double'**
  String get double;

  /// No description provided for @triple.
  ///
  /// In en, this message translates to:
  /// **'Triple'**
  String get triple;

  /// No description provided for @quadruple.
  ///
  /// In en, this message translates to:
  /// **'Quadruple'**
  String get quadruple;

  /// No description provided for @bedInSharedRoom.
  ///
  /// In en, this message translates to:
  /// **'Bed in shared room'**
  String get bedInSharedRoom;

  /// No description provided for @singleRoom.
  ///
  /// In en, this message translates to:
  /// **'Single room'**
  String get singleRoom;

  /// No description provided for @fullApartment.
  ///
  /// In en, this message translates to:
  /// **'Full apartment'**
  String get fullApartment;

  /// No description provided for @searchFilter.
  ///
  /// In en, this message translates to:
  /// **'Search Filter'**
  String get searchFilter;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @applyFilter.
  ///
  /// In en, this message translates to:
  /// **'Apply Filter'**
  String get applyFilter;

  /// No description provided for @priceRangeMonthly.
  ///
  /// In en, this message translates to:
  /// **'Price Range ({currency}/month)'**
  String priceRangeMonthly(Object currency);

  /// No description provided for @housingType.
  ///
  /// In en, this message translates to:
  /// **'Housing Type'**
  String get housingType;

  /// No description provided for @allowedGender.
  ///
  /// In en, this message translates to:
  /// **'Allowed Gender'**
  String get allowedGender;

  /// No description provided for @males.
  ///
  /// In en, this message translates to:
  /// **'Males'**
  String get males;

  /// No description provided for @females.
  ///
  /// In en, this message translates to:
  /// **'Females'**
  String get females;

  /// No description provided for @smoking.
  ///
  /// In en, this message translates to:
  /// **'Smoking'**
  String get smoking;

  /// No description provided for @allowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get allowed;

  /// No description provided for @forbidden.
  ///
  /// In en, this message translates to:
  /// **'Forbidden'**
  String get forbidden;

  /// No description provided for @bookingRequest.
  ///
  /// In en, this message translates to:
  /// **'Booking Request'**
  String get bookingRequest;

  /// No description provided for @underReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get underReview;

  /// No description provided for @reviewNotice.
  ///
  /// In en, this message translates to:
  /// **'Your request will be reviewed by the agent within 24 hours'**
  String get reviewNotice;

  /// No description provided for @bookingDetails.
  ///
  /// In en, this message translates to:
  /// **'Booking Details'**
  String get bookingDetails;

  /// No description provided for @monthlyPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly Price'**
  String get monthlyPriceLabel;

  /// No description provided for @yourData.
  ///
  /// In en, this message translates to:
  /// **'Your Data'**
  String get yourData;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @stayDuration.
  ///
  /// In en, this message translates to:
  /// **'Stay Duration'**
  String get stayDuration;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @totalDuration.
  ///
  /// In en, this message translates to:
  /// **'Total Duration: {duration}'**
  String totalDuration(String duration);

  /// No description provided for @identityVerification.
  ///
  /// In en, this message translates to:
  /// **'Identity Verification'**
  String get identityVerification;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @dataProtectedNotice.
  ///
  /// In en, this message translates to:
  /// **'Your data is protected and will not be shared with any third party'**
  String get dataProtectedNotice;

  /// No description provided for @fullNameInId.
  ///
  /// In en, this message translates to:
  /// **'Full Name (as in Identity)'**
  String get fullNameInId;

  /// No description provided for @nationalIdNumber.
  ///
  /// In en, this message translates to:
  /// **'National ID Number'**
  String get nationalIdNumber;

  /// No description provided for @uploadIdPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload ID Photo'**
  String get uploadIdPhoto;

  /// No description provided for @idFrontFace.
  ///
  /// In en, this message translates to:
  /// **'ID Front Face'**
  String get idFrontFace;

  /// No description provided for @idBackFace.
  ///
  /// In en, this message translates to:
  /// **'ID Back Face'**
  String get idBackFace;

  /// No description provided for @additionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Additional Notes'**
  String get additionalNotes;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Write any notes or special requirements...'**
  String get notesHint;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get fullNameHint;

  /// No description provided for @idNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your ID number'**
  String get idNumberHint;

  /// No description provided for @howBookingWorks.
  ///
  /// In en, this message translates to:
  /// **'How does the booking process work?'**
  String get howBookingWorks;

  /// No description provided for @bookingStep1.
  ///
  /// In en, this message translates to:
  /// **'Your request is sent to the approved agent'**
  String get bookingStep1;

  /// No description provided for @bookingStep2.
  ///
  /// In en, this message translates to:
  /// **'The agent will review your request within 24 hours'**
  String get bookingStep2;

  /// No description provided for @bookingStep3.
  ///
  /// In en, this message translates to:
  /// **'Upon approval, you will be able to complete payment'**
  String get bookingStep3;

  /// No description provided for @submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submitRequest;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @requestSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Request sent successfully'**
  String get requestSentSuccess;

  /// No description provided for @pickPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Pick from gallery or take a photo'**
  String get pickPhotoHint;

  /// No description provided for @singleFurnishedRoom.
  ///
  /// In en, this message translates to:
  /// **'Single Furnished Room'**
  String get singleFurnishedRoom;

  /// No description provided for @riyadhAlNakheel.
  ///
  /// In en, this message translates to:
  /// **'Riyadh - Al Nakheel'**
  String get riyadhAlNakheel;

  /// No description provided for @ahmedMohamed.
  ///
  /// In en, this message translates to:
  /// **'Ahmed Mohamed'**
  String get ahmedMohamed;

  /// No description provided for @examplePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'0501234567'**
  String get examplePhoneNumber;

  /// No description provided for @exampleEmail.
  ///
  /// In en, this message translates to:
  /// **'ahmed@email.com'**
  String get exampleEmail;

  /// No description provided for @february2026.
  ///
  /// In en, this message translates to:
  /// **'1 February 2026'**
  String get february2026;

  /// No description provided for @june2026.
  ///
  /// In en, this message translates to:
  /// **'1 June 2026'**
  String get june2026;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get months;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
