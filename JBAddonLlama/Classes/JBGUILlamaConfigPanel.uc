//=============================================================================
// JBGUILlamaConfig
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id: JBGUILlamaConfigPanel.uc,v 1.1 2003/07/26 20:20:33 wormbo Exp $
//
// User interface panel for Llama Hunt configuration.
//=============================================================================


class JBGUILlamaConfigPanel extends GUIPanel;


//=============================================================================
// Constants
//=============================================================================

const CONTROL_REWARD_ADRENALINE  = 2;
const CONTROL_REWARD_HEALTH      = 3;
const CONTROL_MAX_LLAMA_DURATION = 4;

const DEFAULT_REWARD_ADRENALINE  = 100;
const DEFAULT_REWARD_HEALTH      = 25;
const DEFAULT_MAX_LLAMA_DURATION = 60;


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
  
  moNumericEdit(Controls[CONTROL_REWARD_ADRENALINE]).SetValue(class'JBAddonLlama'.default.RewardAdrenaline);
  moNumericEdit(Controls[CONTROL_REWARD_HEALTH]).SetValue(class'JBAddonLlama'.default.RewardHealth);
  moNumericEdit(Controls[CONTROL_MAX_LLAMA_DURATION]).SetValue(class'JBAddonLlama'.default.MaximumLlamaDuration);
  
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
  
  class'JBAddonLlama'.default.RewardAdrenaline     = moNumericEdit(Controls[CONTROL_REWARD_ADRENALINE]).GetValue();
  class'JBAddonLlama'.default.RewardHealth         = moNumericEdit(Controls[CONTROL_REWARD_HEALTH]).GetValue();
  class'JBAddonLlama'.default.MaximumLlamaDuration = moNumericEdit(Controls[CONTROL_MAX_LLAMA_DURATION]).GetValue();
  class'JBAddonLlama'.static.StaticSaveConfig();
}


//=============================================================================
// ResetConfiguration
//
// Resets the configurable properties to their default values.
//=============================================================================

function bool ResetConfiguration(GUIComponent Sender)
{
  moNumericEdit(Controls[CONTROL_REWARD_ADRENALINE]).SetValue(DEFAULT_REWARD_ADRENALINE);
  moNumericEdit(Controls[CONTROL_REWARD_HEALTH]).SetValue(DEFAULT_REWARD_HEALTH);
  moNumericEdit(Controls[CONTROL_MAX_LLAMA_DURATION]).SetValue(DEFAULT_MAX_LLAMA_DURATION);
  
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
    WinTop=0.3
    WinLeft=0.1
    WinHeight=0.1
    WinWidth=0.8
    Caption="Rewards for killing a Llama:"
  End Object
  Controls(1)=GUILabel'LlamaKillRewardLabel'
  
  Begin Object Class=moNumericEdit Name=RewardAdrenaline
    WinTop=0.4
    WinLeft=0.2
    WinHeight=0.1
    WinWidth=0.6
    Caption="Adrenaline"
    Hint="Adrenaline gained for killing a llama."
    CaptionWidth=0.666666
    MinValue=0
    MaxValue=100
    bHeightFromComponent=False
    OnChange=SaveINISettings
  End Object
  Controls(2)=moNumericEdit'RewardAdrenaline'
  
  Begin Object Class=moNumericEdit Name=RewardHealth
    WinTop=0.55
    WinLeft=0.2
    WinHeight=0.1
    WinWidth=0.6
    Caption="Health"
    Hint="Health gained for killing a llama."
    CaptionWidth=0.666666
    MinValue=0
    MaxValue=199
    bHeightFromComponent=False
    OnChange=SaveINISettings
  End Object
  Controls(3)=moNumericEdit'RewardHealth'
  
  Begin Object Class=moNumericEdit Name=MaximumLlamaDuration
    WinTop=0.1
    WinLeft=0.1
    WinHeight=0.1
    WinWidth=0.7
    Caption="Llama Hunt Duration"
    Hint="Maximum duration of a llama hunt."
    CaptionWidth=0.714286
    MinValue=10
    MaxValue=120
    bHeightFromComponent=False
    OnChange=SaveINISettings
  End Object
  Controls(4)=moNumericEdit'MaximumLlamaDuration'
  
  WinTop=0.330
  WinLeft=0.360
  WinWidth=0.610
  WinHeight=0.600
}