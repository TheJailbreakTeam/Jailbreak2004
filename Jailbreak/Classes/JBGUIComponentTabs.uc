// ============================================================================
// JBGUIComponentTabs
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// User interface component: Has a column of tabs on the left side, each
// containing an instance of a specified component class such as a checkbox.
// ============================================================================


class JBGUIComponentTabs extends JBGUIComponent;


// ============================================================================
// Imports
// ============================================================================

#exec texture import file=Textures\GUITabWatched.dds    alpha=on mips=off
#exec texture import file=Textures\GUITabFocused.dds    alpha=on mips=off

#exec texture import file=Textures\GUIPanelTop.dds      alpha=on mips=off
#exec texture import file=Textures\GUIPanelRight.dds    alpha=on mips=off
#exec texture import file=Textures\GUIPanelBottom.dds   alpha=on mips=off


// ============================================================================
// Properties
// ============================================================================

var() float TabWidth;             // tab width   (relative to component)
var() float TabHeight;            // tab height  (relative to screen)
var() float TabSpacing;           // tab spacing (relative to screen)

var() int iTabFirst;              // index of first visible tab
var() int nTabsVisibleMax;        // maximum number of tabs visible on screen

var() Class<GUIMenuOption> TabComponentClass;  // component class for tabs
var() float TabComponentWidth;    // component width  (relative to tab width)
var() float TabComponentHeight;   // component height (relative to screen)


// ============================================================================
// Variables
// ============================================================================

var private int nTabs;            // total number of tabs in this component
var private int iTabFirstPrev;    // previous number of first visible tab
var private int iTabOpen;         // index of currently open tab
var private int iTabOpenPrev;     // index of previously open tab


// ============================================================================
// delegate OnTabOpened
// delegate OnTabClosed
//
// Called when a tab is opened or closed, respectively.
// ============================================================================

delegate OnTabOpened(GUIComponent GUIComponentSender, GUIMenuOption GUIMenuOptionTab);
delegate OnTabClosed(GUIComponent GUIComponentSender, GUIMenuOption GUIMenuOptionTab);


// ============================================================================
// delegate OnTabInit
//
// Called when the component for a new tab button is initialized. Can be used
// to perform additional initialization of that component.
// ============================================================================

delegate OnTabInit(GUIComponent GUIComponentSender, GUIMenuOption GUIMenuOptionTab)
{
  GUIMenuOptionTab.bSquare = True;
  GUIMenuOptionTab.CaptionWidth = 0.9;
}


// ============================================================================
// delegate OnScroll
//
// Called when the tab component scrolls. Can be used to update any user
// interface elements used to scroll the component.
// ============================================================================

delegate OnScroll(GUIComponent GUIComponentSender);


// ============================================================================
// InitComponent
//
// Initializes the component and registers several delegates.
// ============================================================================

function InitComponent(GUIController GUIController, GUIComponent GUIComponentOwner)
{
  Super.InitComponent(GUIController, GUIComponentOwner);

  OnPreDraw = PreDraw;
  OnDraw    = Draw;
}


// ============================================================================
// FocusFirst
//
// Sets the focus on the currently active tab button control. If no tab is
// open, opens the first one.
// ============================================================================

event bool FocusFirst(GUIComponent GUIComponentSender, bool bIgnoreMultiTabStops)
{
  if (MenuState == MSAT_Disabled || !bVisible)
    return False;

  if (iTabOpen < 0)
    iTabOpen = 0;

  return GetCurrentTabComponent().FocusFirst(Self, False);
}


// ============================================================================
// FocusLast
//
// Set the focus on the last regular control in this component, or the
// currently active tab if none exists.
// ============================================================================

event bool FocusLast(GUIComponent GUIComponentSender, bool bIgnoreMultiTabStops)
{
  local int iControl;

  if (MenuState == MSAT_Disabled || !bVisible)
    return False;

  for (iControl = Controls.Length - 1; iControl >= nTabs; iControl--)
    if (Controls[iControl].FocusLast(Self, bIgnoreMultiTabStops))
      return True;

  return FocusFirst(Self, bIgnoreMultiTabStops);  // focus on tab
}


// ============================================================================
// PrevControl
//
// Sets the focus to the previous regular control in this component, or the
// currently open tab if the first regular control is active, or leaves the
// component otherwise.
// ============================================================================

event bool PrevControl(GUIComponent GUIComponentSender)
{
  local int iControl;
  local int iControlCurrent;

  iControlCurrent = FindComponentIndex(GUIComponentSender);

  if (iControlCurrent < nTabs)
    if (MenuOwner != None)
      return MenuOwner.PrevControl(Self);
    else
      return FocusLast(Self, False);

  for (iControl = iControlCurrent - 1; iControl >= nTabs; iControl--)
    if (Controls[iControl].FocusLast(Self, False))
      return True;

  return FocusFirst(Self, False);
}


