# IconInk

IconInk is an iOS application for tattoo and piercing professionals to manage client information, scan IDs, capture signatures, and generate consent forms with a strong emphasis on privacy, security, and ease of use.

![IconInk Logo](iconink/Assets.xcassets/AppIcon.appiconset/AppIcon-83.5@2x.png)

## Features

- **Client Management**: Add, edit, and view client information
- **ID Scanning**: Extract client information from government-issued ID documents
- **Signature Capture**: Record client signatures for consent forms
- **Consent Forms**: Generate and manage digital consent forms
- **Security**: Local-only storage with optional biometric authentication and encryption
- **Privacy-First**: All data is stored only on the device with no cloud connectivity

## Privacy & Security

IconInk takes privacy and security seriously:

- All data remains on the device with no cloud or external services
- Optional biometric authentication (Face ID/Touch ID)
- Data encryption for sensitive information
- Secure storage of ID photos and personal details
- Auto-lock feature to protect client data

## Tech Stack

- Swift 5.9+
- SwiftUI for UI
- CoreData for local data storage
- Vision framework for ID scanning
- PDFKit for consent form generation
- LocalAuthentication for biometric security

## Requirements

- iOS 15.0 or later
- Xcode 16.2 or later

## Installation

1. Clone the repository:
```
git clone https://github.com/fleXRPL/iconink.git
```

2. Open the project in Xcode:
```
cd iconink
open iconink/iconink.xcodeproj
```

3. Build and run the application on your device or simulator.

## Development

### Architecture

IconInk follows the MVVM (Model-View-ViewModel) architecture pattern:

- **Models**: Core Data entities for clients, consent forms, etc.
- **Views**: SwiftUI views for user interface
- **ViewModels**: Business logic and data processing
- **Utilities**: Helper classes for ID scanning, security, etc.

### Project Structure

- `Models/`: CoreData models and extensions
- `Views/`: SwiftUI views for the user interface
- `Controllers/`: Controllers for camera and other functionalities
- `Utilities/`: Helper classes and utility functions
- `IconInk.xcdatamodeld/`: CoreData model definitions
- `Documentation/`: Project documentation

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Create a new Pull Request

### Code Style

Follow the Swift style guide and SwiftLint rules included in the project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Authors

- **IconInk Team** - [GitHub](https://github.com/fleXRPL)

## Documentation

Additional documentation is available in the [GitHub Wiki](https://github.com/fleXRPL/iconink/wiki).

## Acknowledgments

- Apple's [Vision Framework](https://developer.apple.com/documentation/vision) for ID scanning capabilities
- [SwiftLint](https://github.com/realm/SwiftLint) for Swift style and convention enforcement
