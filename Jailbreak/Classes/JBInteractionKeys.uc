// ============================================================================
// JBInteractionKeys
// Copyright 2004 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Temporarily assigns keys which have not been bound by the user.
// ============================================================================


class JBInteractionKeys extends Interaction;


// ============================================================================
// Types
// ============================================================================

struct TBinding
{
  var string Alias;                          // alias to auto-bind if necessary
  var byte iKeyPreferred;                    // preferred key to auto-bind
  
  var private bool bIsBoundAuto;             // alias has been auto-bound
  var private bool bIsBoundConfig;           // alias bound by configuration
  var private int iKeyAuto;                  // index of auto-bound key
};


struct TDialog
{
  var Material MaterialFrame;                // dialog box frame and background
  var vector Margins;                        // margins within dialog box frame
  
  var string FontTitle;                      // font for dialog box title
  var string FontText;                       // font for text in dialog box
  var string FontKey;                        // font for key names
  var string FontClose;                      // font for closing hint
  
  var Color ColorTextTitle;                  // color for dialog box title
  var Color ColorTextKey;                    // color for key names
  var Color ColorText;                       // color for text in dialog box
  var Color ColorTextClose;                  // color for closing hint

  var vector OffsetTextTitle;                // offset dialog title from top
  var vector OffsetTextClose;                // offset closing hint from bottom

  var private GUIFont GUIFontTitle;          // loaded font for title
  var private GUIFont GUIFontKey;            // loaded font for key names
  var private GUIFont GUIFontText;           // loaded font for text
  var private GUIFont GUIFontClose;          // loaded font for closing hint
};


// ============================================================================
// Localization
// ============================================================================

var localized string TextDialogTitle;        // title at top of dialog box
var localized string TextDialogTopS;         // first line in dialog box (sing)
var localized string TextDialogTopP;         // first line in dialog box (plur)
var localized string TextDialogBottomS;      // last  line in dialog box (sing)
var localized string TextDialogBottomP;      // last  line in dialog box (plur)
var localized string TextDialogClose;        // hint at bottom of dialog box

var localized array<string> TextDescription; // key binding descriptions


// ============================================================================
// Variables
// ============================================================================

var array<TBinding> Bindings;                // temporary key bindings
var private int iBindingByKey[256];          // index of auto-binding, by key

var TDialog Dialog;                          // dialog box layout
var private float TimeFadeoutDialog;         // fadeout start time for dialog

var private byte bIsBoundToPrevWeapon[256];  // key is bound to PrevWeapon
var private byte bIsBoundToNextWeapon[256];  // key is bound to NextWeapon


// ============================================================================
// Initialized
//
// Checks which of the required aliases are bound already and finds temporary
// assignments for those which are not.
// ============================================================================

event Initialized()
{
  local bool bAutoBoundKeys;
  local byte bIsKeyBound  [256];
  local byte bIsKeyUnknown[256];
  local int iBinding;
  local int iKey;
  local int iKeyAuto;
  local string Alias;
  local string Key;

  for (iKey = 0; iKey < EInputKey.EnumCount; iKey++) {
    iBindingByKey[iKey] = -1;
    
    Key   = ViewportOwner.Actor.ConsoleCommand("KeyName"    @ iKey);
    Alias = ViewportOwner.Actor.ConsoleCommand("KeyBinding" @  Key);
        
    bIsKeyUnknown[iKey] = byte(Left(Key, 7) ~= "Unknown");

    if (Alias != "") {
      bIsKeyBound[iKey] = byte(True);
      for (iBinding = 0; iBinding < Bindings.Length; iBinding++)
        if (InStr(Caps(Alias), Caps(Bindings[iBinding].Alias)) >= 0)
          Bindings[iBinding].bIsBoundConfig = True;
    
      if (InStr(Caps(Alias), Caps("PrevWeapon")) >= 0) bIsBoundToPrevWeapon[iKey] = byte(True);
      if (InStr(Caps(Alias), Caps("NextWeapon")) >= 0) bIsBoundToNextWeapon[iKey] = byte(True);
    }
  }

  for (iBinding = 0; iBinding < Bindings.Length; iBinding++) {
    if (Bindings[iBinding].bIsBoundConfig)
      continue;
    
    iKeyAuto = Bindings[iBinding].iKeyPreferred;
    if (bool(bIsKeyBound[iKeyAuto]))
      for (iKeyAuto = EInputKey.IK_0; iKeyAuto <= EInputKey.IK_F12; iKeyAuto++)
        if (!bool(bIsKeyBound  [iKeyAuto]) &&
            !bool(bIsKeyUnknown[iKeyAuto]))
          break;

    if (iKeyAuto >= EInputKey.EnumCount)
      continue;  // no unbound key found
    
    bAutoBoundKeys = True;
    iBindingByKey[iKeyAuto] = iBinding;
    Bindings[iBinding].bIsBoundAuto = True;
    Bindings[iBinding].iKeyAuto = iKeyAuto;
    bIsKeyBound[iKeyAuto] = byte(True);
  }

  if (bAutoBoundKeys) {
    Log("Auto-bound keys:");
    for (iBinding = 0; iBinding < Bindings.Length; iBinding++)
      if (Bindings[iBinding].bIsBoundAuto)
        Log("Temporarily bound" @ GetKeyForCommand(Bindings[iBinding].Alias) @ "to '" $ Bindings[iBinding].Alias $ "'");

    bVisible = True;
  }
}


