// ============================================================================
// JBExecutionDepressurize
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBExecutionDepressurize.uc,v 1.4 2005-10-17 12:53:02 tarquin Exp $
//
// An depressurization execution.
// Based on <GamePlay.PressureVolume>.
// ============================================================================


class JBExecutionDepressurize extends JBExecution;


// ============================================================================
// Imports
// ============================================================================

#exec texture import file=Textures\JBExecutionDepressurize.pcx mips=off masked=on group=icons


// ============================================================================
// Variables
// ============================================================================

var() float DepressurizeTime;
var() float DepressurizeToHeadScale;
var() float DepressurizeStartFogScale;
var() float DepressurizeToFogScale;
var() sound DepressurizeAmbientSound;
var() vector DepressurizeToFog;
var float DepressurizeToFOV;
var float TimePassed;


// ============================================================================
// PostBeginPlay
//
// Disable Tick() and remove evantuel ambient sound.
// ============================================================================

function PostBeginPlay()
{
  Super.PostBeginPlay();

  Disable('Tick');
  AmbientSound = None;
}


// ============================================================================
// MakeNormal
//
// Reset depressurized player head scale.
// ============================================================================

function MakeNormal(Pawn DepressurizedPawn)
{
  if(DepressurizedPawn == None) return;

  DepressurizedPawn.SetHeadScale(1.0);

  if((DepressurizedPawn.Controller != None)
  && (DepressurizedPawn.Controller.IsA('PlayerController')))
    PlayerController(DepressurizedPawn.Controller).SetFOVAngle(PlayerController(DepressurizedPawn.Controller).Default.FOVAngle);
}


// ============================================================================
// Tick
//
// Increase head scaling of all jailed players before explode this players.
// ============================================================================

function Tick(float DeltaTime)
{
  local JBTagPlayer JailedPlayer;
  local Pawn DepressurizePawn;
  local PlayerController DepressurizePlayer;
  local float ratio;
  local float FogScale;
  local vector Fog;

  TimePassed += DeltaTime;
  ratio = TimePassed/DepressurizeTime;
  if(ratio > 1.0) ratio = 1.0;

  for(JailedPlayer=GetFirstTagPlayer(); JailedPlayer!=None; JailedPlayer=JailedPlayer.NextTag) {
    if( PlayerIsInAttachedJail(JailedPlayer)
      && (JailedPlayer.GetPawn() != None))
    {
      DepressurizePawn = JailedPlayer.GetPawn();
      DepressurizePawn.SetHeadScale(1 + (DepressurizeToHeadScale-1) * ratio);

      // pain screem :(
      if((ratio > 0.1)
        && (ratio < 0.9) // make sure to hear the gib sound
        && (FRand() < 0.03))
        DepressurizePawn.PlayDyingSound();

      if(DepressurizePawn.Controller.IsA('PlayerController')) {
        DepressurizePlayer = PlayerController(DepressurizePawn.Controller);
        FogScale = (DepressurizeToFogScale-DepressurizeStartFogScale)*ratio + DepressurizeStartFogScale;
        Fog = (DepressurizeToFog*ratio)*1000;
        DepressurizePlayer.ClientFlash(FogScale, Fog);
        DepressurizePlayer.SetFOVAngle((DepressurizeToFOV-DepressurizePlayer.default.FOVAngle)*ratio + DepressurizePlayer.default.FOVAngle);
      }

      if(ratio == 1.0) {
        ExecuteAllJailedPlayers();
        if(AmbientSound != None) AmbientSound = None;
      }
    }
  }

  if(TimePassed >= DepressurizeTime) {
    Disable('Tick');
    Enable('Trigger');
  }
}


// ============================================================================
// ExecuteJailedPlayer
//
// Execute a player.
// ============================================================================

function ExecuteJailedPlayer(Pawn Victim)
{
  MakeNormal(Victim); // before dead for make sure to spawn normal gib
  InstantKillPawn(Victim, class'Depressurized'); //Kill with gibs
}


// ============================================================================
// Trigger
//
// Start execution, activate Tick().
// ============================================================================

function Trigger(Actor A, Pawn P)
{
  //    Super.Trigger(A, P); -> don't execute now all jailed players!

  Disable('Trigger');
  TimePassed = 0;
  if(DepressurizeAmbientSound != None) AmbientSound = DepressurizeAmbientSound;
  Enable('Tick');
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  Texture = Texture'JBToolbox.icons.JBExecutionDepressurize';
  DepressurizeTime=2.500000
  DepressurizeToHeadScale=2.500000
  DepressurizeStartFogScale=2.000000
  DepressurizeToFog=(X=1000,Y=0,Z=0)
  DepressurizeToFogScale=0.250000
  DepressurizeToFov=150
}
