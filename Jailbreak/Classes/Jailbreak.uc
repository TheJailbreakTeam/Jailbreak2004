// ============================================================================
// Jailbreak
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: Jailbreak.uc,v 1.74 2004/04/22 13:48:13 mychaeel Exp $
//
// Jailbreak game type.
// ============================================================================


class Jailbreak extends xTeamGame
  notplaceable;


// ============================================================================
// Properties
// ============================================================================

var() const editconst string Build;


// ============================================================================
// Configuration
// ============================================================================

var config string Addons;
var config bool bEnableJailFights;
var config bool bEnableSpectatorDeathCam;

var config string WebScoreboardClass;
var config string WebScoreboardPath;


// ============================================================================
// Localization
// ============================================================================

var(LoadingHints) localized array<string> TextHintJailbreak;

var localized string TextDescriptionEnableJailFights;
var localized string TextWebAdminEnableJailFights;
var localized string TextWebAdminPrefixAddon;


// ============================================================================
// Variables
// ============================================================================

var private JBTagPlayer firstTagPlayerInactive;  // disconnected player chain

var private float TimeExecution;         // time for pending execution
var private float TimeRestart;           // time for pending round restart
var private JBInfoJail JailExecution;    // jail viewed during execution

var private float TimeEventFired;        // time of last fired singular event
var private array<name> ListEventFired;  // singular events fired this tick

var private float DilationTimePrev;      // last synchronized time dilation

var transient CacheManager.MutatorRecord MutatorRecord;  // for web admin hack
var private transient JBTagPlayer TagPlayerRestart;  // player being restarted


// ============================================================================
// InitGame
//
// Initializes the game and interprets Jailbreak-specific parameters.
// ============================================================================

event InitGame(string Options, out string Error)
{
  local int iCharSeparator;
  local string OptionAddon;
  local string OptionJailFights;
  local string NameAddon;

  Super.InitGame(Options, Error);

  if (HasOption(Options, "Addon"))
    OptionAddon = ParseOption(Options, "Addon");
  else
    OptionAddon = Addons;

  while (OptionAddon != "") {
    iCharSeparator = InStr(OptionAddon, ",");
    if (iCharSeparator < 0)
      iCharSeparator = Len(OptionAddon);

    NameAddon = Left(OptionAddon, iCharSeparator);
    OptionAddon = Mid(OptionAddon, iCharSeparator + 1);

    Log("Add Jailbreak add-on" @ NameAddon);
    AddMutator(NameAddon, True);
  }

  OptionJailFights = ParseOption(Options, "JailFights");
  if (OptionJailFights != "")
    bEnableJailFights = bool(OptionJailFights);

  bForceRespawn    = True;
  bTeamScoreRounds = False;
  MaxLives         = 0;
}


// ============================================================================
// AddMutator
//
// Loads and adds a mutator to the mutator list. Works like its inherited
// version, but checks whether the given mutator is loaded already first; by
// doing that it never happens that any of the default add-ons are loaded
// several times.
// ============================================================================

function AddMutator(string NameMutator, optional bool bUserAdded)
{
  local Mutator thisMutator;

  for (thisMutator = BaseMutator; thisMutator != None; thisMutator = thisMutator.NextMutator)
    if (string(thisMutator.Class) ~= NameMutator)
      return;

  Super.AddMutator(NameMutator, bUserAdded);
}


// ============================================================================
// GetAllLoadHints
//
// Returns hints for this game type.
// ============================================================================

static function array<string> GetAllLoadHints(optional bool bThisClassOnly)
{
  local int iHint;
  local array<string> Hints;

  if (!bThisClassOnly || Default.TextHintJailbreak.Length == 0)
    Hints = Super.GetAllLoadHints();

  for (iHint = 0; iHint < Default.TextHintJailbreak.Length; iHint++)
    Hints[Hints.Length] = Default.TextHintJailbreak[iHint];

  return Hints;
}


// ============================================================================
// FillPlayInfo
//
// Adds Jailbreak-specific settings to the PlayInfo object.
// ============================================================================

static function FillPlayInfo(PlayInfo PlayInfo)
{
  Super.FillPlayInfo(PlayInfo);

  PlayInfo.AddSetting("Game", "bEnableJailFights", Default.TextWebAdminEnableJailFights, 0, 60, "Check");
}


