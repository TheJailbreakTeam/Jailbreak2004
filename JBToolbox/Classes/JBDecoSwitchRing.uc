// JBDecoSwitchRing
// Copyright 2004 by tarquin <tarquin@beyondunreal.com>
// $Id$
//
// Displays the Jailbreak release switch ring
//=============================================================================


class JBDecoSwitchRing extends Decoration
  notplaceable;
  
  
// ============================================================================
// PreBeginPlay
//
// Sets the ring colour to show the *holding* team
// ============================================================================

event PreBeginPlay()
{
  local JBGameObjectiveSwitch MySwitch;
  MySwitch = JBGameObjectiveSwitch( Owner );
  
  SetStaticMesh( MySwitch.StaticMeshRing );
  
  if( MySwitch.DefenderTeamIndex == 0 ) {
    Skins[0] = MySwitch.SkinRingRed;
  }
  else {
    Skins[0] = MySwitch.SkinRingBlue;
  }
  
  super.PreBeginPlay();
}

// ============================================================================
// Trigger
//
// Called when the release switch releases
// ============================================================================

event Trigger( Actor Other, Pawn EventInstigator )
{
  // do visual effects here
  //SetDrawScale( 0.75 );
  
}


// ============================================================================
// UnTrigger
//
// Called when the release switch is reset by the jail
// ============================================================================

event UnTrigger( Actor Other, Pawn EventInstigator )
{
  // reset visual effects here
  //SetDrawScale( default.DrawScale );
 
  
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
  RotationRate=(Pitch=5000,Yaw=-16000,Roll=48000);
  
  /* visuals */
  Begin Object Class=ColorModifier Name=ColorModifierRed
    Material  = Shader'JBToolbox.SwitchSkins.JBReleaseRingWhiteShader';
    Color     = (A=0,R=255,G=0,B=0);
  End Object

  Begin Object Class=ColorModifier Name=ColorModifierBlue
    Material = Shader'JBToolbox.SwitchSkins.JBReleaseRingWhiteShader';
    Color     = (A=0,R=0,G=0,B=255);
  End Object
}

