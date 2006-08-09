// ============================================================================
// JBGameObjectiveSwitch
// Copyright 2004 by tarquin <tarquin@beyondunreal.com>
// $Id: JBGameObjectiveSwitch.uc,v 1.15 2006-08-08 22:23:09 jrubzjeknf Exp $
//
// Visible release switch that must be touched to be disabled.
// ============================================================================


class JBGameObjectiveSwitch extends GameObjective
  placeable;


// ============================================================================
// Imports
// ============================================================================

#exec obj load file=StaticMeshes\JBReleaseBase.usx     package=JBToolbox.SwitchMeshes
#exec obj load file=Textures\JBReleaseTexturesBase.utx package=JBToolbox.SwitchSkins


// ============================================================================
// Replication
// ============================================================================

replication
{
  reliable if (Role == ROLE_Authority)
    bDisabledRep, bJammedRep;
}


// ============================================================================
// Properties
// ============================================================================

var() array<Class<Decoration> > ListClassDecoration;


// ============================================================================
// Variables
// ============================================================================

var bool bDisabledRep;                  // replicated flag
var bool bDisabledPrev;                 // previous state of flag
var bool bJammedRep;                    // Jammed, replicated flag
var bool bJammedPrev;                   // Jammed, previous state of flag
var bool bReverseSwitchColors;          // Nostalgia mode

var array<Decoration> ListDecoration;   // references to the decoration actors


// ============================================================================
// PostBeginPlay
//
// Spawns the visible parts of the switch client-side.
// ============================================================================

simulated function PostBeginPlay()
{
  local int iDecoration;

  if (Level.NetMode != NM_DedicatedServer)
    for (iDecoration = 0; iDecoration < ListClassDecoration.Length; iDecoration++)
      ListDecoration[iDecoration] = Spawn(
        ListClassDecoration[iDecoration], Self, ,
        ListClassDecoration[iDecoration].Default.Location + Location,
        ListClassDecoration[iDecoration].Default.Rotation + Rotation);

  Super.PostBeginPlay();
}


// ============================================================================
// DisableObjective
//
// Disables this objective if instigated by a player not of the defending
// team. If no players will be released by this action, plays a message.
// ============================================================================

function DisableObjective(Pawn PawnInstigator)
{
  local int nPlayersReleasable;
  local PlayerController PlayerControllerInstigator;
  local JBGameObjectiveSwitch ObjectiveSwitch;
  local JBInfoJail thisJail;

  if (bDisabled                                         ||
      PawnInstigator                            == None ||
      PawnInstigator.PlayerReplicationInfo      == None ||
      PawnInstigator.PlayerReplicationInfo.Team == None ||
      PawnInstigator.PlayerReplicationInfo.Team.TeamIndex == DefenderTeamIndex ||
      Vehicle(PawnInstigator) != none ||
      RedeemerWarhead(PawnInstigator) != None)
    return;

  Super.DisableObjective(PawnInstigator);

  Instigator = PawnInstigator;

  foreach AllActors(class'JBGameObjectiveSwitch', ObjectiveSwitch)
    if(ObjectiveSwitch.Event == Event)
      ObjectiveSwitch.SetCollision(False, False, False);

  PlayerControllerInstigator = PlayerController(PawnInstigator.Controller);
  if (PlayerControllerInstigator != None) {
    foreach DynamicActors(Class'JBInfoJail', thisJail, Event)
      nPlayersReleasable += thisJail.CountPlayers(PawnInstigator.PlayerReplicationInfo.Team);

    if (nPlayersReleasable == 0)
      Level.Game.BroadcastHandler.BroadcastLocalized(
        Self,
        PlayerControllerInstigator,
        MessageClass, 210,
        PawnInstigator.PlayerReplicationInfo, ,
        PawnInstigator.PlayerReplicationInfo.Team);
  }
}


// ============================================================================
// Reset
//
// Resets this actor to its default state. Restores its collision properties.
// Updates whether or not this GameObjective is jammed.
// ============================================================================

function Reset()
{
  local JBGameObjectiveSwitch ObjectiveSwitch;

  Super.Reset();

  bJammedRep = class'JBInfoJail'.static.ObjectiveIsJammed(Self, abs(DefenderTeamIndex-1));

  foreach AllActors(class'JBGameObjectiveSwitch', ObjectiveSwitch)
    if(ObjectiveSwitch.Event == Event)
      ObjectiveSwitch.SetCollision(
        Default.bCollideActors,  // resetting the collision will
        Default.bBlockActors,    // implicitly call Touch again if a
        Default.bBlockPlayers);  // player is still touching this actor
}


// ============================================================================
// JamObjective
//
// Freezes the lock.
// ============================================================================

