//=============================================================================
// JBDecoSwitchRing
// Copyright 2004 by tarquin <tarquin@beyondunreal.com>
// $Id$
//
// Displays the Jailbreak release switch ring
//=============================================================================


class JBDecoSwitchRing extends Decoration
  notplaceable;
  
  
// ============================================================================
// Imports
// ============================================================================

#exec obj load file=StaticMeshes\JBReleaseRing.usx     package=JBToolbox.SwitchMeshes
#exec obj load file=Textures\JBReleaseTexturesRing.utx package=JBToolbox.SwitchSkins


// ============================================================================
// Variables
// ============================================================================

var Color         TeamColor[2];     // colors for the mesh skin
var ConstantColor myConstantColor;
var Combiner      myCombiner; 
var FinalBlend    myFinalBlend;     // material for the mesh skin

// useful mnemonics so I don't go red-blue crazy
var int   TeamNormal; // Team Number for mesh skin in "normal" condition
var int   TeamEffect; // Team Number for mesh skin when reacting

var float EffectTime; // time taken for ring effect
var float Alpha;      // used by Tick()

// effect changes to properties
var float EffectChangeRoll;       // multiplier for RotationRate.Roll
var float EffectChangeDrawScale;  // multiplier for DrawScale


// ============================================================================
// PostBeginPlay
//
// Sets the ring colour to show the *holding* team
// ============================================================================

simulated function PostBeginPlay()
{
  local JBGameObjectiveSwitch MySwitch;
  
  MySwitch    = JBGameObjectiveSwitch( Owner ); // owner was set by the spawn
  TeamNormal  = MySwitch.DefenderTeamIndex;
  TeamEffect  = 1 - TeamNormal;
  
  // create materials for this object
  myConstantColor = ConstantColor(Level.ObjectPool.AllocateObject(class'ConstantColor'));
  myCombiner      = Combiner(Level.ObjectPool.AllocateObject(class'Combiner'));
  myFinalBlend    = FinalBlend(Level.ObjectPool.AllocateObject(class'FinalBlend'));
  
  // set up materials
  myConstantColor.Color = TeamColor[TeamNormal];
  
  myCombiner.Material1  = Skins[0];
  myCombiner.Material2  = myConstantColor;
  myCombiner.CombineOperation = CO_Multiply;
  myCombiner.AlphaOperation   = AO_Use_Mask;
  
  myFinalBlend.Material             = myCombiner;
  myFinalBlend.FrameBufferBlending  = FB_AlphaBlend;
  
  // assign material to skin
  Skins[0] = myFinalBlend;
}


// ============================================================================
// Trigger
//
// Called when the release switch releases. Go to the 'effect' state
// ============================================================================

event Trigger( Actor Other, Pawn EventInstigator )
{
  GotoState('Effect');
}


// ============================================================================
// state Effect
//
// Changes the displayed mesh in funky ways
// ============================================================================

state Effect {

  // ================================================================
  // BeginState
  //
  // Makes instantaneous changes and enables tick()
  // ================================================================

  event BeginState()
  {
    myConstantColor.Color = TeamColor[TeamEffect];
    RotationRate.Roll     *= EffectChangeRoll;

    Alpha = 0.0;
    Enable( 'Tick' );
  }


  // ================================================================
  // Tick
  //
  // Make gradual changes once triggered
  // Disables itself once changes are fully made
  // ============================================================================

  function Tick( float DeltaTime )
  {
    Alpha += DeltaTime / EffectTime;
    if( Alpha > 1.0 )
    {
      Alpha = 1.0;
      Disable( 'Tick' );
    }

    SetDrawScale( lerp ( Alpha, default.DrawScale, EffectChangeDrawScale * default.DrawScale ) );
    myConstantColor.Color.A = 128 * (1.0 - Alpha);
  }


  // ============================================================================
  // UnTrigger
  //
  // Called when the release switch is reset by the jail
  // resets the visual effects and returns to the null state
  // ============================================================================

  event UnTrigger( Actor Other, Pawn EventInstigator )
  {
    SetDrawScale( default.DrawScale );
    myConstantColor.Color = TeamColor[TeamNormal];
    RotationRate.Roll     = default.RotationRate.Roll;

    GotoState(''); 
  }

} // state Effect


//=============================================================================
// default properties
//=============================================================================

defaultproperties
{
  RemoteRole  = ROLE_None;

  DrawType    = DT_StaticMesh;
  DrawScale   = 0.500;
  StaticMesh  = StaticMesh'JBReleaseRing';
  Skins[0]    = Texture'JBReleaseRingWhite';
  Location    = (Z=40.0);
  
  /* blame xDomA */
  bCollideWorld=false
  
  bStatic=false
  bStasis=false
  bFixedRotationDir=True
  Physics=PHYS_Rotating
  
  /* blame Spoon */
  bCollideActors= False
  bBlockActors  = False
  bBlockPlayers = False
  bBlockNonZeroExtentTraces = False
  RotationRate  = (Pitch=5000,Yaw=-16000,Roll=48000);
  
  /* visuals */
  TeamColor[0] = (R=255,G=000,B=000,A=128); // red
  TeamColor[1] = (R=000,G=000,B=255,A=128); // blue

  EffectTime        = 0.500;
  EffectChangeRoll  = 3.000;
  EffectChangeDrawScale = 3.000;
  
}

