// ============================================================================
// JBBotSquad
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBBotSquad.uc,v 1.2 2002/12/22 02:06:13 mychaeel Exp $
//
// Controls the bots of an attacking, freelancing or defending squad.
// ============================================================================


class JBBotSquad extends SquadAI
  notplaceable;


// ============================================================================
// Types
// ============================================================================

struct TInfoEnemy {

  var float TimeUpdate;             // time of last info update
  var bool bIsApproaching;          // enemy is approaching the objective
  var bool bIsVisible;              // enemy was visible at last update
  var float DistanceObjective;      // distance of enemy to defended objective
  };


// ============================================================================
// Variables
// ============================================================================

var transient int nPlayersRemove;  // used by DeployExecute in JBBotTeam

var private TInfoEnemy ListInfoEnemy[8];  // indexed after the Enemies array

var transient float TimeCacheCountEnemies;
var transient int CacheCountEnemies;


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
  
  if (TimeCacheCountEnemies == Level.TimeSeconds)
    return CacheCountEnemies;
  
  CacheCountEnemies = 0;
  for (iEnemy = 0; iEnemy < ArrayCount(Enemies); iEnemy++)
    if (Enemies[iEnemy] != None)
      CacheCountEnemies++;
  
  TimeCacheCountEnemies = Level.TimeSeconds;
  return CacheCountEnemies;
  }


// ============================================================================
// GetSize
//
// Unlike its superclass counterpart, returns the actual number of human
// players and bots in this squad. Bugfix for Epic's code.
// ============================================================================

function int GetSize() {

  if (LeaderPRI.bBot)
    return Size;

  return Size + 1;  // plus human leader
  }


// ============================================================================
// AddBot
//
// Adds the added bot's enemy to the squad's enemies and retasks the bot.
// ============================================================================

function AddBot(Bot Bot) {

  Super.AddBot(Bot);

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
// squad is ordered for an objective's defense.
// ============================================================================

function bool AddEnemy(Pawn PawnEnemy) {

  local bool bEnemyAdded;
  local int iEnemy;
  local float DistanceObjective;
  
  bEnemyAdded = Super.AddEnemy(PawnEnemy);
  
  if (bEnemyAdded && GetOrders() == 'Defend') {
    for (iEnemy = 0; iEnemy < ArrayCount(Enemies); iEnemy++)
      if (Enemies[iEnemy] == PawnEnemy)
        break;
    
    DistanceObjective = Class'JBBotTeam'.Static.CalcDistance(PawnEnemy.Controller, SquadObjective);
    
    ListInfoEnemy[iEnemy].TimeUpdate        = Level.TimeSeconds;
    ListInfoEnemy[iEnemy].bIsApproaching    = False;
    ListInfoEnemy[iEnemy].bIsVisible        = True;
    ListInfoEnemy[iEnemy].DistanceObjective = DistanceObjective;
    }

  return bEnemyAdded;
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
