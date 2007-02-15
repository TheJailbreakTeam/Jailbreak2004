//=============================================================================
// JBLlamaTrailer
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id: JBLlamaTrailer.uc,v 1.3 2003/08/11 20:34:26 wormbo Exp $
//
// Pulsing colored light effect for the llama.
//=============================================================================


class JBLlamaTrailer extends Effects notplaceable;


//=============================================================================
// Variables
//=============================================================================

var transient float HueChangeTime, RadiusChangeTime;


//=============================================================================
// Tick
//
// Modifies the light hue and radius to create a pulsing rainbow color effect.
//=============================================================================

simulated function Tick(float DeltaTime)
{
  HueChangeTime += DeltaTime * (1 + 0.2 * FRand());
  RadiusChangeTime += DeltaTime * (1 + 0.2 * FRand());
  LightHue = int(HueChangeTime * 100.0) % 256;
  LightRadius = 3.0 * Cos(2.0 * Pi * RadiusChangeTime) + 8.0;
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  RemoteRole=ROLE_SimulatedProxy
  bNetTemporary=false
  bReplicateMovement=False
  Physics=PHYS_Trailer
  DrawType=DT_None
  bTrailerSameRotation=True
  LifeSpan=0.0
  bDynamicLight=True
  LightType=LT_Steady
  LightEffect=LE_NonIncidence
  LightSaturation=0
  LightBrightness=250
  bAlwaysTick=True
}
