//=============================================================================
// JBGUICustomHUDMenu
// Copyright (c) 2004 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// custom HUD configuration menu for Jailbreak's clientside settings.
//=============================================================================


class JBGUICustomHUDMenu extends UT2K4CustomHUDMenu;


//=============================================================================
// Variables
//=============================================================================

var automated moCombobox co_AnnouncerPackage;
var automated moCheckbox ch_EnableScreenMaps;


//=============================================================================
// InitializeGameClass
//
// Loads the announcer package list and returns true so the LoadSettings()
// function is called.
//=============================================================================

function bool InitializeGameClass(string GameClassName)
{
  LoadAnnouncerPacks();
  return true;
}


//=============================================================================
// LoadAnnouncerPacks
//
// Fills the co_AnnouncerPackage list.
//=============================================================================

function LoadAnnouncerPacks()
{
  log("LoadAnnouncerPacks()", Name);
}


//=============================================================================
// LoadSettings
//
// Called when initializing and by RestoreDefaults().
//=============================================================================

function LoadSettings()
{
  log("LoadSettings()", Name);
}


//=============================================================================
// SaveSettings
//
// Called when the page is closed with the OK button.
//=============================================================================

function SaveSettings()
{
  log("SaveSettings()", Name);
}


//=============================================================================
// RestoreDefaults
//
// Called when the reset button is clicked.
//=============================================================================

function RestoreDefaults()
{
  log("RestoreDefaults()", Name);
  Super.RestoreDefaults();
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  Begin Object Class=moCheckBox Name=EnableScreenMaps
    ComponentJustification=TXTA_Center
    CaptionWidth=0.100000
    Caption="Enable Screen Maps"
    Hint="Whether you want to see the overview maps placed in some Jailbreak maps."
    WinTop=0.4
    WinLeft=0.3
    WinWidth=0.4
    TabOrder=0
  End Object
  ch_EnableScreenMaps=EnableScreenMaps
  
  Begin Object class=moComboBox Name=AnnouncerPackage
    WinTop    = 0.45;
    WinLeft   = 0.3;
    WinWidth  = 0.4;
    CaptionWidth = 0.48;
    Caption="Announcer Package"
    Hint="The announcer package to use in Jailbreak."
  End Object
  co_AnnouncerPackage=AnnouncerPackage
  
  Begin Object Class=GUIButton Name=CancelButton
    Caption="Cancel"
    Hint="Click to close this menu, discarding changes."
    WinTop=0.6
    WinLeft=0.5
    WinWidth=0.1
    WinHeight=0.04
    TabOrder=4
    OnClick=InternalOnClick
  End Object
  b_Cancel=CancelButton
  
  Begin Object Class=GUIButton Name=ResetButton
    Caption="Defaults"
    Hint="Restore all settings to their default value."
    WinTop=0.6
    WinLeft=0.3
    WinWidth=0.1
    WinHeight=0.04
    TabOrder=3
    OnClick=InternalOnClick
  End Object
  b_Reset=ResetButton
  
  Begin Object Class=GUIButton Name=OkButton
    Caption="OK"
    Hint="Click to close this menu, saving changes."
    WinTop=0.6
    WinLeft=0.62
    WinWidth=0.1
    WinHeight=0.04
    TabOrder=2
    OnClick=InternalOnClick
  End Object
  b_OK=OkButton
  
  WindowName="Jailbreak Clientside Options"
  WinTop=0.3
  WinLeft=0.25
  WinWidth=0.5
  WinHeight=0.4
}