// ============================================================================
// JBBotTeam
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBBotTeam.uc,v 1.8 2003/01/03 22:35:28 mychaeel Exp $
//
// Controls the bots of one team.
// ============================================================================


class JBBotTeam extends TeamAI
  notplaceable;


// ============================================================================
// Variables
// ============================================================================

var class<JBBotSquadArena> ClassSquadArena;
var class<JBBotSquadJail>  ClassSquadJail;

var private bool bTacticsAuto;  // team tactics selected automatically

var private int nObjectives;  // counted once by CountObjectives

var private transient float TimeDeployment;  // time of last deployment order

var private transient float TimeCacheCountEnemiesAccounted;
var private transient float TimeCacheCountEnemiesUnaccounted;
var private transient float TimeCacheRatePlayers;

var private transient int CacheCountEnemiesAccounted;
var private transient int CacheCountEnemiesUnaccounted;
var private transient float CacheRatePlayers;


// ============================================================================
// SetTactics
//
// Sets the current team tactics for this team and returns the selected
// tactics. The following input values are supported:
//
//   Auto             Enables auto-selection of team tactics.
//
//   MoreAggressive   Modify the currently selected team tactics into the
//   MoreDefensive    given direction. Disable auto-selection if enabled.
//
//   Evasive          Set the team tactics to the given value. Disable auto-
//   Defensive        selection if enabled.
//   Normal
//   Aggressive
//   Suicidal
//   
// ============================================================================

function name SetTactics(name Tactics) {

  bTacticsAuto = False;

  switch (Tactics) {
    case 'Auto':
      ReAssessStrategy();
      bTacticsAuto = True;
      break;

    case 'MoreAggressive':
      switch (GetTactics()) {
        case 'Evasive':     return SetTactics('Defensive');
        case 'Defensive':   return SetTactics('Normal');
        case 'Normal':      return SetTactics('Aggressive');
        case 'Aggressive':  return SetTactics('Suicidal');
        }
      break;

    case 'MoreDefensive':
      switch (GetTactics()) {
        case 'Defensive':   return SetTactics('Evasive');
        case 'Normal':      return SetTactics('Defensive');
        case 'Aggressive':  return SetTactics('Normal');
        case 'Suicidal':    return SetTactics('Aggressive');
        }
      break;

    case 'Evasive':     GotoState('TacticsEvasive');     break;
    case 'Defensive':   GotoState('TacticsDefensive');   break;
    case 'Normal':      GotoState('TacticsNormal');      break;
    case 'Aggressive':  GotoState('TacticsAggressive');  break;
    case 'Suicidal':    GotoState('TacticsSuicidal');    break;
    
    default:
      Log("Warning: Invalid tactics" @ Tactics @ "selected for team" @ Team.TeamIndex);
    }

  return GetTactics();
  }


// ============================================================================
// GetTactics
//
// Returns the name of the currently selected team tactics.
// ============================================================================

function name GetTactics() {

  switch (GetStateName()) {
    case 'TacticsEvasive':     return 'Evasive';
    case 'TacticsDefensive':   return 'Defensive';
    case 'TacticsNormal':      return 'Normal';
    case 'TacticsAggressive':  return 'Aggressive';
    case 'TacticsSuicidal':    return 'Suicidal';
    }
  
  return 'Invalid';
  }


// ============================================================================
// GetTacticsAuto
//
// Checks and returns whether the currently used team tactics have been
// selected automatically.
// ============================================================================

function bool GetTacticsAuto() {

  return bTacticsAuto;
  }


// ============================================================================
// RequestReAssessment
//
// Requests a reassessment of strategy and bot orders for this team. This
// function doesn't perform the reassessment itself but schedules it for
// execution within the next half second.
// ============================================================================

function RequestReAssessment() {

  if (TimerRate - TimerCounter > 0.5)
    SetTimer(RandRange(0.3, 0.5), False);
  }


// ============================================================================
// Timer
//
// Calls ReAssessStrategy and ReAssessOrders and sets a new timer with a small
// random time offset to prevent the reassessments from happening for both
// teams always at the same time.
// ============================================================================

