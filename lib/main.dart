import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BiometricApp());
}

class BiometricApp extends StatelessWidget {
  const BiometricApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fingerprint Auth',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];
  String _authStatus = 'Tap to authenticate';
  bool _isAuthenticating = false;
  bool _isSupported = false;

  @override
  void initState() {
    super.initState();
    _initBiometrics();
  }

  Future<void> _initBiometrics() async {
    try {
      _isSupported = await _auth.isDeviceSupported();
      if (!_isSupported) {
        setState(() => _authStatus = 'Biometrics not supported');
        return;
      }

      _canCheckBiometrics = await _auth.canCheckBiometrics;
      _availableBiometrics = await _auth.getAvailableBiometrics();

      if (!mounted) return;

      setState(() {
        _authStatus =
            _canCheckBiometrics
                ? 'Ready to authenticate'
                : 'No biometrics available';
      });
    } on PlatformException catch (e) {
      setState(() => _authStatus = 'Error: ${e.message}');
    }
  }

  Future<void> _authenticate() async {
    if (!_isSupported || _isAuthenticating) return;

    try {
      setState(() {
        _isAuthenticating = true;
        _authStatus = 'Authenticating...';
      });

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Verify your identity to continue',
        options: const AuthenticationOptions(
          biometricOnly: true,
          sensitiveTransaction: true,
          stickyAuth: true,
        ),
      );

      if (!mounted) return;

      setState(() {
        _isAuthenticating = false;
        _authStatus =
            didAuthenticate
                ? 'Authentication successful! ✅'
                : 'Authentication failed ❌';
      });
    } on PlatformException catch (e) {
      setState(() {
        _isAuthenticating = false;
        _authStatus = 'Error: ${e.message}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fingerprint Authentication'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fingerprint, size: 80, color: Colors.blue),
              const SizedBox(height: 30),
              Text(
                'Device Supported: ${_isSupported ? 'Yes' : 'No'}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                'Available Methods: ${_availableBiometrics.join(", ")}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              Text(
                _authStatus,
                style: TextStyle(
                  fontSize: 20,
                  color:
                      _authStatus.contains('success')
                          ? Colors.green
                          : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child:
                    _isAuthenticating
                        ? ElevatedButton(
                          onPressed: () async {
                            await _auth.stopAuthentication();
                            setState(() {
                              _isAuthenticating = false;
                              _authStatus = 'Authentication canceled';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('CANCEL'),
                        )
                        : ElevatedButton(
                          onPressed: _authenticate,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('AUTHENTICATE'),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