// ============================================================================
// KeyEvent
//
// Checks whether the entered key has been auto-assigned and executes the
// attached console command, if so. If a key bound to PrevWeapon or NextWeapon
// is pressed and the player is using a camera, passes those events to it.
// ============================================================================

event bool KeyEvent(out EInputKey InputKey, out EInputAction InputAction, float Delta)
{
  local int iBinding;
  local string Alias;
  local string Key;
  local PlayerController PlayerController;
  local JBCamera Camera;
  
  if (InputAction != IST_Press)
    return False;
    
  PlayerController = ViewportOwner.Actor;

  iBinding = iBindingByKey[InputKey];
  if (iBinding >= 0) {
    Key   = PlayerController.ConsoleCommand("KeyName"    @ InputKey);
    Alias = PlayerController.ConsoleCommand("KeyBinding" @      Key);

    if (Alias != "")
      return False;
    return ConsoleCommand(Bindings[iBinding].Alias);
  }

  if (PlayerController.Pawn == None) {
    Camera = JBCamera(PlayerController.ViewTarget);
    if (Camera != None && Camera.Switching.bAllowManual) {
      if (bool(bIsBoundToPrevWeapon[InputKey])) { GetTagClientLocal().ServerSwitchToPrevCamera(Camera, True);  return True; }
      if (bool(bIsBoundToNextWeapon[InputKey])) { GetTagClientLocal().ServerSwitchToNextCamera(Camera, True);  return True; }
    }
  }
  
  return False;
}


// ============================================================================
// GetTagClientLocal
//
// Returns a reference to the JBTagClient actor of the local player.
// ============================================================================

function JBTagClient GetTagClientLocal()
{
  return Class'JBTagClient'.Static.FindFor(ViewportOwner.Actor);
}


// ============================================================================
// PostRender
//
// Draws the list of automatically assigned key bindings on the screen.
// ============================================================================

