// ============================================================================
// JBDecoSwitchPadlock
// Copyright 2004 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBDecoSwitchPadlock.uc,v 1.2 2004/05/10 14:53:05 mychaeel Exp $
//
// Animated padlock for standard release switch.
// ============================================================================


class JBDecoSwitchPadlock extends Decoration
  notplaceable;


// ============================================================================
// Imports
// ============================================================================

#exec obj load file=Animations\Padlock.ukx    package=JBToolbox
#exec obj load file=Sounds\PadlockSounds.uax  package=JBToolbox
#exec obj load file=Textures\PadlockSkins.utx package=JBToolbox

#exec mesh settexture mesh=Padlock num=0 texture=PadlockBody
#exec mesh settexture mesh=Padlock num=1 texture=PadlockHasp


// ============================================================================
// Variables
// ============================================================================

var private float TimeAnimate;


// ============================================================================
// Tick
//
// Makes the padlock slightly pulse and sway back and forth.
// ============================================================================

event Tick(float TimeDelta)
{
  local Rotator RotationSway;
  
  TimeAnimate += TimeDelta;
  
  RotationSway = Rotation;
  RotationSway.Roll  = Default.Rotation.Roll  + 4096 * Sin(TimeAnimate * 0.6);
  RotationSway.Pitch = Default.Rotation.Pitch + 4096 * Sin(TimeAnimate * 0.9);
  SetRotation(RotationSway);

  SetDrawScale(Default.DrawScale * (1.0 + 0.1 * Sin(TimeAnimate * 3.0)));
}


// ============================================================================
// Trigger
// UnTrigger
//
// Open or close the padlock.
// ============================================================================

event   Trigger(Actor ActorOther, Pawn PawnInstigator) { GotoState('Open'  ); }
event UnTrigger(Actor ActorOther, Pawn PawnInstigator) { GotoState('Closed'); }


// ============================================================================
// state Closed
//
// Padlock closes and remains closed.
// ============================================================================

state Closed
{
  // ================================================================
  // BeginState
  //
  // Plays the closing animation.
  // ================================================================

  event BeginState()
  {
    PlayAnim('PadlockClose');
  }


  // ================================================================
  // AnimEnd
  //
  // Plays a sound effect when the padlock has finished closing.
  // ================================================================

  event AnimEnd(int Channel)
  {
    PlaySound(Sound'PadlockClose');
  }

}  // state Closed


// ============================================================================
// state Open
//
// Padlock opens and remains open.
// ============================================================================

state Open
{
  // ================================================================
  // BeginState
  //
  // Plays the opening animation and a sound effect.
  // ================================================================

  event BeginState()
  {
    PlayAnim('PadlockOpen');
    PlaySound(Sound'PadlockOpen');
  }

}  // state Open


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  DrawType                  = DT_Mesh;
  Mesh                      = SkeletalMesh'Padlock';
  LODBias                   = 1024.0;
  Style                     = STY_Alpha;
  AmbientGlow               = 32;

  Physics                   = PHYS_Rotating;
  Rotation                  = (Pitch=32768,Roll=32768);
  RotationRate              = (Yaw=4800);
  bFixedRotationDir         = True;
  Location                  = (Z=8.0);
  
  bStatic                   = False;
  bStasis                   = False;
  bBlockActors              = False;
  bBlockNonZeroExtentTraces = False;
  bBlockPlayers             = False;
  bCollideActors            = False;
  bCollideWorld             = False;
}