//=============================================================================
// JBGUIPanelConfigLlama
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id: JBGUIPanelConfigLlama.uc,v 1.10 2004/04/04 11:52:52 mychaeel Exp $
//
// User interface panel for Llama Hunt configuration.
//=============================================================================


class JBGUIPanelConfigLlama extends JBGUIPanelConfig;


//=============================================================================
// Constants
//=============================================================================

const CONTROL_REWARD_ADRENALINE  = 1;
const CONTROL_REWARD_HEALTH      = 2;
const CONTROL_REWARD_SHIELD      = 3;
const CONTROL_MAX_LLAMA_DURATION = 4;


//=============================================================================
// Variables
//=============================================================================

var private bool bInitialized;  // used to prevent executing SaveINISettings() during initialization


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
  JBGUIComponentTrackbar(Controls[CONTROL_REWARD_ADRENALINE]).SetValue(class'JBAddonLlama'.default.RewardAdrenaline);
  JBGUIComponentTrackbar(Controls[CONTROL_REWARD_HEALTH]).SetValue(class'JBAddonLlama'.default.RewardHealth);
  JBGUIComponentTrackbar(Controls[CONTROL_REWARD_SHIELD]).SetValue(class'JBAddonLlama'.default.RewardShield);
  JBGUIComponentTrackbar(Controls[CONTROL_MAX_LLAMA_DURATION]).SetValue(class'JBAddonLlama'.default.MaximumLlamaDuration);
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
  
  class'JBAddonLlama'.default.RewardAdrenaline     = JBGUIComponentTrackbar(Controls[CONTROL_REWARD_ADRENALINE]).GetValue();
  class'JBAddonLlama'.default.RewardHealth         = JBGUIComponentTrackbar(Controls[CONTROL_REWARD_HEALTH]).GetValue();
  class'JBAddonLlama'.default.RewardShield         = JBGUIComponentTrackbar(Controls[CONTROL_REWARD_SHIELD]).GetValue();
  class'JBAddonLlama'.default.MaximumLlamaDuration = JBGUIComponentTrackbar(Controls[CONTROL_MAX_LLAMA_DURATION]).GetValue();
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
  Begin Object Class=GUILabel Name=LlamaKillRewardLabel
    WinTop    =0.2 // row 2
    WinLeft   =0.0
    WinHeight =0.1
    WinWidth  =1.0
    Caption="Rewards for killing a Llama:"
    TextColor = (R=255,G=255,B=255);
  End Object
  Controls(0)=GUILabel'LlamaKillRewardLabel'
  
  Begin Object Class=JBGUIComponentTrackbar Name=RewardAdrenaline
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
  Controls(1)=JBGUIComponentTrackbar'RewardAdrenaline'
  
  Begin Object Class=JBGUIComponentTrackbar Name=RewardHealth
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
  Controls(2)=JBGUIComponentTrackbar'RewardHealth'
  
  Begin Object Class=JBGUIComponentTrackbar Name=RewardShield
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
  Controls(3)=JBGUIComponentTrackbar'RewardShield'
  
  Begin Object Class=JBGUIComponentTrackbar Name=MaximumLlamaDuration
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
  Controls(4)=JBGUIComponentTrackbar'MaximumLlamaDuration'
  
  WinTop=0.330
  WinLeft=0.360
  WinWidth=0.610
  WinHeight=0.600
}