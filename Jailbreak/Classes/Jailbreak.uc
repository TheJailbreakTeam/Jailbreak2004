// ============================================================================
// Jailbreak
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: Jailbreak.uc,v 1.50 2003/06/06 07:57:20 mychaeel Exp $
//
// Jailbreak game type.
// ============================================================================


class Jailbreak extends xTeamGame
  notplaceable;


// ============================================================================
// Configuration
// ============================================================================

var string Build;

var config bool bEnableJailFights;
var config bool bEnableSpectatorDeathCam;


// ============================================================================
// Variables
// ============================================================================

var JBGameRules firstJBGameRules;                // game rules chain
var private JBTagPlayer firstTagPlayerInactive;  // disconnected player chain

var private float TimeExecution;         // time for pending execution
var private float TimeRestart;           // time for pending round restart
var private float DilationTimePrev;      // last synchronized time dilation
var private JBCamera CameraExecution;    // camera for execution sequence

var private float TimeEventFired;        // time of last fired singular event
var private array<name> ListEventFired;  // singular events fired this tick

var private transient JBTagPlayer TagPlayerRestart;  // player being restarted


// ============================================================================
// InitGame
//
// Initializes the game.
// ============================================================================

event InitGame(string Options, out string Error) {

  Super.InitGame(Options, Error);
  
  bForceRespawn = True;
  MaxLives = 0;
  }


// ============================================================================
// PostBeginPlay
//
// Spawns JBTagTeam actors for both teams.
// ============================================================================

event PostBeginPlay() {

  Super.PostBeginPlay();
  
  Class'JBTagTeam'.Static.SpawnFor(Teams[0]);
  Class'JBTagTeam'.Static.SpawnFor(Teams[1]);
  }


// ============================================================================
// Login
//
// Gives every player new JBTagPlayer and JBTagClient actors.
// ============================================================================

