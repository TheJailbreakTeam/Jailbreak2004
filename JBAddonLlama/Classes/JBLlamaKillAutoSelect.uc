//=============================================================================
// JBLlamaKillAutoSelect
// Copyright 2004 by Wormbo <wormbo@onlinehome.de>
// $Id: JBLlamaKillAutoSelect.uc,v 1.1 2004/05/31 11:14:58 wormbo Exp $
//
// Automatically selects the best method to kill the player immediately.
//=============================================================================


class JBLlamaKillAutoSelect extends JBLlamaKill;


//=============================================================================
// PostBeginPlay
//
// Start the timer.
//=============================================================================

function PostBeginPlay()
{
  if ( bDeleteMe )
    return;
  
  Timer();
  SetTimer(0.5, True);
}


//=============================================================================
// Timer
//
// Periodically checks whether the player can be killed.
//=============================================================================

function Timer()
{
  if ( Controller(Owner) != None && Controller(Owner).Pawn == None )
    return;
  else if ( Controller(Owner) == None ) {
    Destroy();
    return;
  }
  
  if ( TraceIonCannon() && (Rand(2) == 0 || !TraceSky()) )
    Spawn(class'JBLlamaKillLaser', Owner);
  else if ( TraceSky() )
    Spawn(class'JBLlamaKillLightning', Owner);
  else
    Spawn(class'JBLlamaKillExplode', Owner);
  
  Destroy();
}


//=============================================================================
// TraceIonCannon
//
// Returns whether any Ion Cannon is in sight.
//=============================================================================

function bool TraceIonCannon()
{
  local IonCannon Cannon;
  
  foreach DynamicActors(class'IonCannon', Cannon)
    if ( FastTrace(Cannon.Location, Controller(Owner).Pawn.Location) )
      return true;
  
  return false;
}


//=============================================================================
// TraceSky
//
// Traces upwards and returns whether the "ceiling" is more that 2000 UU away.
//=============================================================================

function bool TraceSky()
{
  return FastTrace(Controller(Owner).Pawn.Location, Controller(Owner).Pawn.Location + 2000 * vect(0,0,1));
}
