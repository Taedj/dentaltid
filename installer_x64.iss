[Setup]
AppName=DentalTid
AppVersion=0.1.0
DefaultDirName={pf}\DentalTid
DefaultGroupName=DentalTid
OutputDir=dist
OutputBaseFilename=dentaltid_x64_setup
PrivilegesRequired=admin

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\DentalTid"; Filename: "{app}\dentaltid.exe"
Name: "{commondesktop}\DentalTid"; Filename: "{app}\dentaltid.exe"

[Run]
Filename: "{app}\dentaltid.exe"; Description: "Launch DentalTid"; Flags: postinstall nowait
