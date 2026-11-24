"""Adds permissions and the app name to the generated Android project."""
import re

path = "android/app/src/main/AndroidManifest.xml"
src = open(path, encoding="utf8").read()

perms = """
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW"/>
            <data android:scheme="https"/>
        </intent>
    </queries>
"""
if "ACCESS_FINE_LOCATION" not in src:
    src = src.replace("<application", perms + "    <application", 1)
src = re.sub(r'android:label="[^"]*"', 'android:label="Schoonmelder"', src, count=1)
open(path, "w", encoding="utf8").write(src)
print("AndroidManifest patched")

# Face ID / fingerprint login (local_auth) needs a FlutterFragmentActivity.
import glob
for act in glob.glob("android/app/src/main/**/MainActivity.*", recursive=True):
    code = open(act, encoding="utf8").read()
    code = code.replace("io.flutter.embedding.android.FlutterActivity", "io.flutter.embedding.android.FlutterFragmentActivity")
    code = re.sub(r"\bFlutterActivity\b", "FlutterFragmentActivity", code)
    open(act, "w", encoding="utf8").write(code)
    print("MainActivity patched:", act)
