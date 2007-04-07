// ============================================================================
// JBTagPlayer
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBTagPlayer.uc,v 1.67 2007-04-06 13:38:57 jrubzjeknf Exp $
//
// Replicated information for a single player.
// ============================================================================


class JBTagPlayer extends JBTag
  notplaceable;


// ============================================================================
// Replication
// ============================================================================

replication
{
  reliable if (Role == ROLE_Authority)
    Arena,
    ArenaPending,
    Jail,
    Pawn,
    Controller,
    Health,
    bReceivedPing,
    bCanBeBaseForPawns,
    ScorePartialAttack,
    ScorePartialDefense,
    ScorePartialRelease,
    LocationPawn,
    VelocityPawn,
    ObjectiveGuessed,
    PawnObjectiveGuessed;

  reliable if (Role == ROLE_Authority)
    ClientSetArena,
    ClientSetJail;
}


// ============================================================================
// Types
// ============================================================================

enum ERestart
{
  Restart_Jail,
  Restart_Freedom,
  Restart_Arena,
};


struct TInfoScore
{
  var float Score;
  var float Deaths;
  var int GoalsScored;
  var int Kills;
  var int Suicides;
  var int FlakCount;
  var int ComboCount;
  var int HeadCount;
};


struct TInfoLocation
{
  var NavigationPoint NavigationPoint;
  var float Probability;
};


// ============================================================================
// Variables
// ============================================================================

var name OrderNameFixed;                  // bot should stick to these orders

var int ScorePartialAttack;               // score earned through attack frags
var int ScorePartialDefense;              // score earned through defense frags
var int ScorePartialRelease;              // score earned through releases

var private string HashIdPlayer;          // key hash for later recognition

var private bool bIsLlama;                // player disconnected in jail
var private int TimeElapsedConnect;       // elapsed time at player connect
var private int TimeElapsedDisconnect;    // elapsed time at player disconnect
var private TInfoScore InfoScore;         // persistent score over reconnects

var float TimeRestart;                    // time of next restart
var private ERestart Restart;             // restart location for this player
var private transient name TagRestart;    // tag of preferred starting spots
var private bool bRestartedBefore;        // whether this player ever restarted

var private JBInfoArena Arena;            // arena player is currently in
var private JBInfoArena ArenaRestart;     // arena player will be restarted in
var private JBInfoArena ArenaPending;     // arena player is scheduled for
var private JBInfoArena ArenaRequest;     // arena player has requested
var private float TimeArenaRequest;       // time of the arena request
var private bool bAdrenalineEnabledPrev;  // adrenaline state before arena
var private float AdrenalinePrev;         // adrenaline amount before arena

var private JBInfoJail Jail;              // jail the player is currently in
var private float TimeRelease;            // time of last release from jail

var private Pawn Pawn;                    // pawn used by this player
var private Controller Controller;        // controller used by this player
var private int Health;                   // current health and armor
var private int Spree;                    // used to carry sprees over rounds
var private bool bReceivedPing;           // whether player completed loading
var private bool bRecoverSpree;           // recover spree after a round
var private bool bCanBeBaseForPawns;      // can be base for other players

var private float TimeUpdateLocation;     // client-side location update time
var private float VelocityPawn;           // replicated velocity of pawn
var private float VelocityPawnBase;       // client-side extrapolation velocity
var private vector LocationPawn[2];       // last two replicated pawn locations
var private vector LocationPawnPrev[2];   // client-side acknowledged locations
var private vector LocationPawnBase;      // client-side extrapolation base
var private vector LocationPawnLast;      // server-side last known location
var private vector DeviationPawn;         // deviation of extrapolated location
var private vector DirectionPawn;         // client-side movement direction

var private float TimeInfoLocation;                 // last known location time
var private array<TInfoLocation> ListInfoLocation;  // location probabilities

var private float TimeObjectiveGuessed;             // time of last guess
var private Pawn PawnObjectiveGuessed;              // pawn used at last guess
var private GameObjective ObjectiveGuessed;         // last guessed objective
var private array<float> ListDistanceObjective;     // distances to objectives

var transient bool bIsInScoreboard;       // scores listed; used by scoreboard


// ============================================================================
// Caches
// ============================================================================

struct TCacheGetRestart       { var float Time; var ERestart Result; };
struct TCacheRateViewOnPlayer { var float Time; var float    Result; var vector LocationViewpoint; };

var private transient TCacheGetRestart       CacheGetRestart;
var private transient TCacheRateViewOnPlayer CacheRateViewOnPlayer;


// ============================================================================
// Internal
// ============================================================================

var JBTagPlayer nextTag;

static function JBTagPlayer FindFor(PlayerReplicationInfo Keeper) {
  return JBTagPlayer(InternalFindFor(Keeper)); }
static function JBTagPlayer SpawnFor(PlayerReplicationInfo Keeper) {
  return JBTagPlayer(InternalSpawnFor(Keeper)); }

protected simulated function JBTag InternalGetFirst() {
  return JBGameReplicationInfo(GetGameReplicationInfo()).firstTagPlayer; }
protected simulated function InternalSetFirst(JBTag TagFirst) {
  JBGameReplicationInfo(GetGameReplicationInfo()).firstTagPlayer = JBTagPlayer(TagFirst); }
protected simulated function JBTag InternalGetNext() {
  return nextTag; }
protected simulated function InternalSetNext(JBTag TagNext) {
  nextTag = JBTagPlayer(TagNext); }


// ============================================================================
// BelongsTo
//
// Checks and returns whether this tag belongs to the given player after a
// reconnect.
// ============================================================================

