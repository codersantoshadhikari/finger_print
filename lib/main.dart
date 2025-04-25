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
      debugShowCheckedModeBanner: false,
      title: 'Biometric Auth',
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
  final LocalAuthentication auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];
  String _authStatus = 'Not Authenticated';
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _initBiometrics();
  }

  Future<void> _initBiometrics() async {
    try {
      final bool canAuthenticate = await auth.canCheckBiometrics;
      final List<BiometricType> biometrics =
          await auth.getAvailableBiometrics();

      if (!mounted) return;

      setState(() {
        _canCheckBiometrics = canAuthenticate;
        _availableBiometrics = biometrics;
      });
    } on PlatformException catch (e) {
      debugPrint('Error initializing biometrics: ${e.message}');
    }
  }

  Future<void> _authenticate() async {
    try {
      setState(() {
        _isAuthenticating = true;
        _authStatus = 'Authenticating...';
      });

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Authenticate to access secure content',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!mounted) return;

      setState(() {
        _authStatus =
            didAuthenticate
                ? 'Authenticated Successfully! ✅'
                : 'Authentication Failed ❌';
        _isAuthenticating = false;
      });
    } on PlatformException catch (e) {
      debugPrint('Authentication error: ${e.message}');
      setState(() {
        _authStatus = 'Error: ${e.message}';
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometric Authentication'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fingerprint, size: 80, color: Colors.blue),
              const SizedBox(height: 40),
              Text(
                'Biometrics Supported: ${_canCheckBiometrics ? 'Yes' : 'No'}',
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
                      _authStatus.contains('Success')
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
                            await auth.stopAuthentication();
                            setState(() {
                              _isAuthenticating = false;
                              _authStatus = 'Authentication Canceled';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('CANCEL'),
                        )
                        : ElevatedButton(
                          onPressed: _authenticate,
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
