import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import 'auth.dart';
import 'data.dart';
import 'widgets.dart';

typedef PatchReport = Future<void> Function(String id, Map<String, dynamic> dbPatch);
typedef SaveProfile = Future<void> Function(Map<String, dynamic> patch);

final ImagePicker _picker = ImagePicker();

/// Takes a photo with the camera and returns it in the same small JPEG
/// format the website uses (480 px wide, quality 60).
Future<String?> takePhoto() async {
  final XFile? file = await _picker.pickImage(
    source: ImageSource.camera,
    maxWidth: 480,
    imageQuality: 60,
    preferredCameraDevice: CameraDevice.rear,
  );
  if (file == null) return null;
  final Uint8List bytes = await file.readAsBytes();
  return toDataUrl(bytes);
}

// ---------------------------------------------------------------- shell

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.userId,
    required this.profile,
    required this.reports,
    required this.dbError,
    required this.addReport,
    required this.patchReport,
    required this.saveProfile,
    required this.signOut,
  });

  final String userId;
  final Profile profile;
  final List<Report> reports;
  final bool dbError;
  final Future<void> Function(Map<String, dynamic> row) addReport;
  final PatchReport patchReport;
  final SaveProfile saveProfile;
  final Future<void> Function() signOut;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  String _tab = 'main';

  void _setTab(String t) => setState(() => _tab = t);

  bool get _isReporter => widget.profile.role == 'reporter';

  List<Report> get _mine {
    final String me = widget.userId;
    if (_isReporter) {
      return widget.reports.where((Report r) => r.reporterId == me).toList();
    }
    return widget.reports
        .where((Report r) => r.status == Status.fresh || r.executorId == me)
        .toList();
  }

  int get _earnedCents {
    if (_isReporter) {
      int photos = 0;
      for (final Report r in _mine) {
        photos += r.photos.length;
      }
      return photos * reporterCentReward;
    }
    final int done = widget.reports
        .where((Report r) =>
            r.executorId == widget.userId &&
            (r.status == Status.awaiting || r.status == Status.confirmed))
        .length;
    return done * executorCentReward;
  }

  int get _balanceCents {
    final int b = _earnedCents - widget.profile.withdrawnCents;
    return b < 0 ? 0 : b;
  }

  void _openWithdraw() {
    final int balance = _balanceCents;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) => WithdrawSheet(
        balanceCents: balance,
        onConfirm: () async {
          await widget.saveProfile(<String, dynamic>{
            'withdrawn_cents': widget.profile.withdrawnCents + balance,
          });
        },
      ),
    );
  }

  Widget _body() {
    final List<Report> mine = _mine;
    switch (_tab) {
      case 'history':
        return HistoryView(
          reports: mine,
          role: widget.profile.role,
          patchReport: widget.patchReport,
        );
      case 'money':
        return EarningsView(
          role: widget.profile.role,
          balanceCents: _balanceCents,
          earnedCents: _earnedCents,
          reports: mine,
          onWithdraw: _openWithdraw,
        );
      case 'chat':
        return ChatView(role: widget.profile.role, reports: mine, myId: widget.userId);
      case 'profile':
        return ProfileView(
          profile: widget.profile,
          reports: mine,
          setTab: _setTab,
          saveProfile: widget.saveProfile,
          signOut: widget.signOut,
        );
      default:
        if (_isReporter) {
          return ReporterMain(
            reports: mine,
            addReport: widget.addReport,
            balanceCents: _balanceCents,
            setTab: _setTab,
          );
        }
        return ExecutorMain(
          userId: widget.userId,
          reports: mine,
          patchReport: widget.patchReport,
          profile: widget.profile,
          saveProfile: widget.saveProfile,
          balanceCents: _balanceCents,
          setTab: _setTab,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<_NavItem> items = <_NavItem>[
      _NavItem('main', _isReporter ? tr('navMessages') : tr('navJobs'), Icons.home_outlined),
      _NavItem('history', tr('navHistory'), Icons.assignment_outlined),
      _NavItem(
        'money',
        _isReporter ? tr('navBonus') : tr('navEarnings'),
        Icons.account_balance_wallet_outlined,
      ),
      _NavItem('chat', tr('navChat'), Icons.chat_bubble_outline),
      _NavItem('profile', tr('navProfile'), Icons.person_outline),
    ];
    final int index = items.indexWhere((_NavItem i) => i.id == _tab);
    final bool scrolls = _tab != 'chat';
    // The report form stretches over the whole free height of the screen.
    final bool fills = _tab == 'main' && _isReporter;
    final Widget body = _body();
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Container(
              color: C.surface,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Image.asset(
                          'assets/logo.jpeg',
                          height: 70,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: C.accentSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              _isReporter
                                  ? Icons.photo_camera_outlined
                                  : Icons.cleaning_services_outlined,
                              size: 16,
                              color: C.accentDark,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _isReporter ? tr('roleReporter') : tr('roleExecutor'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: C.accentDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const LangButton(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isReporter ? tr('subReporter') : tr('subExecutor'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: C.muted),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: C.border),
            if (widget.dbError)
              Container(
                width: double.infinity,
                color: const Color(0xFFFDECEA),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                child: Text(
                  tr('dbErrorText'),
                  style: const TextStyle(color: C.danger, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            Expanded(
              child: scrolls
                  ? LayoutBuilder(
                      builder: (BuildContext ctx, BoxConstraints box) {
                        final double free = box.maxHeight - 28;
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                          child: fills
                              ? ConstrainedBox(
                                  constraints: BoxConstraints(minHeight: free > 0 ? free : 0),
                                  child: IntrinsicHeight(child: body),
                                )
                              : body,
                        );
                      },
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                      child: body,
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index < 0 ? 0 : index,
        onTap: (int i) => _setTab(items[i].id),
        type: BottomNavigationBarType.fixed,
        backgroundColor: C.surface,
        selectedItemColor: C.accent,
        unselectedItemColor: C.muted,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: items
            .map((_NavItem i) => BottomNavigationBarItem(icon: Icon(i.icon), label: i.label))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;
}

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.label, required this.cents, required this.onTap});

  final String label;
  final int cents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFF7A65A), Color(0xFFEF8423), Color(0xFFE0680A)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: C.btnShadow, offset: Offset(0, 5)),
            BoxShadow(color: Color(0x4DBE5B12), offset: Offset(0, 14), blurRadius: 28),
          ],
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFFFFF1E3),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatEuro(cents),
                    style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 26),
          ],
        ),
      ),
    );
  }
}

