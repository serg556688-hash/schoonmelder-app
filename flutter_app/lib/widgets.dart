import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data.dart';

// ---------------------------------------------------------------- buttons

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, this.onTap, this.icon, this.busy = false});

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null && !busy;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: C.btnGradient,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: C.btnShadow, offset: Offset(0, 4)),
            BoxShadow(color: Color(0x40BE5B12), offset: Offset(0, 8), blurRadius: 16),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: 17, color: Colors.white),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, this.onTap, this.icon});

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap != null ? 1 : 0.45,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: C.border),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0xFFEFDCCB), offset: Offset(0, 3)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: 16, color: C.ink),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: C.ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SmCard extends StatelessWidget {
  const SmCard({super.key, required this.child, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: C.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0xFFF6E6D6), offset: Offset(0, 2)),
          BoxShadow(color: Color(0x12784620), offset: Offset(0, 12), blurRadius: 26),
        ],
      ),
      child: child,
    );
  }
}

const TextStyle metaStyle = TextStyle(fontSize: 13, color: C.muted);
const TextStyle titleStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: C.ink);
const TextStyle subTitleStyle = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: C.ink);

InputDecoration smInput(String hint) {
  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: C.muted, fontSize: 14),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    border: border(C.border),
    enabledBorder: border(C.border),
    focusedBorder: border(C.accent),
  );
}

Future<void> showInfo(BuildContext context, String text, {bool settings = false}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      content: Text(text, style: const TextStyle(fontSize: 14.5, color: C.ink)),
      actions: <Widget>[
        if (settings)
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Geo.openSettings();
            },
            child: Text(tr('openSettings')),
          ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(tr('okBtn')),
        ),
      ],
    ),
  );
}

Future<void> openGoogleMaps(LatLng to) async {
  final Uri url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${to.latitude},${to.longitude}');
  try {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (_) {}
}

// ---------------------------------------------------------------- images

class DataImage extends StatelessWidget {
  const DataImage(this.dataUrl, {super.key, this.fit = BoxFit.cover, this.width, this.height});

  final String? dataUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = decodeDataUrl(dataUrl);
    if (bytes == null) {
      return Container(
        width: width,
        height: height,
        color: C.accentSoft,
        child: const Icon(Icons.image_not_supported_outlined, color: C.muted),
      );
    }
    return Image.memory(
      bytes,
      fit: fit,
      width: width,
      height: height,
      gaplessPlayback: true,
      errorBuilder: (BuildContext c, Object e, StackTrace? s) => Container(
        width: width,
        height: height,
        color: C.accentSoft,
        child: const Icon(Icons.image_not_supported_outlined, color: C.muted),
      ),
    );
  }
}

void showPhoto(BuildContext context, String dataUrl) {
  showDialog<void>(
    context: context,
    builder: (BuildContext ctx) => GestureDetector(
      onTap: () => Navigator.of(ctx).pop(),
      child: Container(
        color: Colors.black87,
        alignment: Alignment.center,
        child: InteractiveViewer(child: DataImage(dataUrl, fit: BoxFit.contain)),
      ),
    ),
  );
}

/// Before / after photo with a slider, like on the website.
class CompareBox extends StatefulWidget {
  const CompareBox({super.key, required this.before, required this.after});

  final String before;
  final String after;

  @override
  State<CompareBox> createState() => _CompareBoxState();
}

