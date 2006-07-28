// ============================================================================
// JBGUIPanelConfigPersistence
// Copyright 2006 by Mitchell Davis <mitchelld02@yahoo.com>
//
// The user interface for JBAddonPersistence.
// ============================================================================

class JBGUIPanelConfigPersistence extends JBGUIPanelConfig;

//=============================================================================
// Variables
//=============================================================================

var private bool bInitialized;  // used to prevent executing SaveINISettings() during initialization

var automated GUILabel UprisingLabel;
var automated JBGUIComponentTrackBar HealthTransfer;
var automated moCheckBox UprisingChk;

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
  bInitialized = false;
  UprisingChk.Checked(class'JBAddonPersistence'.default.bUprising);
  HealthTransfer.SetValue(class'JBAddonPersistence'.default.nHealth);

  bInitialized = true;
}


//=============================================================================
// SaveINISettings
//
// Called when a value of a control changed.
// Saves the values of all config GUI controls.
//=============================================================================

function SaveINISettings(GUIComponent Sender)
{
  if(!bInitialized)
    return;

  class'JBAddonPersistence'.default.bUprising = UprisingChk.IsChecked();
  class'JBAddonPersistence'.default.nHealth = HealthTransfer.GetValue();
  class'JBAddonPersistence'.static.StaticSaveConfig();
}


//=============================================================================
// ResetConfiguration
//
// Resets the configurable properties to their default values.
//=============================================================================

function ResetConfiguration()
{
  class'JBAddonPersistence'.static.ResetConfig();
  LoadINISettings();
}

defaultproperties
{
  Begin Object Class=moCheckBox Name=chkUprising
    Caption="The Uprising"
    OnCreateComponent=chkUprising.InternalOnCreateComponent
    Hint="Capturing team loses weapons to the captured team. Weapons throwing is disabled with this option selected."
    WinTop=0.000000
    WinLeft=0.000000
    WinWidth=1.000000
    WinHeight=0.100000
    OnChange=JBGUIPanelConfigPersistence.SaveINISettings
  End Object
  UprisingChk=moCheckBox'JBAddonPersistence.JBGUIPanelConfigPersistence.chkUprising'

  Begin Object Class=JBGUIComponentTrackbar Name=trkHealthTransfer
    MinValue=0.00
    MaxValue=50.00
    bIntegerOnly=True
    Caption="Health Transfer"
    CaptionWidth=-1.000000
    EditBoxWidth=0.180000
    SliderWidth=0.340000
    Hint="The amount of health that gets transferred from Capturing to Captured."
    WinTop=0.20
    WinLeft=0.00
    WinWidth=1.000000
    WinHeight=0.100000
    OnChange=JBGUIPanelConfigPersistence.SaveINISettings
  End Object
  HealthTransfer=JBGUIComponentTrackbar'JBAddonPersistence.JBGUIPanelConfigPersistence.trkHealthTransfer'
}
