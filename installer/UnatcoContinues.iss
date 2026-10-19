; UNATCO Continues - the installer of one version of the mod (tools\build_installers.py builds both):
;   ISCC /DTarget=vanilla|revision /DAppVersion=0.1.0 /DStage=<staged files> installer\UnatcoContinues.iss
; It asks for the Deus Ex folder (Steam's by default), puts the mod's files in a folder of their own there and
; runs the version's install script (install-vanilla.ps1 / install.ps1): the maps are made from the player's own
; copy of the game. Uninstalling runs uninstall-vanilla.ps1 / uninstall.ps1 (what the install added, nothing else).

#ifndef Target
  #define Target "vanilla"
#endif
#ifndef Privileges
  #define Privileges "admin"
#endif
#ifndef AppVersion
  #define AppVersion "0.1.0"
#endif
#if Target == "vanilla"
  #define GameName "Deus Ex"
  #define Payload "UnatcoMaps\Setup"
  #define InstallScript "install-vanilla.ps1"
  #define UninstallScript "uninstall-vanilla.ps1"
  #define GameExe "System\DeusEx.exe"
  #define AppIdGuid "{{6C1E2B7A-3D4F-4E6B-9A21-0D5E8C7B1F01}"
  #define OutName "UNATCO-Continues-DeusEx-Setup-" + AppVersion
#else
  #define GameName "Deus Ex: Revision"
  #define Payload "Revision\UnatcoMaps\Setup"
  #define InstallScript "install.ps1"
  #define UninstallScript "uninstall.ps1"
  #define GameExe "Revision\System\Revision.exe"
  #define AppIdGuid "{{6C1E2B7A-3D4F-4E6B-9A21-0D5E8C7B1F02}"
  #define OutName "UNATCO-Continues-Revision-Setup-" + AppVersion
#endif

[Setup]
AppId={#AppIdGuid}
AppName=UNATCO Continues for {#GameName}
AppVersion={#AppVersion}
AppVerName=UNATCO Continues {#AppVersion} for {#GameName} (work in progress)
AppPublisher=Gabby
DefaultDirName={code:GameDir}
AppendDefaultDirName=no
DirExistsWarning=no
DisableProgramGroupPage=yes
UsePreviousAppDir=yes
PrivilegesRequired={#Privileges}
OutputDir=..\build\installer
OutputBaseFilename={#OutName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayName=UNATCO Continues for {#GameName}
LicenseFile={#Stage}\LICENSE
InfoBeforeFile={#Stage}\BEFORE.txt

[Messages]
SelectDirLabel3=Setup will install UNATCO Continues into your {#GameName} folder.
SelectDirBrowseLabel=This is the folder of the game (with System and Maps in it). To continue, click Next. To choose another folder, click Browse.

[Files]
Source: "{#Stage}\*"; DestDir: "{app}\{#Payload}"; Flags: ignoreversion recursesubdirs createallsubdirs

[UninstallRun]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\{#Payload}\{#UninstallScript}"" -Game ""{app}"""; Flags: runhidden waituntilterminated; RunOnceId: "UnatcoUninstall"

[Code]
function GameDir(Param: String): String;
var
  steam: String;
begin
  Result := ExpandConstant('{commonpf32}\Steam\steamapps\common\Deus Ex');
  if RegQueryStringValue(HKCU, 'Software\Valve\Steam', 'SteamPath', steam) then
  begin
    StringChangeEx(steam, '/', '\', True);
    if FileExists(steam + '\steamapps\common\Deus Ex\{#GameExe}') then
      Result := steam + '\steamapps\common\Deus Ex';
  end;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if (CurPageID = wpSelectDir) and not FileExists(AddBackslash(WizardDirValue) + '{#GameExe}') then
  begin
    MsgBox('{#GameName} is not in this folder ({#GameExe} not found). Choose the folder of the game.', mbError, MB_OK);
    Result := False;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  code: Integer;
  log: String;
begin
  if CurStep = ssPostInstall then
  begin
    log := ExpandConstant('{app}\{#Payload}\install.log');
    WizardForm.StatusLabel.Caption := 'Making the maps from your copy of the game...';
    if not Exec(ExpandConstant('{cmd}'), '/c powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' +
        ExpandConstant('{app}\{#Payload}\{#InstallScript}') + '" -Game "' + ExpandConstant('{app}') + '" > "' + log + '" 2>&1',
        '', SW_HIDE, ewWaitUntilTerminated, code) or (code <> 0) then
      MsgBox('The installation did not finish (is the game open?). What happened is in:' + #13#10 + log, mbError, MB_OK);
  end;
end;
