// ============================================================================
// JBGUICustomHUDMenu
// Copyright (c) 2004 by Wormbo <wormbo@onlinehome.de>
// $Id: JBGUICustomHUDMenu.uc,v 1.4 2004/05/26 11:21:50 mychaeel Exp $
//
// custom HUD configuration menu for Jailbreak's clientside settings.
// ============================================================================


class JBGUICustomHUDMenu extends UT2K4CustomHUDMenu;


// ============================================================================
// Variables
// ============================================================================

var automated moCombobox co_VoicePack;
var automated GUIButton b_TestVoicePack;
var automated moCheckbox ch_EnableScreens;
var automated moCheckbox ch_ReverseSwitchColors;

var private string VoicePackPrev;


// ============================================================================ 
// InitializeGameClass
//
// Loads the voice pack list and returns true so the LoadSettings function is
// called.
// ============================================================================

function bool InitializeGameClass(string GameClassName)
{
  LoadVoicePacks();
  return True;
}


// ============================================================================
// LoadVoicePacks
//
// Fills the co_VoicePack list.
// ============================================================================

function LoadVoicePacks()
{
  local int iVoicePack;
  local array<string> ListEntry;
  local array<string> ListDescription;

  if (DynamicLoadObject("Jailbreak.JBVoice", Class'Class', False) == None)
    return;  // unable to load MetaClass, so GetAllIntDesc would crash

  PlayerOwner().GetAllIntDesc("Jailbreak.JBVoice", ListEntry, ListDescription);

  for (iVoicePack = 0; iVoicePack < ListEntry.Length; iVoicePack++)
    co_VoicePack.AddItem(ListDescription[iVoicePack], , ListEntry[iVoicePack]);
}


// ============================================================================
// LoadSettings
//
// Called when initializing the component. Loads current settings.
// ============================================================================

function LoadSettings()
{
  VoicePackPrev = Class'JBSpeechManager'.Static.GetVoicePack();

  co_VoicePack.Find(VoicePackPrev, , True);
  co_VoicePack.OnChange = VoicePackChange;

  ch_EnableScreens      .Checked(GetEnableScreens());
  ch_ReverseSwitchColors.Checked(GetReverseSwitchColors());
}


// ============================================================================
// Closed
//
// Resets the original voice pack if cancelled.
// ============================================================================

event Closed(GUIComponent GUIComponentSender, bool bCancelled)
{
  if (bCancelled)
    Class'JBSpeechManager'.Static.SetVoicePack(VoicePackPrev);

  Super.Closed(GUIComponentSender, bCancelled);
}


// ============================================================================
// SaveSettings
//
// Called when the page is closed with the OK button.
// ============================================================================

function SaveSettings()
{
  Class'JBSpeechManager'.Static.SetVoicePack(co_VoicePack.GetExtra());
  SetEnableScreens(ch_EnableScreens.IsChecked());
}


// ============================================================================
// RestoreDefaults
//
// Called when the reset button is clicked. Restores factory defaults.
// ============================================================================

function RestoreDefaults()
{
  co_VoicePack.Find("JBVoiceGrrrl.Classic", , True);

  ch_EnableScreens      .Checked(True);
  ch_ReverseSwitchColors.Checked(False);
}


// ============================================================================
// VoicePackChange
//
// Plays a test sample when the user selects another voice pack.
// ============================================================================

function VoicePackChange(GUIComponent GUIComponentSender)
{
  TestVoicePack();
}


// ============================================================================
// TestVoicePackClick
//
// Plays a test sample when the user clicks the Test button.
// ============================================================================

function bool TestVoicePackClick(GUIComponent GUIComponentSender)
{
  TestVoicePack();
  return True;
}


// ============================================================================
// TestVoicePack
//
// Plays a random test sample for the currently selected voice pack.
// ============================================================================

function TestVoicePack()
{
  local string Macro;
  local string Tags;

  switch (Rand(11)) {
    case  0:  Macro = "LastMan";           break;
    case  1:  Macro = "LastSecondSave";    break;
    case  2:  Macro = "TeamCapturedRed";   break;
    case  3:  Macro = "TeamCapturedBlue";  break;
    case  4:  Macro = "TeamCapturedBoth";  break;
    case  5:  Macro = "TeamReleasedRed";   break;
    case  6:  Macro = "TeamReleasedBlue";  break;
    case  7:  Macro = "ArenaWarning";      break;
    case  8:  Macro = "ArenaEndTimeout";   break;
    case  9:  Macro = "ArenaEndWinner";    break;
    case 10:  Macro = "ArenaEndLoser";     break;
  }

  switch (Rand(3)) {
    case 0:  Tags = "red";        break;
    case 1:  Tags = "blue";       break;
    case 2:  Tags = "spectator";  break;
  }

  Class'JBSpeechManager'.Static.SetVoicePack(co_VoicePack.GetExtra());
  Class'JBSpeechManager'.Static.PlayFor(PlayerOwner().Level, "$" $ Macro, Tags);
}


// ============================================================================
// GetEnableScreens
//
// Returns whether the JBScreen actors are currently enabled.
// ============================================================================

function bool GetEnableScreens()
{
  return Class'Jailbreak'.Default.bEnableScreens;
}


