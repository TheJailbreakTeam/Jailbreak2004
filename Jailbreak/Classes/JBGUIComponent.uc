//=============================================================================
// JBGUIComponent
// Copyright 2003-2004 by Wormbo <wormbo@onlinehome.de>
// $Id: JBGUIComponent.uc,v 1.1 2004/03/09 15:39:10 wormbo Exp $
//
// The base class for GUI components which need customized drawing methods.
// This control can be associated with more than one GUILabel.
//=============================================================================


class JBGUIComponent extends GUIPanel
    abstract;


//=============================================================================
// Variables
//=============================================================================

var array<GUILabel> FriendlyLabels;
var bool bIsMultiComponent;


//=============================================================================
// InitComponent
//
// Initializes the component and assigns Draw() to the OnDraw delegate.
//=============================================================================

function InitComponent(GUIController GUIController, GUIComponent GUIComponentOwner)
{
  Super.InitComponent(GUIController, GUIComponentOwner);
  
  // drawing
  OnPreDraw = PreDraw;
  OnDraw    = Draw;
}


//=============================================================================
// PreDraw
//
// Handle FriendlyLabels.
//=============================================================================

function bool PreDraw(Canvas C)
{
  local int i;
  
  if ( FriendlyLabel != None ) {
    FriendlyLabels[FriendlyLabels.Length] = FriendlyLabel;
    FriendlyLabel = None;
  }
  
  for(i = 0; i < FriendlyLabels.Length; i++) {
    if ( FriendlyLabels[i] == None )
      FriendlyLabels.Remove(i--, 1);
    else if ( FriendlyLabels[i].MenuState < MenuState )
      FriendlyLabels[i].MenuState = MenuState;
  }
  
  return False;
}


//=============================================================================
// Draw
//
// Should be subclasses to draw the component.
//=============================================================================

function bool Draw(Canvas C);


//=============================================================================
// MenuStateChange
//
// Resets the friendly labels' MenuStates.
//=============================================================================

event MenuStateChange(eMenuState NewState)
{
  local int i;
  
  if ( bIsMultiComponent )
    Super.MenuStateChange(NewState);
  else
    Super(GUIComponent).MenuStateChange(NewState);
  
  for(i = 0; i < FriendlyLabels.Length; i++) {
    if ( FriendlyLabels[i] == None )
      FriendlyLabels.Remove(i--, 1);
    else
      FriendlyLabels[i].MenuState = MenuState;
  }
}


//=============================================================================
// SetFocus
// LoseFocus
// FocusFirst
// FocusLast
//
// Use GUIComponent's implementations unless this is a multi-component.
//=============================================================================

event SetFocus(GUIComponent Who)
{
  if ( bIsMultiComponent )
    Super.SetFocus(Who);
  else
    Super(GUIComponent).SetFocus(Who);
}

event LoseFocus(GUIComponent Sender)
{
  if ( bIsMultiComponent )
    Super.LoseFocus(Sender);
  else
    Super(GUIComponent).LoseFocus(Sender);
}

event bool FocusFirst(GUIComponent Sender, bool bIgnoreMultiTabStops)
{
  if ( bIsMultiComponent )
    return Super.FocusFirst(Sender, bIgnoreMultiTabStops);
  
  return Super(GUIComponent).FocusFirst(Sender, bIgnoreMultiTabStops);
}

event bool FocusLast(GUIComponent Sender, bool bIgnoreMultiTabStops)
{
  if ( bIsMultiComponent )
    return Super.FocusLast(Sender, bIgnoreMultiTabStops);
  
  return Super(GUIComponent).FocusLast(Sender, bIgnoreMultiTabStops);
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  bTabStop=True
  bIsMultiComponent=False
}