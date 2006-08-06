// ============================================================================
// JBGameRules
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBGameRules.uc,v 1.10 2006-04-17 20:57:47 lynx Exp $
//
// Allows mod authors to hook into and alter the Jailbreak game rules.
//
// See http://www.planetjailbreak.com/jdn/JBGameRules for details about the
// notifications and queries exposed in this class.
// ============================================================================


class JBGameRules extends GameRules
  abstract;


// ============================================================================
// NotifyRound
//
// Called when a game round starts, including the first round in a game.
// ============================================================================

function NotifyRound()
{
  local JBGameRules nextJBGameRules;

  nextJBGameRules = GetNextJBGameRules();
  if (nextJBGameRules != None)
    nextJBGameRules.NotifyRound();
}


// ============================================================================
// NotifyPlayerDisconnect
//
// Called when a human player disconnects from an ongoing match. The bIsLlama
// parameter can be set to indicate that this player should be considered a
// llama the next time he or she rejoins the game.
// ============================================================================

function NotifyPlayerDisconnect(PlayerController ControllerPlayer, out byte bIsLlama)
{
  local JBGameRules nextJBGameRules;

  nextJBGameRules = GetNextJBGameRules();
  if (nextJBGameRules != None)
    nextJBGameRules.NotifyPlayerDisconnect(ControllerPlayer, bIsLlama);
}


// ============================================================================
// NotifyPlayerReconnect
//
// Called when a human player reconnects to an ongoing match after having
// disconnected from it before. Not called for a player's initial connection
// to a game. The bIsLlama parameter tells whether the player left within the
// same round they reconnected and was in jail when they disconnected.
// ============================================================================

function NotifyPlayerReconnect(PlayerController ControllerPlayer, bool bIsLlama)
{
  local JBGameRules nextJBGameRules;

  nextJBGameRules = GetNextJBGameRules();
  if (nextJBGameRules != None)
    nextJBGameRules.NotifyPlayerReconnect(ControllerPlayer, bIsLlama);
}


// ============================================================================
// CanSendToArena
//
// Called to check whether a jailed player can be sent to the given arena. If
// this function returns False during the arena countdown for a player already
// scheduled for a fight in the given arena, the match will be cancelled. The
// bForceSendToArena out parameter can be set to allow even players who are
// not in jail to be sent to the arena.
// ============================================================================

function bool CanSendToArena(JBTagPlayer TagPlayer, JBInfoArena Arena, out byte bForceSendToArena)
{
  local JBGameRules nextJBGameRules;

  nextJBGameRules = GetNextJBGameRules();
  if (nextJBGameRules != None)
    return nextJBGameRules.CanSendToArena(TagPlayer, Arena, bForceSendToArena);

  return True;
}


// ============================================================================
// NotifyArenaStart
//
// Called direcly after both arena combatants have been spawned in the arena.
// ============================================================================

