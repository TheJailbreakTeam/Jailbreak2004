// ============================================================================
// JBBotSquad
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBBotSquad.uc,v 1.1 2002/12/20 20:54:30 mychaeel Exp $
//
// Controls the bots of an attacking, freelancing or defending squad.
// ============================================================================


class JBBotSquad extends SquadAI
  notplaceable;


// ============================================================================
// Variables
// ============================================================================

var transient int nPlayersRemove;  // used by DeployExecute in JBBotTeam

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
// Retasks bots added to this squad.
// ============================================================================

function AddBot(Bot Bot) {

  Super.AddBot(Bot);
  Retask(Bot);
  }
