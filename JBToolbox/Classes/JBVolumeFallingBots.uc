//=============================================================================
// JBVolumeFallingBots
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
//
// Makes bots fall if they are standing on a mover.
//=============================================================================


class JBVolumeFallingBots extends Volume;


//=============================================================================
// Trigger
//
// Starts the checks.
//=============================================================================

function Trigger(Actor Other, Pawn EventInstigator)
{
  GotoState('FallingBots');
}


//=============================================================================
// Untrigger
//
// Stops the checks.
//=============================================================================

function Untrigger(Actor Other, Pawn EventInstigator)
{
  GotoState('');
}


//=============================================================================
// state FallingBots
//
// Checks for bots and whether they should fall.
//=============================================================================

state FallingBots
{
  function Tick(float DeltaTime)
  {
    local Pawn P;
    
    foreach TouchingActors(class'Pawn', P)
      if ( PlayerController(P.Controller) == None && Mover(P.Base) != None )
        P.JumpOffPawn();
  }
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  bNoDelete=True
  bStatic=False
  LocationPriority=-1
}