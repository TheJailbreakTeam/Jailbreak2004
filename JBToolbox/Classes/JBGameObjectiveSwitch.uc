//=============================================================================
// JBGameObjectiveSwitch
// Copyright 2004 by tarquin <tarquin@beyondunreal.com>
// $Id$
//
// Visible release switch that must be touched to be disabled.
//=============================================================================


class JBGameObjectiveSwitch extends GameObjective
  placeable;
  
  
// ============================================================================
// Imports
// ============================================================================

// static meshes
// #exec obj load file=..\StaticMeshes\JBRelease.usx package=JBToolbox.SwitchMeshes

#exec obj load file=StaticMeshes\JBReleaseBase.usx  package=JBToolbox.SwitchMeshes
#exec obj load file=StaticMeshes\JBReleaseRing.usx  package=JBToolbox.SwitchMeshes
#exec obj load file=StaticMeshes\JBReleaseKey.usx   package=JBToolbox.SwitchMeshes

// textures
//#exec obj load file=..\Textures\JBReleaseTextures.utx package=JBToolbox.SwitchSkins

#exec obj load file=Textures\JBReleaseTexturesBase.utx  package=JBToolbox.SwitchSkins
#exec obj load file=Textures\JBReleaseTexturesRing.utx  package=JBToolbox.SwitchSkins
#exec obj load file=Textures\JBReleaseTexturesKey.utx   package=JBToolbox.SwitchSkins


//=============================================================================
// Constants
//=============================================================================

const RED_TEAM  = 0;
const BLUE_TEAM = 1;


// ============================================================================
// Variables
// ============================================================================

var () StaticMesh     StaticMeshRing; // static mesh to display for ring
var () StaticMesh     StaticMeshKey;  // static mesh to display for key

var() Material        SkinBaseRed;    //
var() Material        SkinBaseBlue;   //
var() Material        SkinRingRed;    //
var() Material        SkinRingBlue;   //
var() Material        SkinKeyRed;     //
var() Material        SkinKeyBlue;    //

var() vector          OffsetRing;     // offset from the switch of the ring 
var() vector          OffsetKey;      // offset from the switch of the key

var JBDecoSwitchRing  SwitchRing;     // reference to the ring
var JBDecoSwitchKey   SwitchKey;      // reference to the key


// ============================================================================
// PostBeginPlay
//
// 
// ============================================================================

simulated function PostBeginPlay()
{
  Super.PostBeginPlay();
  
  // should probably check all the Material vars are actually materials
  // replace them with defaults if None?

  if (Level.NetMode != NM_Client) {
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

  // what does this do? (slurped from xDom...)
  // SetShaderStatus(CNeutralState[0],SNeutralState,CNeutralState[1]);
}


// ============================================================================
// DisableObjective
//
// Disables this objective if instigated by a player not of the defending team.
// ============================================================================

function DisableObjective(Pawn PawnInstigator) 
{
  if (PawnInstigator                            == None ||
      PawnInstigator.PlayerReplicationInfo      == None ||
      PawnInstigator.PlayerReplicationInfo.Team == None ||
      PawnInstigator.PlayerReplicationInfo.Team.TeamIndex == DefenderTeamIndex)
    return;

  SetCollision(False, False, False);

  Super.DisableObjective(PawnInstigator);
  
  // visual effects 
  SwitchRing.Trigger( self, PawnInstigator );
  //SwitchKey.bHidden = True;
  //ColorModifier(SwitchRing.Skins[0]).Color.G = 255;
  //ColorModifier(SwitchRing.Skins[0]).Color.B = 0;
}


// ============================================================================
// Reset
//
// Resets this actor to its default state. Restores its collision properties.
// ============================================================================

function Reset() 
{
  Super.Reset();

  SetCollision(Default.bCollideActors,  // resetting the collision will
               Default.bBlockActors,    // implicitly call Touch again if a
               Default.bBlockPlayers);  // player is still touching this actor
               
  // visual effects 
  SwitchRing.UnTrigger( self, none );
  //SwitchKey.bHidden = False;
  
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
  //LightType=LT_SubtlePulse
  //LightEffect=LE_QuadraticNonIncidence
  //LightRadius=6
  //LightBrightness=128 
  //LightHue=255
  //LightSaturation=255
  
  /* DDOM base mesh */
  //StaticMesh          = XGame_rc.DominationPointMesh;
  //DrawScale           = 0.60000;
  //Skins(0)=Texture'XGameTextures.DominationPointTex'            
  //Skins(1)=XGameShaders.DomShaders.DomPointACombiner
  
  /* JB base mesh */
  StaticMesh    = StaticMesh'JBToolbox.SwitchMeshes.JBReleaseBase';
  Skins(0)      = Texture'JBToolbox.SwitchSkins.JBReleaseBaseRed'; // this is just to give the mapper something pretty to look at         

  /* */
  bEdShouldSnap = True;
  bHidden       = False;
  OffsetRing    = (X=0.0,Y=0.0,Z=40.0); 
  OffsetKey     = (X=0.0,Y=0.0,Z=40.0); // = 40 (from base) 
  
  PrePivot        = (X=0.0,Y=0.0,Z=49.0);
  
  /* parent overrides */
  DestructionMessage  = "";
  
  /* display */
  // from existing packages
  //StaticMeshRing = StaticMesh'JBRelease.RevSpinner';
  //StaticMeshKey = StaticMesh'JBRelease.Key';
  //SkinRingRed   = Shader'JBReleaseTextures.Spinner.SpinnerRedTranslucent';
  //SkinRingBlue  = Shader'JBReleaseTextures.Spinner.SpinnerBlueTranslucent';
  //SkinKeyRed    = Shader'JBReleaseTextures.Key.KeyREDsh';
  //SkinKeyBlue   = Shader'JBReleaseTextures.Key.key256sh';
  
  // from this module
  StaticMeshRing  = StaticMesh'JBToolbox.SwitchMeshes.JBReleaseRing';
  StaticMeshKey   = StaticMesh'JBToolbox.SwitchMeshes.JBReleaseKey';
  
  SkinBaseRed   = Texture'JBToolbox.SwitchSkins.JBReleaseBaseRed';
  SkinBaseBlue  = Texture'JBToolbox.SwitchSkins.JBReleaseBaseBlue';
  
  SkinRingRed   = ColorModifier'JBToolbox.SwitchSkins.ColorModRed';
  SkinRingBlue  = ColorModifier'JBToolbox.SwitchSkins.ColorModBlue';
  
  SkinKeyRed    = Shader'JBToolbox.SwitchSkins.JBKeyFinalRed';
  SkinKeyBlue   = Shader'JBToolbox.SwitchSkins.JBKeyFinalBlue';

}
  