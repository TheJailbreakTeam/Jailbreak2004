// ============================================================================
// JBReplicationInfoPlayer
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBReplicationInfoPlayer.uc,v 1.3 2002/11/24 09:35:17 mychaeel Exp $
//
// Replicated information for a single player.
// ============================================================================


class JBReplicationInfoPlayer extends ReplicationInfo
  notplaceable;


// ============================================================================
// Replication
// ============================================================================

replication {

  reliable if (Role == ROLE_Authority)
    PlayerReplicationInfo, Arena, ArenaPending, Jail;
  }


// ============================================================================
// Types
// ============================================================================

enum ERestart {

  Restart_Jail,
  Restart_Freedom,
  Restart_Arena,
  };


// ============================================================================
// Variables
// ============================================================================

var private PlayerReplicationInfo PlayerReplicationInfo;

var private ERestart Restart;          // restart location for this player

var private JBInfoArena Arena;         // arena the player is currently in
var private JBInfoArena ArenaRestart;  // arena the player will be restarted in
var private JBInfoArena ArenaPending;  // arena the player is scheduled for
var private JBInfoArena ArenaRequest;  // arena the player has requested
var private float TimeArenaRequest;    // time of the arena request

var private JBInfoJail Jail;           // jail the player is currently in
var private float TimeRelease;         // time of last release from jail


// ============================================================================
// PostBeginPlay
//
// Starts the timer in a short interval.
// ============================================================================

event PostBeginPlay() {

  if (Controller(Owner) != None)
    PlayerReplicationInfo = Controller(Owner).PlayerReplicationInfo;
  
  SetTimer(0.2, True);
  }


// ============================================================================
// PostNetBeginPlay
//
// Registers this actor with the game.
// ============================================================================

simulated event PostNetBeginPlay() {

  local JBReplicationInfoGame InfoGame;

  InfoGame = JBReplicationInfoGame(Level.GRI);
  InfoGame.ListInfoPlayer[InfoGame.ListInfoPlayer.Length] = Self;
  }


// ============================================================================
// Destroyed
//
// Unregisters this actor.
// ============================================================================

simulated event Destroyed() {

  local int iInfoPlayer;
  local JBReplicationInfoGame InfoGame;

  InfoGame = JBReplicationInfoGame(Level.GRI);
  
  for (iInfoPlayer = InfoGame.ListInfoPlayer.Length - 1; iInfoPlayer >= 0; iInfoPlayer--)
    if (InfoGame.ListInfoPlayer[iInfoPlayer] == Self)
      InfoGame.ListInfoPlayer.Remove(iInfoPlayer, 1);
  }


// ============================================================================
// Timer
//
// Updates the Jail property periodically. If the player left jail, awards
// points to the release instigator. If the player entered jail while the
// release is active, prepares the player for release.
// ============================================================================

event Timer() {

  local int iInfoJail;
  local JBInfoJail JailPrev;
  local JBReplicationInfoGame InfoGame;

  JailPrev = Jail;
  Jail = None;

  if (Arena == None) {
    InfoGame = JBReplicationInfoGame(Level.GRI);
    
    for (iInfoJail = 0; iInfoJail < InfoGame.ListInfoJail.Length; iInfoJail++)
      if (InfoGame.ListInfoJail[iInfoJail].ContainsActor(Controller(Owner).Pawn)) {
        Jail = InfoGame.ListInfoJail[iInfoJail];
        break;
        }
    
         if (JailPrev == None && Jail != None) JailEntered();
    else if (JailPrev != None && Jail == None) JailLeft(JailPrev);
    }
  }


// ============================================================================
// FindFor
//
// Finds the JBReplicationInfoPlayer actor for the controller possessing the
// given PlayerReplicationInfo.
// ============================================================================

simulated static function JBReplicationInfoPlayer FindFor(PlayerReplicationInfo PlayerReplicationInfo) {

  local int iInfoPlayer;
  local JBReplicationInfoGame InfoGame;

  InfoGame = JBReplicationInfoGame(PlayerReplicationInfo.Level.GRI);

  for (iInfoPlayer = 0; iInfoPlayer < InfoGame.ListInfoPlayer.Length; iInfoPlayer++)
    if (InfoGame.ListInfoPlayer[iInfoPlayer].PlayerReplicationInfo == PlayerReplicationInfo)
      return InfoGame.ListInfoPlayer[iInfoPlayer];
  
  return None;
  }


// ============================================================================
// IsInArena
//
// Returns whether this player is fighting in an arena at the moment.
// ============================================================================

simulated function bool IsInArena() {

  return Arena != None;
  }


