// ============================================================================
// JBInteractionKeys
// Copyright 2004 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBInteractionKeys.uc,v 1.1 2004/04/14 12:06:53 mychaeel Exp $
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


// ============================================================================
// Localization
// ============================================================================

var localized string TextBindingsTop;        // first line of hint box
var localized string TextBindingsBottom;     // last  line of hint box
var localized array<string> TextBindings;    // descriptions of key bindings


// ============================================================================
// Variables
// ============================================================================

var array<TBinding> Bindings;                // temporary key bindings
var private int iBindingByKey[256];          // index of auto-binding, by key

var Color ColorBindingsText;                 // color for text
var Color ColorBindingsKey;                  // color for key names

var private byte bIsBoundToPrevWeapon[256];  // key is bound to PrevWeapon
var private byte bIsBoundToNextWeapon[256];  // key is bound to NextWeapon

var private float TimeFadeout;               // fadeout time for hint box


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
      if (bool(bIsBoundToPrevWeapon[InputKey])) { Camera.SwitchToPrev(PlayerController, True);  return True; }
      if (bool(bIsBoundToNextWeapon[InputKey])) { Camera.SwitchToNext(PlayerController, True);  return True; }
    }
  }
  
  return False;
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
  local vector LocationBox;
  local vector LocationText;
  local vector SizeBox;
  local vector SizeText;
  local vector SizeTextMax;
  local vector SizeTextKey;
  local vector SizeTextKeyMax;
  local vector Spacing;
  local array<string> Key;
  local PlayerController PlayerController;

  PlayerController = ViewportOwner.Actor;

  TimeCurrent = PlayerController.Level.TimeSeconds;
  if (bool(PlayerController.bFire) && TimeFadeout == 0.0)
    TimeFadeout = TimeCurrent + 1.0;

  Alpha = 1.0;
  if (TimeFadeout > 0.0)
    Alpha -= FClamp(TimeCurrent - TimeFadeout, 0.0, 1.0);

  if (Alpha == 0.0) {
    bVisible = False;
    return;
  }

  Canvas.Font = PlayerController.myHUD.GetConsoleFont(Canvas);

  for (iBinding = 0; iBinding < Bindings.Length; iBinding++) {
    if (!Bindings[iBinding].bIsBoundAuto)
      continue;
  
    Key[iBinding] = PlayerController.ConsoleCommand("LocalizedKeyName" @ Bindings[iBinding].iKeyAuto); 
  
    Canvas.TextSize(TextBindings[iBinding], SizeText   .X, SizeText   .Y);
    Canvas.TextSize(Key         [iBinding], SizeTextKey.X, SizeTextKey.Y);

    if (SizeText   .X > SizeTextMax   .X) SizeTextMax   .X = SizeText   .X;
    if (SizeTextKey.X > SizeTextKeyMax.X) SizeTextKeyMax.X = SizeTextKey.X;

    nBindings += 1;
  }

  Spacing.X = SizeText.Y;        // font height as horizontal spacing
  Spacing.Y = SizeText.Y * 3/4;  // spacing between paragraphs

  SizeBox.X = Spacing.X + SizeTextKeyMax.X + Spacing.X + SizeTextMax.X;
  SizeBox.Y = SizeText.Y + Spacing.Y + SizeText.Y * nBindings + Spacing.Y + SizeText.Y;

  Canvas.TextSize(TextBindingsTop,    SizeText.X, SizeText.Y);  if (SizeText.X > SizeBox.X) SizeBox.X = SizeText.X;
  Canvas.TextSize(TextBindingsBottom, SizeText.X, SizeText.Y);  if (SizeText.X > SizeBox.X) SizeBox.X = SizeText.X;

  SizeBox += Spacing * 2;        // outer box margin

  LocationBox.X = int((Canvas.ClipX - SizeBox.X) / 2);
  LocationBox.Y = int((Canvas.ClipY - SizeBox.Y) / 2);

  Canvas.Style = 5;  // ERenderStyle.STY_Alpha;

  Canvas.DrawColor.A = FClamp(150 * Alpha, 0, 255);
  Canvas.SetPos(LocationBox.X, LocationBox.Y);
  Canvas.DrawRect(Texture'BlackTexture', SizeBox.X, SizeBox.Y);
  
  LocationText = LocationBox + Spacing;
  
  ColorBindingsText.A = FClamp(255 * Alpha, 0, 255);
  ColorBindingsKey .A = FClamp(255 * Alpha, 0, 255);
  
  Canvas.DrawColor = ColorBindingsText;
  Canvas.SetPos(LocationText.X, LocationText.Y);
  Canvas.DrawText(TextBindingsTop);
  
  LocationText.Y += SizeText.Y + Spacing.Y;
  
  for (iBinding = 0; iBinding < Bindings.Length; iBinding++) {
    if (!Bindings[iBinding].bIsBoundAuto)
      continue;
  
    Canvas.DrawColor = ColorBindingsKey;
    Canvas.SetPos(LocationText.X + Spacing.X, LocationText.Y);
    Canvas.DrawText(Key[iBinding]);
    
    Canvas.DrawColor = ColorBindingsText;
    Canvas.SetPos(LocationText.X + Spacing.X + SizeTextKeyMax.X + Spacing.X, LocationText.Y);
    Canvas.DrawText(TextBindings[iBinding]);
  
    LocationText.Y += SizeText.Y;
  }

  Canvas.SetPos(LocationText.X, LocationText.Y + Spacing.Y);
  Canvas.DrawText(TextBindingsBottom);
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

  ColorBindingsText = (R=255,G=255,B=255);
  ColorBindingsKey  = (R=128,G=128,B=000);

  TextBindingsTop    = "Jailbreak has temporarily bound the following keys for you:";
  TextBindingsBottom = "Use the key binder to permanently bind keys to these functions.";
  
  TextBindings[0] = "Sets team tactics to a more aggressive stance.";
  TextBindings[1] = "Sets team tactics to a more defensive stance.";
  TextBindings[2] = "Returns to auto-selection of team tactics.";
  TextBindings[3] = "Activates the Arena Live Feed.";
}