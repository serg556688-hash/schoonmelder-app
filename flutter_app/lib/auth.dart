import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data.dart';
import 'widgets.dart';

// ---------------------------------------------------------------- language button

class LangButton extends StatelessWidget {
  const LangButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Language',
      onSelected: (String code) => I18n.setLang(code),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (BuildContext ctx) => langOptions
          .map(
            (LangOption o) => PopupMenuItem<String>(
              value: o.code,
              child: Row(
                children: <Widget>[
                  Text(o.flag, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Text(
                    o.label,
                    style: TextStyle(
                      fontSize: 14,
                      color: C.ink,
                      fontWeight: o.code == I18n.lang.value ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[C.accent, C.accentDark],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(color: Color(0x73FF6A1A), blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: const Icon(Icons.language, color: Colors.white, size: 20),
      ),
    );
  }
}

// ---------------------------------------------------------------- shell

/// Orange background with the white card and logo, used by all login screens.
class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.child, this.note});

  final Widget child;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFF7A65A), Color(0xFFEF8423), Color(0xFFE0680A)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(color: Color(0x33803A00), blurRadius: 40, offset: Offset(0, 18)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: LangButton(),
                          ),
                          Image.asset('assets/logo.jpeg', height: 150, fit: BoxFit.contain),
                          const SizedBox(height: 12),
                          child,
                        ],
                      ),
                    ),
                    if (note != null) ...<Widget>[
                      const SizedBox(height: 16),
                      Text(
                        note!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleChoice extends StatelessWidget {
  const _RoleChoice({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  Widget _option(String id, String label, IconData icon) {
    final bool active = value == id;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
          decoration: BoxDecoration(
            color: active ? C.accentSoft : C.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? C.accent : C.border, width: active ? 1.5 : 1),
          ),
          child: Column(
            children: <Widget>[
              Icon(icon, color: active ? C.accent : C.muted, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: active ? C.accentDark : C.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _option('reporter', tr('roleReporter'), Icons.photo_camera_outlined),
        const SizedBox(width: 8),
        _option('executor', tr('roleExecutor'), Icons.cleaning_services_outlined),
      ],
    );
  }
}

// ---------------------------------------------------------------- login / register

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _signup = false;
  String _role = '';
  bool _busy = false;
  String _error = '';
  String _info = '';
  bool _checkEmail = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String email = _email.text.trim();
    final String password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = tr('fillFieldsError'));
      return;
    }
    if (password.length < 6) {
      setState(() => _error = tr('passwordShort'));
      return;
    }
    if (_signup && _role.isEmpty) {
      setState(() => _error = tr('chooseRolePh'));
      return;
    }
    setState(() {
      _busy = true;
      _error = '';
      _info = '';
    });
    try {
      if (_signup) {
        final AuthResponse res = await db.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: webAppUrl,
          data: <String, dynamic>{'role': _role},
        );
        final User? user = res.user;
        if (user != null && user.identities != null && user.identities!.isEmpty) {
          throw AuthException('already registered');
        }
        if (res.session != null && user != null) {
          try {
            await db.from('profiles').insert(<String, dynamic>{
              'id': user.id,
              'role': _role,
              'name': '',
              'phone': '',
              'vehicle': 'foot',
              'withdrawn_cents': 0,
              'created_at': nowMs(),
            });
          } catch (_) {}
        } else if (mounted) {
          setState(() => _checkEmail = true);
        }
      } else {
        await db.auth.signInWithPassword(email: email, password: password);
      }
    } catch (e) {
      if (mounted) setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    final String email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = tr('fillFieldsError'));
      return;
    }
    setState(() {
      _busy = true;
      _error = '';
      _info = '';
    });
    try {
      await db.auth.resetPasswordForEmail(email, redirectTo: webAppUrl);
      if (mounted) setState(() => _info = '${tr('resetSent')} ${tr('confirmOnWeb')}');
    } catch (e) {
      if (mounted) setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _oauth(String provider) {
    setState(() {
      _info = '';
      _error = tr('oauthUnavailable').replaceAll('{p}', provider);
    });
  }

  Widget _tab(String label, bool signup) {
    final bool active = _signup == signup;
    void pick() => setState(() {
          _signup = signup;
          _error = '';
          _info = '';
        });
    return Expanded(
      child: active
          ? PrimaryButton(label: label, onTap: pick)
          : SecondaryButton(label: label, onTap: pick),
    );
  }

  Widget _socialButton(String label, Widget leading, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: C.ink,
          side: const BorderSide(color: C.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            leading,
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkEmail) {
      return AuthShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(tr('checkEmailTitle'), textAlign: TextAlign.center, style: titleStyle),
            const SizedBox(height: 8),
            Text(
              tr('checkEmailNote').replaceAll('{email}', _email.text.trim()),
              textAlign: TextAlign.center,
              style: metaStyle,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: tr('alreadyConfirmedBtn'),
              onTap: () => setState(() {
                _checkEmail = false;
                _signup = false;
              }),
            ),
          ],
        ),
      );
    }
    return AuthShell(
      note: tr('authDemoNote'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              _tab(tr('signInTab'), false),
              const SizedBox(width: 8),
              _tab(tr('signUpTab'), true),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            decoration: smInput(tr('emailPh')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _password,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: smInput(tr('passwordPh')),
          ),
          if (_signup) ...<Widget>[
            const SizedBox(height: 12),
            Text(tr('chooseRoleLabel'), style: subTitleStyle),
            const SizedBox(height: 8),
            _RoleChoice(value: _role, onChanged: (String r) => setState(() => _role = r)),
          ],
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_error, style: const TextStyle(color: C.danger, fontSize: 13)),
            ),
          if (_info.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_info, style: const TextStyle(color: C.success, fontSize: 13)),
            ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: _busy ? tr('pleaseWaitBtn') : (_signup ? tr('signUpBtn') : tr('signInBtn')),
            busy: _busy,
            onTap: _submit,
          ),
          if (!_signup)
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: _busy ? null : _reset,
                child: Text(
                  tr('resetPw'),
                  style: const TextStyle(color: C.accentDark, fontSize: 13),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: <Widget>[
                const Expanded(child: Divider(color: C.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(tr('orDividerText'), style: metaStyle),
                ),
                const Expanded(child: Divider(color: C.border)),
              ],
            ),
          ),
          _socialButton(
            tr('continueGoogle'),
            const Text(
              'G',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF4285F4)),
            ),
            () => _oauth('Google'),
          ),
          _socialButton(
            tr('continueApple'),
            const Icon(Icons.apple, size: 20, color: Colors.black),
            () => _oauth('Apple'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- role setup

/// Shown when an account exists but has no profile row yet.
class RoleSetupScreen extends StatefulWidget {
  const RoleSetupScreen({super.key, required this.user, required this.onDone});

  final User user;
  final ValueChanged<Map<String, dynamic>> onDone;

  @override
  State<RoleSetupScreen> createState() => _RoleSetupScreenState();
}

class _RoleSetupScreenState extends State<RoleSetupScreen> {
  String _role = '';
  bool _busy = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    final dynamic meta = widget.user.userMetadata?['role'];
    if (meta == 'reporter' || meta == 'executor') {
      _role = meta as String;
      WidgetsBinding.instance.addPostFrameCallback((_) => _save());
    }
  }

  Future<void> _save() async {
    if (_role.isEmpty) {
      setState(() => _error = tr('chooseRolePh'));
      return;
    }
    setState(() {
      _busy = true;
      _error = '';
    });
    final Map<String, dynamic> row = <String, dynamic>{
      'id': widget.user.id,
      'role': _role,
      'name': '',
      'phone': '',
      'vehicle': 'foot',
      'withdrawn_cents': 0,
      'created_at': nowMs(),
    };
    try {
      await db.from('profiles').insert(row);
      widget.onDone(row);
    } catch (e) {
      try {
        final Map<String, dynamic>? existing =
            await db.from('profiles').select().eq('id', widget.user.id).maybeSingle();
        if (existing != null) {
          widget.onDone(existing);
          return;
        }
      } catch (_) {}
      if (mounted) setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      note: tr('roleSetupNote'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(tr('roleSetupTitle'), textAlign: TextAlign.center, style: titleStyle),
          const SizedBox(height: 12),
          _RoleChoice(value: _role, onChanged: (String r) => setState(() => _role = r)),
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_error, style: const TextStyle(color: C.danger, fontSize: 13)),
            ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: _busy ? tr('savingBtn') : tr('confirmBtn'),
            busy: _busy,
            onTap: _save,
          ),
          TextButton(
            onPressed: () => db.auth.signOut(),
            child: Text(tr('signOutBtn'), style: const TextStyle(color: C.muted)),
          ),
        ],
      ),
    );
  }
}
