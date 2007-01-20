//=============================================================================
// JBPickupJailCard
// Copyright 2007 by [GSF]JohnDoe <gsfjohndoe@hotmail.com>
// Created 2004 by tarquin <tarquin@beyondunreal.com>
// $Id$
//
// Pickup class for the "Get out of jail free card" for the Jailbreak Addon
// JailCard.
//
// CHANGELOG:
// 14 jan 2007 - Fixed Drawtype defaultproperty
//               Added defaultproperties to make it show up properly
//               Added custom LocalMessage
//               Added pickup sound
//               Added mutator method for MyAddon
//               Added initial Touch() behaviour
// 15 jan 2007 - Seperated Properties and class variable declarations
//               Added JBDecoSwitchBasket effect
// 17 jan 2007 - Added DeleteDecoration in an attempt to fix replication and
//               have the emitter destroyed on clients; I failed :(
//               Changed decoration to custom class
//=============================================================================

class JBPickupJailCard extends TournamentPickup;


// ============================================================================
// Properties
// ============================================================================

var Class<Decoration> MyDecoration;


// ============================================================================
// Variables
// ============================================================================

var JBAddonJailCard MyAddon;
var Decoration Decoration;


//=============================================================================
// setMyAddon
//
// MyAddon mutator method
//=============================================================================

function bool setMyAddon(JBAddonJailCard JC)
{
    MyAddon = JC;
    return true;
}


// ============================================================================
// PostBeginPlay
//
// Spawns the visible parts of the JailCard's decoration client-side.
// ============================================================================

simulated function PostBeginPlay()
{
    if (Level.NetMode != NM_DedicatedServer)
    {
        Decoration = Spawn(MyDecoration, Self, ,
            MyDecoration.Default.Location + Location,
            MyDecoration.Default.Rotation + Rotation);
        log("Decoration spawned");
    }

  Super.PostBeginPlay();
}


//=============================================================================
// Touch
//
// When a player touches the JailCard:
//  Display a message
//  Destroy the decoration
//=============================================================================

auto state Pickup
{
    function Touch( Actor Other )
    {
        local Pawn P;

        if ( ValidTouch(Other) )
        {
            P = Pawn(Other);
            BroadcastLocalizedMessage(MessageClass, 0);
            DeleteDecoration(Other, P);
            SetRespawn();
        }
    }
}


//=============================================================================
// DeleteDecoration
//
// Deletes the emitter decoration
// Note: Does not work properly yet, as it does not get called yet on the
// clients, only on the server. Why? Look into replication... remember that
// RemoteRole=ROLE_DumbProxy atm
//
// I'm so confused  :(
//============================================================================
simulated function DeleteDecoration(Actor Other, Pawn P)
{
    log("DeleteDecoration1"); //show up in server log (not client)
    if ( Level.NetMode != NM_DedicatedServer )
    {
        Decoration.Trigger(Other, P);
        log("DeleteDecoration2");  //doesn't show up anywhere
    }
}


//=============================================================================
// default properties
//=============================================================================

defaultproperties
{
  // visuals
  DrawType    = DT_StaticMesh;
  StaticMesh  = StaticMesh'JBToolbox.SwitchMeshes.JBReleaseKey';
  Skins(0)    = Shader'JBToolbox.SwitchSkins.JBKeyFinalRed';
  bAmbientGlow=true;
  Physics=PHYS_Rotating;
  RotationRate=(Yaw=24000);
  DrawScale=0.6;
  MyDecoration = Class'JBDecoJailCardBasket';
  Style=STY_AlphaZ;
  ScaleGlow=0.6;
  CullDistance=+4500.0;

  // AI
  MaxDesireability=0.3;

  // pickup stuff
  MessageClass=class'JBJailCardMessage';
  PickupMessage="Get Out Of Jail Free Card!";
  PickupSound=sound'2K4MenuSounds.msfxDrag';
  CollisionRadius=24.0;
}

