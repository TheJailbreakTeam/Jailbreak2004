// ============================================================================
// JBInteractionPanorama
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Provides a special interactive adjustment mode for the scoreboard overlook
// map. Use the SetupPanorama console command to enter this mode.
// ============================================================================


class JBInteractionPanorama extends Interaction
  notplaceable;


// ============================================================================
// Localization
// ============================================================================

var localized string TextInstructionsHidden;
var localized string TextInstructions[17];

var localized string TextStatusCopy;
var localized string TextStatusScreenshot;


// ============================================================================
// Variables
// ============================================================================

var private LevelInfo Level;               // convenient LevelInfo reference

var private bool bHideHudPrev;             // previous state of bHideHud
var private bool bPlayersOnlyPrev;         // previous state of bPlayersOnly
var private float FOVAnglePrev;            // previous field of view
var private Pawn PawnPlayerPrev;           // previous pawn of player
var private array<Actor> ListActorHidden;  // actors hidden during startup

var private bool bPressedShift;            // shift key is pressed down
var private bool bShowInstructions;        // instructions are being displayed
var private bool bTakeScreenshot;          // take screenshot on next tick
var private string TextStatus;             // status text at bottom of screen


// ============================================================================
// Initialized
//
// Sets bPlayersOnly and hides all pickup actors, saving a list of their
// references for later unhiding. Puts the player in ghost spectator mode.
// ============================================================================

event Initialized() {

  local Actor thisActor;
  local JBPanorama Panorama;

  Level = ViewportOwner.Actor.Level;

  bHideHudPrev = ViewportOwner.Actor.myHUD.bHideHud;
  ViewportOwner.Actor.myHUD.bHideHud = True;

  bPlayersOnlyPrev = Level.bPlayersOnly;
  Level.bPlayersOnly = True;
  
  foreach Level.AllActors(Class'Actor', thisActor)
    if (Pawn(thisActor) != None) {
      thisActor.bHidden = True;
      ListActorHidden[ListActorHidden.Length] = thisActor;
      }

  PawnPlayerPrev = ViewportOwner.Actor.Pawn;
  FOVAnglePrev   = ViewportOwner.Actor.FOVAngle;

  ViewportOwner.Actor.UnPossess();
  ViewportOwner.Actor.bCollideWorld = False;
  
  Panorama = FindPanorama();

  if (Panorama == None) {
    ViewportOwner.Actor.FOVAngle = 90.0;
    }
  
  else {
    ViewportOwner.Actor.SetLocation(Panorama.Location);
    ViewportOwner.Actor.SetRotation(Panorama.Rotation);
    ViewportOwner.Actor.FOVAngle = Panorama.FieldOfView;
    }
  }


// ============================================================================
// NotifyLevelChange
//
// Cleans up before level change.
// ============================================================================

event NotifyLevelChange() {

  Cleanup();
  }


// ============================================================================
// Cleanup
//
// Cleans up when leaving overlook adjustment mode and unregisters this
// interaction. Unhides all previously hidden actors, puts the player back
// into his or her old body and resets the bPlayersOnly flag.
// ============================================================================

function Cleanup() {

  local int iActorHidden;
  
  ViewportOwner.Actor.myHUD.bHideHud = bHideHudPrev;
  Level.bPlayersOnly = bPlayersOnlyPrev;

  for (iActorHidden = 0; iActorHidden < ListActorHidden.Length; iActorHidden++)
    if (ListActorHidden[iActorHidden] != None)
      ListActorHidden[iActorHidden].bHidden = False;
  ListActorHidden.Length = 0;

  if (PawnPlayerPrev != None)
    ViewportOwner.Actor.Possess(PawnPlayerPrev);
  ViewportOwner.Actor.FOVAngle = FOVAnglePrev;

  Master.RemoveInteraction(Self);
  }


// ============================================================================
// FindPanorama
//
// Gets this level's JBPanorama actor. Returns None if none exists.
// ============================================================================

function JBPanorama FindPanorama() {

  local JBPanorama thisPanorama;

  if (JBInterfaceScores(ViewportOwner.Actor.myHUD.ScoreBoard) != None)
    return JBInterfaceScores(ViewportOwner.Actor.myHUD.ScoreBoard).Panorama;

  foreach Level.DynamicActors(Class'JBPanorama', thisPanorama)
    return thisPanorama;

  return None;
  }


// ============================================================================
// PlacePanorama
//
// Sets the JBPanorama actor to the player's current location and rotation.
// Creates such an actor if none exists yet. Returns a reference to it.
// ============================================================================

function JBPanorama PlacePanorama() {

  local vector LocationViewpoint;
  local rotator RotationViewpoint;
  local Actor ActorViewpoint;
  local JBPanorama Panorama;

  Panorama = FindPanorama();
  if (Panorama == None)
    Panorama = Level.Spawn(Class'JBPanorama');

  ViewportOwner.Actor.PlayerCalcView(ActorViewpoint, LocationViewpoint, RotationViewpoint);

  Panorama.TexturePanorama = None;  // force dynamic
  Panorama.SetLocation(LocationViewpoint);
  Panorama.SetRotation(RotationViewpoint);
  Panorama.FieldOfView = ViewportOwner.Actor.FOVAngle;

  Panorama.Prepare();
  
  if (JBInterfaceScores(ViewportOwner.Actor.myHUD.ScoreBoard) != None)
    JBInterfaceScores(ViewportOwner.Actor.myHUD.ScoreBoard).Panorama = Panorama;

  return Panorama;
  }


// ============================================================================
// CopyPanorama
//
// Copies a JBPanorama actor with the current settings to the clipboard.
// ============================================================================

function CopyPanorama() {

  local JBPanorama Panorama;
  
  Panorama = PlacePanorama();
  Panorama.CopyToClipboard();
  }