// ============================================================================
// NextControl
//
// Sets the focus to the next regular control in this component, or leaves
// the component if none exists.
// ============================================================================

event bool NextControl(GUIComponent GUIComponentSender)
{
  local int iControl;
  local int iControlCurrent;

  iControlCurrent = FindComponentIndex(GUIComponentSender);

  for (iControl = Max(nTabs, iControlCurrent + 1); iControl < Controls.Length; iControl++)
    if (Controls[iControl].FocusFirst(Self, False))
      return True;

  if (MenuOwner != None)
    return MenuOwner.NextControl(Self);

  return FocusFirst(Self, True);
}


// ============================================================================
// PrevTab
//
// Opens the previous tab and optionally sets the focus to the tab button.
// ============================================================================

function PrevTab(optional bool bSetFocus)
{
  if (iTabOpen < 0)
    return;

  iTabOpen -= 1;
  if (iTabOpen < 0)
    iTabOpen = nTabs - 1;

  if (bSetFocus)
    GetCurrentTabComponent().SetFocus(None);
}


// ============================================================================
// NextTab
//
// Opens the next tab and optionally sets the focus to the tab button.
// ============================================================================

function NextTab(optional bool bSetFocus)
{
  if (iTabOpen < 0)
    return;

  iTabOpen += 1;
  if (iTabOpen >= nTabs)
    iTabOpen = 0;

  if (bSetFocus)
    GetCurrentTabComponent().SetFocus(None);
}


// ============================================================================
// PreDraw
//
// Adjusts the placement of all tab components.
// ============================================================================

function bool PreDraw(Canvas Canvas)
{
  local int iTab;
  local int iTabFocused;

  iTabFocused = FindComponentIndex(FocusedControl);
  if (iTabFocused >= 0 && iTabFocused < nTabs)
    iTabOpen = iTabFocused;

  if (nTabsVisibleMax > 0) {
    if (iTabOpen < iTabFirst)
      iTabFirst = iTabOpen;
    else if (iTabOpen >= iTabFirst + nTabsVisibleMax)
      iTabFirst = iTabOpen - nTabsVisibleMax + 1;
  
    if (iTabFirst != iTabFirstPrev)
      OnScroll(Self);
  }

  for (iTab = 0; iTab < nTabs; iTab++)
    PlaceTab(GUIMenuOption(Controls[iTab]), iTab);

  if (iTabOpen != iTabOpenPrev) {
    if (iTabOpenPrev >= 0)
      OnTabClosed(Self, GUIMenuOption(Controls[iTabOpenPrev]));
    OnTabOpened(Self, GUIMenuOption(Controls[iTabOpen]));

    if (iTabOpenPrev >= 0)
      PlayerOwner().PlayOwnedSound(Controller.EditSound, SLOT_Interface, 1.0);

    iTabOpenPrev = iTabOpen;
  }

  return False;  // execute standard code
}


// ============================================================================
// Draw
//
// Draws the tabs and the panel background.
// ============================================================================

function bool Draw(Canvas Canvas)
{
  local int iTab;

  for (iTab = 0; iTab < nTabs; iTab++)
    if (iTab == iTabOpen)
      DrawTab(Canvas, iTab, MSAT_Focused);
    else
      DrawTab(Canvas, iTab, GUIMenuOption(Controls[iTab]).MyLabel.MenuState);

  DrawPanel(Canvas, iTabOpen);

  return False;  // execute standard code
}


// ============================================================================
// CalcTabMetrics
//
// Calculates the metrics of the specified tab and stores them in the out
// parameters.
// ============================================================================

function CalcTabMetrics(int iTab, optional out vector LocationTab, optional out vector SizeTab)
{
  LocationTab.X = int(ActualLeft());
  LocationTab.Y = int(ActualTop() + (iTab - iTabFirst) * (TabHeight + TabSpacing) * ActualHeight() + 32.0);

  SizeTab.X = int(TabWidth  * ActualWidth());
  SizeTab.Y = int(TabHeight * ActualHeight());
}


// ============================================================================
// DrawTab
//
// Draws the background for the given tab in the given state. Emulates the
// behavior of DrawTileStretched using only the left half of the material.
// ============================================================================

