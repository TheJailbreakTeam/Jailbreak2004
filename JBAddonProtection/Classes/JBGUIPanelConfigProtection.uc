// ============================================================================
// JBGUIPanelConfigProtection
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBGUIPanelConfigProtection.uc,v 1.11 2004/05/12 09:14:42 wormbo Exp $
//
// Options for the protection add-on.
// ============================================================================


class JBGUIPanelConfigProtection extends JBGUIPanelConfig;


//=============================================================================
// Constants
//=============================================================================

const CONTROL_PROTECTION_TIME  = 0;
const CONTROL_PROTECTION_TYPE  = 1;
const CONTROL_PROTECT_ARENA    = 2;
const CONTROL_LLAMAIZE_CAMPERS = 3;


// ============================================================================
// Variables
// ============================================================================

var JBGUIComponentTrackbar ProtectionTime;
var JBGUIComponentOptions  ProtectionType;
var moCheckBox  ProtectArenaWinner;
var moCheckBox  LlamaizeCampers;
var private bool bInitialized;  // used to prevent saving config during initialization


// ============================================================================
// InitComponent
//
// Create the windows components.
// ============================================================================

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
  Super.InitComponent(MyController, MyOwner);

  ProtectionTime = JBGUIComponentTrackbar(Controls[CONTROL_PROTECTION_TIME]);
  ProtectionType = JBGUIComponentOptions(Controls[CONTROL_PROTECTION_TYPE]);
  ProtectArenaWinner = moCheckBox(Controls[CONTROL_PROTECT_ARENA]);
  LlamaizeCampers = moCheckBox(Controls[CONTROL_LLAMAIZE_CAMPERS]);
    
  LoadINISettings();
}


// ============================================================================
// ChangeOptions
//
// When you change any component value.
// ============================================================================

function ChangeOptions(GUIComponent Sender)
{
  if ( !bInitialized )
    return;

  if (ProtectionTime == None ||
      ProtectionType == None)
    return;

  class'JBAddonProtection'.default.ProtectionTime = int (ProtectionTime.GetValue());
  class'JBAddonProtection'.default.ProtectionType = byte(ProtectionType.GetIndex());
  class'JBAddonProtection'.default.bProtectArenaWinner = ProtectArenaWinner.IsChecked();
  class'JBAddonProtection'.default.bLlamaizeCampers = LlamaizeCampers.IsChecked();

  class'JBAddonProtection'.static.StaticSaveConfig();
}


//=============================================================================
// LoadINISettings
//
// Loads the values of all config GUI controls.
//=============================================================================

function LoadINISettings()
{
  bInitialized = False;
  ProtectionTime.SetValue(class'JBAddonProtection'.default.ProtectionTime);
  ProtectionType.SetIndex(class'JBAddonProtection'.default.ProtectionType);
  ProtectArenaWinner.Checked(class'JBAddonProtection'.default.bProtectArenaWinner);
  LlamaizeCampers.Checked(class'JBAddonProtection'.default.bLlamaizeCampers);
  bInitialized = True;
}


// ============================================================================
// ResetConfiguration
//
// When you click on Reset button.
// ============================================================================

function ResetConfiguration()
{
  class'JBAddonProtection'.static.ResetConfig();
  LoadINISettings();
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
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
    OptionHint(1) = "Protection is removed when you hit a player.";
    
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
    Hint="Players released from arenas get protection."
    bSquare=true
    bHeightFromComponent = False;

  End Object
  Controls(2)=moCheckBox'ProtectArenaWinnerCheckBox'
  
  Begin Object class=moCheckBox Name=LlamaizeCampersCheckBox
    WinTop        = 0.77; // weird
    WinLeft       = 0.0;
    WinHeight     = 0.07;
    WinWidth      = 0.667;
    CaptionWidth  = 0.9;
    OnChange=ChangeOptions
    Caption="Make jail campers llamas"
    Hint="Causing a protectee lethal damage makes you a llama."
    bSquare=true
    bHeightFromComponent = False;

  End Object
  Controls(3)=moCheckBox'LlamaizeCampersCheckBox'
}
