// ============================================================================
// JBGameObjectiveSwitch
// Copyright 2004 by tarquin <tarquin@beyondunreal.com>
// $Id: JBGameObjectiveSwitch.uc,v 1.3 2004/03/30 22:51:01 mychaeel Exp $
//
// Visible release switch that must be touched to be disabled.
// ============================================================================


class JBGameObjectiveSwitch extends GameObjective
  placeable;
  
  
// ============================================================================
// Imports
// ============================================================================

// static meshes
#exec obj load file=StaticMeshes\JBReleaseBase.usx  package=JBToolbox.SwitchMeshes
#exec obj load file=StaticMeshes\JBReleaseRing.usx  package=JBToolbox.SwitchMeshes
#exec obj load file=StaticMeshes\JBReleaseKey.usx   package=JBToolbox.SwitchMeshes

// textures
#exec obj load file=Textures\JBReleaseTexturesBase.utx  package=JBToolbox.SwitchSkins
#exec obj load file=Textures\JBReleaseTexturesRing.utx  package=JBToolbox.SwitchSkins
#exec obj load file=Textures\JBReleaseTexturesKey.utx   package=JBToolbox.SwitchSkins


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

var() class<Decoration> ClassRing;      // class for ring (not yet used)
var() class<Decoration> ClassKey;       // class for key (not yet used)

var() StaticMesh      StaticMeshRing;   // static mesh to display for ring
var() StaticMesh      StaticMeshKey;    // static mesh to display for key

var() Material        SkinBaseRed;      // skin for base mesh: red
var() Material        SkinBaseBlue;     // skin for base mesh: blue

var() Material        SkinRingNeutral;  // skin for ring mesh: neutral 

var() Material        SkinKeyRed;       // skin for the red key
var() Material        SkinKeyBlue;      // skin for the blue key

var() vector          OffsetRing;       // offset from the switch of the ring 
var() vector          OffsetKey;        // offset from the switch of the key


// ============================================================================
// Variables
// ============================================================================

var bool bDisabledRep;                  // replicated flag
var bool bDisabledPrev;                 // previous state of flag

var JBDecoSwitchRing  SwitchRing;       // reference to the ring
var JBDecoSwitchKey   SwitchKey;        // reference to the key


// ============================================================================
// PostBeginPlay
//
// Spawns the visible parts of the switch client-side.
// ============================================================================

simulated function PostBeginPlay()
{
  Super.PostBeginPlay();
  
  // should probably check all the Material vars are actually materials
  // replace them with defaults if None?

  if (Level.NetMode != NM_DedicatedServer) {
    SwitchRing = Spawn(
      class'JBToolbox.JBDecoSwitchRing', self, , 
      Location + OffsetRing, Rotation );
    SwitchKey = Spawn(
      class'JBToolbox.JBDecoSwitchKey', self, , 
      Location + OffsetKey, Rotation );
  }
  if( DefenderTeamIndex == 0 ) {
    Skins[0] = SkinBaseRed;
  }
  else {
    Skins[0] = SkinBaseBlue;
  }
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
  if (SwitchRing != None) SwitchRing.Trigger(Self, Instigator);
  if (SwitchKey  != None) SwitchKey .Trigger(Self, Instigator);
}


// ============================================================================
// DoEffectReset
//
// Untriggers the visual key and ring actors.
// ============================================================================

simulated function DoEffectReset()
{
  if (SwitchRing != None) SwitchRing.UnTrigger(Self, Instigator);
  if (SwitchKey  != None) SwitchKey .UnTrigger(Self, Instigator);
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
  bCollideActors  = True;
  bBlockActors    = False;
  bBlockPlayers   = False;
  bUseCylinderCollision = True;
  CollisionRadius     = 60.000000;
  CollisionHeight     = 40.000000;
  
  /* slurped from xDomPoint */
  DrawType            = DT_StaticMesh;
  Style=STY_Normal  
  
  LightType       = LT_SubtlePulse;
  LightEffect     = LE_QuadraticNonIncidence;
  LightRadius     = 6;
  LightBrightness = 128;
  LightHue        = 255;
  LightSaturation = 255;
  
  /* DDOM base mesh */
  //StaticMesh          = XGame_rc.DominationPointMesh;
  //DrawScale           = 0.60000;
  //Skins(0)=Texture'XGameTextures.DominationPointTex'            
  //Skins(1)=XGameShaders.DomShaders.DomPointACombiner
  
  /* JB base mesh */
  // this is just to give the mapper something pretty to look at
  StaticMesh    = StaticMesh'JBToolbox.SwitchMeshes.JBReleaseBase';
  Skins(0)      = Texture'JBToolbox.SwitchSkins.JBReleaseBaseRed';

  /* */
  bEdShouldSnap = True;
  bHidden       = False;
  OffsetRing    = (X=0.0,Y=0.0,Z=40.0); 
  OffsetKey     = (X=0.0,Y=0.0,Z=40.0); // = 40 (from base) 
  
  PrePivot        = (X=0.0,Y=0.0,Z=49.0);
  
  /* parent overrides */
  DestructionMessage  = "";
  
  ClassRing     = class'JBToolbox.JBDecoSwitchRing';
  ClassKey      = class'JBToolbox.JBDecoSwitchKey';
  
  /* display */
  StaticMeshRing  = StaticMesh'JBToolbox.SwitchMeshes.JBReleaseRing';
  StaticMeshKey   = StaticMesh'JBToolbox.SwitchMeshes.JBReleaseKey';
  
  SkinBaseRed   = Texture'JBToolbox.SwitchSkins.JBReleaseBaseRed';
  SkinBaseBlue  = Texture'JBToolbox.SwitchSkins.JBReleaseBaseBlue';
  
  SkinRingNeutral = Texture'JBToolbox.SwitchSkins.JBReleaseRingWhite'; 
  
  SkinKeyRed    = Shader'JBToolbox.SwitchSkins.JBKeyFinalRed';
  SkinKeyBlue   = Shader'JBToolbox.SwitchSkins.JBKeyFinalBlue';
  
  // prepivot of Z=44 works nicely on BSP surfaces. consider setting this as default

  /* network */
  RemoteRole = ROLE_SimulatedProxy;

  bStatic              = False;
  bNoDelete            = True;
  bNetNotify           = True;
  bReplicateInstigator = True;
}
  