function NotifyArenaStart(JBInfoArena Arena)
{
  local JBGameRules nextJBGameRules;

  nextJBGameRules = GetNextJBGameRules();
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

function NotifyArenaEnd(JBInfoArena Arena, JBTagPlayer TagPlayerWinner)
{
  local JBGameRules nextJBGameRules;

  nextJBGameRules = GetNextJBGameRules();
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

function bool CanSendToJail(JBTagPlayer TagPlayer)
{
  local JBGameRules nextJBGameRules;

  nextJBGameRules = GetNextJBGameRules();
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

function bool CanRelease(TeamInfo Team, Pawn PawnInstigator, GameObjective Objective)
{
  local JBGameRules nextJBGameRules;

  nextJBGameRules = GetNextJBGameRules();
  if (nextJBGameRules != None)
    return nextJBGameRules.CanRelease(Team, PawnInstigator, Objective);

  return True;
}


// ============================================================================
// AllowForcedRelease
//
// Called when a jail is jammed, but something/someone wants to force a
// release anyway. The function allows mutators to block that behaviour.
// ============================================================================

function bool AllowForcedRelease(JBInfoJail Jail, TeamInfo Team, optional Controller ControllerInstigator)
{
  local JBGameRules nextJBGameRules;

  nextJBGameRules = GetNextJBGameRules();
  if (nextJBGameRules != None)
    return nextJBGameRules.AllowForcedRelease(Jail, Team, ControllerInstigator);

  return True;
}


// ============================================================================
// CanBroadcast
//
// Called when a game attempts to broadcast a localised message to players.
// ============================================================================

function bool CanBroadcast( class<LocalMessage> MessageClass, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
  local JBGameRules nextJBGameRules;

  nextJBGameRules = GetNextJBGameRules();
  if (nextJBGameRules != None)
    return nextJBGameRules.CanBroadcast(MessageClass, switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);

  return True;
}


// ============================================================================
// NotifyJailOpening
//
// Called when somebody activated the release switch and the jail doors start
// opening, but haven't fully opened yet.
// ============================================================================

function NotifyJailOpening(JBInfoJail Jail, TeamInfo Team)
{
  local JBGameRules nextJBGameRules;

  nextJBGameRules = GetNextJBGameRules();
  if (nextJBGameRules != None)
    nextJBGameRules.NotifyJailOpening(Jail, Team);
}


// ============================================================================
// NotifyJailOpened
//
// Called when, after NotifyJailOpening was called, the jail doors have
// completed opening and are fully open now.
// ============================================================================

function NotifyJailOpened(JBInfoJail Jail, TeamInfo Team)
{
  local JBGameRules nextJBGameRules;

  nextJBGameRules = GetNextJBGameRules();
  if (nextJBGameRules != None)
    nextJBGameRules.NotifyJailOpened(Jail, Team);
}


// ============================================================================
// NotifyJailClosed
//
// Called when, after a release, the jail doors have completely closed again
// and before the objectives are activated again.
// ============================================================================

function NotifyJailClosed(JBInfoJail Jail, TeamInfo Team)
{
  local JBGameRules nextJBGameRules;

  nextJBGameRules = GetNextJBGameRules();
  if (nextJBGameRules != None)
    nextJBGameRules.NotifyJailClosed(Jail, Team);
}


// ============================================================================
// NotifyPlayerJailed
//
// Called when a player enters a jail, for instance by being spawned there
// after being killed, or by being sent there after losing an arena fight, or
// by simply physically walking into it.
// ============================================================================

function NotifyPlayerJailed(JBTagPlayer TagPlayer)
{
  local JBGameRules nextJBGameRules;

  nextJBGameRules = GetNextJBGameRules();
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

function NotifyPlayerReleased(JBTagPlayer TagPlayer, JBInfoJail Jail)
{
  local JBGameRules nextJBGameRules;

  nextJBGameRules = GetNextJBGameRules();
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

function NotifyExecutionCommit(TeamInfo Team)
{
  local JBGameRules nextJBGameRules;

  nextJBGameRules = GetNextJBGameRules();
  if (nextJBGameRules != None)
    nextJBGameRules.NotifyExecutionCommit(Team);
}


// ============================================================================
// NotifyExecutionEnd
//
// Called when the execution sequence has been completed, directly before the
// next round starts.
// ============================================================================

function NotifyExecutionEnd()
{
  local JBGameRules nextJBGameRules;

  nextJBGameRules = GetNextJBGameRules();
  if (nextJBGameRules != None)
    nextJBGameRules.NotifyExecutionEnd();
}


// ============================================================================
// CanBotAttackEnemy
//
// Called when a bot looks for a new enemy. Returning True means that the bot
// is allowed to attack the given enemy; returning False prevents the bot from
// attacking the enemy.
// ============================================================================

function bool CanBotAttackEnemy(Bot Bot, Pawn PawnEnemy)
{
  local JBGameRules nextJBGameRules;

  nextJBGameRules = GetNextJBGameRules();
  if (nextJBGameRules != None)
    return nextJBGameRules.CanBotAttackEnemy(Bot, PawnEnemy);

  return True;
}


// ============================================================================
// GetNextJBGameRules
//
// Internal. Used to find the next JBGameRules actor in the GameRules chain.
// ============================================================================

protected final function JBGameRules GetNextJBGameRules()
{
  local GameRules thisGameRules;

  for (thisGameRules = NextGameRules; thisGameRules != None; thisGameRules = thisGameRules.NextGameRules)
    if (JBGameRules(thisGameRules) != None)
      return JBGameRules(thisGameRules);

  return None;
}
