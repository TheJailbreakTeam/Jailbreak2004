//=============================================================================
// JBLlamaTrailer
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id: JBLlamaTrailer.uc,v 1.1 2003/07/26 20:20:35 wormbo Exp $
//
// Pulsing colored light effect for the llama.
//=============================================================================


class JBLlamaTrailer extends Effects;


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
  bReplicateMovement=false
  Physics=PHYS_Trailer
  DrawType=DT_None
  bTrailerSameRotation=true
  bDynamicLight=True
  LightType=LT_Steady
  LightEffect=LE_NonIncidence
  LightSaturation=127
  LightBrightness=250
}
