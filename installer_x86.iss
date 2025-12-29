[Setup]
AppName=DentalTid
AppVersion=0.1.0
DefaultDirName={autopf}\DentalTid
DefaultGroupName=DentalTid
OutputDir=dist
OutputBaseFilename=dentaltid_x86_setup
Compression=lzma
SolidCompression=yes
PrivilegesRequired=admin
; Ensures the installer only runs on 32-bit or 64-bit Windows (x86 apps run on both)
ArchitecturesAllowed=x86 x64
; We install in 32-bit mode
ArchitecturesInstallIn64BitMode=
SetupIconFile=windows\runner\resources\app_icon.ico

[Files]
Source: "build\windows\x86\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs
Source: "drivers\VC_redist.x86.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

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
  // Check for Visual C++ 2015-2022 Redistributable (x86)
  Result := RegKeyExists(HKLM, 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x86');
end;

function InitializeSetup: Boolean;
var
  ErrorCode: Integer;
begin
  Result := True;

  if not IsVCRedistInstalled then
  begin
    if MsgBox('This application requires Microsoft Visual C++ Redistributable (x86).\n' + #13#10 +
              'It will be installed now. Do you want to continue?', mbConfirmation, MB_YESNO) = IDYES then
    begin
      ExtractTemporaryFile('VC_redist.x86.exe');
      if not Exec(ExpandConstant('{tmp}\VC_redist.x86.exe'), '/install /passive /norestart', '', SW_SHOW, ewWaitUntilTerminated, ErrorCode) then
      begin
        MsgBox('Visual C++ installation failed (Error ' + IntToStr(ErrorCode) + '). The app might not run.', mbError, MB_OK);
      end;
    end;
  end;
end;