private simulated function JamObjective()
{
  if (JBDecoSwitchBasket(ListDecoration[0]) != None &&
      JBDecoSwitchBasket(ListDecoration[0]).Emitter != None)
    JBDecoSwitchBasket(ListDecoration[0]).Emitter.GotoState('Disabled'); // Hide emitter.

  if (JBDecoSwitchPadlock(ListDecoration[1]) != None) {
    JBDecoSwitchPadlock(ListDecoration[1]).Disable('Tick'); // Stops pulsing and swaying.
    JBDecoSwitchPadlock(ListDecoration[1]).RotationRate.Yaw = 0; // Stops rotating.
  }
}

// ============================================================================
// UnJamObjective
//
// Unfreezes the lock.
// ============================================================================

private simulated function UnJamObjective()
{
  if (JBDecoSwitchBasket(ListDecoration[0]) != None &&
      JBDecoSwitchBasket(ListDecoration[0]).Emitter != None)
    JBDecoSwitchBasket(ListDecoration[0]).Emitter.GotoState('Enabled'); // Show emitter.

  if (JBDecoSwitchPadlock(ListDecoration[1]) != None) {
    JBDecoSwitchPadlock(ListDecoration[1]).Enable('Tick'); // Starts movement.
    JBDecoSwitchPadlock(ListDecoration[1]).RotationRate.Yaw = 4800; // Starts rotating.
  }
}


// ============================================================================
// Tick
//
// Communicates the state of the bDisabled variable to all clients and, on the
// clients, updates the visual state of the switch according to bDisabled.
// ============================================================================

simulated event Tick(float TimeDelta)
{
  local int i;
  local int TeamIndex;

  if (Role == ROLE_Authority && bDisabledRep != bDisabled)
    bDisabledRep = bDisabled;

  if(Class'Jailbreak'.Default.bReverseSwitchColors != bReverseSwitchColors)
  {
    bReverseSwitchColors = Class'Jailbreak'.Default.bReverseSwitchColors;

    TeamIndex = DefenderTeamIndex;
    if(bReverseSwitchColors)
      TeamIndex = abs(TeamIndex-1);

    for(i=0; i<ListDecoration.Length; i++)
      if(JBDecoSwitchBasket(ListDecoration[i]) != None)
        if(JBDecoSwitchBasket(ListDecoration[i]).Emitter != None)
          JBDecoSwitchBasket(ListDecoration[i]).Emitter.SetDefendingTeam(TeamIndex);
  }

  if (Level.NetMode != NM_DedicatedServer && bDisabledRep != bDisabledPrev) {
    bDisabledPrev = bDisabledRep;
    if (bDisabledRep)
      DoEffectDisabled();
    else
      DoEffectReset();
  }

  if (Level.NetMode != NM_DedicatedServer &&
     !bDisabledRep &&                         //jam when active again
      bJammedRep != bJammedPrev) {
    bJammedPrev = bJammedRep;
    if (bJammedRep)
      JamObjective();
    else
      UnJamObjective();
  }
}


// ============================================================================
// DoEffectDisabled
//
// Triggers the visual key and ring actors.
// ============================================================================

simulated function DoEffectDisabled()
{
  local int iDecoration;

  for (iDecoration = 0; iDecoration < ListDecoration.Length; iDecoration++)
    ListDecoration[iDecoration].Trigger(Self, Instigator);
}


// ============================================================================
// DoEffectReset
//
// Untriggers the visual key and ring actors.
// ============================================================================

simulated function DoEffectReset()
{
  local int iDecoration;

  for (iDecoration = 0; iDecoration < ListDecoration.Length; iDecoration++)
    ListDecoration[iDecoration].UnTrigger(Self, Instigator);
}


// ============================================================================
// Touch
//
// Disables this objective when touched by a player.
// ============================================================================

event Touch(Actor ActorOther)
{
  if (Pawn(ActorOther) != None &&
     !bJammedRep)                  //no releasing when jammed
    DisableObjective(Pawn(ActorOther));
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  /* touchability */
  bCollideActors         = True;
  bBlockActors           = False;
  bBlockPlayers          = False;
  bUseCylinderCollision  = True;
  CollisionRadius        = 60.0;
  CollisionHeight        = 40.0;

  /* mapper convenience */
  bEdShouldSnap          = True;
  PrePivot               = (Z=44.0);

  /* remove destruction message */
  DestructionMessage     = "";

  /* set score to zero */
  Score                  = 0;

  /* base */
  bHidden                = False;
  DrawType               = DT_StaticMesh;
  StaticMesh             = StaticMesh'JBReleaseBase';
  Skins[0]               = Texture'JBReleaseBaseNeutral';

  /* visible animated parts */
  ListClassDecoration[0] = Class'JBDecoSwitchBasket';
  ListClassDecoration[1] = Class'JBDecoSwitchPadlock';

  /* network */
  RemoteRole             = ROLE_SimulatedProxy;
  bStatic                = False;
  bNoDelete              = True;
  bAlwaysRelevant        = True;
  bReplicateInstigator   = True;

  /* messages */
  MessageClass           = Class'Jailbreak.JBLocalMessage';
}
