# Oikad

A Flutter application with Supabase backend integration.

## What does Oikad do?

Oikad is a student registration management system that allows students to:

- **Complete comprehensive registration forms** with personal details, educational background, and family information
- **Switch seamlessly between English and Greek languages** with full localization support
- **Submit secure data** to a Supabase backend with built-in validation and sanitization
- **Experience modern UI/UX** with Material Design 3, dark/light theme support, and smooth animations
- **Access the platform across multiple devices** (iOS, Android, Web, Desktop) thanks to Flutter's cross-platform capabilities

### Key Features

- 📝 **Multi-section registration form**:
  - Personal details (name, birth date, ID information)
  - Educational information (university, department, year of study)
  - Family information (parents' details and contact information)
  - Address information

- 🌍 **Bilingual support**:
  - Full English and Greek localization
  - Easy language switching with persistent preferences

- 🎨 **Modern interface**:
  - Material Design 3 components
  - Dark and light theme modes
  - Smooth animations and transitions
  - Hero animations for seamless navigation

- 🔒 **Security features**:
  - Input validation and sanitization
  - Rate limiting for form submissions
  - Secure data transmission to Supabase backend

- 📱 **Cross-platform compatibility**:
  - iOS and Android mobile apps
  - Web application
  - Desktop applications (Windows, macOS, Linux)

## Getting Started

### Prerequisites

- Flutter SDK (^3.8.1 or later)
- Dart SDK
- Android Studio / VS Code
- Supabase account (for backend services)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/paterkleomenis/oikad.git
   cd oikad

2. Install dependencies:
   ```bash
   flutter pub get

3. Run the application:
   ```bash
   flutter run --dart-define-from-file=.env

4. Build the application:
   ```bash
   # Load environment variables (Linux/Mac)
   set -a && source .env && set +a

   # Build debug APK
   flutter build apk --debug \
     --dart-define=DEV_SUPABASE_URL="$DEV_SUPABASE_URL" \
     --dart-define=DEV_SUPABASE_ANON_KEY="$DEV_SUPABASE_ANON_KEY" \
     --dart-define=DEBUG_MODE=true

## Contributing

Feel free to contribute to this project by opening issues or submitting pull requests.
