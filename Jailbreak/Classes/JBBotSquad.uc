// ============================================================================
// JBBotSquad
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBBotSquad.uc,v 1.10 2003/02/17 19:49:03 mychaeel Exp $
//
// Controls the bots of an attacking, freelancing or defending squad.
// ============================================================================


class JBBotSquad extends SquadAI
  notplaceable;


// ============================================================================
// Types
// ============================================================================

struct TInfoEnemy {

  var float TimeUpdate;         // time of last update
  var bool bIsApproaching;      // enemy was approaching objective when visible
  var bool bIsVisible;          // enemy was visible at last update
  var float DistanceObjective;  // distance of enemy to defended objective
  };


struct TInfoHunt {

  var Controller Controller;            // hunted player
  var NavigationPoint NavigationPoint;  // last known location
  };


// ============================================================================
// Variables
// ============================================================================

var private float TimeInitialized;        // time of squad initialization

var private TInfoEnemy ListInfoEnemy[8];  // indexed like Enemies array
var private TInfoHunt InfoHunt;           // information about player hunt


// ============================================================================
// Caches
// ============================================================================

struct TCacheCountEnemies { var float Time; var int Result; };

var private transient TCacheCountEnemies CacheCountEnemies;


// ============================================================================
// PostBeginPlay
//
// Records the time this squad was created at.
// ============================================================================

event PostBeginPlay() {

  TimeInitialized = Level.TimeSeconds;
  }


// ============================================================================
// Initialize
//
// Initializes this squad with the given team, objective and leader. Unlike
// its superclass counterpart, it forces bots to check their new assignments
// to prevent them from being stuck in camping mode in jail.
// ============================================================================

function Initialize(UnrealTeamInfo UnrealTeamInfo, GameObjective GameObjective, Controller ControllerLeader) {

  Team = UnrealTeamInfo;

  SetLeader(ControllerLeader);
  SetObjective(GameObjective, True);  // force reassessment
  }


// ============================================================================
// FindPathToObjective
//
// If the given objective is a JBGameObjective, finds the path to the
// associated trigger instead.
// ============================================================================

function bool FindPathToObjective(Bot Bot, Actor ActorObjective) {

  if (JBGameObjective(ActorObjective) != None)
    ActorObjective = JBGameObjective(ActorObjective).TriggerRelease;
  
  return Super.FindPathToObjective(Bot, ActorObjective);
  }


// ============================================================================
// SetEnemy
//
// Only acquires free players as new enemies.
// ============================================================================

function bool SetEnemy(Bot Bot, Pawn PawnEnemy) {

  local JBTagPlayer TagPlayerEnemy;
  
  TagPlayerEnemy = Class'JBTagPlayer'.Static.FindFor(PawnEnemy.PlayerReplicationInfo);

  if (TagPlayerEnemy == None ||
      TagPlayerEnemy.IsFree())
    return Super.SetEnemy(Bot, PawnEnemy);

  return False;
  }


// ============================================================================
// IsEnemyAcquired
//
// Checks and returns whether the given enemy player has been acquired by this
// squad.
// ============================================================================

function bool IsEnemyAcquired(Controller Controller) {

  local int iEnemy;
  
  for (iEnemy = 0; iEnemy < ArrayCount(Enemies); iEnemy++)
    if (Enemies[iEnemy] != None &&
        Enemies[iEnemy].Controller == Controller)
      return True;
  
  return False;
  }


// ============================================================================
// CountEnemies
//
// Returns the number of enemies this squad is currently engaged in fight with.
// Result is cached within a tick.
// ============================================================================

function int CountEnemies() {

  local int iEnemy;
  
  if (CacheCountEnemies.Time == Level.TimeSeconds)
    return CacheCountEnemies.Result;
  
  CacheCountEnemies.Result = 0;
  for (iEnemy = 0; iEnemy < ArrayCount(Enemies); iEnemy++)
    if (Enemies[iEnemy] != None)
      CacheCountEnemies.Result += 1;
  
  CacheCountEnemies.Time = Level.TimeSeconds;
  return CacheCountEnemies.Result;
  }


// ============================================================================
// ClearEnemies
//
// Clears the list of enemies acquired by this squad.
// ============================================================================

function ClearEnemies() {

  local int iEnemy;
  local Bot thisBot;
  
  TimeInitialized = Level.TimeSeconds;
  
  for (iEnemy = 0; iEnemy < ArrayCount(Enemies); iEnemy++)
    Enemies[iEnemy] = None;

  for (thisBot = SquadMembers; thisBot != None; thisBot = thisBot.NextSquadMember)
    thisBot.Enemy = None;
  
  ClearHunt();
  }