event Timer() {

  if (Level.Game.IsInState('MatchInProgress')) {
    if (bTacticsAuto)
      ReAssessStrategy();
    ReAssessOrders();
    }
    
  SetTimer(RandRange(4.0, 6.0), False);
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
// FindNewObjectiveFor
//
// Schedules a reassessment of bot orders shortly. Unlike in other team games,
// Jailbreak squads always keep their objectives, but bots change squads.
// ============================================================================

function FindNewObjectiveFor(SquadAI Squad, bool bForceUpdate) {

  RequestReAssessment();
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
    return Max(nPlayersDefending / FClamp(RatePlayers(), 0.5, 1.0) + 0.9, 1);

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
    return Max(nPlayersAttacking / FClamp(RatePlayers(), 0.5, 1.0) + 0.9, 1);
  
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
// Called for bots that just entered the game or were released from jail. Puts
// the bot on freelance and requests reassessment of all team orders.
// ============================================================================

function SetBotOrders(Bot Bot, RosterEntry RosterEntry) {

  PutOnFreelance(Bot);
  RequestReAssessment();
  }


// ============================================================================
// ResetOrders
//
// Puts all bots on freelance, clears the enemy lists of all squads and
// requests reassessment of orders.
// ============================================================================

function ResetOrders() {

  local Controller thisController;
  local SquadAI thisSquad;
  
  for (thisController = Level.ControllerList; thisController != None; thisController = thisController.NextController)
    if (Bot(thisController) != None && thisController.PlayerReplicationInfo.Team == Team)
      PutOnFreelance(Bot(thisController));
  
  for (thisSquad = Squads; thisSquad != None; thisSquad = thisSquad.NextSquad)
    if (JBBotSquad(thisSquad) != None)
      JBBotSquad(thisSquad).ClearEnemies();
  }


// ============================================================================
// CountPlayersDeployed
//
// Returns the number of players currently deployed to the given objective.
// ============================================================================

protected function int CountPlayersDeployed(GameObjective GameObjective) {

  local JBTagObjective TagObjective;

  if (TimeDeployment != Level.TimeSeconds)
    return 0;
  
  TagObjective = Class'JBTagObjective'.Static.FindFor(GameObjective);

  if (TagObjective != None)
    return TagObjective.nPlayersDeployed;
  
  return 0;
  }


// ============================================================================
// DeployToObjective
//
// Records a deployment order for a given objective and number of players.
// Multiple deployment orders on the same objective are accumulative. Call
// DeployExecute after all deployments have been recorded to commit the orders.
// ============================================================================

protected function DeployToObjective(GameObjective GameObjective, int nPlayers) {

  local JBTagObjective TagObjective;
  local JBTagObjective firstTagObjective;
  local JBTagObjective thisTagObjective;
  
  if (GameObjective == None || nPlayers == 0)
    return;
  
  if (TimeDeployment != Level.TimeSeconds) {
    firstTagObjective = JBReplicationInfoGame(Level.Game.GameReplicationInfo).firstTagObjective;
    for (thisTagObjective = firstTagObjective; thisTagObjective != None; thisTagObjective = thisTagObjective.nextTag)
      thisTagObjective.nPlayersDeployed = 0;
    }
  
  TagObjective = Class'JBTagObjective'.Static.FindFor(GameObjective);
  
  if (TagObjective != None) {
    if (TagObjective.nPlayersDeployed == 0)
      TagObjective.nPlayersCurrent = CountPlayersAtObjective(TagObjective.GetObjective());
    TagObjective.nPlayersDeployed += nPlayers;
    }
  
  TimeDeployment = Level.TimeSeconds;
  }


// ============================================================================
// DeployToDefense
//
// Distributes the given number of players on all objectives that need to be
// defended and issues corresponding deployment orders. If more players are
// specified than needed to man (or bot) all objectives, the objective with
// the smallest number of defenders are filled up.
// ============================================================================

protected function DeployToDefense(int nPlayers) {

  local bool bSaturated;
  local int nPlayersDeployed;
  local int nPlayersSuggested;
  local float RatioPlayers;
  local float RatioPlayersDeploy;
  local GameObjective thisObjective;
  local GameObjective ObjectiveDeploy;

  while (nPlayers > 0) {
    ObjectiveDeploy = None;
    
    for (thisObjective = Objectives; thisObjective != None; thisObjective = thisObjective.NextObjective)
      if (IsObjectiveDefense(thisObjective)) {
        if (bSaturated)
          nPlayersSuggested = 1;  // fill up objectives evenly
        else
          nPlayersSuggested = SuggestStrengthDefense(thisObjective);

        if (nPlayersSuggested == 0)
          continue;

        nPlayersDeployed = CountPlayersDeployed(thisObjective);
        RatioPlayers = nPlayersDeployed / nPlayersSuggested;
        
        if (ObjectiveDeploy == None || RatioPlayers < RatioPlayersDeploy) {
          ObjectiveDeploy = thisObjective;
          RatioPlayersDeploy = RatioPlayers;
          }
        }
    
    if (ObjectiveDeploy == None) {
      bSaturated = True;  // all suggested defenses are saturated,
      continue;           // continue distributing surplus defenders
      }
    
    nPlayers -= 1;
    DeployToObjective(ObjectiveDeploy, 1);
    }
  }


// ============================================================================
// IsDeployable
//
// Checks and returns whether the given controller is a bot on this team and 
// can be drawn off from its current objective.
// ============================================================================

protected function bool IsDeployable(Controller Controller) {

  local JBTagObjective TagObjective;

  if (Bot(Controller) == None ||
      Controller.Pawn == None ||
      Controller.PlayerReplicationInfo.Team != Team)
    return False;

  if (JBBotSquad(Bot(Controller).Squad) == None)
    return False;

  if (Bot(Controller).Squad != None &&
      Bot(Controller).Squad.SquadObjective != None)
    TagObjective = Class'JBTagObjective'.Static.FindFor(Bot(Controller).Squad.SquadObjective);
  
  if (TagObjective == None ||
      TagObjective.nPlayersDeployed == 0 ||
      TagObjective.nPlayersDeployed < TagObjective.nPlayersCurrent)
    return True;
  
  return False;
  }


// ============================================================================
// DeployExecute
//
// Deploys bots to objectives as previously recorded by DeployToObjective.
// Players left without deployment are put on the freelance squad.
// ============================================================================

protected function DeployExecute() {

  local float DistanceObjective;
  local float DistanceObjectiveDeploy;
  local Bot BotDeploy;
  local Controller thisController;
  local JBTagObjective firstTagObjective;
  local JBTagObjective thisTagObjective;
  local JBTagObjective TagObjectiveBot;
  local JBTagObjective TagObjectiveDeploy;

  if (TimeDeployment != Level.TimeSeconds)
    return;  // no deployment orders available

  firstTagObjective = JBReplicationInfoGame(Level.Game.GameReplicationInfo).firstTagObjective;        

  while (True) {
    BotDeploy = None;
  
    for (thisController = Level.ControllerList; thisController != None; thisController = thisController.NextController)
      if (IsDeployable(thisController))
        for (thisTagObjective = firstTagObjective; thisTagObjective != None; thisTagObjective = thisTagObjective.nextTag)
          if (thisTagObjective.nPlayersDeployed > 0 &&
              thisTagObjective.nPlayersDeployed > thisTagObjective.nPlayersCurrent) {

            DistanceObjective = CalcDistance(thisController, thisTagObjective.GetObjective());

            if (BotDeploy == None || DistanceObjective < DistanceObjectiveDeploy) {
              BotDeploy = Bot(thisController);
              TagObjectiveDeploy = thisTagObjective;
              DistanceObjectiveDeploy = DistanceObjective;
              }
            }
    
    if (BotDeploy == None)
      break;  // no more bots to deploy to objectives

    TagObjectiveBot = Class'JBTagObjective'.Static.FindFor(BotDeploy.Squad.SquadObjective);
    if (TagObjectiveBot != None)
      TagObjectiveBot.nPlayersCurrent -= 1;
    TagObjectiveDeploy.nPlayersCurrent += 1;

    PutOnSquad(BotDeploy, TagObjectiveDeploy.GetObjective());
    }

  for (thisController = Level.ControllerList; thisController != None; thisController = thisController.NextController)
    if (IsDeployable(thisController) &&
        Bot(thisController).Squad.SquadObjective != None) {

      TagObjectiveBot = Class'JBTagObjective'.Static.FindFor(Bot(thisController).Squad.SquadObjective);
      if (TagObjectiveBot != None)
        TagObjectiveBot.nPlayersCurrent -= 1;

      PutOnFreelance(Bot(thisController));
      }
  }


// ============================================================================
// GetPriorityAttackObjective
//
// Finds the objective that should be attacked. Selects the objective where
// most players can be released with the least required amount of attacking
// players.
// ============================================================================

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
// state TacticsDefensive
//
// Defensive team tactics. Bots try to defend their bases as well as they can,
// abandoning attack if they must and only sending bots on freelance or attack
// if all bases are well guarded.
// ============================================================================

state TacticsDefensive {

  // ================================================================
  // ReAssessOrders
  //
  // Fills up the defense and sends the remaining undeployed players
  // on freelance or attack. Sends at least two players on defense
  // for every objective.
  // ================================================================

  function ReAssessOrders() {

    local int nPlayersFree;
    local int nPlayersJailed;
    local int nPlayersAttacking;
    local int nPlayersDefending;
    local GameObjective thisObjective;
    local GameObjective ObjectiveAttack;
    
    nPlayersFree   = JBReplicationInfoTeam(Team).CountPlayersFree();
    nPlayersJailed = JBReplicationInfoTeam(Team).CountPlayersJailed();

    for (thisObjective = Objectives; thisObjective != None; thisObjective = thisObjective.NextObjective)
      if (IsObjectiveDefense(thisObjective))
        nPlayersDefending += Max(2, SuggestStrengthDefense(thisObjective));

    nPlayersDefending = Min(nPlayersDefending, nPlayersFree);
    
    if (nPlayersJailed > 0) {
      ObjectiveAttack = GetPriorityAttackObjective();
      nPlayersAttacking = SuggestStrengthAttack(ObjectiveAttack);
      }

    if (nPlayersAttacking + nPlayersDefending > nPlayersFree)
      nPlayersAttacking = Max(0, nPlayersFree - nPlayersDefending);
    
    DeployToObjective(ObjectiveAttack, nPlayersAttacking);
    DeployToDefense(nPlayersDefending);
    DeployExecute();
    }

  } // state TacticsDefensive


// ============================================================================
// state TacticsNormal
//
// Normal team tactics. Bots try to defend their bases and attack enemies in
// order to kill them and to release their teammates.
// ============================================================================

auto state TacticsNormal {

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

      DeployToObjective(ObjectiveAttack,  nPlayersAttacking);
      DeployToObjective(ObjectiveDefense, nPlayersDefending);
      DeployExecute();
      }
    
    else {
      nPlayersDefending = Min(nPlayersFree - nPlayersAttacking, nPlayersDefendingMax);

      if (nPlayersAttacking > 0)
        nPlayersAttacking = nPlayersFree - nPlayersDefending;  // attack with full force

      DeployToObjective(ObjectiveAttack, nPlayersAttacking);
      DeployToDefense(nPlayersDefending);
      DeployExecute();  // rest goes on freelance
      }
    }

  } // state TacticsNormal


