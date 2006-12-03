// ============================================================================
// JBGameRulesOvertimeLockdown - original by _Lynx
// Copyright 2006 by Jrubzjeknf <rrvanolst@hotmail.com>
// $id$
//
// When in overtime starts, the releases will be jammed. Once you're jailed,
// there's no getting out any more. Last chance to score a point!
// ============================================================================


class JBGameRulesOvertimeLockdown extends JBGameRules;


// ============================================================================
// Variables
// ============================================================================

var bool bNoArenaInOvertime;
var bool bNoEscapeInOvertime;
var byte RestartPlayers; // 0=dont, 1=free, 2=everybody
var byte LockdownDelay;  // in minutes

var class<JBLocalMessageOvertimeLockdown> MessageClassOvertimeLockdown;
var byte StartCountdownTime;
var byte Countdown;


// ============================================================================
// CanBroadcast
//
// When overtime starts, a message is passed through and ends up here.
// ============================================================================

function bool CanBroadcast(class<LocalMessage> MessageClass, optional int switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
  // When overtime start.
  if (switch == 910) {
    if (LockdownDelay == 0)
      GotoState('Lockdown');
    else
      GotoState('WaitAndCountdown');
  }

  return Super.CanBroadcast(MessageClass, switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
}


// ============================================================================
// state WaitAndCountdown
//
// Wait before starting the Lockdown, which begins after a countdown.
// ============================================================================

state WaitAndCountdown {

  // ================================================================
  // BeginState
  //
  // Announce how long it'll take before the Lockdown starts,
  // calculate when to start counting down and start the timer.
  // ================================================================

  event BeginState()
  {
    Level.Game.BroadcastHandler.BroadcastLocalizedMessage(MessageClassOvertimeLockdown, -1,,, Self);

    StartCountdownTime = DeathMatch(Level.Game).ElapsedTime + LockdownDelay*60 - 9;

    SetTimer(1, True);
  }


  // ================================================================
  // Timer
  //
  // Count down the last 10 seconds. Broadcast the countdown.
  // ================================================================

  function Timer()
  {
    // Cancel lockdown if executing.
    if (Jailbreak(Level.Game).IsInState('Executing')) {
      SetTimer(0, False);
      return;
    }

    if (DeathMatch(Level.Game).ElapsedTime >= StartCountdownTime) {
      Level.Game.BroadcastHandler.BroadcastLocalizedMessage(MessageClassOvertimeLockdown, Countdown,,, Self);

      // Done with countdown.
      if (Countdown == 0) {
        SetTimer(0, False);
        GotoState('Lockdown');
        return;
      }

      Countdown--;
    }
  }
}


// ============================================================================
// state Lockdown
//
// Lockdown has started.
// ============================================================================

state Lockdown {

  // ================================================================
  // BeginState
  //
  // Jam the locks, cancel any ongoing arena match, restart players
  // and notify the players of the lockdown.
  // ================================================================

  event BeginState()
  {
    local JBInfoJail firstJail;
    local JBInfoJail thisJail;
    local JBInfoArena firstArena;
    local JBInfoArena thisArena;

    // Jam the jails, thus the locks
    firstJail = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstJail;
    for (thisJail = firstJail; thisJail != None; thisJail = thisJail.nextJail) {
      thisJail.Jam(0);
      thisJail.Jam(1);
    }

    // Cancel ongoing arena matches.
    firstArena = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstArena;
    for (thisArena = firstArena; thisArena != None; thisArena = thisArena.nextArena)
      if (thisArena.IsInState('MatchRunning'))
        thisArena.MatchTie();

    // Restart players.
    switch (RestartPlayers) {
      case 1: Jailbreak(Level.Game).RestartPlayers(True); break; // restart free players
      case 2: Jailbreak(Level.Game).RestartAll();         break; // restart all
    }

    Level.Game.BroadcastHandler.BroadcastLocalizedMessage(MessageClassOvertimeLockdown,,,,Self);
  }


  // ================================================================
  // CanBroadcast
  //
  // Prevent a message from popping up when an arena match is
  // cancelled during the lockdown.
  // ================================================================

  function bool CanBroadcast(class<LocalMessage> MessageClass, optional int switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
  {
    if (switch == 410 || switch == 420)
      return False; // arenamatch tie - caused by this addon when Lockdown starts

    return Super.CanBroadcast(MessageClass, switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
  }


  // ================================================================
  // CanSendToArena
  //
  // If specified, don't allow arena matches in overtime. Arena
  // matches in countdown will be automatically cancelled.
  // ================================================================

  function bool CanSendToArena(JBTagPlayer TagPlayer, JBInfoArena Arena, out byte bForceSendToArena)
  {
    if (bNoArenaInOvertime)
      return False;

    return Super.CanSendToArena(TagPlayer, Arena, bForceSendToArena);
  }


  // ================================================================
  // AllowForcedRelease
  //
  // Do not allow any releases in overtime.
  // ================================================================

  function bool AllowForcedRelease(JBInfoJail Jail, TeamInfo Team, optional Controller ControllerInstigator)
  {
    return False;
  }


  // ================================================================
  // NotifyPlayerReleased
  //
  // Prevent escaping during Lockdown if the release wasn't already
  // active when it started.
  // ================================================================

  function NotifyPlayerReleased(JBTagPlayer TagPlayer, JBInfoJail Jail)
  {
    if (!Jail.IsReleaseMoverOpen(TagPlayer.GetTeam()) &&
        !Jailbreak(Level.Game).IsInState('Executing')) {
      Level.Game.BroadcastHandler.BroadcastLocalizedMessage(MessageClassOvertimeLockdown, -2); // play message
      TagPlayer.RestartInJail();
    }

    Super.NotifyPlayerReleased(TagPlayer, Jail);
  }
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  Countdown = 10
  MessageClassOvertimeLockdown = class'JBLocalMessageOvertimeLockdown'
}