class _CompareBoxState extends State<CompareBox> {
  double _value = 50;

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: LayoutBuilder(
              builder: (BuildContext ctx, BoxConstraints box) {
                final double w = box.maxWidth;
                final double h = box.maxHeight;
                return Stack(
                  children: <Widget>[
                    Positioned.fill(child: DataImage(widget.after)),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: w * _value / 100,
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.centerLeft,
                          minWidth: w,
                          maxWidth: w,
                          minHeight: h,
                          maxHeight: h,
                          child: DataImage(widget.before, width: w, height: h),
                        ),
                      ),
                    ),
                    Positioned(left: 8, top: 8, child: _tag(tr('beforeLabel'))),
                    Positioned(right: 8, top: 8, child: _tag(tr('afterLabel'))),
                  ],
                );
              },
            ),
          ),
        ),
        Slider(
          value: _value,
          min: 0,
          max: 100,
          activeColor: C.accent,
          onChanged: (double v) => setState(() => _value = v),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- map

class MapPoint {
  const MapPoint(this.kind, this.at);

  /// trash, me or executor
  final String kind;
  final LatLng at;
}

/// Real aerial-photo map (PDOK luchtfoto on top of OpenStreetMap) with markers and a route.
class SmMap extends StatefulWidget {
  const SmMap({
    super.key,
    required this.points,
    this.height = 240,
    this.routeFrom,
    this.routeTo,
    this.profile = 'bike',
    this.onRouteKm,
  });

  final List<MapPoint> points;
  final double height;
  final LatLng? routeFrom;
  final LatLng? routeTo;
  final String profile;
  final ValueChanged<double>? onRouteKm;

  @override
  State<SmMap> createState() => _SmMapState();
}

class _SmMapState extends State<SmMap> {
  final MapController _controller = MapController();
  List<LatLng> _route = <LatLng>[];
  String _routeKey = '';
  bool _ready = false;
  bool _userMoved = false;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void didUpdateWidget(covariant SmMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadRoute();
    if (!_userMoved && widget.points.length != oldWidget.points.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fit());
    }
  }

  String _keyFor(LatLng a, LatLng b) =>
      '${a.latitude.toStringAsFixed(3)},${a.longitude.toStringAsFixed(3)}>${b.latitude.toStringAsFixed(4)},${b.longitude.toStringAsFixed(4)}:${widget.profile}';

  Future<void> _loadRoute() async {
    final LatLng? from = widget.routeFrom;
    final LatLng? to = widget.routeTo;
    if (from == null || to == null) return;
    final String key = _keyFor(from, to);
    if (key == _routeKey) return;
    _routeKey = key;
    if (_route.isEmpty && mounted) {
      setState(() => _route = <LatLng>[from, to]);
    }
    final RouteResult? r = await fetchRoute(from, to, widget.profile);
    if (!mounted || r == null || r.points.length < 2 || key != _routeKey) return;
    setState(() => _route = r.points);
    widget.onRouteKm?.call(r.km);
    if (!_userMoved) _fit();
  }

  void _fit() {
    if (!_ready || !mounted) return;
    final List<LatLng> all = <LatLng>[
      ...widget.points.map((MapPoint p) => p.at),
      ..._route,
    ];
    if (all.isEmpty) return;
    try {
      if (all.length == 1) {
        _controller.move(all.first, 17);
        return;
      }
      final LatLngBounds bounds = LatLngBounds.fromPoints(all);
      if (bounds.north == bounds.south && bounds.east == bounds.west) {
        _controller.move(all.first, 17);
        return;
      }
      _controller.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(40),
          maxZoom: 18,
        ),
      );
    } catch (_) {}
  }

  Widget _marker(String kind) {
    if (kind == 'trash') {
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFFF3933D), Color(0xFFE97510)],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x66BE5B12), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 19),
      );
    }
    return Center(
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: C.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x402E7FD9), blurRadius: 0, spreadRadius: 6),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng center = widget.points.isNotEmpty
        ? widget.points.first.at
        : const LatLng(52.1326, 5.2913);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: <Widget>[
            FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 17,
                minZoom: 4,
                maxZoom: 19,
                onMapReady: () {
                  _ready = true;
                  _fit();
                },
                onPositionChanged: (MapCamera camera, bool hasGesture) {
                  if (hasGesture) _userMoved = true;
                },
              ),
              children: <Widget>[
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'nl.schoonmelder.schoonmelder',
                  maxNativeZoom: 19,
                ),
                TileLayer(
                  urlTemplate:
                      'https://service.pdok.nl/hwh/luchtfotorgb/wmts/v1_0/Actueel_orthoHR/EPSG:3857/{z}/{x}/{y}.jpeg',
                  userAgentPackageName: 'nl.schoonmelder.schoonmelder',
                  maxNativeZoom: 19,
                  errorTileCallback: (TileImage tile, Object error, StackTrace? stack) {},
                ),
                if (_route.length >= 2)
                  PolylineLayer(
                    polylines: <Polyline>[
                      Polyline(
                        points: _route,
                        strokeWidth: 6,
                        color: Colors.white,
                      ),
                      Polyline(
                        points: _route,
                        strokeWidth: 4,
                        color: C.blue,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: widget.points
                      .map(
                        (MapPoint p) => Marker(
                          point: p.at,
                          width: 38,
                          height: 38,
                          child: _marker(p.kind),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            Positioned(
              left: 6,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                color: Colors.white70,
                child: const Text(
                  '© OpenStreetMap · Luchtfoto © PDOK',
                  style: TextStyle(fontSize: 9, color: Colors.black87),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    _userMoved = false;
                    _fit();
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(7),
                    child: Icon(Icons.center_focus_strong, size: 18, color: C.ink),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- address line

/// Street address of a point; tap to open the map and a route button.
class PlaceLine extends StatefulWidget {
  const PlaceLine({super.key, required this.coords, this.open = false, this.noMap = false});

  final LatLng coords;
  final bool open;
  final bool noMap;

  @override
  State<PlaceLine> createState() => _PlaceLineState();
}

class _PlaceLineState extends State<PlaceLine> {
  String _address = '';
  late bool _open = widget.open;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PlaceLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coords.latitude != widget.coords.latitude ||
        oldWidget.coords.longitude != widget.coords.longitude) {
      _address = '';
      _load();
    }
  }

  Future<void> _load() async {
    final LatLng asked = widget.coords;
    final String a = await reverseGeocode(asked);
    if (!mounted || asked != widget.coords) return;
    setState(() => _address = a);
  }

  @override
  Widget build(BuildContext context) {
    final LatLng c = widget.coords;
    final String text = _address.isNotEmpty
        ? _address
        : '${c.latitude.toStringAsFixed(5)}, ${c.longitude.toStringAsFixed(5)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: widget.noMap ? null : () => setState(() => _open = !_open),
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: C.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.location_on, size: 17, color: C.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 13, color: C.ink, fontWeight: FontWeight.w600),
                  ),
                ),
                if (!widget.noMap)
                  Text(
                    _open ? tr('hideMap') : tr('showMap'),
                    style: const TextStyle(fontSize: 12, color: C.accentDark, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
        ),
        if (_open && !widget.noMap) ...<Widget>[
          const SizedBox(height: 8),
          SmMap(height: 220, points: <MapPoint>[MapPoint('trash', c)]),
          const SizedBox(height: 8),
          SecondaryButton(
            label: tr('route'),
            icon: Icons.navigation_outlined,
            onTap: () => openGoogleMaps(c),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------- live tracking

class LiveTrackingBlock extends StatefulWidget {
  const LiveTrackingBlock({super.key, required this.report});

  final Report report;

  @override
  State<LiveTrackingBlock> createState() => _LiveTrackingBlockState();
}

class _LiveTrackingBlockState extends State<LiveTrackingBlock> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Report r = widget.report;
    final double? km = haversineKm(r.coords, r.executorCoords);
    final int? updated = r.executorUpdatedAt;
    final int? ago = updated == null ? null : math.max(0, ((nowMs() - updated) / 1000).round());
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(color: C.blue, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Text(
                tr('executorEnRoute'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.blue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SmMap(
            points: <MapPoint>[
              if (r.coords != null) MapPoint('trash', r.coords!),
              if (r.executorCoords != null) MapPoint('executor', r.executorCoords!),
            ],
            routeFrom: r.executorCoords,
            routeTo: r.coords,
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              _Stat(value: km != null ? '${km.toStringAsFixed(1)} km' : '—', label: tr('distanceLabel')),
              const SizedBox(width: 24),
              _Stat(value: ago != null ? '${ago}s' : '—', label: tr('updatedAgoLabel')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: C.ink)),
        Text(label, style: metaStyle),
      ],
    );
  }
}

class StatPair extends StatelessWidget {
  const StatPair({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => _Stat(value: value, label: label);
}

// ---------------------------------------------------------------- report card

class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.report,
    this.priceCents,
    this.hideLive = false,
    this.children = const <Widget>[],
  });

  final Report report;
  final int? priceCents;
  final bool hideLive;
  final List<Widget> children;

  Widget _geoBadge() {
    final LatLng? a = report.coords;
    final LatLng? b = report.completionCoords;
    bool ok = false;
    String text;
    if (a != null && b != null) {
      final double m = (haversineKm(a, b) ?? 0) * 1000;
      ok = m <= geoVerifyThresholdM;
      text = ok
          ? tr('geoVerified').replaceAll('{n}', m.toStringAsFixed(0))
          : tr('geoMismatch').replaceAll('{n}', (m / 1000).toStringAsFixed(1));
    } else {
      text = tr('geoUnavailable');
    }
    final Color fg = ok ? C.success : C.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: ok ? C.successSoft : const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Icon(ok ? Icons.verified_user_outlined : Icons.gpp_maybe_outlined, size: 15, color: fg),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StatusMeta meta = statusMeta(report.status);
    final List<String> photos = report.photos;
    final String? after = report.completionPhoto;
    final bool compare = photos.isNotEmpty && after != null;
    return SmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: meta.bg, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  tr(meta.labelKey),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: meta.color),
                ),
              ),
              const Spacer(),
              if (priceCents != null) ...<Widget>[
                Text(
                  formatEuro(priceCents!),
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: C.accentDark),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(Icons.schedule, size: 13, color: C.muted),
              const SizedBox(width: 3),
              Text(formatTime(report.createdAt), style: metaStyle),
            ],
          ),
          const SizedBox(height: 10),
          if (compare) ...<Widget>[
            CompareBox(before: photos.first, after: after),
            _geoBadge(),
          ] else if (photos.isNotEmpty)
            SizedBox(
              height: photos.length == 1 ? 200 : 120,
              child: Row(
                children: <Widget>[
                  for (int i = 0; i < photos.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => showPhoto(context, photos[i]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: DataImage(photos[i], height: double.infinity),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (report.status == Status.inProgress && !hideLive) LiveTrackingBlock(report: report),
          if (report.comment.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.chat_bubble_outline, size: 14, color: C.muted),
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text(report.comment, style: metaStyle)),
                ],
              ),
            ),
          if (report.coords != null)
            PlaceLine(
              coords: report.coords!,
              noMap: hideLive || report.status == Status.inProgress,
            ),
          ...children,
        ],
      ),
    );
  }
}
