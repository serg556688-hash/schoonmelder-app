import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth.dart';
import 'data.dart';
import 'home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  await I18n.load();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const SchoonmelderApp());
}

class SchoonmelderApp extends StatelessWidget {
  const SchoonmelderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: I18n.lang,
      builder: (BuildContext context, String lang, Widget? _) {
        return MaterialApp(
          title: 'Schoonmelder',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: C.accent,
              primary: C.accent,
              surface: C.surface,
            ),
            scaffoldBackgroundColor: C.bg,
          ),
          builder: (BuildContext context, Widget? child) {
            return Directionality(
              textDirection: I18n.isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: Root(key: const ValueKey<String>('root'), lang: lang),
        );
      },
    );
  }
}

/// Decides what to show: login, role choice or the app itself,
/// and keeps the profile and the list of reports up to date.
class Root extends StatefulWidget {
  const Root({super.key, required this.lang});

  /// Only here so the whole tree rebuilds when the language changes.
  final String lang;

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> with WidgetsBindingObserver {
  StreamSubscription<AuthState>? _authSub;
  Timer? _poll;
  Session? _session;
  Profile? _profile;
  bool _profileLoading = false;
  List<Report> _reports = <Report>[];
  bool _dbError = false;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _session = db.auth.currentSession;
    if (_session != null) _onSignedIn();
    _authSub = db.auth.onAuthStateChange.listen((AuthState state) {
      final Session? next = state.session;
      final String? before = _session?.user.id;
      final String? after = next?.user.id;
      if (!mounted) return;
      setState(() => _session = next);
      if (after != before) {
        if (next == null) {
          _onSignedOut();
        } else {
          _onSignedIn();
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    _poll?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _session != null) {
      _fetchReports();
    }
  }

  void _onSignedOut() {
    _poll?.cancel();
    _poll = null;
    setState(() {
      _profile = null;
      _reports = <Report>[];
      _profileLoading = false;
      _dbError = false;
    });
  }

  Future<void> _onSignedIn() async {
    final String? id = _session?.user.id;
    if (id == null) return;
    if (mounted) setState(() => _profileLoading = true);
    Profile? loaded;
    try {
      final Map<String, dynamic>? row =
          await db.from('profiles').select().eq('id', id).maybeSingle();
      if (row != null) loaded = Profile(row);
    } catch (_) {
      loaded = null;
    }
    if (!mounted || _session?.user.id != id) return;
    setState(() {
      _profile = loaded;
      _profileLoading = false;
    });
    _poll?.cancel();
    _fetchReports();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _fetchReports());
  }

  Future<void> _fetchReports() async {
    if (_fetching || _session == null) return;
    _fetching = true;
    try {
      final List<Map<String, dynamic>> data =
          await db.from('reports').select().order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _reports = data.map((Map<String, dynamic> r) => Report(r)).toList();
        _dbError = false;
      });
    } catch (_) {
      if (mounted) setState(() => _dbError = true);
    } finally {
      _fetching = false;
    }
  }

  Future<void> _addReport(Map<String, dynamic> row) async {
    final String? me = _session?.user.id;
    final Map<String, dynamic> full = Map<String, dynamic>.from(row);
    if (me != null) full['reporter_id'] = me;
    setState(() => _reports = <Report>[Report(full), ..._reports]);
    try {
      await db.from('reports').insert(full);
      if (mounted) setState(() => _dbError = false);
    } catch (_) {
      if (mounted) setState(() => _dbError = true);
    }
  }

  Future<void> _patchReport(String id, Map<String, dynamic> dbPatch) async {
    final String? me = _session?.user.id;
    final Map<String, dynamic> patch = Map<String, dynamic>.from(dbPatch);
    if (patch['status'] == Status.inProgress && me != null) {
      patch['executor_id'] = me;
    }
    setState(() {
      _reports = _reports.map((Report r) => r.id == id ? r.patched(patch) : r).toList();
    });
    try {
      await db.from('reports').update(patch).eq('id', id);
      if (mounted) setState(() => _dbError = false);
    } catch (_) {
      if (mounted) setState(() => _dbError = true);
    }
  }

  Future<void> _saveProfile(Map<String, dynamic> patch) async {
    final String? me = _session?.user.id;
    final Profile? current = _profile;
    if (me == null || current == null) return;
    setState(() => _profile = current.patched(patch));
    try {
      await db.from('profiles').update(patch).eq('id', me);
    } catch (_) {}
  }

  Future<void> _signOut() async {
    try {
      await db.auth.signOut();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final Session? session = _session;
    if (session == null) {
      return const AuthScreen();
    }
    if (_profileLoading) {
      return const Scaffold(
        backgroundColor: C.bg,
        body: Center(child: CircularProgressIndicator(color: C.accent)),
      );
    }
    final Profile? profile = _profile;
    if (profile == null) {
      return RoleSetupScreen(
        user: session.user,
        onDone: (Map<String, dynamic> row) {
          if (mounted) setState(() => _profile = Profile(row));
        },
      );
    }
    return HomeShell(
      userId: session.user.id,
      profile: profile,
      reports: _reports,
      dbError: _dbError,
      addReport: _addReport,
      patchReport: _patchReport,
      saveProfile: _saveProfile,
      signOut: _signOut,
    );
  }
}
