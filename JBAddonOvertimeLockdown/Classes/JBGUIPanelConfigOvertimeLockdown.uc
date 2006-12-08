// ============================================================================
// JBLocalMessageOvertimeLockdown - original by _Lynx
// Copyright 2006 by Jrubzjeknf <rrvanolst@hotmail.com>
// $Id$
//
// Addon's GUI.
// ============================================================================


class JBGUIPanelConfigOvertimeLockdown extends JBGUIPanelConfig;


//=============================================================================
// Variables
//=============================================================================

var private bool bInitialized;  // used to prevent executing SaveINISettings() during initialization

var automated moCheckbox             ch_NoArenaInOvertime;
var automated moCheckbox             ch_NoEscapeInOvertime;
var automated moComboBox             co_RestartPlayers;
var automated JBGUIComponentTrackbar tb_LockdownDelay;

var localized string str_RestartAllPlayers;
var localized string str_RestartOnlyFreePlayers;
var localized string str_DoNotRestart;


//=============================================================================
// InitComponent
//
// Sets the values for co_RestartPlayers dropdown box and loads the
// configurable values.
//=============================================================================

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
  Super.InitComponent(MyController, MyOwner);

  co_RestartPlayers.AddItem(str_DoNotRestart);
  co_RestartPlayers.AddItem(str_RestartOnlyFreePlayers);
  co_RestartPlayers.AddItem(str_RestartAllPlayers);

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

  ch_NoArenaInOvertime.Checked (class'JBAddonOvertimeLockdown'.default.bNoArenaInOvertime);
  ch_NoEscapeInOvertime.Checked(class'JBAddonOvertimeLockdown'.default.bNoEscapeInOvertime);
  co_RestartPlayers.SetIndex   (class'JBAddonOvertimeLockdown'.default.RestartPlayers);
  tb_LockdownDelay.SetValue    (class'JBAddonOvertimeLockdown'.default.LockdownDelay);

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
  if (!bInitialized)
    return;

  class'JBAddonOvertimeLockdown'.default.bNoArenaInOvertime  = ch_NoArenaInOvertime.IsChecked();
  class'JBAddonOvertimeLockdown'.default.bNoEscapeInOvertime = ch_NoEscapeInOvertime.IsChecked();
  class'JBAddonOvertimeLockdown'.default.RestartPlayers      = co_RestartPlayers.GetIndex();
  class'JBAddonOvertimeLockdown'.default.LockdownDelay       = tb_LockdownDelay.GetValue();

  class'JBAddonOvertimeLockdown'.static.StaticSaveConfig();
}


//=============================================================================
// ResetConfiguration
//
// Resets the configurable properties to their default values.
//=============================================================================

function ResetConfiguration()
{
  class'JBAddonOvertimeLockdown'.static.ResetConfig();

  LoadINISettings();
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  str_RestartAllPlayers="All players"
  str_RestartOnlyFreePlayers="Free players"
  str_DoNotRestart="No-one"

  Begin Object Class=moCheckBox Name=NoArenaInOvertimeCheckBox
    CaptionWidth=0.6
    Caption="No arena matches in Overtime"
    Hint="No arena matches will start when the game goes into overtime. Pending matches will be cancelled."
      WinTop   =0.015000
      WinLeft  =0.000000
      WinWidth =1.000000
      WinHeight=0.100000
    TabOrder=0
    OnChange=SaveINISettings
  End Object
  ch_NoArenaInOvertime=moCheckBox'JBaddonOvertimeLockdown.JBGUIPanelConfigOvertimeLockdown.NoArenaInOvertimeCheckBox'

  Begin Object Class=moCheckBox Name=NoEscapeInOvertimeCheckBox
    CaptionWidth=0.6
    Caption="No escapes in Overtime"
    Hint="Players who try to get out of jail during the Lockdown, will be killed."
      WinTop   =0.215000
      WinLeft  =0.000000
      WinWidth =1.000000
      WinHeight=0.100000
    TabOrder=1
    OnChange=SaveINISettings
  End Object
  ch_NoEscapeInOvertime=moCheckBox'JBaddonOvertimeLockdown.JBGUIPanelConfigOvertimeLockdown.NoEscapeInOvertimeCheckBox'

  Begin Object Class=moComboBox Name=RestartPlayersComboBox
    bReadOnly=True
    CaptionWidth=0.6
    Caption="Restart players in Overtime"
    Hint="Restart all, free or no players when the game goes into overtime."
      WinTop   =0.400000
      WinLeft  =0.000000
      WinWidth =1.000000
      WinHeight=0.100000
    TabOrder=2
    OnChange=SaveINISettings
  End Object
  co_RestartPlayers=moComboBox'JBaddonOvertimeLockdown.JBGUIPanelConfigOvertimeLockdown.RestartPlayersComboBox'

  Begin Object Class=JBGUIComponentTrackbar Name=LockdownDelayTrackBar
    CaptionWidth=-1
    Caption="Lockdown delay"
    Hint="How long normal overtime should last before before the lockdown kicks in."
      WinTop   =0.600000
      WinLeft  =0.000000
      WinWidth =1.000000
      WinHeight=0.100000
    TabOrder=3
    SliderWidth =0.34;
    EditBoxWidth=0.18;
    MinValue=0
    MaxValue=15
    bIntegerOnly=True
    OnChange=SaveINISettings
  End Object
  tb_LockdownDelay = LockdownDelayTrackBar
}