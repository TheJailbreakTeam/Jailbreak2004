// ============================================================================
// JBLocalMessage
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Localized messages for generic Jailbreak announcements.
// ============================================================================


class JBLocalMessage extends LocalMessage
  notplaceable;


// ============================================================================
// Localization
// ============================================================================

var localized string TextTeamCaptured[2];
var localized string TextTeamReleased[2];
var localized string TextTeamStalemate;


// ============================================================================
// ClientReceive
//
// Receives an event on a client's computer and performs appropriate actions.
// The parameters assume the following values:
//
//   Switch    Meaning             Info 1           Info 2           Object    
//   =======   =================   ==============   ==============   ========
//   100 (b)   Team captured                                         TeamInfo
//   200 (b)   Team released       Releaser                          TeamInfo
//   300 (b)   Team stalemate
//   403       Arena countdown 3                                     Arena
//   402       Arena countdown 2                                     Arena
//   401       Arena countdown 1                                     Arena
//   400 (b)   Arena start         Red Combatant    Blue Combatant   Arena
//   410 (b)   Arena tie           Red Combatant    Blue Combatant   Arena
//   420 (b)   Arena victory       Winner           Loser            Arena
//
// Switches marked with (b) are broadcasted to all players, all other messages
// are directly sent to the players in question.
// ============================================================================

static function ClientReceive(PlayerController Player,
                              optional int Switch,
                              optional PlayerReplicationInfo PlayerReplicationInfo1, 
                              optional PlayerReplicationInfo PlayerReplicationInfo2,
                              optional Object ObjectOptional) {

  Super.ClientReceive(Player, Switch, PlayerReplicationInfo1, PlayerReplicationInfo2, ObjectOptional);
  }


// ============================================================================
// GetString
//
// Gets the localized string for the given event. See ClientReceive for an
// explanation of possible parameter values.
// ============================================================================

static function string GetString(optional int Switch,
                                 optional PlayerReplicationInfo PlayerReplicationInfo1, 
                                 optional PlayerReplicationInfo PlayerReplicationInfo2,
                                 optional Object ObjectOptional) {

  switch (Switch) {
    case 100:  return Default.TextTeamCaptured[TeamInfo(ObjectOptional).TeamIndex];
    case 200:  return Default.TextTeamReleased[TeamInfo(ObjectOptional).TeamIndex];
    case 300:  return Default.TextTeamStalemate;
    }
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  TextTeamCaptured[0] = "The red team has been captured";
  TextTeamCaptured[1] = "The blue team has been captured";
  TextTeamReleased[0] = "The red team has been released";
  TextTeamReleased[1] = "The blue team has been released";
  TextTeamStalemate   = "Both teams captured, no score";

  bFadeMessage = True;
  bIsUnique    = True;
  bIsSpecial   = True;
  }