// ============================================================================
// GetSize
//
// Unlike its superclass counterpart, returns the actual number of human
// players and bots in this squad. Bugfix for Epic's code prior to patch two.
// ============================================================================

function int GetSize() {

  if (LeaderPRI.bBot)
    return Size;

  return Size + 1;  // plus human leader
  }


// ============================================================================
// AddBot
//
// Adds the added bot's enemy to the squad's enemies and retasks the bot. If
// the bot is currently following a scripted sequence, stops it.
// ============================================================================

function AddBot(Bot Bot) {

  Super.AddBot(Bot);

  Bot.FreeScript();
  TeamPlayerReplicationInfo(Bot.PlayerReplicationInfo).bHolding = False;

  if (Bot.Enemy != None)
    AddEnemy(Bot.Enemy);

  Retask(Bot);
  }


// ============================================================================
// RemoveBot
//
// Removes the removed bot's enemy from the squad's enemies unless another bot
// has acquired the same enemy.
// ============================================================================

function RemoveBot(Bot Bot) {

  local Bot thisBot;

  Super.RemoveBot(Bot);

  if (Bot.Enemy != None) {
    for (thisBot = SquadMembers; thisBot != None; thisBot = thisBot.NextSquadMember)
      if (thisBot.Enemy == Bot.Enemy)
        break;
    
    if (thisBot == None)
      RemoveEnemy(Bot.Enemy);
    }
  }


// ============================================================================
// AddEnemy
//
// Initializes the TInfoEnemy structure for the newly added enemy if this
// squad is ordered for an objective's defense. Also, if the acquired enemy is
// the one this squad hunted for, resets the hunting order.
// ============================================================================

function bool AddEnemy(Pawn PawnEnemy) {

  local bool bEnemyAdded;
  local int iEnemy;
  local float DistanceObjective;
  
  bEnemyAdded = Super.AddEnemy(PawnEnemy);
  
  if (bEnemyAdded) {
    if (GetOrders() == 'Defend') {
      for (iEnemy = 0; iEnemy < ArrayCount(Enemies); iEnemy++)
        if (Enemies[iEnemy] == PawnEnemy)
          break;
      
      DistanceObjective = Class'JBBotTeam'.Static.CalcDistance(PawnEnemy.Controller, SquadObjective);
      
      ListInfoEnemy[iEnemy].TimeUpdate        = Level.TimeSeconds;
      ListInfoEnemy[iEnemy].bIsApproaching    = False;
      ListInfoEnemy[iEnemy].bIsVisible        = True;
      ListInfoEnemy[iEnemy].DistanceObjective = DistanceObjective;
      }

    if (PawnEnemy.Controller == InfoHunt.Controller)
      ClearHunt();  // found him, no more hunting needed
    }

  return bEnemyAdded;
  }


// ============================================================================
// ModifyThreat
//
// For defending squads, increases the perceived threat posed through an enemy
// player approaching the defended objective and for enemies closer to the
// defended objective than the inquiring bot itself.
// ============================================================================

function float ModifyThreat(float Threat, Pawn PawnThreat, bool bThreatVisible, Bot Bot) {

  local int iEnemy;
  local float DistanceObjectiveBot;
  
  if (GetOrders() == 'Defend') {
    for (iEnemy = 0; iEnemy < ArrayCount(Enemies); iEnemy++)
      if (Enemies[iEnemy] == PawnThreat)
        break;
  
    if (ListInfoEnemy[iEnemy].bIsApproaching &&
       !ListInfoEnemy[iEnemy].bIsVisible)
      Threat += 0.3;
    
    DistanceObjectiveBot = Class'JBBotTeam'.Static.CalcDistance(Bot, SquadObjective);
    if (DistanceObjectiveBot > ListInfoEnemy[iEnemy].DistanceObjective)
      Threat += 0.1;
    }
  
  return Super.ModifyThreat(Threat, PawnThreat, bThreatVisible, Bot);
  }


// ============================================================================
// MustKeepEnemy
//
// Tells the squad to keep the given enemy by all means if the squad is on
// defense and the enemy is approaching the defended objective.
// ============================================================================

