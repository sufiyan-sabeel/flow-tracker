#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

[Setup]
AppId={{EB1BEEEF-EC84-4267-A9E7-078FE4863579}
AppName=Flow-tracker
AppVersion={#AppVersion}
AppVerName=Flow-tracker {#AppVersion}
AppPublisher=InlitX
AppPublisherURL=https://github.com/sufiyan-sabeel/flow-tracker
AppSupportURL=https://github.com/sufiyan-sabeel/flow-tracker/issues
AppUpdatesURL=https://github.com/sufiyan-sabeel/flow-tracker/releases
DefaultDirName={autopf}\Flow-tracker
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\build\installer
OutputBaseFilename=Flow-tracker-windows-x64-setup
SetupIconFile=runner\resources\app_icon.ico
UninstallDisplayIcon={app}\Flow-tracker.exe
UninstallDisplayName=Flow-tracker
WizardStyle=modern
Compression=lzma2
SolidCompression=yes
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "german"; MessagesFile: "compiler:Languages\German.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "dutch"; MessagesFile: "compiler:Languages\Dutch.isl"
Name: "korean"; MessagesFile: "compiler:Languages\Korean.isl"
Name: "portuguese"; MessagesFile: "compiler:Languages\Portuguese.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "ukrainian"; MessagesFile: "compiler:Languages\Ukrainian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Flow-tracker"; Filename: "{app}\Flow-tracker.exe"; AppUserModelID: "com.flowtracker.app"
Name: "{autodesktop}\Flow-tracker"; Filename: "{app}\Flow-tracker.exe"; Tasks: desktopicon; AppUserModelID: "com.flowtracker.app"

[Run]
Filename: "{app}\Flow-tracker.exe"; Description: "{cm:LaunchProgram,Flow-tracker}"; Flags: nowait postinstall skipifsilent
