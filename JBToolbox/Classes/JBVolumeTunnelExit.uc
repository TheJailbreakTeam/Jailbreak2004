//=============================================================================
// JBVolumeTunnelExit
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// Allows pawns to walk off ledges even when crouched.
//=============================================================================


class JBVolumeTunnelExit extends Volume;


//=============================================================================
// state AssociatedTouch
//
// Ensures that the tunnel exit volume also works when it has an associated
// actor. Regular volumes only call the associated actor's (Un)Touch function
// but this volume also needs its own (Un)Touch to be executed.
//=============================================================================

state AssociatedTouch
{
  simulated event Touch(Actor Other)
  {
    AssociatedActor.Touch(Other);
    Global.Touch(Other);
  }
  
  simulated event UnTouch(Actor Other)
  {
    AssociatedActor.Untouch(Other);
    Global.UnTouch(Other);
  }
}


//=============================================================================
// Touch
//
// Allow the pawn to walk off ledges.
//=============================================================================

simulated event Touch(Actor Other)
{
  if ( Pawn(Other) != None ) {
    Pawn(Other).bAvoidLedges = False;
    Pawn(Other).bStopAtLedges = False;
    Pawn(Other).bCanWalkOffLedges = True;
  }
}


//=============================================================================
// Untouch
//
// Restore the pawn's default bAvoidLedges and bStopAtLedges which usually
// means it can't walk off ledges anymore.
//=============================================================================

simulated event UnTouch(Actor Other)
{
  if ( Pawn(Other) != None ) {
    Pawn(Other).bAvoidLedges = Pawn(Other).default.bAvoidLedges;
    Pawn(Other).bStopAtLedges = Pawn(Other).default.bStopAtLedges;
    Pawn(Other).bCanWalkOffLedges = Pawn(Other).default.bCanWalkOffLedges;
  }
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  LocationPriority=-1 // other volumes' location names should have higher priority
  bStatic=False
}