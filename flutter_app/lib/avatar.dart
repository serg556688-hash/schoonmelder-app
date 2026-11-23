import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';
import 'fancy.dart';

const Map<String, Map<String, String>> _av = <String, Map<String, String>>{
  'nl': <String, String>{
    'avTitle': 'Profielfoto',
    'avHint': 'Met een echte foto weten melders wie er komt opruimen.',
    'avGallery': 'Kies uit galerij',
    'avCamera': 'Maak een foto',
    'avRemove': 'Foto verwijderen',
    'avAdd': 'Foto toevoegen',
  },
  'en': <String, String>{
    'avTitle': 'Profile photo',
    'avHint': 'With a real photo, reporters know who is coming to clean up.',
    'avGallery': 'Choose from gallery',
    'avCamera': 'Take a photo',
    'avRemove': 'Remove photo',
    'avAdd': 'Add photo',
  },
  'ru': <String, String>{
    'avTitle': 'Фото профиля',
    'avHint': 'По настоящему фото заказчик узнает, кто придёт убирать.',
    'avGallery': 'Выбрать из галереи',
    'avCamera': 'Сделать фото',
    'avRemove': 'Удалить фото',
    'avAdd': 'Добавить фото',
  },
  'ar': <String, String>{
    'avTitle': 'صورة الملف الشخصي',
    'avHint': 'بصورة حقيقية يعرف المبلّغ من سيأتي للتنظيف.',
    'avGallery': 'اختر من المعرض',
    'avCamera': 'التقط صورة',
    'avRemove': 'حذف الصورة',
    'avAdd': 'إضافة صورة',
  },
};

String _t(String key) => _av[I18n.lang.value]?[key] ?? _av['en']?[key] ?? key;

final ImagePicker _avatarPicker = ImagePicker();

/// Round profile picture with an orange "+" button: the user can put in a
/// photo from the gallery or take a selfie, so others can recognise them.
/// The photo is kept on the phone and, when the database allows it, also
/// saved with the profile.
class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({super.key, required this.userId, this.initialPhoto});

  final String userId;
  final String? initialPhoto;

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  String? _photo;

  String get _key => 'avatar:${widget.userId}';

  @override
  void initState() {
    super.initState();
    _photo = widget.initialPhoto;
    _loadLocal();
  }

  Future<void> _loadLocal() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? saved = prefs.getString(_key);
      if (saved != null && saved.isNotEmpty && mounted) setState(() => _photo = saved);
    } catch (_) {}
  }

  Future<void> _store(String? photo) async {
    setState(() => _photo = photo);
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (photo == null) {
        await prefs.remove(_key);
      } else {
        await prefs.setString(_key, photo);
      }
    } catch (_) {}
    // Also keep it with the profile, so others can see it (ignored when the
    // database has no place for it yet).
    try {
      await db.from('profiles').update(<String, dynamic>{'avatar': photo}).eq('id', widget.userId);
    } catch (_) {}
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final XFile? file = await _avatarPicker.pickImage(
        source: source,
        maxWidth: 420,
        maxHeight: 420,
        imageQuality: 75,
        preferredCameraDevice: CameraDevice.front,
      );
      if (file == null) return;
      final Uint8List bytes = await file.readAsBytes();
      await _store(toDataUrl(bytes));
    } catch (_) {}
  }

  Future<void> _openMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (BuildContext ctx) {
        Widget item(IconData icon, Color color, String label, VoidCallback onTap) {
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color),
            ),
            title: Text(label, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: C.ink)),
            onTap: () {
              Navigator.of(ctx).pop();
              onTap();
            },
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 12),
                Text(_t('avTitle'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: C.ink)),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _t('avHint'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: C.muted),
                  ),
                ),
                const SizedBox(height: 8),
                item(Icons.photo_library_rounded, C.blue, _t('avGallery'), () => _pick(ImageSource.gallery)),
                item(Icons.photo_camera_rounded, C.accent, _t('avCamera'), () => _pick(ImageSource.camera)),
                if (_photo != null)
                  item(Icons.delete_outline_rounded, C.danger, _t('avRemove'), () => _store(null)),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = decodeDataUrl(_photo);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GestureDetector(
          onTap: _openMenu,
          child: SizedBox(
            width: 104,
            height: 104,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                // Orange ring around the photo.
                Container(
                  width: 104,
                  height: 104,
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xFFFFB574), Color(0xFFFF6A1A), Color(0xFFE0500A)],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(color: Color(0x40E85A0C), blurRadius: 16, offset: Offset(0, 7)),
                    ],
                  ),
                  child: Container(
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                    padding: const EdgeInsets.all(3),
                    child: ClipOval(
                      child: bytes != null
                          ? Image.memory(bytes, fit: BoxFit.cover, width: 90, height: 90, gaplessPlayback: true)
                          : Container(
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                gradient: RadialGradient(
                                  center: Alignment(-0.3, -0.4),
                                  colors: <Color>[Color(0xFFFFF4EA), C.accentSoft],
                                ),
                              ),
                              child: const Icon3D(Icon3DKind.person, size: 66),
                            ),
                    ),
                  ),
                ),
                // The "+" button.
                Positioned(
                  right: -2,
                  bottom: 2,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[Color(0xFF6FB6FF), Color(0xFF2E7FD9)],
                      ),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(color: Color(0x402E7FD9), blurRadius: 8, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Icon(
                      bytes != null ? Icons.edit_rounded : Icons.add_rounded,
                      color: Colors.white,
                      size: bytes != null ? 16 : 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (bytes == null) ...<Widget>[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _openMenu,
            child: Text(
              _t('avAdd'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.blue),
            ),
          ),
        ],
      ],
    );
  }
}
