// ============================================================================
// JBGUIPanelConfigAvenger (formerly JBGUIPanelConfigBerserker)
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBGUIPanelConfigAvenger.uc,v 1.2 2004/05/20 14:47:57 wormbo Exp $
//
// Options for the Avenger add-on.
// ============================================================================
class JBGUIPanelConfigAvenger extends JBGUIPanelConfig;


//=============================================================================
// Constants
//=============================================================================

const CONTROL_COMBO_TIME_MULT   = 0;
const CONTROL_COMBO_TIME_MAX    = 1;
const CONTROL_COMBO_POWERUP     = 2;


// ============================================================================
// Variables
// ============================================================================

var JBGUIComponentTrackbar SliderTimeMultiplier;
var JBGUIComponentTrackbar SliderTimeMax;
var moComboBox      ComboBoxPowerType;

var localized string SecondsText;
var localized string ComboBoxText[4];
var private bool bInitialized;  // used to prevent saving config during initialization


// ============================================================================
// InitComponent
//
// Create the windows components.
// ============================================================================

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
  //local Object TestClass;
  local int i;
  
  Super.InitComponent(MyController, MyOwner);

  // Berserk Time Multiplier
  SliderTimeMultiplier = JBGUIComponentTrackbar(Controls[CONTROL_COMBO_TIME_MULT]);

  // Max Berserk Time
  SliderTimeMax = JBGUIComponentTrackbar(Controls[CONTROL_COMBO_TIME_MAX]);

  // combo box
  ComboBoxPowerType = moComboBox(Controls[CONTROL_COMBO_POWERUP]);
  for( i=0; i<4; i++) 
    ComboBoxPowerType.AddItem(ComboBoxText[i]);

  LoadINISettings();

  // was trying to get all currently loaded combo classes
  // class list: xPlayer.defaults.ComboNameList
  /*
  foreach AllObjects(class'Object', TestClass) {
    if( Class(TestClass) != None ) {
    
      if( ClassIsChildOf( Class(TestClass), class'Combo')) {
        log("JB AVENGER: got"@string(TestClass.name));
      }
     // execute something here
     // WON'T WORK: these classes are not loaded!
   }
  }
  */
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

  class'JBAddonAvenger'.default.PowerTimeMultiplier = int(SliderTimeMultiplier.GetValue());
  class'JBAddonAvenger'.default.PowerTimeMaximum = int(SliderTimeMax.GetValue());
  class'JBAddonAvenger'.default.PowerComboIndex = ComboBoxPowerType.GetIndex();

  class'JBAddonAvenger'.static.StaticSaveConfig();
}


//=============================================================================
// LoadINISettings
//
// Loads the values of all config GUI controls.
//=============================================================================

function LoadINISettings()
{
  bInitialized = False;
  SliderTimeMultiplier.SetValue(class'JBAddonAvenger'.default.PowerTimeMultiplier);
  SliderTimeMax.SetValue(class'JBAddonAvenger'.default.PowerTimeMaximum);
  ComboBoxPowerType.SetIndex(class'JBAddonAvenger'.default.PowerComboIndex);
  bInitialized = True;

}

// ============================================================================
// ResetConfiguration
//
// When you click on Reset button.
// ============================================================================

function ResetConfiguration()
{
  class'JBAddonAvenger'.static.ResetConfiguration();
  LoadINISettings();
}


// ============================================================================
// Default properties
// ============================================================================
/*
  from xPLayer:
    ComboNameList(0)="XGame.ComboSpeed"
    ComboNameList(1)="XGame.ComboBerserk"
    ComboNameList(2)="XGame.ComboDefensive"
    ComboNameList(3)="XGame.ComboInvis"
*/
defaultproperties
{
  SecondsText = "seconds"

  Begin Object Class=JBGUIComponentTrackbar Name=BerserkTimeMultiplierEditSlider
    WinTop    =0.0 // row 1
    WinLeft   =0.0
    WinHeight =0.1
    WinWidth  =1.0
    CaptionWidth  = -1;
    SliderWidth   = 0.34;
    EditBoxWidth  = 0.18;
    Caption="Avenger time multiplier"
    Hint="Percentage of remaining arena time."
    MinValue=1
    MaxValue=200
    bIntegerOnly=True
    OnChange=SaveINISettings
  End Object
  Controls(0)=JBGUIComponentTrackbar'BerserkTimeMultiplierEditSlider'

  Begin Object Class=JBGUIComponentTrackbar Name=BerserkTimeMaxEditSlider
    WinTop    =0.2 // row 2
    WinLeft   =0.0
    WinHeight =0.1
    WinWidth  =1.0
    CaptionWidth  = -1;
    SliderWidth   = 0.34;
    EditBoxWidth  = 0.18;
    Caption="Maximum avenger time"
    Hint="Maximum seconds of avenger time."
    MinValue=10
    MaxValue=60
    bIntegerOnly=True
    OnChange=SaveINISettings
  End Object
  Controls(1)=JBGUIComponentTrackbar'BerserkTimeMaxEditSlider'

  Begin Object class=moComboBox Name=PowerUpTypeComboBox
    WinTop    = 0.4; // row 3
    WinLeft   = 0.0;
    WinWidth  = 1.0;
    WinHeight = 0.1;

    CaptionWidth = 0.48;
    
    Caption="Avenger power"
    Hint="The power-up the arena winner gets."
    bHeightFromComponent  = False;
    
    OnChange=SaveINISettings
  End Object
  
  Controls(2)=moComboBox'PowerUpTypeComboBox'
  ComboBoxText(0)="Speed"
  ComboBoxText(1)="Berserk"
  ComboBoxText(2)="Booster"
  ComboBoxText(3)="Invisible"
}