Widget _gap([double h = 12]) => SizedBox(height: h);

// ---------------------------------------------------------------- notices (reporter)

class Notices extends StatefulWidget {
  const Notices({super.key, required this.reports, required this.setTab});

  final List<Report> reports;
  final ValueChanged<String> setTab;

  @override
  State<Notices> createState() => _NoticesState();
}

class _NoticesState extends State<Notices> {
  Timer? _timer;
  Set<String> _flags = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final List<String> ids = widget.reports
        .where((Report r) => r.status == Status.inProgress)
        .map((Report r) => r.id)
        .toList();
    if (ids.isEmpty) {
      if (_flags.isNotEmpty && mounted) setState(() => _flags = <String>{});
      return;
    }
    try {
      final List<Map<String, dynamic>> data = await db
          .from('messages')
          .select('report_id,text')
          .inFilter('report_id', ids)
          .like('text', '[[sm:%');
      final Set<String> next = <String>{};
      for (final Map<String, dynamic> m in data) {
        final String text = (m['text'] ?? '').toString();
        final String rid = (m['report_id'] ?? '').toString();
        if (text.startsWith('[[sm:far:')) {
          next.add('far:$rid');
        } else if (text == '[[sm:onsite]]') {
          next.add(rid);
        }
      }
      if (mounted) setState(() => _flags = next);
    } catch (_) {}
  }

  Widget _box(Color bg, Color border, String text, String button) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.ink),
            ),
          ),
          TextButton(
            onPressed: () => widget.setTab('history'),
            child: Text(button, style: const TextStyle(color: C.accentDark, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  String _withComment(String base, Report r) {
    if (r.comment.isEmpty) return base;
    final String c = r.comment.length > 40 ? r.comment.substring(0, 40) : r.comment;
    return '$base — $c';
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> boxes = <Widget>[];
    for (final Report r in widget.reports) {
      if (r.status == Status.inProgress && _flags.contains('far:${r.id}')) {
        boxes.add(_box(const Color(0xFFFDECEA), const Color(0xFFF1A9A0), tr('evFarShort'), tr('evOpen')));
      }
    }
    for (final Report r in widget.reports) {
      if (r.status == Status.inProgress && _flags.contains(r.id)) {
        boxes.add(_box(
          const Color(0xFFEAF4FF),
          const Color(0xFFB4CBE4),
          _withComment(tr('evOnsite'), r),
          tr('evOpen'),
        ));
      }
    }
    for (final Report r in widget.reports) {
      if (r.status == Status.awaiting) {
        boxes.add(_box(
          const Color(0xFFEAF9EE),
          const Color(0xFF9ED9AE),
          _withComment(tr('evDone'), r),
          tr('evCheck'),
        ));
      }
    }
    if (boxes.isEmpty) return const SizedBox.shrink();
    return Column(children: boxes);
  }
}

// ---------------------------------------------------------------- reporter main

class ReporterMain extends StatefulWidget {
  const ReporterMain({
    super.key,
    required this.reports,
    required this.addReport,
    required this.balanceCents,
    required this.setTab,
  });

  final List<Report> reports;
  final Future<void> Function(Map<String, dynamic> row) addReport;
  final int balanceCents;
  final ValueChanged<String> setTab;

  @override
  State<ReporterMain> createState() => _ReporterMainState();
}

class _ReporterMainState extends State<ReporterMain> {
  final TextEditingController _comment = TextEditingController();
  final List<String> _photos = <String>[];
  final GeoSampler _gps = GeoSampler();

  /// Where the GPS measured the reporter while the photo was taken.
  GeoFix? _fix;

  /// The point that goes into the report (the measured spot, or the moved pin).
  LatLng? _coords;
  bool _manual = false;
  bool _locating = false;
  bool _sending = false;
  bool _sent = false;
  String _error = '';
  bool _geoProblem = false;

  @override
  void dispose() {
    _gps.stop();
    _comment.dispose();
    super.dispose();
  }

  /// Takes the most precise position of the last seconds. The GPS is started
  /// before the camera opens, so it has had time to warm up.
  Future<LatLng?> _locate() async {
    setState(() {
      _locating = true;
      _error = '';
      _geoProblem = false;
    });
    final GeoFix? fix = await _gps.start() ? await _gps.settle() : null;
    _gps.stop();
    final bool approx = fix != null && fix.accuracy > 100 && await Geo.isApproximate();
    if (!mounted) return fix?.at;
    setState(() {
      _locating = false;
      if (fix == null) {
        _error = tr(Geo.lastError);
        _geoProblem = Geo.lastError != 'noLoc';
      } else {
        _fix = fix;
        _coords = fix.at;
        _manual = false;
        if (approx) {
          Geo.lastError = 'geoDeniedApp';
          _error = tr('geoApprox');
          _geoProblem = true;
        }
      }
    });
    return fix?.at;
  }

  Future<void> _addPhoto() async {
    setState(() => _error = '');
    final bool needPlace = _coords == null && !_locating;
    // Warm the GPS up while the camera is open: the place is fixed at the
    // moment of the photo, not when the report is sent.
    if (needPlace) unawaited(_gps.start());
    try {
      final String? photo = await takePhoto();
      if (photo == null || !mounted) {
        if (needPlace) _gps.stop();
        return;
      }
      setState(() {
        if (_photos.length < 3) _photos.add(photo);
      });
      if (needPlace) await _locate();
    } catch (_) {
      if (needPlace) _gps.stop();
      if (mounted) setState(() => _error = tr('photoErrorText'));
    }
  }

  /// Opens the map so the reporter can put the pin exactly on the litter.
  Future<void> _adjustPin() async {
    final GeoFix? fix = _fix;
    final LatLng? at = _coords;
    if (fix == null || at == null) return;
    final LatLng? picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute<LatLng>(
        builder: (BuildContext ctx) => PinPickerPage(
          measured: fix.at,
          start: at,
          accuracyM: fix.accuracy,
        ),
      ),
    );
    if (picked == null || !mounted) return;
    final double movedM = (haversineKm(at, picked) ?? 0) * 1000;
    if (movedM < 1) return;
    setState(() {
      _coords = picked;
      _manual = true;
    });
  }

  Future<void> _submit() async {
    if (_photos.isEmpty || _sending) return;
    LatLng? pos = _coords;
    pos ??= await _locate();
    if (pos == null || !mounted) return;
    final LatLng? home = homeZone(widget.reports);
    if (home != null) {
      final double m = (haversineKm(home, pos) ?? 0) * 1000;
      if (m > homeRadiusM) {
        setState(() => _error = tr('homeFar'));
        return;
      }
    }
    setState(() {
      _error = '';
      _sending = true;
    });
    await widget.addReport(<String, dynamic>{
      'id': uid(),
      'photos': List<String>.from(_photos),
      'lat': pos.latitude,
      'lng': pos.longitude,
      if (_fix != null) 'accuracy_m': _fix!.accuracy.round(),
      'pin_manual': _manual,
      'comment': _comment.text.trim(),
      'created_at': nowMs(),
      'status': Status.fresh,
    });
    if (!mounted) return;
    setState(() {
      _photos.clear();
      _comment.clear();
      _coords = null;
      _fix = null;
      _manual = false;
      _sending = false;
      _sent = true;
    });
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _sent = false);
    });
  }

  /// One square photo place; three of them share the row evenly.
  Widget _slot(int index) {
    Widget inner;
    if (index < _photos.length) {
      inner = Stack(
        children: <Widget>[
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: DataImage(_photos[index]),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _photos.removeAt(index)),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(color: C.ink, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    } else if (index == _photos.length) {
      inner = GestureDetector(
        onTap: _addPhoto,
        child: Container(
          decoration: BoxDecoration(
            color: C.accentSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: C.accent, width: 1.5),
          ),
          child: const Center(
            child: Icon(Icons.add_a_photo_outlined, color: C.accent, size: 30),
          ),
        ),
      );
    } else {
      inner = Container(
        decoration: BoxDecoration(
          color: C.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: C.border),
        ),
        child: const Center(
          child: Icon(Icons.image_outlined, color: C.border, size: 26),
        ),
      );
    }
    return Expanded(
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: index == 0 ? 0 : 10),
        child: AspectRatio(aspectRatio: 1, child: inner),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canSend = _photos.isNotEmpty && !_sending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Notices(reports: widget.reports, setTab: widget.setTab),
        BalanceCard(
          label: tr('balanceBonusLabel'),
          cents: widget.balanceCents,
          onTap: () => widget.setTab('money'),
        ),
        _gap(16),
        if (_sent) ...<Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(color: C.successSoft, borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.check, size: 16, color: C.success),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    tr('sentBanner'),
                    style: const TextStyle(color: C.success, fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                ),
              ],
            ),
          ),
          _gap(),
        ],
        Expanded(
          child: SmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(tr('reportFormTitle'), style: titleStyle),
              _gap(10),
              Row(
                children: <Widget>[
                  for (int i = 0; i < 3; i++) _slot(i),
                ],
              ),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(_error, style: const TextStyle(color: C.danger, fontSize: 12.5)),
                      if (_geoProblem)
                        TextButton(
                          onPressed: Geo.openSettings,
                          child: Text(
                            tr('openSettings'),
                            style: const TextStyle(color: C.accentDark, fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                ),
              if (_coords != null && !_locating)
                PlaceLine(
                  coords: _coords!,
                  open: true,
                  accuracyM: _fix?.accuracy,
                  manual: _manual,
                  onAdjust: _adjustPin,
                )
              else
                InkWell(
                  onTap: _locating ? null : _locate,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.location_on, size: 17, color: C.accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _locating
                                ? tr('locating')
                                : (_photos.isNotEmpty ? tr('tapRetry') : tr('locationPending')),
                            style: metaStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              _gap(),
              Text(tr('commentLabel'), style: subTitleStyle),
              _gap(8),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 96),
                  child: TextField(
                    controller: _comment,
                    expands: true,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: smInput(tr('commentPlaceholder')),
                  ),
                ),
              ),
              _gap(),
              PrimaryButton(
                label: _sending ? tr('submitBtnBusy') : tr('submitBtn'),
                busy: _sending,
                onTap: canSend ? _submit : null,
              ),
              if (_photos.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(tr('needPhotoHint'), textAlign: TextAlign.center, style: metaStyle),
                ),
            ],
          ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- executor main