// ============================================================================
// state TacticsAggressive
//
// Aggressive team tactics. Bots will attack even at the expense of defending
// their own bases if they must.
// ============================================================================

state TacticsAggressive {

  // ================================================================
  // ReAssessOrders
  //
  // Puts as many players as required on attack. The remaining
  // players are distributed on defended objectives. If there are
  // barely enough players to defend one objective, abandons defense
  // of all other objectives. If there are not enough bots even for
  // that, abandons defense altogether.
  // ================================================================
  
  function ReAssessOrders() {

    local int nPlayersFree;
    local int nPlayersJailed;
    local int nPlayersAttacking;
    local int nPlayersDefending;
    local int nPlayersDefendingMax;
    local int nPlayersDefendingMin;
    local int nPlayersReleasable;
    local int nPlayersReleasableMax;
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

    if (nPlayersAttacking + nPlayersDefendingMax <= nPlayersFree) {
      DeployToObjective(ObjectiveAttack, nPlayersAttacking);
      DeployToDefense(nPlayersDefendingMax);
      DeployExecute();  // rest go on freelance
      }
      
    else if (nPlayersAttacking + nPlayersDefendingMin / 2 <= nPlayersFree) {
      nPlayersDefending = nPlayersFree - nPlayersAttacking;

      for (thisObjective = Objectives; thisObjective != None; thisObjective = thisObjective.NextObjective)
        if (IsObjectiveDefense(thisObjective)) {
          nPlayersReleasable = CountPlayersReleasable(thisObjective);
          if (nPlayersReleasable > nPlayersReleasableMax &&
              nPlayersDefendingMin >= SuggestStrengthDefense(thisObjective)) {
            ObjectiveDefense = thisObjective;
            nPlayersReleasableMax = nPlayersReleasable;
            }
          }
      
      DeployToObjective(ObjectiveAttack,  nPlayersAttacking);
      DeployToObjective(ObjectiveDefense, nPlayersDefending);
      DeployExecute();
      }

    else {
      DeployToObjective(ObjectiveAttack, nPlayersFree);
      DeployExecute();
      }
    }

  } // state TacticsAggressive


// ============================================================================
// state TacticsEvasive
// state TacticsSuicidal
//
// Dummy states pending implementation.
// ============================================================================

state TacticsEvasive  extends TacticsDefensive  {}
state TacticsSuicidal extends TacticsAggressive {}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  bTacticsAuto = True;

  ClassSquadArena = Class'JBBotSquadArena';
  ClassSquadJail  = Class'JBBotSquadJail';

  SquadType = Class'JBBotSquad';
  }