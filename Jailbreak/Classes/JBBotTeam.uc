// ============================================================================
// JBBotTeam
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBBotTeam.uc,v 1.7 2003/01/02 16:42:58 mychaeel Exp $
//
// Controls the bots of one team.
// ============================================================================


class JBBotTeam extends TeamAI
  notplaceable;


// ============================================================================
// Types
// ============================================================================

struct TDeployment {

  var int nPlayersOrdered;
  var int nPlayersCurrent;
  var GameObjective Objective;
  };


// ============================================================================
// Variables
// ============================================================================

var class<JBBotSquadArena> ClassSquadArena;
var class<JBBotSquadJail>  ClassSquadJail;

var private int nObjectives;  // counted once by CountObjectives

var private transient array<TDeployment> ListDeployment;

var private transient float TimeCacheCountEnemiesAccounted;
var private transient float TimeCacheCountEnemiesUnaccounted;
var private transient float TimeCacheRatePlayers;

var private transient int CacheCountEnemiesAccounted;
var private transient int CacheCountEnemiesUnaccounted;
var private transient float CacheRatePlayers;


// ============================================================================
// Timer
//
// Calls ReAssessStrategy and ReAssessOrders and sets a new timer with a small
// random time offset to prevent the reassessments from happening for both
// teams always at the same time.
// ============================================================================

event Timer() {

  ReAssessStrategy();
  ReAssessOrders();
  
  SetTimer(4.0 + FRand() * 2.0, False);
  }


// ============================================================================
// SetObjectiveLists
//
// For all GameObjective actors that don't have a JBTagObjective actor yet,
// spawns one. For every trigger directly connected to a jail, spawns a
// JBGameObjective actor and sets it up for this team.
// ============================================================================

function SetObjectiveLists() {

  local GameObjective thisObjective;
  local JBGameObjective Objective;
  local JBInfoJail thisJail;
  local Trigger thisTrigger;

  foreach AllActors(Class'GameObjective', thisObjective)
    Class'JBTagObjective'.Static.SpawnFor(thisObjective);

  foreach DynamicActors(Class'Trigger', thisTrigger) {
    foreach DynamicActors(Class'JBInfoJail', thisJail)
      if (thisJail.Tag == thisTrigger.Event &&
          thisJail.CanRelease(Team))
        break;
    
    if (thisJail == None)
      continue;

    Objective = Spawn(Class'JBGameObjective', , , thisTrigger.Location);
    Objective.TriggerRelease = thisTrigger;
    Objective.DefenderTeamIndex = EnemyTeam.TeamIndex;
    Objective.StartTeam = EnemyTeam.TeamIndex;
    Objective.Event = thisJail.Tag;
    Objective.FindDefenseScripts(thisTrigger.Tag);
    }

  Super.SetObjectiveLists();
  }


// ============================================================================
// PutOnFreelance
//
// Puts the given bot on the first freelance squad found that can still take
// new players. Creates a new freelance squad if none is found.
// ============================================================================

function PutOnFreelance(Bot Bot) {

  local SquadAI SquadFreelance;
  
  for (SquadFreelance = Squads; SquadFreelance != None; SquadFreelance = SquadFreelance.NextSquad)
    if (SquadFreelance.bFreelance &&
        SquadFreelance.MaxSquadSize > SquadFreelance.GetSize())
      break;
  
  if (SquadFreelance == None)
    Super.PutOnFreelance(Bot);
  else
    SquadFreelance.AddBot(Bot);
  }


// ============================================================================
// PutOnSquad
//
// Puts the given bot on the squad attacking or defending the given objective.
// ============================================================================

function PutOnSquad(Bot Bot, GameObjective GameObjective) {

  if (IsObjectiveAttack(GameObjective)) {
    if (AttackSquad == None)
      AttackSquad = AddSquadWithLeader(Bot, GameObjective);
    else
      AttackSquad.AddBot(Bot);
    }
  
  else if (IsObjectiveDefense(GameObjective)) {
    if (GameObjective.DefenseSquad == None)
      GameObjective.DefenseSquad = AddSquadWithLeader(Bot, GameObjective);
    else
      GameObjective.DefenseSquad.AddBot(Bot);
    }
  
  else {
    Log("Warning: Cannot order bot" @ Bot.PlayerReplicationInfo.PlayerName @
        "to attack or defend objective" @ GameObjective);
    PutOnFreelance(Bot);
    }
  }