// ============================================================================
// IsInJail
//
// Returns whether this player is in jail at the moment.
// ============================================================================

simulated function bool IsInJail() {

  return Jail != None;
  }


// ============================================================================
// JailEntered
//
// Automatically called when the player entered the jail. If the jail release
// is open, prepares the player for release.
// ============================================================================

function JailEntered() {

  ReleasePrepare();
  }


// ============================================================================
// JailLeft
//
// Automatically called when the player left the jail. Resets all arena-related
// information and scores points for the releaser if necessary.
// ============================================================================

function JailLeft(JBInfoJail JailPrev) {

  local int iInfoArena;
  local JBReplicationInfoGame InfoGame;

  if (ArenaPending != None)
    ArenaPending.MatchCancel();
  ArenaRequest = None;
  
  InfoGame = JBReplicationInfoGame(Level.GRI);

  for (iInfoArena = 0; iInfoArena < InfoGame.ListInfoArena.Length; iInfoArena++)
    InfoGame.ListInfoArena[iInfoArena].ExcludeRemove(Controller(Owner));

  if (JailPrev.GetReleaseTime(PlayerReplicationInfo.Team.TeamIndex) != TimeRelease) {
    TimeRelease = JailPrev.GetReleaseTime(PlayerReplicationInfo.Team.TeamIndex);
    Jailbreak(Level.Game).ScoreEvent(JailPrev.GetReleaseInstigator(PlayerReplicationInfo.Team.TeamIndex), 'Release');
    }
  }


// ============================================================================
// RestartPlayer
//
// Restarts the player, making sure everything is properly cleaned up before
// doing so.
// ============================================================================

private function RestartPlayer() {

  if (Controller(Owner).Pawn != None)
    Controller(Owner).Pawn.Destroy();
  
  Level.Game.RestartPlayer(Controller(Owner));
  }


// ============================================================================
// RestartFreedom
//
// Restarts this player in freedom.
// ============================================================================

function RestartFreedom() {

  Restart = Restart_Freedom;
  
  ArenaRestart = None;
  ArenaPending = None;
  ArenaRequest = None;
  
  RestartPlayer();

  Restart = Restart_Jail;
  }


// ============================================================================
// RestartJail
//
// Restarts this player in jail.
// ============================================================================

function RestartJail() {

  Restart = Restart_Jail;
  
  ArenaRestart = None;
  ArenaPending = None;
  ArenaRequest = None;
  
  RestartPlayer();
  }


// ============================================================================
// RestartArena
//
// Restarts this player in the given arena (at once, not delayed).
// ============================================================================

function RestartArena(JBInfoArena NewArenaRestart) {

  Restart = Restart_Arena;
  
  ArenaRestart = NewArenaRestart;
  ArenaPending = None;
  ArenaRequest = None;
  
  RestartPlayer();
  
  Arena = ArenaRestart;
  ArenaRestart = None;
  
  Restart = Restart_Jail;
  }


// ============================================================================
// ReleasePrepare
//
// Prepares this player for release.
// ============================================================================

function ReleasePrepare() {

  // nothing yet
  }


// ============================================================================
// SetArenaPending
//
// Sets ArenaPending if the player can actually fight in the given arena.
// ============================================================================

function SetArenaPending(JBInfoArena NewArenaPending) {

  if (NewArenaPending == None || NewArenaPending.CanFight(Controller(Owner)))
    ArenaPending = NewArenaPending;
  }


// ============================================================================
// SetArenaRequest
//
// Sets ArenaRequest and TimeArenaRequest if the player can actually fight in
// the given arena.
// ============================================================================

function SetArenaRequest(JBInfoArena NewArenaRequest) {

  if (NewArenaRequest != None) {
    if (ArenaPending != None)
      return;
    if (!NewArenaRequest.CanFight(Controller(Owner)))
      return;
    }

  ArenaRequest = NewArenaRequest;
  TimeArenaRequest = Level.TimeSeconds;
  }


// ============================================================================
// Accessors
// ============================================================================

simulated function PlayerReplicationInfo GetPlayerReplicationInfo() {
  return PlayerReplicationInfo;
  }

simulated function JBInfoArena GetArena() {
  return Arena;
  }

simulated function JBInfoArena GetArenaPending() {
  return ArenaPending;
  }

simulated function JBInfoJail GetJail() {
  return Jail;
  }

function ERestart GetRestart() {
  return Restart;
  }

function JBInfoArena GetArenaRestart() {
  return ArenaRestart;
  }

function JBInfoArena GetArenaRequest() {
  return ArenaRequest;
  }

function float GetArenaRequestTime() {
  return TimeArenaRequest;
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  Restart = Restart_Jail;
  }
