// ============================================================================
// JBLocalMessageScreen
// Copyright 2004 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Displays on-screen messages.
// ============================================================================


class JBLocalMessageScreen extends JBLocalMessage
  notplaceable;


// ============================================================================
// Variables
// ============================================================================

var float PosYTeam;        // position for capture and release messages
var float PosYArena;       // position for arena messages

var Color ColorTextTeam;   // color for capture and release messages
var Color ColorTextArena;  // color for arena messages


// ============================================================================
// GetColor
//
// Returns the color to use for the given message.
// ============================================================================

static function Color GetColor(optional int Switch,
                               optional PlayerReplicationInfo PlayerReplicationInfo1,
                               optional PlayerReplicationInfo PlayerReplicationInfo2)
{
       if (Switch < 400) return Default.ColorTextTeam;
  else if (Switch < 500) return Default.ColorTextArena;
  
  return Super.GetColor(Switch, PlayerReplicationInfo1, PlayerReplicationInfo2);
}


// ============================================================================
// GetPos
//
// Returns the position to use for the given message.
// ============================================================================

static function GetPos(int Switch,
                       out EDrawPivot OutDrawPivot,
                       out EStackMode OutStackMode,
                       out float OutPosX, out float OutPosY)
{
  Super.GetPos(Switch, OutDrawPivot, OutStackMode, OutPosX, OutPosY);

       if (Switch < 400) OutPosY = Default.PosYTeam;
  else if (Switch < 500) OutPosY = Default.PosYArena;
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  bIsConsoleMessage = False;

  ColorTextTeam  = (R=000,G=160,B=255,A=255);
  ColorTextArena = (R=032,G=064,B=255,A=255);

  PosYTeam  = 0.12;
  PosYArena = 0.70;

  bFadeMessage = True;
  bIsUnique    = True;
  bIsSpecial   = True;
}