//=============================================================================
// JBGUIPanelConfigAddonDefault
// Copyright 2004 by tarquin <tarquin@planetjailbreak.com>
// $Id$
//
// Default config panel for add-ons that do not specify their own.
//=============================================================================


class JBGUIPanelConfigAddonDefault extends GUIPanel;


//=============================================================================
// Defaults
//=============================================================================

defaultproperties
{
  Begin Object class=GUILabel Name=BasicLabel
    Caption="This add-on has no user-set properties."
    WinLeft=0.0
    WinTop=0.2
    WinWidth=1.0
    WinHeight=40
    bBoundToParent=true
    bScaleToParent=true
  End Object
  Controls(0)=GUILabel'BasicLabel'
  
  WinWidth=1.000000
  WinHeight=0.098750
  WinLeft=0.000000
  WinTop=0.473333
}
