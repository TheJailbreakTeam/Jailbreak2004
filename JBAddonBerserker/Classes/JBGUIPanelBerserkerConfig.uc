// ============================================================================
// JBGUIPanelBerserkerConfig
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBGUIPanelBerserkerConfig.uc,v 1.1 2003/06/27 11:14:32 crokx Exp $
//
// Options of Berserker add-on.
// ============================================================================
class JBGUIPanelBerserkerConfig extends GUIPanel;


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
    BerserkTimeMultiplier = GUISlider(Controls[2]);
    BerserkTimeMultiplier.SetValue(class'JBAddonBerserker'.default.BerserkTimeMultiplier);
    BerserkTimeMultiplier.OnDrawCaption = BerserkTimeMultiplierValueText;
    Controls[2].FriendlyLabel = GUILabel(Controls[1]);

    // Max Berserk Time
    MaxBerserkTime = GUISlider(Controls[4]);
    MaxBerserkTime.SetValue(class'JBAddonBerserker'.default.MaxBerserkTime);
    MaxBerserkTime.OnDrawCaption = MaxBerserkTimeValueText;
    Controls[4].FriendlyLabel = GUILabel(Controls[3]);
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
function bool ClickReset(GUIComponent Sender)
{
    BerserkTimeMultiplier.SetValue(50);
    MaxBerserkTime.SetValue(30);

    class'JBAddonBerserker'.default.BerserkTimeMultiplier = 50;
    class'JBAddonBerserker'.default.MaxBerserkTime = 30;
    class'JBAddonBerserker'.static.StaticSaveConfig();

    return TRUE;
}


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
    SecondsText="seconds"

////////////////////////////////////////////////////////////////

    Begin Object Class=GUIButton Name=ResetButton
        Caption="RESET"
        WinWidth=0.200000
        WinHeight=0.100000
        WinLeft=0.775000
        WinTop=0.900000
        Hint="Reset options"
        OnClick=ClickReset
    End Object
    Controls(0)=GUIButton'ResetButton'

////////////////////////////////////////////////////////////////

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
    Controls(1)=GUILabel'BerserkTimeMultiplierLabel'
    
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
    Controls(2)=GUISlider'BerserkTimeMultiplierSlider'

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
    Controls(3)=GUILabel'MaxBerserkTimeLabel'
    
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
    Controls(4)=GUISlider'MaxBerserkTimeSlider'
}
