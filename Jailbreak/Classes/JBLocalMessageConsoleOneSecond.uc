// ============================================================================
// JBLocalMessageConsoleOneSecond
// Copyright 2008 by Jrubzjeknf <rrvanolst@hotmail.com>
// $Id$
//
// Displays console messages of one second. A seperate class is required, since
// HUD.AddTextMessage() is unable to use LocalMessage.GetLifeTime().
// ============================================================================


class JBLocalMessageConsoleOneSecond extends JBLocalMessageConsole
  notplaceable;


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  LifeTime = 1;
}