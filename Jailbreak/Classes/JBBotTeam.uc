// ============================================================================
// JBBotTeam
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Controls the bots of one team.
// ============================================================================


class JBBotTeam extends TeamAI
  config
  notplaceable;


// ============================================================================
// Types
// ============================================================================

struct TExplanation
{
  var bool bIsShaded;                        // color shade for message blocks
  var string Text;                           // text of message on screen
};


// ============================================================================
// Configuration
// ============================================================================

var config bool bExplainToLog;               // write verbose log messages
var config bool bExplainToScreen;            // write log messages on screen


// ============================================================================
// Variables
// ============================================================================

var class<JBBotSquadArena> ClassSquadArena;  // bot squad for arena
var class<JBBotSquadJail>  ClassSquadJail;   // bot squad for jail

var private bool bIsExplanationInitialized;  // registered as screen overlay
var private float TimeExplanation;           // time of last explanation
var private string IndentExplanation;        // current explanation level
var private array<TExplanation> ListExplanation;  // explanations on screen

var private JBTagTeam TagTeamSelf;           // team tag of own team
var private JBTagTeam TagTeamEnemy;          // team tag of enemy team
var private JBTagTeam TagTeam[2];            // team tags by team index

var private int nObjectives;                 // cached number of objectives

var private bool bTacticsAuto;               // tactics selected automatically
var private float TimeTacticsSelected;       // time of last tactics selection

var private transient float TimeDeployment;  // time of last deployment order


// ============================================================================
// Caches
// ============================================================================

struct TCacheCalcDistance            { var float Time; var float Result; var vector LocationController, LocationActorTarget; };
struct TCacheCountEnemiesAccounted   { var float Time; var int   Result; };
struct TCacheCountEnemiesUnaccounted { var float Time; var int   Result; };
struct TCacheRatePlayers             { var float Time; var float Result; };

var private transient TCacheCalcDistance            CacheCalcDistance;
var private transient TCacheCountEnemiesAccounted   CacheCountEnemiesAccounted;
var private transient TCacheCountEnemiesUnaccounted CacheCountEnemiesUnaccounted;
var private transient TCacheRatePlayers             CacheRatePlayers;


// ============================================================================
// MatchStarting
//
// Initializes the JBTagPlayer references.
// ============================================================================

function MatchStarting()
{
  TagTeamSelf  = Class'JBTagTeam'.Static.FindFor(     Team);
  TagTeamEnemy = Class'JBTagTeam'.Static.FindFor(EnemyTeam);

  TagTeam[     Team.TeamIndex] = TagTeamSelf;
  TagTeam[EnemyTeam.TeamIndex] = TagTeamEnemy;
}


// ============================================================================
// SetTactics
//
// Sets the current team tactics for this team and returns the selected
// tactics. Resets all bots to follow the selected tactics. The following input
// values are supported:
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

function name SetTactics(name Tactics)
{
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;

  if (TimeTacticsSelected == Level.TimeSeconds)
    return GetTactics();  // set tactics only once per tick

  firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    if (thisTagPlayer.GetTeam() == Team &&
         (thisTagPlayer.OrderNameFixed == 'Attack' ||
          thisTagPlayer.OrderNameFixed == 'Defend'))
      SetOrders(Bot(thisTagPlayer.GetController()), 'Freelance', None);

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

  TimeTacticsSelected = Level.TimeSeconds;

  Explain("setting tactics to" @ Tactics);
  return GetTactics();
}


// ============================================================================
// GetTactics
//
// Returns the name of the currently selected team tactics.
// ============================================================================

