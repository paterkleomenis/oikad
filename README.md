# OIKAD - Dormitory Registration System

A modern Flutter application for student dormitory registration with document management, built with Supabase backend integration.

## 🚀 Quick Start

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/paterkleomenis/oikad.git
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
   flutter run --dart-define-from-file=.env
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


---
