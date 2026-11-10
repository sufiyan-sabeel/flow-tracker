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
