// ============================================================================
// JBLocalMessageArenaLockdown - original by _Lynx
// Copyright 2006 by Jrubzjeknf <rrvanolst@hotmail.com>
// $Id
//
// Addon's GUI.
// ============================================================================

class JBGUIPanelConfigArenaLockdown extends JBGUIPanelConfig;


//=============================================================================
// Variables
//=============================================================================

var private bool bInitialized;  // used to prevent executing SaveINISettings() during initialization

var automated moCheckbox ch_CrossBaseSpawning;
var automated moComboBox co_SelectionMethod;

var localized string str_FIFO;
var localized string str_Random;


//=============================================================================
// InitComponent
//
// Sets the values for co_RestartPlayers dropdown box and loads the
// configurable values.
//=============================================================================

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
  Super.InitComponent(MyController, MyOwner);

  co_SelectionMethod.AddItem(str_FIFO);
  co_SelectionMethod.AddItem(str_Random);

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

  ch_CrossBaseSpawning.Checked(class'JBAddonArenaLockdown'.default.bCrossBaseSpawning);
  co_SelectionMethod.SetIndex (class'JBAddonArenaLockdown'.default.SelectionMethod);

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

  class'JBAddonArenaLockdown'.default.bCrossBaseSpawning = ch_CrossBaseSpawning.IsChecked();
  class'JBAddonArenaLockdown'.default.SelectionMethod    = co_SelectionMethod.GetIndex();

  class'JBAddonArenaLockdown'.static.StaticSaveConfig();
}


//=============================================================================
// ResetConfiguration
//
// Resets the configurable properties to their default values.
//=============================================================================

function ResetConfiguration()
{
  class'JBAddonArenaLockdown'.static.ResetConfig();

  LoadINISettings();
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  str_FIFO   = "Queue"
  str_Random = "Random"

  Begin Object Class=moCheckBox Name=CrossBaseSpawningCheckBox
    CaptionWidth=0.8
    Caption="Random base spawning"
    Hint="Players can be spawned in their enemy's base, so that basecamping is discouraged."
      WinTop   =0.015000
      WinLeft  =0.000000
      WinWidth =1.000000
      WinHeight=0.100000
    TabOrder=1
    OnChange=SaveINISettings
  End Object
  ch_CrossBaseSpawning=moCheckBox'JBAddonArenaLockdown.JBGUIPanelConfigArenaLockdown.CrossBaseSpawningCheckBox'.

  Begin Object Class=moComboBox Name=SelectionMethodComboBox
    bReadOnly=True
    CaptionWidth=0.8
    Caption="Selection method"
    Hint="Choose how the arena players will be picked from their jail."
      WinTop   =0.215000
      WinLeft  =0.000000
      WinWidth =1.000000
      WinHeight=0.100000
    TabOrder=2
    OnChange=SaveINISettings
  End Object
  co_SelectionMethod=moComboBox'JBAddonArenaLockdown.JBGUIPanelConfigArenaLockdown.SelectionMethodComboBox'
}