class ExecutorMain extends StatefulWidget {
  const ExecutorMain({
    super.key,
    required this.userId,
    required this.reports,
    required this.patchReport,
    required this.profile,
    required this.saveProfile,
    required this.balanceCents,
    required this.setTab,
  });

  final String userId;
  final List<Report> reports;
  final PatchReport patchReport;
  final Profile profile;
  final SaveProfile saveProfile;
  final int balanceCents;
  final ValueChanged<String> setTab;

  @override
  State<ExecutorMain> createState() => _ExecutorMainState();
}

class _ExecutorMainState extends State<ExecutorMain> {
  /// Per report: 'route' (on the way) or 'onsite' (arrived).
  final Map<String, String> _stage = <String, String>{};
  StreamSubscription<Position>? _watch;
  LatLng? _me;
  bool _locating = false;
  int _lastSentAt = 0;
  String _busyId = '';

  List<Report> get _active => widget.reports
      .where((Report r) => r.status == Status.fresh || r.status == Status.inProgress)
      .toList();

  List<String> get _myRunningIds => widget.reports
      .where((Report r) => r.status == Status.inProgress && r.executorId == widget.userId)
      .map((Report r) => r.id)
      .toList();

  @override
  void initState() {
    super.initState();
    _syncStages();
    if (_myRunningIds.isNotEmpty) {
      _startWatch();
    }
  }

