"""Adds the app name and permission texts to the generated iOS project."""
import plistlib

path = "ios/Runner/Info.plist"
with open(path, "rb") as f:
    info = plistlib.load(f)

info["CFBundleDisplayName"] = "Schoonmelder"
info["CFBundleName"] = "Schoonmelder"
info["NSLocationWhenInUseUsageDescription"] = (
    "Schoonmelder gebruikt je locatie om te laten zien waar het afval ligt "
    "en om te controleren dat de foto op de juiste plek is gemaakt."
)
info["NSCameraUsageDescription"] = "Schoonmelder gebruikt de camera om een foto van het afval te maken."
info["NSPhotoLibraryUsageDescription"] = "Schoonmelder heeft toegang nodig om een foto toe te voegen."
info["NSMicrophoneUsageDescription"] = "De microfoon wordt niet gebruikt voor opnames."
info["ITSAppUsesNonExemptEncryption"] = False

with open(path, "wb") as f:
    plistlib.dump(info, f)
print("Info.plist patched")
