# Installing Flow-tracker on Windows

## What you need

| | |
| --- | --- |
| Windows | 10 (64-bit) or 11 |
| Architecture | x64 |
| Free disk | ~250 MB |
| Visual C++ runtime | included in the installer — nothing to install separately |
| Windows Media Foundation | included in standard Windows; **missing on "N" editions** |

## Which file to download

- **`Flow-Tracker-1.5.0-Windows-x64.exe`** — the installer. Recommended.
- **`Flow-Tracker-1.5.0-Windows-x64.msi`** — the same app as an MSI, for managed
  deployment.

Both install to `C:\Program Files\Flow-tracker` and create a Start Menu shortcut.
Neither is a portable build: the executable needs the DLLs and the `data` folder
that sit beside it, so don't copy the `.exe` out of the installed folder.

## About "MFPlat.dll was not found"

If Windows shows a **System Error** saying `MFPlat.dll` was not found, the cause is
specific and not a broken download:

Flow-tracker plays focus soundscapes and a completion chime through the
`audioplayers` plugin. On Windows that plugin uses **Media Foundation**, and it is
loaded before any Flow-tracker code runs. If Media Foundation is absent, Windows
refuses to start the process — so the app cannot show its own error message.

Media Foundation ships with standard Windows 10 and 11. It is **absent on "N"
editions** (the versions sold in the EU without media features), and on some
stripped enterprise images.

### Check whether you have it

```powershell
Test-Path "$env:SystemRoot\System32\mfplat.dll"
```

`True` means you have it. `False` means you need the Media Feature Pack.

### Install the Media Feature Pack

Either:

1. **Settings → Apps → Optional features → Add a feature**, tick **Media Feature
   Pack**, install, restart.

or, in an administrator PowerShell:

```powershell
DISM /Online /Add-Capability /CapabilityName:Media.MediaFeaturePack~~~~0.0.1.0
```

Then start Flow-tracker again. No reinstall is needed.

### What the installer does now

Both installers check for `mfplat.dll`:

- the **EXE** shows an explanation with these instructions and asks whether to
  continue;
- the **MSI** refuses to install and displays the same guidance.

That is deliberate. An install that leaves a shortcut which cannot launch is worse
than a clear message up front.

## Verifying your download

```powershell
Get-FileHash .\Flow-Tracker-1.5.0-Windows-x64.exe -Algorithm SHA256
```

Compare with the same line in `SHA256SUMS.txt` on the release page.

## What is inside the package

| Item | Why |
| --- | --- |
| `Flow-tracker.exe` | the app |
| `flutter_windows.dll` | the Flutter engine |
| `audioplayers_windows_plugin.dll`, `printing_plugin.dll`, `pdfium.dll`, `share_plus_plugin.dll`, `url_launcher_windows_plugin.dll`, `file_selector_windows_plugin.dll`, `gal_plugin.dll`, `local_auth_windows_plugin.dll`, `flutter_local_notifications_windows.dll`, `flutter_timezone_plugin.dll` | plugins |
| `msvcp140*.dll`, `vcruntime140*.dll`, `concrt140.dll` | the Visual C++ runtime, shipped beside the app so no separate install is required |
| `data\` | fonts, icons, sounds and the app's assets |

No Windows system DLL is redistributed. The files above are the app's own build
output and the Microsoft runtime that Flutter's Windows build copies in.

## Uninstalling

Settings → Apps → Flow-tracker → Uninstall. Your habit data lives in your user
profile and is not removed by the uninstaller.

## Known limitations

- Windows **N edition** needs the Media Feature Pack, as above.
- The installers are currently **unsigned**, so SmartScreen will warn about an
  unknown publisher. Signing is set up in the repository but needs a code-signing
  certificate to be configured.
- Windows on ARM runs the x64 build through emulation; it has not been tested on
  ARM hardware.
