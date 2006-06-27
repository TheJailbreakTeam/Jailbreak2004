//=============================================================================
// JBPickupJailCard
// Copyright 2004 by tarquin <tarquin@beyondunreal.com>
// $Id$
//
// Desc
//=============================================================================


class JBPickupJailCard extends Pickup;


// ============================================================================
// Variables
// ============================================================================

var JBAddonJailCard MyAddon;


//=============================================================================
// default properties
//=============================================================================

defaultproperties
{
  DrawType    = DTStaticMesh;
  StaticMesh  = StaticMesh'JBToolbox.SwitchMeshes.JBReleaseKey';
  Skins(0)    = Shader'JBToolbox.SwitchSkins.JBKeyFinalRed';
}

