import 'package:flutter/material.dart';

import 'package:webapp_commons/service/api_service.dart';
import 'package:webapp_commons/service/project_service.dart';
// import 'package:webapp_commons/snippets/screens/result_screen.dart';
import 'package:webapp_commons/utils/logger.dart';
import 'screens/home_screen.dart';

import 'styles.dart';

void main() async {
  // CRITICAL: Initialize Flutter binding first
  WidgetsFlutterBinding.ensureInitialized();
  
  // CRITICAL: Initialize Tercen connection BEFORE any widgets
  await _initializeTercenConnection();
  
  // Only run app AFTER Tercen connection is established
  runApp(const MyApp());
}

Future<void> _initializeTercenConnection() async {
  try {
    await ApiService().connect();    
  } catch (e) {
   
    // Show undismissable error and stop app
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red,
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 80, color: Colors.white),
                const SizedBox(height: 20),
                const Text(
                  'CRITICAL ERROR',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Cannot connect to Tercen server.',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Error: $e',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Please check your connection and try again.',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ));
    
    // Stop execution here - app cannot continue without Tercen
    return;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'APP Title',
      theme: ThemeData(
        // primarySwatch: Mater,
        useMaterial3: true,
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  
  String _appName = '';
  String _appVersion = '';
  String _projectName = '';
  String _userName = '';
  String _teamName = '';

  final List<Widget> _screens = [
    const HomeScreen(),
    // const ResultScreen(),
  ];

  final List<IconData> _icons = [
    Icons.home,
    // Icons.api,
  ];

  final List<String> _labels = [
    'Home',
    // 'Results',
  ];

  @override
  void initState() {
    super.initState();
    // Connection is already established in main() - just load UI data
    _loadAppInfo();
    _loadFooterInfo();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  Future<void> _loadAppInfo() async {
    final packageInfo = await ApiService().getPackageInfo();
    setState(() {
      _appName = packageInfo['appName'] ?? 'Tercen WebApp';
      _appVersion = packageInfo['version'] ?? 'No Version Info';
    });
  }

  Future<void> _loadFooterInfo() async {
    try {
      setState(() {
        _projectName = ProjectService().projectName;
        _userName = ApiService().user;
        _teamName = ApiService().team;
      });
    } catch (e) {
      // Handle error gracefully
      Logger().log(
        level: Logger.ERROR,
        message: 'Error loading footer info: $e',
      );
      setState(() {
        _projectName = 'Error loading project';
        _userName = 'Error loading user';
        _teamName = 'Error loading team';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(screenSize),
            
            // Navigation Menu
            _buildNavigationMenu(screenSize, safeArea),
            
            // Separator Line
            Container(
              height: 1,
              color: Colors.grey[300],
            ),
            
            // Main Content Area
            Expanded(
              child: Container(
                color: Colors.white,
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.only(left: screenSize.width * 0.01),
                    child: _screens[_selectedIndex],
                  ),
                ),
              ),
            ),
            
            // Footer
            _buildFooter(screenSize, safeArea),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(Size screenSize) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Logo
          Image.asset(
            'assets/img/logo.png',
            width: 399 * 0.25,
            height: 145 * 0.25,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 399 * 0.25,
                height: 145 * 0.25,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.image, size: 50, color: Styles.inactiveForeground),
              );
            },
          ),
          const SizedBox(width: 20),
          
          // App Name
          Text(
            _appName,
            style: Styles.appHeader,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationMenu(Size screenSize, EdgeInsets safeArea) {
    
    var cont =  Container(
      constraints: BoxConstraints(
        minHeight: (screenSize.height - safeArea.top - safeArea.bottom) * Styles.minNavigationSz,
        maxHeight: (screenSize.height - safeArea.top - safeArea.bottom) * Styles.maxNavigationSz,
      ),
      color: Styles.appBackgroundColor,
      child: Row(
        children: List.generate(_icons.length, (index) {
          final isSelected = index == _selectedIndex;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? Styles.activeBackgroundColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  
                  Icon(
                    _icons[index],
                    size: 38,
                    color: isSelected ? Styles.activeForegroundColor : Styles.appForegroundColor,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _labels[index],
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Styles.activeForegroundColor : Styles.appForegroundColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );

    return Padding(padding: const EdgeInsets.fromLTRB(20, 0, 0, 0), child: cont,);
  }

  Widget _buildFooter(Size screenSize, EdgeInsets safeArea) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: (screenSize.height - safeArea.top - safeArea.bottom) * Styles.maxFooterHeight,
      ),
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$_appName ($_appVersion)',
            style: Styles.footerTextStyle,
          ),
          const SizedBox(width: 20),
          Text(
            _projectName,
            style: Styles.footerTextStyle,
          ),
          const SizedBox(width: 20),
          Text(
            "User: $_userName",
            style: Styles.footerTextStyle,
          ),
          const SizedBox(width: 20),
          Text(
            "Team: $_teamName",
            style: Styles.footerTextStyle,
          ),

        ],
      ),
    );
  }
}