//=============================================================================
// JBDecoSwitchKey
// Copyright 2004 by tarquin <tarquin@beyondunreal.com>
// $Id: JBDecoSwitchKey.uc,v 1.1 2004/03/15 12:47:22 tarquin Exp $
//
// Displays the Jailbreak release switch key
//=============================================================================


class JBDecoSwitchKey extends Decoration
  notplaceable;
  
  
// ============================================================================
// PostBeginPlay
//
// Sets the key colour to show the *captive* team
// ============================================================================

event PostBeginPlay()
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
  //Style=STY_Translucent
  bCollideActors=False
  bBlockActors=False
  bBlockPlayers=False
  bBlockNonZeroExtentTraces=False
  RotationRate=(Yaw=24000)
}

