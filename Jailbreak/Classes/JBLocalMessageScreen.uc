// ============================================================================
// JBLocalMessageScreen
// Copyright 2004 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBLocalMessageScreen.uc,v 1.3 2004/04/20 15:13:12 mychaeel Exp $
//
// Displays on-screen messages.
// ============================================================================


class JBLocalMessageScreen extends JBLocalMessage
  notplaceable;


// ============================================================================
// Variables
// ============================================================================

var int FontSizeTeam;          // font size for capture and release messages
var int FontSizeArena;         // font size for arena messages
var int FontSizeKeyboard;      // font size for keyboard information messages

var float PosYTeam;            // position for capture and release messages
var float PosYArena;           // position for arena messages
var float PosYKeyboardArena;   // position for keyboard arena messages
var float PosYKeyboardCamera;  // position for keyboard camera messages

var Color ColorTextTeam;       // color for capture and release messages
var Color ColorTextArena;      // color for arena messages
var Color ColorTextKeyboard;   // color for keyboard information messages

var int LifetimeTeam;          // lifetime of capture and release messages
var int LifetimeArena;         // lifetime of arena messages
var int LifetimeKeyboard;      // lifetime of keyboard information messages


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
  else if (Switch < 600) return Default.ColorTextKeyboard;
  
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

       if (Switch <  400) OutPosY = Default.PosYTeam;
  else if (Switch <  500) OutPosY = Default.PosYArena;
  else if (Switch == 500) OutPosY = Default.PosYKeyboardArena;
  else if (Switch == 510) OutPosY = Default.PosYKeyboardCamera;
}


// ============================================================================
// GetFontSize
//
// Returns the font size to use for the given message.
// ============================================================================

static function int GetFontSize(int Switch,
                                PlayerReplicationInfo PlayerReplicationInfo1,
                                PlayerReplicationInfo PlayerReplicationInfo2,
                                PlayerReplicationInfo PlayerReplicationInfoLocal)
{
       if (Switch < 400) return Default.FontSizeTeam;
  else if (Switch < 500) return Default.FontSizeArena;
  else if (Switch < 600) return Default.FontSizeKeyboard;
  
  return Super.GetFontSize(Switch, PlayerReplicationInfo1, PlayerReplicationInfo2, PlayerReplicationInfoLocal);
}


// ============================================================================
// GetLifeTime
//
// Returns the lifetime of the given message.
// ============================================================================

static function float GetLifeTime(int Switch)
{
       if (Switch < 400) return Default.LifetimeTeam;
  else if (Switch < 500) return Default.LifetimeArena;
  else if (Switch < 600) return Default.LifetimeKeyboard;

  return Super.GetLifeTime(Switch);  
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  bIsConsoleMessage  = False;
  StackMode          = SM_Down;

  FontSizeTeam       =  0;  // normal
  FontSizeArena      =  0;  // normal
  FontSizeKeyboard   = -2;  // small

  ColorTextTeam      = (R=000,G=160,B=255,A=255);
  ColorTextArena     = (R=032,G=064,B=255,A=255);
  ColorTextKeyboard  = (R=255,G=255,B=255,A=255);

  PosYTeam           = 0.12;
  PosYArena          = 0.70;
  PosYKeyboardArena  = 0.12;
  PosYKeyboardCamera = 0.04;

  LifetimeTeam       = 3;
  LifetimeArena      = 3;
  LifetimeKeyboard   = 6;

  bFadeMessage       = True;
  bIsPartiallyUnique = True;
  bIsSpecial         = True;
}