  @override
  void didUpdateWidget(covariant ExecutorMain oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncStages();
    if (_myRunningIds.isEmpty) {
      _stopWatch();
    } else if (_watch == null) {
      _startWatch();
    }
  }

  @override
  void dispose() {
    _stopWatch();
    super.dispose();
  }

  void _syncStages() {
    for (final String id in _myRunningIds) {
      _stage.putIfAbsent(id, () => 'route');
    }
  }

  Future<void> _startWatch() async {
    if (_watch != null) return;
    final Stream<Position>? stream = await Geo.watch();
    if (stream == null || !mounted || _watch != null) return;
    _watch = stream.listen(
      (Position p) {
        Geo.remember(p);
        final LatLng here = LatLng(p.latitude, p.longitude);
        if (mounted) setState(() => _me = here);
        final int now = nowMs();
        if (now - _lastSentAt > 6000) {
          _lastSentAt = now;
          for (final String id in _myRunningIds) {
            widget.patchReport(id, <String, dynamic>{
              'executor_lat': here.latitude,
              'executor_lng': here.longitude,
              'executor_updated_at': now,
            });
          }
        }
      },
      onError: (Object _) {},
    );
  }

  void _stopWatch() {
    _watch?.cancel();
    _watch = null;
  }

  Future<void> _accept(Report r) async {
    setState(() {
      _stage[r.id] = 'route';
      _busyId = r.id;
    });
    await widget.patchReport(r.id, <String, dynamic>{'status': Status.inProgress});
    if (!mounted) return;
    setState(() => _busyId = '');
    if (_me == null && !_locating) {
      setState(() => _locating = true);
      final LatLng? pos = await Geo.getLocation();
      if (!mounted) return;
      setState(() {
        _me = pos ?? _me;
        _locating = false;
      });
      if (pos == null) {
        await showInfo(context, tr(Geo.lastError), settings: Geo.lastError != 'noLoc');
      }
    }
    _startWatch();
  }