event PostRender(Canvas Canvas)
{
  local int iBinding;
  local int nBindings;
  local float Alpha;
  local float TimeCurrent;
  local vector LocationDialog;
  local vector LocationText;
  local vector SizeDialog;
  local vector SizeText;
  local vector SizeTextMax;
  local vector SizeTextKey;
  local vector SizeTextKeyMax;
  local vector Spacing;
  local string TextDialogTop;
  local string TextDialogBottom;
  local array<string> Key;
  local Font FontTitle;
  local Font FontText;
  local Font FontKey;
  local Font FontClose;
  local GUIController GUIController;
  local PlayerController PlayerController;

  PlayerController = ViewportOwner.Actor;
  GUIController = GUIController(ViewportOwner.GUIController);

  TimeCurrent = PlayerController.Level.TimeSeconds;
  if (bool(PlayerController.bFire) && TimeFadeoutDialog == 0.0)
    TimeFadeoutDialog = TimeCurrent;

  if (PlayerController.myHUD.bShowScoreBoard)
    return;

  if (TimeFadeoutDialog == 0.0)
         Alpha =           1.0;
    else Alpha = FMax(0.0, 1.0 - (TimeCurrent - TimeFadeoutDialog) * 2.0);
    
  if (Alpha == 0.0) {
    bVisible = False;
    return;
  }

  if (Dialog.GUIFontTitle == None) Dialog.GUIFontTitle = GUIController.GetMenuFont(Dialog.FontTitle);
  if (Dialog.GUIFontText  == None) Dialog.GUIFontText  = GUIController.GetMenuFont(Dialog.FontText);
  if (Dialog.GUIFontKey   == None) Dialog.GUIFontKey   = GUIController.GetMenuFont(Dialog.FontKey);
  if (Dialog.GUIFontClose == None) Dialog.GUIFontClose = GUIController.GetMenuFont(Dialog.FontClose);

  FontTitle = Dialog.GUIFontTitle.GetFont(Canvas.ClipX);
  FontText  = Dialog.GUIFontText .GetFont(Canvas.ClipX);
  FontKey   = Dialog.GUIFontKey  .GetFont(Canvas.ClipX);
  FontClose = Dialog.GUIFontClose.GetFont(Canvas.ClipX);

  for (iBinding = 0; iBinding < Bindings.Length; iBinding++) {
    if (!Bindings[iBinding].bIsBoundAuto)
      continue;
  
    Key[iBinding] = PlayerController.ConsoleCommand("LocalizedKeyName" @ Bindings[iBinding].iKeyAuto); 
  
    Canvas.Font = FontText;  Canvas.TextSize(TextDescription[iBinding], SizeText   .X, SizeText   .Y);
    Canvas.Font = FontKey;   Canvas.TextSize(Key            [iBinding], SizeTextKey.X, SizeTextKey.Y);

    if (SizeText   .X > SizeTextMax   .X) SizeTextMax   .X = SizeText   .X;
    if (SizeTextKey.X > SizeTextKeyMax.X) SizeTextKeyMax.X = SizeTextKey.X;

    nBindings += 1;
  }

  Spacing.X = SizeText.Y * 1.5;
  Spacing.Y = SizeText.Y;

  SizeDialog.X = Spacing.X + SizeTextKeyMax.X + Spacing.X + SizeTextMax.X;
  SizeDialog.Y = SizeText.Y + Spacing.Y + SizeText.Y * nBindings + Spacing.Y + SizeText.Y;

  if (nBindings == 1)
         { TextDialogTop = TextDialogTopS;  TextDialogBottom = TextDialogBottomS; }
    else { TextDialogTop = TextDialogTopP;  TextDialogBottom = TextDialogBottomP; }

  Canvas.Font = FontText;
  Canvas.TextSize(TextDialogTop,    SizeText.X, SizeText.Y);  if (SizeText.X > SizeDialog.X) SizeDialog.X = SizeText.X;
  Canvas.TextSize(TextDialogBottom, SizeText.X, SizeText.Y);  if (SizeText.X > SizeDialog.X) SizeDialog.X = SizeText.X;

  SizeDialog += Dialog.Margins * 2;
  SizeDialog.Y *= 0.5 + Alpha * 0.5;

  LocationDialog.X = int((Canvas.ClipX - SizeDialog.X) / 2);
  LocationDialog.Y = int((Canvas.ClipY - SizeDialog.Y) / 2);

  Canvas.Style = 5;  // ERenderStyle.STY_Alpha;

  Canvas.DrawColor = Canvas.MakeColor(255, 255, 255);
  Canvas.DrawColor.A = 255 * Alpha;
  Canvas.SetPos(
    LocationDialog.X,
    LocationDialog.Y);
  Canvas.DrawTileStretched(
    Dialog.MaterialFrame,
    SizeDialog.X,
    SizeDialog.Y);
  
  LocationText = LocationDialog + Dialog.Margins;
  
  Dialog.ColorText     .A = Canvas.DrawColor.A;
  Dialog.ColorTextTitle.A = Canvas.DrawColor.A;
  Dialog.ColorTextKey  .A = Canvas.DrawColor.A;
  Dialog.ColorTextClose.A = Canvas.DrawColor.A;
  
  Canvas.SetClip(
    LocationDialog.X + SizeDialog.X - Dialog.Margins.X,
    LocationDialog.Y + SizeDialog.Y - Dialog.Margins.Y);

  Canvas.Font = FontTitle;
  Canvas.DrawColor = Dialog.ColorTextTitle;
  Canvas.DrawScreenText(
    TextDialogTitle,
    (LocationDialog.X + SizeDialog.X / 2.0 + Dialog.OffsetTextTitle.X) / Canvas.SizeX,
    (LocationDialog.Y                      + Dialog.OffsetTextTitle.Y) / Canvas.SizeY,
    DP_MiddleMiddle);
  
  Canvas.Font = FontText;
  Canvas.DrawColor = Dialog.ColorText;
  Canvas.SetPos(
    LocationText.X,
    LocationText.Y);
  Canvas.DrawTextClipped(TextDialogTop);
  
  LocationText.Y += SizeText.Y + Spacing.Y;
  
  for (iBinding = 0; iBinding < Bindings.Length; iBinding++) {
    if (!Bindings[iBinding].bIsBoundAuto)
      continue;
  
    Canvas.Font = FontKey;
    Canvas.DrawColor = Dialog.ColorTextKey;
    Canvas.SetPos(
      LocationText.X + Spacing.X,
      LocationText.Y);
    Canvas.DrawTextClipped(Key[iBinding]);
    
    Canvas.Font = FontText;
    Canvas.DrawColor = Dialog.ColorText;
    Canvas.SetPos(
      LocationText.X + Spacing.X + SizeTextKeyMax.X + Spacing.X,
      LocationText.Y);
    Canvas.DrawTextClipped(TextDescription[iBinding]);
  
    LocationText.Y += SizeText.Y;
  }

  Canvas.SetPos(
    LocationText.X,
    LocationText.Y + Spacing.Y);
  Canvas.DrawTextClipped(TextDialogBottom);

  Canvas.SetClip(
    Canvas.SizeX,
    Canvas.SizeY);

  Canvas.Font = FontClose;
  Canvas.DrawColor = Dialog.ColorTextClose;
  Canvas.DrawScreenText(
    TextDialogClose,
    (LocationDialog.X + SizeDialog.X / 2.0 + Dialog.OffsetTextClose.X) / Canvas.SizeX,
    (LocationDialog.Y + SizeDialog.Y       + Dialog.OffsetTextClose.Y) / Canvas.SizeY,
    DP_MiddleMiddle);
}


