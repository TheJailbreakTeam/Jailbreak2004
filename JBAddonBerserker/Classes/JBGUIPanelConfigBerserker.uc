// ============================================================================
// JBGUIPanelConfigBerserker
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBGUIPanelConfigBerserker.uc,v 1.2 2004/03/12 20:57:54 tarquin Exp $
//
// Options of Berserker add-on.
// ============================================================================
class JBGUIPanelConfigBerserker extends JBGUIPanelConfig;


// ============================================================================
// Variables
// ============================================================================
var GUISlider BerserkTimeMultiplier;
var GUISlider MaxBerserkTime;
var localized string SecondsText;


// ============================================================================
// *ValueText
//
// Write the text value of sliders.
// ============================================================================
function string BerserkTimeMultiplierValueText() {
    return "("$int(BerserkTimeMultiplier.Value)$"%)"; }

function string MaxBerserkTimeValueText() {
    return "("$int(MaxBerserkTime.Value)@SecondsText$")"; }


// ============================================================================
// InitComponent
//
// Create the windows components.
// ============================================================================
function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    Super.InitComponent(MyController, MyOwner);

    // Berserk Time Multiplier
    BerserkTimeMultiplier = GUISlider(Controls[1]);
    BerserkTimeMultiplier.SetValue(class'JBAddonBerserker'.default.BerserkTimeMultiplier);
    BerserkTimeMultiplier.OnDrawCaption = BerserkTimeMultiplierValueText;
    Controls[2].FriendlyLabel = GUILabel(Controls[0]);

    // Max Berserk Time
    MaxBerserkTime = GUISlider(Controls[3]);
    MaxBerserkTime.SetValue(class'JBAddonBerserker'.default.MaxBerserkTime);
    MaxBerserkTime.OnDrawCaption = MaxBerserkTimeValueText;
    Controls[3].FriendlyLabel = GUILabel(Controls[2]);
}


// ============================================================================
// ChangeOptions
//
// When you change any component value.
// ============================================================================
function ChangeOptions(GUIComponent Sender)
{
    if(Sender == BerserkTimeMultiplier)
        class'JBAddonBerserker'.default.BerserkTimeMultiplier = int(BerserkTimeMultiplier.Value);
    else if(Sender == MaxBerserkTime)
        class'JBAddonBerserker'.default.MaxBerserkTime = int(MaxBerserkTime.Value);

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

    Begin Object class=GUILabel Name=BerserkTimeMultiplierLabel
        Caption="Berserk time multiplier :"
        TextALign=TXTA_Left
        TextColor=(R=255,G=0,B=0,A=255)
        WinWidth=0.450000
        WinHeight=0.100000
        WinLeft=0.00000
        WinTop=0.100000
        StyleName="TextLabel"
    End Object
    Controls(0)=GUILabel'BerserkTimeMultiplierLabel'
    
    Begin Object class=GUISlider Name=BerserkTimeMultiplierSlider
        WinWidth=0.525000
        WinHeight=0.080000
        WinLeft=0.475000
        WinTop=0.100000
        MinValue=1.000000
        MaxValue=200.000000
        bIntSlider=True
        OnChange=ChangeOptions
        Hint="Multipli the arena countdown remaning"
    End Object
    Controls(1)=GUISlider'BerserkTimeMultiplierSlider'

    Begin Object class=GUILabel Name=MaxBerserkTimeLabel
        Caption="Maximum Berserk time :"
        TextALign=TXTA_Left
        TextColor=(R=255,G=0,B=0,A=255)
        WinWidth=0.450000
        WinHeight=0.100000
        WinLeft=0.000000
        WinTop=0.300000
        StyleName="TextLabel"
    End Object
    Controls(2)=GUILabel'MaxBerserkTimeLabel'
    
    Begin Object class=GUISlider Name=MaxBerserkTimeSlider
        WinWidth=0.525000
        WinHeight=0.080000
        WinLeft=0.475000
        WinTop=0.300000
        MinValue=10.000000
        MaxValue=60.000000
        bIntSlider=True
        OnChange=ChangeOptions
        Hint="Limit the maximum berserk time"
    End Object
    Controls(3)=GUISlider'MaxBerserkTimeSlider'
}
