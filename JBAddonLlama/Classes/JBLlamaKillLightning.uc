//=============================================================================
// JBLlamaKillLightning
// Copyright 2004 by Wormbo <wormbo@onlinehome.de>
// $Id: JBLlamaKillLightning.uc,v 1.1 2004-05-31 11:14:58 wormbo Exp $
//
// A lightning strikes the player.
//=============================================================================


class JBLlamaKillLightning extends JBLlamaKill;


//=============================================================================
// Import
//=============================================================================

#exec audio import file=Sounds\Thunder.wav   name=Thunder   group=KillSounds
#exec audio import file=Sounds\Lightning.wav name=Lightning group=KillSounds


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
// Periodically checks whether there's enough space above the player.
//=============================================================================

function Timer()
{
  local xPawn P;

  if ( Controller(Owner) != None && Controller(Owner).Pawn == None )
    return;

  foreach Owner.ChildActors(class'xPawn', P)
    if ( P.Health > 0 && FastTrace(P.Location, P.Location + 2000 * vect(0,0,1)) ) {
      Spawn(class'JBEmitterKillLightning',,, P.Location);
      P.PlaySound(sound'Thunder', SLOT_Interact, 100.0,, 5000.0);
      P.PlaySound(sound'Lightning', SLOT_Pain, 100.0,, 500.0);
      P.TakeDamage(1000, P, P.Location, vect(0,0,0), class'JBDamageTypeLlamaLightning');
      if ( P != None && P.Health > 0 )
        P.Died(Controller(Owner), class'JBDamageTypeLlamaLightning', P.Location);
    }

  if ( Controller(Owner) == None || Controller(Owner).Pawn == None )
    Destroy();
}
