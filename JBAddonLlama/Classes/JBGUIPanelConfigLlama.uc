//=============================================================================
// JBGUIPanelConfigLlama
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id: JBGUIPanelConfigLlama.uc,v 1.11 2004/05/11 10:53:10 wormbo Exp $
//
// User interface panel for Llama Hunt configuration.
//=============================================================================


class JBGUIPanelConfigLlama extends JBGUIPanelConfig;


//=============================================================================
// Variables
//=============================================================================

var private bool bInitialized;  // used to prevent executing SaveINISettings() during initialization

var automated GUILabel               RewardLabel;
var automated JBGUIComponentTrackbar RewardAdrenaline;
var automated JBGUIComponentTrackbar RewardHealth;
var automated JBGUIComponentTrackbar RewardShield;
var automated JBGUIComponentTrackbar MaxLlamaDuration;
var automated moCheckbox             LlamaizeOnJailDisconnect;


//=============================================================================
// InitComponent
//
// Loads the configurable values.
//=============================================================================

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
  Super.InitComponent(MyController, MyOwner);
  
  LoadINISettings();
}

//=============================================================================
// LoadINISettings
//
// Loads the values of all config GUI controls.
//=============================================================================

function LoadINISettings()
{
  bInitialized = False;
  RewardAdrenaline.SetValue(class'JBAddonLlama'.default.RewardAdrenaline);
  RewardHealth.SetValue(class'JBAddonLlama'.default.RewardHealth);
  RewardShield.SetValue(class'JBAddonLlama'.default.RewardShield);
  MaxLlamaDuration.SetValue(class'JBAddonLlama'.default.MaximumLlamaDuration);
  LlamaizeOnJailDisconnect.Checked(class'JBAddonLlama'.default.bLlamaizeOnJailDisconnect);
  bInitialized = True;
}


//=============================================================================
// SaveINISettings
//
// Called when a value of a control changed.
// Saves the values of all config GUI controls.
//=============================================================================

function SaveINISettings(GUIComponent Sender)
{
  if ( !bInitialized )
    return;
  
  class'JBAddonLlama'.default.RewardAdrenaline          = RewardAdrenaline.GetValue();
  class'JBAddonLlama'.default.RewardHealth              = RewardHealth.GetValue();
  class'JBAddonLlama'.default.RewardShield              = RewardShield.GetValue();
  class'JBAddonLlama'.default.MaximumLlamaDuration      = MaxLlamaDuration.GetValue();
  class'JBAddonLlama'.default.bLlamaizeOnJailDisconnect = LlamaizeOnJailDisconnect.IsChecked();
  class'JBAddonLlama'.static.StaticSaveConfig();
}


//=============================================================================
// ResetConfiguration
//
// Resets the configurable properties to their default values.
//=============================================================================

function ResetConfiguration()
{
  class'JBAddonLlama'.static.ResetConfig();
  LoadINISettings();
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  Begin Object Class=JBGUIComponentTrackbar Name=trkMaximumLlamaDuration
    WinTop    =0.0 // row 1
    WinLeft   =0.0
    WinHeight =0.1
    WinWidth  =1.0
    CaptionWidth  = -1;
    SliderWidth   = 0.34;
    EditBoxWidth  = 0.18;
  
    Caption="Llama Hunt duration"
    Hint="Maximum duration of a llama hunt."
    MinValue=10
    MaxValue=120
    bIntegerOnly=True
    OnChange=SaveINISettings
  End Object
  MaxLlamaDuration = trkMaximumLlamaDuration
  
  Begin Object Class=GUILabel Name=LlamaKillRewardLabel
    WinTop    =0.2 // row 2
    WinLeft   =0.0
    WinHeight =0.1
    WinWidth  =1.0
    Caption="Rewards for killing a Llama:"
    TextColor = (R=255,G=255,B=255);
  End Object
  RewardLabel = LlamaKillRewardLabel
  
  Begin Object Class=JBGUIComponentTrackbar Name=trkRewardAdrenaline
    WinTop=0.3
    WinLeft   =0.0
    WinHeight =0.1
    WinWidth  =1.0
    CaptionWidth  = -1;
    SliderWidth   = 0.34;
    EditBoxWidth  = 0.18;
    LeftIndent    = 0.05

    Caption="Adrenaline"
    Hint="Adrenaline gained for killing a llama."
    MinValue=0
    MaxValue=100
    bIntegerOnly=True
    OnChange=SaveINISettings
  End Object
  RewardAdrenaline = trkRewardAdrenaline
  
  Begin Object Class=JBGUIComponentTrackbar Name=trkRewardHealth
    WinTop=0.45
    WinLeft   =0.0
    WinHeight =0.1
    WinWidth  =1.0
    CaptionWidth  = -1;
    SliderWidth   = 0.34;
    EditBoxWidth  = 0.18;
    LeftIndent    = 0.05

    Caption="Health"
    Hint="Health gained for killing a llama."
    MinValue=0
    MaxValue=199
    bIntegerOnly=True
    OnChange=SaveINISettings
  End Object
  RewardHealth = trkRewardHealth
  
  Begin Object Class=JBGUIComponentTrackbar Name=trkRewardShield
    WinTop=0.6
    WinLeft   =0.0
    WinHeight =0.1
    WinWidth  =1.0
    CaptionWidth  = -1;
    SliderWidth   = 0.34;
    EditBoxWidth  = 0.18;
    LeftIndent    = 0.05
    
    Caption="Shield"
    Hint="Shield gained for killing a llama."
    MinValue=0
    MaxValue=150
    bIntegerOnly=True
    OnChange=SaveINISettings
  End Object
  RewardShield = trkRewardShield
  
  Begin Object Class=moCheckbox Name=chkLlamaizeOnJailDisconnect
    WinTop    =0.8
    WinLeft   =0.0
    WinHeight =0.1
    WinWidth  =1.0
    Caption="Llamaize on jail disconnect"
    Hint="Llamaize players who disconnect and reconnect to get out of jail."
    OnChange=SaveINISettings
  End Object
  LlamaizeOnJailDisconnect = chkLlamaizeOnJailDisconnect
  
  WinTop=0.330
  WinLeft=0.360
  WinWidth=0.610
  WinHeight=0.600
}