import '../utils/app_info.dart';

class LocalizationService {
  static Map<String, Map<String, String>> get _translations => {
    'en': {
      // Basic UI
      'register': 'Register',
      'documents': 'Documents',
      'english': 'English',
      'greek': 'Greek',
      'yes': 'Yes',
      'no': 'No',
      'save': 'Save',
      'cancel': 'Cancel',
      'continue': 'Continue',
      'submit': 'Submit',
      'edit': 'Edit',
      'delete': 'Delete',
      'add': 'Add',
      'remove': 'Remove',
      'upload': 'Upload',
      'download': 'Download',
      'view': 'View',
      'open': 'Open',
      'close': 'Close',
      'exit': 'Exit',
      'clear': 'Clear',
      'reset': 'Reset',
      'back': 'Back',
      'ok': 'OK',
      'or': 'or',
      'and': 'and',
      'optional': 'optional',
      'required': 'Required',

      // Status
      'pending': 'Pending',
      'processing': 'Processing',
      'complete': 'Complete',
      'incomplete': 'Incomplete',
      'success': 'Success',
      'failed': 'Failed',
      'cancelled': 'Cancelled',
      'error': 'Error',
      'warning': 'Warning',
      'info': 'Info',
      'update': 'Update',

      // Theme and Settings
      'dark': 'Dark',
      'light': 'Light',
      'settings': 'Settings',
      'security': 'Security',
      'update_your_password': 'Update your password',
      'new_password': 'New Password',
      'help': 'Help',
      'refresh': 'Refresh',
      'dismiss': 'Dismiss',
      'change_language': 'Change Language',

      // Navigation and Screens
      'dashboard': 'Dashboard',
      'welcome': 'Welcome',

      'welcome_message': 'Welcome to the Student Document Portal',
      'getting_started': 'Getting Started',

      // Authentication
      'sign_in': 'Sign In',
      'sign_out': 'Sign Out',
      'create_account': 'Create Account',
      'create_new_account': 'Create New Account',
      'login': 'Login',
      'login_to_account': 'Login to Your Account',
      'forgot_password': 'Forgot Password?',
      'reset_password': 'Reset Password',
      'change_password': 'Change Password',
      'remember_me': 'Remember me',
      'confirm_sign_out': 'Confirm Sign Out',
      'sign_out_message': 'Are you sure you want to sign out?',

      // Forms and Validation
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'full_name': 'Full Name',
      'confirm_email': 'Confirm Email',
      'email_hint': 'your@email.com',
      'password_hint': 'At least 6 characters',
      'phone_hint': '+30 123 456 7890',
      'full_name_hint': 'Enter your full name',
      'id_card_hint': 'Enter your ID card number',
      'enter_valid_email': 'Please enter a valid email address',
      'password_too_short': 'Password must be at least 6 characters long',
      'passwords_match': 'Passwords match',
      'passwords_do_not_match': 'Passwords do not match',
      'strong_password': 'Strong password',
      'medium_password': 'Medium password',
      'weak_password': 'Weak password',
      'full_name_required': 'Full name is required',
      'full_name_too_short': 'Full name must be at least 2 characters',
      'confirm_password_required': 'Confirm password is required',
      'confirm_password_hint': 'Re-enter your password',
      'email_required': 'Email is required',
      'invalid_email': 'Please enter a valid email address',
      'password_required': 'Password is required',

      // Registration and User Info
      'student_registration': 'Student Registration',
      'dormitory_registration': 'Dormitory Registration',
      'dormitory_registration_subtitle': 'Register for student housing',
      'register_header': 'Create Your Account',
      'register_subtitle': 'Join us to access all features and services',
      'sign_in_subtitle': 'Enter your credentials to access your account',
      'dont_have_account': 'Don\'t have an account?',
      'already_have_account': 'Already have an account?',
      'must_accept_terms': 'You must accept the terms and conditions',
      'i_accept_the': 'I accept the',
      'accept_terms_and_conditions': 'I accept the Terms and Conditions',
      'terms_and_conditions': 'Terms and Conditions',
      'privacy_policy': 'Privacy Policy',
      'by_creating_account': 'By creating an account, you agree to our',
      'consent_required': 'You must accept the consent declaration',

      // Personal Information
      'personal_information': 'Personal Information',
      'details': 'Details',
      'name': 'Name',
      'family_name': 'Family Name',
      'father_name': 'Father\'s Name',
      'mother_name': 'Mother\'s Name',
      'birth_date': 'Birth Date (dd/mm/yyyy)',
      'birth_place': 'Birth Place',
      'select_birth_date': 'Select your birth date',
      'id_card_number': 'ID Card Number',
      'issuing_authority': 'Issuing Authority',
      'tax_number': 'Tax Number',
      'phone': 'Phone',

      // Academic Information
      'education': 'Education',
      'university': 'University',
      'department': 'Department',
      'year_of_study': 'Year of Study',
      'has_other_degree': 'Has Other Degree',

      // Family Information
      'parents_info': 'Parents Info',
      'parents_address': 'Parents Address',
      'father_job': 'Father\'s Job',
      'mother_job': 'Mother\'s Job',
      'address': 'Address',
      'city': 'City',
      'region': 'Region',
      'postal_code': 'Postal Code',
      'country': 'Country',
      'number': 'Number',

      // Parent/Family Information
      'parent_address': 'Parent Address',
      'parent_city': 'Parent City',
      'parent_region': 'Parent Region',
      'parent_postal': 'Parent Postal Code',
      'parent_country': 'Parent Country',

      // Document specific translations
      'student_photo': 'Student Photo',
      'id_front': 'ID Front',
      'id_back': 'ID Back',
      'passport_photo': 'Passport Photo',
      'medical_certificate': 'Medical Certificate',
      'health_card': 'Health Card',
      'select_all': 'Select All',
      'consent_accepted': 'Consent',
      'select_identity_document': 'Select Identity Document',
      'id_card_front_back': 'ID Card (Front & Back)',
      'passport_document': 'Passport',

      // Documents
      'document_upload': 'Document Upload',
      'attached_documents': 'Documents',
      'upload_documents': 'Upload Documents',
      'upload_documents_subtitle': 'Upload your required documents',
      'save_documents': 'Save Documents',
      'documents_saved': 'Documents saved successfully',
      'file_uploaded': 'File uploaded successfully',
      'file_upload_failed': 'File upload failed',
      'student_photo_required': 'Student photo is required',
      'id_documents_required': 'Both ID front and back photos are required',
      'passport_required': 'Passport photo is required',
      'document_type_required':
          'Please select a document type (ID or Passport)',
      'medical_certificate_required': 'Medical certificate is required',
      'max_file_size': 'Maximum file size',
      'allowed_formats': 'Allowed formats',
      'select_file': 'Select File',
      'drag_drop_files': 'Drag and drop files here or click to select',
      'no_file_selected': 'No file selected',
      'file_too_large': 'File is too large',
      'invalid_file_format': 'Invalid file format',
      'upload_in_progress': 'Upload in progress...',

      // Dashboard
      'overview': 'Overview',
      'documents_uploaded': 'Documents Uploaded',
      'receipts': 'Receipts',
      'profile_completion': 'Profile Completion',
      'days_since_registration': 'Days Since Registration',
      'quick_actions': 'Quick Actions',
      'recent_documents': 'Recent Documents',
      'view_all': 'View All',
      'dashboard_subtitle': '',
      'completed_tasks': 'Completed Tasks',
      'pending_tasks': 'Pending Tasks',
      'no_completed_tasks': 'No completed tasks yet',
      'complete_registration_first': 'Complete your dormitory registration',
      'upload_required_documents': 'Upload your required documents',

      // Settings
      'app_updates': 'App Updates',
      'auto_check_updates': 'Auto-check for updates',
      'auto_check_updates_desc': 'Automatically check for updates daily',
      'appearance': 'Appearance',
      'theme': 'Theme',
      'system': 'System',
      'language': 'Language',
      'app_language': 'App Language',
      'about': 'About',
      'oikad': 'OIKAD',
      'dormitory_registration_system': 'Dormitory Registration System',
      'version': 'Version',

      // Application Status
      'draft': 'Draft',
      'submitted': 'Submitted',
      'under_review': 'Under Review',
      'approved': 'Approved',
      'rejected': 'Rejected',
      'not_started': 'Not Started',

      // Receipts
      'month': 'Month',
      'year': 'Year',
      'all_years': 'All Years',
      'all_months': 'All Months',
      'no_receipts_found': 'No receipts found',
      'uploaded': 'Uploaded',
      'size': 'Size',
      'downloading': 'Downloading...',
      'download_failed': 'Download failed',
      'download_error': 'Download error',
      'download_cancelled': 'Download cancelled',
      'choose_save_location': 'Choose save location',
      'file_saved_to': 'File saved to',
      'web_download_not_supported':
          'Download not supported in web browser. Please use the mobile app or desktop version.',
      'download_options': 'Download Options',
      'choose_download_location': 'Choose where to save the file:',
      'downloads_folder': 'Downloads Folder',
      'choose_location': 'Choose Location',
      'downloads_folder_error': 'Cannot access Downloads folder',
      'app_documents': 'App Documents',
      'documents_folder_error': 'Cannot access Documents folder',

      // Messages
      'registration_complete': 'Registration Complete',
      'registration_submitted': 'Your registration has been submitted.',
      'registration_failed': 'Registration failed',
      'registration_saved_successfully': 'Registration saved successfully',
      'please_login_first': 'Please login first to register',
      'unexpected_error': 'An unexpected error occurred',
      'coming_soon': 'Coming soon!',

      // Email Verification
      'email_verification_required': 'Email Verification Required',
      'email_verification_message':
          'Please check your email and click the verification link to activate your account.',
      'go_to_login': 'Go to Login',
      'continue_to_dashboard': 'Continue to Dashboard',
      'auto_login_after_verification':
          'After verifying your email, you\'ll be automatically logged in.',

      // Social Login
      'sign_in_with_google': 'Sign in with Google',

      // Welcome Screen
      'app_title': 'OIKAD',
      'app_subtitle': 'Dormitory Registration System',
      'browse_as_guest': 'Browse as Guest',
      'guest_mode_info':
          'In guest mode, you can view documents but cannot upload or submit them. Create an account to access all features.',
      'app_version': AppInfo.isInitialized
          ? AppInfo.displayVersion
          : 'Version Unknown',
      'terms_of_service': 'Terms of Service',

      // Update System
      'check_updates': 'Check for Updates',
      'update_available': 'Update Available',
      'no_updates_available': 'No updates available',
      'update_check_failed': 'Failed to check for updates',
      'download_update': 'Download Update',
      'install_update': 'Install Update',
      'update_now': 'Update Now',
      'update_later': 'Later',

      'downloading_update': 'Downloading Update...',
      'update_downloaded': 'Update downloaded successfully',
      'update_failed': 'Update failed',
      'critical_update': 'Critical Update',
      'security_update': 'Security Update',
      'tap_to_check': 'Tap to check for updates',
      'feature_update': 'Feature Update',
      'bug_fixes': 'Bug Fixes',
      'new_features': 'New Features',
      'whats_new': 'What\'s New',
      'current_version': 'Current Version',
      'new_version': 'New Version',
      'download_size': 'Download Size',
      'update_description': 'Update Description',
      'update_required': 'This update is required',
      'restart_required': 'Restart required after update',

      // Links
      'privacy_policy_link':
          'https://www.lawspot.gr/nomikes-plirofories/nomothesia/nomos-4624-2019',
    },
    'el': {
      // Basic UI
      'register': 'Εγγραφή',
      'documents': 'Δικαιολογητικά',
      'english': 'Αγγλικά',
      'greek': 'Ελληνικά',
      'yes': 'Ναι',
      'no': 'Όχι',
      'save': 'Αποθήκευση',
      'cancel': 'Ακύρωση',
      'continue': 'Συνέχεια',
      'submit': 'Υποβολή',
      'edit': 'Επεξεργασία',
      'delete': 'Διαγραφή',
      'add': 'Προσθήκη',
      'remove': 'Αφαίρεση',
      'upload': 'Ανέβασμα',
      'download': 'Λήψη',
      'view': 'Προβολή',
      'open': 'Άνοιγμα',
      'close': 'Κλείσιμο',
      'exit': 'Έξοδος',
      'clear': 'Καθαρισμός',
      'reset': 'Επαναφορά',
      'back': 'Πίσω',
      'ok': 'OK',
      'or': 'ή',
      'and': 'και',
      'optional': 'προαιρετικό',
      'required': 'Υποχρεωτικό',

      // Status
      'pending': 'Εκκρεμεί',
      'processing': 'Επεξεργασία',
      'complete': 'Ολοκληρωμένο',
      'incomplete': 'Ημιτελές',
      'success': 'Επιτυχία',
      'failed': 'Απέτυχε',
      'cancelled': 'Ακυρώθηκε',
      'error': 'Σφάλμα',
      'warning': 'Προειδοποίηση',
      'info': 'Πληροφορίες',
      'update': 'Ενημέρωση',

      // Theme and Settings
      'dark': 'Σκοτεινό',
      'light': 'Φωτεινό',
      'settings': 'Ρυθμίσεις',
      'security': 'Ασφάλεια',
      'update_your_password': 'Ενημερώστε τον κωδικό σας',
      'new_password': 'Νέος Κωδικός',
      'help': 'Βοήθεια',
      'refresh': 'Ανανέωση',
      'dismiss': 'Απόρριψη',
      'change_language': 'Αλλαγή Γλώσσας',

      // Navigation and Screens
      'dashboard': 'Πίνακας Ελέγχου',
      'welcome': 'Καλώς ήρθατε',

      'welcome_message': 'Καλώς ήρθατε στην Πύλη Δικαιολογητικών Φοιτητών',
      'getting_started': 'Ξεκινώντας',

      // Authentication
      'sign_in': 'Σύνδεση',
      'sign_out': 'Αποσύνδεση',
      'create_account': 'Δημιουργία Λογαριασμού',
      'create_new_account': 'Δημιουργία Νέου Λογαριασμού',
      'login': 'Σύνδεση',
      'login_to_account': 'Σύνδεση στον Λογαριασμό σας',
      'forgot_password': 'Ξεχάσατε τον κωδικό;',
      'reset_password': 'Επαναφορά Κωδικού',
      'change_password': 'Αλλαγή Κωδικού',
      'remember_me': 'Να με θυμάσαι',
      'confirm_sign_out': 'Επιβεβαίωση Αποσύνδεσης',
      'sign_out_message': 'Είστε σίγουροι ότι θέλετε να αποσυνδεθείτε;',

      // Forms and Validation
      'email': 'Email',
      'password': 'Κωδικός Πρόσβασης',
      'confirm_password': 'Επιβεβαίωση Κωδικού',
      'full_name': 'Πλήρες Όνομα',
      'confirm_email': 'Επιβεβαίωση Email',
      'email_hint': 'το@email.σας',
      'password_hint': 'Τουλάχιστον 6 χαρακτήρες',
      'phone_hint': '+30 123 456 7890',
      'full_name_hint': 'Εισάγετε το πλήρες όνομά σας',
      'id_card_hint': 'Εισάγετε τον αριθμό δελτίου ταυτότητας',
      'enter_valid_email': 'Παρακαλώ εισάγετε μια έγκυρη διεύθυνση email',
      'password_too_short': 'Ο κωδικός πρέπει να έχει τουλάχιστον 6 χαρακτήρες',
      'passwords_match': 'Οι κωδικοί ταιριάζουν',
      'passwords_do_not_match': 'Οι κωδικοί δεν ταιριάζουν',
      'strong_password': 'Ισχυρός κωδικός',
      'medium_password': 'Μέτριος κωδικός',
      'weak_password': 'Αδύναμος κωδικός',
      'full_name_required': 'Το πλήρες όνομα είναι υποχρεωτικό',
      'full_name_too_short':
          'Το πλήρες όνομα πρέπει να έχει τουλάχιστον 2 χαρακτήρες',
      'confirm_password_required': 'Η επιβεβαίωση κωδικού είναι υποχρεωτική',
      'confirm_password_hint': 'Εισάγετε ξανά τον κωδικό σας',
      'email_required': 'Το email είναι υποχρεωτικό',
      'invalid_email': 'Παρακαλώ εισάγετε μια έγκυρη διεύθυνση email',
      'password_required': 'Ο κωδικός πρόσβασης είναι υποχρεωτικός',

      // Registration and User Info
      'student_registration': 'Εγγραφή Φοιτητή',
      'dormitory_registration': 'Εγγραφή Οικοτροφείου',
      'dormitory_registration_subtitle': 'Εγγραφή για φοιτητική στέγαση',
      'register_header': 'Δημιουργήστε τον Λογαριασμό σας',
      'register_subtitle': 'Γίνετε μέλος για πρόσβαση σε όλες τις λειτουργίες',
      'sign_in_subtitle': 'Εισάγετε τα διαπιστευτήριά σας για πρόσβαση',
      'dont_have_account': 'Δεν έχετε λογαριασμό;',
      'already_have_account': 'Έχετε ήδη λογαριασμό;',
      'must_accept_terms': 'Πρέπει να αποδεχτείτε τους όρους και προϋποθέσεις',
      'i_accept_the': 'Αποδέχομαι τους',
      'accept_terms_and_conditions': 'Αποδέχομαι τους Όρους και Προϋποθέσεις',
      'terms_and_conditions': 'Όρους και Προϋποθέσεις',
      'privacy_policy': 'Πολιτική Απορρήτου',
      'by_creating_account': 'Δημιουργώντας λογαριασμό, συμφωνείτε με τους',
      'consent_required': 'Πρέπει να αποδεχτείτε τη δήλωση συναίνεσης',

      // Personal Information
      'personal_information': 'Προσωπικά Στοιχεία',
      'details': 'Στοιχεία',
      'name': 'Όνομα',
      'family_name': 'Επώνυμο',
      'father_name': 'Όνομα Πατέρα',
      'mother_name': 'Όνομα Μητέρας',
      'birth_date': 'Ημερομηνία Γέννησης (ηη/μμ/εεεε)',
      'birth_place': 'Τόπος Γέννησης',
      'select_birth_date': 'Επιλέξτε ημερομηνία γέννησης',
      'id_card_number': 'Αριθμός Δελτίου Ταυτότητας',
      'issuing_authority': 'Εκδούσα Αρχή',
      'tax_number': 'ΑΦΜ',
      'phone': 'Τηλέφωνο',

      // Academic Information
      'education': 'Εκπαίδευση',
      'university': 'Πανεπιστήμιο',
      'department': 'Τμήμα',
      'year_of_study': 'Έτος Σπουδών',
      'has_other_degree': 'Έχει Άλλο Πτυχίο',

      // Family Information
      'parents_info': 'Στοιχεία Γονέων',
      'parents_address': 'Διεύθυνση Γονέων',
      'father_job': 'Επάγγελμα Πατέρα',
      'mother_job': 'Επάγγελμα Μητέρας',
      'address': 'Διεύθυνση',
      'city': 'Πόλη',
      'region': 'Περιφέρεια',
      'postal_code': 'Ταχυδρομικός Κώδικας',
      'country': 'Χώρα',
      'number': 'Αριθμός',

      // Parent/Family Information
      'parent_address': 'Διεύθυνση Γονέων',
      'parent_city': 'Πόλη Γονέων',
      'parent_region': 'Περιφέρεια Γονέων',
      'parent_postal': 'Ταχυδρομικός Κώδικας Γονέων',
      'parent_country': 'Χώρα Γονέων',

      // Document specific translations
      'student_photo': 'Φωτογραφία Φοιτητή',
      'id_front': 'Μπροστινή Πλευρά Ταυτότητας',
      'id_back': 'Πίσω Πλευρά Ταυτότητας',
      'passport_photo': 'Φωτογραφία Διαβατηρίου',
      'medical_certificate': 'Ιατρικό Πιστοποιητικό',
      'health_card': 'Κάρτα Υγείας',
      'select_all': 'Επιλογή Όλων',
      'consent_accepted': 'Συγκατάθεση',
      'select_identity_document': 'Επιλέξτε Έγγραφο Ταυτότητας',
      'id_card_front_back': 'Δελτίο Ταυτότητας (Μπροστά & Πίσω)',
      'passport_document': 'Διαβατήριο',

      // Documents
      'document_upload': 'Ανέβασμα Δικαιολογητικών',
      'attached_documents': 'Δικαιολογητικά',
      'upload_documents': 'Ανέβασμα Δικαιολογητικών',
      'upload_documents_subtitle': 'Ανεβάστε τα απαιτούμενα δικαιολογητικά',
      'save_documents': 'Αποθήκευση Δικαιολογητικών',
      'documents_saved': 'Τα δικαιολογητικά αποθηκεύτηκαν με επιτυχία',
      'file_uploaded': 'Το αρχείο ανέβηκε με επιτυχία',
      'file_upload_failed': 'Το ανέβασμα του αρχείου απέτυχε',
      'student_photo_required': 'Η φωτογραφία φοιτητή είναι υποχρεωτική',
      'id_documents_required':
          'Και οι δύο φωτογραφίες της ταυτότητας (μπροστά και πίσω) είναι υποχρεωτικές',
      'passport_required': 'Η φωτογραφία του διαβατηρίου είναι υποχρεωτική',
      'document_type_required':
          'Παρακαλώ επιλέξτε τύπο εγγράφου (Ταυτότητα ή Διαβατήριο)',
      'medical_certificate_required':
          'Το ιατρικό πιστοποιητικό είναι υποχρεωτικό',
      'max_file_size': 'Μέγιστο μέγεθος αρχείου',
      'allowed_formats': 'Επιτρεπόμενες μορφές',
      'select_file': 'Επιλογή Αρχείου',
      'drag_drop_files':
          'Σύρετε και αφήστε αρχεία εδώ ή κάντε κλικ για επιλογή',
      'no_file_selected': 'Δεν επιλέχθηκε αρχείο',
      'file_too_large': 'Το αρχείο είναι πολύ μεγάλο',
      'invalid_file_format': 'Μη έγκυρη μορφή αρχείου',
      'upload_in_progress': 'Ανέβασμα σε εξέλιξη...',

      // Dashboard
      'overview': 'Επισκόπηση',
      'documents_uploaded': 'Δικαιολογητικά',
      'receipts': 'Αποδείξεις',
      'profile_completion': 'Ολοκλήρωση Προφίλ',
      'days_since_registration': 'Ημέρες από την Εγγραφή',
      'quick_actions': 'Γρήγορες Ενέργειες',
      'recent_documents': 'Πρόσφατα Δικαιολογητικά',
      'view_all': 'Προβολή Όλων',
      'dashboard_subtitle': '',
      'completed_tasks': 'Ολοκληρωμένα Καθήκοντα',
      'pending_tasks': 'Εκκρεμή Καθήκοντα',
      'no_completed_tasks': 'Δεν υπάρχουν ολοκληρωμένα καθήκοντα',
      'complete_registration_first': 'Ολοκληρώστε την εγγραφή οικοτροφείου',
      'upload_required_documents': 'Ανεβάστε τα απαιτούμενα δικαιολογητικά',

      // Settings
      'app_updates': 'Ενημερώσεις Εφαρμογής',
      'auto_check_updates': 'Αυτόματος έλεγχος ενημερώσεων',
      'auto_check_updates_desc':
          'Αυτόματος καθημερινός έλεγχος για ενημερώσεις',
      'appearance': 'Εμφάνιση',
      'theme': 'Θέμα',
      'system': 'Σύστημα',
      'language': 'Γλώσσα',
      'app_language': 'Γλώσσα Εφαρμογής',
      'about': 'Σχετικά',
      'oikad': 'ΟΙΚΑΔ',
      'dormitory_registration_system': 'Σύστημα Εγγραφής Οικοτροφείου',
      'version': 'Έκδοση',

      // Application Status
      'draft': 'Πρόχειρο',
      'submitted': 'Υποβλήθηκε',
      'under_review': 'Υπό Εξέταση',
      'approved': 'Εγκρίθηκε',
      'rejected': 'Απορρίφθηκε',
      'not_started': 'Δεν Ξεκίνησε',

      // Receipts
      'month': 'Μήνας',
      'year': 'Έτος',
      'all_years': 'Όλα τα Έτη',
      'all_months': 'Όλους τους Μήνες',
      'no_receipts_found': 'Δεν βρέθηκαν αποδείξεις',
      'uploaded': 'Ανέβηκε',
      'size': 'Μέγεθος',
      'downloading': 'Λήψη σε εξέλιξη...',
      'download_failed': 'Η λήψη απέτυχε',
      'download_error': 'Σφάλμα λήψης',
      'download_cancelled': 'Η λήψη ακυρώθηκε',
      'choose_save_location': 'Επιλογή τοποθεσίας αποθήκευσης',
      'file_saved_to': 'Το αρχείο αποθηκεύτηκε στη διαδρομή',
      'web_download_not_supported':
          'Η λήψη δεν υποστηρίζεται στον περιηγητή ιστού. Παρακαλώ χρησιμοποιήστε την εφαρμογή κινητού ή την έκδοση υπολογιστή.',
      'download_options': 'Επιλογές Λήψης',
      'choose_download_location': 'Επιλέξτε πού να αποθηκευτεί το αρχείο:',
      'downloads_folder': 'Φάκελος Λήψεων',
      'choose_location': 'Επιλογή Τοποθεσίας',
      'downloads_folder_error':
          'Δεν είναι δυνατή η πρόσβαση στον φάκελο Λήψεων',
      'app_documents': 'Έγγραφα Εφαρμογής',
      'documents_folder_error':
          'Δεν είναι δυνατή η πρόσβαση στον φάκελο Εγγράφων',

      // Messages
      'registration_complete': 'Η εγγραφή ολοκληρώθηκε',
      'registration_submitted': 'Η εγγραφή σας υποβλήθηκε.',
      'registration_failed': 'Η εγγραφή απέτυχε',
      'registration_saved_successfully': 'Η εγγραφή αποθηκεύτηκε με επιτυχία',
      'please_login_first': 'Παρακαλώ συνδεθείτε πρώτα για εγγραφή',
      'unexpected_error': 'Προέκυψε ένα απροσδόκητο σφάλμα',
      'coming_soon': 'Έρχεται σύντομα!',

      // Email Verification
      'email_verification_required': 'Απαιτείται Επιβεβαίωση Email',
      'email_verification_message':
          'Παρακαλώ ελέγξτε το email σας και κάντε κλικ στον σύνδεσμο επιβεβαίωσης για να ενεργοποιήσετε τον λογαριασμό σας.',
      'go_to_login': 'Μετάβαση στη Σύνδεση',
      'continue_to_dashboard': 'Συνέχεια στον Πίνακα Ελέγχου',
      'auto_login_after_verification':
          'Μετά την επιβεβαίωση του email σας, θα συνδεθείτε αυτόματα.',

      // Social Login
      'sign_in_with_google': 'Σύνδεση με Google',

      // Welcome Screen
      'app_title': 'OIKAD',
      'app_subtitle': 'Σύστημα Εγγραφής Φοιτητικών Εστιών',
      'browse_as_guest': 'Περιήγηση ως Επισκέπτης',
      'guest_mode_info':
          'Στη λειτουργία επισκέπτη, μπορείτε να δείτε τα δικαιολογητικά αλλά δεν μπορείτε να ανεβάσετε ή να υποβάλετε. Δημιουργήστε λογαριασμό για πρόσβαση σε όλες τις λειτουργίες.',
      'app_version': AppInfo.isInitialized
          ? 'Έκδοση ${AppInfo.version}'
          : 'Έκδοση Άγνωστη',
      'terms_of_service': 'Όροι Χρήσης',

      // Update System
      'check_updates': 'Έλεγχος για Ενημερώσεις',
      'update_available': 'Διαθέσιμη Ενημέρωση',
      'no_updates_available': 'Δεν υπάρχουν διαθέσιμες ενημερώσεις',
      'update_check_failed': 'Αποτυχία ελέγχου ενημερώσεων',
      'download_update': 'Λήψη Ενημέρωσης',
      'install_update': 'Εγκατάσταση Ενημέρωσης',
      'update_now': 'Ενημέρωση Τώρα',
      'update_later': 'Αργότερα',

      'downloading_update': 'Λήψη Ενημέρωσης...',
      'update_downloaded': 'Η ενημέρωση ολοκληρώθηκε επιτυχώς',
      'update_failed': 'Η ενημέρωση απέτυχε',
      'critical_update': 'Κρίσιμη Ενημέρωση',
      'security_update': 'Ενημέρωση Ασφαλείας',
      'tap_to_check': 'Πατήστε για έλεγχο ενημερώσεων',
      'feature_update': 'Ενημέρωση Χαρακτηριστικών',
      'bug_fixes': 'Διορθώσεις Σφαλμάτων',
      'new_features': 'Νέα Χαρακτηριστικά',
      'whats_new': 'Τι Νέο Υπάρχει',
      'current_version': 'Τρέχουσα Έκδοση',
      'new_version': 'Νέα Έκδοση',
      'download_size': 'Μέγεθος Λήψης',
      'update_description': 'Περιγραφή Ενημέρωσης',
      'update_required': 'Αυτή η ενημέρωση είναι απαραίτητη',
      'restart_required': 'Απαιτείται επανεκκίνηση μετά την ενημέρωση',

      // Links
      'privacy_policy_link':
          'https://www.lawspot.gr/nomikes-plirofories/nomothesia/nomos-4624-2019',
    },
  };

  static String t(String locale, String key) {
    return _translations[locale]?[key] ?? key;
  }

  static Map<String, String> getTranslations(String locale) {
    return _translations[locale] ?? _translations['en']!;
  }

  static List<String> get supportedLocales => _translations.keys.toList();
}