function bool BelongsTo(Controller Controller)
{
  return (PlayerController(Controller) != None &&
          PlayerController(Controller).GetPlayerIDHash() == HashIdPlayer);
}


// ============================================================================
// Register
//
// Initializes variables relating to the owning player and starts the timer
// with a short interval. Restores the saved values in PlayerReplicationInfo.
// ============================================================================

function Register()
{
  local JBGameRules firstJBGameRules;

  Super.Register();

  Controller = Controller(PlayerReplicationInfo(Keeper).Owner);
  bRestartedBefore = False;

  PlayerReplicationInfo(Keeper).Score       = InfoScore.Score;
  PlayerReplicationInfo(Keeper).Deaths      = InfoScore.Deaths;
  PlayerReplicationInfo(Keeper).GoalsScored = InfoScore.GoalsScored;
  PlayerReplicationInfo(Keeper).Kills       = InfoScore.Kills;

  TeamPlayerReplicationInfo(Keeper).Suicides   = InfoScore.Suicides;
  TeamPlayerReplicationInfo(Keeper).FlakCount  = InfoScore.FlakCount;
  TeamPlayerReplicationInfo(Keeper).ComboCount = InfoScore.ComboCount;
  TeamPlayerReplicationInfo(Keeper).HeadCount  = InfoScore.HeadCount;

  TimeElapsedConnect += Level.Game.GameReplicationInfo.ElapsedTime - TimeElapsedDisconnect;
  PlayerReplicationInfo(Keeper).StartTime = TimeElapsedConnect;

  firstJBGameRules = Jailbreak(Level.Game).GetFirstJBGameRules();
  if (TimeElapsedDisconnect > 0 && firstJBGameRules != None)
    firstJBGameRules.NotifyPlayerReconnect(PlayerController(Controller), bIsLlama);

  if (PlayerController(Controller) != None)
    HashIdPlayer = PlayerController(Controller).GetPlayerIDHash();

  Enable('Tick');
  SetTimer(RandRange(0.18, 0.22), True);
}


// ============================================================================
// RegisterLocal
//
// Fixes the location displayed in player talk messages during the execution
// sequence. This goes at the expense of displaying them as dead in the brief
// period between a frag and the subsequent respawn.
// ============================================================================

protected simulated function RegisterLocal()
{
  PlayerReplicationInfo(Keeper).StringDead = PlayerReplicationInfo(Keeper).StringSpectating;
}


// ============================================================================
// Unregister
//
// Saves persistent information for later restoration and stops the timer.
// ============================================================================

function Unregister()
{
  local byte bIsLlamaByte;
  local JBGameRules firstJBGameRules;

  bIsLlama = !IsFree();
  bIsLlamaByte = byte(bIsLlama);  // out parameters cannot be bool

  firstJBGameRules = Jailbreak(Level.Game).GetFirstJBGameRules();
  if (PlayerController(Controller) != None && firstJBGameRules != None)
    firstJBGameRules.NotifyPlayerDisconnect(PlayerController(Controller), bIsLlamaByte);

  bIsLlama = bool(bIsLlamaByte);

  Arena        = None;
  ArenaRestart = None;
  ArenaPending = None;
  ArenaRequest = None;
  Jail         = None;

  InfoScore.Score       = PlayerReplicationInfo(Keeper).Score;
  InfoScore.Deaths      = PlayerReplicationInfo(Keeper).Deaths;
  InfoScore.GoalsScored = PlayerReplicationInfo(Keeper).GoalsScored;
  InfoScore.Kills       = PlayerReplicationInfo(Keeper).Kills;

  InfoScore.Suicides    = TeamPlayerReplicationInfo(Keeper).Suicides + 1;
  InfoScore.FlakCount   = TeamPlayerReplicationInfo(Keeper).FlakCount;
  InfoScore.ComboCount  = TeamPlayerReplicationInfo(Keeper).ComboCount;
  InfoScore.HeadCount   = TeamPlayerReplicationInfo(Keeper).HeadCount;

  TimeElapsedDisconnect = Level.Game.GameReplicationInfo.ElapsedTime;

  Disable('Tick');
  SetTimer(0.0, False);  // stop timer

  Super.Unregister();
}


// ============================================================================
// Timer
//
// Updates jail status, replicated location and health.
// ============================================================================

event Timer()
{
  bReceivedPing = PlayerReplicationInfo(Keeper).bReceivedPing;

  UpdateJail();
  UpdateLocation();

  GetHealth();  // update Health variable
}


// ============================================================================
// Tick
//
// Disallows the player spawning a pawn if he's not able to control it yet.
// Updates the Pawn and LocationPawnLast variables. Configures the Pawn to be
// a base for a human ladder if the player is crouching and replicates this
// information to all clients.
// ============================================================================

event Tick(float TimeDelta)
{
  local xPawn thisPawn;

  Pawn = Controller.Pawn;

  // fixes replicating over and over when referenced actor has been destroyed
  if (PawnObjectiveGuessed == None)
    PawnObjectiveGuessed = None;

  if (Pawn != None) {
    LocationPawnLast = Pawn.Location;

    if (xPawn(Pawn) != None) {
      if (Pawn.bCanBeBaseForPawns && !Pawn.bIsCrouched)
        foreach DynamicActors(Class'xPawn', thisPawn)
          if (Pawn != thisPawn && Pawn.TouchingActor(thisPawn))
            thisPawn.JumpOffPawn();

      Pawn.bCanBeBaseForPawns = Pawn.bIsCrouched;
      bCanBeBaseForPawns = Pawn.bCanBeBaseForPawns;

      if(bRecoverSpree)
        RecoverSpree();
    }

    // hack to fix the hack that fixes a hack

    if (ASTurret(Pawn)                          != None &&
        Pawn.Controller                         == None &&
        PlayerController(Controller)            != None &&
        PlayerController(Controller).ViewTarget == Pawn)
      Pawn.Controller = Controller;

    // As the player has now restarted, make sure that the next game-induced
    // restart sends him to a random starting spot in jail.

    Restart    = default.Restart;
    TagRestart = Default.TagRestart;
  }
}


