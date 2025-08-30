# Auto-Update System Guide

This guide explains how the auto-update system works in the OIKAD app and how to use it effectively.

## Overview

The OIKAD app includes a built-in auto-update system that automatically checks for new versions on GitHub releases and allows users to download and install updates seamlessly.

## Features

### ✅ Automatic Update Checking
- Checks for updates every 24 hours (configurable)
- Background checking when app starts or resumes
- Manual update checking available

### ✅ Smart Update Detection
- Compares semantic versions (1.0.0 vs 1.0.1)
- Detects update severity (patch, minor, major)
- Identifies critical security updates

### ✅ Platform Support
- **Android**: Downloads and installs APK files
- **iOS**: Redirects to App Store (when published)
- **Windows**: Downloads EXE installer
- **macOS**: Downloads DMG package
- **Linux**: Downloads DEB package

### ✅ User-Friendly Interface
- Update notification banner
- Detailed update dialog with changelog
- Progress indicator during download
- Skip option for non-critical updates

## How to Use

### For End Users

#### Automatic Updates
1. The app automatically checks for updates daily
2. When an update is available, you'll see a notification banner
3. Tap "Update" to view details and download
4. Follow the installation prompts

#### Manual Update Check
1. Open the app dashboard
2. Tap the menu (⋮) in the top-right corner
3. Select "Check for Updates"
4. If an update is available, you'll see the update dialog

#### Settings
1. Go to Dashboard → Menu → Settings
2. Under "App Updates" section:
   - View current version
   - Check for updates manually
   - Toggle automatic update checking
   - View available updates

#### Update Types
- **Critical Updates**: Security fixes (cannot be skipped)
- **Major Updates**: New features and significant changes
- **Minor Updates**: Feature improvements and enhancements
- **Patch Updates**: Bug fixes and small improvements

### For Developers

#### Setting Up Releases

1. **Version Numbering**
   ```
   Format: v1.2.3
   - Major: Breaking changes (1.0.0)
   - Minor: New features (1.1.0)
   - Patch: Bug fixes (1.1.1)
   ```

2. **Creating a Release**
   ```bash
   # Tag your commit
   git tag v1.2.3
   git push origin v1.2.3
   
   # GitHub Actions will automatically build and create release
   ```

3. **Manual Release via GitHub Actions**
   - Go to GitHub → Actions tab
   - Run "Build and Release" workflow
   - Enter version number (e.g., 1.2.3)

#### Release Notes Format

Create releases with proper changelog format:

```markdown
## New Features
- Added new document upload system
- Improved user interface design
- Enhanced security features

## Bug Fixes
- Fixed registration form validation
- Resolved document upload issues
- Fixed theme switching problems

## Security
- Updated authentication system
- Enhanced data encryption
- Fixed security vulnerabilities
```

#### Critical Updates

Mark security updates as critical by including keywords in release notes:
- "critical"
- "security"
- "urgent"

This will make the update mandatory (cannot be skipped).

## Technical Implementation

### Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   UpdateService │────│  GitHub Releases │────│ Version Service │
│                 │    │       API        │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                                               │
         │                                               │
         ▼                                               ▼
┌─────────────────┐                              ┌─────────────────┐
│  Update Dialog  │                              │ Update Checker  │
│                 │                              │                 │
└─────────────────┘                              └─────────────────┘
```

### Key Components

1. **UpdateService**: Main service handling update logic
2. **VersionService**: Version comparison and utilities
3. **UpdateDialog**: User interface for update prompts
4. **UpdateChecker**: Background update checking widget
5. **AppUpdate**: Model representing update information

### Configuration

The update system is configured in `lib/services/update_service.dart`:

```dart
static const String _githubRepoUrl = 
    'https://api.github.com/repos/paterkleomenis/oikad/releases';
```

### Permissions

Android requires these permissions for installing updates:
```xml
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

## Troubleshooting

### Common Issues

#### Update Check Fails
- **Cause**: Network connectivity issues
- **Solution**: Check internet connection and try again

#### Download Fails
- **Cause**: Insufficient storage or network interruption
- **Solution**: Free up storage space and retry download

#### Installation Fails (Android)
- **Cause**: "Install from unknown sources" disabled
- **Solution**: Enable installation from unknown sources in device settings

#### No Updates Available
- **Cause**: Already on latest version or check frequency
- **Solution**: Wait for new releases or check manually

### Debug Information

Enable debug logging to troubleshoot issues:

```dart
// In main.dart
debugPrint('Update service initialized');

// Check logs for update-related messages
```

## Best Practices

### For Users
1. Keep automatic updates enabled for security
2. Install critical updates immediately
3. Ensure stable internet connection during updates
4. Have sufficient storage space available

### For Developers
1. Follow semantic versioning strictly
2. Write clear, descriptive release notes
3. Test releases thoroughly before publishing
4. Mark security updates as critical
5. Provide migration guides for breaking changes

## Security Considerations

### Update Verification
- Updates are downloaded from official GitHub releases only
- HTTPS connection ensures secure download
- No automatic execution without user consent

### Privacy
- Update checks only send version information
- No personal data transmitted during update process
- Update preferences stored locally

### Permissions
- Minimal required permissions requested
- User consent required for installation
- No background installation without notification

## Future Enhancements

### Planned Features
- [ ] Delta updates (download only changes)
- [ ] Rollback capability
- [ ] Update scheduling
- [ ] Update notifications customization
- [ ] Enterprise update management

### Considerations
- Implement update verification signatures
- Add update size optimization
- Enhance offline update capabilities
- Improve update UI/UX

## Support

If you encounter issues with the auto-update system:

1. Check the [GitHub Issues](https://github.com/paterkleomenis/oikad/issues)
2. Report bugs with detailed information:
   - Device/OS information
   - Current app version
   - Error messages
   - Steps to reproduce

## License

The auto-update system is part of the OIKAD project and follows the same license terms.