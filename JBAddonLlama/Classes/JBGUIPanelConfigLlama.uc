//=============================================================================
// JBGUIPanelConfigLlama
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id: JBGUIPanelConfigLlama.uc,v 1.5 2004/03/09 18:57:08 wormbo Exp $
//
// User interface panel for Llama Hunt configuration.
//=============================================================================


class JBGUIPanelConfigLlama extends GUIPanel;


//=============================================================================
// Constants
//=============================================================================

const CONTROL_REWARD_ADRENALINE  = 2;
const CONTROL_REWARD_HEALTH      = 3;
const CONTROL_REWARD_SHIELD      = 4;
const CONTROL_MAX_LLAMA_DURATION = 5;


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
  JBGUIEditSlider(Controls[CONTROL_REWARD_ADRENALINE]).SetValue(class'JBAddonLlama'.default.RewardAdrenaline);
  JBGUIEditSlider(Controls[CONTROL_REWARD_HEALTH]).SetValue(class'JBAddonLlama'.default.RewardHealth);
  JBGUIEditSlider(Controls[CONTROL_REWARD_SHIELD]).SetValue(class'JBAddonLlama'.default.RewardShield);
  JBGUIEditSlider(Controls[CONTROL_MAX_LLAMA_DURATION]).SetValue(class'JBAddonLlama'.default.MaximumLlamaDuration);
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
  
  class'JBAddonLlama'.default.RewardAdrenaline     = JBGUIEditSlider(Controls[CONTROL_REWARD_ADRENALINE]).GetValue();
  class'JBAddonLlama'.default.RewardHealth         = JBGUIEditSlider(Controls[CONTROL_REWARD_HEALTH]).GetValue();
  class'JBAddonLlama'.default.RewardShield         = JBGUIEditSlider(Controls[CONTROL_REWARD_SHIELD]).GetValue();
  class'JBAddonLlama'.default.MaximumLlamaDuration = JBGUIEditSlider(Controls[CONTROL_MAX_LLAMA_DURATION]).GetValue();
  class'JBAddonLlama'.static.StaticSaveConfig();
}


//=============================================================================
// ResetConfiguration
//
// Resets the configurable properties to their default values.
//=============================================================================

function bool ResetConfiguration(GUIComponent Sender)
{
  class'JBAddonLlama'.static.ResetConfiguration();
  LoadINISettings();
  
  return True;
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  Begin Object Class=GUIButton Name=ResetButton
    Caption="RESET"
    WinWidth=0.3
    WinHeight=0.1
    WinLeft=0.7
    WinTop=0.9
    Hint="Reset Llama Hunt options."
    OnClick=ResetConfiguration
  End Object
  Controls(0)=GUIButton'ResetButton'

  Begin Object Class=GUILabel Name=LlamaKillRewardLabel
    WinTop=0.2
    WinLeft=0.05
    WinHeight=0.1
    WinWidth=0.8
    Caption="Rewards for killing a Llama:"
  End Object
  Controls(1)=GUILabel'LlamaKillRewardLabel'
  
  Begin Object Class=JBGUIEditSlider Name=RewardAdrenaline
    WinTop=0.3
    WinLeft=0.15
    WinHeight=0.1
    WinWidth=0.8
    Caption="Adrenaline"
    Hint="Adrenaline gained for killing a llama."
    CaptionWidth=0.4
    SliderWidth=-1
    EditBoxWidth=0.2
    MinValue=0
    MaxValue=100
    bIntegerOnly=True
    OnChange=SaveINISettings
  End Object
  Controls(2)=JBGUIEditSlider'RewardAdrenaline'
  
  Begin Object Class=JBGUIEditSlider Name=RewardHealth
    WinTop=0.45
    WinLeft=0.15
    WinHeight=0.1
    WinWidth=0.8
    Caption="Health"
    Hint="Health gained for killing a llama."
    CaptionWidth=0.4
    SliderWidth=-1
    EditBoxWidth=0.2
    MinValue=0
    MaxValue=199
    bIntegerOnly=True
    OnChange=SaveINISettings
  End Object
  Controls(3)=JBGUIEditSlider'RewardHealth'
  
  Begin Object Class=JBGUIEditSlider Name=RewardShield
    WinTop=0.6
    WinLeft=0.15
    WinHeight=0.1
    WinWidth=0.8
    Caption="Shield"
    Hint="Shield gained for killing a llama."
    CaptionWidth=0.4
    SliderWidth=-1
    EditBoxWidth=0.2
    MinValue=0
    MaxValue=150
    bIntegerOnly=True
    OnChange=SaveINISettings
  End Object
  Controls(4)=JBGUIEditSlider'RewardShield'
  
  Begin Object Class=JBGUIEditSlider Name=MaximumLlamaDuration
    WinTop=0.0
    WinLeft=0.05
    WinHeight=0.1
    WinWidth=0.9
    Caption="Llama Hunt Duration"
    Hint="Maximum duration of a llama hunt."
    CaptionWidth=0.475
    SliderWidth=-1
    EditBoxWidth=0.175
    MinValue=10
    MaxValue=120
    bIntegerOnly=True
    OnChange=SaveINISettings
  End Object
  Controls(5)=JBGUIEditSlider'MaximumLlamaDuration'
  
  WinTop=0.330
  WinLeft=0.360
  WinWidth=0.610
  WinHeight=0.600
}