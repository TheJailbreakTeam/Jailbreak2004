// ============================================================================
// JBCamControllerTracking
// Copyright 2004 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Camera controller which tracks players.
// ============================================================================


class JBCamControllerTracking extends JBCamController
  editinlinenew;


// ============================================================================
// UpdateMovement
//
// Rotates the camera in order to show a view on all players around it.
// ============================================================================

function UpdateMovement(float TimeDelta)
{
  local float Rating;
  local vector VectorTotal;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;

  if (Camera.Level.Game != None)
         firstTagPlayer = JBGameReplicationInfo(Camera.Level.Game.GameReplicationInfo).firstTagPlayer;
    else firstTagPlayer = JBGameReplicationInfo(Camera.Level.GetLocalPlayerController().GameReplicationInfo).firstTagPlayer;

  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag) {
    if (IsPlayerIgnored(thisTagPlayer))
      continue;

    Rating = thisTagPlayer.RateViewOnPlayer(Camera.Location);
    VectorTotal += Rating * (thisTagPlayer.GetPawn().Location - Camera.Location);
  }

  if (VSize(VectorTotal) > 0.0)
    InterpolateRotation(rotator(VectorTotal), TimeDelta);
}
