// ============================================================================
// JBScreenMapFlat
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Renders a flat, isometric minimap on a ScriptedTexture.
// ============================================================================


class JBScreenMapFlat extends JBScreenMap
  placeable;


// ============================================================================
// Replication
// ============================================================================

replication {

  reliable if (Role == ROLE_Authority)
    CoordPlane,
    CoordBounds,
    CoordCustom;
  }


// ============================================================================
// Types
// ============================================================================

enum ECoordPlane {

  CoordPlane_ViewTop,    // UnrealEd top view
  CoordPlane_ViewFront,  // UnrealEd front view
  CoordPlane_ViewSide,   // UnrealEd side view
  CoordPlane_Custom,     // custom coordinate system
  };


struct TCoordBounds {

  var() float Top;       // coordinate corresponding to upper  texture edge
  var() float Left;      // coordinate corresponding to left   texture edge
  var() float Right;     // coordinate corresponding to right  texture edge
  var() float Bottom;    // coordinate corresponding to bottom texture edge
  };


// The custom coordinate system users can set up here is defined as follows:
//
//   LocationOrigin         World location corresponding to the lower-left
//                          corner of the texture. (This value has one degree
//                          of freedom due to the isometric projection.)
//
//   VectorAxisHorizontal   Axes defining the projected plane in the world.
//   VectorAxisVertical     The length of these vectors defines the distance in
//                          world space along the edges of the texture from
//                          corner to corner. The axes don't have to be
//                          perpendicular, but they must be non-zero.

struct TCoordCustom {

  var() vector LocationOrigin;        // location of coordinate system origin
  var() vector VectorAxisHorizontal;  // scaled vector horizontal texture axis
  var() vector VectorAxisVertical;    // scaled vector vertical   texture axis
  };


// ============================================================================
// Properties
// ============================================================================

var() ECoordPlane  CoordPlane;   // coordinate plane locations are projected on

var() TCoordBounds CoordBounds;  // coordinate bounds for top, front, side view
var() TCoordCustom CoordCustom;  // coordinate system for custom view


// ============================================================================
// PrepareCoords
//
// Translates any of the simplified coordinate views to their coordinate
// system representation. Flips the coordinate system so that the origin is
// set into the upper-left texture corner, and inverts the axis vectors.
// ============================================================================

simulated protected function bool PrepareCoords() {

  local vector VectorAxes;

  if (CoordPlane != CoordPlane_Custom) {
     if (CoordBounds.Left == CoordBounds.Right ||
         CoordBounds.Top  == CoordBounds.Bottom)
       return False;

    CoordCustom.LocationOrigin       = vect(0,0,0);
    CoordCustom.VectorAxisHorizontal = vect(0,0,0);
    CoordCustom.VectorAxisVertical   = vect(0,0,0);
    
    VectorAxes.X = CoordBounds.Right - CoordBounds.Left;
    VectorAxes.Y = CoordBounds.Top   - CoordBounds.Bottom;
    }

  switch (CoordPlane) {
    case CoordPlane_ViewTop:
      CoordCustom.LocationOrigin.X = CoordBounds.Left;
      CoordCustom.LocationOrigin.Y = CoordBounds.Bottom;
      CoordCustom.VectorAxisHorizontal.X = VectorAxes.X;
      CoordCustom.VectorAxisVertical  .Y = VectorAxes.Y;
      break;
    
    case CoordPlane_ViewFront:
      CoordCustom.LocationOrigin.X = CoordBounds.Left;
      CoordCustom.LocationOrigin.Z = CoordBounds.Bottom;
      CoordCustom.VectorAxisHorizontal.X = VectorAxes.X;
      CoordCustom.VectorAxisVertical  .Z = VectorAxes.Y;
      break;
    
    case CoordPlane_ViewSide:
      CoordCustom.LocationOrigin.Y = CoordBounds.Left;
      CoordCustom.LocationOrigin.Z = CoordBounds.Bottom;
      CoordCustom.VectorAxisHorizontal.Y = VectorAxes.X;
      CoordCustom.VectorAxisVertical  .Z = VectorAxes.Y;
      break;
    }

  if (VSize(CoordCustom.VectorAxisHorizontal) == 0.0 ||
      VSize(CoordCustom.VectorAxisVertical)   == 0.0)
    return False;

  CoordCustom.LocationOrigin += CoordCustom.VectorAxisVertical;
  CoordCustom.VectorAxisHorizontal *= SizeScriptedTexture.X /  Square(VSize(CoordCustom.VectorAxisHorizontal));
  CoordCustom.VectorAxisVertical   *= SizeScriptedTexture.Y / -Square(VSize(CoordCustom.VectorAxisVertical));

  return True;
  }


// ============================================================================
// CalcLocation
//
// Calculates and returns the texture pixel coordinates corresponding to the
// given world coordinates.
// ============================================================================

simulated function vector CalcLocation(vector LocationWorld) {

  local vector LocationIcon;
  
  LocationWorld -= CoordCustom.LocationOrigin;
  LocationIcon.X = LocationWorld dot CoordCustom.VectorAxisHorizontal;
  LocationIcon.Y = LocationWorld dot CoordCustom.VectorAxisVertical;
  
  return LocationIcon;
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  CoordPlane = CoordPlane_ViewTop;
  CoordBounds = (Top=8192,Left=-8192,Right=8192,Bottom=-8192);
  }