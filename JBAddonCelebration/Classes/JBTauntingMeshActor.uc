//=============================================================================
// JBTauntingMeshActor
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id: JBTauntingMeshActor.uc,v 1.2 2004/03/05 19:18:24 wormbo Exp $
//
// Plays taunting animations for the celebration screen.
//=============================================================================


class JBTauntingMeshActor extends Actor
    notplaceable;


//=============================================================================
// Import
//=============================================================================

#exec obj load file=..\Animations\Jugg.ukx


//=============================================================================
// Variables
//=============================================================================

var float TauntDelay;                   // seconds before playing the taunt anim
var array<name> TauntAnims;             // taunt animations for bots
var array<name> IdleAnims;              // idle animations while not taunting
var array<name> DeathAnims;             // death animations when owner died
var bool bStartedTaunting;
var bool bRagdollStarted;
var vector InitialLocationOffset;


//=============================================================================
// Tick
//
// Check whether owner died.
//=============================================================================

function Tick(float DeltaTime)
{
  if ( Pawn(Owner) != None ) {
    if ( Mesh != Owner.Mesh )
      LinkMesh(Owner.Mesh);
    Skins = Owner.Skins;
    OverlayMaterial = Owner.OverlayMaterial;
    OverlayTimer = Owner.OverlayTimer;
    ClientOverlayTimer = Owner.ClientOverlayTimer;
    ClientOverlayCounter = Owner.ClientOverlayCounter;
    if ( xPawn(Owner) == None || !xPawn(Owner).bDeRes )
      AmbientGlow = Max(Owner.AmbientGlow, 100);
    else
      AmbientGlow = Owner.AmbientGlow;
    if ( Owner.Physics == PHYS_KarmaRagdoll ) {
      if ( !bRagdollStarted ) {
        InitialLocationOffset = Owner.Location;
        bRagdollStarted = True;
      }
      PrePivot = vect(0,0,1) * Owner.default.CollisionHeight + (Owner.Location - InitialLocationOffset);
    }
    SetRotation(Owner.Rotation);
  }
  else if ( bAnimByOwner && Pawn(Owner) == None && !IsInState('Taunting') ) {
    SetDrawScale(0.0);
    bAnimByOwner = False;
  }
}


//=============================================================================
// PlayNamedTauntAnim
//
// Stub function for Taunting state.
//=============================================================================

function PlayNamedTauntAnim(name AnimName);


//=============================================================================
// GetRandomTauntAnim
//
// Returns a random taunt animation name.
//=============================================================================

function name GetRandomTauntAnim()
{
  local int i;
  
  while (TauntAnims.Length > 0) {
    i = Rand(TauntAnims.Length);
    if ( HasAnim(TauntAnims[i]) )
      return TauntAnims[i];
    else
      TauntAnims.Remove(i, 1);
  }
  
  return '';
}


//=============================================================================
// state Taunting
//
// Automatically play some taunt animations.
//=============================================================================

state Taunting
{
  //===========================================================================
  // PlayTauntAnim
  //
  // Play the next taunt animation.
  //===========================================================================
  
  function PlayTauntAnim()
  {
    local name TauntName;
    
    TauntName = GetRandomTauntAnim();
    if ( HasAnim(TauntName) )
      PlayAnim(TauntName,, 0.2);
  }
  
  
  //===========================================================================
  // PlayNamedTauntAnim
  //
  // Tries to play the specified taunt animation.
  //===========================================================================
  
  function PlayNamedTauntAnim(name AnimName)
  {
    if ( HasAnim(AnimName) ) {
      PlayAnim(AnimName,, 0.2);
      //AnimBlendParams(1, 1.0, 0.2, 0.3);
      //AnimBlendToAlpha(1, 1.0, 0.3);
      GotoState('');
      GotoState('Taunting', 'FinishTaunt');
    }
  }
  
BeginTaunting:
  LoopAnim(IdleAnims[Rand(IdleAnims.Length)]);
Taunt:
  Sleep(TauntDelay);
  PlayTauntAnim();
  FinishAnim();
  LoopAnim(IdleAnims[Rand(IdleAnims.Length)],, 0.3);
  Sleep(1.5 * FRand() + 1);
  Goto('Taunt');

ManualTaunting:
  LoopAnim(IdleAnims[Rand(IdleAnims.Length)]);
  //AnimBlendParams(1, 1.0, 0.2, 0.2);
  Stop;

FinishTaunt:
  FinishAnim();
  LoopAnim(IdleAnims[Rand(IdleAnims.Length)],, 0.3);
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  TauntAnims(0)=PThrust
  TauntAnims(1)=AssSmack
  TauntAnims(2)=ThroatCut
  TauntAnims(3)=Specific_1
  TauntAnims(4)=gesture_cheer
  TauntAnims(5)=Gesture_Taunt01
  TauntAnims(6)=Gesture_Taunt02
  IdleAnims(0)=Idle_Rest
  IdleAnims(1)=Idle_Biggun
  DeathAnims(0)=DeathB
  DeathAnims(1)=DeathF
  DeathAnims(2)=DeathL
  DeathAnims(3)=DeathR
  TauntDelay=1.5
  
  RemoteRole=ROLE_None
  bUnlit=True
  bHidden=True
  bAcceptsProjectors=false
  AmbientGlow=128
  DrawType=DT_Mesh
  Style=STY_Alpha
  DrawScale=1.0
  DrawScale3D=(X=1.0,Y=1.0,Z=1.0)
  bAlwaysTick=true
  LODBias=100000
  Mesh=JuggMaleA
}