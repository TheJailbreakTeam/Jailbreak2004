// ============================================================================
// JBPanorama
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBPanorama.uc,v 1.2 2003/06/30 20:59:00 mychaeel Exp $
//
// Marks the viewpoint for the panoramic map overview in the scoreboard.
// ============================================================================


class JBPanorama extends Keypoint
  placeable;


// ============================================================================
// Replication
// ============================================================================

replication
{
  reliable if (Role == ROLE_Authority)
    RepLocation, RepRotation, TexturePanorama, FieldOfView;
}


// ============================================================================
// Properties
// ============================================================================

var() Texture TexturePanorama;     // panoramic overview of the level
var() float FieldOfView;           // field of view for panoramic overview


// ============================================================================
// Localization
// ============================================================================

var localized string TextSetup;    // panorama level setup instructions
var localized string TextPreview;  // dynamically rendered preview warning


// ============================================================================
// Variables
// ============================================================================

var private vector RepLocation;              // replicated actor location
var private rotator RepRotation;             // replicated actor rotation

var private float TimeRenderFirst;           // time of first panorama render

var private Coords CoordsPanorama;           // coordinate system of viewpoint
var private float ScaleDepth;                // field of view depth adjustment

var private vector SizeMaterialPanorama;     // pixel size of panorama material
var private Material MaterialPanorama;       // internal panorama material
var private Texture TexturePanoramaInitial;  // initial value for clipboard


// ============================================================================
// UpdatePrecacheMaterials
//
// Adds the panorama texture to the global list of precached materials.
// ============================================================================

simulated function UpdatePrecacheMaterials()
{
  Level.AddPrecacheMaterial(TexturePanorama);
}


// ============================================================================
// PostBeginPlay
//
// Replicated the actor's location and rotation to clients. Required because
// movement variables are only unreliably replicated and thus haven't reached
// the client already when PostNetBeginPlay is called.
// ============================================================================

event PostBeginPlay()
{
  RepLocation = Location;
  RepRotation = Rotation;
}


// ============================================================================
// PostNetBeginPlay
//
// Calls Prepare for the initial values of this actor. Saves the initial
// value of TexturePanorama for clipboard copy operations. Registers this
// actor with the local player's scoreboard.
// ============================================================================

simulated event PostNetBeginPlay()
{
  local PlayerController PlayerControllerLocal;

  TexturePanoramaInitial = TexturePanorama;

  PlayerControllerLocal = Level.GetLocalPlayerController();
  if (                  PlayerControllerLocal                   != None &&
      JBInterfaceScores(PlayerControllerLocal.myHUD.ScoreBoard) != None)
    JBInterfaceScores(PlayerControllerLocal.myHUD.ScoreBoard).Panorama = Self;

  SetLocation(RepLocation);
  SetRotation(RepRotation);

  Prepare();
}


// ============================================================================
// Prepare
//
// Must be called whenever properties were changed to prepare upcoming draw
// and calculation operations.
// ============================================================================

simulated function Prepare()
{
  PrepareCoords();
  PrepareMaterial();
}


// ============================================================================
// PrepareCoords
//
// Prepares the panorama's coordinate system for location translations.
// ============================================================================

simulated protected function PrepareCoords()
{
  CoordsPanorama.Origin = Location;

  GetAxes(Rotation,
    CoordsPanorama.XAxis,
    CoordsPanorama.YAxis,
    CoordsPanorama.ZAxis);

  ScaleDepth = 1.0 / Tan(FieldOfView * Pi / 360.0);
}


// ============================================================================
// PrepareMaterial
//
// Prepares the material that will be drawn on the screen. In case no texture
// has been specified, dynamically creates a screenshot.
// ============================================================================

simulated protected function PrepareMaterial()
{
  if (TexturePanorama != None) {
    MaterialPanorama = TexturePanorama;

    SizeMaterialPanorama.X = TexturePanorama.USize;
    SizeMaterialPanorama.Y = TexturePanorama.VSize;
  }

  else {
    SizeMaterialPanorama.X = 512;
    SizeMaterialPanorama.Y = 512;

    if (ScriptedTexture(MaterialPanorama) == None) {
      MaterialPanorama = new Class'ScriptedTexture';

      ScriptedTexture(MaterialPanorama).SetSize(SizeMaterialPanorama.X, SizeMaterialPanorama.Y);
      ScriptedTexture(MaterialPanorama).Client = Self;
    }

    ScriptedTexture(MaterialPanorama).Revision++;
  }
}


// ============================================================================
// RenderTexture
//
// Renders a panorama view of the map on the scripted texture.
// ============================================================================

simulated event RenderTexture(ScriptedTexture ScriptedTexture)
{
  ScriptedTexture.DrawPortal(
    0,
    0,
    ScriptedTexture.USize,
    ScriptedTexture.VSize - 1,  // bug workaround
    Self,
    Location,
    Rotation,
    FieldOfView);
}


// ============================================================================
// Draw
//
// Draws the current panorama view at the bottom middle of the screen.
// ============================================================================

