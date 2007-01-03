// ============================================================================
// JBGUIPanelConfigSpoils - original by TheForgotten
//
// Copyright 2004 by TheForgotten
//
// $Id$
//
// Options for the Spoils add-on.
// ============================================================================

class JBGUIPanelConfigSpoils extends JBGUIPanelConfig;


//=============================================================================
// Constants
//=============================================================================

const CONTROL_COMBO_WEAPON = 0;
const CONTROL_CHECK_AMMO   = 1;
const CONTROL_CAN_THROW    = 2;


// ============================================================================
// Variables
// ============================================================================

var           moComboBox ComboBoxWeaponType;
var automated moCheckbox MaxAmmo, CanThrow;

var localized string ComboBoxText[15];
var private bool bInitialized;  // used to prevent saving config during initialization


// ============================================================================
// InitComponent
//
// Create the windows components.
// ============================================================================

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
  local int i;
  local array<CacheManager.WeaponRecord> Recs;

  Super.InitComponent(MyController, MyOwner);

  // combo box
  ComboBoxWeaponType = moComboBox(Controls[CONTROL_COMBO_WEAPON]);

  class'CacheManager'.static.GetWeaponList(Recs);
  for (i = 0; i < Recs.Length; i++)
  ComboBoxWeaponType.AddItem(Recs[i].FriendlyName,,Recs[i].ClassName);

  ComboBoxWeaponType.AddItem("Super Shock Rifle",,"XWeapons.SuperShockRifle");
  ComboBoxWeaponType.AddItem("Zoom Super Shock Rifle",,"XWeapons.ZoomSuperShockRifle");

  ComboBoxWeaponType.MyComboBox.List.Sort();

  MaxAmmo = moCheckBox(Controls[CONTROL_CHECK_AMMO]);
  CanThrow = moCheckBox(Controls[CONTROL_CAN_THROW]);

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

  class'JBAddonSpoils'.default.SpoilsWeapon = class<Weapon>(DynamicLoadObject(ComboBoxWeaponType.GetExtra(),class'Class'));
  class'JBAddonSpoils'.default.bMaxAmmo = MaxAmmo.IsChecked();
  class'JBAddonSpoils'.default.bCanThrow = CanThrow.IsChecked();

  class'JBAddonSpoils'.static.StaticSaveConfig();
}



// ============================================================================
// SaveINISettings
//
// Called when the user changes any component value.
// ============================================================================

function SaveINISettings(GUIComponent Sender)
{
  if ( !bInitialized )
    return;

  class'JBAddonSpoils'.default.SpoilsWeapon = class<Weapon>(DynamicLoadObject(ComboBoxWeaponType.GetExtra(),class'Class'));
  class'JBAddonSpoils'.default.bMaxAmmo = MaxAmmo.IsChecked();
  class'JBAddonSpoils'.default.bCanThrow = CanThrow.IsChecked();

  class'JBAddonSpoils'.static.StaticSaveConfig();
}


//=============================================================================
// LoadINISettings
//
// Loads the values of all config GUI controls.
//=============================================================================

function LoadINISettings()
{
  bInitialized = False;

  ComboBoxWeaponType.SetIndex(ComboBoxWeaponType.FindExtra(string(class'JBAddonSpoils'.default.SpoilsWeapon)));
  MaxAmmo.Checked(class'JBAddonSpoils'.default.bMaxAmmo);
  CanThrow.Checked(class'JBAddonSpoils'.default.bCanThrow);

  bInitialized = True;
}

// ============================================================================
// ResetConfiguration
//
// When you click on Reset button.
// ============================================================================

function ResetConfiguration()
{
  class'JBAddonSpoils'.static.ResetConfiguration();
  LoadINISettings();
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  Begin Object class=moComboBox Name=WeaponTypeComboBox
    bReadOnly=True
    CaptionWidth=0.480000
    Caption="Avenger weapon"
    OnCreateComponent=WeaponTypeComboBox.InternalOnCreateComponent
    Hint="The weapon which is awarded to the avenger."
    WinTop=0.000000
    WinLeft=0.000000
    WinWidth=1.000000
    WinHeight=0.100000
    OnChange=JBGUIPanelConfigSpoils.SaveINISettings
  End Object
  Controls(0)=moComboBox'JBAddonSpoils.JBGUIPanelConfigSpoils.WeaponTypeComboBox'

  Begin Object class=moCheckBox Name=CheckBoxMaxAmmo
    Caption="Max out ammo"
    OnCreateComponent=CheckBoxMaxAmmo.InternalOnCreateComponent
    Hint="Maximize the ammunition of the Avenger's weapon."
    WinTop=0.200000
    WinLeft=0.000000
    WinWidth=1.000000
    WinHeight=0.100000
    OnChange=JBGUIPanelConfigSpoils.SaveINISettings
  End Object
  Controls(1)=moCheckBox'JBAddonSpoils.JBGUIPanelConfigSpoils.CheckBoxMaxAmmo'

  Begin Object class=moCheckBox Name=CheckBoxCanThrow
    Caption="Allow weapon drop"
    OnCreateComponent=CheckBoxCanThrow.InternalOnCreateComponent
    Hint="Allow the weapon to be thrown by the Avenger or dropped when he dies."
    WinTop=0.300000
    WinLeft=0.000000
    WinWidth=1.000000
    WinHeight=0.100000
    OnChange=JBGUIPanelConfigSpoils.SaveINISettings
  End Object
  Controls(2)=moCheckBox'JBAddonSpoils.JBGUIPanelConfigSpoils.CheckBoxCanThrow'
}
