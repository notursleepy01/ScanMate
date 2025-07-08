import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

// Custom HTTP client that includes the access token in headers
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveAppdataScope, // Access to appDataFolder
      drive.DriveApi.driveFileScope,    // Access to files created or opened by the app.
                                        // Consider if broader scope is needed, but start specific.
    ],
  );

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  // --- Authentication ---

  Future<bool> isSignedIn() async {
    return _googleSignIn.isSignedIn();
  }

  Future<GoogleSignInAccount?> getCurrentUser() async {
    _currentUser ??= await _googleSignIn.signInSilently();
    return _currentUser;
  }

  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser == null) {
        debugPrint('GoogleDriveService: Sign-in cancelled by user.');
        return false;
      }
      debugPrint('GoogleDriveService: User signed in: ${_currentUser!.displayName}');
      await _initializeDriveApi();
      return true;
    } catch (error) {
      debugPrint('GoogleDriveService: Error signing in: $error');
      _currentUser = null;
      _driveApi = null;
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      _driveApi = null;
      debugPrint('GoogleDriveService: User signed out.');
    } catch (error) {
      debugPrint('GoogleDriveService: Error signing out: $error');
    }
  }

  Future<void> _initializeDriveApi() async {
    if (_currentUser == null) {
      debugPrint('GoogleDriveService: Cannot initialize Drive API, user not signed in.');
      return;
    }
    final authHeaders = await _currentUser!.authHeaders;
    final authenticatedClient = GoogleAuthClient(authHeaders);
    _driveApi = drive.DriveApi(authenticatedClient);
    debugPrint('GoogleDriveService: Drive API initialized.');
  }

  // --- File Operations ---
  // Using appDataFolder to store app-specific configuration or metadata.
  // Actual PDFs might be stored in a user-visible folder if drive.DriveApi.driveFileScope is used effectively.

  Future<String?> _getOrCreateAppFolderId() async {
    if (_driveApi == null) await _initializeDriveApi();
    if (_driveApi == null) {
      debugPrint("Drive API not initialized for getting/creating app folder.");
      return null;
    }

    try {
      // Check if a specific folder for ScanMate already exists.
      // Using a query to find a folder by name in the appDataFolder.
      // This is more robust than relying on a hardcoded ID.
      // Note: appDataFolder contents are hidden from the user's regular Drive UI.
      // If user-visible files are desired, use 'root' instead of 'appDataFolder' as parents
      // and ensure driveFileScope is granted.

      final String appFolderName = "ScanMateAppData"; // Or whatever you choose
      var query = "name='$appFolderName' and 'appDataFolder' in parents and mimeType='application/vnd.google-apps.folder' and trashed=false";

      drive.FileList fileList = await _driveApi!.files.list(
        q: query,
        spaces: 'appDataFolder', // Search within appDataFolder
        $fields: 'files(id, name)',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        debugPrint("ScanMate appDataFolder found: ${fileList.files!.first.id}");
        return fileList.files!.first.id;
      } else {
        // Create the folder
        debugPrint("Creating ScanMate appDataFolder...");
        var folder = drive.File();
        folder.name = appFolderName;
        folder.mimeType = "application/vnd.google-apps.folder";
        folder.parents = ["appDataFolder"]; // Create inside appDataFolder

        var createdFolder = await _driveApi!.files.create(folder);
        debugPrint("ScanMate appDataFolder created: ${createdFolder.id}");
        return createdFolder.id;
      }
    } catch (e) {
      debugPrint("Error getting/creating app folder ID: $e");
      return null;
    }
  }

  Future<String?> uploadPdf(String filePath, String fileNameInDrive, {String? parentFolderId}) async {
    if (_driveApi == null) await _initializeDriveApi();
    if (_driveApi == null) {
      debugPrint("Drive API not initialized for upload.");
      return null;
    }

    final fileToUpload = File(filePath);
    if (!await fileToUpload.exists()) {
      debugPrint("File to upload does not exist: $filePath");
      return null;
    }

    try {
      var driveFile = drive.File();
      driveFile.name = fileNameInDrive;
      // If parentFolderId is null, it will be uploaded to the root of the accessible scope
      // (e.g., appDataFolder or general Drive if driveFileScope is used broadly)
      // For user-visible files, you'd typically get/create a specific app folder in user's Drive.
      // For this example, let's assume we might pass a specific folder ID or default to appDataFolder.

      String? effectiveParentId = parentFolderId;
      if (effectiveParentId == null) {
          // Default to creating/using a folder within appDataFolder for organization
          effectiveParentId = await _getOrCreateAppFolderId();
          if (effectiveParentId == null) {
              debugPrint("Could not get/create app folder for upload.");
              return null;
          }
          driveFile.parents = [effectiveParentId]; // Set parent to appDataFolder subfolder
      } else {
          driveFile.parents = [parentFolderId];
      }


      final media = drive.Media(fileToUpload.openRead(), await fileToUpload.length());
      final uploadedFile = await _driveApi!.files.create(driveFile, uploadMedia: media);
      debugPrint('File uploaded successfully. ID: ${uploadedFile.id}');
      return uploadedFile.id;
    } catch (e) {
      debugPrint('Error uploading file to Google Drive: $e');
      return null;
    }
  }

  // Placeholder for other operations like listing files, download, delete from Drive
  Future<List<drive.File>> listFilesInAppFolder() async {
    if (_driveApi == null) await _initializeDriveApi();
    if (_driveApi == null) return [];

    String? appFolderId = await _getOrCreateAppFolderId();
    if (appFolderId == null) return [];

    try {
      final fileList = await _driveApi!.files.list(
        q: "'$appFolderId' in parents and trashed=false", // List files in our appData subfolder
        spaces: 'appDataFolder', // Ensure we are looking in the right space
        $fields: "files(id, name, mimeType, modifiedTime, size)",
      );
      return fileList.files ?? [];
    } catch (e) {
      debugPrint('Error listing files from Google Drive: $e');
      return [];
    }
  }

  Future<File?> downloadFile(String fileId, String localPath) async {
    // Implementation needed
    debugPrint("Download for $fileId to $localPath not implemented.");
    return null;
  }

  Future<void> deleteFile(String fileId) async {
    // Implementation needed
    debugPrint("Delete for $fileId not implemented.");
  }

  // --- Sync Logic (Simplified Placeholder) ---
  // This would be much more complex in a real app.
  Future<void> synchronize() async {
    if (!await isSignedIn()) {
      debugPrint("Cannot synchronize, user not signed in.");
      return;
    }
    if (_driveApi == null) {
      await _initializeDriveApi();
      if (_driveApi == null) {
        debugPrint("Failed to initialize Drive API for sync.");
        return;
      }
    }
    debugPrint("Starting synchronization with Google Drive...");
    // 1. List local documents/folders.
    // 2. List remote documents/folders (e.g., in appDataFolder).
    // 3. Compare and decide what to upload/download.
    //    - This needs a strategy for last-modified timestamps, conflict resolution, etc.
    //    - For simplicity, this placeholder won't implement the full diffing logic.

    // Example: Upload a test file (replace with actual document paths)
    // final Directory appDocDir = await getApplicationDocumentsDirectory();
    // final String testFilePath = '${appDocDir.path}/example.pdf'; // Assume it exists for testing
    // final File testFile = File(testFilePath);
    // if (await testFile.exists()) {
    //    await uploadPdf(testFilePath, "example_synced.pdf");
    // } else {
    //    debugPrint("Test file for sync not found at $testFilePath");
    // }

    final driveFiles = await listFilesInAppFolder();
    debugPrint("Files in app folder on Drive: ${driveFiles.map((f) => f.name).toList()}");

    debugPrint("Synchronization logic placeholder finished.");
  }
}
