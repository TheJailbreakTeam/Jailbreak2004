// ============================================================================
// JBGUIPanelConfigProtection
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id$
//
// Option of protection mutator.
// ============================================================================
class JBGUIPanelConfigProtection extends JBGUIPanelConfig;


//=============================================================================
// Constants
//=============================================================================

const CONTROL_PROTECTION_TIME  = 0;
const CONTROL_PROTECTION_TYPE  = 1;
const CONTROL_PROTECT_ARENA    = 2;


// ============================================================================
// Variables
// ============================================================================
var JBGUIComponentTrackbar ProtectionTime;
var JBGUIComponentOptions  ProtectionType;
var moCheckBox  ProtectArenaWinner;
var localized string ProtectionTypeText[2];
var localized string SecondText, SecondsText;


// ============================================================================
// InitComponent
//
// Create the windows components.
// ============================================================================
function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    local int index;

    Super.InitComponent(MyController, MyOwner);

    // Protection time
    ProtectionTime = JBGUIComponentTrackbar(Controls[CONTROL_PROTECTION_TIME]);
    ProtectionTime.SetValue(int(class'JBAddonProtection'.default.ProtectionTime));

    // Protection type
    ProtectionType = JBGUIComponentOptions(Controls[CONTROL_PROTECTION_TYPE]);
    ProtectionType.SetIndex(class'JBAddonProtection'.default.ProtectionType);
    //log("JB set protection type to"@ class'JBAddonProtection'.default.ProtectionType);

    // Protect the arena winner
    ProtectArenaWinner = moCheckBox(Controls[CONTROL_PROTECT_ARENA]);
    ProtectArenaWinner.Checked(class'JBAddonProtection'.default.bProtectArenaWinner);
}


// ============================================================================
// ChangeOptions
//
// When you change any component value.
// ============================================================================
function ChangeOptions(GUIComponent Sender)
{
  if (ProtectionTime == None ||
      ProtectionType == None)
    return;

  class'JBAddonProtection'.default.ProtectionTime = int (ProtectionTime.GetValue());
  class'JBAddonProtection'.default.ProtectionType = byte(ProtectionType.GetIndex());
  class'JBAddonProtection'.default.bProtectArenaWinner = ProtectArenaWinner.IsChecked();
  
  class'JBAddonProtection'.static.StaticSaveConfig();
}


// ============================================================================
// ClickReset
//
// When you click on Reset button.
// ============================================================================
function ResetConfiguration()
{
    ProtectionTime.SetValue(3);
    ProtectionType.SetIndex(0);
    ProtectArenaWinner.Checked(TRUE);

    class'JBAddonProtection'.default.ProtectionTime = 3;
    class'JBAddonProtection'.default.ProtectionType = 0;
    class'JBAddonProtection'.default.bProtectArenaWinner = TRUE;
    class'JBAddonProtection'.static.StaticSaveConfig();

}


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
  ProtectionTypeText(0)="You can't inflict damage"
  ProtectionTypeText(1)="Drop when you inflict damage"
  SecondText="second"
  SecondsText="seconds"
  
  Begin Object Class=JBGUIComponentTrackbar Name=TrackbarProtectionTime
    WinTop    =0.0
    WinLeft   =0.0
    WinHeight =0.1
    WinWidth  =1.0
    CaptionWidth  = -1;
    SliderWidth   = 0.34;
    EditBoxWidth  = 0.18;
    Caption="Protection time"
    Hint="Duration of protection in seconds."
    MinValue=0
    MaxValue=10
    bIntegerOnly=True
    OnChange=ChangeOptions
  End Object
  Controls(0)=JBGUIComponentTrackbar'TrackbarProtectionTime'

  Begin Object class=JBGUIComponentOptions Name=OptionsProtectionType
    WinTop    = 0.2;
    WinLeft   = 0.0; 
    WinWidth  = 1.0;
    WinHeight = 0.5;
    
    GroupCaption = "Protection type:";

    OptionText(0) = "You can't inflict damage";
    OptionText(1) = "Drop when you inflict damage";
    
    OptionHint(0) = "Your weapons do no damage while protected.";
    OptionHint(1) = "Protection is removed when you fire on a player.";
    
    ItemHeight = 0.1;
    ButtonWidth=0.04;
    LabelWidth = 0.63;
    ItemIndent = 0.05;

    OnChange=ChangeOptions
  End Object
  Controls(1)=JBGUIComponentOptions'OptionsProtectionType'

  Begin Object class=moCheckBox Name=ProtectArenaWinnerCheckBox
    WinTop        =0.6
    WinLeft       =0.0
    WinHeight = 0.07; // for button to be right size
    WinWidth  = 0.667; // sets how far button is from left edge
    CaptionWidth  =0.9
    
    OnChange=ChangeOptions
    Caption="Protect the arena winner"
    Hint="When enabled, the arena winner is protected."
    bSquare=true
    bHeightFromComponent = False;

  End Object
  Controls(2)=moCheckBox'ProtectArenaWinnerCheckBox'
}
