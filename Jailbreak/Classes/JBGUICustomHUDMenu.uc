// ============================================================================
// JBGUICustomHUDMenu
// Copyright (c) 2004 by Wormbo <wormbo@onlinehome.de>
// $Id: JBGUICustomHUDMenu.uc,v 1.1 2004/05/14 19:00:41 wormbo Exp $
//
// custom HUD configuration menu for Jailbreak's clientside settings.
// ============================================================================


class JBGUICustomHUDMenu extends UT2K4CustomHUDMenu;


// ============================================================================
// Variables
// ============================================================================

var automated moCombobox co_VoicePack;
var automated moCheckbox ch_EnableScreens;


// ============================================================================ 
// InitializeGameClass
//
// Loads the voice pack list and returns true so the LoadSettings function is
// called.
// ============================================================================

function bool InitializeGameClass(string GameClassName)
{
  LoadVoicePacks();
  return true;
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
  co_VoicePack.Find(Class'JBSpeechManager'.Static.GetVoicePack(), , True);
  ch_EnableScreens.Checked(GetEnableScreens());
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
  co_VoicePack.Find("JBVoiceGrrrl.Echo", , True);
  ch_EnableScreens.Checked(True);
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
    WinWidth               = 0.52;
    TabOrder               = 1;
    Hint = "The voice pack to use in Jailbreak.";
  End Object
  co_VoicePack=VoicePack
  
  Begin Object Class=moCheckBox Name=EnableScreens
    Caption                = "Enable Dynamic Screen Textures";
    CaptionWidth           = 0.10;
    ComponentJustification = TXTA_Center;
    WinTop                 = 0.50;
    WinLeft                = 0.24;
    WinWidth               = 0.52;
    TabOrder               = 2;
    Hint = "Whether you want to see the dynamic screens placed in some Jailbreak maps. Disabling this setting may increase your framerate."
  End Object
  ch_EnableScreens=EnableScreens
  
  Begin Object Class=GUIButton Name=ResetButton
    Caption                = "Defaults";
    WinTop                 = 0.60;
    WinLeft                = 0.24;
    WinWidth               = 0.12;
    WinHeight              = 0.04;
    TabOrder               = 3;
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
    TabOrder               = 4;
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
    TabOrder               = 5;
    OnClick                = InternalOnClick;
    Hint = "Click to close this menu, saving changes.";
  End Object
  b_OK=OkButton
}