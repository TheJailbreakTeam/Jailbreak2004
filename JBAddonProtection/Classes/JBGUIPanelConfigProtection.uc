// ============================================================================
// JBGUIPanelConfigProtection
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBGUIPanelConfigProtection.uc,v 1.3 2004/03/12 20:43:02 tarquin Exp $
//
// Option of protection mutator.
// ============================================================================
class JBGUIPanelConfigProtection extends JBGUIPanelConfig;


// ============================================================================
// Variables
// ============================================================================
var GUISlider ProtectionTime;
var moComboBox ProtectionType;
var moCheckBox ProtectArenaWinner;
var localized string ProtectionTypeText[2];
var localized string SecondText, SecondsText;


// ============================================================================
// ProtectionTimeValueText
//
// Write the text value of protection time option.
// ============================================================================
function string ProtectionTimeValueText()
{
    if(ProtectionTime.value >= 2) return "("$int(ProtectionTime.Value)@SecondsText$")";
    return "("$int(ProtectionTime.Value)@SecondText$")";
}


// ============================================================================
// InitComponent
//
// Create the windows components.
// ============================================================================
function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    local int index;

    Super.InitComponent(MyController, MyOwner);

    // Protection time
    ProtectionTime = GUISlider(Controls[1]);
    ProtectionTime.SetValue(int(class'JBAddonProtection'.default.ProtectionTime));
    ProtectionTime.OnDrawCaption = ProtectionTimeValueText;
    Controls[1].FriendlyLabel = GUILabel(Controls[0]);

    // Protection type
    ProtectionType = moComboBox(Controls[2]);
    for(index=0; index<2; index++) Protectiontype.AddItem(ProtectionTypeText[index]);
    Protectiontype.ReadOnly(True);
    Protectiontype.SetIndex(class'JBAddonProtection'.default.ProtectionType);

    // Protect the arena winner
    ProtectArenaWinner = moCheckBox(Controls[3]);
    ProtectArenaWinner.Checked(class'JBAddonProtection'.default.bProtectArenaWinner);
}


// ============================================================================
// ChangeOptions
//
// When you change any component value.
// ============================================================================
function ChangeOptions(GUIComponent Sender)
{
    if(Sender == ProtectionTime)
        class'JBAddonProtection'.default.ProtectionTime = int(ProtectionTime.Value);
    else if(Sender == Protectiontype)
        class'JBAddonProtection'.default.ProtectionType = ProtectionType.GetIndex();
    else if(Sender == ProtectArenaWinner)
        class'JBAddonProtection'.default.bProtectArenaWinner = ProtectArenaWinner.IsChecked();

    class'JBAddonProtection'.static.StaticSaveConfig();
}


// ============================================================================
// ClickReset
//
// When you click on Reset button.
// ============================================================================
function ResetConfiguration()
{
    ProtectionTime.SetValue(3);
    ProtectionType.SetIndex(0);
    ProtectArenaWinner.Checked(TRUE);

    class'JBAddonProtection'.default.ProtectionTime = 3;
    class'JBAddonProtection'.default.ProtectionType = 0;
    class'JBAddonProtection'.default.bProtectArenaWinner = TRUE;
    class'JBAddonProtection'.static.StaticSaveConfig();

}


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
    ProtectionTypeText(0)="You can't inflict damage"
    ProtectionTypeText(1)="Drop when you inflict damage"
    SecondText="second"
    SecondsText="seconds"
    Begin Object class=GUILabel Name=ProtectionTimeLabel
        Caption="Protection time :"
        TextALign=TXTA_Left
        TextColor=(R=255,G=255,B=255,A=255)
        WinWidth=0.300000
        WinHeight=0.100000
        WinLeft=0.000000
        WinTop=0.100000
        StyleName="TextLabel"
    End Object
    Controls(0)=GUILabel'ProtectionTimeLabel'
    
    Begin Object class=GUISlider Name=ProtectionTimeSlider
        WinWidth=0.650000
        WinHeight=0.100000
        WinLeft=0.350000
        WinTop=0.100000
        MinValue=1.000000
        MaxValue=10.000000
        OnChange=ChangeOptions
        Hint="This delay begin when you are released"
    End Object
    Controls(1)=GUISlider'ProtectionTimeSlider'

    Begin Object class=moComboBox Name=ProtectionTypeComboBox
        WinWidth=1.000000
        WinHeight=0.100000
        WinLeft=0.000000
        WinTop=0.300000
        CaptionWidth=0.350000
        OnChange=ChangeOptions
        Caption="Protection type :"
        Hint="Choose the type of protection"
    End Object
    Controls(2)=moComboBox'ProtectionTypeComboBox'

    Begin Object class=moCheckBox Name=ProtectArenaWinnerCheckBox
        WinWidth=1.000000
        WinHeight=0.100000
        WinLeft=0.000000
        WinTop=0.500000
        CaptionWidth=0.900000
        OnChange=ChangeOptions
        Caption="Protect the arena winner :"
        Hint="When enabled, the arena winner are protected"
        bSquare=true
        ComponentJustification=TXTA_Left
    End Object
    Controls(3)=moCheckBox'ProtectArenaWinnerCheckBox'
}
