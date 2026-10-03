import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------- config

const String supabaseUrl = 'https://hkgcktbpovfkfopobmly.supabase.co';
const String supabaseKey = 'sb_publishable___JY0xqVNJPZw5ShW7hbIA_V-bd-0gR';
const String webAppUrl = 'https://schoonmelder-app.vercel.app';

SupabaseClient get db => Supabase.instance.client;

const int reporterCentReward = 5;
const int executorCentReward = 50;
const int geoVerifyThresholdM = 150;
const int homeRadiusM = 2000;

class Status {
  static const String fresh = 'new';
  static const String inProgress = 'in_progress';
  static const String awaiting = 'awaiting_confirmation';
  static const String confirmed = 'confirmed';
}

// ---------------------------------------------------------------- colors

class C {
  static const Color bg = Color(0xFFFFF9F4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF2A2420);
  static const Color muted = Color(0xFF8A8074);
  static const Color accent = Color(0xFFFF6A1A);
  static const Color accentDark = Color(0xFFE85A0C);
  static const Color accentSoft = Color(0xFFFFE3CF);
  static const Color success = Color(0xFF2F9E64);
  static const Color successSoft = Color(0xFFDCF3E5);
  static const Color border = Color(0xFFF1E4D8);
  static const Color blue = Color(0xFF2E7FD9);
  static const Color blueSoft = Color(0xFFDCEBFB);
  static const Color danger = Color(0xFFD9432B);
  static const Color btnShadow = Color(0xFFC25A07);
  static const List<Color> btnGradient = <Color>[
    Color(0xFFF6A050),
    Color(0xFFEF8423),
    Color(0xFFE46F0C),
  ];
}

class StatusMeta {
  const StatusMeta(this.labelKey, this.color, this.bg);
  final String labelKey;
  final Color color;
  final Color bg;
}

StatusMeta statusMeta(String status) {
  switch (status) {
    case Status.inProgress:
      return const StatusMeta('statusInProgress', C.blue, C.blueSoft);
    case Status.awaiting:
      return const StatusMeta('statusAwaiting', C.success, C.successSoft);
    case Status.confirmed:
      return const StatusMeta('statusConfirmed', C.muted, C.border);
    default:
      return const StatusMeta('statusNew', C.accent, C.accentSoft);
  }
}

// ---------------------------------------------------------------- i18n

class LangOption {
  const LangOption(this.code, this.flag, this.label);
  final String code;
  final String flag;
  final String label;
}

const List<LangOption> langOptions = <LangOption>[
  LangOption('nl', '🇳🇱', 'Nederlands'),
  LangOption('en', '🇬🇧', 'English'),
  LangOption('ru', '🇷🇺', 'Русский'),
  LangOption('ar', '🇸🇦', 'العربية'),
];