function bool MustKeepEnemy(Pawn PawnEnemy) {

  local bool bIsVisible;
  local int iEnemy;
  local float DistanceObjective;
  local Bot thisBot;

  if (GetOrders() == 'Defend') {
    for (iEnemy = 0; iEnemy < ArrayCount(Enemies); iEnemy++)
      if (Enemies[iEnemy] == PawnEnemy)
        break;

    if (ListInfoEnemy[iEnemy].TimeUpdate < Level.TimeSeconds + 0.5) {
      DistanceObjective = Class'JBBotTeam'.Static.CalcDistance(PawnEnemy.Controller, SquadObjective);

      for (thisBot = SquadMembers; thisBot != None; thisBot = thisBot.NextSquadMember)
        if (thisBot.Enemy == PawnEnemy &&
            thisBot.CanSee(PawnEnemy))
          bIsVisible = True;
  
      if (bIsVisible || ListInfoEnemy[iEnemy].bIsVisible)  // came into view, went out of view, or is in view
        ListInfoEnemy[iEnemy].bIsApproaching = (DistanceObjective <= ListInfoEnemy[iEnemy].DistanceObjective);

      ListInfoEnemy[iEnemy].TimeUpdate        = Level.TimeSeconds;
      ListInfoEnemy[iEnemy].bIsVisible        = bIsVisible;
      ListInfoEnemy[iEnemy].DistanceObjective = DistanceObjective;
      }

    if (ListInfoEnemy[iEnemy].bIsApproaching)
      return True;
    }

  return Super.MustKeepEnemy(PawnEnemy);
  }


// ============================================================================
// CheckSquadObjectives
//
// If this squad is on a hunt, directs the leader to the hunting target or
// aborts the hunt if the leader has already reached it.
// ============================================================================

function bool CheckSquadObjectives(Bot Bot) {

  if (Bot.Pawn == None)
    return False;

  if (Super.CheckSquadObjectives(Bot))
    return True;
  
  if (InfoHunt.NavigationPoint != None && Bot == SquadLeader)
    if (Bot.Pawn.ReachedDestination(InfoHunt.NavigationPoint))
      ClearHunt();
    else
      return FindPathToObjective(Bot, InfoHunt.NavigationPoint);
  
  return False;
  }


// ============================================================================
// Hunt
//
// Sends this squad on a hunt for the given player who was last seen at the
// given location. The hunt ends when the player is found or killed. Returns
// whether the hunt could be started.
// ============================================================================

function bool Hunt(Controller Controller, NavigationPoint NavigationPoint) {

  if (Bot(SquadLeader) == None)
    return False;

  InfoHunt.Controller      = Controller;
  InfoHunt.NavigationPoint = NavigationPoint;
  
  return CheckSquadObjectives(Bot(SquadLeader));
  }


// ============================================================================
// CanHunt
//
// Checks and returns whether this squad is currently fit to hunt an enemy
// player.
// ============================================================================

function bool CanHunt() {

  return (TimeInitialized < Level.TimeSeconds - 0.5 &&
          Bot(SquadLeader) != None &&
          GetOrders() == 'Freelance' &&
          CountEnemies() == 0);
  }


// ============================================================================
// CanHuntBetterThan
//
// Checks and returns whether this squad is currently more fit to hunt the
// given enemy than the given squad.
// ============================================================================

function bool CanHuntBetterThan(JBBotSquad Squad, Controller Controller) {

  if (Squad == None)
    return True;

  return (Squad.InfoHunt.Controller != None &&
          Squad.InfoHunt.Controller != Controller &&
          (InfoHunt.Controller == None ||
           InfoHunt.Controller == Controller));
  }


// ============================================================================
// IsHunting
//
// Checks and returns whether this squad is currently hunting the given player
// or any player at all if none is specified.
// ============================================================================

function bool IsHunting(optional Controller Controller) {

  if (Controller == None)
    return (InfoHunt.Controller != None);
  else
    return (InfoHunt.Controller == Controller);
  }


// ============================================================================
// ClearHunt
//
// Stops an ongoing hunt.
// ============================================================================

function ClearHunt() {

  InfoHunt.Controller      = None;
  InfoHunt.NavigationPoint = None;
  
  if (Bot(SquadLeader) != None)
    CheckSquadObjectives(Bot(SquadLeader));
  }


// ============================================================================
// NotifyKilled
//
// If the killed player is the one this squad hunted for, ends the hunt.
// ============================================================================

function NotifyKilled(Controller ControllerKiller, Controller ControllerVictim, Pawn PawnVictim) {

  if (ControllerVictim == InfoHunt.Controller)
    ClearHunt();

  Super.NotifyKilled(ControllerKiller, ControllerVictim, PawnVictim);
  }
