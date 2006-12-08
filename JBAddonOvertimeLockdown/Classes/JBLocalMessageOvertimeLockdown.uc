// ============================================================================
// JBLocalMessageOvertimeLockdown - original by _Lynx
// Copyright 2006 by Jrubzjeknf <rrvanolst@hotmail.com>
// $Id$
//
// Used instead of normal overtime announcement.
// ============================================================================


class JBLocalMessageOvertimeLockdown extends LocalMessage;


// ============================================================================
// Variables
// ============================================================================

var localized string TextOvertimeLockdown;
var localized string TextLockdownCountdown;
var localized string TextTeleport;
var localized string TextLockdownStarts;
var localized string TextNoEscaping;
var localized string TextMinute;
var localized string TextMinutes;


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
  local JBTagPlayer TagPlayer;
  local JBGameRulesOvertimeLockdown GameRules;

  GameRules = JBGameRulesOvertimeLockdown(ObjectOptional);

  // Announces lockdown at overtime.
  if (Switch == -1)
    return FormatMinute(default.TextLockdownStarts, GameRules.LockdownDelay);

  // Instigator tried to escape.
  if (Switch == -2)
    return default.TextNoEscaping;

  if (GameRules == None) {
    Warn("JBLocalMessageOvertimeLockdown expects a JBGameRulesOvertimeLockdown as ObjectOptional, gets"@GameRules$"!");
    return "";
  }

  if (GameRules.Level.GetLocalPlayerController() != None &&
      GameRules.Level.GetLocalPlayerController().PlayerReplicationInfo != None &&
      class'JBTagPlayer'.static.FindFor(GameRules.Level.GetLocalPlayerController().PlayerReplicationInfo) != None)
    TagPlayer = class'JBTagPlayer'.static.FindFor(GameRules.Level.GetLocalPlayerController().PlayerReplicationInfo);

  if (TagPlayer == None)
    return "";

  // When counting down. Adds if the player will be teleported or not.
  if (Switch > 0) {
    if (GameRules.RestartPlayers == 2 ||
       (GameRules.RestartPlayers == 1 && TagPlayer.IsFree()))
      return FormatTime(default.TextLockdownCountdown, Switch)@default.TextTeleport;

    return FormatTime(default.TextLockdownCountdown, Switch);
  }

  return default.TextOvertimeLockdown;
}


// ============================================================================
// FormatTime / FormatMinute
//
// Replaces a string with a variable number or a localized string.
// ============================================================================

static function string FormatTime(string S, int iTime)
{
  return class'JBLocalMessage'.static.StaticReplaceText(S, "%time%", string(iTime));
}

static function string FormatMinute(String S, int iMinutes)
{
  S = FormatTime(S, iMinutes);

  if (iMinutes == 1)
    return class'JBLocalMessage'.static.StaticReplaceText(S, "%minute%", default.TextMinute);

  return class'JBLocalMessage'.static.StaticReplaceText(S, "%minute%", default.TextMinutes);
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  TextLockdownStarts    = "Lockdown starts in %time% %minute%."
  TextLockdownCountdown = "Lockdown in %time%."
  TextTeleport          = "Prepare to be teleported!"
  TextOvertimeLockdown  = "Locks jammed - last chance to win!"
  TextNoEscaping        = "No escaping in Lockdown!"
  TextMinute            = "minute"
  TextMinutes           = "minutes"

  bBeep = True
  bIsUnique=True
  bFadeMessage=True
  Lifetime=4
  FontSize=1
  DrawColor=(R=255,G=15,B=15,A=255),
  StackMode=2
  PosY=0.60
}
