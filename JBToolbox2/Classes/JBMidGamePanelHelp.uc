// ============================================================================
// JBMidGamePanelHelp
// Copyright 2007 by Jrubzjeknf <rrvanolst@hotmail.com>
// $Id: JBMidGamePanelHelp.uc,v 1.2 2007-08-09 11:45:47 jrubzjeknf Exp $
//
// Jailbreak's help tab for the mini tutorial. Created from a combination of
// UT2K4SPTab_Tutorials and UT2K4OnslaughtPowerLinkDesigner.
// ============================================================================


class JBMidGamePanelHelp extends MidGamePanel;


// ============================================================================
// Imports
// ============================================================================

#exec texture import file=Textures\MiniTutorial.dds mips=on alpha=on lodset=LODSET_Interface


// ============================================================================
// Structs
// ============================================================================

struct TTutorial
{
  var string Texture;
  var int X1, Y1, X2, Y2;
  var localized string Title, Description;
};

struct TTutorialGUIs
{
  var GUISectionBackground Border;
  var GUIImage Image;
};


// ============================================================================
// Variables
// ============================================================================

var array<TTutorial> Tutorials;
var array<TTutorialGUIs> TutorialGUIs;

var localized string StartTutorial;
var bool bResolutionChanged;


// ============================================================================
// InitComponent
//
// Create the GUI.
// ============================================================================

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
  local int i;
  local GUISectionBackground sbg;
  local GUIImage img;
  local GUIToolTip tip;

  Super.InitComponent(MyController, MyOwner);

  if (TutorialGUIs.Length > 0)
    Warn("TutorialGUIs should be empty at this point");

  for (i = 0; i < Tutorials.Length; i++) {
    TutorialGUIs.Length = i + 1;

    // Create the image's background with border.
    sbg = new class'AltSectionBackground';
    sbg.RenderWeight = 0.1;
    sbg.Caption = Tutorials[i].Title;
    AppendComponent(sbg, True);
    TutorialGUIs[i].Border = sbg;

    // Create the image.
    img = new class'GUIImage';
    img.ImageStyle = ISTY_Scaled;
    img.X1 = Tutorials[i].X1;
    img.Y1 = Tutorials[i].Y1;
    img.X2 = Tutorials[i].X2;
    img.Y2 = Tutorials[i].Y2;
    img.Image         = Material(DynamicLoadObject(Tutorials[i].Texture, class'Material'));
    img.OnPreDraw     = DrawImages;
    img.RenderWeight  = 0.17;
    img.bTabStop      = True;
    img.bAcceptsInput = True;
    img.Hint          = Tutorials[i].Description;
    tip = new class'GUIToolTip';
    img.ToolTip = tip;
    AppendComponent(img, True);
    TutorialGUIs[i].Image = img;
  }

  SetGUIPosition();
}


// ============================================================================
// SetGUIPosition
//
// Set the position of the GUI objects created in InitComponent().
// ============================================================================

function SetGUIPosition()
{
  local int i, cols, rows;
  local float colWidth, rowHeight, cellWidth, cellHeight, spacingHeight, spacingWidth, X, Y;
  local float BorderHeight, BorderWidth, BorderOffsetTop, BorderOffsetLeft;
  local GUISectionBackground sbg;
  local GUIImage img;

  // Hard-coded. Appearantly, these are the dimensions of the border. (Taken from UT2K4SPTab_Tutorials)
  BorderHeight     = 0.09605;
  BorderWidth      = 0.02625;
  BorderOffsetTop  = 0.046667;
  BorderOffsetLeft = 0.01375;

  rows = Tutorials.Length;
  cols = 1;

  colWidth = PageOwner.WinWidth/cols;
  rowHeight = (1 - 2 * (PageOwner.WinTop + class'GUITabControl'.default.TabHeight)) / rows;
  cellWidth  = colWidth  * 0.9;
  cellHeight = rowHeight * 0.9;

  // Calculate the size of the cells, with an aspect ratio of 6:1.
  //Takes the border and screen resolution in account.
  X = FMin(cellWidth - BorderWidth, 6 * (cellHeight - BorderHeight) * GetScreenRatio(Controller));
  cellWidth  = X;
  cellHeight = X/(GetScreenRatio(Controller) * 6);

  // The space that should not be drawed on, since it's not inside the box.
  spacingWidth  = (colWidth-cellWidth)/2.0 + PageOwner.WinLeft;
  spacingHeight = (rowHeight-cellHeight)/2.0 + PageOwner.WinTop + class'GUITabControl'.default.TabHeight;

  // Calculate and set the size and offset of both the borders and images.
  for (i = 0; i < TutorialGUIs.Length; i++) {
    // Position on the left top corner.
    X = (i%cols)*colWidth + spacingWidth;
    Y = (i/cols)*rowHeight + spacingHeight;

    // Get the border and the image of the current mini tutorial.
    sbg = TutorialGUIs[i].Border;
    img = TutorialGUIs[i].Image;

    // Set the size and offset of the border.
    sbg.WinHeight = cellHeight + BorderHeight;
    sbg.WinWidth  = cellWidth + BorderWidth;
    sbg.WinTop    = Y - BorderOffsetTop;
    sbg.WinLeft   = X - BorderOffsetLeft;

    // Set the size and offset of the image.
    img.WinHeight = cellHeight;
    img.WinWidth  = cellWidth;
    img.WinTop    = Y;
    img.WinLeft   = X;
  }
}


// ============================================================================
// GetScreenRatio
//
// Returns the heights of the screen proportional to the width.
// Example: 1024x768 equals 1:0.75, the function returns 0.75 then.
// ============================================================================

static function float GetScreenRatio(GUIController Controller)
{
  local string sX, sY;

  if (Controller == None) {
    Warn("Given GUIController is None.");
    return 1;
  }

  Divide(Controller.GetCurrentRes(), "x", sX, sY);

  return float(sY) / float(sX);
}


// ============================================================================
// ResolutionChanged
//
// Updates the bounds of the tutorial's images.
// ============================================================================

function ResolutionChanged(int ResX, int ResY)
{
  bResolutionChanged = True;

  Super.ResolutionChanged(ResX, ResY);
}


// ============================================================================
// DrawImages
//
// Updates the bounds of the tutorial's images.
// ============================================================================

function bool DrawImages(Canvas Canvas)
{
  if (bResolutionChanged) {
    SetGUIPosition();
    bResolutionChanged = False;
  }

  return False;
}


// ============================================================================
// Default properties.
// ============================================================================

defaultproperties
{
  Tutorials[0] = (Texture="JBToolbox2.MiniTutorial",X1=0,Y1=0,X2=1199,Y2=199,Title="Imprison",Description="Kill a player to jail him.")
  Tutorials[1] = (Texture="JBToolbox2.MiniTutorial",X1=0,Y1=400,X2=1199,Y2=599,Title="Release",Description="Walk over the enemy's release switch to free your teammates.")
  Tutorials[2] = (Texture="JBToolbox2.MiniTutorial",X1=0,Y1=200,X2=1199,Y2=399,Title="Score",Description="Jail everybody on the enemy team to execute them and gain a point.")
}
