//=============================================================================
// JBGUISliderLabeled
// Copyright 2003-2004 by Wormbo <wormbo@onlinehome.de>
// $Id: JBGUISliderLabeled.uc,v 1.1 2004/03/09 15:39:13 wormbo Exp $
//
// User interface component: A slider with labels for caption and value.
//=============================================================================


class JBGUISliderLabeled extends GUIMultiComponent;


//=============================================================================
// Variables
//=============================================================================

var JBGUIComponentSlider MySlider;
var GUILabel MyCaptionLabel;
var GUILabel MyValueLabel;

var(Menu) protected float MinValue;
var(Menu) protected float MaxValue;
var(Menu) protected float Value;
var(Menu) protected bool bIntegerOnly;
var(Menu) bool bVerticalLayout;
var(Menu) eTextAlign CaptionAlign;      // alignment for caption label for vertical layout
var(Menu) eTextAlign ValueAlign;        // alignment for value label for vertical layout

var(Menu) localized string Caption;     // Caption for the label
var(Menu) string LabelFont;             // Name of the Font for the label
var(Menu) color LabelColor;             // Color for the label  
var(Menu) float CaptionWidth;
var(Menu) float SliderWidth;


//=============================================================================
// InitComponent
//
// Initializes the component and registers several delegates.
//=============================================================================

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
  Super.InitComponent(MyController, MyOwner);
  
  MyCaptionLabel = GUILabel(Controls[0]);
  MySlider       = JBGUIComponentSlider(Controls[1]);
  MyValueLabel   = GUILabel(Controls[2]);
  
  MyCaptionLabel.TextFont  = LabelFont;
  MyCaptionLabel.TextColor = LabelColor;
  
  MySlider.FriendlyLabels[0] = MyCaptionLabel;
  MySlider.FriendlyLabels[1] = MyValueLabel;
  MySlider.OnValueChanged    = InternalOnValueChanged;
  MySlider.OnChange          = InternalOnChange;
  MySlider.Hint              = Hint;
  MySlider.SetSliderRange(MinValue, MaxValue);
  MySlider.SetIntSlider(bIntegerOnly);
  MySlider.SetValue(Value, True);

  if ( !bVerticalLayout ) {
    if ( Caption != "" )
      MyCaptionLabel.Caption = Caption @ OnDrawCaption(Self);
    else
      MyCaptionLabel.Caption = OnDrawCaption(Self);
    if ( SliderWidth != -1 ) {
      MySlider.WinWidth = SliderWidth;
      if ( CaptionWidth == -1 )
        MyCaptionLabel.WinWidth = 1 - SliderWidth;
    }
    else if ( CaptionWidth != -1 ) {
      MyCaptionLabel.WinWidth = CaptionWidth;
      if ( SliderWidth == -1 )
        MySlider.WinWidth = 1 - CaptionWidth;
    }
    MySlider.WinLeft = 1 - MySlider.WinWidth;
  }
  else {
    MyCaptionLabel.Caption   = Caption;
    MyCaptionLabel.WinWidth  = 1.0;
    MyCaptionLabel.WinHeight = 0.3;
    MyCaptionLabel.TextAlign = CaptionAlign;
    
    MySlider.WinLeft   = 0.0;
    MySlider.WinTop    = 0.3;
    MySlider.WinWidth  = 1.0;
    MySlider.WinHeight = 0.4;
    
    MyValueLabel.bVisible  = True;
    MyValueLabel.Caption   = OnDrawCaption(Self);
    MyValueLabel.TextFont  = LabelFont;
    MyValueLabel.TextColor = LabelColor;
    MyValueLabel.TextAlign = ValueAlign;
    
    if ( Caption == "" ) {
      MyCaptionLabel.bVisible = False;
      
      MySlider.WinTop    = 0.0;
      MySlider.WinHeight = 0.6;
      MySlider.FriendlyLabel = MyValueLabel;
      
      MyValueLabel.WinTop    = 0.6;
      MyValueLabel.WinHeight = 0.4;
    }
  }
}  