// ============================================================================
// PutOnSquadArena
//
// Creates an arena squad for the given bot and adds the bot to it.
// ============================================================================

function PutOnSquadArena(Bot Bot) {

  local JBBotSquadArena SquadArena;

  SquadArena = Spawn(ClassSquadArena);
  SquadArena.AddBot(Bot);
  }


// ============================================================================
// PutOnSquadJail
//
// Creates a jail squad for the given bot and adds the bot to it.
// ============================================================================

function PutOnSquadJail(Bot Bot) {

  local JBBotSquadJail SquadJail;

  SquadJail = Spawn(ClassSquadJail);
  SquadJail.AddBot(Bot);
  }


// ============================================================================
// IsObjectiveAttack
//
// Returns whether the given objective is to be attacked by this team.
// ============================================================================

function bool IsObjectiveAttack(GameObjective GameObjective) {

  return (GameObjective != None &&
          GameObjective.DefenderTeamIndex != Team.TeamIndex);
  }


// ============================================================================
// IsObjectiveDefense
//
// Returns whether the given objective is to be defended by this team.
// ============================================================================

function bool IsObjectiveDefense(GameObjective GameObjective) {

  return (GameObjective != None &&
          GameObjective.DefenderTeamIndex == Team.TeamIndex);
  }


// ============================================================================
// CountObjectives
//
// Returns the number of objectives.
// ============================================================================

function int CountObjectives() {

  local GameObjective thisObjective;

  if (nObjectives == 0)
    for (thisObjective = Objectives; thisObjective != None; thisObjective = thisObjective.NextObjective)
      nObjectives++;
  
  return nObjectives;
  }


// ============================================================================
// CountPlayersAtObjective
//
// Returns the number of players attacking or defending the given objective.
// Takes human players into consideration.
// ============================================================================

