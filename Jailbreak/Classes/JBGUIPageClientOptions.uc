// ============================================================================
// JBGUIPageClientOptions
// Copyright 2004 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBGUIPageClientOptions.uc,v 1.1.2.1 2004/05/17 17:29:00 mychaeel Exp $
//
// Dialog box for Jailbreak's client-side settings. Hooks a button into the
// mid-game menu.
// ============================================================================


class JBGUIPageClientOptions extends GUIPage;


// ============================================================================
// Variables
// ============================================================================

var moCombobox co_VoicePack;
var GUIButton b_TestVoicePack;
var moCheckbox ch_EnableScreens;

var GUIButton b_Reset;
var GUIButton b_Cancel;
var GUIButton b_OK;

var private string VoicePackPrev;


// ============================================================================ 
// Hook
//
// Checks whether the mid-game menu is currently visible. If so, adds the
// button that opens this dialog box if it is not present already.
// ============================================================================ 

static function Hook(PlayerController PlayerController)
{
  local UT2MidGameMenu UT2MidGameMenu;
  local JBGUIButtonClientOptions JBGUIButtonClientOptions;
  
  if (GUIController(PlayerController.Player.GUIController).ActivePage == None)
    return;

  foreach PlayerController.AllObjects(Class'UT2MidGameMenu', UT2MidGameMenu)
    if (UT2MidGameMenu.Controls.Length == UT2MidGameMenu.Default.Controls.Length)
      break;

  if (UT2MidGameMenu == None)
    return;

  // move server browser button to the left
  UT2MidGameMenu.Controls[7].WinLeft -= (UT2MidGameMenu.ButtonWidth + UT2MidGameMenu.ButtonHGap) / 2.0;

  JBGUIButtonClientOptions = new(None) Class'JBGUIButtonClientOptions';
  JBGUIButtonClientOptions.WinTop    = UT2MidGameMenu.Controls[7].WinTop;
  JBGUIButtonClientOptions.WinLeft   = UT2MidGameMenu.Controls[7].WinLeft + UT2MidGameMenu.ButtonWidth + UT2MidGameMenu.ButtonHGap;
  JBGUIButtonClientOptions.WinWidth  = UT2MidGameMenu.ButtonWidth;
  JBGUIButtonClientOptions.WinHeight = UT2MidGameMenu.ButtonHeight;

  JBGUIButtonClientOptions.InitComponent(UT2MidGameMenu.Controller, UT2MidGameMenu);
  UT2MidGameMenu.Controls[UT2MidGameMenu.Controls.Length] = JBGUIButtonClientOptions;
}


// ============================================================================ 
// InitComponent
//
// Loads current settings after initializing the component.
// ============================================================================

function InitComponent(GUIController GUIController, GUIComponent GUIComponentOwner)
{
  Super.InitComponent(GUIController, GUIComponentOwner);

  co_VoicePack     = moComboBox(Controls[2]);
  b_TestVoicePack  = GUIButton (Controls[3]);
  ch_EnableScreens = moCheckBox(Controls[4]);

  b_Reset  = GUIButton(Controls[5]);
  b_Cancel = GUIButton(Controls[6]);
  b_OK     = GUIButton(Controls[7]);

  LoadVoicePacks();
  LoadSettings();

  if (UT2MidGameMenu(ParentPage) != None)
    ParentPage.InactiveFadeColor.A = 0;
}


// ============================================================================
// LoadVoicePacks
//
// Fills the co_VoicePack list.
// ============================================================================

function LoadVoicePacks()
{
  local int iVoicePack;
  local string Entry;
  local string Description;

  if (DynamicLoadObject("Jailbreak.JBVoice", Class'Class', False) == None)
    return;  // unable to load MetaClass, so GetAllIntDesc would crash

  for (iVoicePack = 0; True; iVoicePack++) {
    PlayerOwner().GetNextIntDesc("Jailbreak.JBVoice", iVoicePack, Entry, Description);
    if (Entry == "")
      break;
    co_VoicePack.AddItem(Description, , Entry);
  }
}


// ============================================================================
// LoadSettings
//
// Called when initializing the component. Loads current settings.
// ============================================================================

function LoadSettings()
{
  local int iVoicePack;
  local int nVoicePacks;
  
  VoicePackPrev = Class'JBSpeechManager'.Static.GetVoicePack();
  
  nVoicePacks = co_VoicePack.ItemCount();
  for (iVoicePack = 0; iVoicePack < nVoicePacks; iVoicePack++)
    if (co_VoicePack.MyComboBox.List.GetExtraAtIndex(iVoicePack) ~= VoicePackPrev)
      co_VoicePack.Find(co_VoicePack.GetItem(iVoicePack), True);

  co_VoicePack.OnChange = VoicePackChange;

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
  local int iVoicePack;
  local int nVoicePacks;
  
  nVoicePacks = co_VoicePack.ItemCount();
  for (iVoicePack = 0; iVoicePack < nVoicePacks; iVoicePack++)
    if (co_VoicePack.MyComboBox.List.GetExtraAtIndex(iVoicePack) ~= "JBVoiceGrrrl.Echo")
      co_VoicePack.Find(co_VoicePack.GetItem(iVoicePack), True);
  
  ch_EnableScreens.Checked(True);
}


