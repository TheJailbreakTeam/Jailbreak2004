// JBDecoSwitchKey
// Copyright 2004 by tarquin <tarquin@beyondunreal.com>
// $Id$
//
// Displays the Jailbreak release switch key
//=============================================================================


class JBDecoSwitchKey extends Decoration
  notplaceable;
  
  
// ============================================================================
// PreBeginPlay
//
// Sets the key colour to show the *captive* team
// ============================================================================

event PreBeginPlay()
{
  local JBGameObjectiveSwitch MySwitch;
  MySwitch = JBGameObjectiveSwitch( Owner );
  
  SetStaticMesh( MySwitch.StaticMeshKey );

  if( MySwitch.DefenderTeamIndex == 0 ) {
    Skins[0] = MySwitch.SkinKeyBlue;
  }
  else {
    Skins[0] = MySwitch.SkinKeyRed;
  }
  
  super.PreBeginPlay();
}


//=============================================================================
// default properties
//=============================================================================

defaultproperties
{
  DrawType    = DT_StaticMesh;
  DrawScale   = 0.500;
  
  /* blame xDomA */
  bCollideWorld=false
  bStatic=false
  Physics=PHYS_Rotating
  bStasis=false
  bFixedRotationDir=True
  
  /* blame Spoon */
  AmbientGlow=255
  Style=STY_Translucent
  bCollideActors=False
  bBlockActors=False
  bBlockPlayers=False
  bBlockNonZeroExtentTraces=False
  RotationRate=(Yaw=24000)
}

