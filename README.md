# OIKAD - Dormitory Registration System

A modern Flutter application for student dormitory registration with document management, built with Supabase backend integration.

## 🏠 Overview

OIKAD is a comprehensive dormitory registration system that streamlines the student housing application process. Students can register for dormitory accommodation, upload required documents, and track their application status through an intuitive mobile and web interface.

## ✨ Features

### 📝 **Registration System**
- Complete dormitory application with personal, academic, and family information
- Multi-step form with validation and data sanitization
- Real-time form saving and progress tracking

### 📄 **Document Management**
- Smart document selection (ID Card OR Passport)
- Image compression and optimization
- Secure file upload to Supabase Storage
- Support for multiple file formats (JPG, PNG, PDF)

### 🌍 **Internationalization**
- Full bilingual support (English & Greek)
- Dynamic language switching
- Culturally appropriate translations and formatting

### 🎨 **Modern UI/UX**
- Material Design 3 components
- Dark/Light theme support with system preference detection
- Smooth animations and transitions
- Responsive design for mobile, tablet, and desktop

### 🔐 **Security & Privacy**
- Supabase authentication integration
- Row Level Security (RLS) policies
- Input validation and sanitization
- GDPR-compliant data handling

### 📱 **Cross-Platform**
- iOS & Android mobile apps
- Progressive Web App (PWA)
- Desktop support (Windows, macOS, Linux)

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Frontend                         │
├─────────────────────────────────────────────────────────────┤
│  • Registration Screens    • Document Upload               │
│  • Dashboard              • Authentication UI              │
│  • Localization          • Theme Management                │
└─────────────────────────────────────────────────────────────┘
                                    │
                                    │ HTTP/REST API
                                    ▼
┌─────────────────────────────────────────────────────────────┐
│                   Supabase Backend                          │
├─────────────────────────────────────────────────────────────┤
│  • PostgreSQL Database    • Authentication                 │
│  • Row Level Security     • File Storage                   │
│  • Real-time Updates      • Edge Functions                 │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Flutter SDK (^3.8.1)
- Dart SDK
- Supabase account
- Android Studio / VS Code

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/oikad.git
   cd oikad
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Supabase**
   - Create a new Supabase project
   - Run the database setup script from `sql/setup_database.sql`
   - Get your project URL and anon key

4. **Configure environment variables**
   ```bash
   # Create .env file
   echo "SUPABASE_URL=your_supabase_url" > .env
   echo "SUPABASE_ANON_KEY=your_anon_key" >> .env
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
oikad/
├── lib/
│   ├── screens/          # UI screens (Welcome, Dashboard, Registration, etc.)
│   ├── services/         # Business logic and API integration
│   ├── widgets/          # Reusable UI components
│   ├── notifiers/        # State management (Provider pattern)
│   └── main.dart         # App entry point
├── assets/               # Images, icons, and static resources
├── sql/                  # Database setup scripts
├── android/              # Android-specific configuration
├── ios/                  # iOS-specific configuration
├── web/                  # Web-specific configuration
└── pubspec.yaml          # Dependencies and project metadata
```

## 🗄️ Database Schema

The application uses a PostgreSQL database via Supabase with the following main tables:

- **`dormitory_students`** - Student registration data
- **`document_categories`** - Document type definitions
- **`student_documents`** - Uploaded file metadata
- **`document_submissions`** - Submission tracking and consent

Full schema available in `sql/setup_database.sql`

## 🔧 Development

### Building for Production

```bash
# Android APK
flutter build apk --release

# iOS (requires macOS and Xcode)
flutter build ios --release

# Web
flutter build web --release

# Desktop
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

### Running Tests

```bash
flutter test
```

### Code Analysis

```bash
flutter analyze
```

## 📊 Key Technologies

| Technology | Purpose |
|------------|---------|
| **Flutter** | Cross-platform UI framework |
| **Supabase** | Backend-as-a-Service (Database, Auth, Storage) |
| **Provider** | State management |
| **Material 3** | Design system and UI components |
| **PostgreSQL** | Relational database |
| **Image Compression** | File optimization for uploads |

## 🌐 Localization

The app supports:
- **English** (en) - Default language
- **Greek** (el) - Full localization including forms, validation messages, and UI text

Language can be changed dynamically through the UI, with preferences persisted locally.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

For support, email [support@oikad.example] or create an issue on GitHub.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for the powerful backend services
- Material Design team for the design system
- The open-source community for various packages used

---

**Built with ❤️ using Flutter and Supabase**