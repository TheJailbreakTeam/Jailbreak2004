//=============================================================================
// JBPickupJailCard
// Copyright 2006 by [GSF]JohnDoe <gsfjohndoe@hotmail.com>
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
//=============================================================================

class JBPickupJailCard extends TournamentPickup;


// ============================================================================
// Variables
// ============================================================================

var JBAddonJailCard MyAddon;


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


//=============================================================================
// Touch
//=============================================================================

auto state Pickup
{
	function Touch( actor Other )
	{
        local Pawn P;

		if ( ValidTouch(Other) )
		{
            P = Pawn(Other);
            BroadcastLocalizedMessage(MessageClass, 0);
            SetRespawn();
		}
	}
}


//=============================================================================
// default properties
//=============================================================================

defaultproperties
{
  DrawType    = DT_StaticMesh;
  StaticMesh  = StaticMesh'JBToolbox.SwitchMeshes.JBReleaseKey';
  Skins(0)    = Shader'JBToolbox.SwitchSkins.JBKeyFinalRed';

  bAmbientGlow=true
  MaxDesireability=0.3
  Physics=PHYS_Rotating
  RotationRate=(Yaw=24000)
  DrawScale=0.6
  PickupSound=sound'2K4MenuSounds.msfxDrag'
  CollisionRadius=24.0
  Style=STY_AlphaZ
  ScaleGlow=0.6
  CullDistance=+4500.0
  MessageClass=class'JBJailCardMessage'
  PickupMessage="Get Out Of Jail Free Card!"
}

