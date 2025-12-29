[Setup]
AppName=DentalTid
AppVersion=0.1.0
DefaultDirName={autopf}\DentalTid
DefaultGroupName=DentalTid
OutputDir=dist
OutputBaseFilename=dentaltid_x64_setup
Compression=lzma
SolidCompression=yes
PrivilegesRequired=admin
; Ensures the installer only runs on 64-bit Windows
ArchitecturesAllowed=x64
; Ensures the app installs in Program Files instead of Program Files (x86)
ArchitecturesInstallIn64BitMode=x64
SetupIconFile=windows\runner\resources\app_icon.ico

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs
Source: "drivers\vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

; Drivers (Optional)
Source: "drivers\*"; DestDir: "{app}\drivers"; Flags: skipifsourcedoesntexist recursesubdirs

[Icons]
Name: "{group}\DentalTid"; Filename: "{app}\dentaltid.exe"
Name: "{commondesktop}\DentalTid"; Filename: "{app}\dentaltid.exe"

[Run]
Filename: "{app}\dentaltid.exe"; Description: "Launch DentalTid"; Flags: postinstall nowait

[Code]
function IsVCRedistInstalled: Boolean;
begin
  // Check for Visual C++ 2015-2022 Redistributable (x64)
  Result := RegKeyExists(HKLM, 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64');
end;

function InitializeSetup: Boolean;
var
  ErrorCode: Integer;
begin
  Result := True;
  
  // Check if we are on 64-bit Windows (Inno Setup handles this via ArchitecturesAllowed, 
  // but this is a double check)
  if not Is64BitInstallMode then
  begin
    MsgBox('This application is 64-bit and can only be installed on 64-bit Windows.', mbCriticalError, MB_OK);
    Result := False;
    Exit;
  end;

  if not IsVCRedistInstalled then
  begin
    if MsgBox('This application requires Microsoft Visual C++ Redistributable (x64).\' + #13#10 +
              'It will be installed now. Do you want to continue?', mbConfirmation, MB_YESNO) = IDYES then
    begin
      ExtractTemporaryFile('vc_redist.x64.exe');
      if not Exec(ExpandConstant('{tmp}\vc_redist.x64.exe'), '/install /passive /norestart', '', SW_SHOW, ewWaitUntilTerminated, ErrorCode) then
      begin
        MsgBox('Visual C++ installation failed (Error ' + IntToStr(ErrorCode) + '). The app might not run.', mbError, MB_OK);
      end;
    end;
  end;
end;