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
Source: "vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

; Drivers (Optional) - User should create a 'drivers' folder next to this script
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
  if not IsVCRedistInstalled then
  begin
    if MsgBox('This application requires Microsoft Visual C++ Redistributable (x64).' + #13#10 +
              'It is missing and will be installed automatically.' + #13#10#13#10 +
              'Do you want to continue?', mbConfirmation, MB_YESNO) = IDYES then
    begin
      ExtractTemporaryFile('vc_redist.x64.exe');
      if not Exec(ExpandConstant('{tmp}\vc_redist.x64.exe'), '/install /passive /norestart', '', SW_SHOW, ewWaitUntilTerminated, ErrorCode) then
      begin
        MsgBox('Automatic installation failed (Error ' + IntToStr(ErrorCode) + ').', mbError, MB_OK);
        
        // Fallback warning
        if MsgBox('The application will likely crash without this component. Are you sure you want to continue?', mbConfirmation, MB_YESNO) = IDNO then
        begin
          Result := False;
        end;
      end;
    end
    else
    begin
      // User chose not to install dependencies
      if MsgBox('The application will likely crash without this component. Are you sure you want to continue?', mbConfirmation, MB_YESNO) = IDNO then
      begin
        Result := False;
      end;
    end;
  end;
end;
