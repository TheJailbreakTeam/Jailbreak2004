// ============================================================================
// JBCamControllerRotating
// Copyright 2004 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Constantly rotates a camera.
// ============================================================================


class JBCamControllerRotating extends JBCamController
  editinlinenew;


// ============================================================================
// Properties
// ============================================================================

var() rotator RotationRate;  // speed of rotation


// ============================================================================
// UpdateMovement
//
// Rotates the camera.
// ============================================================================

function UpdateMovement(float TimeDelta)
{
  Camera.SetRotation(Camera.Rotation + RotationRate * (TimeDelta % 1.0));
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  RotationRate = (Yaw=2048);
}