// ============================================================================
// NotifyLevelChange
//
// Removes this Interaction before level change.
// ============================================================================

event NotifyLevelChange()
{
  Master.RemoveInteraction(Self);
}


// ============================================================================
// GetKeyForCommand
//
// Returns the name of the key bound to the given command. Partial commands
// match. Prefers actual keys over mouse commands over joystick commands.
// Returns an the fallback string if no match is found.
// ============================================================================

static function string GetKeyForCommand(string Command, optional string Fallback)
{
  local int iBinding;
  local int iKey;
  local int RatingKey;
  local int RatingKeyBest;
  local string Alias;
  local string Key;
  local string KeyBest;
  local PlayerController PlayerController;
  local JBInteractionKeys InteractionKeys;
  
  foreach Default.Class.AllObjects(Class'JBInteractionKeys', InteractionKeys)
    break;
    
  if (InteractionKeys == None)
    return Fallback;
  
  PlayerController = InteractionKeys.ViewportOwner.Actor;
  
  for (iBinding = 0; iBinding < InteractionKeys.Bindings.Length; iBinding++)
    if (InteractionKeys.Bindings[iBinding].Alias ~= Command &&
        InteractionKeys.Bindings[iBinding].bIsBoundAuto)
      return PlayerController.ConsoleCommand("LocalizedKeyName" @ InteractionKeys.Bindings[iBinding].iKeyAuto);

  for (iKey = 0; iKey < EInputKey.EnumCount; iKey++) {
    Key   = PlayerController.ConsoleCommand("KeyName"    @ iKey);
    Alias = PlayerController.ConsoleCommand("KeyBinding" @  Key);

    if (InStr(Caps(Alias), Caps(Command)) < 0)
      continue;
    
         if (Left(Key, 3) ~= "Joy")   RatingKey = 1;
    else if (Left(Key, 5) ~= "Mouse") RatingKey = 2;
    else                              RatingKey = 3;
    
    if (RatingKey > RatingKeyBest) {
      KeyBest = PlayerController.ConsoleCommand("LocalizedKeyName" @ iKey);
      RatingKeyBest = RatingKey;
    }
  }

  if (KeyBest != "")
    return KeyBest;
  
  return Fallback;
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  Bindings[0] = (Alias="TeamTactics Up",iKeyPreferred=107);    // GreyPlus
  Bindings[1] = (Alias="TeamTactics Down",iKeyPreferred=109);  // GreyMinus
  Bindings[2] = (Alias="TeamTactics Auto",iKeyPreferred=111);  // GreySlash
  Bindings[3] = (Alias="ArenaCam",iKeyPreferred=106);          // GreyStar

  Dialog = (MaterialFrame=Texture'2K4Menus.Display99',Margins=(X=30,Y=44),FontTitle="UT2DefaultFont",FontText="UT2SmallFont",FontKey="UT2SmallFont",FontClose="UT2SmallFont",ColorTextTitle=(R=255,G=210,B=0),ColorText=(R=255,G=255,B=255),ColorTextKey=(R=255,G=210,B=0),ColorTextClose=(R=255,G=210,B=0),OffsetTextTitle=(Y=16),OffsetTextClose=(Y=-16));

  TextDialogTitle   = "Temporary Key Bindings";
  TextDialogTopS    = "Jailbreak has temporarily bound the following key for you:";
  TextDialogTopP    = "Jailbreak has temporarily bound the following keys for you:";
  TextDialogBottomS = "Use the key binder to permanently bind a key to this function.";
  TextDialogBottomP = "Use the key binder to permanently bind keys to these functions.";
  TextDialogClose   = "Press FIRE to close";
  
  TextDescription[0] = "Sets team tactics to a more aggressive stance.";
  TextDescription[1] = "Sets team tactics to a more defensive stance.";
  TextDescription[2] = "Returns to auto-selection of team tactics.";
  TextDescription[3] = "Activates the Arena Live Feed.";
}