// ============================================================================
// GetDescriptionText
//
// Returns hints for Jailbreak options. Also hooks the Add-Ons tab into the
// menu system.
// ============================================================================

static event string GetDescriptionText(string Property)
{
  Class'JBGUIHook'.Static.Hook();

  if (Property ~= "bEnableJailFights")
    return Default.TextDescriptionEnableJailFights;

  return Super.GetDescriptionText(Property);
}


// ============================================================================
// AcceptPlayInfoProperty
//
// Hides several properties from the web admin interface that don't apply for
// Jailbreak games.
// ============================================================================

static event bool AcceptPlayInfoProperty(string Property)
{
  if (Property ~= "MaxLives"         ||
      Property ~= "bForceRespawn"    ||
      Property ~= "bTeamScoreRounds")
    return False;

  return Super.AcceptPlayInfoProperty(Property);
}


// ============================================================================
// ReadAddonsForWebAdmin
//
// Reads the list of Jailbreak Add-Ons and adds them to the mutators list of
// the web admin interface.
// ============================================================================

function ReadAddonsForWebAdmin()
{
  local int iClassAddon;
  local int iInfoAddon;
  local string NameClassAddon;
  local Class<JBAddon> ClassAddon;
  local Mutator thisMutator;
  local UTServerAdmin UTServerAdmin;

  foreach AllObjects(Class'UTServerAdmin', UTServerAdmin)
    break;

  if (UTServerAdmin == None)
    return;  // web admin not running

  while (True) {
    NameClassAddon = GetNextInt("JBAddon", iClassAddon++);
    if (NameClassAddon == "")
      break;

    ClassAddon = Class<JBAddon>(DynamicLoadObject(NameClassAddon, Class'Class', True));
    if (ClassAddon == None ||
        ClassAddon.Default.FriendlyName == Class'JBAddon'.Default.FriendlyName)
      continue;

    // workaround for the MutatorRecord struct members being marked constant
    SetPropertyText("MutatorRecord", "("
      $ "ClassName"    $ "=\"" $ NameClassAddon                                            $ "\","
      $ "FriendlyName" $ "=\"" $ TextWebAdminPrefixAddon @ ClassAddon.Default.FriendlyName $ "\","
      $ "Description"  $ "=\"" $                           ClassAddon.Default.Description  $ "\","
      $ "GroupName"    $ "=\"" $                           ClassAddon.Default.GroupName    $ "\")");

    iInfoAddon = UTServerAdmin.AllMutators.Length;
    UTServerAdmin.AllMutators[iInfoAddon] = MutatorRecord;

    for (thisMutator = BaseMutator; thisMutator != None; thisMutator = thisMutator.NextMutator)
      if (thisMutator.bUserAdded &&
          thisMutator.Class == ClassAddon)
        UTServerAdmin.AIncMutators.Add(string(iInfoAddon), NameClassAddon);

    UTServerAdmin.AExcMutators.Add(string(iInfoAddon), NameClassAddon);
  }
}


// ============================================================================
// SetupWebScoreboard
//
// Sets up the Jailbreak Web Scoreboard if the web server is running.
// ============================================================================

function SetupWebScoreboard()
{
  local int iWebApplication;
  local WebServer WebServer;
  local WebApplication WebApplicationScoreboard;
  local Class<WebApplication> ClassWebApplicationScoreboard;

  foreach DynamicActors(Class'WebServer', WebServer)
    break;

  if (WebServer == None)
    return;  // web server not running

  for (iWebApplication = 0; iWebApplication < ArrayCount(WebServer.ApplicationObjects); iWebApplication++)
    if (WebServer.ApplicationObjects[iWebApplication] == None)
      break;

  if (iWebApplication >= ArrayCount(WebServer.ApplicationObjects))
    return;  // no empty application slot found

  ClassWebApplicationScoreboard = Class<WebApplication>(DynamicLoadObject(WebScoreboardClass, Class'Class', True));
  if (ClassWebApplicationScoreboard == None)
    return;

  WebApplicationScoreboard = new(None) ClassWebApplicationScoreboard;
  WebApplicationScoreboard.Level     = Level;
  WebApplicationScoreboard.WebServer = WebServer;
  WebApplicationScoreboard.Path      = WebScoreboardPath;
  WebApplicationScoreboard.Init();

  WebServer.ApplicationObjects[iWebApplication] = WebApplicationScoreboard;
  WebServer.ApplicationPaths  [iWebApplication] = WebScoreboardPath;
}


