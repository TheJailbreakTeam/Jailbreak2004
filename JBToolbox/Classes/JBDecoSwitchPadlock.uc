// ============================================================================
// JBDecoSwitchPadlock
// Copyright 2004 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
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

var float TimeSway;


// ============================================================================
// Tick
//
// Makes the padlock slightly sway back and forth.
// ============================================================================

event Tick(float TimeDelta)
{
  local Rotator RotationSway;
  
  TimeSway += TimeDelta;
  
  RotationSway = Rotation;
  RotationSway.Roll  = Default.Rotation.Roll  + 4096 * Sin(TimeSway * 0.6);
  RotationSway.Pitch = Default.Rotation.Pitch + 4096 * Sin(TimeSway * 0.9);

  SetRotation(RotationSway);
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
  Style                     = STY_Alpha;
  AmbientGlow               = 16;
  LODBias                   = 1024.0;

  Physics                   = PHYS_Rotating;
  Rotation                  = (Pitch=32768,Roll=32768);
  RotationRate              = (Yaw=4800);
  bFixedRotationDir         = True;
  
  bStatic                   = False;
  bBlockActors              = False;
  bBlockNonZeroExtentTraces = False;
  bBlockPlayers             = False;
  bCollideActors            = False;
  bCollideWorld             = False;
}