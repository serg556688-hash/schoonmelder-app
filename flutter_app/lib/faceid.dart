import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import 'data.dart';

const Map<String, Map<String, String>> _fid = <String, Map<String, String>>{
  'nl': <String, String>{
    'fidReason': 'Log in bij Schoonmelder',
    'fidButton': 'Inloggen met Face ID',
    'fidFailed': 'Niet herkend. Probeer opnieuw of tik op Inloggen.',
  },
  'en': <String, String>{
    'fidReason': 'Sign in to Schoonmelder',
    'fidButton': 'Sign in with Face ID',
    'fidFailed': 'Not recognised. Try again or tap Sign in.',
  },
  'ru': <String, String>{
    'fidReason': 'Вход в Schoonmelder',
    'fidButton': 'Войти по Face ID',
    'fidFailed': 'Не распознано. Попробуйте ещё раз или нажмите «Войти».',
  },
  'ar': <String, String>{
    'fidReason': 'تسجيل الدخول إلى Schoonmelder',
    'fidButton': 'الدخول عبر Face ID',
    'fidFailed': 'لم يتم التعرف. حاول مجدداً أو اضغط دخول.',
  },
};

String fid(String key) => _fid[I18n.lang.value]?[key] ?? _fid['en']?[key] ?? key;

final LocalAuthentication _auth = LocalAuthentication();

/// True when the phone can check the face (or fingerprint / passcode).
Future<bool> biometricAvailable() async {
  try {
    return await _auth.isDeviceSupported();
  } catch (_) {
    return false;
  }
}

/// Asks the phone to recognise the owner (Face ID, fingerprint or passcode).
Future<bool> biometricUnlock() async {
  try {
    return await _auth.authenticate(
      localizedReason: fid('fidReason'),
      options: const AuthenticationOptions(stickyAuth: true),
    );
  } catch (_) {
    return false;
  }
}

/// Wraps the "welcome back" screen: as soon as it appears, Face ID is
/// asked; when the face is recognised the app opens without typing
/// anything. Also offers a big Face ID button to try again.
class FaceIdUnlock extends StatefulWidget {
  const FaceIdUnlock({super.key, required this.onUnlocked, required this.builder});

  final VoidCallback onUnlocked;

  /// Builds the screen; gets the Face ID button to place in it (or null
  /// when the phone has no Face ID / fingerprint).
  final Widget Function(BuildContext context, Widget? faceIdButton) builder;

  @override
  State<FaceIdUnlock> createState() => _FaceIdUnlockState();
}

class _FaceIdUnlockState extends State<FaceIdUnlock> {
  bool _available = false;
  bool _busy = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final bool ok = await biometricAvailable();
    if (!mounted) return;
    setState(() => _available = ok);
    if (ok) await _unlock();
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    final bool ok = await biometricUnlock();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failed = !ok;
    });
    if (ok) widget.onUnlocked();
  }

  Widget _button() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        GestureDetector(
          onTap: _unlock,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFF3A3A44), Color(0xFF15151B)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const <BoxShadow>[
                BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Icon(Icons.face_retouching_natural, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Text(
                  fid('fidButton'),
                  style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        if (_failed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              fid('fidFailed'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: C.danger),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _available ? _button() : null);
  }
}
