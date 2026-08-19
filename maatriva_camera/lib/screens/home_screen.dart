import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../services/permission_service.dart';
import '../services/socket_service.dart';
import '../services/webrtc_service.dart';
import '../theme/app_colors.dart';
import '../widgets/camera_preview.dart';
import '../widgets/control_buttons.dart';
import '../widgets/status_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SocketService _socketService = SocketService();
  late final WebrtcService _webrtcService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Settings inputs
  final TextEditingController _apiUrlController =
      TextEditingController(text: 'http://localhost:3000');
  final TextEditingController _emailController =
      TextEditingController(text: 'maatriva@example.com');
  final TextEditingController _passwordController =
      TextEditingController(text: 'Password@123');

  List<dynamic> _babiesList = [];
  String? _selectedBabyId;

  bool _isSettingsLoading = false;
  String? _settingsError;

  @override
  void initState() {
    super.initState();
    _webrtcService = WebrtcService(_socketService);

    _socketService.onSessionExpired = () {
      if (mounted) {
        _showSnackBar('Session expired. Please log in again.', isError: true);
        _openSettingsModal();
      }
    };

    // Initial permissions check and preview startup
    _checkAndStartLocalPreview();

    // Load cached credentials
    _loadCachedSettings();
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _webrtcService.dispose();
    _socketService.disconnect();
    super.dispose();
  }

  Future<void> _checkAndStartLocalPreview() async {
    final hasPerms = await PermissionService.checkCameraAndMicrophone();
    if (hasPerms) {
      try {
        await _webrtcService.startLocalStream();
      } catch (e) {
        _showSnackBar('Error starting camera view: $e', isError: true);
      }
    }
  }

  Future<void> _loadCachedSettings() async {
    final cachedUrl = await _storage.read(key: 'camera_api_url');
    final cachedEmail = await _storage.read(key: 'camera_email');
    final cachedPassword = await _storage.read(key: 'camera_password');
    final cachedBabyId = await _storage.read(key: 'camera_baby_id');
    final cachedToken = await _storage.read(key: 'camera_token');

    if (cachedUrl != null) _apiUrlController.text = cachedUrl;
    if (cachedEmail != null) _emailController.text = cachedEmail;
    if (cachedPassword != null) _passwordController.text = cachedPassword;
    
    if (mounted) {
      setState(() {
        _selectedBabyId = cachedBabyId;
      });
    }

    if (cachedToken != null && cachedUrl != null) {
      // Proactively fetch babies list to populate dropdown
      _fetchBabiesList(cachedUrl, cachedToken);
    }
  }

  Future<void> _loginAndFetchBabies() async {
    final url = _apiUrlController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (url.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _settingsError = 'Please fill out all fields.';
      });
      return;
    }

    setState(() {
      _isSettingsLoading = true;
      _settingsError = null;
    });

    try {
      final apiUrl = SocketService.sanitizeApiUrl(url);

      // 1. Authenticate with Backend
      final loginResponse = await http.post(
        Uri.parse('$apiUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final loginJson = jsonDecode(loginResponse.body);
      if (loginResponse.statusCode != 200 || loginJson['success'] != true) {
        throw Exception(loginJson['message'] ?? 'Authentication failed.');
      }

      final accessToken = loginJson['data']['accessToken'] as String;
      final refreshToken = loginJson['data']['refreshToken'] as String;

      // Cache credentials
      await _storage.write(key: 'camera_api_url', value: url);
      await _storage.write(key: 'camera_email', value: email);
      await _storage.write(key: 'camera_password', value: password);
      await _storage.write(key: 'camera_token', value: accessToken);
      await _storage.write(key: 'camera_refresh_token', value: refreshToken);

      // 2. Fetch Authorized Babies List
      await _fetchBabiesList(url, accessToken);

      _showSnackBar('Authenticated successfully!');
    } catch (e) {
      setState(() {
        _settingsError = e.toString().replaceAll('Exception:', '');
      });
    } finally {
      setState(() {
        _isSettingsLoading = false;
      });
    }
  }

  Future<void> _fetchBabiesList(String url, String token) async {
    try {
      final apiUrl = SocketService.sanitizeApiUrl(url);
      final babiesResponse = await http.get(
        Uri.parse('$apiUrl/babies'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final babiesJson = jsonDecode(babiesResponse.body);
      if (babiesResponse.statusCode != 200 || babiesJson['success'] != true) {
        throw Exception(babiesJson['message'] ?? 'Failed to retrieve babies.');
      }

      final list = babiesJson['data'] as List<dynamic>;
      setState(() {
        _babiesList = list;
        if (list.isNotEmpty) {
          // If previous selection isn't in the list, set to first item
          final containsPrev = list.any((b) => b['id'] == _selectedBabyId);
          if (!containsPrev) {
            _selectedBabyId = list.first['id'] as String;
          }
        } else {
          _selectedBabyId = null;
          _settingsError = 'No babies assigned to this parent account.';
        }
      });

      if (_selectedBabyId != null) {
        await _storage.write(key: 'camera_baby_id', value: _selectedBabyId);
      }
    } catch (e) {
      setState(() {
        _settingsError = 'Failed to fetch babies: $e';
      });
    }
  }

  Future<void> _startStreaming() async {
    // 1. Check/request permissions
    final permsGranted = await PermissionService.requestCameraAndMicrophone();
    if (!permsGranted) {
      _showSnackBar('Camera and Microphone permissions are required to stream.', isError: true);
      return;
    }

    final url = _apiUrlController.text.trim();
    final babyId = _selectedBabyId;

    if (url.isEmpty || babyId == null) {
      _showSnackBar('Please open Settings and authenticate before starting stream.', isError: true);
      _openSettingsModal();
      return;
    }

    try {
      // Start local viewfinder
      await _webrtcService.startLocalStream();

      // Connect signaling Socket.IO client (refreshes if needed)
      final connected = await _socketService.connect(url, babyId);
      if (!connected) {
        throw Exception('Signaling connection failed. Access token might be invalid or expired.');
      }

      // Transition WebRTC service to publishing/streaming mode
      await _webrtcService.startStreaming(babyId);

      _showSnackBar('Streaming initialized successfully.');
    } catch (e) {
      _showSnackBar('Streaming start failed: $e', isError: true);
      _webrtcService.stopStreaming();
      _socketService.disconnect();
    }
  }

  Future<void> _stopStreaming() async {
    try {
      await _webrtcService.stopStreaming();
      _socketService.disconnect();
      _showSnackBar('Streaming stopped.');
    } catch (e) {
      _showSnackBar('Error stopping stream: $e', isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _openSettingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Server Settings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white60),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 16),

                    if (_settingsError != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          border: Border.all(color: AppColors.error.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _settingsError!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // API URL
                    const Text(
                      'API Backend URL',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _apiUrlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black26,
                        hintText: 'e.g. http://192.168.1.100:3000',
                        hintStyle: const TextStyle(color: Colors.white24),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email
                    const Text(
                      'Parent Email',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black26,
                        hintText: 'parent@example.com',
                        hintStyle: const TextStyle(color: Colors.white24),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    const Text(
                      'Password',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Auth Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSettingsLoading
                            ? null
                            : () async {
                                await _loginAndFetchBabies();
                                setModalState(() {});
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isSettingsLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Login & Fetch Babies', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Baby Selector Dropdown
                    if (_babiesList.isNotEmpty) ...[
                      const Text(
                        'Target Baby Room',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedBabyId,
                            dropdownColor: AppColors.cardBg,
                            isExpanded: true,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            items: _babiesList.map<DropdownMenuItem<String>>((baby) {
                              return DropdownMenuItem<String>(
                                value: baby['id'],
                                child: Text("${baby['name']} (${baby['gender']})"),
                              );
                            }).toList(),
                            onChanged: (val) async {
                              setState(() {
                                _selectedBabyId = val;
                              });
                              setModalState(() {});
                              if (val != null) {
                                await _storage.write(key: 'camera_baby_id', value: val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'MAATRIVA Camera',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
            onPressed: _openSettingsModal,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Camera Preview Box
              CameraPreviewWidget(webrtcService: _webrtcService),
              const SizedBox(height: 12),

              // 2. Camera Toggle Controls
              Align(
                alignment: Alignment.centerRight,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _webrtcService.isStreamingNotifier,
                  builder: (context, isStreaming, child) {
                    return TextButton.icon(
                      icon: const Icon(Icons.flip_camera_android_rounded, color: AppColors.primary),
                      label: const Text(
                        'Switch Camera',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        try {
                          await _webrtcService.toggleCamera();
                        } catch (e) {
                          _showSnackBar('Failed to toggle camera: $e', isError: true);
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // 3. Connection Status Card
              StatusCardWidget(
                socketService: _socketService,
                webrtcService: _webrtcService,
              ),
              const SizedBox(height: 24),

              // 4. Control Buttons (Start / Stop)
              ValueListenableBuilder<bool>(
                valueListenable: _webrtcService.isStreamingNotifier,
                builder: (context, isStreaming, child) {
                  return ControlButtonsWidget(
                    isStreaming: isStreaming,
                    onStart: _startStreaming,
                    onStop: _stopStreaming,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
