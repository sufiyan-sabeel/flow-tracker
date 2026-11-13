; Inno Setup script for the Flow-tracker Windows installer.
;
; Built in CI with:
;   ISCC.exe /DAppVersion=1.8.0 /DSourceDir=<Release folder> /DOutputDir=<out> flow_tracker.iss
;
; The Flutter Windows build produces a folder with the executable, the Flutter
; DLLs and the data directory. All of it has to ship, not just the .exe, so the
; script pulls in the whole release folder.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\build\windows\x64\runner\Release"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\out"
#endif

#define AppName "Flow-tracker"
#define AppPublisher "Umaiz Sufiyan"
#define AppExe "Flow-tracker.exe"
#define AppId "{{7C1D2A6E-9B34-4C7A-9F2E-6E0B1D5A8C10}"

[Setup]
AppId={#AppId}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL=https://github.com/sufiyan-sabeel/flow-tracker
AppSupportURL=https://github.com/sufiyan-sabeel/flow-tracker/issues
AppUpdatesURL=https://github.com/sufiyan-sabeel/flow-tracker/releases
VersionInfoVersion={#AppVersion}
VersionInfoCompany={#AppPublisher}
VersionInfoDescription={#AppName} installer
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
LicenseFile=..\..\LICENSE
OutputDir={#OutputDir}
OutputBaseFilename=Flow-Tracker-{#AppVersion}-Windows-x64
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#AppExe}
; unsigned build: no signing tool is configured in CI
SetupIconFile=..\runner\resources\app_icon.ico

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; the whole Flutter release folder: exe, DLLs and the data directory
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

[Code]
{ Flow-tracker links the audioplayers plugin, which uses Windows Media
  Foundation. On an edition without it (Windows "N", some stripped images) the
  process cannot start at all, and Windows shows only "MFPlat.dll was not found".
  Check here so the user gets an explanation instead of a dead shortcut. }

function MediaFoundationPresent: Boolean;
begin
  Result := FileExists(ExpandConstant('{sys}\mfplat.dll'));
end;

function InitializeSetup: Boolean;
var
  Msg: String;
  NL: String;
begin
  Result := True;
  if MediaFoundationPresent then
    Exit;

  { Inno's preprocessor treats a line starting with # as a directive, so the
    newline escape lives in a variable rather than at the start of a line. }
  NL := #13#10;

  Msg := 'Flow-tracker needs Windows Media Foundation for its focus sounds, and this edition of Windows does not include it.' + NL + NL;
  Msg := Msg + 'Without it the app cannot start. To enable it:' + NL + NL;
  Msg := Msg + '  1. Open Settings > Apps > Optional features > Add a feature' + NL;
  Msg := Msg + '  2. Tick "Media Feature Pack" and install it' + NL + NL;
  Msg := Msg + 'Or run this in an administrator PowerShell:' + NL;
  Msg := Msg + '  DISM /Online /Add-Capability /CapabilityName:Media.MediaFeaturePack~~~~0.0.1.0' + NL + NL;
  Msg := Msg + 'You can continue installing now and add the feature afterwards.';

  if MsgBox(Msg, mbConfirmation, MB_YESNO) = IDNO then
    Result := False;
end;