function int CountPlayersAtObjective(GameObjective GameObjective) {

  local int nPlayersAtObjective;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  local SquadAI thisSquad;

  firstTagPlayer = JBReplicationInfoGame(Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    if (PlayerController(thisTagPlayer.GetController()) != None &&
        thisTagPlayer.IsFree() &&
        thisTagPlayer.GetTeam() == Team &&
        thisTagPlayer.GuessObjective() == GameObjective)
      nPlayersAtObjective++;

  for (thisSquad = Squads; thisSquad != None; thisSquad = thisSquad.NextSquad)
    if (thisSquad.SquadObjective == GameObjective)
      nPlayersAtObjective += thisSquad.GetSize();

  return nPlayersAtObjective;
  }


// ============================================================================
// CountPlayersReleasable
//
// Returns the number of players of this team that could be released by
// attacking the given objective. Works for both teams.
// ============================================================================

function int CountPlayersReleasable(GameObjective GameObjective) {

  local JBTagObjective TagObjective;

  TagObjective = Class'JBTagObjective'.Static.FindFor(GameObjective);
  if (TagObjective != None)
    return TagObjective.CountPlayersReleasable();
  
  return 0;
  }


// ============================================================================
// CalcDistance
//
// Calculates the traveling distance of the given player or bot to the given
// objective. Expensive, so use sparingly.
// ============================================================================

static function float CalcDistance(Controller Controller, GameObjective GameObjective) {

  local Actor ActorTarget;

  if (Controller.Pawn == None)
    return 0.0;  // no pathfinding without pawn

  if (JBGameObjective(GameObjective) == None)
    ActorTarget = GameObjective;
  else
    ActorTarget = JBGameObjective(GameObjective).TriggerRelease;
  
  if (Controller.FindPathToward(ActorTarget) == None)
    return VSize(ActorTarget.Location - Controller.Pawn.Location);
  
  return Controller.RouteDist;
  }


// ============================================================================
// CalcEfficiency
//
// Calculates the efficiency of a player or team with the given number of
// kills and deaths.
// ============================================================================

static function float CalcEfficiency(int nKills, int nDeaths) {

  if (nKills + nDeaths == 0)
    return 0.5;  // average efficiency
  
  return nKills / (nKills + nDeaths);
  }


// ============================================================================
// RatePlayers
//
// Rates the effectivity of all free players on this team compared to free
// players on the enemy team. Results are cached within a tick.
// ============================================================================

function float RatePlayers() {

  local int nDeathsByTeam[2];
  local int nKillsByTeam[2];
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  local PlayerReplicationInfo PlayerReplicationInfo;

  if (TimeCacheRatePlayers == Level.TimeSeconds)
    return CacheRatePlayers;
  
  firstTagPlayer = JBReplicationInfoGame(Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    if (thisTagPlayer.IsFree()) {
      PlayerReplicationInfo = thisTagPlayer.GetPlayerReplicationInfo();
      nKillsByTeam [PlayerReplicationInfo.Team.TeamIndex] += PlayerReplicationInfo.Kills;
      nDeathsByTeam[PlayerReplicationInfo.Team.TeamIndex] += PlayerReplicationInfo.Deaths;
      }

  CacheRatePlayers = CalcEfficiency(nKillsByTeam[     Team.TeamIndex], nDeathsByTeam[     Team.TeamIndex]) /
                     CalcEfficiency(nKillsByTeam[EnemyTeam.TeamIndex], nDeathsByTeam[EnemyTeam.TeamIndex]);
  
  TimeCacheRatePlayers = Level.TimeSeconds;
  return CacheRatePlayers;
  }


// ============================================================================
// IsEnemyAcquired
//
// Checks and returns whether the given enemy player has been acquired by a
// squad of this team.
// ============================================================================

function bool IsEnemyAcquired(Controller Controller) {

  local SquadAI thisSquad;

  for (thisSquad = Squads; thisSquad != None; thisSquad = thisSquad.NextSquad)
    if (JBBotSquad(thisSquad) != None &&
        JBBotSquad(thisSquad).IsEnemyAcquired(Controller))
      return True;
  
  return False;
  }


// ============================================================================
// IsEnemyAcquiredAtObjective
//
// Checks and returns whether the given enemy player has been acquired by a
// squad of this team defending or attacking the given objective.
// ============================================================================

function bool IsEnemyAcquiredAtObjective(Controller Controller, GameObjective GameObjective) {

  local SquadAI thisSquad;

  for (thisSquad = Squads; thisSquad != None; thisSquad = thisSquad.NextSquad)
    if (thisSquad.SquadObjective == GameObjective &&
        JBBotSquad(thisSquad) != None &&
        JBBotSquad(thisSquad).IsEnemyAcquired(Controller))
      return True;
  
  return False;
  }


// ============================================================================
// CountEnemiesFree
//
// Returns the total number of free enemies.
// ============================================================================

function int CountEnemiesFree() {

  return JBReplicationInfoTeam(EnemyTeam).CountPlayersFree();
  }


// ============================================================================
// CountEnemiesAccounted
//
// Returns the number of free enemies that are currently engaged in a fight
// with players of this team; in short, enemies whose objective is known.
// Results are cached within a tick.
// ============================================================================

function int CountEnemiesAccounted() {

  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;

  if (TimeCacheCountEnemiesAccounted == Level.TimeSeconds)
    return CacheCountEnemiesAccounted;

  CacheCountEnemiesAccounted = 0;

  firstTagPlayer = JBReplicationInfoGame(Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    if (thisTagPlayer.IsFree() && IsEnemyAcquired(thisTagPlayer.GetController()))
      CacheCountEnemiesAccounted++;
  
  TimeCacheCountEnemiesAccounted = Level.TimeSeconds;
  return CacheCountEnemiesAccounted;
  }


// ============================================================================
// CountEnemiesUnaccounted
//
// Returns the number of free enemies whose objective currently isn't known.
// Results are cached within a tick.
// ============================================================================

function int CountEnemiesUnaccounted() {

  if (TimeCacheCountEnemiesUnaccounted == Level.TimeSeconds)
    return CacheCountEnemiesUnaccounted;
  
  CacheCountEnemiesUnaccounted = CountEnemiesFree() - CountEnemiesAccounted();
  
  TimeCacheCountEnemiesUnaccounted = Level.TimeSeconds;
  return CacheCountEnemiesUnaccounted;
  }


// ============================================================================
// EstimateStrengthAttack
//
// Estimates the number of players the enemy team will attack the given
// objective with.
// ============================================================================

function int EstimateStrengthAttack(GameObjective GameObjective) {

  local bool bEnemiesReleasable;
  local int nEnemiesAttacking;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  
  bEnemiesReleasable = CountPlayersReleasable(GameObjective) > 0;
  if (bEnemiesReleasable)
    nEnemiesAttacking += CountEnemiesUnaccounted();  // worst case
  
  firstTagPlayer = JBReplicationInfoGame(Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    if (thisTagPlayer.IsFree() &&
        (IsEnemyAcquiredAtObjective(thisTagPlayer.GetController(), GameObjective) ||
         (bEnemiesReleasable && IsEnemyAcquiredAtObjective(thisTagPlayer.GetController(), None))))
      nEnemiesAttacking++;
  
  return nEnemiesAttacking;
  }


// ============================================================================
// EstimateStrengthDefense
//
// Estimates the number of players the enemy team will defend the given
// objective with.
// ============================================================================

function int EstimateStrengthDefense(GameObjective GameObjective) {

  local int nEnemiesDefending;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  
  firstTagPlayer = JBReplicationInfoGame(Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    if (thisTagPlayer.IsFree() &&
        IsEnemyAcquiredAtObjective(thisTagPlayer.GetController(), GameObjective))
      nEnemiesDefending++;
  
  if (CountPlayersReleasable(GameObjective) > 0)
    nEnemiesDefending += CountEnemiesUnaccounted();  // worst case
  
  return nEnemiesDefending;
  }


// ============================================================================
// SuggestStrengthAttack
//
// Returns the number of players that should ideally be attacking the given
// objective. Excess players may be drawn off to other objectives.
// ============================================================================

function int SuggestStrengthAttack(GameObjective GameObjective) {

  local int nPlayersDefending;

  if (GameObjective == None ||
      GameObjective.bDisabled)
    return 0;

  nPlayersDefending = EstimateStrengthDefense(GameObjective);
  if (CountPlayersReleasable(GameObjective) > 0)
    return Max(nPlayersDefending / FClamp(RatePlayers(), 1.0, 2.0) + 0.9, 1);

  return 0;
  }


// ============================================================================
// SuggestStrengthDefense
//
// Returns the number of players that should ideally be defending the given
// objective. Excess players may be drawn off to other objectives.
// ============================================================================

function int SuggestStrengthDefense(GameObjective GameObjective) {

  local int nPlayersAttacking;

  nPlayersAttacking = EstimateStrengthAttack(GameObjective);
  if (nPlayersAttacking > 0)
    return Max(nPlayersAttacking / FClamp(RatePlayers(), 1.0, 2.0) + 0.9, 1);
  
  return 0;
  }


// ============================================================================
// ReAssessStrategy
//
// Periodically checks whether the current situation warrants a change in team
// tactics and, if so, changes the tactics and reorders bots.
// ============================================================================

function ReAssessStrategy() {

  // TODO: implement
  }


// ============================================================================
// ReAssessOrders
//
// Checks every bot's orders and changes them if necessary to accommodate the
// currently selected team tactics. Dummy implementation here which only
// issues a warning to the log; actual implementations in Tactics states.
// ============================================================================

function ReAssessOrders() {

  Log("Warning: ReAssessOrders for team" @ Team.TeamIndex @ "should not be called in default state");
  }


// ============================================================================
// SetBotOrders
//
// Called for bots that just entered the game or were released from jail. The
// default implementation should never be called, but for crash-safety's sake
// puts them on the freelance squad and issues a warning to the log.
// ============================================================================

function SetBotOrders(Bot Bot, RosterEntry RosterEntry) {

  Log("Warning: SetBotOrders called for" @ Bot.PlayerReplicationInfo.PlayerName @
      "in team" @ Bot.PlayerReplicationInfo.Team.TeamIndex @ "outside any Tactics state");

  PutOnFreelance(Bot);
  }


// ============================================================================
// DeployPlayers
//
// Records a deployment order for a given objective and number of players.
// Multiple deployment orders on the same objective are accumulative. Call
// DeployExecute after all deployments have been recorded to commit the orders.
// ============================================================================

function DeployPlayers(GameObjective GameObjective, int nPlayersDeploy) {

  local int iDeployment;

  if (nPlayersDeploy == 0)
    return;
  
  for (iDeployment = 0; iDeployment < ListDeployment.Length; iDeployment++)
    if (ListDeployment[iDeployment].Objective == GameObjective)
      break;

  if (iDeployment == ListDeployment.Length)
    ListDeployment.Insert(iDeployment, 1);

  ListDeployment[iDeployment].Objective = GameObjective;
  ListDeployment[iDeployment].nPlayersOrdered += nPlayersDeploy;
  }


// ============================================================================
// DeployPlayersDefense
//
// Distributes the given number of players on all objectives that need to be
// defended and issues corresponding deployment orders.
// ============================================================================

function DeployPlayersDefense(int nPlayersDeploy) {

  local int iDeployment;
  local int nPlayersSuggested;
  local float RatioPlayers;
  local float RatioPlayersWeakest;
  local GameObjective thisObjective;
  local GameObjective ObjectiveWeakest;
  
  while (nPlayersDeploy > 0) {
    ObjectiveWeakest = None;
    
    for (thisObjective = Objectives; thisObjective != None; thisObjective = thisObjective.NextObjective)
      if (IsObjectiveDefense(thisObjective)) {
        nPlayersSuggested = SuggestStrengthDefense(thisObjective);
        if (nPlayersSuggested == 0)
          continue;

        for (iDeployment = 0; iDeployment < ListDeployment.Length; iDeployment++)
          if (ListDeployment[iDeployment].Objective == thisObjective)
            break;
        
        if (iDeployment < ListDeployment.Length)
          RatioPlayers = ListDeployment[iDeployment].nPlayersOrdered / nPlayersSuggested;
        else
          RatioPlayers = 0.0;

        if (ObjectiveWeakest == None || RatioPlayers < RatioPlayersWeakest) {
          ObjectiveWeakest = thisObjective;
          RatioPlayersWeakest = RatioPlayers;
          }
        }

    if (ObjectiveWeakest == None) {
      Log("Warning:" @ nPlayersDeploy @ "player(s) on team" @ Team.TeamIndex @ "left to deploy for defense," @
          "but no objectives found that need to be defended.");
      break;
      }

    nPlayersDeploy--;
    DeployPlayers(ObjectiveWeakest, 1);
    }
  }


// ============================================================================
// DeployExecute
//
// Deploys bots to objectives as previously recorded by calling DeployPlayers.
// Players left without deployment are put on the freelance squad. After that,
// resets all orders.
// ============================================================================

function DeployExecute() {

  local int iDeployment;
  local int iDeploymentNearest;
  local float Distance;
  local float DistanceNearest;
  local Bot BotNearest;
  local SquadAI thisSquad;
  local Controller thisController;

  for (thisSquad = Squads; thisSquad != None; thisSquad = thisSquad.NextSquad)
    if (JBBotSquad(thisSquad) != None) {
      for (iDeployment = 0; iDeployment < ListDeployment.Length; iDeployment++)
        if (ListDeployment[iDeployment].Objective == thisSquad.SquadObjective)
          break;
      
      if (iDeployment == ListDeployment.Length)
        JBBotSquad(thisSquad).nPlayersRemove = thisSquad.GetSize();
      else
        JBBotSquad(thisSquad).nPlayersRemove =
          Max(0, CountPlayersAtObjective(thisSquad.SquadObjective) - ListDeployment[iDeployment].nPlayersOrdered);
      }

  for (iDeployment = ListDeployment.Length - 1; iDeployment >= 0; iDeployment--) {
    ListDeployment[iDeployment].nPlayersCurrent = CountPlayersAtObjective(ListDeployment[iDeployment].Objective);
    if (ListDeployment[iDeployment].nPlayersCurrent >=
        ListDeployment[iDeployment].nPlayersOrdered)
      ListDeployment.Remove(iDeployment, 1);
    }

  while (True) {
    BotNearest = None;
  
    for (thisController = Level.ControllerList; thisController != None; thisController = thisController.NextController)
      if (Bot(thisController) != None &&
          thisController.PlayerReplicationInfo != None &&
          thisController.PlayerReplicationInfo.Team == Team &&
          JBBotSquad(Bot(thisController).Squad) != None &&
          JBBotSquad(Bot(thisController).Squad).nPlayersRemove > 0)

        for (iDeployment = 0; iDeployment < ListDeployment.Length; iDeployment++) {
          Distance = CalcDistance(thisController, ListDeployment[iDeployment].Objective);
          if (BotNearest == None || Distance < DistanceNearest) {
            BotNearest = Bot(thisController);
            DistanceNearest = Distance;
            iDeploymentNearest = iDeployment;
            }
          }

    if (BotNearest == None)
      break;

    JBBotSquad(BotNearest.Squad).nPlayersRemove--;
    PutOnSquad(BotNearest, ListDeployment[iDeploymentNearest].Objective);

    ListDeployment[iDeploymentNearest].nPlayersCurrent++;
    if (ListDeployment[iDeploymentNearest].nPlayersCurrent >=
        ListDeployment[iDeploymentNearest].nPlayersOrdered)
      ListDeployment.Remove(iDeploymentNearest, 1);
    }

  for (thisSquad = Squads; thisSquad != None; thisSquad = thisSquad.NextSquad)
    if (JBBotSquad(thisSquad) != None && thisSquad.bFreelance)
      JBBotSquad(thisSquad).nPlayersRemove = 0;

  for (thisController = Level.ControllerList; thisController != None; thisController = thisController.NextController)
    if (Bot(thisController) != None &&
        thisController.PlayerReplicationInfo != None &&
        thisController.PlayerReplicationInfo.Team == Team &&
        JBBotSquad(Bot(thisController).Squad) != None &&
        JBBotSquad(Bot(thisController).Squad).nPlayersRemove > 0)
      PutOnFreelance(Bot(thisController));

  ListDeployment.Length = 0;
  }


// ============================================================================
// GetPriorityFreelanceObjective
//
// Always returns None. The freelance squad in Jailbreak is always to roam the
// map more or less randomly. If a directed attack is required, bots are
// redistributed to different squads.
// ============================================================================

function GameObjective GetPriorityFreelanceObjective() {

  return None;
  }


// ============================================================================
// state TacticsNormal
//
// Normal team tactics. Bots try to defend their bases and attack enemies in
// order to kill them and to release their teammates. Nothing fancy here.
// ============================================================================

auto state TacticsNormal {

  // ================================================================
  // SetBotOrders
  //
  // Finds the objective that needs more players most urgently and
  // assigns the new bot to that objective's squad.
  // ================================================================

  function SetBotOrders(Bot Bot, RosterEntry RosterEntry) {

    local GameObjective thisObjective;
    local GameObjective ObjectiveWeakest;
    local int nPlayersNeeded;
    local int nPlayersNeededWeakest;

    for (thisObjective = Objectives; thisObjective != None; thisObjective = thisObjective.NextObjective) {
      if (IsObjectiveAttack(thisObjective))
        nPlayersNeeded = SuggestStrengthAttack(thisObjective) - CountPlayersAtObjective(thisObjective);
      else if (IsObjectiveDefense(thisObjective))
        nPlayersNeeded = SuggestStrengthDefense(thisObjective) - CountPlayersAtObjective(thisObjective);
      else
        continue;
      
      if (ObjectiveWeakest == None || nPlayersNeeded > nPlayersNeededWeakest) {
        ObjectiveWeakest = thisObjective;
        nPlayersNeededWeakest = nPlayersNeeded;
        }
      }

    if (nPlayersNeededWeakest > 0)
      PutOnSquad(Bot, ObjectiveWeakest);
    else
      PutOnFreelance(Bot);
    }
  

  // ================================================================
  // GetPriorityAttackObjective
  //
  // Finds the objective that should be attacked. Selects the
  // objective where most players can be released with the least
  // required amount of attacking players.
  // ================================================================

  function GameObjective GetPriorityAttackObjective() {

    local int nPlayersReleasable;
    local int nPlayersReleasableMax;
    local int nPlayersAttacking;
    local int nPlayersAttackingMin;
    local GameObjective thisObjective;
    local GameObjective ObjectiveAttack;
    
    for (thisObjective = Objectives; thisObjective != None; thisObjective = thisObjective.NextObjective)
      if (IsObjectiveAttack(thisObjective)) {
        nPlayersAttacking = SuggestStrengthAttack(thisObjective);
        if (nPlayersAttacking == 0)
          continue;

        if (ObjectiveAttack == None || nPlayersAttacking < nPlayersAttackingMin) {
          nPlayersReleasable = CountPlayersReleasable(thisObjective);
          if (ObjectiveAttack == None || nPlayersReleasable > nPlayersReleasableMax) {
            nPlayersAttackingMin  = nPlayersAttacking;
            nPlayersReleasableMax = nPlayersReleasable;
            ObjectiveAttack = thisObjective;
            }
          }
        }
    
    return ObjectiveAttack;
    }


  // ================================================================
  // ReAssessOrders
  //
  // Tries to release players while keeping at least minimum
  // defenses up, but abandons defenses if otherwise attack would
  // be unlikely to succeed. Appoints a freelance squad if nothing
  // must be attacked.
  // ================================================================

  function ReAssessOrders() {

    local int nPlayersFree;
    local int nPlayersJailed;
    local int nPlayersAttacking;
    local int nPlayersDefending;
    local int nPlayersDefendingMin;
    local int nPlayersDefendingMax;
    local int nPlayersReleasable;
    local int nPlayersReleasableMax;
    local int nPlayersRequired;
    local GameObjective thisObjective;
    local GameObjective ObjectiveAttack;
    local GameObjective ObjectiveDefense;

    nPlayersFree   = JBReplicationInfoTeam(Team).CountPlayersFree();
    nPlayersJailed = JBReplicationInfoTeam(Team).CountPlayersJailed();

    for (thisObjective = Objectives; thisObjective != None; thisObjective = thisObjective.NextObjective)
      if (IsObjectiveDefense(thisObjective)) {
        nPlayersDefending = SuggestStrengthDefense(thisObjective);
        nPlayersDefendingMax += nPlayersDefending;
        if (nPlayersDefendingMin == 0 ||
            nPlayersDefendingMin > nPlayersDefending)
          nPlayersDefendingMin = nPlayersDefending;
        }

    if (nPlayersJailed > 0) {
      ObjectiveAttack = GetPriorityAttackObjective();
      nPlayersAttacking = SuggestStrengthAttack(ObjectiveAttack);
      }

    nPlayersRequired = nPlayersAttacking + nPlayersDefendingMin;

    if (nPlayersRequired > nPlayersFree && nPlayersAttacking > 0) {
      nPlayersDefending = Max(0, nPlayersFree - Abs(nPlayersDefendingMin - nPlayersAttacking) / 2.0 - 0.5);
      if (nPlayersDefending <= nPlayersDefendingMin / 2)
        nPlayersDefending = 0;  // no use defending
      nPlayersAttacking = Max(0, nPlayersFree - nPlayersDefending);
      
      for (thisObjective = Objectives; thisObjective != None; thisObjective = thisObjective.NextObjective)
        if (IsObjectiveDefense(thisObjective)) {
          nPlayersReleasable = CountPlayersReleasable(thisObjective);
          if (nPlayersReleasable > nPlayersReleasableMax &&
              nPlayersDefendingMin >= SuggestStrengthDefense(thisObjective)) {
            ObjectiveDefense = thisObjective;
            nPlayersReleasableMax = nPlayersReleasable;
            }
          }

      DeployPlayers(ObjectiveAttack,  nPlayersAttacking);
      DeployPlayers(ObjectiveDefense, nPlayersDefending);
      DeployExecute();
      }
    
    else {
      nPlayersDefending = Min(nPlayersFree - nPlayersAttacking, nPlayersDefendingMax);

      if (nPlayersAttacking > 0)
        nPlayersAttacking = nPlayersFree - nPlayersDefending;  // attack with full force

      DeployPlayers(ObjectiveAttack, nPlayersAttacking);
      DeployPlayersDefense(nPlayersDefending);
      DeployExecute();  // rest goes on freelance
      }
    }

  } // state TacticsNormal


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  ClassSquadArena = Class'JBBotSquadArena';
  ClassSquadJail  = Class'JBBotSquadJail';

  SquadType = Class'JBBotSquad';
  }