// ============================================================================
// UpdateJail
//
// Checks whether the player has entered or left jail meanwhile and updates
// the Jail variable accordingly, giving all necessary notifications.
// ============================================================================

private function UpdateJail()
{
  local JBInfoJail JailPrev;

  if (Arena == None &&
      Controller.Pawn != None &&
      Controller.Pawn.IsPlayerPawn()) {

    JailPrev = Jail;
    Jail = FindJail();

    if (JailPrev != None && Jail == None) NotifyJailLeft(JailPrev);
    if (JailPrev == None && Jail != None) NotifyJailEntered();

    if (JailPrev != Jail)
      ClientSetJail(Jail);
  }
}


// ============================================================================
// UpdateLocation
//
// Replicates information about the player's movement to all clients. Does not
// apply in standalone games.
// ============================================================================

private function UpdateLocation()
{
  local int iLocationPawn;
  local vector DirectionPawnActual;
  local vector DirectionPawnPrev;
  local vector LocationPawnActual;
  local vector LocationPawnExtrapolated;
  local vector VelocityPawnActual;

  if (Level.NetMode == NM_Standalone)
    return;

  if (Controller.Pawn == None) {
    VelocityPawn = 0.0;
    LocationPawn[0] = LocationPawnLast;
    LocationPawn[1] = LocationPawnLast;
  }

  else {
    DirectionPawnPrev = LocationPawn[1] - LocationPawn[0];
    if (CalcOrientation(DirectionPawnPrev) * VelocityPawn < 0)
      iLocationPawn = 1;

    VelocityPawnActual = Controller.Pawn.Velocity;
    if (Controller.Pawn.Base != None)
      VelocityPawnActual += Controller.Pawn.Base.Velocity;

    // quantize and round velocity to minimize replication
    VelocityPawn = int(VSize(VelocityPawnActual) * 32.0 + 0.5) / 32.0;
    VelocityPawnBase = VelocityPawn;  // used for server-side extrapolation

    LocationPawnActual = Controller.Pawn.Location;

    if (VelocityPawn == 0.0) {
      LocationPawn[0] = LocationPawnActual;
      LocationPawn[1] = LocationPawnActual;
    }

    else {
      LocationPawnExtrapolated = ExtrapolateLocationPawn();

      DirectionPawnActual = Normal(LocationPawnActual - LocationPawnBase);
      if (CalcOrientation(DirectionPawnActual) < 0)
        VelocityPawn = -VelocityPawn;  // resolve orientation ambiguity

      if (VSize(LocationPawnExtrapolated - LocationPawnActual) > 16.0) {
        LocationPawn[    iLocationPawn] = LocationPawnActual;
        LocationPawn[1 - iLocationPawn] = LocationPawnBase;

        // used for server-side extrapolation
        DirectionPawn = DirectionPawnActual;
        LocationPawnBase = LocationPawnActual;

        TimeUpdateLocation = Level.TimeSeconds;
      }
    }
  }
}


// ============================================================================
// PostNetReceive
//
// If new information about the Pawn's whereabouts is received, derives the
// player's current movement direction from the last two location updates.
// Calculates the deviation between the extrapolated and the actual location.
//
// Also sets the bCanBeBaseForPawns flag client-side.
// ============================================================================

simulated event PostNetReceive()
{
  local vector LocationPawnSmoothed;

  Super.PostNetReceive();

  if (LocationPawn[0] != LocationPawnPrev[0] ||
      LocationPawn[1] != LocationPawnPrev[1]) {

    LocationPawnSmoothed = GetLocationPawn();

    LocationPawnBase = LocationPawn[1];
    DirectionPawn = Normal(LocationPawn[1] - LocationPawn[0]);

    if (CalcOrientation(DirectionPawn) * VelocityPawn < 0) {
      DirectionPawn = -DirectionPawn;  // switch orientation
      LocationPawnBase = LocationPawn[0];
    }

    TimeUpdateLocation = Level.TimeSeconds;

    DeviationPawn = LocationPawnSmoothed - LocationPawnBase;
    if (VSize(DeviationPawn) > 1024.0)
      DeviationPawn = vect(0, 0, 0);  // apparently sudden relocation

    LocationPawnPrev[0] = LocationPawn[0];
    LocationPawnPrev[1] = LocationPawn[1];
  }

  VelocityPawnBase = Abs(VelocityPawn);

  if (Pawn != None)  // for human ladder
    Pawn.bCanBeBaseForPawns = bCanBeBaseForPawns;
}


// ============================================================================
// CalcOrientation
//
// Calculates and returns an artificial value representing the orientation of
// a vector. The returned value has the following properties:
//
//   * Non-zero for any non-zero vector. Zero for the zero vector.
//   * Negating the argument yields the negative result.
//
// Those properties allow to use this function to make any difference between
// two given points in space unambiguous by passing a single additional binary
// bit of information.
// ============================================================================

simulated function float CalcOrientation(vector VectorInput)
{
  local vector VectorTranslated;

  VectorTranslated.X = VectorInput dot vect(1, 1, 0);  if (VectorTranslated.X != 0.0) return VectorTranslated.X;
  VectorTranslated.Y = VectorInput dot vect(1,-1, 0);  if (VectorTranslated.Y != 0.0) return VectorTranslated.Y;
  VectorTranslated.Z = VectorInput dot vect(0, 0, 1);  if (VectorTranslated.Z != 0.0) return VectorTranslated.Z;

  return 0.0;
}


