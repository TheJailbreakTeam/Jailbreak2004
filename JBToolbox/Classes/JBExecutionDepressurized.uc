// ============================================================================
// JBExecutionDepressurized
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBExecutionDepressurized.uc,v 1.1.1.1 2003/03/12 23:53:20 mychaeel Exp $
//
// An depressurization execution.
// Based on <GamePlay.PressureVolume>.
// ============================================================================
class JBExecutionDepressurized extends JBExecution;


// ============================================================================
// Variables
// ============================================================================
var() float DepressurizeTime;
var() float DepressurizeToHeadScale;
var() sound DepressurizeAmbientSound;
var float DepressurizedFOV;
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

    if(DepressurizedPawn.Controller != None)
        if(DepressurizedPawn.Controller.IsA('PlayerController'))
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

    TimePassed += DeltaTime;
    ratio = TimePassed/DepressurizeTime;
    if(ratio > 1.0) ratio = 1.0;

    foreach DynamicActors(class'JBTagPlayer', JailedPlayer)
    {
        if(JailedPlayer != None)
        {
            if(JailedPlayer.GetController() != None)
            {
                if(JailedPlayer.GetController().Pawn != None)
                {
                    if(JailedPlayer.GetJail() == TargetedJail)
                    {
                        DepressurizePawn = JailedPlayer.GetController().Pawn;
                        DepressurizePawn.SetHeadScale(1 + (DepressurizeToHeadScale-1) * ratio);

                        if(DepressurizePawn.Controller != None)
                        {
                            if(DepressurizePawn.Controller.IsA('PlayerController'))
                            {
                                DepressurizePlayer = PlayerController(DepressurizePawn.Controller);
                                DepressurizePlayer.SetFOVAngle((DepressurizedFOV-DepressurizePlayer.default.FOVAngle)*ratio + DepressurizePlayer.default.FOVAngle);
                            }
                        }

                        if(ratio == 1.0)
                        {
                            SeekJailedPlayerForExecution();
                            if(AmbientSound != None)
                                AmbientSound = None;
                        }
                    }
                }
            }
        }
    }

    if(TimePassed >= DepressurizeTime)
    {
        Disable('Tick');
        Enable('Trigger');
    }
}


// ============================================================================
// ExecutePlayer
//
// Execute a player.
// ============================================================================
protected function ExecutePlayer(Controller Victim)
{
    MakeNormal(Victim.Pawn);
    Victim.Pawn.Died(None, class'Depressurized', vect(0,0,0));
}


// ============================================================================
// Trigger
//
// Start execution, activate Tick().
// ============================================================================
function Trigger(Actor A, Pawn P)
{
//    Super.Trigger(A, P); -> don't execute now all jailed players!

    TimePassed = 0;
    Disable('Trigger');
    Enable('Tick');
    if(DepressurizeAmbientSound != None)
        AmbientSound = DepressurizeAmbientSound;
}

// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
    DepressurizedFov=150
    DepressurizeTime=2.5
    DepressurizeToHeadScale=2.5
}