simulated function Draw(Canvas Canvas)
{
  local float ScaleMaterialPanorama;
  local vector SizeMaterialPanoramaScaled;
  local vector LocationMaterialPanorama;

  ScaleMaterialPanorama = 256 / SizeMaterialPanorama.X * Canvas.ClipX / 640;
  SizeMaterialPanoramaScaled = SizeMaterialPanorama * ScaleMaterialPanorama;

  LocationMaterialPanorama.X = (Canvas.ClipX - SizeMaterialPanoramaScaled.X) / 2;
  LocationMaterialPanorama.Y =  Canvas.ClipY - SizeMaterialPanoramaScaled.Y + SizeMaterialPanoramaScaled.X / 8;

  if (TimeRenderFirst == 0.0)
    TimeRenderFirst = Level.TimeSeconds;

  Canvas.Style = ERenderStyle.STY_Alpha;
  Canvas.SetDrawColor(255, 255, 255, 1 + 254 * FMin(1.0, (Level.TimeSeconds - TimeRenderFirst) * 2.0));
  Canvas.SetPos(LocationMaterialPanorama.X, LocationMaterialPanorama.Y);

  Canvas.DrawTile(
    MaterialPanorama,
    SizeMaterialPanoramaScaled.X,
    SizeMaterialPanoramaScaled.Y,
    0,
    0,
    SizeMaterialPanorama.X,
    SizeMaterialPanorama.Y);

  if (ScriptedTexture(MaterialPanorama) != None && Level.NetMode == NM_Standalone)
    DrawStatus(Canvas, TextPreview);
}


// ============================================================================
// DrawStatus
//
// Draws a pulsing status text at the bottom of the screen.
// ============================================================================

static function DrawStatus(Canvas Canvas, string TextStatus)
{
  Canvas.SetDrawColor(255, 255, 255, 128 + 127 * Sin(Canvas.Viewport.Actor.Level.TimeSeconds * 6.0));

  Canvas.Font = Canvas.TinyFont;
  Canvas.DrawScreenText(TextStatus, 0.500, 1.000, DP_LowerMiddle);
}


// ============================================================================
// CalcLocation
//
// Calculates and returns the screen pixel that corresponds to the given world
// location on the panorama map. The returned Z component specifies the
// distance from the viewing plane to the given location in world units. If it
// is zero, the X and Y components are undefined.
// ============================================================================

simulated function vector CalcLocation(Canvas Canvas, vector LocationWorld)
{
  local float ScaleLateral;
  local vector LocationScreenOrigin;
  local vector LocationScreen;

  LocationWorld -= CoordsPanorama.Origin;

  LocationScreen.X = LocationWorld dot CoordsPanorama.YAxis;
  LocationScreen.Y = LocationWorld dot CoordsPanorama.ZAxis;
  LocationScreen.Z = LocationWorld dot CoordsPanorama.XAxis;

  if (LocationScreen.Z == 0.0)
    return vect(0,0,0);  // undefined

  ScaleLateral = ScaleDepth / LocationScreen.Z * Canvas.ClipX * 0.200;

  LocationScreen.X *=  ScaleLateral;
  LocationScreen.Y *= -ScaleLateral;

  LocationScreenOrigin.X =                Canvas.ClipX * 0.500;
  LocationScreenOrigin.Y = Canvas.ClipY - Canvas.ClipX * 0.150;
  LocationScreen += LocationScreenOrigin;

  return LocationScreen;
}


// ============================================================================
// CopyToClipboard
//
// Copies this JBPanorama actor to the clipboard in order to let users paste
// it into a level in UnrealEd.
// ============================================================================

function CopyToClipboard()
{
  local string TextClipboard;
  local string TextTexture;

  TextTexture = "None";
  if (TexturePanoramaInitial != None)
    TextTexture = TexturePanoramaInitial.Class.Name $ "'" $ TexturePanoramaInitial.Name $ "'";

  TextClipboard = "Begin Map"                                      $ Chr(13) $ Chr(10) $
                  "Begin Actor Class=JBPanorama"                   $ Chr(13) $ Chr(10) $
                  "    TexturePanorama=" $ TextTexture             $ Chr(13) $ Chr(10) $
                  "    Location=(X="     $ Location.X - 32.0 $ "," $
                                "Y="     $ Location.Y - 32.0 $ "," $
                                "Z="     $ Location.Z - 32.0 $ ")" $ Chr(13) $ Chr(10) $
                  "    Rotation=(Yaw="   $ Rotation.Yaw      $ "," $
                                "Pitch=" $ Rotation.Pitch    $ "," $
                                "Roll="  $ Rotation.Roll     $ ")" $ Chr(13) $ Chr(10) $
                  "    FieldOfView="     $ FieldOfView             $ Chr(13) $ Chr(10) $
                  "End Actor"                                      $ Chr(13) $ Chr(10) $
                  "End Map"                                        $ Chr(13) $ Chr(10);

  Level.GetLocalPlayerController().CopyToClipboard(TextClipboard);
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  FieldOfView = 90.0;

  TextSetup   = "enter SetupPanorama at the console"
  TextPreview = "preview only, assign TexturePanorama"

  bDirectional    = True;
  bStatic         = False;
  bAlwaysRelevant = True;
}