// ============================================================================
// FindJail
//
// Determines the jail the player is currently in. Returns None if the player
// is in freedom. Expects the player to possess a valid Pawn when called.
// ============================================================================

function JBInfoJail FindJail()
{
  local JBInfoJail firstJail;
  local JBInfoJail thisJail;

  firstJail = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstJail;
  for (thisJail = firstJail; thisJail != None; thisJail = thisJail.nextJail)
    if (thisJail.ContainsActor(Controller.Pawn))
      return thisJail;

  return None;
}


// ============================================================================
// IsFree
//
// Returns whether this player is in freedom at the moment.
// ============================================================================

simulated function bool IsFree()
{
  return (Arena == None &&
          Jail  == None);
}


// ============================================================================
// IsInArena
//
// Returns whether this player is fighting in an arena at the moment.
// ============================================================================

simulated function bool IsInArena()
{
  return (Arena != None);
}


// ============================================================================
// IsInJail
//
// Returns whether this player is in jail at the moment.
// ============================================================================

simulated function bool IsInJail()
{
  return (Jail != None);
}


// ============================================================================
// NotifyRound
//
// Called when a new round starts. Resets the player's llama state and allow a
// previously saved spree to be recovered.
// ============================================================================

function NotifyRound()
{
  bIsLlama = False;
  if (Spree > 0)
    bRecoverSpree = true;
}


// ============================================================================
// NotifyRestarted
//
// Called by class Jailbreak directly after a player has been respawned.
// Updates the values of the Arena and Jail variables depending on the value
// stored in the Restart variable. Enables the timer unless the player went to
// the arena or disables it otherwise.
// ============================================================================

function NotifyRestarted()
{
  local JBInfoArena ArenaPrev;
  local JBInfoJail JailPrev;

  ArenaPrev = Arena;
  JailPrev  = Jail;

  switch (GetRestart()) {
    case Restart_Freedom:  Arena = None;          Jail = None;        break;
    case Restart_Jail:     Arena = None;          Jail = FindJail();  break;
    case Restart_Arena:    Arena = ArenaRestart;  Jail = None;        break;
  }

  bRestartedBefore = True;
  CacheGetRestart.Time = 0.0;  // reset GetRestart cache

  if (ArenaPrev != None && Arena == None) NotifyArenaLeft(ArenaPrev);
  if (JailPrev  != None && Jail  == None) NotifyJailLeft(JailPrev);
  if (ArenaPrev == None && Arena != None) NotifyArenaEntered();
  if (JailPrev  == None && Jail  != None) NotifyJailEntered();

  if (ArenaPrev != Arena) ClientSetArena(Arena);
  if (JailPrev  != Jail)  ClientSetJail(Jail);
}


// ============================================================================
// NotifyArenaEntered
//
// Called when the player entered an arena. Puts bots on the arena squad.
// ============================================================================

function NotifyArenaEntered()
{
  if (Bot(Controller) != None)
    JBBotTeam(UnrealTeamInfo(GetTeam()).AI).PutOnSquadArena(Bot(Controller));

  bAdrenalineEnabledPrev = Controller.bAdrenalineEnabled;
  AdrenalinePrev         = Controller.Adrenaline;

  Controller.bAdrenalineEnabled = False;
  Controller.Adrenaline = Controller.AdrenalineMax;

  UnsetJailInventory();
}


// ============================================================================
// NotifyArenaLeft
//
// Called when the player left the arena for jail or for freedom.
// ============================================================================

function NotifyArenaLeft(JBInfoArena ArenaPrev)
{
  Controller.bAdrenalineEnabled = bAdrenalineEnabledPrev;
  Controller.Adrenaline = AdrenalinePrev;

  if (IsInJail())
    return;

  JBBotTeam(TeamGame(Level.Game).Teams[0].AI).NotifySpawn(Controller);
  JBBotTeam(TeamGame(Level.Game).Teams[1].AI).NotifySpawn(Controller);
}


// ============================================================================
// NotifyJailEntered
//
// Called when the player walks into or respawns inside a jail. Notifies the
// jail of that. Puts bots on the jail squad. Modifies the player's inventory.
// ============================================================================

function NotifyJailEntered()
{
  if (Bot(Controller) != None)
    JBBotTeam(UnrealTeamInfo(GetTeam()).AI).PutOnSquadJail(Bot(Controller));

  SetJailInventory();

  Jail.NotifyJailEntered(Self);
}


// ============================================================================
// NotifyJailLeft
//
// Called when the player escapes from a jail. Resets all arena-related
// information and scores points for the releaser. Checks if the player is
// allowed to leave the jail. Modifies the player's inventory.
// ============================================================================