// ============================================================================
// InternalOnClick
//
// Called when a button is clicked. Performs the necessary actions.
// ============================================================================

function bool InternalOnClick(GUIComponent GUIComponentSender)
{
  switch (GUIComponentSender) {
    case b_Reset:   RestoreDefaults();            break;
    case b_Cancel:  Controller.CloseMenu(True);   break;
    case b_OK:      Controller.CloseMenu(False);  break;
  }

  return True;
}


// ============================================================================
// InternalOnClose
//
// Called when the dialog is closed. Saves changes if not cancelled.
// ============================================================================

function InternalOnClose(optional bool bCancelled)
{
  if (bCancelled)
    Class'JBSpeechManager'.Static.SetVoicePack(VoicePackPrev);
  else
    SaveSettings();

  if (UT2MidGameMenu(ParentPage) != None)
    ParentPage.InactiveFadeColor.A = ParentPage.Default.InactiveFadeColor.A;
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
  WinTop    = 0.30;
  WinLeft   = 0.20;
  WinWidth  = 0.60;
  WinHeight = 0.40;
  
  bRequire640x480  = False;
  bAllowedAsLast   = True;
  bPauseIfPossible = True;

  OnClose = InternalOnClose;

  Begin Object Class=GUIButton Name=DialogBackground
    WinTop                 = 0.00;
    WinLeft                = 0.00;
    WinWidth               = 1.00;
    WinHeight              = 1.00;
    bAcceptsInput          = False;
    bNeverFocus            = True;
    StyleName              = "SquareButton";
    bBoundToParent         = True;
    bScaleToParent         = True;
  End Object
  Controls[0] = GUIButton'DialogBackground';
  
  Begin Object Class=GUILabel Name=DialogTitle
    Caption                = "Jailbreak Client Options";
    TextAlign              = TXTA_Center;
    TextColor              = (R=255,G=210,B=0);
    WinTop                 = 0.00;
    WinLeft                = 0.00;
    WinWidth               = 1.00;
    WinHeight              = 0.15;
    bBoundToParent         = True;
    bScaleToParent         = True;
  End Object
  Controls[1] = GUILabel'DialogTitle';

  Begin Object Class=moComboBox Name=VoicePack
    Caption                = "Voice Pack";
    CaptionWidth           = 0.35;
    bReadOnly              = True;
    WinTop                 = 0.40;
    WinLeft                = 0.24;
    WinWidth               = 0.43;
    Hint = "The voice pack to use in Jailbreak.";
  End Object
  Controls[2] = moComboBox'VoicePack';
  
  Begin Object Class=GUIButton Name=TestVoicePackButton
    Caption                = "Test";
    WinTop                 = 0.40;
    WinLeft                = 0.68;
    WinWidth               = 0.08;
    WinHeight              = 0.06;
    StyleName              = "SquareButton";
    OnClick                = TestVoicePackClick;
    Hint = "Click to play a random test sample from the selected voice pack.";
  End Object
  Controls[3] = GUIButton'TestVoicePackButton';

  Begin Object Class=moCheckBox Name=EnableScreens
    Caption                = "Enable Dynamic Screen Textures";
    CaptionWidth           = 0.90;
    ComponentJustification = TXTA_Center;
    bSquare                = True;
    WinTop                 = 0.50;
    WinLeft                = 0.24;
    WinWidth               = 0.52;
    Hint = "Whether you want to see the dynamic screens placed in some Jailbreak maps. Disabling this setting may increase your framerate."
  End Object
  Controls[4] = moCheckBox'EnableScreens';
  
  Begin Object Class=GUIButton Name=ResetButton
    Caption                = "Defaults";
    WinTop                 = 0.60;
    WinLeft                = 0.24;
    WinWidth               = 0.12;
    WinHeight              = 0.04;
    OnClick                = InternalOnClick;
    Hint = "Restore all settings to their default value.";
  End Object
  Controls[5] = GUIButton'ResetButton';
  
  Begin Object Class=GUIButton Name=CancelButton
    Caption                = "Cancel";
    WinTop                 = 0.60;
    WinLeft                = 0.50;
    WinWidth               = 0.12;
    WinHeight              = 0.04;
    OnClick                = InternalOnClick;
    Hint = "Click to close this menu, discarding changes.";
  End Object
  Controls[6] = GUIButton'CancelButton';
  
  Begin Object Class=GUIButton Name=OkButton
    Caption                = "OK";
    WinTop                 = 0.60;
    WinLeft                = 0.64;
    WinWidth               = 0.12;
    WinHeight              = 0.04;
    OnClick                = InternalOnClick;
    Hint = "Click to close this menu, saving changes.";
  End Object
  Controls[7] = GUIButton'OkButton';
}