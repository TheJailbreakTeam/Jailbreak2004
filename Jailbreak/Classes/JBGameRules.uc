// ============================================================================
// JBGameRules
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBGameRules.uc,v 1.2 2003/01/30 23:18:18 mychaeel Exp $
//
// Allows mod authors to hook into and alter the Jailbreak game rules.
//
// See http://www.planetjailbreak.com/jdn/JBGameRules for details about the
// notifications and queries exposed in this class.
// ============================================================================


class JBGameRules extends Info
  abstract;


// ============================================================================
// Variables
// ============================================================================

var JBGameRules nextJBGameRules;  // next game rules object in chain


// ============================================================================
// NotifyRound
//
// Called when a game round starts, including the first round in a game.
// ============================================================================

function NotifyRound() {

  if (nextJBGameRules != None)
    nextJBGameRules.NotifyRound();
  }


// ============================================================================
// NotifyPlayerReconnect
//
// Called when a player reconnects to an ongoing match after having
// disconnected from it before. Not called for a player's initial connection
// to a game. The bIsLlama parameter tells whether the player left within the
// same round they reconnected and was in jail when they disconnected.
// ============================================================================

function NotifyPlayerReconnect(PlayerController ControllerPlayer, bool bIsLlama) {

  if (nextJBGameRules != None)
    nextJBGameRules.NotifyPlayerReconnect(ControllerPlayer, bIsLlama);
  }


// ============================================================================
// CanSendToArena
//
// Called to check whether a jailed player can be sent to the given arena. If
// this function returns False during the arena countdown for a player already
// scheduled for a fight in the given arena, the match will be cancelled.
// ============================================================================

function bool CanSendToArena(JBTagPlayer TagPlayer, JBInfoArena Arena) {

  if (nextJBGameRules != None)
    return nextJBGameRules.CanSendToArena(TagPlayer, Arena);
  
  return True;
  }


// ============================================================================
// NotifyArenaStart
//
// Called direcly after both arena combatants have been spawned in the arena.
// ============================================================================

function NotifyArenaStart(JBInfoArena Arena) {

  if (nextJBGameRules != None)
    nextJBGameRules.NotifyArenaStart(Arena);
  }


// ============================================================================
// NotifyArenaEnd
//
// Called when an arena match has been decided, directly after the winner (if
// any) has been respawned in freedom. The loser might have respawned in jail
// a short time earlier already.
// ============================================================================

function NotifyArenaEnd(JBInfoArena Arena, JBTagPlayer TagPlayerWinner) {

  if (nextJBGameRules != None)
    nextJBGameRules.NotifyArenaEnd(Arena, TagPlayerWinner);
  }


// ============================================================================
// CanSendToJail
//
// Called when a player is about to be sent to jail by the game. Not called
// for players who simply physically enter jail or are sent back to jail after
// losing an arena fight. Returning False will restart the player in freedom.
// ============================================================================

function bool CanSendToJail(JBTagPlayer TagPlayer) {

  if (nextJBGameRules != None)
    return nextJBGameRules.CanSendToJail(TagPlayer);
  
  return True;
  }


// ============================================================================
// CanRelease
//
// Called when a player attempts to release a team by activating a release
// switch. Returning False will prevent the release; in that case the
// objectives for this jail will remain disabled for a short time before
// they are activated again.
// ============================================================================

function bool CanRelease(TeamInfo Team, Pawn PawnInstigator, GameObjective Objective) {

  if (nextJBGameRules != None)
    return nextJBGameRules.CanRelease(Team, PawnInstigator, Objective);
  
  return True;
  }


// ============================================================================
// NotifyJailOpening
//
// Called when somebody activated the release switch and the jail doors start
// opening, but haven't fully opened yet.
// ============================================================================

function NotifyJailOpening(JBInfoJail Jail) {

  if (nextJBGameRules != None)
    nextJBGameRules.NotifyJailOpening(Jail);
  }


// ============================================================================
// NotifyJailOpened
//
// Called when, after NotifyJailOpening was called, the jail doors have
// completed opening and are fully open now.
// ============================================================================

function NotifyJailOpened(JBInfoJail Jail) {

  if (nextJBGameRules != None)
    nextJBGameRules.NotifyJailOpened(Jail);
  }


// ============================================================================
// NotifyJailClosed
//
// Called when, after a release, the jail doors have completely closed again
// and before the objectives are activated again.
// ============================================================================

function NotifyJailClosed(JBInfoJail Jail) {

  if (nextJBGameRules != None)
    nextJBGameRules.NotifyJailClosed(Jail);
  }


// ============================================================================
// NotifyPlayerJailed
//
// Called when a player enters a jail, for instance by being spawned there
// after being killed, or by being sent there after losing an arena fight, or
// by simply physically walking into it.
// ============================================================================

function NotifyPlayerJailed(JBTagPlayer TagPlayer) {

  if (nextJBGameRules != None)
    nextJBGameRules.NotifyPlayerJailed(TagPlayer);
  }


// ============================================================================
// NotifyPlayerReleased
//
// Called when a player leaves jail. Note that this also happens before and
// during the execution sequence and when a player is teleported to an arena
// for a fight.
// ============================================================================

function NotifyPlayerReleased(JBTagPlayer TagPlayer, JBInfoJail Jail) {

  if (nextJBGameRules != None)
    nextJBGameRules.NotifyPlayerReleased(TagPlayer, Jail);
  }


// ============================================================================
// NotifyExecutionCommit
//
// Called when a team is about to be executed, before the execution sequence
// starts and directly after the other players' views switch to the execution
// camera.
// ============================================================================

function NotifyExecutionCommit(TeamInfo Team) {

  if (nextJBGameRules != None)
    nextJBGameRules.NotifyExecutionCommit(Team);
  }


// ============================================================================
// NotifyExecutionEnd
//
// Called when the execution sequence has been completed, directly before the
// next round starts.
// ============================================================================

function NotifyExecutionEnd() {

  if (nextJBGameRules != None)
    nextJBGameRules.NotifyExecutionEnd();
  }


// ============================================================================
// AddJBGameRules
//
// Internal. Used to add a JBGameRules actor to the end of the current chain.
// ============================================================================

function AddJBGameRules(JBGameRules JBGameRules) {

  if (nextJBGameRules == None)
    nextJBGameRules = JBGameRules;
  else
    nextJBGameRules.AddJBGameRules(JBGameRules);
  }