function DrawTab(Canvas Canvas, int iTab, EMenuState MenuStateTab)
{
  local vector LocationTab;
  local vector SizeTab;
  local Material Material;

  if (!IsTabVisible(iTab))
    return;

  switch (MenuStateTab) {
    case EMenuState.MSAT_Blurry:   Material = Texture'GUITabFocused';  Canvas.SetDrawColor(255, 255, 255,  40);  break;
    case EMenuState.MSAT_Watched:  Material = Texture'GUITabWatched';  Canvas.SetDrawColor(255, 255, 255, 255);  break;
    case EMenuState.MSAT_Focused:  Material = Texture'GUITabFocused';  Canvas.SetDrawColor(255, 255, 255, 160);  break;
  }

  if (Material == None)
    return;

  CalcTabMetrics(iTab, LocationTab, SizeTab);

  Canvas.Style = EMenuRenderStyle.MSTY_Alpha;
  Canvas.SetPos(LocationTab.X, LocationTab.Y);
  Canvas.DrawTileStretched(Material, SizeTab.X, SizeTab.Y);
}


// ============================================================================
// DrawPanel
//
// Draws the background panel.
// ============================================================================

function DrawPanel(Canvas Canvas, int iTab)
{
  local vector LocationPanel;
  local vector LocationTab;
  local vector SizePanel;
  local vector SizeTab;

  CalcTabMetrics(iTab, LocationTab, SizeTab);

  LocationPanel.X = int(LocationTab.X + SizeTab.X);
  LocationPanel.Y = int(ActualTop());

  SizePanel.X = int(ActualWidth() + ActualLeft() - LocationPanel.X);
  SizePanel.Y = int(ActualHeight());

  Canvas.Style = EMenuRenderStyle.MSTY_Alpha;
  Canvas.SetDrawColor(255, 255, 255, 160);
  
  if (IsTabVisible(iTab)) {
    Canvas.SetPos(LocationPanel.X, LocationPanel.Y);
    Canvas.DrawTileStretched(Texture'GUIPanelTop', SizePanel.X, LocationTab.Y - LocationPanel.Y);
  
    Canvas.SetPos(LocationPanel.X, LocationTab.Y);
    Canvas.DrawTileStretched(Texture'GUIPanelRight', SizePanel.X, SizeTab.Y);
  
    Canvas.SetPos(LocationPanel.X, LocationTab.Y + SizeTab.Y);
    Canvas.DrawTileStretched(Texture'GUIPanelBottom', SizePanel.X, LocationPanel.Y + SizePanel.Y - Canvas.CurY);
  }
  else {
    Canvas.SetPos(LocationPanel.X, LocationPanel.Y);
    Canvas.DrawTileStretched(Texture'GUIPanelTop', SizePanel.X, 32.0);

    Canvas.SetPos(LocationPanel.X, LocationPanel.Y + 32.0);
    Canvas.DrawTileStretched(Texture'GUIPanelBottom', SizePanel.X, LocationPanel.Y + SizePanel.Y - Canvas.CurY);
  }
}


// ============================================================================
// AddTab
//
// Adds a tab to the component given its title and a hint displayed in the
// status line when the user hovers the tab title with the mouse. Returns an
// object reference unique to the tab that can be used to identify it later.
// ============================================================================

function GUIMenuOption AddTab(string TextCaption, optional string TextHint)
{
  local int iTabAdded;
  local GUIMenuOption GUIMenuOptionTab;

  GUIMenuOptionTab = new TabComponentClass;

  GUIMenuOptionTab.Caption = TextCaption;
  GUIMenuOptionTab.Hint    = TextHint;

  OnTabInit(Self, GUIMenuOptionTab);
  GUIMenuOptionTab.InitComponent(Controller, Self);

  GUIMenuOptionTab.MyLabel.bAcceptsInput   = True;
  GUIMenuOptionTab.MyLabel.bMouseOverSound = True;
  GUIMenuOptionTab.MyLabel.OnClick = GUIMenuOptionTab_LabelClick;

  GUIMenuOptionTab.OnKeyEvent = GUIMenuOptionTab.MyComponent.OnKeyEvent;
  GUIMenuOptionTab.MyComponent.OnKeyEvent = GUIMenuOptionTab_ComponentKeyEvent;

  iTabAdded = nTabs;
  nTabs += 1;
  if (iTabOpen < 0)
    iTabOpen = iTabAdded;

  Controls.Insert(iTabAdded, 1);
  Controls[iTabAdded] = GUIMenuOptionTab;

  return GUIMenuOptionTab;
}


// ============================================================================
// AddComponent
//
// Adds an arbitrary control to this component, initializes it and returns a
// reference to it.
// ============================================================================

function GUIComponent AddComponent(GUIComponent GUIComponent)
{
  Controls[Controls.Length] = GUIComponent;
  GUIComponent.InitComponent(Controller, Self);

  return GUIComponent;
}