// ============================================================================
// PostBeginPlay
//
// Spawns JBTagTeam actors for both teams. Reads the add-on list for the web
// admin interface. Sets up the Jailbreak Web Scoreboard. Calls InitAddon for
// all already registered add-ons.
// ============================================================================

event PostBeginPlay()
{
  local Mutator thisMutator;

  Super.PostBeginPlay();

  Class'JBTagTeam'.Static.SpawnFor(Teams[0]);
  Class'JBTagTeam'.Static.SpawnFor(Teams[1]);

  ReadAddonsForWebAdmin();
  SetupWebScoreboard();

  for (thisMutator = BaseMutator; thisMutator != None; thisMutator = thisMutator.NextMutator)
    if (JBAddon(thisMutator) != None)
      JBAddon(thisMutator).InitAddon();
}


// ============================================================================
// Login
//
// Gives every player new JBTagPlayer and JBTagClient actors.
// ============================================================================

event PlayerController Login(string Portal, string Options, out string Error)
{
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

function Bot SpawnBot(optional string NameBot)
{
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

function InitPlacedBot(Controller Controller, RosterEntry RosterEntry)
{
  if (Bot(Controller) != None)
    Super.InitPlacedBot(Controller, RosterEntry);
}


// ============================================================================
// Logout
//
// Destroys the JBTagPlayer and JBTagClient actors for the given player or bot
// if one exists. Reassesses the leaving player's team.
// ============================================================================

function Logout(Controller ControllerExiting)
{
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

function bool ChangeTeam(Controller ControllerPlayer, int iTeam, bool bNewTeam)
{
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

function ReAssessTeam(TeamInfo Team)
{
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
// GetFirstJBGameRules
//
// Finds the first JBGameRules actor in the GameRules chain. Returns None if
// none is found.
// ============================================================================

function JBGameRules GetFirstJBGameRules()
{
  local GameRules thisGameRules;

  for (thisGameRules = GameRulesModifiers; thisGameRules != None; thisGameRules = thisGameRules.NextGameRules)
    if (JBGameRules(thisGameRules) != None)
      return JBGameRules(thisGameRules);

  return None;
}


// ============================================================================
// FindPlayerStart
//
// Finds out where the restarted player should be spawned at and communicates
// it to the RatePlayerStart function.
// ============================================================================

function NavigationPoint FindPlayerStart(Controller Controller, optional byte iTeam, optional string Teleporter)
{
  if (Controller == None)
         TagPlayerRestart = None;
    else TagPlayerRestart = Class'JBTagPlayer'.Static.FindFor(Controller.PlayerReplicationInfo);

  return Super.FindPlayerStart(Controller, iTeam, Teleporter);
}


// ============================================================================
// RatePlayerStart
//
// Returns a negative value for all starts that are inappropriate for the
// given player's scheduled respawn area.
// ============================================================================

function float RatePlayerStart(NavigationPoint NavigationPoint, byte iTeam, Controller Controller)
{
  if (TagPlayerRestart == None)
    if (ContainsActorJail (NavigationPoint) ||
        ContainsActorArena(NavigationPoint))
           return -20000000;  // prefer spawn-fragging over jail or arena
      else return Super.RatePlayerStart(NavigationPoint, iTeam, Controller);

  if (TagPlayerRestart.IsStartValid(NavigationPoint))
    if (TagPlayerRestart.IsStartPreferred(NavigationPoint))
           return Super.RatePlayerStart(NavigationPoint, iTeam, Controller) + 10000000;
      else return Super.RatePlayerStart(NavigationPoint, iTeam, Controller);
  
  return -20000000;  // prefer spawn-fragging over inappropriate start spots
}


// ============================================================================
// AddGameSpecificInventory
//
// Adds game-specific inventory. Skips the translocator if the player has
// restarted in jail.
// ============================================================================

function AddGameSpecificInventory(Pawn PawnPlayer)
{
  local bool bAllowTransPrev;
  local JBTagPlayer TagPlayer;

  bAllowTransPrev = bAllowTrans;

  TagPlayer = Class'JBTagPlayer'.Static.FindFor(PawnPlayer.PlayerReplicationInfo);
  if (TagPlayer != None &&
      TagPlayer.IsInJail())
    bAllowTrans = False;

  Super.AddGameSpecificInventory(PawnPlayer);

  bAllowTrans = bAllowTransPrev;
}


// ============================================================================
// PickupQuery
//
// Prevents arena combatants from picking up adrenaline.
// ============================================================================

function bool PickupQuery(Pawn PawnPlayer, Pickup Pickup)
{
  local JBTagPlayer TagPlayer;

  if (AdrenalinePickup(Pickup) != None) {
    TagPlayer = Class'JBTagPlayer'.Static.FindFor(PawnPlayer.PlayerReplicationInfo);
    if (TagPlayer != None &&
        TagPlayer.IsInArena())
      return False;
  }
  
  return Super.PickupQuery(PawnPlayer, Pickup);
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
      TagPlayerVictim.GetJail() == TagPlayerInstigator.GetJail() &&
     !TagPlayerVictim.GetJail().IsReleaseActive(PawnVictim.PlayerReplicationInfo.Team))
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
// Sets the killed player's restart time with a short delay for effect. If the
// victim was killed in jail, forwards further handling to a special function
// instead of the default handling.
// ============================================================================

function Killed(Controller ControllerKiller, Controller ControllerVictim, Pawn PawnVictim,
                Class<DamageType> ClassDamageType) {

  local JBTagPlayer TagPlayerVictim;

  if (ControllerVictim != None)
    TagPlayerVictim = Class'JBTagPlayer'.Static.FindFor(ControllerVictim.PlayerReplicationInfo);

  if (TagPlayerVictim != None)
    TagPlayerVictim.TimeRestart = Level.TimeSeconds + 2.0;

  if (TagPlayerVictim != None &&
      TagPlayerVictim.IsInJail())
    KilledInJail(ControllerKiller, ControllerVictim, PawnVictim, ClassDamageType);
  else
    Super.Killed(ControllerKiller, ControllerVictim, PawnVictim, ClassDamageType);
}


// ============================================================================
// KilledInJail
//
// Called when a player is killed in jail. Unlike the normal Killed event,
// skips all statistics and spree logging and does not award adrenaline.
// ============================================================================

function KilledInJail(Controller ControllerKiller, Controller ControllerVictim, Pawn PawnVictim,
                      Class<DamageType> ClassDamageType) {

  BroadcastDeathMessage(ControllerKiller, ControllerVictim, ClassDamageType);

  if (ControllerVictim != None)
    ScoreKill(ControllerKiller, ControllerVictim);

  DiscardInventory(PawnVictim);
  NotifyKilled(ControllerKiller, ControllerVictim, PawnVictim);
}


// ============================================================================
// ScoreKill
//
// Translates kills into ScorePlayer calls according to Jailbreak rules.
// ============================================================================

function ScoreKill(Controller ControllerKiller, Controller ControllerVictim)
{
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

  else if (TagPlayerVictim != None &&
           TagPlayerVictim.IsInArena())
    ScorePlayer(ControllerKiller, 'ArenaAttack');

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
      else ScorePlayer(ControllerKiller, 'Attack');

    ControllerKiller.PlayerReplicationInfo.Kills  += 1;
    ControllerVictim.PlayerReplicationInfo.Deaths += 1;
  }
}


// ============================================================================
// ScoreKillAdjust
//
// Performs bot skill adjustments as implemented in ScoreKill in DeathMatch.
// ============================================================================

function ScoreKillAdjust(Controller ControllerKiller, Controller ControllerVictim)
{
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

function ScoreKillTaunt(Controller ControllerKiller, Controller ControllerVictim)
{
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

function ScorePlayer(Controller Controller, name Event)
{
  local JBTagPlayer TagPlayer;

  TagPlayer = Class'JBTagPlayer'.Static.FindFor(Controller.PlayerReplicationInfo);
  if (TagPlayer == None)
    return;

  switch (Event) {
    case 'Suicide':       ScoreObjective(Controller.PlayerReplicationInfo, -1);  break;
    case 'Teamkill':      ScoreObjective(Controller.PlayerReplicationInfo, -1);  break;
    case 'Attack':        ScoreObjective(Controller.PlayerReplicationInfo, +1);  TagPlayer.ScorePartialAttack  += 1;  break;
    case 'Defense':       ScoreObjective(Controller.PlayerReplicationInfo, +2);  TagPlayer.ScorePartialDefense += 1;  break;
    case 'Release':       ScoreObjective(Controller.PlayerReplicationInfo, +1);  TagPlayer.ScorePartialRelease += 1;  break;
    case 'Capture':       ScoreObjective(Controller.PlayerReplicationInfo, +1);  break;
    case 'ArenaAttack':   ScoreObjective(Controller.PlayerReplicationInfo, +2);  break;
  }

  switch (Event) {
    case 'Defense':       Controller.AwardAdrenaline(ADR_MinorBonus);  break;
    case 'Release':       Controller.AwardAdrenaline(ADR_MinorBonus);  break;
    case 'ArenaVictory':  Controller.AwardAdrenaline(ADR_MinorBonus);  break;
  }
}


// ============================================================================
// BroadcastDeathMessage
//
// Broadcasts death messages concerning suicides or kills in jail only to all
// jailed players of that team.
// ============================================================================

function BroadcastDeathMessage(Controller ControllerKiller, Controller ControllerVictim, Class<DamageType> DamageType)
{
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
      else SwitchMessage = 0;  // homicide

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

function bool CanSpectate(PlayerController PlayerViewer, bool bOnlySpectator, Actor ViewTarget)
{
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

function bool CanFireEvent(name EventFire, optional bool bFire)
{
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

function bool ContainsActorJail(Actor Actor, optional out JBInfoJail Jail)
{
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

function bool ContainsActorArena(Actor Actor, optional out JBInfoArena Arena)
{
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

function int CountPlayersJailed(TeamInfo Team)
{
  return Class'JBTagTeam'.Static.FindFor(Team).CountPlayersJailed();
}


// ============================================================================
// CountPlayersTotal
//
// Forwarded to CountPlayersTotal in JBTagTeam.
// ============================================================================

function int CountPlayersTotal(TeamInfo Team)
{
  return Class'JBTagTeam'.Static.FindFor(Team).CountPlayersTotal();
}


// ============================================================================
// IsCaptured
//
// Returns whether the given team has been captured.
// ============================================================================

function bool IsCaptured(TeamInfo Team)
{
  if (CountPlayersTotal(Team) == 0)
    return False;

  return CountPlayersJailed(Team) == CountPlayersTotal(Team);
}


// ============================================================================
// FindJailExecution
//
// Finds the jail which contains most players from the executed team. Used to
// select which camera array to activate for the execution sequence.
// ============================================================================

function JBInfoJail FindJailExecution(TeamInfo TeamExecuted)
{
  local int nPlayersJailed;
  local int nPlayersJailedBest;
  local JBInfoJail firstJail;
  local JBInfoJail thisJail;
  local JBInfoJail JailBest;

  firstJail = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstJail;
  for (thisJail = firstJail; thisJail != None; thisJail = thisJail.nextJail) {
    nPlayersJailed = thisJail.CountPlayers(TeamExecuted);
    if (JailBest == None || nPlayersJailed > nPlayersJailedBest) {
      JailBest = thisJail;
      nPlayersJailedBest = nPlayersJailed;
    }
  }

  return JailBest;
}


// ============================================================================
// RestartAll
//
// Restarts all players in freedom.
// ============================================================================

function RestartAll()
{
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

function RestartTeam(TeamInfo Team)
{
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

function bool IsReleaseActive(TeamInfo Team)
{
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
// announces a tie and starts a new round. If exactly one, commits execution.
// Can only be called in the default state.
// ============================================================================

function bool ExecutionInit()
{
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
// Prepares and commits a team's execution. Selects a jail to view during the
// execution sequence, respawns all other players, scores and announces the
// capture.
// ============================================================================

function ExecutionCommit(TeamInfo TeamExecuted)
{
  local Controller thisController;
  local JBCamera thisCamera;
  local JBInfoJail firstJail;
  local JBInfoJail thisJail;
  local JBGameRules firstJBGameRules;
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

    JailExecution = FindJailExecution(TeamExecuted);

    if (bEnableSpectatorDeathCam)
      for (thisController = Level.ControllerList; thisController != None; thisController = thisController.NextController)
        if (thisController.PlayerReplicationInfo != None &&
            thisController.PlayerReplicationInfo.bOnlySpectator)
          JailExecution.ActivateCameraFor(thisController);

    TeamCapturer = OtherTeam(TeamExecuted);
    TeamCapturer.Score += 1;
    RestartTeam(TeamCapturer);

    firstJail = JBGameReplicationInfo(GameReplicationInfo).firstJail;
    for (thisJail = firstJail; thisJail != None; thisJail = thisJail.nextJail)
      thisJail.ExecutionInit();

    firstJBGameRules = GetFirstJBGameRules();
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

function ExecutionEnd()
{
  local Controller thisController;
  local JBCamera Camera;
  local JBInfoJail firstJail;
  local JBInfoJail thisJail;
  local JBGameRules firstJBGameRules;

  if (IsInState('Executing')) {
    firstJail = JBGameReplicationInfo(GameReplicationInfo).firstJail;
    for (thisJail = firstJail; thisJail != None; thisJail = thisJail.nextJail)
      thisJail.ExecutionEnd();

    firstJBGameRules = GetFirstJBGameRules();
    if (firstJBGameRules != None)
      firstJBGameRules.NotifyExecutionEnd();

    GotoState('MatchInProgress');
    RestartAll();

    if (bEnableSpectatorDeathCam)
      for (thisController = Level.ControllerList; thisController != None; thisController = thisController.NextController)
        if (thisController.PlayerReplicationInfo != None &&
            thisController.PlayerReplicationInfo.bOnlySpectator) {
          Camera = JBCamera(PlayerController(thisController).ViewTarget);
          if (Camera != None)
            Camera.DeactivateFor(thisController);
        }

    if ((Teams[0].Score >= GoalScore ||
         Teams[1].Score >= GoalScore) && GoalScore > 0)
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

  event BeginState()
  {
    local JBTagPlayer firstTagPlayer;
    local JBTagPlayer thisTagPlayer;
    local JBGameReplicationInfo InfoGame;
    local JBGameRules firstJBGameRules;

    if (bWaitingToStartMatch)
      Super.BeginState();

    JBBotTeam(Teams[0].AI).ResetOrders();
    JBBotTeam(Teams[1].AI).ResetOrders();

    firstJBGameRules = GetFirstJBGameRules();
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

  event Timer()
  {
    local bool bSynchronizeTime;
    local int iTeam;

    bSynchronizeTime = ElapsedTime % 30 == 0 ||
                       ElapsedTime != GameReplicationInfo.ElapsedTime ||
                       DilationTimePrev != Level.TimeDilation;

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

    if (bSynchronizeTime) {
      JBGameReplicationInfo(GameReplicationInfo).SynchronizeMatchTimer(ElapsedTime);
      DilationTimePrev = Level.TimeDilation;
    }
  }


  // ================================================================
  // RestartPlayer
  //
  // Notifies both bot teams of the respawn.
  // ================================================================

  function RestartPlayer(Controller Controller)
  {
    local JBTagPlayer TagPlayer;

    TagPlayer = Class'JBTagPlayer'.Static.FindFor(Controller.PlayerReplicationInfo);
    if (TagPlayer.TimeRestart > Level.TimeSeconds)
      return;

    Global.RestartPlayer(Controller);

    if (TagPlayer != None)
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

  event EndState()
  {
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

  event BeginState()
  {
    JBGameReplicationInfo(GameReplicationInfo).bIsExecuting = True;
  }


  // ================================================================
  // Timer
  //
  // Checks whether there are still players alive in jail. If not,
  // sets TimeRestart for a brief delay. If TimeRestart is set and
  // has passed, resets TimeRestart and calls ExecutionEnd.
  // ================================================================

  event Timer()
  {
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
          thisTagPlayer.GetPawn() == None)
        thisTagPlayer.RestartInFreedom();
  }


  // ================================================================
  // RestartPlayer
  //
  // Puts the given player in spectator mode and activates the
  // execution cam for him or her.
  // ================================================================

  function RestartPlayer(Controller Controller)
  {
    local JBTagPlayer TagPlayer;

    JailExecution.ActivateCameraFor(Controller);

    TagPlayer = Class'JBTagPlayer'.Static.FindFor(Controller.PlayerReplicationInfo);
    TagPlayer.NotifyRestarted();
  }


  // ================================================================
  // EndState
  //
  // Resets the bIsExecuting flag in JBGameReplicationInfo.
  // ================================================================

  event EndState()
  {
    JBGameReplicationInfo(GameReplicationInfo).bIsExecuting = False;
  }

} // state Executing


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  Build = "%%%%-%%-%% %%:%%";

  Description = "Two teams face off to send the other team's players to jail by fragging them. When all members of a team are in jail, the opposing team scores a point."

  TextHintJailbreak[ 0] = "Watch the compass dots: The faster they pulse, the more players can be released by the corresponding switch."
  TextHintJailbreak[ 1] = "Use %PREVWEAPON% and %NEXTWEAPON% to switch view points when watching through a surveillance camera."
  TextHintJailbreak[ 2] = "You can stand on teammates while they're crouching. Look out for jail escape routes requiring this cooperation!"
  TextHintJailbreak[ 3] = "Some jails have hidden escape routes. You may have to stand on a crouching teammate to reach them."
  TextHintJailbreak[ 4] = "There may be more than one release switch for your team. The faster a compass dot pulses, the more players can be released through the corresponding switch."
  TextHintJailbreak[ 5] = "Sometimes it is better to hide away from the enemy team rather than to give them an easy capture."
  TextHintJailbreak[ 6] = "If you killed the last free enemy, you can taunt the enemy team on the celebration screen during the execution sequence."
  TextHintJailbreak[ 7] = "Bored in jail? You can fight your teammates for fun with the Shield Gun without any penalties."
  TextHintJailbreak[ 8] = "Some jails contain monitors for surveillance cameras showing important spots in the map. Approach one of them to activate the camera."
  TextHintJailbreak[ 9] = "When you're jailed, you may be chosen for an arena match with a jailed enemy. Win the match to gain your freedom!"
  TextHintJailbreak[10] = "When an arena match is going on, press %ARENACAM% to watch a live feed!"
  TextHintJailbreak[11] = "Use %TEAMTACTICS UP% to increase and %TEAMTACTICS DOWN% to decrease the overall aggressiveness of the bots on your team."
  TextHintJailbreak[12] = "The Jailbreak scoreboard shows the whereabouts of you and your teammates in a panorama minimap."
  TextHintJailbreak[13] = "You can see what your human teammates are up to on the Jailbreak scoreboard: It shows whether they are attacking, defending or roaming the map."
  TextHintJailbreak[14] = "The red, yellow and green bars next to each player name in the Jailbreak scoreboard show that player's attack kills, defense kills and released teammates."
  TextHintJailbreak[15] = "The markers on the clock in the upper right corner of the Jailbreak scoreboard indicate team captures."
  TextHintJailbreak[16] = "Don't try to cheat by reconnecting to the server while you're in jail! The game will turn you into a llama (quite literally) and give other players bonus points for hunting you down."
  TextHintJailbreak[17] = "Don't attack protected players who were just released from jail. You might get llamaized for it!"

  TextDescriptionEnableJailFights = "Allows jail inmates to fight each other with their Shield Guns for fun."
  TextWebAdminEnableJailFights    = "Allow Jail Fights";
  TextWebAdminPrefixAddon         = "Jailbreak:";

  WebScoreboardClass = "Jailbreak.JBWebApplicationScoreboard";
  WebScoreboardPath  = "/scoreboard";

  Addons = "JBAddonCelebration.JBAddonCelebration,JBAddonLlama.JBAddonLlama,JBAddonProtection.JBAddonProtection";
  bEnableJailFights        = True;
  bEnableSpectatorDeathCam = True;
  GoalScore                = 5;

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
  bScoreTeamKills  = False;
  bAllowVehicles   = True;
}