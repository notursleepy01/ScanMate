# ScanMate Flutter App

ScanMate is a mobile application built with Flutter for scanning documents, extracting text via OCR, managing them locally, and optionally syncing with Google Drive.

## Features

*   **Document Scanning**:
    *   Capture documents using the device camera.
    *   Automatic (via `image_cropper` capabilities) and manual edge detection/cropping.
    *   Image enhancement filters (Grayscale, Black & White).
    *   Conversion of captured images into multi-page PDF documents.
*   **OCR Support**:
    *   Text extraction from scanned images using `google_mlkit_text_recognition`.
    *   Search scanned documents by their content.
*   **Document Management**:
    *   Local storage of documents and their metadata using Hive.
    *   Organization of documents into folders.
    *   Search documents by title or extracted OCR content.
    *   Rename, delete, and sort documents/folders.
    *   Export and share PDF documents.
*   **Google Drive Sync (Optional)**:
    *   Authenticate with Google account.
    *   Sync document PDFs and metadata to a dedicated app folder on Google Drive.
*   **Modern UI**:
    *   Built with Material Design 3 principles.
    *   Support for Light and Dark mode.
    *   Custom AppBar and Bottom Navigation Bar (`NavigationBar`).
    *   User-friendly interface with subtle animations.
*   **Code Structure**:
    *   Follows clean architecture principles.
    *   Code organized into `models`, `services`, `bloc` (for BLoC pattern), `widgets`, and `screens`.
    *   Null safety enabled.

## Build Instructions

### Prerequisites

*   Flutter SDK (Version 3.22.2 or as specified in `pubspec.yaml`'s `environment` section).
*   Dart SDK (comes with Flutter).
*   An IDE like Android Studio (with Flutter plugin) or VS Code (with Flutter extension).
*   For Android: Android SDK, NDK (if building from source for certain plugins or specific native code).
*   For iOS: Xcode, CocoaPods.

### Setup

1.  **Clone the repository (if applicable)**:
    ```bash
    git clone <repository-url>
    cd scanmate
    ```
2.  **Ensure Flutter is set up**:
    Run `flutter doctor` to check for any missing dependencies or setup issues for your target platform.
3.  **Get dependencies**:
    ```bash
    flutter pub get
    ```
4.  **Generate Hive TypeAdapters (and other generated files)**:
    If you've made changes to Hive models or other code requiring generation:
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```
    *Note: This step is crucial for Hive to work correctly.*

### Running the App

*   **Connect a device or start an emulator/simulator.**
*   **Run the app**:
    ```bash
    flutter run
    ```

### Building for Release

*   **Android (APK)**:
    ```bash
    flutter build apk --release
    ```
    The output APK can be found in `build/app/outputs/flutter-apk/app-release.apk`.

*   **Android (App Bundle)**:
    ```bash
    flutter build appbundle --release
    ```
    The output AAB can be found in `build/app/outputs/bundle/release/app.aab`.

*   **iOS**:
    Open the `ios` folder in Xcode and follow standard iOS deployment procedures.
    Alternatively, use Flutter commands:
    ```bash
    flutter build ios --release
    ```
    (Further setup for code signing and provisioning profiles will be required in Xcode.)


## Screenshots

*(Placeholder for screenshots of the app - e.g., Documents Screen, Scan Screen, Settings, etc.)*

---

*This README was auto-generated as part of the project setup.*