// ============================================================================
// KeyEvent
//
// Intercepts special key events used by this interaction.
// ============================================================================

function bool KeyEvent( out EInputKey InputKey, out EInputAction InputAction, float Delta) {

  if (InputKey == IK_Shift)
    if (InputAction == IST_Press)
      bPressedShift = True;
    else if (InputAction == IST_Release)
      bPressedShift = False;

  if (bPressedShift && InputAction == IST_Press) {
    switch (InputKey) {
      case IK_H:
        bShowInstructions = !bShowInstructions;
        return True;
      
      case IK_GreyPlus:
        ViewportOwner.Actor.FOVAngle -= 1.0;
        if (ViewportOwner.Actor.FOVAngle < 1.0)
          ViewportOwner.Actor.FOVAngle = 1.0;
        return True;

      case IK_GreyMinus:
        ViewportOwner.Actor.FOVAngle += 1.0;
        return True;

      case IK_GreyStar:
        ViewportOwner.Actor.FOVAngle = 90.0;
        return True;

      case IK_S:
        PlacePanorama();
        bTakeScreenshot = True;
        TextStatus = TextStatusScreenshot;
        return True;

      case IK_C:
        CopyPanorama();
        TextStatus = TextStatusCopy;
        return True;

      case IK_X:
        Cleanup();
        return True;
      }
    }

  return Super.KeyEvent(InputKey, InputAction, Delta);
  }


// ============================================================================
// PostRender
//
// Draws a crosshair and instructions on the screen.
// ============================================================================

event PostRender(Canvas Canvas) {

  local int iLineInstructions;
  local vector LocationInstructions;
  local vector LocationStatus;
  local vector LocationZoom;
  local vector SizeCharacter;
  local string TextZoom;

  if (bTakeScreenshot) {
    ConsoleCommand("shot");
    bTakeScreenshot = False;
    }

  else {
    Canvas.Style = 5;  // ERenderStyle.STY_Alpha;
  
    Canvas.SetDrawColor(255, 255, 255, 64);
    Canvas.SetPos(0, Canvas.ClipY / 2);
    Canvas.DrawRect(Texture'WhiteTexture', Canvas.ClipX, 1);
    Canvas.SetPos(Canvas.ClipX / 2, 0);
    Canvas.DrawRect(Texture'WhiteTexture', 1, Canvas.ClipY);
    
    Canvas.SetDrawColor(255, 255, 255);
    Canvas.Font = Canvas.TinyFont;
    Canvas.TextSize("X", SizeCharacter.X, SizeCharacter.Y);
    
    LocationInstructions.X = Canvas.ClipX * 0.030;
    LocationInstructions.Y = Canvas.ClipY * 0.040;
    
    if (bShowInstructions) {
      for (iLineInstructions = 0; iLineInstructions < ArrayCount(TextInstructions); iLineInstructions++) {
        Canvas.SetPos(LocationInstructions.X, LocationInstructions.Y + iLineInstructions * SizeCharacter.Y);
        Canvas.DrawText(TextInstructions[iLineInstructions]);
        }
      }
    
    else {
      Canvas.SetPos(LocationInstructions.X, LocationInstructions.Y);
      Canvas.DrawText(TextInstructionsHidden);
      }

    TextZoom = "Field of View:" @ int(ViewportOwner.Actor.FOVAngle) $ "°";

    LocationZoom.X = Canvas.ClipX * 0.970 - SizeCharacter.X * Len(TextZoom);
    LocationZoom.Y = Canvas.ClipY * 0.040;

    Canvas.SetPos(LocationZoom.X, LocationZoom.Y);
    Canvas.DrawText(TextZoom);

    if (TextStatus != "") {
      LocationStatus.X = Canvas.ClipX * 0.030;
      LocationStatus.Y = Canvas.ClipY * 0.960 - SizeCharacter.Y;

      Canvas.SetPos(LocationStatus.X, LocationStatus.Y);
      Canvas.DrawText(TextStatus);
      }
    }
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  bShowInstructions = True;

  TextInstructionsHidden = "Press Shift+H to show instructions.";

  TextInstructions[ 0] = "SCOREBOARD MAP PANORAMA ADJUSTMENT MODE";
  TextInstructions[ 1] = "";
  TextInstructions[ 2] = "";
  TextInstructions[ 3] = "STEP 1: Move the camera to a position where you have a nice view of the entire map.";
  TextInstructions[ 4] = "        Press Shift+GreyPlus and Shift+GreyMinus to zoom in or out, Shift+GreyStar to reset.";
  TextInstructions[ 5] = "";
  TextInstructions[ 6] = "STEP 2: Press Shift+S to take a screenshot of the map.";
  TextInstructions[ 7] = "        Press Shift+C to copy a pre-setup JBPanorama actor to the clipboard.";
  TextInstructions[ 8] = "";
  TextInstructions[ 9] = "STEP 3: Use the screenshot to make a texture showing a panorama of your map.";
  TextInstructions[10] = "        Import it into your map's MyLevel package.";
  TextInstructions[11] = "        Reload Jailbreak.u and paste the JBPanorama actor from the clipboard into your map.";
  TextInstructions[12] = "        Set its TexturePanorama property to the imported panorama texture.";
  TextInstructions[13] = "";
  TextInstructions[14] = "";
  TextInstructions[15] = "Press Shift+H to hide these instructions.";
  TextInstructions[16] = "Press Shift+X to exit adjustment mode.";

  TextStatusCopy       = "JBPanorama actor copied to the clipboard.";
  TextStatusScreenshot = "Screenshot saved to the last Shot?????.bmp file in your System directory.";

  bVisible      = True;
  bRequiresTick = True;
  }