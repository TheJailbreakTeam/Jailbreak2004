//=============================================================================
// JBGUILlamaConfig
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// User interface panel for Llama Hunt configuration.
//=============================================================================


class JBGUILlamaConfigPanel extends GUIPanel;


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
  
  moNumericEdit(Controls[1]).SetValue(class'JBAddonLlama'.default.RewardAdrenaline);
  moNumericEdit(Controls[2]).SetValue(class'JBAddonLlama'.default.RewardHealth);
  
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
  
  class'JBAddonLlama'.default.RewardAdrenaline = moNumericEdit(Controls[1]).GetValue();
  class'JBAddonLlama'.default.RewardHealth     = moNumericEdit(Controls[2]).GetValue();
  class'JBAddonLlama'.static.StaticSaveConfig();
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  Begin Object Class=GUILabel Name=LlamaKillRewardLabel
    WinTop=0.0
    WinLeft=0.0
    WinHeight=0.1
    WinWidth=1.0
    Caption="Rewards for killing a Llama:"
  End Object
  Controls(0)=GUILabel'LlamaKillRewardLabel'
  
  Begin Object Class=moNumericEdit Name=RewardAdrenaline
    WinTop=0.15
    WinLeft=0.2
    WinHeight=0.1
    WinWidth=0.4
    Caption="Adrenaline"
    CaptionWidth=0.6
    MinValue=0
    MaxValue=100
    bHeightFromComponent=False
    OnChange=SaveINISettings
  End Object
  Controls(1)=moNumericEdit'RewardAdrenaline'
  
  Begin Object Class=moNumericEdit Name=RewardHealth
    WinTop=0.3
    WinLeft=0.2
    WinHeight=0.1
    WinWidth=0.4
    Caption="Health"
    CaptionWidth=0.6
    MinValue=0
    MaxValue=199
    bHeightFromComponent=False
    OnChange=SaveINISettings
  End Object
  Controls(2)=moNumericEdit'RewardHealth'
  
  WinTop=0.330
  WinLeft=0.360
  WinWidth=0.610
  WinHeight=0.600
}