// ============================================================================
// GetReverseSwitchColors
//
// Returns whether switch colors are reversed.
// ============================================================================

function bool GetReverseSwitchColors()
{
  return Class'Jailbreak'.Default.bReverseSwitchColors;
}


// ============================================================================
// SetEnableScreens
//
// Sets the config setting which enables JBScreen actors and updates any
// present instances of this class.
// ============================================================================

function SetEnableScreens(bool bEnableScreens)
{
  local Info thisInfo;
  local Jailbreak thisJailbreak;

  Class'Jailbreak'.Default.bEnableScreens = bEnableScreens;
  Class'Jailbreak'.Static.StaticSaveConfig();

  foreach PlayerOwner().DynamicActors(Class'Jailbreak', thisJailbreak)
    thisJailbreak.bEnableScreens = bEnableScreens;

  foreach PlayerOwner().DynamicActors(Class'Info', thisInfo)
    if (thisInfo.IsA('JBScreen'))
      thisInfo.Reset();
}


// ============================================================================
// SetReverseSwitchColors
//
// Sets the config setting which reverses switch colors and updates any
// present objectives to reflect those changes.
// ============================================================================

function SetReverseSwitchColors(bool bReverseSwitchColors)
{
  local GameObjective thisGameObjective;
  local Jailbreak thisJailbreak;

  Class'Jailbreak'.Default.bReverseSwitchColors = bReverseSwitchColors;
  Class'Jailbreak'.Static.StaticSaveConfig();

  foreach PlayerOwner().DynamicActors(Class'Jailbreak', thisJailbreak)
    thisJailbreak.bReverseSwitchColors = bReverseSwitchColors;

  foreach PlayerOwner().AllActors(Class'GameObjective', thisGameObjective)
    thisGameObjective.SetTeam(thisGameObjective.DefenderTeamIndex);
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  WindowName = "Jailbreak Client Options";
  WinTop     = 0.30;
  WinLeft    = 0.20;
  WinWidth   = 0.60;
  WinHeight  = 0.40;

  Begin Object class=moComboBox Name=VoicePack
    Caption                = "Voice Pack";
    CaptionWidth           = 0.35;
    bReadOnly              = True;
    WinTop                 = 0.40;
    WinLeft                = 0.24;
    WinWidth               = 0.43;
    TabOrder               = 1;
    Hint = "The voice pack to use in Jailbreak.";
  End Object
  co_VoicePack=VoicePack
  
  Begin Object Class=GUIButton Name=TestVoicePackButton
    Caption                = "Test";
    WinTop                 = 0.395;
    WinLeft                = 0.68;
    WinWidth               = 0.08;
    WinHeight              = 0.04;
    TabOrder               = 2;
    OnClick                = TestVoicePackClick;
    Hint = "Click to play a random test sample from the selected voice pack.";
  End Object
  b_TestVoicePack=TestVoicePackButton
  
  Begin Object Class=moCheckBox Name=EnableScreens
    Caption                = "Enable Dynamic Screen Textures";
    CaptionWidth           = 0.10;
    ComponentJustification = TXTA_Center;
    WinTop                 = 0.46;
    WinLeft                = 0.24;
    WinWidth               = 0.52;
    TabOrder               = 3;
    Hint = "Whether you want to see the dynamic screens placed in some Jailbreak maps. Disabling this setting may increase your framerate."
  End Object
  ch_EnableScreens=EnableScreens
  
  Begin Object Class=moCheckBox Name=ReverseSwitchColors
    Caption                = "Reverse Switch Colors";
    CaptionWidth           = 0.10;
    ComponentJustification = TXTA_Center;
    WinTop                 = 0.52;
    WinLeft                = 0.24;
    WinWidth               = 0.52;
    TabOrder               = 4;
    Hint = "Whether you want to reverse release switch colors so that the switch attacked by the red team is blue, and vice-versa."
  End Object
  ch_ReverseSwitchColors=ReverseSwitchColors
  
  Begin Object Class=GUIButton Name=ResetButton
    Caption                = "Defaults";
    WinTop                 = 0.60;
    WinLeft                = 0.24;
    WinWidth               = 0.12;
    WinHeight              = 0.04;
    TabOrder               = 5;
    OnClick                = InternalOnClick;
    Hint = "Restore all settings to their default value.";
  End Object
  b_Reset=ResetButton
  
  Begin Object Class=GUIButton Name=CancelButton
    Caption                = "Cancel";
    WinTop                 = 0.60;
    WinLeft                = 0.50;
    WinWidth               = 0.12;
    WinHeight              = 0.04;
    TabOrder               = 6;
    OnClick                = InternalOnClick;
    Hint = "Click to close this menu, discarding changes.";
  End Object
  b_Cancel=CancelButton
  
  Begin Object Class=GUIButton Name=OkButton
    Caption                = "OK";
    WinTop                 = 0.60;
    WinLeft                = 0.64;
    WinWidth               = 0.12;
    WinHeight              = 0.04;
    TabOrder               = 7;
    OnClick                = InternalOnClick;
    Hint = "Click to close this menu, saving changes.";
  End Object
  b_OK=OkButton
}