/// Texts that only exist in the native app (the web texts talk about
/// "this site" and browser settings, which make no sense here).
const Map<String, Map<String, String>> _nativeTexts = <String, Map<String, String>>{
  'nl': <String, String>{
    'geoDeniedApp':
        'De app heeft geen toegang tot je locatie. Sta locatie toe in de instellingen van je telefoon en probeer het opnieuw.',
    'geoOffApp': 'Locatie staat uit op je telefoon. Zet locatie (GPS) aan en probeer het opnieuw.',
    'openSettings': 'Instellingen openen',
    'okBtn': 'OK',
    'retryBtn': 'Opnieuw proberen',
    'confirmOnWeb':
        'Je wachtwoord herstel je via de link in de e-mail. Log daarna hier opnieuw in.',
  },
  'en': <String, String>{
    'geoDeniedApp':
        'The app has no access to your location. Allow location in your phone settings and try again.',
    'geoOffApp': 'Location is switched off on your phone. Turn on location (GPS) and try again.',
    'openSettings': 'Open settings',
    'okBtn': 'OK',
    'retryBtn': 'Try again',
    'confirmOnWeb': 'Reset your password with the link in the e-mail, then sign in here again.',
  },
  'ru': <String, String>{
    'geoDeniedApp':
        'У приложения нет доступа к геолокации. Разрешите доступ в настройках телефона и попробуйте ещё раз.',
    'geoOffApp': 'Геолокация на телефоне выключена. Включите её (GPS) и попробуйте ещё раз.',
    'openSettings': 'Открыть настройки',
    'okBtn': 'OK',
    'retryBtn': 'Попробовать ещё раз',
    'confirmOnWeb': 'Пароль меняется по ссылке из письма. После этого войдите здесь заново.',
  },
  'ar': <String, String>{
    'geoDeniedApp':
        'التطبيق لا يملك إذن الوصول إلى موقعك. اسمح بالموقع من إعدادات الهاتف ثم حاول مرة أخرى.',
    'geoOffApp': 'خدمة الموقع متوقفة على هاتفك. شغّل الموقع (GPS) ثم حاول مرة أخرى.',
    'openSettings': 'فتح الإعدادات',
    'okBtn': 'موافق',
    'retryBtn': 'حاول مرة أخرى',
    'confirmOnWeb': 'أعد تعيين كلمة المرور عبر الرابط في البريد ثم سجّل الدخول هنا.',
  },
};

class I18n {
  static Map<String, Map<String, String>> _dict = <String, Map<String, String>>{};
  static final ValueNotifier<String> lang = ValueNotifier<String>('nl');

  static Future<void> load() async {
    try {
      final String raw = await rootBundle.loadString('assets/i18n.json');
      final Map<String, dynamic> parsed = jsonDecode(raw) as Map<String, dynamic>;
      final Map<String, Map<String, String>> out = <String, Map<String, String>>{};
      parsed.forEach((String code, dynamic value) {
        final Map<String, String> entries = <String, String>{};
        (value as Map<String, dynamic>).forEach((String k, dynamic v) {
          entries[k] = v.toString();
        });
        out[code] = entries;
      });
      _dict = out;
    } catch (_) {
      _dict = <String, Map<String, String>>{};
    }
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? saved = prefs.getString('lang');
      if (saved != null && langOptions.any((LangOption o) => o.code == saved)) {
        lang.value = saved;
      }
    } catch (_) {}
  }

  static Future<void> setLang(String code) async {
    lang.value = code;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('lang', code);
    } catch (_) {}
  }

  static bool get isRtl => lang.value == 'ar';
}

/// Translate a key into the current language.
String tr(String key) {
  final String code = I18n.lang.value;
  return _nativeTexts[code]?[key] ??
      I18n._dict[code]?[key] ??
      _nativeTexts['en']?[key] ??
      I18n._dict['en']?[key] ??
      I18n._dict['nl']?[key] ??
      key;
}

// ---------------------------------------------------------------- models

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return num.tryParse(v.toString())?.toInt();
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

LatLng? _asPoint(dynamic lat, dynamic lng) {
  final double? a = _asDouble(lat);
  final double? b = _asDouble(lng);
  if (a == null || b == null) return null;
  return LatLng(a, b);
}

class Report {
  Report(this.row);

  final Map<String, dynamic> row;

  String get id => row['id'].toString();

  List<String> get photos {
    final dynamic p = row['photos'];
    if (p is List) {
      return p.map((dynamic e) => e.toString()).toList();
    }
    final dynamic single = row['photo'];
    if (single is String && single.isNotEmpty) return <String>[single];
    return <String>[];
  }

  LatLng? get coords => _asPoint(row['lat'], row['lng']);
  String get comment => (row['comment'] ?? '').toString();
  int get createdAt => _asInt(row['created_at']) ?? 0;
  String get status => (row['status'] ?? Status.fresh).toString();
  LatLng? get executorCoords => _asPoint(row['executor_lat'], row['executor_lng']);
  int? get executorUpdatedAt => _asInt(row['executor_updated_at']);

  String? get completionPhoto {
    final dynamic p = row['completion_photo'];
    if (p is String && p.isNotEmpty) return p;
    return null;
  }

