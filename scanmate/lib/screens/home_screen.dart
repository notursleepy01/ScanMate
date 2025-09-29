import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scanmate/main.dart'; // To access theme switching
import 'package:scanmate/screens/scan_screen.dart';
import 'package:scanmate/screens/documents_screen.dart';
import 'package:scanmate/bloc/file_manager_bloc.dart';
import 'package:scanmate/services/storage_service.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _bottomNavSelectedIndex = 0; // For highlighting BottomNavBar item
  int _indexedStackIndex = 0;    // For controlling IndexedStack child

  // Screens for IndexedStack
  static final List<Widget> _pageWidgetOptions = <Widget>[
    const DocumentsScreen(), // Actual Documents screen
    // Scan is a navigation action, not a persistent IndexedStack page
    const Center(child: Text('Settings Screen Content - Placeholder')), // Placeholder for actual Settings
  ];

  void _navigateToScanScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanScreen()),
    );
  }

  void _onItemTapped(int index) {
    _bottomNavSelectedIndex = index; // Always update for visual feedback on BottomNavBar
    if (index == 1) { // "Scan" tab
      _navigateToScanScreen();
      // Don't change _indexedStackIndex as ScanScreen is a separate route
    } else {
      setState(() {
        // Documents (index 0) -> IndexedStack index 0
        // Settings (index 2) -> IndexedStack index 1
        _indexedStackIndex = index > 1 ? index - 1 : index;
      });
    }
  }

  void _showCreateFolderDialog(BuildContext context) {
    final TextEditingController folderNameController = TextEditingController();
    final fileManagerBloc = BlocProvider.of<FileManagerBloc>(context);
    final currentState = fileManagerBloc.state;
    String? parentFolderId;

    if (currentState is FileManagerLoaded) {
      if (currentState.currentFolderPath != 'root') {
        parentFolderId = currentState.currentFolderPath;
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create New Folder'),
          content: TextField(
            controller: folderNameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Folder name'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            TextButton(
              child: const Text('Create'),
              onPressed: () {
                final folderName = folderNameController.text.trim();
                if (folderName.isNotEmpty) {
                  fileManagerBloc.add(CreateNewFolder(
                    folderName: folderName,
                    parentFolderId: parentFolderId,
                  ));
                }
                Navigator.pop(dialogContext);
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final scanMateAppState = _ScanMateAppState.of(context); // Corrected call
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Provide FileManagerBloc higher up if needed by multiple direct children of HomeScreen,
    // but DocumentsScreen will have its own provider for now.
    // This one is for the FAB to access it.
    return BlocProvider(
      create: (context) => FileManagerBloc(StorageService())..add(const LoadRootContent()), // Initial load for FAB context
      child: Builder( // Use Builder to get context with FileManagerBloc
        builder: (context) {
          // Determine AppBar title based on the selected screen/tab
          String appBarTitle = 'ScanMate';
          if (_bottomNavSelectedIndex == 0) {
            appBarTitle = 'Documents';
          } else if (_bottomNavSelectedIndex == 2) {
            appBarTitle = 'Settings';
          }
          // Note: Scan screen will have its own AppBar title.

          return Scaffold(
            appBar: AppBar(
              title: Text(appBarTitle),
              elevation: 0, // M3 often uses less or no elevation for default AppBar
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer, // M3-ish color
              // foregroundColor: Theme.of(context).colorScheme.onSurface, // For text/icon colors
              actions: [
                IconButton(
                  icon: Icon(isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                  onPressed: () {
                    if (scanMateAppState != null) {
                      final newMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
                      scanMateAppState.setThemeMode(newMode);
                    }
                  },
                  tooltip: 'Toggle Theme',
                ),
              ],
            ),
            body: IndexedStack(
              index: _indexedStackIndex,
              children: _pageWidgetOptions,
            ),
            bottomNavigationBar: NavigationBar( // Using NavigationBar for M3 style
              selectedIndex: _bottomNavSelectedIndex,
              onDestinationSelected: _onItemTapped,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow, // Or .onlyShowSelected
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.folder_outlined),
                  selectedIcon: Icon(Icons.folder),
                  label: 'Documents',
                ),
                NavigationDestination(
                  icon: Icon(Icons.camera_alt_outlined),
                  selectedIcon: Icon(Icons.camera_alt),
                  label: 'Scan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
            floatingActionButton: _indexedStackIndex == 0 // Show FABs only on Documents screen (index 0 of _pageWidgetOptions)
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'fab_new_folder',
                        onPressed: () => _showCreateFolderDialog(context),
                        tooltip: 'New Folder',
                        child: const Icon(Icons.create_new_folder_outlined),
                      ),
                      const SizedBox(height: 12),
                      FloatingActionButton(
                        heroTag: 'fab_new_scan',
                        onPressed: _navigateToScanScreen,
                        tooltip: 'New Scan',
                        child: const Icon(Icons.camera_alt),
                      ),
                    ],
                  )
                : null,
            floatingActionButtonLocation: _indexedStackIndex == 0
                ? FloatingActionButtonLocation.endFloat
                : null, // Hide FAB if not on documents tab
          );
        }
      ),
    );
  }
}
