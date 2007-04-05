//=============================================================================
// JBLlamaKillLaser
// Copyright 2004 by Wormbo <wormbo@onlinehome.de>
// $Id: JBLlamaKillLaser.uc,v 1.1 2004-05-31 11:14:58 wormbo Exp $
//
// Kills a player by letting a satellite fire a laser beam at that player.
//=============================================================================


class JBLlamaKillLaser extends JBLlamaKill;


//=============================================================================
// Import
//=============================================================================

#exec audio import file=Sounds\LaserBeamFire.wav name=LaserBeamFire group=KillSounds


//=============================================================================
// PostBeginPlay
//
// Start the timer.
//=============================================================================

function PostBeginPlay()
{
  local IonCannon Cannon;

  if ( bDeleteMe )
    return;

  if ( Controller(Owner) != None )
    foreach DynamicActors(class'IonCannon', Cannon)
      break;

  if ( Cannon == None )
    Destroy();
  else {
    Timer();
    SetTimer(0.25, True);
  }
}


//=============================================================================
// Timer
//
// Periodically checks whether the player is in ion cannon range.
//=============================================================================

function Timer()
{
  local IonCannon Cannon;
  local IonCannon BestCannon, BestActiveCannon;
  local float BestDist, BestActiveDist;
  local xPawn P;
  local JBxEmitterKillLaser Beam;

  if ( Controller(Owner) != None && Controller(Owner).Pawn == None )
    return;

  foreach Owner.ChildActors(class'xPawn', P) {
    if ( P.Health > 0 ) {
      BestDist = 20000;
      BestActiveDist = 20000;
      BestCannon = None;
      BestActiveCannon = None;
      foreach DynamicActors(class'IonCannon', Cannon)
        if ( VSize(Cannon.Location - P.Location) < BestDist && FastTrace(Cannon.Location, P.Location) ) {
          if ( Cannon.IsFiring() && VSize(Cannon.Location - P.Location) < BestActiveDist ) {
            BestActiveDist = VSize(Cannon.Location - P.Location);
            BestActiveCannon = Cannon;
          }
          else if ( !Cannon.IsFiring() ) {
            BestDist = VSize(Cannon.Location - P.Location);
            BestCannon = Cannon;
          }
        }

      if ( BestCannon == None )
        BestCannon = BestActiveCannon;

      if ( BestCannon != None ) {
        Beam = Spawn(class'JBxEmitterKillLaser',,, BestCannon.Location);
        Beam.SetBeam(BestCannon.Location, P.Location);
        BestCannon.PlaySound(sound'LaserBeamFire', SLOT_Interact, 100.0,, 5000.0);
        P.PlaySound(sound'LaserBeamFire', SLOT_Interact, 100.0,, 500.0);
        P.TakeDamage(1000, P, P.Location, vect(0,0,0), class'JBDamageTypeLlamaLaser');
        if ( P != None && P.Health > 0 )
          P.Died(Controller(Owner), class'JBDamageTypeLlamaLaser', P.Location);
      }
    }
  }

  if ( Controller(Owner) == None || Controller(Owner).Pawn == None )
    Destroy();
}
