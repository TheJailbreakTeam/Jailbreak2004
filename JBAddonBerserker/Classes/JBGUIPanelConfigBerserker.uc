// ============================================================================
// JBGUIPanelConfigBerserker
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBGUIPanelConfigBerserker.uc,v 1.4 2004/03/26 20:43:46 tarquin Exp $
//
// Options of Berserker add-on.
// ============================================================================
class JBGUIPanelConfigBerserker extends JBGUIPanelConfig;


//=============================================================================
// Constants
//=============================================================================

const CONTROL_BESERK_TIME_MULT   = 0;
const CONTROL_BESERK_TIME_MAX    = 1;


// ============================================================================
// Variables
// ============================================================================
var JBGUIEditSlider BerserkTimeMultiplier;
var JBGUIEditSlider MaxBerserkTime;
var localized string SecondsText;


// ============================================================================
// InitComponent
//
// Create the windows components.
// ============================================================================
function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    Super.InitComponent(MyController, MyOwner);

    // Berserk Time Multiplier
    BerserkTimeMultiplier = JBGUIEditSlider(Controls[CONTROL_BESERK_TIME_MULT]);
    BerserkTimeMultiplier.SetValue(class'JBAddonBerserker'.default.BerserkTimeMultiplier);

    // Max Berserk Time
    MaxBerserkTime = JBGUIEditSlider(Controls[CONTROL_BESERK_TIME_MAX]);
    MaxBerserkTime.SetValue(class'JBAddonBerserker'.default.MaxBerserkTime);
}


// ============================================================================
// ChangeOptions
//
// When you change any component value.
// ============================================================================
function ChangeOptions(GUIComponent Sender)
{
    if(Sender == BerserkTimeMultiplier)
        class'JBAddonBerserker'.default.BerserkTimeMultiplier = int(BerserkTimeMultiplier.GetValue());
    else if(Sender == MaxBerserkTime)
        class'JBAddonBerserker'.default.MaxBerserkTime = int(MaxBerserkTime.GetValue());

    class'JBAddonBerserker'.static.StaticSaveConfig();
}


// ============================================================================
// ClickReset
//
// When you click on Reset button.
// ============================================================================
function ResetConfiguration()
{
    BerserkTimeMultiplier.SetValue(50);
    MaxBerserkTime.SetValue(30);

    class'JBAddonBerserker'.default.BerserkTimeMultiplier = 50;
    class'JBAddonBerserker'.default.MaxBerserkTime = 30;
    class'JBAddonBerserker'.static.StaticSaveConfig();
}


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
  SecondsText = "seconds"

  Begin Object Class=JBGUIEditSlider Name=BerserkTimeMultiplierEditSlider
    WinTop    =0.0 // row 1
    WinLeft   =0.0
    WinHeight =0.1
    WinWidth  =1.0
    CaptionWidth  = -1;
    SliderWidth   = 0.34;
    EditBoxWidth  = 0.18;
    Caption="Berserk time multiplier"
    Hint="Percentage of remaining arena time."
    MinValue=1
    MaxValue=200
    bIntegerOnly=True
    OnChange=ChangeOptions
  End Object
  Controls(0)=JBGUIEditSlider'BerserkTimeMultiplierEditSlider'

  Begin Object Class=JBGUIEditSlider Name=BerserkTimeMaxEditSlider
    WinTop    =0.2 // row 2
    WinLeft   =0.0
    WinHeight =0.1
    WinWidth  =1.0
    CaptionWidth  = -1;
    SliderWidth   = 0.34;
    EditBoxWidth  = 0.18;
    Caption="Maximum Berserk time"
    Hint="Maximum seconds of berserk time."
    MinValue=10
    MaxValue=60
    bIntegerOnly=True
    OnChange=ChangeOptions
  End Object
  Controls(1)=JBGUIEditSlider'BerserkTimeMaxEditSlider'
}
