// ============================================================================
// JBCamControllerSweeping
// Copyright 2004 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBCamControllerSweeping.uc,v 1.1 2004-03-28 13:52:14 mychaeel Exp $
//
// Sweeps a camera between two LookTarget actors.
// ============================================================================


class JBCamControllerSweeping extends JBCamController
  editinlinenew;


// ============================================================================
// Properties
// ============================================================================

var() name TagLookTargetLeft;          // tag of LookTarget on left  range end
var() name TagLookTargetRight;         // tag of LookTarget on right range end

var() float TimeSweep;                 // time to sweep between LookTargets
var() float TimeWait;                  // time to wait before sweeping back


// ============================================================================
// Variables
// ============================================================================

var private int YawSweepLeft;          // yaw on left  end of sweep
var private int YawSweepRight;         // yaw on right end of sweep
var private int YawSweepDelta;         // yaw difference and current direction

var private float TimeCountdownSweep;  // countdown for sweep
var private float TimeCountdownWait;   // countdown for wait


// ============================================================================
// Init
//
// Finds the two LookTarget actors which define the sweeping range. Outputs a
// log error message and sets the camera's caption to an error message if one
// or both can not be found.
// ============================================================================

function Init()
{
  local rotator Rotation;
  local string Error;
  local LookTarget LookTargetLeft;
  local LookTarget LookTargetRight;

  if (TagLookTargetLeft  == '' || TagLookTargetLeft  == 'None' ||
      TagLookTargetRight == '' || TagLookTargetRight == 'None') {
    Error = "TagLookTargetLeft and/or TagLookTargetRight have not been set";
  }
  else {
    foreach Camera.DynamicActors(Class'LookTarget', LookTargetLeft,  TagLookTargetLeft)  break;
    foreach Camera.DynamicActors(Class'LookTarget', LookTargetRight, TagLookTargetRight) break;

    if (LookTargetLeft  == None ||
        LookTargetRight == None) {
      Error = "No matching LookTarget actor found for TagLookTargetLeft and/or TagLookTargetRight";
    }
    else {
      YawSweepLeft  = rotator(LookTargetLeft .Location - Camera.Location).Yaw;
      YawSweepRight = rotator(LookTargetRight.Location - Camera.Location).Yaw;

      if (YawSweepRight < YawSweepLeft)
        YawSweepRight += 65536;

      YawSweepDelta = YawSweepRight - YawSweepLeft;

      Rotation = Camera.Rotation;
      Rotation.Yaw = (YawSweepLeft + YawSweepRight) / 2;
      Camera.SetRotation(Rotation);

      TimeCountdownSweep = TimeSweep / 2.0;
    }
  }

  if (Error != "") {
    Log("Unable to initialize" @ Self @ "of" @ Camera $ ":" @ Error);

    Camera.Caption.Text = "Error:" @ Error;
    Camera.Caption.Position = 0.5;
    Camera.Caption.Color.R  = 255;
    Camera.Caption.Color.G  =   0;
    Camera.Caption.Color.B  =   0;
    Camera.Caption.Color.A  = 255;
  }
}


// ============================================================================
// UpdateMovement
//
// Sweeps the camera back and forth about the yaw axis.
// ============================================================================

function UpdateMovement(float TimeDelta)
{
  local rotator Rotation;

  //Jr.-- sweep when TimeWait is set to 0
  //if (TimeCountdownSweep == 0.0 &&
  //    TimeCountdownWait  == 0.0)
  //  return;  // error
  //--Jr.

  if (TimeCountdownSweep > 0.0) {
    TimeCountdownSweep -= TimeDelta;

    if (TimeCountdownSweep <= 0.0) {
      TimeCountdownSweep = 0.0;
      TimeCountdownWait  = TimeWait;
    }

    Rotation = Camera.Rotation;

    if (YawSweepDelta > 0)
           Rotation.Yaw = YawSweepRight - YawSweepDelta * TimeCountdownSweep / TimeSweep;
      else Rotation.Yaw = YawSweepLeft  - YawSweepDelta * TimeCountdownSweep / TimeSweep;

    Camera.SetRotation(Rotation);
  }

  else {
    TimeCountdownWait -= TimeDelta;

    if (TimeCountdownWait <= 0.0) {
      TimeCountdownWait  = 0.0;
      TimeCountdownSweep = TimeSweep;
      YawSweepDelta = -YawSweepDelta;
    }
  }
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  TimeSweep = 4.0;
  TimeWait  = 2.0;
}
