// ============================================================================
// JBGameObjectiveSwitch
// Copyright 2004 by tarquin <tarquin@beyondunreal.com>
// $Id$
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
    bDisabledRep;
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
// Disables this objective if instigated by a player not of the defending team.
// ============================================================================

function DisableObjective(Pawn PawnInstigator) 
{
  local JBGameObjectiveSwitch ObjectiveSwitch;
  
  if (PawnInstigator                            == None ||
      PawnInstigator.PlayerReplicationInfo      == None ||
      PawnInstigator.PlayerReplicationInfo.Team == None ||
      PawnInstigator.PlayerReplicationInfo.Team.TeamIndex == DefenderTeamIndex)
    return;

  bDisabledRep = True;
  Super.DisableObjective(PawnInstigator);

  Instigator = PawnInstigator;
  
  foreach AllActors(class'JBGameObjectiveSwitch', ObjectiveSwitch) {
    if(ObjectiveSwitch.Event == Event) {
      ObjectiveSwitch.SetCollision(False, False, False);
      ObjectiveSwitch.DoEffectDisabled();
    }
  }
}


// ============================================================================
// Reset
//
// Resets this actor to its default state. Restores its collision properties.
// ============================================================================

function Reset() 
{
  local JBGameObjectiveSwitch ObjectiveSwitch;
  
  Super.Reset();
  bDisabledRep = False;

  foreach AllActors(class'JBGameObjectiveSwitch', ObjectiveSwitch) {
    if(ObjectiveSwitch.Event == Event) {
      ObjectiveSwitch.DoEffectReset();
      ObjectiveSwitch.SetCollision(
        Default.bCollideActors,  // resetting the collision will
        Default.bBlockActors,    // implicitly call Touch again if a
        Default.bBlockPlayers);  // player is still touching this actor
    }
  }
}


// ============================================================================
// PostNetReceive
//
// Triggers the visual effects client-side when the flag changes its status.
// ============================================================================

simulated event PostNetReceive()
{
  if (bDisabledRep == bDisabledPrev)
    return;
  
  if (bDisabledRep)
         DoEffectDisabled();
    else DoEffectReset();
  
  bDisabledPrev = bDisabledRep;
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
  if (Pawn(ActorOther) != None)
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
  bNetNotify             = True;
  bReplicateInstigator   = True;
}
  