//=============================================================================
// JBDecoSwitchKey
// Copyright 2004 by tarquin <tarquin@beyondunreal.com>
// $Id: JBDecoSwitchKey.uc,v 1.2 2004/03/17 16:22:55 tarquin Exp $
//
// Displays the Jailbreak release switch key
//=============================================================================


class JBDecoSwitchKey extends Decoration
  notplaceable;
  

// ============================================================================
// Imports
// ============================================================================

#exec obj load file=StaticMeshes\JBReleaseKey.usx      package=JBToolbox.SwitchMeshes
#exec obj load file=Textures\JBReleaseTexturesKey.utx  package=JBToolbox.SwitchSkins


// ============================================================================
// Properties
// ============================================================================

var() Material MaterialSkinRed;
var() Material MaterialSkinBlue;

  
// ============================================================================
// PostBeginPlay
//
// Sets the key colour to show the *captive* team
// ============================================================================

event PostBeginPlay()
{
  switch (GameObjective(Owner).DefenderTeamIndex) {
    case 0:  Skins[0] = MaterialSkinBlue;  break;
    case 1:  Skins[0] = MaterialSkinRed;   break;
  }
}


//=============================================================================
// default properties
//=============================================================================

defaultproperties
{
  RemoteRole  = ROLE_None;

  DrawType    = DT_StaticMesh;
  DrawScale   = 0.500;
  StaticMesh  = StaticMesh'JBReleaseKey';
  Location    = (Z=40.0);
  
  MaterialSkinRed  = Shader'JBKeyFinalRed';
  MaterialSkinBlue = Shader'JBKeyFinalBlue';
  
  /* blame xDomA */
  bCollideWorld=false
  bStatic=false
  Physics=PHYS_Rotating
  bStasis=false
  bFixedRotationDir=True
  
  /* blame Spoon */
  AmbientGlow=255
  //Style=STY_Translucent
  bCollideActors=False
  bBlockActors=False
  bBlockPlayers=False
  bBlockNonZeroExtentTraces=False
  RotationRate=(Yaw=24000)
}