function NotifyJailLeft(JBInfoJail JailPrev)
{
  local Controller ControllerInstigator;
  local JBInfoArena firstArena;
  local JBInfoArena thisArena;

  if (ArenaPending != None &&
      ArenaPending != Arena)
    ArenaPending.MatchCancel();

  ArenaPending = None;
  ArenaRequest = None;

  if (IsInArena())
    return;

  // Prevent leaving jail.
  if (Jailbreak(Level.Game).bDisallowEscaping &&
     !Jailbreak(Level.Game).IsInState('Executing') &&
      JailPrev.IsReleaseMoverClosed(GetTeam()) &&
      Restart != Restart_Freedom) {
    Level.Game.BroadcastHandler.BroadcastLocalizedMessage(MessageClass, 800);
    RestartInJail();
    return;
  }

  firstArena = JBGameReplicationInfo(GetGameReplicationInfo()).firstArena;
  for (thisArena = firstArena; thisArena != None; thisArena = thisArena.nextArena)
    thisArena.ExcludeRemove(Controller);

  if (JailPrev.GetReleaseTime(GetTeam()) != TimeRelease) {
    ControllerInstigator = JailPrev.GetReleaseInstigator(GetTeam());
    if (ControllerInstigator != None &&
        ControllerInstigator != Controller)
      Jailbreak(Level.Game).ScorePlayer(ControllerInstigator, 'Release');

    TimeRelease = JailPrev.GetReleaseTime(GetTeam());
  }

  UnsetJailInventory();

  JBBotTeam(TeamGame(Level.Game).Teams[0].AI).NotifyReleasePlayer(JailPrev.Tag, Controller);
  JBBotTeam(TeamGame(Level.Game).Teams[1].AI).NotifyReleasePlayer(JailPrev.Tag, Controller);

  JailPrev.NotifyJailLeft(Self);
}


// ============================================================================
// NotifyJailOpening
//
// Called when the doors of the jail this player is in start opening. Resets
// the player's health and viewpoint and cancels an upcoming arena match.
// ============================================================================

function NotifyJailOpening()
{
  if (Controller.Pawn != None &&
      Controller.Pawn.Health < Controller.Pawn.Default.Health)
    Controller.Pawn.Health = Controller.Pawn.Default.Health;

  if (PlayerController(Controller) != None)
    Jailbreak(Level.Game).ResetViewTarget(PlayerController(Controller));

  if (ArenaPending != None)
    ArenaPending.MatchCancel();
}


// ============================================================================
// NotifyJailOpened
//
// Called when the doors of the jail this player is in have fully opened.
// Gives bots new orders to make them leave the jail.
// ============================================================================

function NotifyJailOpened()
{
  if (Bot(Controller) != None)
    JBBotTeam(UnrealTeamInfo(GetTeam()).AI).ResumeBotOrders(Bot(Controller));
}


// ============================================================================
// NotifyJailClosed
//
// Called when the jail closes while this player is in jail. Sets bots back on
// the jail squad.
// ============================================================================

function NotifyJailClosed()
{
  if (Bot(Controller) != None)
    JBBotTeam(UnrealTeamInfo(GetTeam()).AI).PutOnSquadJail(Bot(Controller));
}


// ============================================================================
// SetJailInventory
//
// Removes the player's translocator, adds the shieldgun if an arena mutator
// is active.
// ============================================================================

function SetJailInventory()
{
  local Pawn P;
  local Inventory thisInventory;
  local Inventory nextInventory;

  if (Vehicle(Controller.Pawn) != None)
    P = Vehicle(Controller.Pawn).Driver;
  else
    P = Controller.Pawn;

  if (P != None) {
    log("SetJailInventory("$P.GetHumanReadableName()$")");

    for (thisInventory = P.Inventory; thisInventory != None; thisInventory = nextInventory) {
      nextInventory = thisInventory.Inventory;
      if (TransLauncher(thisInventory) != None)
        thisInventory.Destroy();
    }

    if  (P.Weapon == None)
      Controller.ClientSwitchToBestWeapon();

    if (Jailbreak(Level.Game).bArenaMutatorActive &&
        Jailbreak(Level.Game).bEnableJailFights)
      P.CreateInventory("XWeapons.ShieldGun");
  }
}


// ============================================================================
// UnsetJailInventory
//
// Gives back a translocator to the player if it is enabled in the game.
// Removes the ShieldGun from the player if an Arena mutator is active.
// ============================================================================

function UnsetJailInventory()
{
  local Pawn P;
  local Inventory thisInventory;
  local Inventory nextInventory;

  if (Vehicle(Controller.Pawn) != None)
    P = Vehicle(Controller.Pawn).Driver;
  else
    P = Controller.Pawn;

  if (P != None) {
    log("UnsetJailInventory("$P.GetHumanReadableName()$")");

    if (DeathMatch(Level.Game).bAllowTrans)
      P.CreateInventory("XWeapons.TransLauncher");

    if (Jailbreak(Level.Game).bArenaMutatorActive &&
        Jailbreak(Level.Game).bEnableJailFights) {
      if (class'JBBotSquadJail'.static.CountWeaponsFor(P) > 1)
        for (thisInventory = P.Inventory; thisInventory != None; thisInventory = nextInventory) {
          nextInventory = thisInventory.Inventory;
          if (thisInventory == class'JBBotSquadJail'.static.GetPrimaryWeaponFor(P)) {
            Weapon(thisInventory).StopFire(0);
            Weapon(thisInventory).StopFire(1);
            thisInventory.Destroy();
            break;
          }
        }

      if  (P.Weapon == None)
        Controller.ClientSwitchToBestWeapon();
    }
  }
}

// ============================================================================
// RestartPlayer
//
// Restarts the player, making sure everything is properly cleaned up before
// doing so. Plays a teleport effect at the place where the player teleports
// away from. Prefers starting spots with a given Tag if specified.
// ============================================================================

private function RestartPlayer(ERestart RestartCurrent, optional name TagPreferred)
{
  local xPawn xPawn;

  if (Controller.Pawn != None)
    Controller.Pawn.PlayTeleportEffect(True, True);

  while (Controller.Pawn != None) {
    xPawn = xPawn(Controller.Pawn);

    if (xPawn != None) {
      if (xPawn.CurrentCombo != None)
        xPawn.CurrentCombo.Destroy();

      if (xPawn.UDamageTimer != None) {
        xPawn.UDamageTimer.Destroy();
        xPawn.DisableUDamage();
      }
    }

    Controller.Pawn.Destroy();
  }

  Restart = RestartCurrent;
  TagRestart = TagPreferred;

  TimeRestart = Level.TimeSeconds;
  Level.Game.RestartPlayer(Controller);

  // The values of Restart and TagRestart are reset in the Tick event as soon
  // as the player has a Pawn. Works around problems when a player is unable to
  // spawn because there are not enough PlayerStarts available in the map.
}