  Future<void> _finish(Report r) async {
    if (_busyId.isNotEmpty) return;
    String? photo;
    try {
      photo = await takePhoto();
    } catch (_) {
      if (mounted) await showInfo(context, tr('photoErrorText'));
      return;
    }
    if (photo == null || !mounted) return;
    setState(() => _busyId = r.id);
    final LatLng? pos = await Geo.getLocation();
    if (!mounted) return;
    if (pos == null) {
      setState(() => _busyId = '');
      await showInfo(context, tr(Geo.lastError), settings: Geo.lastError != 'noLoc');
      return;
    }
    // The "after" photo is never refused because of GPS: a spot that does not
    // match is only flagged on the report, so the reporter can check it.
    final LatLng? target = r.coords;
    if (target != null) {
      final int meters = ((haversineKm(target, pos) ?? 0) * 1000).round();
      if (meters > geoVerifyThresholdM) smEvent(r.id, 'far:$meters');
    }
    await widget.patchReport(r.id, <String, dynamic>{
      'status': Status.awaiting,
      'completion_photo': photo,
      'completion_lat': pos.latitude,
      'completion_lng': pos.longitude,
      'completed_at': nowMs(),
    });
    smEvent(r.id, 'done');
    if (!mounted) return;
    setState(() {
      _busyId = '';
      _stage.remove(r.id);
    });
  }

