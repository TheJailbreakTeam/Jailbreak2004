//=============================================================================
// JBGUIComponentOptions
// Copyright 2004 by tarquin <tarquin@beyondunreal.com>
// $Id$
//
// A group of radio button options
//=============================================================================


class JBGUIComponentOptions extends GUIMultiComponent;
  
  
// ============================================================================
// Variables
// ============================================================================

var(Menu) localized array<string> OptionText;   // text for each option
var(Menu) localized array<string> OptionHint;   // hint for each option
var(Menu) localized string        GroupCaption; // requests label for the entire group

var(Menu) string        GroupCaptionFont;
var(Menu) Color         GroupCaptionColor;
var(Menu) string        GroupCaptionStyleName;
var(Menu) bool          bHasBorder;   // doesn't quite work yet... :)
var(Menu) int           DefaultOption;
var(Menu) float         ButtonHeightInRow; // relative to one row
var(Menu) float         LabelWidth;
var(Menu) string        LabelFont;
var(Menu) Color         LabelColor;
var(Menu) string        LabelStyleName;
var(Menu) float         ButtonWidth;
var(Menu) float         ItemIndent; // option indent from label
var(Menu) float         LeftIndent; // ident of whole component (TBI)
var(Menu) float         ItemHeight; // height of each item, 
  // relative to the parent. Overrides WinHeight

var int   Index;

var GUILabel                GroupLabel;
var array<GUILabel>         OptionLabel;
var array<JBGUIRadioButton> OptionButton;


// ============================================================================
// InitComponent
// ============================================================================

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
  local int i;
  local int iGroupLabel;
  local int numRows; // number of rows
  local float RowHeight; // relative to this component's height
  
  Super.Initcomponent(MyController, MyOwner);
  
  // set up metrics
  iGroupLabel = int( GroupCaption != "");
  numRows     = OptionText.Length  + iGroupLabel;
  RowHeight   = 1.0 / numRows;
  WinHeight   = numRows * ItemHeight; // override WinHeight
  
  Controls[0].bVisible = bHasBorder;
  
  // if GroupCaption requested, create the group label 
  if( GroupCaption != "" ) {
    GroupLabel = new class'GUILabel';
    GroupLabel.Caption = GroupCaption;
    
    GroupLabel.bBoundToParent = True;
    GroupLabel.bScaleToParent = True;
    GroupLabel.WinTop      = 0.0;
    GroupLabel.WinLeft     = 0.0;
    GroupLabel.WinWidth    = 1.0;
    GroupLabel.WinHeight   = RowHeight;
    
    // style
    if ( GroupCaptionStyleName == "" ) {
      GroupLabel.TextColor = GroupCaptionColor;
      GroupLabel.TextFont  = GroupCaptionFont;
    } else {
      GroupLabel.Style = Controller.GetStyle(GroupCaptionStyleName, GroupLabel.FontScale);
    }
    
    Controls[1] = GroupLabel;
    GroupLabel.InitComponent(MyController, Self);
    
    // the presence of this affects:
    //  * Controls array
    //  * height of other components
    //  * height of this component
  }
  
  // create components
  OptionLabel.Length = OptionText.Length;
  for ( i=0; i < OptionLabel.Length; i++ ) {
    // create labels
    OptionLabel[i] = new class'GUILabel';
    if (OptionLabel[i] == None)
    {
      log("Could not create the GUILabel");
      return;
    }
    Controls[2 * i + 1 + iGroupLabel] = OptionLabel[i];
    
    OptionLabel[i].Caption    = OptionText[i];
    OptionLabel[i].bBoundToParent = True;
    OptionLabel[i].bScaleToParent = True;
    
    OptionLabel[i].WinHeight  = RowHeight;
    OptionLabel[i].WinTop     = RowHeight * (i + iGroupLabel);
    
    // width and indent
    OptionLabel[i].WinWidth   = LabelWidth - ItemIndent;
    OptionLabel[i].WinLeft    = ItemIndent;
    
    // style
    if ( LabelStyleName == "" ) {
      OptionLabel[i].TextColor = LabelColor;
      OptionLabel[i].TextFont  = LabelFont;
    } else {
      OptionLabel[i].Style = Controller.GetStyle(LabelStyleName, OptionLabel[i].FontScale);
    }

    // create buttons
    OptionButton[i] = new class'JBGUIRadioButton';
    Controls[2 * i + 2 + iGroupLabel] = OptionButton[i];
    
    /*
    OptionButton[i].WinTop     = WinTop + i * WinHeight / OptionText.Length;
    OptionButton[i].WinLeft    = LabelWidth;
    //OptionButton[i].WinWidth   = 0.1;
    //OptionButton[i].WinHeight  = 1.0 / OptionText.Length;
    */
    
    OptionButton[i].Hint      = OptionHint[i];
    OptionButton[i].bBoundToParent = True;
    OptionButton[i].bScaleToParent = True;
    OptionButton[i].WinTop    = OptionLabel[i].WinTop + ( 1 - ButtonHeightInRow ) / numRows / 2;
    OptionButton[i].WinLeft   = ItemIndent + OptionLabel[i].WinWidth;
    
    OptionButton[i].WinWidth  = ButtonWidth;
    OptionButton[i].WinHeight = ButtonHeightInRow / numRows;
    
    //OptionButton[i].SetFriendlyLabel(OptionLabel[i]);
    
    OptionLabel[i].InitComponent(MyController, Self); // try here for friendly?
    OptionButton[i].InitComponent(MyController, Self);
    OptionButton[i].IndexInParent = i;

    OptionButton[i].FriendlyLabel = OptionLabel[i];
  }
  
  // set default
  Index = DefaultOption;
  OptionButton[DefaultOption].SetChecked( True );
}


//=============================================================================
// SetIndex
// Called when one of the buttons is set. Unchecks the currently checked button
// Can also be called from elsewhere
//=============================================================================

function SetIndex(int newIndex)
{
  if( newIndex == Index )
    return;

  OptionButton[Index].SetChecked( False );
  Index = newIndex;
  OptionButton[Index].SetChecked( True );
  
  OnChange(self);
}

//=============================================================================
// GetIndex
//=============================================================================

function int GetIndex()
{
  return Index;
}


//=============================================================================
// Defaults
//=============================================================================

defaultproperties
{
  DefaultOption = 0;

  ButtonHeightInRow = 0.7;
  ButtonWidth       = 0.2;
  LabelWidth        = 0.6;
  ItemIndent        = 0.0;

  GroupCaptionStyleName = "TextLabel";
  LabelStyleName        = "TextLabel";

  Begin Object Class=GUIButton name=GroupBackground
    WinWidth=1.0
    WinHeight=1.0
    WinTop=0.0
    WinLeft=0.0
    bAcceptsInput=False
    bNeverFocus=True
    bBoundToParent=True
    bScaleToParent=True
  End Object
  Controls(0)=GUIButton'GroupBackground'
}