  LatLng? get completionCoords => _asPoint(row['completion_lat'], row['completion_lng']);
  String? get reporterId => row['reporter_id']?.toString();
  String? get executorId => row['executor_id']?.toString();

  Report patched(Map<String, dynamic> patch) {
    final Map<String, dynamic> next = Map<String, dynamic>.from(row);
    next.addAll(patch);
    return Report(next);
  }
}

class Profile {
  Profile(this.row);

  final Map<String, dynamic> row;

  String get role => (row['role'] ?? 'reporter').toString();
  String get name => (row['name'] ?? '').toString();
  String get phone => (row['phone'] ?? '').toString();
  String get vehicle => (row['vehicle'] ?? 'foot').toString();
  int get withdrawnCents => _asInt(row['withdrawn_cents']) ?? 0;

  Profile patched(Map<String, dynamic> patch) {
    final Map<String, dynamic> next = Map<String, dynamic>.from(row);
    next.addAll(patch);
    return Profile(next);
  }
}

class Vehicle {
  const Vehicle(this.id, this.labelKey, this.icon, this.speedKmh);
  final String id;
  final String labelKey;
  final IconData icon;
  final double speedKmh;
}

const List<Vehicle> vehicles = <Vehicle>[
  Vehicle('foot', 'vehicleFoot', Icons.directions_walk, 5),
  Vehicle('bike', 'vehicleBike', Icons.pedal_bike, 15),
  Vehicle('ebike', 'vehicleEbike', Icons.electric_bike, 20),
  Vehicle('scooter', 'vehicleScooter', Icons.electric_scooter, 25),
  Vehicle('car', 'vehicleCar', Icons.directions_car, 30),
];

// ---------------------------------------------------------------- helpers

final math.Random _rnd = math.Random();

String uid() {
  final String a = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  const String chars = '0123456789abcdefghijklmnopqrstuvwxyz';
  final StringBuffer b = StringBuffer();
  for (int i = 0; i < 5; i++) {
    b.write(chars[_rnd.nextInt(chars.length)]);
  }
  return a + b.toString();
}

int nowMs() => DateTime.now().millisecondsSinceEpoch;

String formatEuro(int cents) => '€${(cents / 100).toStringAsFixed(2)}';

String _two(int n) => n.toString().padLeft(2, '0');

String formatTime(int ms) {
  final DateTime d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${_two(d.day)}.${_two(d.month)} ${_two(d.hour)}:${_two(d.minute)}';
}

double? haversineKm(LatLng? a, LatLng? b) {
  if (a == null || b == null) return null;
  const double r = 6371;
  final double dLat = (b.latitude - a.latitude) * math.pi / 180;
  final double dLng = (b.longitude - a.longitude) * math.pi / 180;
  final double la = a.latitude * math.pi / 180;
  final double lb = b.latitude * math.pi / 180;
  final double h = math.pow(math.sin(dLat / 2), 2).toDouble() +
      math.cos(la) * math.cos(lb) * math.pow(math.sin(dLng / 2), 2).toDouble();
  return r * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
}

int estimateMinutes(double km, String vehicleId) {
  double speed = 5;
  for (final Vehicle v in vehicles) {
    if (v.id == vehicleId) speed = v.speedKmh;
  }
  return math.max(1, (km / speed * 60).round());
}

/// The reporter's "home zone" is the place of his very first report.
LatLng? homeZone(List<Report> reports) {
  final List<Report> withCoords = reports.where((Report r) => r.coords != null).toList()
    ..sort((Report a, Report b) => a.createdAt.compareTo(b.createdAt));
  return withCoords.isEmpty ? null : withCoords.first.coords;
}

// ---------------------------------------------------------------- images

final Map<String, Uint8List> _imageCache = <String, Uint8List>{};

