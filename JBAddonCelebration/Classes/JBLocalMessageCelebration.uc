//=============================================================================
// JBLocalMessageCelebration
// Copyright 2012 by Wormbo
// $Id$
//
// Displays a usage hint to the player currently controlling the celebration
// screen.
//=============================================================================


class JBLocalMessageCelebration extends JBLocalMessageScreen abstract;


//=============================================================================
// Localization
//=============================================================================

var localized string TextKeyboardCelebration;


// ============================================================================
// GetString
//
// Gets the localized string for the given event. See ClientReceive for an
// explanation of possible parameter values.
// ============================================================================

static function string GetString(optional int Switch,
                                 optional PlayerReplicationInfo PlayerReplicationInfo1,
                                 optional PlayerReplicationInfo PlayerReplicationInfo2,
                                 optional Object ObjectOptional)
{
  switch (Switch) {
    case 520: return default.TextKeyboardCelebration;

    default:  return Super.GetString(Switch, PlayerReplicationInfo1, PlayerReplicationInfo2, ObjectOptional);
  }
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

  if (Switch == 520) OutPosY = Default.PosYKeyboardArena;
}


//=============================================================================
// Default values
//=============================================================================

defaultproperties
{
  TextKeyboardCelebration = "Press your movement and taunt keys to celebrate the capture"
}