// ============================================================================
// RestartInFreedom
// RestartInJail
//
// Restarts the player in freedom or in jail, respectively. Prefers starting
// spots with a given tag, if specified.
// ============================================================================

function RestartInFreedom(optional name TagPreferred) { RestartPlayer(Restart_Freedom, TagPreferred); }
function RestartInJail   (optional name TagPreferred) { RestartPlayer(Restart_Jail,    TagPreferred); }


// ============================================================================
// RestartInArena
//
// Restarts the player in a specified arena.
// ============================================================================

function RestartInArena(JBInfoArena Arena)
{
  ArenaRestart = Arena;
  RestartPlayer(Restart_Arena);
}


// ============================================================================
// ClientSetArena
// ClientSetJail
//
// Replicated functions. Set the Arena and Jail property client-side. Used
// in addition to replicating the variables themselves for timing reasons.
// ============================================================================

simulated function ClientSetArena(JBInfoArena ArenaNew) { Arena = ArenaNew; }
simulated function ClientSetJail (JBInfoJail  JailNew)  { Jail  = JailNew;  }


// ============================================================================
// GetRestart
//
// Returns where this player ought to be restarted next, taking world spawn
// and game rules into accound. Caches its result within a tick.
// ============================================================================

private function ERestart GetRestart()
{
  local JBGameRules firstJBGameRules;

  if (CacheGetRestart.Time == Level.TimeSeconds)
    return CacheGetRestart.Result;

  CacheGetRestart.Result = Restart;
  CacheGetRestart.Time = Level.TimeSeconds;

  // Initial world spawn.
  if (!bRestartedBefore && !bIsLlama &&
      !(Jailbreak(Level.Game).bJailNewcomers &&
        Level.Game.GameReplicationInfo.bMatchHasBegun &&
        PlayerController(Controller) != None))
    CacheGetRestart.Result = Restart_Freedom;

  firstJBGameRules = Jailbreak(Level.Game).GetFirstJBGameRules();
  if (Restart == Restart_Jail &&
      firstJBGameRules != None &&
     !firstJBGameRules.CanSendToJail(Self))
    CacheGetRestart.Result = Restart_Freedom;

  return CacheGetRestart.Result;
}


// ============================================================================
// IsStartValid
//
// Checks and returns whether the given NavigationPoint is a valid start for
// this player in the current situation, regardless of the player's team.
// ============================================================================

function bool IsStartValid(NavigationPoint NavigationPoint)
{
  local JBInfoArena firstArena;
  local JBInfoArena thisArena;
  local JBInfoJail firstJail;
  local JBInfoJail thisJail;

  switch (GetRestart()) {
    case Restart_Freedom:
      firstJail = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstJail;
      for (thisJail = firstJail; thisJail != None; thisJail = thisJail.nextJail)
        if (thisJail.ContainsActor(NavigationPoint))
          return False;
      firstArena = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstArena;
      for (thisArena = firstArena; thisArena != None; thisArena = thisArena.nextArena)
        if (thisArena.ContainsActor(NavigationPoint))
          return False;
      return True;

    case Restart_Jail:
      firstJail = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstJail;
      for (thisJail = firstJail; thisJail != None; thisJail = thisJail.nextJail)
        if (thisJail.ContainsActor(NavigationPoint))
          return True;
      return False;

    case Restart_Arena:
      return ArenaRestart.ContainsActor(NavigationPoint);
  }
}


// ============================================================================
// IsStartPreferred
//
// Checks and returns whether this NavigationPoint is currently a preferred
// start for this player, regardless of the player's team. Returns False for
// all starts if no particular start is preferred.
// ============================================================================

function bool IsStartPreferred(NavigationPoint NavigationPoint)
{
  if (TagRestart == '' ||
      TagRestart == 'None')
    return False;

  return (NavigationPoint.Tag == TagRestart);
}


// ============================================================================
// SetArenaPending
//
// Sets ArenaPending if the player can actually fight in the given arena.
// ============================================================================

function SetArenaPending(JBInfoArena NewArenaPending)
{
  if (NewArenaPending == None ||
      NewArenaPending.CanFight(Controller))
    ArenaPending = NewArenaPending;
}


// ============================================================================
// SetArenaRequest
//
// Sets ArenaRequest and TimeArenaRequest if the player can actually fight in
// the given arena.
// ============================================================================

function SetArenaRequest(JBInfoArena NewArenaRequest)
{
  if (NewArenaRequest != None) {
    if (ArenaPending != None)
      return;
    if (!NewArenaRequest.CanFight(Controller))
      return;
  }

  ArenaRequest = NewArenaRequest;
  TimeArenaRequest = Level.TimeSeconds;
}


// ============================================================================
// GetHealth
//
// Calculates and returns the player's current health and armor, that is, the
// total number of hitpoints the player can take before dying.
// ============================================================================

simulated function int GetHealth(optional bool bCached)
{
  local Inventory thisInventory;

  if (bCached || Role < ROLE_Authority)
    return Health;

  Health = 0;

  if (Controller.Pawn != None) {
    Health = Controller.Pawn.Health;

    for (thisInventory = Controller.Pawn.Inventory; thisInventory != None; thisInventory = thisInventory.Inventory)
      if (Armor(thisInventory) != None)
        Health += (Armor(thisInventory).Charge * Armor(thisInventory).ArmorAbsorption) / 100;

    if (xPawn(Controller.Pawn) != None)
      Health += xPawn(Controller.Pawn).ShieldStrength;
  }

  return Health;
}


