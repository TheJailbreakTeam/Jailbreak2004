//=============================================================================
// JBLlamaTrailer
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// Pulsing colored light effect for the llama.
//=============================================================================


class JBLlamaTrailer extends Effects notplaceable;


//=============================================================================
// Tick
//
// Modifies the light hue and radius to create a pulsing rainbow color effect.
//=============================================================================

simulated function Tick(float DeltaTime)
{
  LightHue = int(Level.TimeSeconds * 100.0) % 256;
  LightRadius = 3.0 * Cos(2.0 * Pi * Level.TimeSeconds) + 8.0;
}


//=============================================================================
// default properties
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
}
