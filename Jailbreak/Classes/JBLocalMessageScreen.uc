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

var int FontSizeTeam;          // font size for capture and release messages
var int FontSizeArena;         // font size for arena messages
var int FontSizeKeyboard;      // font size for keyboard information messages
var int FontSizeLastMan;       // font size for last man message

var float PosYTeam;            // position for capture and release messages
var float PosYArena;           // position for arena messages
var float PosYKeyboardArena;   // position for keyboard arena messages
var float PosYKeyboardCamera;  // position for keyboard camera messages
var float PosYLastMan;         // position for last man message

var Color ColorTextTeam;       // color for capture and release messages
var Color ColorTextArena;      // color for arena messages
var Color ColorTextKeyboard;   // color for keyboard information messages
var Color ColorTextLastMan;    // color for last man message

var int LifetimeTeam;          // lifetime of capture and release messages
var int LifetimeArena;         // lifetime of arena messages
var int LifetimeKeyboard;      // lifetime of keyboard information messages
var int LifetimeLastMan;       // lifetime of last man message


// ============================================================================
// ClientReceive
//
// Clears previous messages of the same message group from the screen.
// ============================================================================

static function ClientReceive(PlayerController PlayerController,
                              optional int Switch,
                              optional PlayerReplicationInfo PlayerReplicationInfo1,
                              optional PlayerReplicationInfo PlayerReplicationInfo2,
                              optional Object ObjectOptional)
{
  local JBInterfaceHud JBInterfaceHud;
  
  JBInterfaceHud = JBInterfaceHud(PlayerController.myHUD);

  if (Switch >= 400 && Switch <= 499) {
    JBInterfaceHud.ClearMessageByClass(Default.Class, 400);
    JBInterfaceHud.ClearMessageByClass(Default.Class, 401);
    JBInterfaceHud.ClearMessageByClass(Default.Class, 402);
    JBInterfaceHud.ClearMessageByClass(Default.Class, 403);
  }

  Super.ClientReceive(PlayerController, Switch, PlayerReplicationInfo1, PlayerReplicationInfo2, ObjectOptional);
}


// ============================================================================
// GetColor
//
// Returns the color to use for the given message.
// ============================================================================

static function Color GetColor(optional int Switch,
                               optional PlayerReplicationInfo PlayerReplicationInfo1,
                               optional PlayerReplicationInfo PlayerReplicationInfo2)
{
       if (Switch <= 399) return Default.ColorTextTeam;
  else if (Switch <= 499) return Default.ColorTextArena;
  else if (Switch <= 599) return Default.ColorTextKeyboard;
  else if (Switch <= 699) return Default.ColorTextLastMan;
  
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

       if (Switch <= 399) OutPosY = Default.PosYTeam;
  else if (Switch <= 499) OutPosY = Default.PosYArena;
  else if (Switch == 500) OutPosY = Default.PosYKeyboardArena;
  else if (Switch == 510) OutPosY = Default.PosYKeyboardCamera;
  else if (Switch <= 699) OutPosY = Default.PosYLastMan;
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
       if (Switch <= 399) return Default.FontSizeTeam;
  else if (Switch <= 499) return Default.FontSizeArena;
  else if (Switch <= 599) return Default.FontSizeKeyboard;
  else if (Switch <= 699) return Default.FontSizeLastMan;
  
  return Super.GetFontSize(Switch, PlayerReplicationInfo1, PlayerReplicationInfo2, PlayerReplicationInfoLocal);
}


// ============================================================================
// GetLifeTime
//
// Returns the lifetime of the given message.
// ============================================================================

static function float GetLifeTime(int Switch)
{
       if (Switch <= 399) return Default.LifetimeTeam;
  else if (Switch <= 499) return Default.LifetimeArena;
  else if (Switch <= 599) return Default.LifetimeKeyboard;
  else if (Switch <= 699) return Default.LifetimeLastMan;

  return Super.GetLifeTime(Switch);  
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  bIsConsoleMessage  = False;
  StackMode          = SM_Down;

  FontSizeTeam       =  0;  // larger
  FontSizeArena      =  0;  // larger
  FontSizeKeyboard   = -2;  // small
  FontSizeLastMan    =  0;  // larger

  ColorTextTeam      = (R=000,G=160,B=255,A=255);
  ColorTextArena     = (R=032,G=064,B=255,A=255);
  ColorTextKeyboard  = (R=255,G=255,B=255,A=255);
  ColorTextLastMan   = (R=255,G=255,B=000,A=255);

  PosYTeam           = 0.13;
  PosYArena          = 0.70;
  PosYKeyboardArena  = 0.13;
  PosYKeyboardCamera = 0.04;
  PosYLastMan        = 0.13;

  LifetimeTeam       = 3;
  LifetimeArena      = 3;
  LifetimeKeyboard   = 6;
  LifetimeLastMan    = 1;

  bFadeMessage       = True;
  bIsPartiallyUnique = True;
  bIsSpecial         = True;
}