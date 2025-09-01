# OIKAD - Student Dormitory Management System

<div align="center">

![OIKAD Logo](assets/oikad-logo.png)

**A modern Flutter application for student dormitory registration with document management and auto-update capabilities**

[![Flutter](https://img.shields.io/badge/Flutter-3.19+-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-lightgrey.svg)](https://flutter.dev/multi-platform)

[Features](#features) • [Installation](#installation) • [Configuration](#configuration) • [Documentation](#documentation) • [Contributing](#contributing)

</div>

---

## 🚀 Features

### Core Functionality
- 📝 **Student Registration System** - Complete dormitory application process
- 📁 **Document Management** - Upload, organize, and track required documents
- 🌐 **Multi-language Support** - English and Greek localization
- 📱 **Cross-platform** - Android, iOS, Web, Windows, macOS, Linux
- 🎨 **Modern UI** - Material Design 3 with dynamic theming

### Advanced Features
- 🔄 **Auto-Update System** - Seamless updates for sideloaded applications
- 🔐 **Secure File Handling** - SHA-256 integrity verification
- 📊 **Real-time Status Tracking** - Monitor application progress
- 💾 **Offline Capability** - Work without internet connection
- 🔒 **Privacy-focused** - GDPR compliant with consent management

### Technical Highlights
- ⚡ **High Performance** - Optimized image compression and caching
- 🛡️ **Security** - End-to-end encryption and secure authentication
- 🔧 **Developer Tools** - Comprehensive debugging and diagnostics
- 📈 **Scalable Architecture** - Clean separation of concerns

---

## 📦 Installation

### Prerequisites

- **Flutter SDK** 3.19 or higher
- **Android SDK** (for Android builds)
- **Xcode** (for iOS builds, macOS only)
- **Git** for version control

### Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/paterkleomenis/oikad.git
cd oikad

# 2. Install Flutter dependencies
flutter pub get

# 3. Set up environment variables
cp .env.example .env
# Edit .env with your configuration

# 4. Run the application
flutter run --dart-define-from-file=.env
```

### Platform-specific Setup

<details>
<summary><strong>🤖 Android Setup</strong></summary>

1. **Install Android Studio** and Android SDK
2. **Configure signing** (for release builds):
   ```bash
   # Generate keystore
   keytool -genkey -v -keystore android/app/upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
3. **Update package name** in `android/app/build.gradle.kts` if needed
4. **Enable unknown sources** for auto-update functionality

</details>

<details>
<summary><strong>🍎 iOS Setup</strong></summary>

1. **Install Xcode** from the Mac App Store
2. **Configure signing** in Xcode project settings
3. **Update bundle identifier** if needed
4. **Add capabilities** for file access and networking

</details>

<details>
<summary><strong>🌐 Web Setup</strong></summary>

```bash
# Build for web
flutter build web --release

# Serve locally
flutter run -d chrome --web-port 8080
```

</details>

---

## ⚙️ Configuration

### Environment Variables

Create a `.env` file based on `.env.example`:

```bash
# Backend Configuration (Optional)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key

# Auto-Update System
GITHUB_TOKEN=github_pat_your_token_here
GITHUB_REPO_URL=https://api.github.com/repos/username/repo/releases

# App Settings
APP_ENV=production
DEBUG_MODE=false
ENABLE_AUTO_UPDATES=true
```

### Supabase Setup (Optional)

1. **Create a Supabase project** at [supabase.com](https://supabase.com)
2. **Import the database schema**:
   ```sql
   -- Run the SQL script
   psql -f sql/setup_database.sql
   ```
3. **Configure authentication** (email, OAuth, etc.)
4. **Set up storage buckets** for file uploads

### Auto-Update Configuration

The app includes a sophisticated auto-update system for sideloaded installations:

1. **GitHub Releases**: Configure your repository to create releases
2. **Security**: Updates are verified with SHA-256 checksums
3. **User Control**: Users can enable/disable auto-checks
4. **Permissions**: Automatic handling of Android install permissions

---

## 🏗️ Architecture

### Project Structure

```
oikad/
├── 📁 lib/
│   ├── 📁 models/          # Data models and entities
│   ├── 📁 screens/         # UI screens and pages
│   ├── 📁 services/        # Business logic and API clients
│   ├── 📁 widgets/         # Reusable UI components
│   ├── 📁 utils/           # Utilities and helpers
│   ├── 📁 notifiers/       # State management
│   └── 📄 main.dart        # Application entry point
├── 📁 assets/              # Images, fonts, and static files
├── 📁 sql/                 # Database schema and migrations
├── 📁 android/             # Android-specific configuration
├── 📁 ios/                 # iOS-specific configuration
├── 📁 web/                 # Web-specific configuration
├── 📁 scripts/             # Build and deployment scripts
└── 📄 pubspec.yaml         # Dependencies and metadata
```

### Key Services

| Service | Purpose |
|---------|---------|
| `AuthService` | User authentication and session management |
| `UpdateService` | Auto-update functionality and GitHub integration |
| `LocalizationService` | Multi-language support |
| `ConfigService` | Environment and app configuration |
| `DatabaseService` | Supabase integration and data persistence |

### State Management

- **Provider Pattern** for reactive state management
- **Notifiers** for UI state and user preferences
- **Dependency Injection** for service instances

---

## 🗄️ Database Schema

### Core Tables

```sql
-- Student registration data
CREATE TABLE dormitory_students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    student_id VARCHAR(50) UNIQUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Document categories and requirements
CREATE TABLE document_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    required BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Uploaded documents
CREATE TABLE student_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES dormitory_students(id),
    category_id UUID REFERENCES document_categories(id),
    file_path VARCHAR(500),
    file_name VARCHAR(255),
    file_size INTEGER,
    uploaded_at TIMESTAMP DEFAULT NOW()
);
```

Full schema available in [`sql/setup_database.sql`](sql/setup_database.sql)

---

## 🛠️ Development

### Building for Production

```bash
# Android APK (sideloading)
flutter build apk --release --dart-define-from-file=.env

# Android App Bundle (Play Store)
flutter build appbundle --release --dart-define-from-file=.env

# iOS
flutter build ios --release --dart-define-from-file=.env

# Web
flutter build web --release --dart-define-from-file=.env

# Desktop
flutter build windows --release --dart-define-from-file=.env
flutter build macos --release --dart-define-from-file=.env
flutter build linux --release --dart-define-from-file=.env
```

### Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Generate test coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Code Quality

```bash
# Static analysis
flutter analyze

# Format code
flutter format .

# Check for outdated dependencies
flutter pub outdated
```

### Debugging

The app includes comprehensive debugging tools:

- **Debug Menu**: Available in debug builds
- **Error Reporting**: Structured error logging
- **Performance Monitoring**: Flutter Inspector integration
- **Network Debugging**: Request/response logging

---

## 🔄 Auto-Update System

### Overview

OIKAD includes a sophisticated auto-update system designed for applications distributed outside official app stores:

### Features

- ✅ **GitHub Integration**: Automatic release detection
- ✅ **Security**: SHA-256 checksum verification
- ✅ **User Control**: Configurable auto-check settings
- ✅ **Progress Tracking**: Real-time download progress
- ✅ **Error Handling**: Comprehensive error recovery
- ✅ **Permissions**: Automatic Android permission management

### How It Works

1. **Check**: Periodically checks GitHub releases API
2. **Compare**: Semantic version comparison with current app
3. **Download**: Secure download with integrity verification
4. **Install**: Guided installation process for users

### Configuration

```dart
// Configure in .env
GITHUB_TOKEN=github_pat_your_token_here
GITHUB_REPO_URL=https://api.github.com/repos/username/repo/releases

// App settings
ENABLE_AUTO_UPDATES=true
```

### Security

- **Checksum Verification**: All downloads verified with SHA-256
- **Package Validation**: Ensures updates are from trusted source
- **Permission Management**: Secure handling of install permissions
- **User Consent**: Users control when updates are installed

---

## 🌐 Deployment

### GitHub Actions CI/CD

```yaml
# .github/workflows/build.yml
name: Build and Release
on:
  push:
    tags: ['v*']
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - name: Build APK
        run: flutter build apk --release
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: build/app/outputs/flutter-apk/app-release.apk
```

### Release Process

1. **Version Bump**: Update version in `pubspec.yaml`
2. **Tag Release**: Create git tag `v1.2.3`
3. **Build**: GitHub Actions automatically builds APK
4. **Release**: Creates GitHub release with assets
5. **Auto-Update**: Existing users get update notification

---

## 📚 Documentation

### API Documentation

- [Supabase Integration Guide](docs/supabase-setup.md)
- [Auto-Update System](docs/auto-update.md)
- [Internationalization](docs/i18n.md)
- [Security Guidelines](docs/security.md)

### Code Documentation

```bash
# Generate documentation
dart doc .

# Serve documentation locally
python -m http.server 8000 -d doc/api
```

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Quick Start for Contributors

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature-name`
3. **Make** your changes
4. **Test** thoroughly: `flutter test`
5. **Submit** a pull request

### Development Workflow

- **Code Style**: Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- **Testing**: Add tests for new features
- **Documentation**: Update docs for API changes
- **Commit Messages**: Use [Conventional Commits](https://conventionalcommits.org/)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙋‍♂️ Support

### Getting Help

- 📧 **Email**: support@oikad.app
- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/paterkleomenis/oikad/issues)
- 💡 **Feature Requests**: [GitHub Discussions](https://github.com/paterkleomenis/oikad/discussions)
- 📖 **Documentation**: [Wiki](https://github.com/paterkleomenis/oikad/wiki)

### Community

- 💬 **Discord**: [Join our server](https://discord.gg/oikad)
- 🐦 **Twitter**: [@OikadApp](https://twitter.com/OikadApp)
- 📱 **Telegram**: [OIKAD Support](https://t.me/oikad_support)

---

## 🎯 Roadmap

### Current Version (v1.1.1)
- ✅ Core dormitory registration system
- ✅ Document upload and management
- ✅ Auto-update system
- ✅ Multi-language support

### Upcoming Features
- 🔄 **v1.2.0**: Enhanced analytics and reporting
- 🔄 **v1.3.0**: Mobile app for staff
- 🔄 **v1.4.0**: Integration with university systems
- 🔄 **v2.0.0**: Complete redesign with new features

---

## ⭐ Acknowledgments

- [Flutter Team](https://flutter.dev/) for the amazing framework
- [Supabase](https://supabase.com/) for the backend infrastructure
- [Material Design](https://material.io/) for design guidelines
- All [contributors](https://github.com/paterkleomenis/oikad/contributors) who helped make this project better

---

<div align="center">

**Made with ❤️ by the OIKAD Team**

If you find this project helpful, please consider giving it a ⭐ on GitHub!

</div>