event PlayerController Login(string Portal, string Options, out string Error) {

  local PlayerController PlayerLogin;
  local JBTagPlayer thisTagPlayer;
  local JBTagPlayer TagPlayerLogin;
  
  PlayerLogin = Super.Login(Portal, Options, Error);
  
  if (PlayerLogin                            != None &&
      PlayerLogin.PlayerReplicationInfo      != None &&
      PlayerLogin.PlayerReplicationInfo.Team != None) {

    for (thisTagPlayer = firstTagPlayerInactive; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
      if (thisTagPlayer.BelongsTo(PlayerLogin))
        break;

    if (thisTagPlayer != None) {
      TagPlayerLogin = thisTagPlayer;

      if (firstTagPlayerInactive == TagPlayerLogin)
        firstTagPlayerInactive = firstTagPlayerInactive.nextTag;
      else
        for (thisTagPlayer = firstTagPlayerInactive; thisTagPlayer.nextTag != None; thisTagPlayer = thisTagPlayer.nextTag)
          if (thisTagPlayer.nextTag == TagPlayerLogin)
            thisTagPlayer.nextTag = TagPlayerLogin.nextTag;
      
      TagPlayerLogin.SetOwner(PlayerLogin.PlayerReplicationInfo);
      TagPlayerLogin.Register();
      }

    else {
      Class'JBTagPlayer'.Static.SpawnFor(PlayerLogin.PlayerReplicationInfo);
      }
    }
  
  Class'JBTagClient'.Static.SpawnFor(PlayerLogin);
  
  return PlayerLogin;
  }


// ============================================================================
// SpawnBot
//
// Gives every new bot a JBTagPlayer actor and fills the OrderNames slots used
// for the custom team tactics submenu of the speech menu.
// ============================================================================

function Bot SpawnBot(optional string NameBot) {

  local int iOrderNameTactics;
  local Bot BotSpawned;
  local JBGameReplicationInfo InfoGame;
  
  BotSpawned = Super.SpawnBot(NameBot);
  if (BotSpawned == None)
    return None;

  Class'JBTagPlayer'.Static.SpawnFor(BotSpawned.PlayerReplicationInfo);
  
  InfoGame = JBGameReplicationInfo(GameReplicationInfo);
  for (iOrderNameTactics = 0; iOrderNameTactics < ArrayCount(InfoGame.OrderNameTactics); iOrderNameTactics++)
    BotSpawned.OrderNames[InfoGame.OrderNameTactics[iOrderNameTactics].iOrderName] =
      InfoGame.OrderNameTactics[iOrderNameTactics].OrderName;
  
  return BotSpawned;
  }


// ============================================================================
// InitPlacedBot
//
// Only gives actual bots a team, as opposed to other scripted controllers.
// ============================================================================

function InitPlacedBot(Controller Controller, RosterEntry RosterEntry) {

  if (Bot(Controller) != None)
    Super.InitPlacedBot(Controller, RosterEntry);
  }


// ============================================================================
// Logout
//
// Destroys the JBTagPlayer and JBTagClient actors for the given player or bot
// if one exists. Reassesses the leaving player's team.
// ============================================================================

function Logout(Controller ControllerExiting) {

  local JBTagPlayer TagPlayerExiting;

  if (ControllerExiting.PlayerReplicationInfo != None)
    ReAssessTeam(ControllerExiting.PlayerReplicationInfo.Team);

  if (PlayerController(ControllerExiting) != None) {
    Class'JBTagClient'.Static.DestroyFor(PlayerController(ControllerExiting));

    TagPlayerExiting = Class'JBTagPlayer'.Static.FindFor(ControllerExiting.PlayerReplicationInfo);
    TagPlayerExiting.Unregister();

    TagPlayerExiting.nextTag = firstTagPlayerInactive;
    firstTagPlayerInactive = TagPlayerExiting;
    }

  else {
    Class'JBTagPlayer'.Static.DestroyFor(ControllerExiting.PlayerReplicationInfo);
    }

  Super.Logout(ControllerExiting);
  }


// ============================================================================
// ChangeTeam
//
// Changes the given player's team. Reassesses both teams involved in the
// change if it is successful.
// ============================================================================

function bool ChangeTeam(Controller ControllerPlayer, int iTeam, bool bNewTeam) {

  local TeamInfo TeamBefore;
  
  if (ControllerPlayer.PlayerReplicationInfo != None)
    TeamBefore = ControllerPlayer.PlayerReplicationInfo.Team;

  if (Super.ChangeTeam(ControllerPlayer, iTeam, bNewTeam)) {
    ReAssessTeam(TeamBefore);
    ReAssessTeam(ControllerPlayer.PlayerReplicationInfo.Team);
    return True;
    }

  return False;
  }


// ============================================================================
// ReAssessTeam
//
// If all members of the given team are bots, sets its team tactics to auto.
// ============================================================================

function ReAssessTeam(TeamInfo Team) {

  local Controller thisController;
  
  if (Team == None)
    return;
  
  for (thisController = Level.ControllerList; thisController != None; thisController = thisController.NextController)
    if (PlayerController(thisController)     != None &&
        thisController.PlayerReplicationInfo != None &&
        thisController.PlayerReplicationInfo.Team == Team)
      return;

  JBBotTeam(UnrealTeamInfo(Team).AI).SetTactics('Auto');
  }


// ============================================================================
// AddJBGameRules
//
// Adds a new JBGameRules actor. Multiple JBGameRules actors can be chained.
// ============================================================================

function AddJBGameRules(JBGameRules JBGameRules) {

  if (firstJBGameRules == None)
    firstJBGameRules = JBGameRules;
  else
    firstJBGameRules.AddJBGameRules(JBGameRules);
  }


// ============================================================================
// FindPlayerStart
//
// Finds out where the restarted player should be spawned at and communicates
// it to the RatePlayerStart function.
// ============================================================================

function NavigationPoint FindPlayerStart(Controller Controller, optional byte iTeam, optional string Teleporter) {

  if (Controller == None)
    TagPlayerRestart = None;
  else
    TagPlayerRestart = Class'JBTagPlayer'.Static.FindFor(Controller.PlayerReplicationInfo);
  
  return Super.FindPlayerStart(Controller, iTeam, Teleporter);
  }


// ============================================================================
// RatePlayerStart
//
// Returns a negative value for all starts that are inappropriate for the
// given player's scheduled respawn area.
// ============================================================================

function float RatePlayerStart(NavigationPoint NavigationPoint, byte iTeam, Controller Controller) {

  if (TagPlayerRestart == None)
    if (ContainsActorJail (NavigationPoint) ||
        ContainsActorArena(NavigationPoint))
      return -20000000;
    else
      return Super.RatePlayerStart(NavigationPoint, iTeam, Controller);

  if (TagPlayerRestart.IsValidStart(NavigationPoint))
    return Super.RatePlayerStart(NavigationPoint, iTeam, Controller);
  else
    return -20000000;
  }


// ============================================================================
// AddGameSpecificInventory
//
// Adds game-specific inventory. Skips the translocator if the player has
// restarted in jail.
// ============================================================================

function AddGameSpecificInventory(Pawn PawnPlayer) {

  local bool bAllowTransPrev;
  local JBTagPlayer TagPlayer;

  bAllowTransPrev = bAllowTrans;

  TagPlayer = Class'JBTagPlayer'.Static.FindFor(PawnPlayer.PlayerReplicationInfo);
  if (TagPlayer != None && TagPlayer.IsInJail())
    bAllowTrans = False;

  Super.AddGameSpecificInventory(PawnPlayer);
  
  bAllowTrans = bAllowTransPrev;
  }


// ============================================================================
// ReduceDamage
//
// Applies several rules on who may inflict damage on whom:
//
//   * Players in an arena cannot be damaged by anyone except themselves and
//     their opponents.
//
//   * Players in jail can damage anybody, but not players in the same jail
//     unless they both are currently engaged in a jail fight. In that case
//     they get full damage regardless of current friendly fire settings.
//
// ============================================================================

function int ReduceDamage(int Damage, Pawn PawnVictim, Pawn PawnInstigator, vector LocationHit, out vector MomentumHit,
                          Class<DamageType> ClassDamageType) {

  local JBTagPlayer TagPlayerInstigator;
  local JBTagPlayer TagPlayerVictim;

  if (PawnInstigator == None ||
      PawnInstigator.Controller == PawnVictim.Controller)
    return Super.ReduceDamage(Damage, PawnVictim, PawnInstigator, LocationHit, MomentumHit, ClassDamageType);

  TagPlayerInstigator = Class'JBTagPlayer'.Static.FindFor(PawnInstigator.PlayerReplicationInfo);
  TagPlayerVictim     = Class'JBTagPlayer'.Static.FindFor(PawnVictim    .PlayerReplicationInfo);

  if (TagPlayerInstigator == None ||
      TagPlayerVictim     == None)
    return Super.ReduceDamage(Damage, PawnVictim, PawnInstigator, LocationHit, MomentumHit, ClassDamageType);

  if (TagPlayerVictim.GetArena() != TagPlayerInstigator.GetArena()) {
    MomentumHit = vect(0,0,0);
    return 0;
    }

  if (TagPlayerVictim.IsInJail() &&
      TagPlayerVictim.GetJail() == TagPlayerInstigator.GetJail())
    if (bEnableJailFights &&
        Class'JBBotSquadJail'.Static.IsPlayerFighting(TagPlayerInstigator.GetController()) &&
        Class'JBBotSquadJail'.Static.IsPlayerFighting(TagPlayerVictim    .GetController()))
      return Damage;
    else
      return 0;

  return Super.ReduceDamage(Damage, PawnVictim, PawnInstigator, LocationHit, MomentumHit, ClassDamageType);
  }


// ============================================================================
// Killed
//
// Sets the killed player's restart time with a short delay for effect.
// ============================================================================

function Killed(Controller ControllerKiller, Controller ControllerVictim, Pawn PawnVictim,
                Class<DamageType> ClassDamageType) {

  local JBTagPlayer TagPlayerVictim;
  
  if (ControllerVictim != None)
    TagPlayerVictim = Class'JBTagPlayer'.Static.FindFor(ControllerVictim.PlayerReplicationInfo);
  if (TagPlayerVictim != None)
    TagPlayerVictim.TimeRestart = Level.TimeSeconds + 2.0;
  
  Super.Killed(ControllerKiller, ControllerVictim, PawnVictim, ClassDamageType);
  }


// ============================================================================
// ScoreKill
//
// Translates kills into ScorePlayer calls according to Jailbreak rules.
// ============================================================================

function ScoreKill(Controller ControllerKiller, Controller ControllerVictim) {

  local float DistanceRelease;
  local float DistanceReleaseMin;
  local JBTagObjective firstTagObjective;
  local JBTagObjective thisTagObjective;
  local JBTagPlayer TagPlayerVictim;

  if (GameRulesModifiers != None)
    GameRulesModifiers.ScoreKill(ControllerKiller, ControllerVictim);

  ScoreKillAdjust(ControllerKiller, ControllerVictim);
  ScoreKillTaunt (ControllerKiller, ControllerVictim);

  TagPlayerVictim = Class'JBTagPlayer'.Static.FindFor(ControllerVictim.PlayerReplicationInfo);
  if (TagPlayerVictim != None &&
      TagPlayerVictim.IsInJail())
    return;

  if (ControllerKiller == None ||
      ControllerKiller == ControllerVictim)
    ScorePlayer(ControllerVictim, 'Suicide');
  
  else if (SameTeam(ControllerKiller, ControllerVictim))
    ScorePlayer(ControllerKiller, 'Teamkill');

  else {
    DistanceReleaseMin = -1.0;
  
    firstTagObjective = JBGameReplicationInfo(GameReplicationInfo).firstTagObjective;
    for (thisTagObjective = firstTagObjective; thisTagObjective != None; thisTagObjective = thisTagObjective.nextTag) {
      DistanceRelease = VSize(thisTagObjective.GetObjective().Location - ControllerVictim.Pawn.Location);
      if (DistanceReleaseMin < 0.0 ||
          DistanceReleaseMin > DistanceRelease)
        DistanceReleaseMin = DistanceRelease;
      }
  
    if (DistanceRelease < 1024.0)
      ScorePlayer(ControllerKiller, 'Defense');
    else
      ScorePlayer(ControllerKiller, 'Attack');
    
    ControllerKiller.PlayerReplicationInfo.Kills  += 1;
    ControllerVictim.PlayerReplicationInfo.Deaths += 1;
    }
  }


// ============================================================================
// ScoreKillAdjust
//
// Performs bot skill adjustments as implemented in ScoreKill in DeathMatch.
// ============================================================================

function ScoreKillAdjust(Controller ControllerKiller, Controller ControllerVictim) {

  if (bAdjustSkill) {
    if (AIController(ControllerKiller) != None && PlayerController(ControllerVictim) != None)
      AdjustSkill(AIController(ControllerKiller), PlayerController(ControllerVictim), True);
    if (AIController(ControllerVictim) != None && PlayerController(ControllerKiller) != None)
      AdjustSkill(AIController(ControllerVictim), PlayerController(ControllerKiller), False);
    }
  }


// ============================================================================
// ScoreKillTaunt
//
// Performs auto-taunts as implemented in ScoreKill in DeathMatch.
// ============================================================================

function ScoreKillTaunt(Controller ControllerKiller, Controller ControllerVictim) {

  local bool bNoHumanOnly;

  if (bAllowTaunts &&
      ControllerKiller != None &&
      ControllerKiller != ControllerVictim &&
      ControllerKiller.AutoTaunt() && 
      ControllerKiller.PlayerReplicationInfo.VoiceType != None) {

    bNoHumanOnly = PlayerController(ControllerKiller) == None;

    ControllerKiller.SendMessage(
      ControllerVictim.PlayerReplicationInfo, 'AutoTaunt',
      ControllerKiller.PlayerReplicationInfo.VoiceType.Static.PickRandomTauntFor(ControllerKiller, False, bNoHumanOnly),
      10, 'Global');
    }
  }


// ============================================================================
// ScorePlayer
//
// Adds points to the given player's score according to the given game event.
// ============================================================================

function ScorePlayer(Controller Controller, name Event) {

  local JBTagPlayer TagPlayer;

  TagPlayer = Class'JBTagPlayer'.Static.FindFor(Controller.PlayerReplicationInfo);
  if (TagPlayer == None)
    return;

  switch (Event) {
    case 'Suicide':   ScoreObjective(Controller.PlayerReplicationInfo, -1);  break;
    case 'Teamkill':  ScoreObjective(Controller.PlayerReplicationInfo, -1);  break;
    case 'Attack':    ScoreObjective(Controller.PlayerReplicationInfo, +1);  TagPlayer.ScorePartialAttack  += 1;  break;
    case 'Defense':   ScoreObjective(Controller.PlayerReplicationInfo, +2);  TagPlayer.ScorePartialDefense += 1;  break;
    case 'Release':   ScoreObjective(Controller.PlayerReplicationInfo, +1);  TagPlayer.ScorePartialRelease += 1;  break;
    case 'Capture':   ScoreObjective(Controller.PlayerReplicationInfo, +1);  break;
    }

  switch (Event) {
    case 'Defense':   Controller.AwardAdrenaline(ADR_MinorBonus);  break;
    case 'Release':   Controller.AwardAdrenaline(ADR_MinorBonus);  break;
    case 'Capture':   Controller.AwardAdrenaline(ADR_MinorBonus);  break;
    }
  }


// ============================================================================
// BroadcastDeathMessage
//
// Broadcasts death messages concerning suicides or kills in jail only to all
// jailed players of that team.
// ============================================================================

function BroadcastDeathMessage(Controller ControllerKiller, Controller ControllerVictim, Class<DamageType> DamageType) {

  local int SwitchMessage;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  local JBTagPlayer TagPlayerKiller;
  local JBTagPlayer TagPlayerVictim;
  local PlayerReplicationInfo PlayerReplicationInfoKiller;
  local PlayerReplicationInfo PlayerReplicationInfoVictim;

  if (ControllerKiller != None)
    TagPlayerKiller = Class'JBTagPlayer'.Static.FindFor(ControllerKiller.PlayerReplicationInfo);
  TagPlayerVictim = Class'JBTagPlayer'.Static.FindFor(ControllerVictim.PlayerReplicationInfo);

  if (TagPlayerVictim.IsInJail() &&
      (TagPlayerKiller == None ||
       TagPlayerKiller.IsInJail())) {

    if (ControllerKiller != None)
      PlayerReplicationInfoKiller = ControllerKiller.PlayerReplicationInfo;
    PlayerReplicationInfoVictim = ControllerVictim.PlayerReplicationInfo;

    if (ControllerKiller == None ||
        ControllerKiller == ControllerVictim)
      SwitchMessage = 1;  // suicide
    else
      SwitchMessage = 0;  // homicide

    firstTagPlayer = JBGameReplicationInfo(GameReplicationInfo).firstTagPlayer;
    for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
      if (thisTagPlayer.GetJail() == TagPlayerVictim.GetJail() &&
          PlayerController(thisTagPlayer.GetController()) != None)
        BroadcastHandler.BroadcastLocalized(
          Self,
          PlayerController(thisTagPlayer.GetController()),
          DeathMessageClass,
          SwitchMessage,
          PlayerReplicationInfoKiller,
          PlayerReplicationInfoVictim,
          DamageType);
    }
  
  else {
    Super.BroadcastDeathMessage(ControllerKiller, ControllerVictim, DamageType);
    }
  }


// ============================================================================
// CanSpectate
//
// Checks and returns whether the given player can spectate from the given new
// view target. Only allows players to spectate other actual players.
// ============================================================================

function bool CanSpectate(PlayerController PlayerViewer, bool bOnlySpectator, Actor ViewTarget) {

  if (Pawn(ViewTarget) != None &&
      Class'JBTagPlayer'.Static.FindFor(Pawn(ViewTarget).PlayerReplicationInfo) == None)
    return False;
  
  return Super.CanSpectate(PlayerViewer, bOnlySpectator, ViewTarget);
  }


// ============================================================================
// CanFireEvent
//
// Checks whether the given event has been fired already within this tick and
// returns True if not, False otherwise. Thus makes sure that certain events
// are only fired once per tick.
// ============================================================================

function bool CanFireEvent(name EventFire, optional bool bFire) {

  local int iEventFired;
  
  if (TimeEventFired < Level.TimeSeconds)
    ListEventFired.Length = 0;
  
  for (iEventFired = 0; iEventFired < ListEventFired.Length; iEventFired++)
    if (ListEventFired[iEventFired] == EventFire)
      return False;
  
  if (bFire) {
    ListEventFired[ListEventFired.Length] = EventFire;
    TimeEventFired = Level.TimeSeconds;
    }
  
  return True;
  }


// ============================================================================
// ContainsActorJail
//
// Iterates over all jails and returns whether one of them contains the given
// actor (and optionally which of them).
// ============================================================================

function bool ContainsActorJail(Actor Actor, optional out JBInfoJail Jail) {

  local JBInfoJail firstJail;

  firstJail = JBGameReplicationInfo(GameReplicationInfo).firstJail;
  for (Jail = firstJail; Jail != None; Jail = Jail.nextJail)
    if (Jail.ContainsActor(Actor))
      return True;

  return False;
  }


// ============================================================================
// ContainsActorArena
//
// Iterates over all arenas and returns whether one of them contains the given
// actor (and optionally which of them).
// ============================================================================

function bool ContainsActorArena(Actor Actor, optional out JBInfoArena Arena) {

  local JBInfoArena firstArena;
  
  firstArena = JBGameReplicationInfo(GameReplicationInfo).firstArena;
  for (Arena = firstArena; Arena != None; Arena = Arena.nextArena)
    if (Arena.ContainsActor(Actor))
      return True;

  return False;
  }


// ============================================================================
// CountPlayersJailed
//
// Forwarded to CountPlayersJailed in JBTagTeam.
// ============================================================================

function int CountPlayersJailed(TeamInfo Team) {

  return Class'JBTagTeam'.Static.FindFor(Team).CountPlayersJailed();
  }


// ============================================================================
// CountPlayersTotal
//
// Forwarded to CountPlayersTotal in JBTagTeam.
// ============================================================================

function int CountPlayersTotal(TeamInfo Team) {

  return Class'JBTagTeam'.Static.FindFor(Team).CountPlayersTotal();
  }


// ============================================================================
// IsCaptured
//
// Returns whether the given team has been captured.
// ============================================================================

function bool IsCaptured(TeamInfo Team) {

  if (CountPlayersTotal(Team) == 0)
    return False;

  return CountPlayersJailed(Team) == CountPlayersTotal(Team);
  }


// ============================================================================
// RateCameraExecution
//
// Rates the given camera in terms of a good view on an execution sequence.
// The higher the returned value, the better.
// ============================================================================

function int RateCameraExecution(JBCamera CameraExecution, TeamInfo TeamExecuted) {

  local int nPlayersJailed;
  local JBInfoJail firstJail;
  local JBInfoJail thisJail;
  
  firstJail = JBGameReplicationInfo(GameReplicationInfo).firstJail;
  for (thisJail = firstJail; thisJail != None; thisJail = thisJail.nextJail)
    if (thisJail.Event == CameraExecution.Tag)
      nPlayersJailed += thisJail.CountPlayers(TeamExecuted);
  
  return nPlayersJailed;
  }


// ============================================================================
// FindCameraExecution
//
// Finds the execution camera with the best view on the execution sequence.
// ============================================================================

function JBCamera FindCameraExecution(TeamInfo TeamExecuted) {

  local int RatingCamera;
  local int RatingCameraSelected;
  local int RatingCameraTotal;
  local array<int> ListRatingCamera;
  local JBCamera thisCamera;

  foreach DynamicActors(Class'JBCamera', thisCamera) {
    RatingCamera = RateCameraExecution(thisCamera, TeamExecuted);
    RatingCameraTotal += RatingCamera;
    ListRatingCamera[ListRatingCamera.Length] = RatingCamera;
    }
  
  if (RatingCameraTotal == 0)
    return None;
  
  RatingCameraSelected = Rand(RatingCameraTotal);
  RatingCameraTotal = 0;
  
  foreach DynamicActors(Class'JBCamera', thisCamera) {
    RatingCameraTotal += ListRatingCamera[0];
    if (RatingCameraSelected < RatingCameraTotal)
      return thisCamera;
    ListRatingCamera.Remove(0, 1);
    }
  
  return None;
  }


// ============================================================================
// RestartAll
//
// Restarts all players in freedom.
// ============================================================================

function RestartAll() {

  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  local JBTagPlayer nextTagPlayer;
  
  firstTagPlayer = JBGameReplicationInfo(GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = nextTagPlayer) {
    nextTagPlayer = thisTagPlayer.nextTag;
    thisTagPlayer.RestartInFreedom();
    }
  }


// ============================================================================
// RestartTeam
//
// Restarts all players of the given team in freedom.
// ============================================================================

function RestartTeam(TeamInfo Team) {

  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  local JBTagPlayer nextTagPlayer;
  
  firstTagPlayer = JBGameReplicationInfo(GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = nextTagPlayer) {
    nextTagPlayer = thisTagPlayer.nextTag;
    if (thisTagPlayer.GetTeam() == Team)
      thisTagPlayer.RestartInFreedom();
    }
  }


// ============================================================================
// IsReleaseActive
//
// Checks whether a release is active for the given team.
// ============================================================================

function bool IsReleaseActive(TeamInfo Team) {

  local JBInfoJail firstJail;
  local JBInfoJail thisJail;
  
  firstJail = JBGameReplicationInfo(GameReplicationInfo).firstJail;
  for (thisJail = firstJail; thisJail != None; thisJail = thisJail.nextJail)
    if (thisJail.IsReleaseActive(Team))
      return True;
  
  return False;
  }


// ============================================================================
// ExecutionInit
//
// Checks how many teams are captured. If none, fails. If more than one,
// announces a tie and starts a new round. If exactly one, respawns all other
// players in freedom, selects an execution camera and initiates execution.
// Can only be called in the default state.
// ============================================================================

function bool ExecutionInit() {

  local bool bFoundCaptured;
  local int iTeam;
  local int iTeamCaptured;
  
  if (IsInState('MatchInProgress')) {
    for (iTeam = 0; iTeam < ArrayCount(Teams); iTeam++)
      if (IsCaptured(Teams[iTeam])) {
        if (bFoundCaptured) {
          RestartAll();
          BroadcastLocalizedMessage(MessageClass, 300);
          JBGameReplicationInfo(GameReplicationInfo).AddCapture(ElapsedTime, None);
          return False;
          }
      
        bFoundCaptured = True;
        iTeamCaptured = iTeam;
        }
  
    if (!bFoundCaptured || IsReleaseActive(Teams[iTeamCaptured]))
      return False;
  
    ExecutionCommit(Teams[iTeamCaptured]);
    return True;
    }
  
  else {
    Log("Warning: Cannot initiate execution while in state" @ GetStateName());
    return False;
    }
  }


// ============================================================================
// ExecutionCommit
//
// Prepares and commits a team's execution. Respawns all other players, scores
// and announces the capture.
// ============================================================================

function ExecutionCommit(TeamInfo TeamExecuted) {

  local Controller thisController;
  local JBCamera thisCamera;
  local JBInfoJail firstJail;
  local JBInfoJail thisJail;
  local TeamInfo TeamCapturer;

  if (IsInState('MatchInProgress')) {
    GotoState('Executing');
    
    BroadcastLocalizedMessage(MessageClass, 100, , , TeamExecuted);
    JBGameReplicationInfo(GameReplicationInfo).AddCapture(ElapsedTime, TeamExecuted);
    
    for (thisController = Level.ControllerList; thisController != None; thisController = thisController.NextController)
      if (thisController.PlayerReplicationInfo != None &&
          thisController.PlayerReplicationInfo.Team != TeamExecuted)
        ScorePlayer(thisController, 'Capture');

    foreach DynamicActors(Class'JBCamera', thisCamera)
      thisCamera.DeactivateForAll();

    CameraExecution = FindCameraExecution(TeamExecuted);
    if (CameraExecution == None)
      Log("Warning: No execution camera found");
  
    if (bEnableSpectatorDeathCam && CameraExecution != None)
      for (thisController = Level.ControllerList; thisController != None; thisController = thisController.NextController)
        if (thisController.PlayerReplicationInfo != None &&
            thisController.PlayerReplicationInfo.bOnlySpectator)
          CameraExecution.ActivateFor(thisController);

    TeamCapturer = OtherTeam(TeamExecuted);
    TeamCapturer.Score += 1;
    RestartTeam(TeamCapturer);
    
    firstJail = JBGameReplicationInfo(GameReplicationInfo).firstJail;
    for (thisJail = firstJail; thisJail != None; thisJail = thisJail.nextJail)
      thisJail.ExecutionInit();

    if (firstJBGameRules != None)
      firstJBGameRules.NotifyExecutionCommit(TeamExecuted);
    }
  
  else {
    Log("Warning: Cannot commit execution while in state" @ GetStateName());
    }
  }


// ============================================================================
// ExecutionEnd
//
// Goes to the default state and restarts all players in the game in freedom.
// Can only be called in state Executing.
// ============================================================================

function ExecutionEnd() {

  local Controller thisController;
  local JBInfoJail firstJail;
  local JBInfoJail thisJail;

  if (IsInState('Executing')) {
    firstJail = JBGameReplicationInfo(GameReplicationInfo).firstJail;
    for (thisJail = firstJail; thisJail != None; thisJail = thisJail.nextJail)
      thisJail.ExecutionEnd();
  
    if (firstJBGameRules != None)
      firstJBGameRules.NotifyExecutionEnd();

    GotoState('MatchInProgress');
    RestartAll();

    if (bEnableSpectatorDeathCam && CameraExecution != None)
      for (thisController = Level.ControllerList; thisController != None; thisController = thisController.NextController)
        if (thisController.PlayerReplicationInfo != None &&
            thisController.PlayerReplicationInfo.bOnlySpectator)
          CameraExecution.DeactivateFor(thisController);

    if (Teams[0].Score >= GoalScore ||
        Teams[1].Score >= GoalScore)
      EndGame(None, "TeamScoreLimit");
    else if (bOverTime)
      EndGame(None, "TimeLimit");
    }
  
  else {
    Log("Warning: Cannot end execution while in state" @ GetStateName());
    }
  }


// ============================================================================
// state MatchInProgress
//
// Normal gameplay in progress.
// ============================================================================

state MatchInProgress {

  // ================================================================
  // BeginState
  //
  // Only calls the superclass function if this state is entered the
  // first time. Resets the orders for all bots, and restarts the
  // client-side match time counters.
  // ================================================================

  event BeginState() {

    local JBTagPlayer firstTagPlayer;
    local JBTagPlayer thisTagPlayer;
    local JBGameReplicationInfo InfoGame;
  
    if (bWaitingToStartMatch)
      Super.BeginState();
    
    JBBotTeam(Teams[0].AI).ResetOrders();
    JBBotTeam(Teams[1].AI).ResetOrders();
    
    if (firstJBGameRules != None)
      firstJBGameRules.NotifyRound();
    
    InfoGame = JBGameReplicationInfo(Level.Game.GameReplicationInfo);
    
    firstTagPlayer = InfoGame.firstTagPlayer;
    for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
      thisTagPlayer.NotifyRound();
    for (thisTagPlayer = firstTagPlayerInactive; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
      thisTagPlayer.NotifyRound();
    
    InfoGame.StartMatchTimer();
    InfoGame.SynchronizeMatchTimer(ElapsedTime);
    }


  // ================================================================
  // Timer
  //
  // Periodically checks whether at least one team is completely
  // jailed and sets TimeExecution if so. If TimeExecution is set
  // and has passed, resets it and calls the ExecutionInit function.
  // Synchronizes the client match timers.
  // ================================================================
  
  event Timer() {
  
    local int iTeam;
  
    Super.Timer();
    
    if (TimeExecution == 0.0) {
      for (iTeam = 0; iTeam < ArrayCount(Teams); iTeam++)
        if (IsCaptured(Teams[iTeam]))
          TimeExecution = Level.TimeSeconds + 1.0;
      }
    
    else if (Level.TimeSeconds > TimeExecution) {
      TimeExecution = 0.0;
      ExecutionInit();
      }

    if (ElapsedTime % 30 == 0 || DilationTimePrev != Level.TimeDilation) {
      DilationTimePrev = Level.TimeDilation;
      JBGameReplicationInfo(GameReplicationInfo).SynchronizeMatchTimer(ElapsedTime);
      }
    }


  // ================================================================
  // RestartPlayer
  //
  // Notifies both bot teams of the respawn.
  // ================================================================

  function RestartPlayer(Controller Controller) {
  
    local JBTagPlayer TagPlayer;
  
    TagPlayer = Class'JBTagPlayer'.Static.FindFor(Controller.PlayerReplicationInfo);
    if (TagPlayer.TimeRestart > Level.TimeSeconds)
      return;
  
    Super.RestartPlayer(Controller);
    TagPlayer.NotifyRestarted();

    if (Controller != None) {
      JBBotTeam(Teams[0].AI).NotifySpawn(Controller);
      JBBotTeam(Teams[1].AI).NotifySpawn(Controller);
      }
    }


  // ================================================================
  // EndState
  //
  // Interrupts the client-side match time counters.
  // ================================================================

  event EndState() {
  
    local JBGameReplicationInfo InfoGame;
  
    InfoGame = JBGameReplicationInfo(GameReplicationInfo);
    InfoGame.StopMatchTimer();
    InfoGame.SynchronizeMatchTimer(ElapsedTime);
    }

  } // state MatchInProgress


// ============================================================================
// state Executing
//
// The game is currently executing a team. During that time, players cannot
// spawn in the game.
// ============================================================================

state Executing {

  ignores BroadcastDeathMessage;  // no death messages during execution
  ignores CheckEndGame;           // game cannot end during execution


  // ================================================================
  // BeginState
  //
  // Sets the bIsExecuting flag in JBGameReplicationInfo.
  // ================================================================

  event BeginState() {
  
    JBGameReplicationInfo(GameReplicationInfo).bIsExecuting = True;
    }


  // ================================================================
  // Timer
  //
  // Checks whether there are still players alive in jail. If not,
  // sets TimeRestart for a brief delay. If TimeRestart is set and
  // has passed, resets TimeRestart and calls ExecutionEnd.
  // ================================================================

  event Timer() {
  
    local int iTeam;
    local int nPlayersJailed;
    local JBTagPlayer firstTagPlayer;
    local JBTagPlayer thisTagPlayer;
    
    if (TimeRestart == 0.0) {
      for (iTeam = 0; iTeam < ArrayCount(Teams); iTeam++)
        nPlayersJailed += CountPlayersJailed(Teams[iTeam]);
      if (nPlayersJailed == 0)
        TimeRestart = Level.TimeSeconds + 1.0;
      }

    else if (Level.TimeSeconds > TimeRestart) {
      TimeRestart = 0.0;
      ExecutionEnd();
      }

    firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
    for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
      if (thisTagPlayer.TimeRestart <= Level.TimeSeconds &&
          thisTagPlayer.IsInJail() &&
          thisTagPlayer.GetController().Pawn == None)
        thisTagPlayer.RestartInFreedom();
    }


  // ================================================================
  // RestartPlayer
  //
  // Puts the given player in spectator mode and sets his or her
  // ViewTarget to the currently selected execution camera.
  // ================================================================

  function RestartPlayer(Controller Controller) {
  
    local JBTagPlayer TagPlayer;
  
    if (CameraExecution != None)
      CameraExecution.ActivateFor(Controller);

    TagPlayer = Class'JBTagPlayer'.Static.FindFor(Controller.PlayerReplicationInfo);
    TagPlayer.NotifyRestarted();
    }


  // ================================================================
  // EndState
  //
  // Resets the bIsExecuting flag in JBGameReplicationInfo.
  // ================================================================

  event EndState() {
  
    JBGameReplicationInfo(GameReplicationInfo).bIsExecuting = False;
    }

  } // state Executing


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  Build = "%%%%-%%-%% %%:%%";

  bEnableJailFights        = True;
  bEnableSpectatorDeathCam = True;

  Acronym                  = "JB";
  MapPrefix                = "JB";
  BeaconName               = "JB";

  GameName                 = "Jailbreak";
  HUDType                  = "Jailbreak.JBInterfaceHud";
  ScoreBoardType           = "Jailbreak.JBInterfaceScores";
  MapListType              = "Jailbreak.JBMapList";
  
  MessageClass             = Class'JBLocalMessage';
  GameReplicationInfoClass = Class'JBGameReplicationInfo';
  TeamAIType[0]            = Class'JBBotTeam';
  TeamAIType[1]            = Class'JBBotTeam';
  
  bSpawnInTeamArea = True;
  bScoreTeamKills = False;
  }