//=============================================================================
// GetValue
//
// Returns the slider's value.
//=============================================================================

function float GetValue()
{
  return Value;
}


//=============================================================================
// SetValue
//
// Sets the slider's value.
//=============================================================================

function SetValue(float NewValue)
{
  Value = NewValue;
  if ( bIntegerOnly )
    Value = Round(Value);
  else
    Value = Round(Value * 100) * 0.01;
  MySlider.SetValue(Value);
}


//=============================================================================
// IntegerOnly
//
// Change the slider's int-only status.
//=============================================================================

function IntegerOnly(bool bIntOnly)
{
  bIntegerOnly = bIntOnly;
  MySlider.SetIntSlider(bIntOnly);
  if ( bIntOnly )
    Value = Round(Value);
}


//=============================================================================
// NumericRange
//
// Change the slider's numeric range.
//=============================================================================

function NumericRange(float NewMin, float NewMax)
{
  MinValue = FMin(NewMin, NewMax);
  MaxValue = FMax(NewMin, NewMax);
  if ( bIntegerOnly ) {
    MinValue = Round(MinValue);
    MaxValue = Round(MaxValue);
  }
  Value = FClamp(Value, MinValue, MaxValue);
  MySlider.SetSliderRange(MinValue, MaxValue);
}


//=============================================================================
// InternalOnChange
//
// Called when the slider's value has changed.
//=============================================================================

function InternalOnChange(GUIComponent Sender)
{
  OnChange(self);
}


//=============================================================================
// InternalOnValueChanged
//
// Updates the value label.
//=============================================================================

function InternalOnValueChanged(JBGUIComponentSlider Sender)
{
  Value = Sender.GetValue();
  if ( bVerticalLayout )
    MyValueLabel.Caption = OnDrawCaption(Self);
  else
    MyCaptionLabel.Caption = Caption @ OnDrawCaption(Self);
}


//=============================================================================
// delegate OnDrawCaption
//
// Returns the displayed value.
//=============================================================================

delegate string OnDrawCaption(JBGUISliderLabeled Sender)
{
  if ( bVerticalLayout ) {
    if ( bIntegerOnly )
      return "(" $ int(MySlider.GetValue()) $ ")";
    else
      return "(" $ MySlider.GetValue() $ ")";
  }
  else {
    if ( bIntegerOnly )
      return string(int(MySlider.GetValue()));
    else
      return string(MySlider.GetValue());
  }
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  Begin Object Class=GUILabel Name=CaptionLabel
    bScaleToParent=True
    bBoundToParent=True
    WinTop=0
    WinLeft=0
    WinHeight=1
    WinWidth=0.5
    StyleName="TextLabel"
  End Object
  Controls(0)=GUILabel'CaptionLabel'
  
  Begin Object Class=JBGUIComponentSlider Name=Slider
    bScaleToParent=True
    bBoundToParent=True
    WinTop=0
    WinLeft=0.5
    WinHeight=1
    WinWidth=0.5
  End Object
  Controls(1)=JBGUIComponentSlider'Slider'
  
  Begin Object Class=GUILabel Name=ValueLabel
    bScaleToParent=True
    bBoundToParent=True
    WinTop=0.7
    WinLeft=0.0
    WinHeight=0.3
    WinWidth=1.0
    StyleName="TextLabel"
    bVisible=False
  End Object
  Controls(2)=GUILabel'ValueLabel'
  
  WinWidth=0.5
  WinHeight=0.1
  CaptionWidth=0.5
  SliderWidth=-1
  LabelFont="UT2MenuFont"
  LabelColor=(R=255,G=255,B=255,A=255)
  bVerticalLayout=True
  CaptionAlign=TXTA_Center
  ValueAlign=TXTA_Center
}