// ============================================================================
// SaveSpree
//
// Saves the current killing spree. Called from Jailbreak.ExecutionCommit
// ============================================================================

function SaveSpree()
{
  if (Pawn != None)
    Spree = Pawn.GetSpree();
}


// ============================================================================
// RecoverSpree
//
// Recovers a previously saved killing spree.
// ============================================================================

function RecoverSpree()
{
  if (Pawn == None) {
    Spree = 0;
  }
  else {
    while (Spree > 0) {
      Pawn.IncrementSpree();  // deals with custom Pawns/Vehicles
      Spree--;
    }
  }

  bRecoverSpree = False;
}


// ============================================================================
// ExtrapolateLocationPawn
//
// Extrapolates and returns the current location of the player's pawn based on
// the information sent by the server. Does not attempt to smooth the pawn's
// movement in any other way.
// ============================================================================

private simulated function vector ExtrapolateLocationPawn()
{
  return LocationPawnBase + DirectionPawn * VelocityPawnBase * (Level.TimeSeconds - TimeUpdateLocation);
}


// ============================================================================
// GetLocationPawn
//
// Gets the last known location of the player's pawn. If the pawn is not
// replicated to this client, uses the client-side extrapolated location and
// applies time-based smoothing on it.
// ============================================================================

simulated function vector GetLocationPawn()
{
  if (Role == ROLE_Authority)
    return LocationPawnLast;

  return ExtrapolateLocationPawn() + DeviationPawn * FMax(0.0, 1.0 - (Level.TimeSeconds - TimeUpdateLocation) / 2.0);
}


// ============================================================================
// RecordLocation
//
// Records a known location of this player. Later calls of GuessLocation will
// use this location as the player's assumed starting point.
// ============================================================================

function RecordLocation(optional NavigationPoint NavigationPoint)
{
  if (NavigationPoint == None) {
    ListInfoLocation.Length = 0;
  }
  else {
    ListInfoLocation.Length = 1;
    ListInfoLocation[0].NavigationPoint = NavigationPoint;
    ListInfoLocation[0].Probability = 1.0;
  }

  TimeInfoLocation = Level.TimeSeconds;
}


// ============================================================================
// RecordLocationList
//
// Records a list of possible location this player could be at with equal
// probabilities. If no argument is given, resets the list.
// ============================================================================

function RecordLocationList(optional array<NavigationPoint> ListNavigationPoint)
{
  local int iNavigationPoint;

  ListInfoLocation.Length = ListNavigationPoint.Length;
  for (iNavigationPoint = 0; iNavigationPoint < ListNavigationPoint.Length; iNavigationPoint++) {
    ListInfoLocation[iNavigationPoint].NavigationPoint = ListNavigationPoint[iNavigationPoint];
    ListInfoLocation[iNavigationPoint].Probability = 1.0 / ListNavigationPoint.Length;
  }

  TimeInfoLocation = Level.TimeSeconds;
}


// ============================================================================
// GuessLocation
//
// Takes a guess which location of a given set of possible location this
// player is currently at. Takes into account the previously recorded possible
// locations of this player and their respective probabilities. Updates the
// list of possible locations.
// ============================================================================

function NavigationPoint GuessLocation(array<NavigationPoint> ListNavigationPoint)
{
  local int iNavigationPointStart;
  local int iNavigationPointTarget;
  local float Distance;
  local float DistanceMax;
  local float ProbabilityPath;
  local float ProbabilitySelected;
  local float ProbabilityTotal;
  local array<TInfoLocation> ListInfoLocationTarget;

  if (Controller.Pawn == None)
    return None;

  if (TimeInfoLocation != Level.TimeSeconds) {
    DistanceMax = Controller.Pawn.GroundSpeed * (Level.TimeSeconds - TimeInfoLocation) * 1.1;

    for (iNavigationPointTarget = 0; iNavigationPointTarget < ListNavigationPoint.Length; iNavigationPointTarget++) {
      ListInfoLocationTarget.Insert(iNavigationPointTarget, 1);
      ListInfoLocationTarget[iNavigationPointTarget].NavigationPoint = ListNavigationPoint[iNavigationPointTarget];

      for (iNavigationPointStart = 0; iNavigationPointStart < ListInfoLocation.Length; iNavigationPointStart++) {
        Distance = Class'JBTagNavigation'.Static.CalcDistance(
          ListInfoLocation[iNavigationPointStart].NavigationPoint,
          ListNavigationPoint[iNavigationPointTarget]);
        ProbabilityPath = Exp(-Square(2.0 * (Distance / DistanceMax - 1.0))) * (1.0 - Distance / DistanceMax);
        if (ProbabilityPath > 0.0)
          ListInfoLocationTarget[iNavigationPointTarget].Probability +=
            ProbabilityPath * ListInfoLocation[iNavigationPointStart].Probability;
      }

      ProbabilityTotal += ListInfoLocationTarget[iNavigationPointTarget].Probability;
    }

    if (ProbabilityTotal > 0.0) {
      for (iNavigationPointTarget = 0; iNavigationPointTarget < ListInfoLocationTarget.Length; iNavigationPointTarget++)
        ListInfoLocationTarget[iNavigationPointTarget].Probability /= ProbabilityTotal;  // normalize

      ListInfoLocation.Length = ListInfoLocationTarget.Length;
      for (iNavigationPointTarget = 0; iNavigationPointTarget < ListInfoLocationTarget.Length; iNavigationPointTarget++)
        ListInfoLocation[iNavigationPointTarget] = ListInfoLocationTarget[iNavigationPointTarget];

      TimeInfoLocation = Level.TimeSeconds;
    }

    else {
      RecordLocationList(ListNavigationPoint);  // unknown, could be anywhere
    }
  }

  ProbabilitySelected = FRand();

  for (iNavigationPointTarget = 0; iNavigationPointTarget < ListInfoLocationTarget.Length; iNavigationPointTarget++) {
    ProbabilitySelected -= ListInfoLocation[iNavigationPointTarget].Probability;
    if (ProbabilitySelected < 0.0)
      return ListInfoLocation[iNavigationPointTarget].NavigationPoint;
  }

  return None;  // should never happen
}


