//=============================================================================
// JBLlamaKillExplode
// Copyright 2004 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// Lets the player explode.
//=============================================================================


class JBLlamaKillExplode extends JBLlamaKill;


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
  SetTimer(0.25, True);
}


//=============================================================================
// Timer
//
// Periodically checks whether the player is in ion cannon range.
//=============================================================================

function Timer()
{
  local Pawn P;
  
  if ( Controller(Owner) != None && Controller(Owner).Pawn == None )
    return;
  
  foreach Owner.ChildActors(class'Pawn', P)
    if ( P.Health > 0 ) {
      Spawn(class'JBEmitterKillExplosion',,, P.Location + vect(0,0,1) * (FRand() - 0.3) * P.CollisionHeight);
      P.TakeDamage(1000, P, P.Location, Normal(VRand() + vect(0,0,1.2)) * 30000, class'JBDamageTypeLlamaExploded');
      if ( P != None && P.Health > 0 ) {
        P.Health = -1000;
        P.Died(Controller(Owner), class'JBDamageTypeLlamaExploded', P.Location);
      }
    }
  
  if ( Controller(Owner) == None || Controller(Owner).Pawn == None )
    Destroy();
}