/// Photos are stored as "data:image/jpeg;base64,..." strings, same as the web app.
Uint8List? decodeDataUrl(String? dataUrl) {
  if (dataUrl == null || dataUrl.isEmpty) return null;
  final Uint8List? cached = _imageCache[dataUrl];
  if (cached != null) return cached;
  try {
    final int comma = dataUrl.indexOf(',');
    final String b64 = comma >= 0 ? dataUrl.substring(comma + 1) : dataUrl;
    final Uint8List bytes = base64Decode(b64);
    if (_imageCache.length > 80) _imageCache.clear();
    _imageCache[dataUrl] = bytes;
    return bytes;
  } catch (_) {
    return null;
  }
}

String toDataUrl(Uint8List bytes) => 'data:image/jpeg;base64,${base64Encode(bytes)}';

// ---------------------------------------------------------------- location

class Geo {
  /// Last problem, as a translation key: geoOffApp, geoDeniedApp or noLoc.
  static String lastError = 'noLoc';
  static LatLng? _last;
  static int _lastAt = 0;

  static Future<bool> _ensurePermission() async {
    try {
      final bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        lastError = 'geoOffApp';
        return false;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        lastError = 'geoDeniedApp';
        return false;
      }
      return true;
    } catch (_) {
      lastError = 'noLoc';
      return false;
    }
  }

  static Future<LatLng?> getLocation() async {
    if (!await _ensurePermission()) return null;
    try {
      final Position p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      _last = LatLng(p.latitude, p.longitude);
      _lastAt = nowMs();
      return _last;
    } catch (_) {
      // Fall back to a recent fix (max 1 minute old), like the web app does.
      if (_last != null && nowMs() - _lastAt < 60000) return _last;
      try {
        final Position? known = await Geolocator.getLastKnownPosition();
        if (known != null &&
            DateTime.now().difference(known.timestamp).inSeconds.abs() < 60) {
          return LatLng(known.latitude, known.longitude);
        }
      } catch (_) {}
      lastError = 'noLoc';
      return null;
    }
  }

  static Future<Stream<Position>?> watch() async {
    if (!await _ensurePermission()) return null;
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    );
  }

  static void remember(Position p) {
    _last = LatLng(p.latitude, p.longitude);
    _lastAt = nowMs();
  }

  static Future<void> openSettings() async {
    try {
      if (lastError == 'geoOffApp') {
        await Geolocator.openLocationSettings();
      } else {
        await Geolocator.openAppSettings();
      }
    } catch (_) {}
  }
}

// ---------------------------------------------------------------- address / route

const Map<String, String> _httpHeaders = <String, String>{
  'User-Agent': 'SchoonmelderApp/1.0 (nl.schoonmelder.schoonmelder)',
  'Accept': 'application/json',
};

final Map<String, Future<String>> _addressCache = <String, Future<String>>{};

Future<String> reverseGeocode(LatLng c) {
  final String key = '${c.latitude.toStringAsFixed(5)},${c.longitude.toStringAsFixed(5)}';
  return _addressCache.putIfAbsent(key, () => _reverse(c));
}

Future<String> _reverse(LatLng c) async {
  try {
    final Uri pdok = Uri.parse(
        'https://api.pdok.nl/bzk/locatieserver/search/v3_1/reverse?lat=${c.latitude}&lon=${c.longitude}&rows=1&type=adres&distance=150&fl=weergavenaam');
    final http.Response r =
        await http.get(pdok, headers: _httpHeaders).timeout(const Duration(seconds: 8));
    if (r.statusCode == 200) {
      final dynamic j = jsonDecode(utf8.decode(r.bodyBytes));
      final dynamic docs = j is Map ? (j['response'] is Map ? j['response']['docs'] : null) : null;
      if (docs is List && docs.isNotEmpty && docs.first is Map) {
        final dynamic name = docs.first['weergavenaam'];
        if (name is String && name.isNotEmpty) return name;
      }
    }
  } catch (_) {}
  try {
    final Uri nom = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&zoom=18&lat=${c.latitude}&lon=${c.longitude}');
    final http.Response r =
        await http.get(nom, headers: _httpHeaders).timeout(const Duration(seconds: 8));
    if (r.statusCode == 200) {
      final dynamic j = jsonDecode(utf8.decode(r.bodyBytes));
      final dynamic a = j is Map ? j['address'] : null;
      if (a is Map) {
        final String street = <dynamic>[a['road'], a['house_number']]
            .where((dynamic e) => e != null && e.toString().isNotEmpty)
            .join(' ');
        final String city =
            (a['city'] ?? a['town'] ?? a['village'] ?? a['municipality'] ?? '').toString();
        return <String>[street, city].where((String e) => e.isNotEmpty).join(', ');
      }
    }
  } catch (_) {}
  return '';
}