function name GetTactics()
{
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

function bool GetTacticsAuto()
{
  return bTacticsAuto;
}


// ============================================================================
// RequestReAssessment
//
// Requests a reassessment of strategy and bot orders for this team. This
// function doesn't perform the reassessment itself but schedules it for
// execution within the next half second.
// ============================================================================

function RequestReAssessment()
{
  if (TimerRate - TimerCounter > 0.5) {
    SetTimer(RandRange(0.3, 0.5), False);
    Explain("strategy will be reassessed in" @ TimerCounter @ "seconds");
  }
}


// ============================================================================
// Timer
//
// Calls ReAssessStrategy and ReAssessOrders and sets a new timer with a small
// random time offset to prevent the reassessments from happening for both
// teams always at the same time.
// ============================================================================

event Timer()
{
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

function SetObjectiveLists()
{
  local GameObjective thisObjective;
  local JBGameObjective Objective;
  local JBInfoJail thisJail;
  local Trigger thisTrigger;

  foreach AllActors(Class'GameObjective', thisObjective)
    Class'JBTagObjective'.Static.SpawnFor(thisObjective);

  foreach DynamicActors(Class'Trigger', thisTrigger) {
    foreach DynamicActors(Class'JBInfoJail', thisJail)
      if (thisJail.Tag == thisTrigger.Event &&
          thisJail.CanReleaseTeam(Team))
        break;

    if (thisJail == None)
      continue;

    Objective = Spawn(Class'JBGameObjective', , , thisTrigger.Location);
    Objective.TriggerRelease    = thisTrigger;
    Objective.DefenderTeamIndex = EnemyTeam.TeamIndex;
    Objective.StartTeam         = EnemyTeam.TeamIndex;
    Objective.Event             = thisJail.Tag;
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

function FindNewObjectiveFor(SquadAI Squad, bool bForceUpdate)
{
  RequestReAssessment();
}


// ============================================================================
// PutOnFreelance
//
// Puts the given bot on the first freelance squad found that can still take
// new players. Creates a new freelance squad if none is found.
// ============================================================================

function PutOnFreelance(Bot Bot)
{
  local SquadAI SquadFreelance;

  for (SquadFreelance = Squads; SquadFreelance != None; SquadFreelance = SquadFreelance.NextSquad)
    if (SquadFreelance.bFreelance &&
        SquadFreelance.MaxSquadSize > SquadFreelance.GetSize())
      break;

  if (SquadFreelance == None)
    Super.PutOnFreelance(Bot);
  else
    SquadFreelance.AddBot(Bot);

  Explain("ordering" @ GetExplanationPlayer(Bot) @ "to freelance");
}


// ============================================================================
// PutOnSquad
//
// Puts the given bot on the squad attacking or defending the given objective.
// ============================================================================

function PutOnSquad(Bot Bot, GameObjective GameObjective)
{
  if (IsObjectiveAttack(GameObjective)) {
    if (AttackSquad == None)
           AttackSquad = AddSquadWithLeader(Bot, GameObjective);
      else AttackSquad.AddBot(Bot);
    Explain("ordering" @ GetExplanationPlayer(Bot) @ "to attack" @ GetExplanationObjective(GameObjective));
  }

  else if (IsObjectiveDefense(GameObjective)) {
    if (GameObjective.DefenseSquad == None)
           GameObjective.DefenseSquad = AddSquadWithLeader(Bot, GameObjective);
      else GameObjective.DefenseSquad.AddBot(Bot);
    Explain("ordering" @ GetExplanationPlayer(Bot) @ "to defend" @ GetExplanationObjective(GameObjective));
  }

  else {
    Log("Warning: Cannot order bot" @ GetExplanationPlayer(Bot) @
        "to attack or defend objective" @ GameObjective);
    PutOnFreelance(Bot);
  }
}


// ============================================================================
// PutOnSquadArena
//
// Creates an arena squad for the given bot and adds the bot to it.
// ============================================================================

function PutOnSquadArena(Bot Bot)
{
  local JBBotSquadArena SquadArena;

  SquadArena = Spawn(ClassSquadArena);
  SquadArena.Initialize(Team, None, Bot);

  SquadArena.NextSquad = Squads;
  Squads = SquadArena;
}


// ============================================================================
// PutOnSquadJail
//
// Creates a jail squad for the given bot and adds the bot to it.
// ============================================================================

function PutOnSquadJail(Bot Bot)
{
  local JBBotSquadJail SquadJail;

  SquadJail = Spawn(ClassSquadJail);
  SquadJail.Initialize(Team, None, Bot);

  SquadJail.NextSquad = Squads;
  Squads = SquadJail;
}


// ============================================================================
// SendSquadTo
//
// Finds an idle squad that could be sent to investigate the given location
// and orders it to go there. If a hunted player is specified, prefers a squad
// already ordered to hunt that player or, failing to find that, one that
// doesn't hunt any player at the moment at all. Returns whether a suitable
// squad was found and ordered.
// ============================================================================

function bool SendSquadTo(NavigationPoint NavigationPoint, optional Controller ControllerHunted)
{
  local float Distance;
  local float DistanceClosest;
  local SquadAI thisSquad;
  local JBBotSquad SquadSelected;

  if (ControllerHunted != None)
    for (thisSquad = Squads; thisSquad != None; thisSquad = thisSquad.NextSquad)
      if (JBBotSquad(thisSquad) != None &&
          JBBotSquad(thisSquad).IsHunting(ControllerHunted))
        break;

  SquadSelected = JBBotSquad(thisSquad);

  if (SquadSelected == None)
    for (thisSquad = Squads; thisSquad != None; thisSquad = thisSquad.NextSquad)
      if (JBBotSquad(thisSquad) != None &&
          JBBotSquad(thisSquad).CanHunt()) {

        Distance = CalcDistance(thisSquad.SquadLeader, NavigationPoint);

        if (JBBotSquad(thisSquad).CanHuntBetterThan(SquadSelected, ControllerHunted) || Distance < DistanceClosest) {
          SquadSelected = JBBotSquad(thisSquad);
          DistanceClosest = Distance;
        }
      }

  if (SquadSelected != None)
    return SquadSelected.Hunt(ControllerHunted, NavigationPoint);

  return False;
}


// ============================================================================
// FindBotForArena
//
// Returns a reference to the jailed bot who is currently best suited for an
// arena match against the given opponent in the given arena. Returns None if
// no suitable bot is found. Tactics states can override this function.
// ============================================================================

function Bot FindBotForArena(JBInfoArena Arena, Controller ControllerOpponent, optional float FactorEfficiencyOpponent)
{
  local float EfficiencyBot;
  local float EfficiencyBotBest;
  local float EfficiencyOpponent;
  local Bot Bot;
  local Bot BotBest;
  local PlayerReplicationInfo PlayerReplicationInfoBot;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;

  if (ControllerOpponent.PlayerReplicationInfo == None)
    return None;

  EfficiencyOpponent = CalcEfficiency(ControllerOpponent.PlayerReplicationInfo.Kills,
                                      ControllerOpponent.PlayerReplicationInfo.Deaths);

  if (FactorEfficiencyOpponent == 0.0)
    FactorEfficiencyOpponent = 1.0;

  EfficiencyBotBest = -1.0;

  firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag) {
    Bot = Bot(thisTagPlayer.GetController());
    if (Bot != None &&
        thisTagPlayer.GetTeam() == Team &&
        thisTagPlayer.IsInJail()) {
      
      PlayerReplicationInfoBot = thisTagPlayer.GetPlayerReplicationInfo();
      EfficiencyBot = CalcEfficiency(PlayerReplicationInfoBot.Kills,
                                     PlayerReplicationInfoBot.Deaths);

      if (EfficiencyBot >= EfficiencyOpponent * FactorEfficiencyOpponent &&
          EfficiencyBot >  EfficiencyBotBest) {
        BotBest = Bot;
        EfficiencyBotBest = EfficiencyBot;
      }
    }
  }

  return BotBest;
}


// ============================================================================
// IsObjectiveAttack
//
// Returns whether the given objective is to be attacked by this team.
// ============================================================================

function bool IsObjectiveAttack(GameObjective GameObjective)
{
  return (GameObjective != None &&
          GameObjective.DefenderTeamIndex != Team.TeamIndex);
}


// ============================================================================
// IsObjectiveDefense
//
// Returns whether the given objective is to be defended by this team.
// ============================================================================

function bool IsObjectiveDefense(GameObjective GameObjective)
{
  return (GameObjective != None &&
          GameObjective.DefenderTeamIndex == Team.TeamIndex);
}


// ============================================================================
// CountObjectives
//
// Returns the number of objectives.
// ============================================================================

function int CountObjectives()
{
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

function int CountPlayersAtObjective(GameObjective GameObjective)
{
  local int nPlayersAtObjective;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  local SquadAI thisSquad;
  local SquadAI SquadControlled;

  firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    if (PlayerController(thisTagPlayer.GetController()) != None &&
        thisTagPlayer.IsFree() &&
        thisTagPlayer.GetTeam() == Team &&
        thisTagPlayer.GuessObjective() == GameObjective) {

      SquadControlled = GetSquadLedBy(thisTagPlayer.GetController());
      if (SquadControlled == None)
        nPlayersAtObjective += 1;
      else
        nPlayersAtObjective += SquadControlled.GetSize();
    }

  for (thisSquad = Squads; thisSquad != None; thisSquad = thisSquad.NextSquad)
    if (thisSquad.SquadObjective == GameObjective)
      nPlayersAtObjective += thisSquad.GetSize();

  return nPlayersAtObjective;
}


// ============================================================================
// CountPlayersReleasable
//
// Returns the number of players on this team that could be released by
// attacking the given objective. Works for both teams.
// ============================================================================

function int CountPlayersReleasable(GameObjective GameObjective)
{
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
// objective or actor. Expensive, so use sparingly.
// ============================================================================

static function float CalcDistance(Controller Controller, Actor ActorTarget)
{
  if (Default.CacheCalcDistance.Time == Controller.Level.TimeSeconds &&
      Default.CacheCalcDistance.LocationController  == Controller .Location &&
      Default.CacheCalcDistance.LocationActorTarget == ActorTarget.Location)
    return Default.CacheCalcDistance.Result;

  if (Controller.Pawn == None)
    return 0.0;  // no pathfinding without pawn

  Default.CacheCalcDistance.Time = Controller.Level.TimeSeconds;
  Default.CacheCalcDistance.LocationController  = Controller .Location;
  Default.CacheCalcDistance.LocationActorTarget = ActorTarget.Location;

  if (JBGameObjective(ActorTarget) != None)
    ActorTarget = JBGameObjective(ActorTarget).TriggerRelease;

  if (Controller.FindPathToward(ActorTarget) != None)
    Default.CacheCalcDistance.Result = Controller.RouteDist;
  else
    Default.CacheCalcDistance.Result = VSize(ActorTarget.Location - Controller.Pawn.Location);

  return Default.CacheCalcDistance.Result;
}


// ============================================================================
// CalcEfficiency
//
// Calculates the efficiency of a player or team with the given number of
// kills and deaths.
// ============================================================================

static function float CalcEfficiency(int nKills, int nDeaths)
{
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

function float RatePlayers()
{
  local int nDeathsByTeam[2];
  local int nKillsByTeam[2];
  local float EfficiencyTeamSelf;
  local float EfficiencyTeamEnemy;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  local PlayerReplicationInfo PlayerReplicationInfo;

  if (CacheRatePlayers.Time == Level.TimeSeconds)
    return CacheRatePlayers.Result;

  firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    if (thisTagPlayer.IsFree()) {
      PlayerReplicationInfo = thisTagPlayer.GetPlayerReplicationInfo();
      nKillsByTeam [PlayerReplicationInfo.Team.TeamIndex] += PlayerReplicationInfo.Kills;
      nDeathsByTeam[PlayerReplicationInfo.Team.TeamIndex] += PlayerReplicationInfo.Deaths;
    }

  EfficiencyTeamSelf  = CalcEfficiency(nKillsByTeam[     Team.TeamIndex], nDeathsByTeam[     Team.TeamIndex]);
  EfficiencyTeamEnemy = CalcEfficiency(nKillsByTeam[EnemyTeam.TeamIndex], nDeathsByTeam[EnemyTeam.TeamIndex]);

  if (EfficiencyTeamEnemy > 0)
         CacheRatePlayers.Result = EfficiencyTeamSelf / EfficiencyTeamEnemy;
    else CacheRatePlayers.Result = 9999;  // theoretically infinite

  Explain("efficiency rating for this team (kills/total):" @ CacheRatePlayers.Result);

  CacheRatePlayers.Time = Level.TimeSeconds;
  return CacheRatePlayers.Result;
}


// ============================================================================
// IsEnemyAcquired
//
// Checks and returns whether the given enemy player has been acquired by a
// squad of this team.
// ============================================================================

function bool IsEnemyAcquired(Controller Controller)
{
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

function bool IsEnemyAcquiredAtObjective(Controller Controller, GameObjective GameObjective)
{
  local SquadAI thisSquad;

  for (thisSquad = Squads; thisSquad != None; thisSquad = thisSquad.NextSquad)
    if (thisSquad.SquadObjective == GameObjective &&
        JBBotSquad(thisSquad) != None &&
        JBBotSquad(thisSquad).IsEnemyAcquired(Controller))
      return True;

  return False;
}


// ============================================================================
// CountEnemiesAccounted
//
// Returns the number of free enemies that are currently engaged in a fight
// with players of this team; in short, enemies whose objective is known.
// Results are cached within a tick.
// ============================================================================

function int CountEnemiesAccounted()
{
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;

  if (CacheCountEnemiesAccounted.Time == Level.TimeSeconds)
    return CacheCountEnemiesAccounted.Result;

  CacheCountEnemiesAccounted.Result = 0;

  firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    if (thisTagPlayer.IsFree() && IsEnemyAcquired(thisTagPlayer.GetController()))
      CacheCountEnemiesAccounted.Result += 1;

  CacheCountEnemiesAccounted.Time = Level.TimeSeconds;
  return CacheCountEnemiesAccounted.Result;
}


// ============================================================================
// CountEnemiesUnaccounted
//
// Returns the number of free enemies whose objective currently isn't known.
// Results are cached within a tick.
// ============================================================================

function int CountEnemiesUnaccounted()
{
  if (CacheCountEnemiesUnaccounted.Time == Level.TimeSeconds)
    return CacheCountEnemiesUnaccounted.Result;

  CacheCountEnemiesUnaccounted.Result =
    TagTeamEnemy.CountPlayersFree() - CountEnemiesAccounted();

  CacheCountEnemiesUnaccounted.Time = Level.TimeSeconds;
  return CacheCountEnemiesUnaccounted.Result;
}


// ============================================================================
// EstimateStrengthAttack
//
// Estimates the number of players the enemy team will attack the given
// objective with.
// ============================================================================

function int EstimateStrengthAttack(GameObjective GameObjective)
{
  local bool bEnemiesReleasable;
  local int nEnemiesAttacking;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;

  bEnemiesReleasable = CountPlayersReleasable(GameObjective) > 0;
  if (bEnemiesReleasable)
    nEnemiesAttacking += CountEnemiesUnaccounted();  // worst case

  firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
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

function int EstimateStrengthDefense(GameObjective GameObjective)
{
  local int nEnemiesDefending;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;

  firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
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

function int SuggestStrengthAttack(GameObjective GameObjective)
{
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

function int SuggestStrengthDefense(GameObjective GameObjective)
{
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

function ReAssessStrategy()
{
  local int nPlayersFree;
  local int nPlayersKilledEstimated;
  local int ScoreLead;
  local int ScoreTeamEnemy;
  local int ScoreTeamSelf;
  local float KillsPerSecond;
  local name Strategy;
  local name Tactics;
  local PlayerReplicationInfo PlayerReplicationInfo;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  local JBTagTeam TagTeamWinning;
  local JBTagTeam TagTeamLosing;

  ScoreTeamEnemy = EnemyTeam.Score;
  ScoreTeamSelf  =      Team.Score;

  ScoreLead = ScoreTeamSelf - ScoreTeamEnemy;

  Explain("reassessing strategy:");
  ExplainBlockStart();
  Explain("enemy score:" @ ScoreTeamEnemy $ ", own score:" @ ScoreTeamSelf);

  Strategy = 'Scorelimit';
  Tactics  = 'TacticsNormal';

  if (ScoreLead != 0                             &&
      DeathMatch(Level.Game).RemainingTime >   0 &&
      DeathMatch(Level.Game).RemainingTime < 120) {

    if (ScoreLead > 0) { TagTeamWinning = TagTeamSelf;   TagTeamLosing = TagTeamEnemy; }
                  else { TagTeamWinning = TagTeamEnemy;  TagTeamLosing = TagTeamSelf;  }
  
    firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
    for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
      if (thisTagPlayer.IsFree() &&
          thisTagPlayer.GetTeam() != TagTeamLosing.GetTeam()) {

        PlayerReplicationInfo = thisTagPlayer.GetPlayerReplicationInfo();
        if (PlayerReplicationInfo.Kills > 0)
          KillsPerSecond += PlayerReplicationInfo.Kills / (DeathMatch(Level.Game).ElapsedTime - PlayerReplicationInfo.StartTime);
      }

    nPlayersFree = TagTeamWinning.CountPlayersFree();
    nPlayersKilledEstimated = KillsPerSecond * DeathMatch(Level.Game).RemainingTime;

    if (nPlayersFree > nPlayersKilledEstimated)
      Strategy = 'Timelimit';

    Explain("free players from losing team have been killing" @ KillsPerSecond * 60 @ "players per minute up to now");
    Explain("estimating that" @ nPlayersKilledEstimated @ "of" @ nPlayersFree @ "free players will be killed in remaining time");
  }

  Explain("following strategy" @ Strategy);

  switch (Strategy) {
    case 'Scorelimit':
           if (ScoreLead > 1) Tactics = 'TacticsDefensive';
      else if (ScoreLead < 0) Tactics = 'TacticsAggressive';
      break;

    case 'Timelimit':
           if (ScoreLead > 0) Tactics = 'TacticsEvasive';
      else if (ScoreLead < 0) Tactics = 'TacticsAggressive';
      break;
  }

  Explain("selecting" @ Tactics @ "(current:" @ GetStateName() $ ")");
  ExplainBlockEnd();

  GotoState(Tactics);
}


// ============================================================================
// ReAssessOrders
//
// Checks every bot's orders and changes them if necessary to accommodate the
// currently selected team tactics. Dummy implementation here which only
// issues a warning to the log; actual implementations in Tactics states.
// ============================================================================

function ReAssessOrders()
{
  Log("Warning: ReAssessOrders for team" @ Team.TeamIndex @ "should not be called in default state");
}


// ============================================================================
// SetOrders
//
// Called when a player issues an explicit order for a bot, and when something
// is selected from the custom team tactics submenu in the speech menu.
// ============================================================================

function SetOrders(Bot Bot, name OrderName, Controller ControllerCommander)
{
  local JBTagPlayer TagPlayerBot;

  TagPlayerBot = Class'JBTagPlayer'.Static.FindFor(Bot.PlayerReplicationInfo);

  switch (OrderName) {
    case 'Attack':
    case 'Defend':
    case 'Follow':
    case 'Hold':
      TagPlayerBot.OrderNameFixed = OrderName;
      Explain("setting orders" @ OrderName @ "for" @ GetExplanationPlayer(Bot));
      break;

    case 'Freelance':
      TagPlayerBot.OrderNameFixed = '';  // reset to team tactics
      Explain("resetting orders to team tactics for" @ GetExplanationPlayer(Bot));
      break;

    case 'TacticsAuto':        SetTactics('Auto');        return;
    case 'TacticsSuicidal':    SetTactics('Suicidal');    return;
    case 'TacticsAggressive':  SetTactics('Aggressive');  return;
    case 'TacticsNormal':      SetTactics('Normal');      return;
    case 'TacticsDefensive':   SetTactics('Defensive');   return;
    case 'TacticsEvasive':     SetTactics('Evasive');     return;
  }

  if (TagPlayerBot.IsFree() ||
     (TagPlayerBot.IsInJail() &&
       (TagPlayerBot.GetJail().IsReleaseOpening(Team) ||
        TagPlayerBot.GetJail().IsReleaseOpen   (Team)))) {

    Super.SetOrders(Bot, OrderName, ControllerCommander);
    RequestReAssessment();
  }
}


// ============================================================================
// SetBotOrders
//
// Called for bots that just entered the game or were released from jail. Puts
// the bot on freelance and requests reassessment of all team orders.
// ============================================================================

function SetBotOrders(Bot Bot, RosterEntry RosterEntry)
{
  local JBTagPlayer TagPlayerBot;

  TagPlayerBot = Class'JBTagPlayer'.Static.FindFor(Bot.PlayerReplicationInfo);
  if (TagPlayerBot != None)
    TagPlayerBot.OrderNameFixed = '';  // reset to team tactics

  PutOnFreelance(Bot);
  RequestReAssessment();
}


// ============================================================================
// ResumeBotOrders
//
// If the given bot has been explicitly ordered to attack or defend, resumes
// those orders. Otherwise clears the fixed orders and sets team orders.
// ============================================================================

function ResumeBotOrders(Bot Bot)
{
  local JBTagPlayer TagPlayerBot;

  TagPlayerBot = Class'JBTagPlayer'.Static.FindFor(Bot.PlayerReplicationInfo);
  if (TagPlayerBot == None)
    return;

  if (TagPlayerBot.OrderNameFixed == 'Attack' ||
      TagPlayerBot.OrderNameFixed == 'Defend')
    SetOrders(Bot, TagPlayerBot.OrderNameFixed, None);
  else
    SetBotOrders(Bot, None);  // team tactics
}


// ============================================================================
// ResetOrders
//
// Puts all bots on freelance, clears the enemy lists of all squads and
// requests reassessment of orders.
// ============================================================================

function ResetOrders()
{
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

protected function int CountPlayersDeployed(GameObjective GameObjective)
{
  local JBTagObjective TagObjective;

  if (TimeDeployment != Level.TimeSeconds)
    return 0;

  TagObjective = Class'JBTagObjective'.Static.FindFor(GameObjective);

  if (TagObjective != None)
    return TagObjective.nPlayersDeployed;

  return 0;
}


// ============================================================================
// DeployRestart
//
// Resets all deployment orders. Automatically called by DeployToObjective and
// DeployToDefense on the first deployment order within a tick.
// ============================================================================

protected function DeployRestart()
{
  local JBTagObjective firstTagObjective;
  local JBTagObjective thisTagObjective;

  Explain("starting bot deployment:");
  ExplainBlockStart();

  firstTagObjective = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagObjective;
  for (thisTagObjective = firstTagObjective; thisTagObjective != None; thisTagObjective = thisTagObjective.nextTag)
    thisTagObjective.nPlayersDeployed = 0;

  TimeDeployment = Level.TimeSeconds;
}


// ============================================================================
// DeployToObjective
//
// Records a deployment order for a given objective and number of players.
// Multiple deployment orders on the same objective are accumulative. Call
// DeployExecute after all deployments have been recorded to commit the orders.
// ============================================================================

protected function DeployToObjective(GameObjective GameObjective, int nPlayers)
{
  local JBTagObjective TagObjective;

  if (TimeDeployment != Level.TimeSeconds)
    DeployRestart();

  if (GameObjective != None && nPlayers > 0) {
    TagObjective = Class'JBTagObjective'.Static.FindFor(GameObjective);

    if (TagObjective != None) {
      if (TagObjective.nPlayersDeployed == 0)
        TagObjective.nPlayersCurrent = CountPlayersAtObjective(TagObjective.GetObjective());

      if (TagObjective.nPlayersDeployed == 0)
             Explain("deploying" @ nPlayers @            "player(s) to" @ GetExplanationObjective(GameObjective));
        else Explain("deploying" @ nPlayers @ "additional player(s) to" @ GetExplanationObjective(GameObjective));
      
      TagObjective.nPlayersDeployed += nPlayers;
    }
  }
}


// ============================================================================
// DeployToDefense
//
// Distributes the given number of players on all objectives that need to be
// defended and issues corresponding deployment orders. If more players are
// specified than needed to man (or bot) all objectives, the objectives with
// the smallest number of defenders are filled up.
// ============================================================================

protected function DeployToDefense(int nPlayers)
{
  local bool bSaturated;
  local int nPlayersDeployed;
  local int nPlayersSuggested;
  local float RatioPlayers;
  local float RatioPlayersDeploy;
  local GameObjective thisObjective;
  local GameObjective ObjectiveDeploy;

  if (TimeDeployment != Level.TimeSeconds)
    DeployRestart();

  Explain("deploying" @ nPlayers @ "player(s) to defense:");
  ExplainBlockStart();

  while (nPlayers > 0) {
    ObjectiveDeploy = None;

    for (thisObjective = Objectives; thisObjective != None; thisObjective = thisObjective.NextObjective)
      if (IsObjectiveDefense(thisObjective)) {
        if (bSaturated)
               nPlayersSuggested = 1;  // fill up objectives evenly
          else nPlayersSuggested = SuggestStrengthDefense(thisObjective);

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

  ExplainBlockEnd();
}


// ============================================================================
// CanDeploy
//
// Checks and returns whether the given controller is a bot on this team and
// can be drawn off from its current objective.
// ============================================================================

protected function bool CanDeploy(Controller Controller)
{
  local Controller ControllerLeader;
  local JBTagObjective TagObjective;

  if (Bot(Controller) == None ||
      Controller.Pawn == None ||
      Controller.PlayerReplicationInfo.Team != Team ||
      JBBotSquad(Bot(Controller).Squad) == None)
    return False;

  ControllerLeader = Bot(Controller).Squad.SquadLeader;
  if (PlayerController(ControllerLeader) != None)
    return False;

  if (Bot(Controller).Squad.SquadObjective != None)
    TagObjective = Class'JBTagObjective'.Static.FindFor(Bot(Controller).Squad.SquadObjective);

  if (TagObjective == None ||
      TagObjective.nPlayersDeployed == 0 ||
      TagObjective.nPlayersDeployed < TagObjective.nPlayersCurrent)
    return True;

  return False;
}


// ============================================================================
// CanDeployToObjective
//
// Checks and returns whether the given player can be deployed to the given
// objective. Assumes that CanDeploy returns True for the given player.
// ============================================================================

protected function bool CanDeployToObjective(Controller Controller, GameObjective ObjectiveDeploy)
{
  local JBTagPlayer TagPlayer;

  TagPlayer = Class'JBTagPlayer'.Static.FindFor(Controller.PlayerReplicationInfo);

  if (TagPlayer != None)
    switch (TagPlayer.OrderNameFixed) {
      case 'Attack':  return IsObjectiveAttack (ObjectiveDeploy);
      case 'Defend':  return IsObjectiveDefense(ObjectiveDeploy);
      case 'Follow':  return PlayerController(Bot(Controller).Squad.SquadLeader) == None;
      case 'Hold':    return HoldSpot(Bot(Controller).GoalScript) == None;
    }

  return True;
}


// ============================================================================
// DeployExecute
//
// Deploys bots to objectives as previously recorded by DeployToObjective.
// Players left without deployment are put on the freelance squad.
// ============================================================================

protected function DeployExecute()
{
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

  Explain("executing deployment orders:");
  ExplainBlockStart();

  firstTagObjective = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagObjective;

  while (True) {
    BotDeploy = None;

    for (thisController = Level.ControllerList; thisController != None; thisController = thisController.NextController)
      if (CanDeploy(thisController))
        for (thisTagObjective = firstTagObjective; thisTagObjective != None; thisTagObjective = thisTagObjective.nextTag)
          if (CanDeployToObjective(thisController, thisTagObjective.GetObjective()) &&
              thisTagObjective.nPlayersDeployed != 0 &&
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
    if (CanDeploy(thisController) &&
        CanDeployToObjective(thisController, None)) {
      if (Bot(thisController).Squad.SquadObjective != None) {
        TagObjectiveBot = Class'JBTagObjective'.Static.FindFor(Bot(thisController).Squad.SquadObjective);
        if (TagObjectiveBot != None)
          TagObjectiveBot.nPlayersCurrent -= 1;
  
        PutOnFreelance(Bot(thisController));
      }
    }

  ExplainBlockEnd();
}


// ============================================================================
// GetLeastDefendedObjective
//
// Returns the objective that has the lowest ratio currently present to
// actually suggested defenders. If no objective currently requires defenders,
// selects the objective that currently has the smallest number of them.
// ============================================================================

function GameObjective GetLeastDefendedObjective()
{
  local int nPlayersCurrent;
  local int nPlayersCurrentMin;
  local int nPlayersSuggested;
  local float RatioPlayers;
  local float RatioPlayersSelected;
  local GameObjective thisObjective;
  local GameObjective ObjectiveSelected;

  for (thisObjective = Objectives; thisObjective != None; thisObjective = thisObjective.NextObjective)
    if (IsObjectiveDefense(thisObjective)) {
      nPlayersSuggested = SuggestStrengthDefense(thisObjective);
      if (nPlayersSuggested > 0) {
        nPlayersCurrent = CountPlayersAtObjective(thisObjective);
        RatioPlayers = nPlayersCurrent / nPlayersSuggested;
        if (ObjectiveSelected == None || RatioPlayers < RatioPlayersSelected) {
          ObjectiveSelected = thisObjective;
          RatioPlayersSelected = RatioPlayers;
        }
      }
    }

  if (ObjectiveSelected == None)
    for (thisObjective = Objectives; thisObjective != None; thisObjective = thisObjective.NextObjective)
      if (IsObjectiveDefense(thisObjective)) {
        nPlayersCurrent = CountPlayersAtObjective(thisObjective);
        if (ObjectiveSelected == None || nPlayersCurrent < nPlayersCurrentMin) {
          ObjectiveSelected = thisObjective;
          nPlayersCurrentMin = nPlayersCurrent;
        }
      }

  return ObjectiveSelected;
}


// ============================================================================
// GetPriorityAttackObjective
//
// Finds the objective that should be attacked. Selects the objective where
// most players can be released with the least required amount of attacking
// players. If no objective currently requires attackers, selects the
// objective that currently has the smallest number of them.
// ============================================================================

function GameObjective GetPriorityAttackObjective()
{
  local int nPlayersCurrent;
  local int nPlayersCurrentMin;
  local int nPlayersReleasable;
  local int nPlayersReleasableMax;
  local int nPlayersSuggested;
  local int nPlayersSuggestedMin;
  local GameObjective thisObjective;
  local GameObjective ObjectiveSelected;

  for (thisObjective = Objectives; thisObjective != None; thisObjective = thisObjective.NextObjective)
    if (IsObjectiveAttack(thisObjective)) {
      nPlayersSuggested = SuggestStrengthAttack(thisObjective);
      if (nPlayersSuggested == 0)
        continue;

      if (ObjectiveSelected == None || nPlayersSuggested <= nPlayersSuggestedMin) {
        nPlayersReleasable = CountPlayersReleasable(thisObjective);
        if (ObjectiveSelected == None || nPlayersReleasable >= nPlayersReleasableMax) {
          if (ObjectiveSelected != None &&
              nPlayersSuggested  == nPlayersSuggestedMin &&
              nPlayersReleasable == nPlayersReleasableMax) {

            if (thisObjective.DefensePriority > ObjectiveSelected.DefensePriority) continue;
            if (thisObjective.DefensePriority < ObjectiveSelected.DefensePriority) break;

            if (Class'JBTagObjective'.Static.FindFor(thisObjective    ).GetRandomWeight() <
                Class'JBTagObjective'.Static.FindFor(ObjectiveSelected).GetRandomWeight())
              continue;
          }

          nPlayersSuggestedMin  = nPlayersSuggested;
          nPlayersReleasableMax = nPlayersReleasable;
          ObjectiveSelected = thisObjective;
        }
      }
    }

  if (ObjectiveSelected == None)
    for (thisObjective = Objectives; thisObjective != None; thisObjective = thisObjective.NextObjective)
      if (IsObjectiveAttack(thisObjective)) {
        nPlayersCurrent = CountPlayersAtObjective(thisObjective);
        if (ObjectiveSelected == None || nPlayersCurrent < nPlayersCurrentMin) {
          ObjectiveSelected = thisObjective;
          nPlayersCurrentMin = nPlayersCurrent;
        }
      }

  return ObjectiveSelected;
}


// ============================================================================
// GetPriorityFreelanceObjective
//
// Always returns None. The freelance squad in Jailbreak is always to roam the
// map more or less randomly. If a directed attack is required, bots are
// redistributed to different squads.
// ============================================================================

function GameObjective GetPriorityFreelanceObjective()
{
  return None;
}


// ============================================================================
// NotifySpawn
//
// Called after a player respawns. When an enemy spawns in freedom, dispatches
// a freelancing squad to the enemy's probable spawning point. Tells bots to
// resume their fixed orders if they have any. When an enemy spawns in jail,
// tells all bots to ignore him.
// ============================================================================

function NotifySpawn(Controller ControllerSpawned)
{
  local bool bIsOnSameTeam;
  local NavigationPoint NavigationPointGuessed;
  local SquadAI thisSquad;
  local JBTagPlayer TagPlayer;

  TagPlayer = Class'JBTagPlayer'.Static.FindFor(ControllerSpawned.PlayerReplicationInfo);
  if (TagPlayer == None)
    return;

  bIsOnSameTeam = (TagPlayer.GetTeam() == Team);

  if (TagPlayer.IsFree()) {
    if (bIsOnSameTeam) {
      if (Bot(ControllerSpawned) != None)
        ResumeBotOrders(Bot(ControllerSpawned));
    }
    else {
      NavigationPointGuessed = TagPlayer.GuessLocation(TagTeam[TagPlayer.GetTeam().TeamIndex].FindPlayerStarts());
      if (NavigationPointGuessed != None)
        SendSquadTo(NavigationPointGuessed, ControllerSpawned);
    }
  }
  else {
    if (bIsOnSameTeam) {
      if (TagPlayer.OrderNameFixed == 'Attack')
        SetOrders(Bot(ControllerSpawned), 'Freelance', None);
    }
    else {
      for (thisSquad = Squads; thisSquad != None; thisSquad = thisSquad.NextSquad)
        thisSquad.RemoveEnemy(ControllerSpawned.Pawn);
    }
  
    TagPlayer.RecordLocation(None);
  }
}


// ============================================================================
// NotifyReleaseTeam
//
// Called when a team is released. Resets all bots who were explicitly ordered
// to attack this objective to team tactics. Dispatches a freelancing squad to
// the objective where the release was probably caused from by the given enemy.
// ============================================================================

function NotifyReleaseTeam(name EventRelease, TeamInfo TeamReleased, Controller ControllerInstigator)
{
  local Bot BotAttacking;
  local GameObjective thisObjective;
  local GameObjective ObjectiveAttacked;
  local NavigationPoint NavigationPointGuessed;
  local array<NavigationPoint> ListNavigationPointSwitch;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  local JBTagPlayer TagPlayerInstigator;

  if (TeamReleased == Team) {
    firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
    for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
      if (thisTagPlayer.OrderNameFixed == 'Attack' &&
          thisTagPlayer.GetTeam() == TeamReleased) {
        BotAttacking = Bot(thisTagPlayer.GetController());
        if (BotAttacking != None) {
          ObjectiveAttacked = BotAttacking.Squad.SquadObjective;
          if (ObjectiveAttacked != None &&
              ObjectiveAttacked.Event == EventRelease)
            SetOrders(BotAttacking, 'Freelance', None);
        }
      }
  }

  if (ControllerInstigator == None ||
      Team == TeamReleased ||
      Team == ControllerInstigator.PlayerReplicationInfo.Team)
    return;

  TagPlayerInstigator = Class'JBTagPlayer'.Static.FindFor(ControllerInstigator.PlayerReplicationInfo);
  if (TagPlayerInstigator == None)
    return;

  for (thisObjective = Objectives; thisObjective != None; thisObjective = thisObjective.NextObjective)
    if (IsObjectiveDefense(thisObjective) && thisObjective.Event == EventRelease)
      ListNavigationPointSwitch[ListNavigationPointSwitch.Length] = thisObjective;

  NavigationPointGuessed = TagPlayerInstigator.GuessLocation(ListNavigationPointSwitch);

  if (NavigationPointGuessed != None)
    SendSquadTo(NavigationPointGuessed, ControllerInstigator);
}


// ============================================================================
// NotifyReleasePlayer
//
// Called when an individual player leaves jail. Dispatches a freelancing
// squad to the location where the enemy player probably left the jail.
// ============================================================================

function NotifyReleasePlayer(name EventRelease, Controller ControllerReleased)
{
  local int iNavigationPoint;
  local JBInfoJail firstJail;
  local JBInfoJail thisJail;
  local JBTagPlayer TagPlayerReleased;
  local NavigationPoint NavigationPointGuessed;
  local array<NavigationPoint> ListNavigationPointExitJail;
  local array<NavigationPoint> ListNavigationPointExitTotal;

  if (ControllerReleased.PlayerReplicationInfo.Team == Team) {
    if (Bot(ControllerReleased) != None && JBBotSquadJail(Bot(ControllerReleased).Squad) != None)
      ResumeBotOrders(Bot(ControllerReleased));
  }

  else {
    TagPlayerReleased = Class'JBTagPlayer'.Static.FindFor(ControllerReleased.PlayerReplicationInfo);
    if (TagPlayerReleased == None)
      return;

    firstJail = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstJail;
    for (thisJail = firstJail; thisJail != None; thisJail = thisJail.nextJail)
      if (thisJail.Tag == EventRelease) {
        ListNavigationPointExitJail = thisJail.FindExits();
        ListNavigationPointExitTotal.Insert(0, ListNavigationPointExitJail.Length);
        for (iNavigationPoint = 0; iNavigationPoint < ListNavigationPointExitJail.Length; iNavigationPoint++)
          ListNavigationPointExitTotal[iNavigationPoint] = ListNavigationPointExitJail[iNavigationPoint];
      }

    NavigationPointGuessed = TagPlayerReleased.GuessLocation(ListNavigationPointExitTotal);

    if (NavigationPointGuessed != None)
      SendSquadTo(NavigationPointGuessed, ControllerReleased);
  }
}


// ============================================================================
// state TacticsEvasive
//
// Evasive team tactics. Bots try not to get caught and flee at the sight of
// enemies if they can. Useful when a team is leading by a small margin
// shortly before the time limit is hit.
// ============================================================================

state TacticsEvasive {

  // ================================================================
  // ReAssessOrders
  //
  // Puts all bots that aren't bound in fixed orders to freelance
  // squads and then sets those squads to evasive tactics.
  // ================================================================

  function ReAssessOrders()
  {
    local SquadAI thisSquad;

    Explain("reassessing orders for TacticsEvasive:");
    ExplainBlockStart();
    Explain("ordering all bots to evade enemies on sight");

    DeployRestart();
    DeployExecute();  // set all unbound bots on freelance

    for (thisSquad = Squads; thisSquad != None; thisSquad = thisSquad.NextSquad)
      if (JBBotSquad(thisSquad) != None)
        JBBotSquad(thisSquad).StartEvasive();
  }


  // ================================================================
  // FindBotForArena
  //
  // Never let a bot volunteer for an arena fight.
  // ================================================================

  function Bot FindBotForArena(JBInfoArena Arena, Controller ControllerOpponent, optional float Ignored)
  {
    return None;
  }
  

  // ================================================================
  // EndState
  //
  // Resets all freelance squads to normal operation.
  // ================================================================

  event EndState()
  {
    local SquadAI thisSquad;

    for (thisSquad = Squads; thisSquad != None; thisSquad = thisSquad.NextSquad)
      if (JBBotSquad(thisSquad) != None)
        JBBotSquad(thisSquad).StopEvasive();
  }

} // state TacticsEvasive


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

  function ReAssessOrders()
  {
    local int nPlayersFree;
    local int nPlayersJailed;
    local int nPlayersAttacking;
    local int nPlayersDefending;
    local int nPlayersDefendingMax;
    local GameObjective thisObjective;
    local GameObjective ObjectiveAttack;

    nPlayersFree   = TagTeamSelf.CountPlayersFree();
    nPlayersJailed = TagTeamSelf.CountPlayersJailed();

    ExplainHeader();
    Explain("assessing defense:");
    ExplainBlockStart();

    for (thisObjective = Objectives; thisObjective != None; thisObjective = thisObjective.NextObjective)
      if (IsObjectiveDefense(thisObjective)) {
        nPlayersDefending = Max(2, SuggestStrengthDefense(thisObjective));
        nPlayersDefendingMax += nPlayersDefending;
        Explain("should defend" @ GetExplanationObjective(thisObjective) @ "with" @ nPlayersDefending @ "player(s)");
      }

    nPlayersDefending = Min(nPlayersDefending, nPlayersFree);
    ExplainBlockEnd();

    if (nPlayersJailed > 0) {
      ObjectiveAttack = GetPriorityAttackObjective();
      nPlayersAttacking = SuggestStrengthAttack(ObjectiveAttack);
      Explain("should attack" @ GetExplanationObjective(ObjectiveAttack) @ "with" @ nPlayersAttacking @ "player(s)");
    }

    if (nPlayersAttacking + nPlayersDefending > nPlayersFree)
      nPlayersAttacking = Max(0, nPlayersFree - nPlayersDefending);

    DeployToObjective(ObjectiveAttack, nPlayersAttacking);
    DeployToDefense(nPlayersDefending);
    DeployExecute();
  }


  // ================================================================
  // FindBotForArena
  //
  // Only let a bot volunteer for an arena fight if we are really
  // really sure he has good chances to win.
  // ================================================================

  function Bot FindBotForArena(JBInfoArena Arena, Controller ControllerOpponent, optional float Ignored)
  {
    return Global.FindBotForArena(Arena, ControllerOpponent, 2.0);
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

  function ReAssessOrders()
  {
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

    nPlayersFree   = TagTeamSelf.CountPlayersFree();
    nPlayersJailed = TagTeamSelf.CountPlayersJailed();

    ExplainHeader();
    Explain("assessing defense:");
    ExplainBlockStart();

    for (thisObjective = Objectives; thisObjective != None; thisObjective = thisObjective.NextObjective)
      if (IsObjectiveDefense(thisObjective)) {
        nPlayersDefending = Max(1, SuggestStrengthDefense(thisObjective));
        nPlayersDefendingMax += nPlayersDefending;
        if (nPlayersDefendingMin == 0 ||
            nPlayersDefendingMin > nPlayersDefending)
          nPlayersDefendingMin = nPlayersDefending;
        Explain("should defend" @ GetExplanationObjective(thisObjective) @ "with" @ nPlayersDefending @ "player(s)");
      }

    ExplainBlockEnd();

    if (nPlayersJailed > 0) {
      ObjectiveAttack = GetPriorityAttackObjective();
      nPlayersAttacking = SuggestStrengthAttack(ObjectiveAttack);
      Explain("should attack" @ GetExplanationObjective(ObjectiveAttack) @ "with" @ nPlayersAttacking @ "player(s)");
    }

    nPlayersRequired = nPlayersAttacking + nPlayersDefendingMin;

    if (nPlayersRequired > nPlayersFree && nPlayersAttacking > 0) {
      Explain("require"  @ nPlayersRequired @ "player(s) for all orders," @
              "but only" @ nPlayersFree     @ "player(s) are free - concentrating defense");

      nPlayersDefending = Max(0, nPlayersFree - Abs(nPlayersDefendingMin - nPlayersAttacking) / 2.0 - 0.5);
      
      if (nPlayersDefending > 0 && nPlayersDefending <= nPlayersDefendingMin / 2) {
        Explain("require"  @ nPlayersDefendingMin @ "player(s) minimally for defense," @
                "but only" @ nPlayersDefending    @ "player(s) available - abandoning defense");
        nPlayersDefending = 0;  // no use defending
      }

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

      if (ObjectiveDefense != None)
        Explain("defense most urgently needed at" @ GetExplanationObjective(ObjectiveDefense));

      DeployToObjective(ObjectiveAttack,  nPlayersAttacking);
      DeployToObjective(ObjectiveDefense, nPlayersDefending);
      DeployExecute();
    }

    else {
      nPlayersDefending = Min(nPlayersFree - nPlayersAttacking, nPlayersDefendingMax);

      if (nPlayersAttacking > 0)  // attack with full force
        nPlayersAttacking = nPlayersFree - nPlayersDefending;

      DeployToObjective(ObjectiveAttack, nPlayersAttacking);
      DeployToDefense(nPlayersDefending);
      DeployExecute();  // rest goes on freelance
    }
  }


  // ================================================================
  // FindBotForArena
  //
  // Select a bot volunteer for an arena fight who is at least as
  // efficient as the selected opponent.
  // ================================================================

  function Bot FindBotForArena(JBInfoArena Arena, Controller ControllerOpponent, optional float Ignored)
  {
    return Global.FindBotForArena(Arena, ControllerOpponent, 1.0);
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

  function ReAssessOrders()
  {
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

    nPlayersFree   = TagTeamSelf.CountPlayersFree();
    nPlayersJailed = TagTeamSelf.CountPlayersJailed();

    ExplainHeader();
    Explain("assessing defense:");
    ExplainBlockStart();

    for (thisObjective = Objectives; thisObjective != None; thisObjective = thisObjective.NextObjective)
      if (IsObjectiveDefense(thisObjective)) {
        nPlayersDefending = SuggestStrengthDefense(thisObjective);
        nPlayersDefendingMax += nPlayersDefending;
        if (nPlayersDefendingMin == 0 ||
            nPlayersDefendingMin > nPlayersDefending)
          nPlayersDefendingMin = nPlayersDefending;
        Explain("should defend" @ GetExplanationObjective(thisObjective) @ "with" @ nPlayersDefending @ "player(s)");
      }

    ExplainBlockEnd();

    if (nPlayersJailed > 0) {
      ObjectiveAttack = GetPriorityAttackObjective();
      nPlayersAttacking = SuggestStrengthAttack(ObjectiveAttack);
      Explain("should attack" @ GetExplanationObjective(ObjectiveAttack) @ "with" @ nPlayersAttacking @ "player(s)");
    }

    if (nPlayersAttacking + nPlayersDefendingMax <= nPlayersFree) {
      Explain("enough free players to fulfull all orders");
      
      DeployToObjective(ObjectiveAttack, nPlayersAttacking);
      DeployToDefense(nPlayersDefendingMax);
      DeployExecute();  // rest go on freelance
    }

    else if (nPlayersAttacking + nPlayersDefendingMin / 2 <= nPlayersFree) {
      Explain("require"  @ nPlayersDefendingMin             @ "player(s) for defense," @
              "but only" @ nPlayersFree - nPlayersAttacking @ "player(s) available - concentrating defense");
    
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

      if (ObjectiveDefense != None)
        Explain("defense most urgently needed at" @ GetExplanationObjective(ObjectiveDefense));

      DeployToObjective(ObjectiveAttack,  nPlayersAttacking);
      DeployToObjective(ObjectiveDefense, nPlayersDefending);
      DeployExecute();
    }

    else {
      Explain("require"  @ nPlayersDefendingMin             @ "player(s) minimally for defense," @
              "but only" @ nPlayersFree - nPlayersAttacking @ "player(s) available - abandoning defense");
    
      DeployToObjective(ObjectiveAttack, nPlayersFree);
      DeployExecute();
    }
  }


  // ================================================================
  // FindBotForArena
  //
  // Select a bot volunteer for an arena fight even if the opponent
  // is much more efficient.
  // ================================================================

  function Bot FindBotForArena(JBInfoArena Arena, Controller ControllerOpponent, optional float Ignored)
  {
    return Global.FindBotForArena(Arena, ControllerOpponent, 0.5);
  }
  
} // state TacticsAggressive


// ============================================================================
// state TacticsSuicidal
//
// Suicidal team tactics. In disregard to their own safety and their base's
// defense, all bots either attack to release their teammates or roam the map
// to kill everything.
// ============================================================================

state TacticsSuicidal {

  // ================================================================
  // ReAssessOrders
  //
  // If a jail requires attack, sends all free players to attack it.
  // Otherwise sets all free players to freelance.
  // ================================================================

  function ReAssessOrders()
  {
    local int nPlayersFree;
    local int nPlayersJailed;
    local GameObjective ObjectiveAttack;

    nPlayersFree   = TagTeamSelf.CountPlayersFree();
    nPlayersJailed = TagTeamSelf.CountPlayersJailed();

    ExplainHeader();

    if (nPlayersJailed == 0) {
      Explain("nobody jailed, putting all players on freelance");
      DeployRestart();
      DeployExecute();  // all on freelance
    }
    else {
      ObjectiveAttack = GetPriorityAttackObjective();
      Explain("attacking" @ GetExplanationObjective(ObjectiveAttack) @ "with full force");
      DeployToObjective(ObjectiveAttack, nPlayersFree);
      DeployExecute();
    }
  }


  // ================================================================
  // FindBotForArena
  //
  // Find a bot volunteer at all costs. Hey, we're suicidal.
  // ================================================================

  function Bot FindBotForArena(JBInfoArena Arena, Controller ControllerOpponent, optional float Ignored)
  {
    return Global.FindBotForArena(Arena, ControllerOpponent, 0.001);
  }

} // state TacticsSuicidal


// ============================================================================
// Explain
//
// Used for debugging. Timestamps the given message and writes it to the log
// or to the screen if so configured.
// ============================================================================

function Explain(string Text)
{
  local int iExplanation;

  if (!bExplainToLog &&
      !bExplainToScreen)
    return;

  if (TimeExplanation != Level.TimeSeconds)
    IndentExplanation = "";

  if (bExplainToScreen) {
    if (!bIsExplanationInitialized) {
      JBInterfaceHud(Level.GetLocalPlayerController().myHUD).RegisterOverlay(Self);
      bIsExplanationInitialized = True;
    }
  
    if (ListExplanation.Length > 100)
      ListExplanation.Remove(1, ListExplanation.Length - 100);
  
    iExplanation = ListExplanation.Length;
    ListExplanation.Insert(iExplanation, 1);
    ListExplanation[iExplanation].Text = IndentExplanation $ Text;

    if (iExplanation > 0)
      if (TimeExplanation != Level.TimeSeconds)
             ListExplanation[iExplanation].bIsShaded = !ListExplanation[iExplanation - 1].bIsShaded;
        else ListExplanation[iExplanation].bIsShaded =  ListExplanation[iExplanation - 1].bIsShaded;
  }

  if (bExplainToLog) {
    if (TimeExplanation != Level.TimeSeconds)
      Log("---" @ Level.TimeSeconds, 'BotThoughts');
    Log("Team" @ Team.TeamIndex $ ":" @ IndentExplanation $ Text, 'BotThoughts');
  }

  TimeExplanation = Level.TimeSeconds;
}


// ============================================================================
// RenderOverlays
//
// Renders the current list of explanations on the screen.
// ============================================================================

function RenderOverlays(Canvas Canvas)
{
  local int iExplanation;
  local int ClipXPrev;
  local vector LocationText;
  local vector LocationTextMin;
  local Color ColorBase;
  local Color ColorShaded;
  
  if (!bExplainToScreen)
    return;
  
  ClipXPrev = Canvas.ClipX;
  
  switch (Team.TeamIndex) {
    case 0:  ColorBase = Canvas.MakeColor(255, 0, 0);  LocationText.X = 0;  Canvas.ClipX /= 2;   break;
    case 1:  ColorBase = Canvas.MakeColor(0, 0, 255);  LocationText.X = int(Canvas.ClipX /  2);  break;
  }

  LocationText   .Y = int(Canvas.ClipY * 0.75);
  LocationTextMin.Y = int(Canvas.ClipY * 0.15);

  Canvas.Style = ERenderStyle.STY_Alpha;
  Canvas.Font = Font'DefaultFont';

  Canvas.SetDrawColor(0, 0, 0, 128);
  Canvas.SetPos(LocationText.X, LocationTextMin.Y);
  Canvas.DrawRect(Texture'BlackTexture', Canvas.ClipX - LocationText.X, LocationText.Y - LocationTextMin.Y + 3);

  for (iExplanation = ListExplanation.Length - 1; iExplanation >= 0; iExplanation--) {
    LocationText.Y -= 6;
    if (LocationText.Y < LocationTextMin.Y)
      break;

    if (ListExplanation[iExplanation].bIsShaded)
           ColorShaded = ColorBase * 0.75;
      else ColorShaded = ColorBase;
  
    Canvas.DrawColor = ColorShaded;
    Canvas.SetPos(LocationText.X, LocationText.Y);
    Canvas.DrawTextClipped(ListExplanation[iExplanation].Text);
  }

  Canvas.ClipX = ClipXPrev;
}


// ============================================================================
// ExplainHeader
//
// Outputs the explanation header for the current tactics.
// ============================================================================

function ExplainHeader()
{
  local string ExplanationPlayer;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;

  if (!bExplainToLog &&
      !bExplainToScreen)
    return;

  Explain("reassessing orders for" @ GetStateName() $ ":");
  ExplainBlockStart();

  Explain("current team status:");
  ExplainBlockStart();

  firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    if (thisTagPlayer.GetTeam() == Team) {
      ExplanationPlayer = GetExplanationPlayer(thisTagPlayer.GetController());
           if (thisTagPlayer.IsInArena()) Explain("arena: " @ ExplanationPlayer @ "in" @ thisTagPlayer.GetArena().Tag);
      else if (thisTagPlayer.IsInJail())  Explain("jailed:" @ ExplanationPlayer @ "in" @ thisTagPlayer.GetJail() .Tag);
      else                                Explain("free:  " @ ExplanationPlayer @ GetExplanationOrders(thisTagPlayer.GetController()));
    }
  
  ExplainBlockEnd();
}


// ============================================================================
// ExplainBlockStart
//
// Starts an indented explanation block.
// ============================================================================

function ExplainBlockStart()
{
  IndentExplanation = IndentExplanation $ "  ";
}


// ============================================================================
// ExplainBlockEnd
//
// Ends an indented explanation block.
// ============================================================================

function ExplainBlockEnd()
{
  if (Len(IndentExplanation) >= 2)
    IndentExplanation = Left(IndentExplanation, Len(IndentExplanation) - 2);
}


// ============================================================================
// GetExplanationObjective
//
// Returns a human-readable explanation for the given objective.
// ============================================================================

function string GetExplanationObjective(GameObjective GameObjective)
{
  local string Result;

  if (!bExplainToLog &&
      !bExplainToScreen)
    return "(disabled)";

  if (GameObjective == None)
    return "freelancing";

  if (GameObjective.ObjectiveName != GameObjective.Default.ObjectiveName)
         Result = GameObjective.ObjectiveName;
    else Result = "switch";
  
  if (GameObjective.Region.Zone.LocationName != GameObjective.Region.Zone.Default.LocationName)
    Result = Result @ "in" @ GameObjective.Region.Zone.LocationName;
  
  if (GameObjective.DefenderTeamIndex == Team.TeamIndex)
         Result = Result @ "(own base)";
    else Result = Result @ "(enemy base)";

  return Result;
}


// ============================================================================
// GetExplanationPlayer
//
// Returns a human-readable explanation for the given player or bot.
// ============================================================================

function string GetExplanationPlayer(Controller Controller)
{
  if (!bExplainToLog &&
      !bExplainToScreen)
    return "(disabled)";

  if (Controller.PlayerReplicationInfo != None)
         if (PlayerController(Controller) != None) return Controller.PlayerReplicationInfo.PlayerName @ "(human)";
    else if (Bot             (Controller) != None) return Controller.PlayerReplicationInfo.PlayerName @ "(bot)";
  
  return "unnamed" @ Controller.Class.Name;
}


// ============================================================================
// GetExplanationOrders
//
// Returns a human-readable string explaining the given player's orders.
// ============================================================================

function string GetExplanationOrders(Controller Controller)
{
  local string Result;
  local GameObjective GameObjective;
  local JBTagPlayer TagPlayer;

  if (!bExplainToLog &&
      !bExplainToScreen)
    return "(disabled)";

  TagPlayer = Class'JBTagPlayer'.Static.FindFor(Controller.PlayerReplicationInfo);

  if (Bot(Controller) != None && Bot(Controller).Squad != None)
         GameObjective = Bot(Controller).Squad.SquadObjective;
    else GameObjective = TagPlayer.GuessObjective();

       if (IsObjectiveAttack (GameObjective)) Result = "attacking" @ GetExplanationObjective(GameObjective);
  else if (IsObjectiveDefense(GameObjective)) Result = "defending" @ GetExplanationObjective(GameObjective);
  else                                        Result = "freelancing";

  if (TagPlayer.OrderNameFixed != '')
    Result = Result @ "(fixed orders)";

  return Result;
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  bTacticsAuto = True;

  ClassSquadArena = Class'JBBotSquadArena';
  ClassSquadJail  = Class'JBBotSquadJail';

  SquadType = Class'JBBotSquad';
}