  Widget _vehiclePicker() {
    return Row(
      children: <Widget>[
        for (int i = 0; i < vehicles.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => widget.saveProfile(<String, dynamic>{'vehicle': vehicles[i].id}),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                decoration: BoxDecoration(
                  color: widget.profile.vehicle == vehicles[i].id ? C.accentSoft : C.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.profile.vehicle == vehicles[i].id ? C.accent : C.border,
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Icon(
                      vehicles[i].icon,
                      size: 19,
                      color: widget.profile.vehicle == vehicles[i].id ? C.accent : C.muted,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tr(vehicles[i].labelKey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, color: C.ink),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _actions(Report r) {
    final String? stage = _stage[r.id];
    final bool busy = _busyId == r.id;
    if (r.status == Status.fresh && stage == null) {
      return <Widget>[
        _gap(),
        PrimaryButton(
          label: busy ? tr('pleaseWaitBtn') : tr('acceptJobBtn'),
          busy: busy,
          onTap: () => _accept(r),
        ),
      ];
    }
    if (stage == 'onsite') {
      return <Widget>[
        _gap(),
        PrimaryButton(
          label: busy ? tr('pleaseWaitBtn') : tr('imDoneBtn'),
          icon: Icons.add_a_photo_outlined,
          busy: busy,
          onTap: () => _finish(r),
        ),
      ];
    }
    return <Widget>[
      _gap(),
      RouteView(
        from: _me,
        to: r.coords,
        locating: _locating,
        vehicle: widget.profile.vehicle,
        onArrived: () {
          smEvent(r.id, 'onsite');
          setState(() => _stage[r.id] = 'onsite');
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final List<Report> active = _active;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        BalanceCard(
          label: tr('balanceIncomeLabel'),
          cents: widget.balanceCents,
          onTap: () => widget.setTab('money'),
        ),
        _gap(16),
        SmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(tr('vehicleTitle'), style: subTitleStyle),
              _gap(8),
              _vehiclePicker(),
            ],
          ),
        ),
        _gap(),
        Text('${tr('newJobsTitle')} (${active.length})', style: subTitleStyle),
        _gap(8),
        if (active.isEmpty) Text(tr('noNewJobs'), style: metaStyle),
        for (final Report r in active) ...<Widget>[
          ReportCard(
            key: ValueKey<String>('job-${r.id}'),
            report: r,
            priceCents: executorCentReward,
            hideLive: true,
            children: _actions(r),
          ),
          _gap(),
        ],
      ],
    );
  }
}

class RouteView extends StatefulWidget {
  const RouteView({
    super.key,
    required this.from,
    required this.to,
    required this.locating,
    required this.vehicle,
    required this.onArrived,
  });

  final LatLng? from;
  final LatLng? to;
  final bool locating;
  final String vehicle;
  final VoidCallback onArrived;

  @override
  State<RouteView> createState() => _RouteViewState();
}

class _RouteViewState extends State<RouteView> {
  double? _routeKm;

  @override
  Widget build(BuildContext context) {
    final double? km = _routeKm ?? haversineKm(widget.from, widget.to);
    final int? minutes = km != null ? estimateMinutes(km, widget.vehicle) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SmMap(
          points: <MapPoint>[
            if (widget.from != null) MapPoint('me', widget.from!),
            if (widget.to != null) MapPoint('trash', widget.to!),
          ],
          routeFrom: widget.from,
          routeTo: widget.to,
          profile: routeProfileFor(widget.vehicle),
          onRouteKm: (double v) {
            if (mounted) setState(() => _routeKm = v);
          },
        ),
        _gap(10),
        Row(
          children: <Widget>[
            StatPair(
              value: widget.locating ? '…' : (km != null ? '${km.toStringAsFixed(1)} km' : '—'),
              label: tr('distanceLabel'),
            ),
            const SizedBox(width: 24),
            StatPair(
              value: widget.locating ? '…' : (minutes != null ? '$minutes min' : '—'),
              label: tr('etaLabel'),
            ),
          ],
        ),
        _gap(),
        Row(
          children: <Widget>[
            Expanded(
              child: SecondaryButton(
                label: tr('openNavBtn'),
                icon: Icons.navigation_outlined,
                onTap: widget.to == null ? null : () => openGoogleMaps(widget.to!),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: PrimaryButton(label: tr('imHereBtn'), onTap: widget.onArrived)),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- history

class HistoryView extends StatelessWidget {
  const HistoryView({super.key, required this.reports, required this.role, required this.patchReport});

  final List<Report> reports;
  final String role;
  final PatchReport patchReport;

  @override
  Widget build(BuildContext context) {
    final bool reporter = role == 'reporter';
    final List<Report> shown = reporter
        ? reports
        : reports
            .where((Report r) => r.status == Status.awaiting || r.status == Status.confirmed)
            .toList();
    final List<Report> active = shown.where((Report r) => r.status != Status.confirmed).toList();
    final List<Report> done = shown.where((Report r) => r.status == Status.confirmed).toList();

    Widget card(Report r) {
      final bool finished = r.status == Status.awaiting || r.status == Status.confirmed;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ReportCard(
          key: ValueKey<String>('hist-${r.id}'),
          report: r,
          priceCents: reporter ? reporterCentReward : executorCentReward,
          children: <Widget>[
            if (reporter && r.status == Status.awaiting) ...<Widget>[
              _gap(),
              PrimaryButton(
                label: tr('confirmDoneBtn'),
                icon: Icons.check,
                onTap: () => patchReport(r.id, <String, dynamic>{'status': Status.confirmed}),
              ),
            ],
            if (finished) RatingRow(report: r, canRate: reporter),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('${tr('activeSec')} (${active.length})', style: subTitleStyle),
        _gap(8),
        if (active.isEmpty) Text(tr('noActiveSec'), style: metaStyle),
        ...active.map(card),
        _gap(),
        Text('${tr('doneSec')} (${done.length})', style: subTitleStyle),
        _gap(8),
        if (done.isEmpty) Text(tr('noDoneSec'), style: metaStyle),
        ...done.map(card),
      ],
    );
  }
}

class RatingRow extends StatefulWidget {
  const RatingRow({super.key, required this.report, required this.canRate});

  final Report report;
  final bool canRate;

  @override
  State<RatingRow> createState() => _RatingRowState();
}

class _RatingRowState extends State<RatingRow> {
  int _value = 0;
  bool _busy = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    if (!widget.canRate) {
      _timer = Timer.periodic(const Duration(seconds: 15), (_) => _load());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final List<Map<String, dynamic>> data = await db
          .from('messages')
          .select('text,created_at')
          .eq('report_id', widget.report.id)
          .like('text', '[[sm:rating:%')
          .order('created_at', ascending: false)
          .limit(1);
      if (!mounted || data.isEmpty) return;
      final RegExpMatch? m = RegExp(r'rating:(\d)').firstMatch((data.first['text'] ?? '').toString());
      if (m != null) setState(() => _value = int.parse(m.group(1)!));
    } catch (_) {}
  }

  Future<void> _set(int n) async {
    if (!widget.canRate || _busy) return;
    setState(() {
      _busy = true;
      _value = n;
    });
    await smEvent(widget.report.id, 'rating:$n');
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.canRate && _value == 0) return const SizedBox.shrink();
    final String label = widget.canRate
        ? (_value == 0 ? tr('rateAsk') : tr('rateYours'))
        : tr('rateGot');
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: metaStyle)),
          for (int i = 1; i <= 5; i++)
            GestureDetector(
              onTap: widget.canRate ? () => _set(i) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  i <= _value ? Icons.star : Icons.star_border,
                  color: const Color(0xFFF5A623),
                  size: 26,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- earnings

class EarningsView extends StatelessWidget {
  const EarningsView({
    super.key,
    required this.role,
    required this.balanceCents,
    required this.earnedCents,
    required this.reports,
    required this.onWithdraw,
  });

  final String role;
  final int balanceCents;
  final int earnedCents;
  final List<Report> reports;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final bool reporter = role == 'reporter';
    int count = 0;
    if (reporter) {
      for (final Report r in reports) {
        count += r.photos.length;
      }
    } else {
      count = reports.where((Report r) => r.status != Status.fresh).length;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFFF7A65A), Color(0xFFEF8423), Color(0xFFE0680A)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                reporter ? tr('balanceBonusLabel2') : tr('balanceIncomeLabel2'),
                style: const TextStyle(color: Color(0xFFFFF1E3), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                formatEuro(balanceCents),
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: tr('withdrawBtn'),
                icon: Icons.download_outlined,
                onTap: balanceCents == 0 ? null : onWithdraw,
              ),
            ],
          ),
        ),
        _gap(),
        SmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _statRow(tr('totalEarnedLabel'), formatEuro(earnedCents)),
              _gap(10),
              _statRow(reporter ? tr('sentPhotosLabel') : tr('doneJobsLabel'), '$count'),
              _gap(10),
              Text(
                reporter
                    ? tr('explainReporter').replaceAll('{n}', '$reporterCentReward')
                    : tr('explainExecutor').replaceAll('{n}', formatEuro(executorCentReward)),
                style: metaStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget _statRow(String label, String value) {
  return Row(
    children: <Widget>[
      Expanded(child: Text(label, style: metaStyle)),
      Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: C.ink)),
    ],
  );
}

class WithdrawSheet extends StatefulWidget {
  const WithdrawSheet({super.key, required this.balanceCents, required this.onConfirm});

  final int balanceCents;
  final Future<void> Function() onConfirm;

  @override
  State<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<WithdrawSheet> {
  String _method = 'card';
  bool _done = false;

  Future<void> _confirm() async {
    setState(() => _done = true);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await widget.onConfirm();
    if (mounted) Navigator.of(context).pop();
  }

  Widget _row(String id, String label, String sub, IconData icon) {
    final bool active = _method == id;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _method = id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: active ? C.accentSoft : C.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? C.accent : C.border, width: active ? 1.5 : 1),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 20, color: active ? C.accent : C.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.ink)),
                    Text(sub, style: metaStyle),
                  ],
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: _done
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(color: C.success, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(tr('withdrawDoneTitle'), style: titleStyle),
                  const SizedBox(height: 4),
                  Text(tr('withdrawDoneSub'), style: metaStyle),
                  const SizedBox(height: 10),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(tr('withdrawAvailable'), style: metaStyle),
                  Text(
                    formatEuro(widget.balanceCents),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: C.ink),
                  ),
                  const SizedBox(height: 10),
                  Text(tr('withdrawMethodTitle'), style: subTitleStyle),
                  _row('card', tr('methodCard'), tr('methodCardSub'), Icons.credit_card),
                  _row('paypal', 'PayPal', tr('methodPaypalSub'), Icons.account_balance_wallet_outlined),
                  _row('gift', tr('methodGift'), tr('methodGiftSub'), Icons.card_giftcard),
                  const SizedBox(height: 14),
                  PrimaryButton(label: tr('withdrawConfirm'), onTap: _confirm),
                  const SizedBox(height: 8),
                  SecondaryButton(label: tr('withdrawCancel'), onTap: () => Navigator.of(context).pop()),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------- chat

class ChatView extends StatefulWidget {
  const ChatView({super.key, required this.role, required this.reports, required this.myId});

  final String role;
  final List<Report> reports;
  final String myId;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Timer? _timer;
  String? _selectedId;
  String? _loadedFor;
  List<Map<String, dynamic>> _messages = <Map<String, dynamic>>[];

  List<Report> get _chats => widget.reports
      .where((Report r) => r.reporterId != null && r.executorId != null && r.status != Status.fresh)
      .toList();

  Report? get _current {
    final List<Report> chats = _chats;
    if (chats.isEmpty) return null;
    for (final Report r in chats) {
      if (r.id == _selectedId) return r;
    }
    return chats.first;
  }

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final String? id = _current?.id;
    if (id == null) {
      if (_messages.isNotEmpty && mounted) setState(() => _messages = <Map<String, dynamic>>[]);
      return;
    }
    try {
      final List<Map<String, dynamic>> data = await db
          .from('messages')
          .select()
          .eq('report_id', id)
          .order('created_at', ascending: true);
      if (!mounted || _current?.id != id) return;
      final bool grew = data.length != _messages.length || _loadedFor != id;
      setState(() {
        _messages = data;
        _loadedFor = id;
      });
      if (grew) _toBottom();
    } catch (_) {}
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final String text = _input.text.trim();
    final String? id = _current?.id;
    if (text.isEmpty || id == null) return;
    final Map<String, dynamic> row = <String, dynamic>{
      'id': uid(),
      'report_id': id,
      'sender_id': widget.myId,
      'text': text,
      'created_at': nowMs(),
    };
    setState(() {
      _messages = <Map<String, dynamic>>[..._messages, row];
      _input.clear();
    });
    _toBottom();
    try {
      await db.from('messages').insert(row);
    } catch (_) {}
  }

  String _chatLabel(Report r) {
    final String time = formatTime(r.createdAt);
    if (r.comment.isEmpty) return time;
    final String c = r.comment.length > 30 ? r.comment.substring(0, 30) : r.comment;
    return '$time — $c';
  }

  @override
  Widget build(BuildContext context) {
    final Report? current = _current;
    if (current == null) {
      return Align(alignment: Alignment.topLeft, child: Text(tr('chatEmpty'), style: metaStyle));
    }
    final List<Report> chats = _chats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (chats.length > 1)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: C.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: current.id,
                items: chats
                    .map(
                      (Report r) => DropdownMenuItem<String>(
                        value: r.id,
                        child: Text(
                          _chatLabel(r),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13.5, color: C.ink),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (String? v) {
                  setState(() {
                    _selectedId = v;
                    _messages = <Map<String, dynamic>>[];
                  });
                  _load();
                },
              ),
            ),
          ),
        Text(
          widget.role == 'reporter' ? tr('roleExecutor') : tr('roleReporter'),
          style: titleStyle,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            itemCount: _messages.length,
            itemBuilder: (BuildContext ctx, int i) {
              final Map<String, dynamic> m = _messages[i];
              final String raw = (m['text'] ?? '').toString();
              final bool event = raw.startsWith('[[sm:');
              final bool mine = (m['sender_id'] ?? '').toString() == widget.myId;
              if (event) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: C.accentSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        smEventText(raw),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: C.accentDark, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                );
              }
              return Align(
                alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
                  decoration: BoxDecoration(
                    color: mine ? C.accent : C.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: mine ? null : Border.all(color: C.border),
                  ),
                  child: Text(
                    raw,
                    style: TextStyle(fontSize: 14, height: 1.35, color: mine ? Colors.white : C.ink),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _input,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: smInput(tr('chatPlaceholder')),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: C.accent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _send,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- profile

class ProfileView extends StatefulWidget {
  const ProfileView({
    super.key,
    required this.profile,
    required this.reports,
    required this.setTab,
    required this.saveProfile,
    required this.signOut,
  });

  final Profile profile;
  final List<Report> reports;
  final ValueChanged<String> setTab;
  final SaveProfile saveProfile;
  final Future<void> Function() signOut;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final TextEditingController _name = TextEditingController(text: widget.profile.name);
  late final TextEditingController _phone = TextEditingController(text: widget.profile.phone);
  bool _editing = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Widget _listButton(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SmCard(
          child: Row(
            children: <Widget>[
              Expanded(child: Text(label, style: const TextStyle(fontSize: 14.5, color: C.ink))),
              Icon(icon, size: 18, color: C.muted),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool reporter = widget.profile.role == 'reporter';
    final String roleLabel = reporter ? tr('roleReporter') : tr('roleExecutor');
    final String shownName = widget.profile.name.isNotEmpty ? widget.profile.name : roleLabel;
    final String initial = shownName.trim().isEmpty ? '?' : shownName.trim().substring(0, 1).toUpperCase();
    final int count = reporter
        ? widget.reports.length
        : widget.reports.where((Report r) => r.status != Status.fresh).length;
    String vehicleLabel = tr('vehicleFoot');
    for (final Vehicle v in vehicles) {
      if (v.id == widget.profile.vehicle) vehicleLabel = tr(v.labelKey);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SmCard(
          child: Column(
            children: <Widget>[
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: C.accentSoft, shape: BoxShape.circle),
                child: Text(
                  initial,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: C.accentDark),
                ),
              ),
              const SizedBox(height: 10),
              if (_editing) ...<Widget>[
                TextField(controller: _name, decoration: smInput(tr('namePh'))),
                const SizedBox(height: 8),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: smInput(tr('phonePh')),
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: tr('profileSave'),
                  onTap: () {
                    widget.saveProfile(<String, dynamic>{
                      'name': _name.text.trim(),
                      'phone': _phone.text.trim(),
                    });
                    setState(() => _editing = false);
                  },
                ),
              ] else ...<Widget>[
                Text(shownName, style: titleStyle),
                const SizedBox(height: 2),
                Text(
                  widget.profile.phone.isNotEmpty ? widget.profile.phone : tr('noPhone'),
                  style: metaStyle,
                ),
                const SizedBox(height: 10),
                SecondaryButton(
                  label: tr('profileEdit'),
                  onTap: () => setState(() => _editing = true),
                ),
              ],
            ],
          ),
        ),
        _gap(),
        SmCard(child: _statRow(reporter ? tr('statSentMessages') : tr('statDoneJobs'), '$count')),
        if (!reporter) ...<Widget>[
          _gap(),
          SmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(tr('myVehicleLabel'), style: subTitleStyle),
                const SizedBox(height: 4),
                Text(vehicleLabel, style: metaStyle),
              ],
            ),
          ),
        ],
        _listButton(
          reporter ? tr('myBonusesLabel') : tr('myIncomeLabel'),
          Icons.account_balance_wallet_outlined,
          () => widget.setTab('money'),
        ),
        _listButton(tr('supportLabel'), Icons.chat_bubble_outline, () => widget.setTab('chat')),
        _gap(16),
        SecondaryButton(label: tr('signOutAccountBtn'), onTap: () => widget.signOut()),
      ],
    );
  }
}