// ============================================================================
// GuessObjective
//
// Takes a guess which objective this player is currently attacking or
// defending based on the players location and recent movement in relation to
// the available objectives. All calls within a three-second interval will
// yield the same result; then the function evaluates its guess again.
// ============================================================================

function GameObjective GuessObjective()
{
  local int iObjective;
  local float Distance;
  local float DistanceApproached;
  local float DistanceApproachedMax;
  local float DistanceClosest;
  local float DistanceClosestPrev;
  local float DistanceTravelledMax;
  local GameObjective thisObjective;
  local GameObjective ObjectiveApproachedMax;
  local GameObjective ObjectiveClosest;

  if (Controller.Pawn == None)
    return None;

  if (TimeObjectiveGuessed + 3.0 > Level.TimeSeconds && Controller.Pawn == PawnObjectiveGuessed)
    return ObjectiveGuessed;

  if (Controller.Pawn != PawnObjectiveGuessed) {
    ListDistanceObjective.Length = 0;  // clear list after respawn
    PawnObjectiveGuessed = Controller.Pawn;
  }

  for (thisObjective = UnrealTeamInfo(GetTeam()).AI.Objectives;
       thisObjective != None;
       thisObjective = thisObjective.NextObjective) {

    Distance = Class'JBBotTeam'.Static.CalcDistance(Controller, thisObjective);

    if (ObjectiveClosest == None || Distance < DistanceClosest) {
      ObjectiveClosest = thisObjective;
      DistanceClosestPrev = DistanceClosest;
      DistanceClosest = Distance;
    }

    else if (DistanceClosestPrev == 0.0 ||
             DistanceClosestPrev > Distance) {
      DistanceClosestPrev = Distance;
    }

    // assumes that number and order of objectives never change

    if (iObjective < ListDistanceObjective.Length) {
      DistanceApproached = ListDistanceObjective[iObjective] - Distance;
      if (ObjectiveApproachedMax == None || DistanceApproached > DistanceApproachedMax) {
        ObjectiveApproachedMax = thisObjective;
        DistanceApproachedMax = DistanceApproached;
      }
    }

    ListDistanceObjective[iObjective] = Distance;
    iObjective++;
  }

  DistanceTravelledMax = Controller.Pawn.GroundSpeed * (Level.TimeSeconds - TimeObjectiveGuessed);

  if (DistanceApproachedMax > DistanceTravelledMax * 0.8)
    ObjectiveGuessed = ObjectiveApproachedMax;  // moving towards objective
  else
    if (DistanceClosestPrev == 0.0 ||
        DistanceClosestPrev > DistanceClosest * 2.0)
      ObjectiveGuessed = ObjectiveClosest;  // located in vicinity of objective
    else
      ObjectiveGuessed = None;  // located between objectives, freelancing

  TimeObjectiveGuessed = Level.TimeSeconds;
  return ObjectiveGuessed;
}


// ============================================================================
// RateViewOnPlayer
//
// Calculates and returns a rating for the view from the given location on
// this player, not taking into account the viewer's field of view, if any.
// The higher the return value, the better the view. Results are cached.
// ============================================================================

simulated function float RateViewOnPlayer(vector LocationViewpoint)
{
  if (CacheRateViewOnPlayer.Time == Level.TimeSeconds &&
      CacheRateViewOnPlayer.LocationViewpoint == LocationViewpoint)
    return CacheRateViewOnPlayer.Result;

  CacheRateViewOnPlayer.Time = Level.TimeSeconds;
  CacheRateViewOnPlayer.Result = 0.0;
  CacheRateViewOnPlayer.LocationViewpoint = LocationViewpoint;

  if (Pawn != None && FastTrace(Pawn.Location, LocationViewpoint))
    CacheRateViewOnPlayer.Result = Exp(-Square((VSize(Pawn.Location - LocationViewpoint) - 64.0) / 1024.0));

  return CacheRateViewOnPlayer.Result;
}


// ============================================================================
// Accessors
// ============================================================================

simulated function PlayerReplicationInfo GetPlayerReplicationInfo() {
  return PlayerReplicationInfo(Keeper); }
simulated function Pawn GetPawn() {
  return Pawn; }
simulated function Controller GetController() {
  return Controller; }
simulated function TeamInfo GetTeam() {
  if (Keeper == None) return None; return PlayerReplicationInfo(Keeper).Team; }
simulated function bool HasReceivedPing() {
  return bReceivedPing; }

simulated function JBInfoJail GetJail() {
  return Jail; }
simulated function JBInfoArena GetArena() {
  return Arena; }

simulated function JBInfoArena GetArenaPending() {
  return ArenaPending; }
function JBInfoArena GetArenaRequest() {
  return ArenaRequest; }
function float GetArenaRequestTime() {
  return TimeArenaRequest; }

simulated function GameObjective GetObjectiveGuessed() {
  return ObjectiveGuessed; }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  Restart = Restart_Jail;
  MessageClass = class'JBLocalMessage';

  RemoteRole = ROLE_SimulatedProxy;
}
