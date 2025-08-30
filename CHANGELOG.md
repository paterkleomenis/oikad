# Changelog

All notable changes to the OIKAD project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Auto-update system with GitHub releases integration
- Update notification banner and dialog
- Settings screen with update preferences
- Manual update checking functionality
- Version comparison and severity detection
- Platform-specific update installation (Android APK, Windows EXE, macOS DMG, Linux DEB)
- Automatic daily update checks (configurable)
- Update skip functionality for non-critical updates
- Forced updates for critical security patches
- Multi-language support for update notifications
- GitHub Actions workflow for automated releases

### Changed
- Enhanced dashboard with update checking capabilities
- Improved settings management
- Updated dependencies for auto-update functionality

### Security
- Added secure update verification
- Permission handling for app installation

## [1.0.0] - 2024-01-15

### Added
- Initial release of OIKAD Dormitory Registration System
- Student registration with personal information forms
- Document upload and management system
- Multi-language support (English and Greek)
- Dark and light theme support
- Supabase integration for backend services
- User authentication system
- Document categorization and validation
- Progress tracking for registration completion
- Responsive design for multiple screen sizes
- Material 3 design system implementation

### Features
- Complete student registration workflow
- Document upload with file validation
- Real-time form validation
- Secure data storage with Supabase
- Cross-platform support (Android, iOS, Web, Windows, macOS, Linux)
- Localized user interface
- Theme customization
- User profile management
- Registration progress tracking

### Technical
- Flutter 3.24.0+ compatibility
- Supabase Flutter integration
- Provider state management
- Material 3 theming
- Multi-platform builds
- Responsive layouts
- Form validation
- File handling and compression
- Secure credential management

## Release Notes Template

When creating new releases, use this template:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features

### Changed
- Modified features

### Fixed
- Bug fixes

### Removed
- Removed features

### Security
- Security improvements
```

## Version Naming Convention

- **Major version (X.0.0)**: Breaking changes, major new features
- **Minor version (X.Y.0)**: New features, non-breaking changes
- **Patch version (X.Y.Z)**: Bug fixes, small improvements

## Update Types

- **Critical**: Security fixes, urgent bug fixes (forced updates)
- **Major**: New features, significant improvements
- **Minor**: Feature enhancements, minor improvements
- **Patch**: Bug fixes, small updates