class RouteResult {
  RouteResult(this.points, this.km);
  final List<LatLng> points;
  final double km;
}

/// profile: car, bike or foot.
Future<RouteResult?> fetchRoute(LatLng from, LatLng to, String profile) async {
  try {
    final Uri url = Uri.parse(
        'https://routing.openstreetmap.de/routed-$profile/route/v1/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}?overview=full&geometries=geojson');
    final http.Response r =
        await http.get(url, headers: _httpHeaders).timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) return null;
    final dynamic j = jsonDecode(utf8.decode(r.bodyBytes));
    final dynamic routes = j is Map ? j['routes'] : null;
    if (routes is! List || routes.isEmpty) return null;
    final dynamic first = routes.first;
    final dynamic coords = first['geometry']['coordinates'];
    if (coords is! List) return null;
    final List<LatLng> pts = <LatLng>[];
    for (final dynamic p in coords) {
      if (p is List && p.length >= 2) {
        pts.add(LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble()));
      }
    }
    final double km = ((first['distance'] as num?)?.toDouble() ?? 0) / 1000;
    return RouteResult(pts, km);
  } catch (_) {
    return null;
  }
}

String routeProfileFor(String vehicleId) {
  if (vehicleId == 'car') return 'car';
  if (vehicleId == 'foot') return 'foot';
  return 'bike';
}

// ---------------------------------------------------------------- events in chat

/// System events are stored as chat messages like "[[sm:onsite]]".
Future<void> smEvent(String reportId, String kind) async {
  try {
    final String? me = db.auth.currentUser?.id;
    if (me == null) return;
    await db.from('messages').insert(<String, dynamic>{
      'id': uid(),
      'report_id': reportId,
      'sender_id': me,
      'text': '[[sm:$kind]]',
      'created_at': nowMs(),
    });
  } catch (_) {}
}

String smEventText(String text) {
  if (text == '[[sm:onsite]]') return tr('evOnsite');
  if (text == '[[sm:done]]') return tr('evDone');
  final RegExpMatch? rating = RegExp(r'^\[\[sm:rating:(\d)\]\]$').firstMatch(text);
  if (rating != null) {
    final int n = math.min(5, math.max(0, int.parse(rating.group(1)!)));
    return '${tr('evRating')} ${'★' * n}${'☆' * (5 - n)}';
  }
  final RegExpMatch? far = RegExp(r'^\[\[sm:far:(\d+)\]\]$').firstMatch(text);
  if (far != null) return tr('evFar').replaceAll('{n}', far.group(1)!);
  return text;
}

String friendlyAuthError(Object e) {
  String msg;
  if (e is AuthException) {
    msg = e.message;
  } else {
    msg = e.toString();
  }
  final String m = msg.toLowerCase();
  if (m.contains('invalid login')) return tr('invalidLogin');
  if (m.contains('not confirmed')) return tr('notConfirmed');
  if (m.contains('already registered') || m.contains('already been registered')) {
    return tr('userExists');
  }
  if (m.contains('rate limit') || m.contains('security purposes')) return tr('tooManyEmails');
  if (m.contains('password should be') || m.contains('at least 6')) return tr('passwordShort');
  if (m.contains('socket') || m.contains('failed host lookup') || m.contains('network')) {
    return tr('dbErrorText');
  }
  return msg;
}