// ============================================================================
// GUIMenuOptionTab_LabelClick
//
// Called when a user clicks the caption of one of the tab button components.
// Sets the focus to the main component (which in turn leads to this tab
// being opened).
// ============================================================================

function bool GUIMenuOptionTab_LabelClick(GUIComponent GUIComponentSender)
{
  if (GUILabel(GUIComponentSender) != None)
    GUIComponentSender.MenuOwner.SetFocus(None);

  return True;
}


// ============================================================================
// GUIMenuOptionTab_ComponentKeyEvent
//
// Called when a user presses a key while one of the tab button components is
// focused. Switches to another tab when the up or down arrow is pressed.
// ============================================================================

function bool GUIMenuOptionTab_ComponentKeyEvent(out byte Key, out byte State, float Delta)
{
  local GUIMenuOption GUIMenuOptionTab;

       if (State == 1 && Key == Controller.EInputKey.IK_Up)   { PrevTab(True);  return True; }
  else if (State == 1 && Key == Controller.EInputKey.IK_Down) { NextTab(True);  return True; }

  GUIMenuOptionTab = GetTabComponent(iTabOpen);
  return GUIMenuOptionTab.OnKeyEvent(Key, State, Delta);
}


// ============================================================================
// PlaceTab
//
// Updates the position and size of the given tab button component.
// ============================================================================

function PlaceTab(GUIMenuOption GUIMenuOptionTab, int iTab)
{
  if (IsTabVisible(iTab)) {
    GUIMenuOptionTab.bBoundToParent = True;
    GUIMenuOptionTab.bScaleToParent = True;

    GUIMenuOptionTab.WinTop    = FMax(0.0, (iTab - iTabFirst) * (TabHeight + TabSpacing));
    GUIMenuOptionTab.WinLeft   = 0.0;
    GUIMenuOptionTab.WinWidth  = TabComponentWidth * TabWidth * WinWidth;
    GUIMenuOptionTab.WinHeight = TabComponentHeight;
  
    GUIMenuOptionTab.WinTop  += (TabHeight       - TabComponentHeight)            / 2;
    GUIMenuOptionTab.WinLeft += (TabWidth * (1.0 - TabComponentWidth) * WinWidth) / 2;
  
    GUIMenuOptionTab.WinTop = int(GUIMenuOptionTab.WinTop * ActualHeight() + 32.0);
  }
  else {
    GUIMenuOptionTab.bBoundToParent = False;
    GUIMenuOptionTab.bScaleToParent = False;

    GUIMenuOptionTab.WinTop = 1.0;
  }
}


// ============================================================================
// GetTabComponent
//
// Returns the tab button component corresponding to the given tab index.
// ============================================================================

function GUIMenuOption GetTabComponent(int iTab)
{
  if (iTab < 0 || iTab >= nTabs)
    return None;

  return GUIMenuOption(Controls[iTab]);
}


// ============================================================================
// GetTabIndex
//
// Returns the tab index corresponding to the given tab button component.
// ============================================================================

function int GetTabIndex(GUIMenuOption GUIMenuOptionTab)
{
  local int iTab;

  iTab = FindComponentIndex(GUIMenuOptionTab);

  if (iTab < 0 || iTab >= nTabs)
    return -1;

  return iTab;
}


// ============================================================================
// IsTabVisible
//
// Checks and returns whether the tab with the given index is currently
// visible on the screen.
// ============================================================================

function bool IsTabVisible(int iTab)
{
  if (nTabsVisibleMax <= 0)
    return True;
  
  return (iTab >= iTabFirst &&
          iTab <  iTabFirst + nTabsVisibleMax);
}


// ============================================================================
// GetCurrentTabComponent
// GetCurrentTabIndex
//
// Return a reference to the tab button component of the currently open tab or
// its tab index, respectively.
// ============================================================================

function GUIMenuOption GetCurrentTabComponent() { return GetTabComponent(iTabOpen); }
function int           GetCurrentTabIndex()     { return                 iTabOpen;  }


// ============================================================================
// CountTabs
// CountTabsVisible
//
// Return the total number of tabs in this component and the number of tabs
// currently visible on the screen, respectively.
// ============================================================================

function int CountTabs()        { return     nTabs; }
function int CountTabsVisible() { return Max(nTabs - iTabFirst, nTabsVisibleMax); }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  bIsMultiComponent = True;

  iTabFirstPrev = -1;
  iTabOpen      = -1;
  iTabOpenPrev  = -1;

  TabWidth   = 0.330;
  TabHeight  = 0.080;
  TabSpacing = 0.020;

  TabComponentClass  = Class'moCheckBox';
  TabComponentWidth  = 0.850;
  TabComponentHeight = 0.040;
}