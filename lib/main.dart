import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fingerprint Auth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FingerprintAuthScreen(),
    );
  }
}

class FingerprintAuthScreen extends StatefulWidget {
  const FingerprintAuthScreen({super.key});

  @override
  State<FingerprintAuthScreen> createState() => _FingerprintAuthScreenState();
}

class _FingerprintAuthScreenState extends State<FingerprintAuthScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];
  String _authorized = 'Not Authorized';
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    bool canCheckBiometrics;
    try {
      canCheckBiometrics = await _localAuth.canCheckBiometrics;
    } on PlatformException catch (e) {
      canCheckBiometrics = false;
      debugPrint('Error checking biometrics: $e');
    }
    if (!mounted) return;

    setState(() {
      _canCheckBiometrics = canCheckBiometrics;
    });

    if (canCheckBiometrics) {
      _getAvailableBiometrics();
    }
  }

  Future<void> _getAvailableBiometrics() async {
    List<BiometricType> availableBiometrics;
    try {
      availableBiometrics = await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      availableBiometrics = [];
      debugPrint('Error getting biometrics: $e');
    }
    if (!mounted) return;

    setState(() {
      _availableBiometrics = availableBiometrics;
    });
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
        _authorized = 'Authenticating...';
      });
      
      authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan your fingerprint to authenticate',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      
      setState(() {
        _isAuthenticating = false;
      });
    } on PlatformException catch (e) {
      debugPrint('Authentication error: $e');
      setState(() {
        _isAuthenticating = false;
        _authorized = 'Error: ${e.message}';
      });
      return;
    }
    if (!mounted) return;

    setState(() {
      _authorized = authenticated ? 'Authorized ✅' : 'Not Authorized ❌';
    });
  }

  Future<void> _cancelAuthentication() async {
    await _localAuth.stopAuthentication();
    setState(() {
      _isAuthenticating = false;
      _authorized = 'Authentication canceled';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fingerprint Authentication'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fingerprint, size: 80, color: Colors.blue),
            const SizedBox(height: 30),
            Text(
              'Biometrics available: ${_canCheckBiometrics ? 'Yes' : 'No'}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Supported methods: ${_availableBiometrics.join(", ")}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            Text(
              'Status: $_authorized',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            if (_isAuthenticating)
              ElevatedButton(
                onPressed: _cancelAuthentication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('CANCEL AUTHENTICATION'),
              )
            else
              ElevatedButton(
                onPressed: _authenticate,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('AUTHENTICATE WITH FINGERPRINT'),
              ),
          ],
        ),
      ),
    );
  }
}