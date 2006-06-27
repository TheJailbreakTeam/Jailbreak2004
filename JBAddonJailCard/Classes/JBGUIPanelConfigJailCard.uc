//=============================================================================
// JBGUIPanelConfigJailCard
// Copyright 2004 by tarquin <tarquin@planetjailbreak.com>
// $Id$
//
// GUI options for the Get Out of Jail Free Card Addon
//=============================================================================


class JBGUIPanelConfigJailCard extends JBGUIPanelConfig;


//=============================================================================
// Constants
//=============================================================================
/*
Add-on class vars and defaults for reference:

var config bool bAutoUseCard;     // the GOOJF card is used automatically when jailed
  const DEFAULT_AUTOUSE_CARD      = False;

var config bool bAllowDropCard;   // can the GOOJF card be dropped?
  const DEFAULT_ALLOW_DROP        = True;

var config int  SpawnDelay;       // delay at round start before spawning card
  const DEFAULT_SPAWN_DELAY       = 0;

var config int  NumCards;         // number of cards to spawn
  const DEFAULT_NUM_CARDS         = 1;
*/
const CONTROL_AUTOUSE_CARD      = 0;
const CONTROL_ALLOW_DROP        = 1;
const CONTROL_SPAWN_DELAY       = 2;
const CONTROL_NUM_CARDS         = 3;


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
  moCheckbox(Controls[CONTROL_AUTOUSE_CARD]).Checked(class'JBAddonJailCard'.default.bAutoUseCard);
  moCheckbox(Controls[CONTROL_ALLOW_DROP]).Checked(class'JBAddonJailCard'.default.bAllowDropCard);
  JBGUIComponentTrackbar(Controls[CONTROL_SPAWN_DELAY]).SetValue(class'JBAddonJailCard'.default.SpawnDelay);
  JBGUIComponentTrackbar(Controls[CONTROL_NUM_CARDS]).SetValue(class'JBAddonJailCard'.default.NumCards);
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

  class'JBAddonJailCard'.default.bAutoUseCard   = moCheckbox(Controls[CONTROL_AUTOUSE_CARD]).IsChecked();
  class'JBAddonJailCard'.default.bAllowDropCard = moCheckbox(Controls[CONTROL_ALLOW_DROP]).IsChecked();
  class'JBAddonJailCard'.default.SpawnDelay     = JBGUIComponentTrackbar(Controls[CONTROL_SPAWN_DELAY]).GetValue();
  class'JBAddonJailCard'.default.NumCards       = JBGUIComponentTrackbar(Controls[CONTROL_NUM_CARDS]).GetValue();

  class'JBAddonJailCard'.static.StaticSaveConfig();
}


//=============================================================================
// ResetConfiguration
//
// Resets the configurable properties to their default values.
//=============================================================================

function ResetConfiguration()
{
  class'JBAddonJailCard'.static.ResetConfiguration();
  LoadINISettings();
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  Begin Object Class=moCheckBox Name=CheckBoxAutoUseCard
    WinTop    = 0.01; // Check box text is a tiny bit too high at 0.
    WinLeft   = 0.0;
    WinHeight = 0.07; // for button to be right size
    WinWidth  = 0.667; // sets how far button is from left edge
    bHeightFromComponent = False;
    CaptionWidth  = 0.9;
    bSquare = True; // makes button round
    Caption="Use card automatically"
    Hint="You are freed as soon as you are jailed!"
  End Object
  Controls(0)=moCheckBox'CheckBoxAutoUseCard'

  Begin Object Class=moCheckBox Name=CheckBoxAllowDropCard
    WinTop    = 0.21;
    WinLeft   = 0.0;
    WinHeight = 0.07; // for button to be right size
    WinWidth  = 0.667; // sets how far button is from left edge
    bHeightFromComponent = False;
    CaptionWidth  = 0.9;
    bSquare = True; // makes button round
    Caption="Card can be dropped"
    Hint="You may drop the card for another player to pick up."
  End Object
  Controls(1)=moCheckBox'CheckBoxAllowDropCard'

  Begin Object Class=JBGUIComponentTrackbar Name=SliderSpawnDelay
    WinTop    =0.4 // row 3
    WinLeft   =0.0
    WinHeight =0.1
    WinWidth  =1.0
    CaptionWidth  = -1;
    SliderWidth   = 0.34;
    EditBoxWidth  = 0.18;
    Caption="Spawn delay"
    Hint="Seconds after round start before card spawns."
    MinValue=0
    MaxValue=180
    bIntegerOnly=True
  End Object
  Controls(2)=JBGUIComponentTrackbar'SliderSpawnDelay'

  Begin Object Class=JBGUIComponentTrackbar Name=SliderNumCards
    WinTop    =0.6 // row 4
    WinLeft   =0.0
    WinHeight =0.1
    WinWidth  =1.0
    CaptionWidth  = -1;
    SliderWidth   = 0.34;
    EditBoxWidth  = 0.18;
    Caption="Number of cards"
    Hint="How many cards are spawned in the game."
    MinValue=1
    MaxValue=4
    bIntegerOnly=True
  End Object
  Controls(3)=JBGUIComponentTrackbar'SliderNumCards'
}










