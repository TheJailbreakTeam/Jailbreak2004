// ============================================================================
// JBScreenMapPanorama
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Renders a panoramic minimap similar to the scoreboard on a ScriptedTexture.
// ============================================================================


class JBScreenMapPanorama extends JBScreenMap
  placeable
  showcategories(Movement);


// ============================================================================
// Replication
// ============================================================================

replication {

  reliable if (Role == ROLE_Authority)
    RepLocation,
    RepRotation,
    FieldOfView;
  }


// ============================================================================
// Properties
// ============================================================================

var() float FieldOfView;            // field of view for panoramic overview


// ============================================================================
// Variables
// ============================================================================

var private vector RepLocation;     // replicated actor location
var private rotator RepRotation;    // replicated actor rotation

var private Coords CoordsPanorama;  // coordinate system of viewpoint
var private float ScaleDepth;       // field of view depth adjustment


// ============================================================================
// PostBeginPlay
//
// Replicated the actor's location and rotation to clients. Required because
// movement variables are only unreliably replicated and thus haven't reached
// the client already when PostNetBeginPlay is called.
// ============================================================================

event PostBeginPlay() {

  RepLocation = Location;
  RepRotation = Rotation;
  }


// ============================================================================
// PrepareCoords
//
// Prepares the panorama's coordinate system for location translations.
// ============================================================================

simulated protected function bool PrepareCoords() {

  if (FieldOfView <= 0.0)
    return False;

  CoordsPanorama.Origin = RepLocation;

  GetAxes(RepRotation,
    CoordsPanorama.XAxis,
    CoordsPanorama.YAxis,
    CoordsPanorama.ZAxis);

  ScaleDepth = 1.0 / Tan(FieldOfView * Pi / 360.0);
  
  return True;
  }


// ============================================================================
// CalcLocation
//
// Calculates and returns the texture pixel coordinates corresponding to the
// given world coordinates.
// ============================================================================

simulated function vector CalcLocation(vector LocationWorld) {

  local float ScaleLateral;
  local vector LocationIcon;
  
  LocationWorld -= CoordsPanorama.Origin;

  LocationIcon.X = LocationWorld dot CoordsPanorama.YAxis;
  LocationIcon.Y = LocationWorld dot CoordsPanorama.ZAxis;
  LocationIcon.Z = LocationWorld dot CoordsPanorama.XAxis;

  if (LocationIcon.Z == 0.0)
    return vect(0,0,0);  // undefined

  ScaleLateral = ScaleDepth / LocationIcon.Z * SizeScriptedTexture.X / 2;
  LocationIcon.X *=  ScaleLateral;  LocationIcon.X += SizeScriptedTexture.X / 2;
  LocationIcon.Y *= -ScaleLateral;  LocationIcon.Y += SizeScriptedTexture.Y / 2;

  return LocationIcon;
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  FieldOfView = 90.0;

  bDirectional = True;
  }