// ============================================================================
// JBInterfaceHud
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBInterfaceHud.uc,v 1.13 2003/03/15 18:47:14 mychaeel Exp $
//
// Heads-up display for Jailbreak, showing team states and switch locations.
// ============================================================================


class JBInterfaceHud extends HudBTeamDeathMatch
  notplaceable;


// ============================================================================
// Imports
// ============================================================================

#exec texture import file=Textures\SpriteWidgetHud.dds mips=on alpha=on


// ============================================================================
// Localization
// ============================================================================

var localized string TextMenuEntryTactics;   // tactics entry in order menu
var localized string TextMenuTitleTactics;   // title for tactics submenu
var localized string TextOrderName[6];       // selections in tactics submenu
var localized string TextTactics[5];         // tactics names for widget


// ============================================================================
// Variables
// ============================================================================

var bool bWidescreen;                        // display widescreen bars
var private float RatioWidescreen;           // widescreen scroll-in progress

var private transient JBTagPlayer TagPlayerOwner;   // player state for owner

var private float TimeUpdateCompass;         // last compass rendering
var private float TimeUpdateDisposition;     // last disposition rendering
var private float TimeUpdateTactics;         // last tactics rendering
var private float TimeUpdateWidescreen;      // last widescreen bar rendering

var private byte SpeechMenuState;            // current speech menu state
var private bool bSpeechMenuVisible;         // speech menu displayed
var private bool bSpeechMenuVisibleTactics;  // tactics submenu displayed

var private float AlphaCompass;              // transparency of compass dots
var private JBDispositionTeam DispositionTeamRed;   // red team disposition
var private JBDispositionTeam DispositionTeamBlue;  // blue team disposition

var string FontTactics;                      // name of font for tactics text
var vector LocationTextTactics;              // location of tactics text
var vector SizeIconTactics;                  // size of tactics icons
var vector SizeTextTactics;                  // relative size of tactics text
var Color ColorTactics[5];                   // colors for the tactics blob
var private float TacticsInterpolated;       // currently displayed tactics
var private Font FontObjectTactics;          // dynamically loaded font object

var SpriteWidget SpriteWidgetCompass[2];
var SpriteWidget SpriteWidgetCompassDot;
var SpriteWidget SpriteWidgetHandcuffs[2];

var SpriteWidget SpriteWidgetTacticsCircle;
var SpriteWidget SpriteWidgetTacticsBlob;
var SpriteWidget SpriteWidgetTacticsFill;
var SpriteWidget SpriteWidgetTacticsTint;
var SpriteWidget SpriteWidgetTacticsFrame;
var SpriteWidget SpriteWidgetTacticsIcon[5];
var SpriteWidget SpriteWidgetTacticsAuto;


// ============================================================================
// TeamScoreOffset
//
// Calculates and adjusts the draw offset of the team scores.
// ============================================================================

simulated function TeamScoreOffset() {

                                   ScoreTeam[1].OffsetX = 180;
  if     (ScoreTeam[1].Value  < 0) ScoreTeam[1].OffsetX += 90;
  if (Abs(ScoreTeam[1].Value) > 9) ScoreTeam[1].OffsetX += 90;
  }


// ============================================================================
// SetRelativePos
//
// Sets the pen position of the given Canvas to the specified relative
// position depending on the current scaling factors.
// ============================================================================

simulated function SetRelativePos(Canvas Canvas, float X, float Y, EDrawPivot Pivot) {

  local float OffsetPixelX;
  local float OffsetPixelY;
  
  switch (Pivot) {
    case DP_UpperLeft:
    case DP_UpperMiddle:
    case DP_UpperRight:
      OffsetPixelY = 0;
      break;
    
    case DP_MiddleLeft:
    case DP_MiddleMiddle:
    case DP_MiddleRight:
      OffsetPixelY = Canvas.ClipY / 2.0;
      break;
    
    case DP_LowerLeft:
    case DP_LowerMiddle:
    case DP_LowerRight:
      OffsetPixelY = Canvas.ClipY;
      break;
    }


  switch (Pivot) {
    case DP_UpperLeft:
    case DP_MiddleLeft:
    case DP_LowerLeft:
      OffsetPixelX = 0;
      break;
    
    case DP_UpperMiddle:
    case DP_MiddleMiddle:
    case DP_LowerMiddle:
      OffsetPixelX = Canvas.ClipX / 2.0;
      break;
    
    case DP_UpperRight:
    case DP_MiddleRight:
    case DP_LowerRight:
      OffsetPixelX = Canvas.ClipX;
      break;
    }

  OffsetPixelX += Canvas.ClipX * X * HUDScale;
  OffsetPixelY += Canvas.ClipY * Y * HUDScale;
  
  Canvas.SetPos(OffsetPixelX, OffsetPixelY);
  }


// ============================================================================
// PostRender
//
// Displays the overlays of the JBCamera actor the player is viewing from, if
// applicable. Otherwise just does the usual.
// ============================================================================

simulated event PostRender(Canvas Canvas) {

  if (PawnOwner != None)
    TagPlayerOwner = Class'JBTagPlayer'.Static.FindFor(PawnOwner.PlayerReplicationInfo);

  ShowWidescreen(Canvas);

  if (JBCamera(PlayerOwner.ViewTarget) != None) {
    PlayerOwner.ViewTarget.RenderOverlays(Canvas);

    if (bShowBadConnectionAlert)
      DisplayBadConnectionAlert(Canvas);
    DisplayMessages(Canvas);

    PlayerOwner.RenderOverlays(Canvas);

    if (PlayerConsole != None && PlayerConsole.bTyping)
      DrawTypingPrompt(Canvas, PlayerConsole.TypedStr);
    }
  
  else {
    Super.PostRender(Canvas);
    }
  }


// ============================================================================
// ShowPointBarBottom
// ShowPointBarTop
// ShowPersonalScore
//
// Disabled inherited functions.
// ============================================================================

simulated function ShowPointBarBottom(Canvas Canvas);
simulated function ShowPointBarTop(Canvas Canvas);
simulated function ShowPersonalScore(Canvas Canvas);


// ============================================================================
// ShowWidescreen
//
// Updates the size of and draws the widescreen bars.
// ============================================================================

simulated function ShowWidescreen(Canvas Canvas) {

  local int HeightBars;
  local float TimeDelta;
  
  TimeDelta = Level.TimeSeconds - TimeUpdateWidescreen;
  TimeUpdateWidescreen = Level.TimeSeconds;
  
  if (bWidescreen)
    RatioWidescreen = FMin(1.0, RatioWidescreen + TimeDelta);
  else
    RatioWidescreen = FMax(0.0, RatioWidescreen - TimeDelta);
  
  HeightBars = RatioWidescreen * Max(0, Canvas.ClipY - Canvas.ClipX / (16.0 / 9.0)) / 2;
  
  Canvas.Style = ERenderStyle.STY_Alpha;
  Canvas.DrawColor.A = 255 * RatioWidescreen;
  
  Canvas.SetPos(0, 0);             Canvas.DrawTileStretched(Texture'BlackTexture', Canvas.ClipX,  HeightBars);
  Canvas.SetPos(0, Canvas.ClipY);  Canvas.DrawTileStretched(Texture'BlackTexture', Canvas.ClipX, -HeightBars);
  }


// ============================================================================
// ShowTactics
//
// Updates and displays the team tactics widget.
// ============================================================================

simulated function ShowTactics(Canvas Canvas) {

  local float AlphaTactics;
  local float TacticsSelected;
  local float TimeDelta;
  local JBTagTeam TagTeam;

  TimeDelta = Level.TimeSeconds - TimeUpdateTactics;
  TimeUpdateTactics = Level.TimeSeconds;

  TagTeam = Class'JBTagTeam'.Static.FindFor(PawnOwner.PlayerReplicationInfo.Team);

  switch (TagTeam.GetTactics()) {
    case 'Evasive':     TacticsSelected = 0.0;  break;
    case 'Defensive':   TacticsSelected = 1.0;  break;
    case 'Normal':      TacticsSelected = 2.0;  break;
    case 'Aggressive':  TacticsSelected = 3.0;  break;
    case 'Suicidal':    TacticsSelected = 4.0;  break;
    }

  if (TacticsSelected > TacticsInterpolated)
    TacticsInterpolated = FMin(TacticsSelected, TacticsInterpolated + TimeDelta * 4.0);
  else
    TacticsInterpolated = FMax(TacticsSelected, TacticsInterpolated - TimeDelta * 4.0);

  AlphaTactics = TacticsInterpolated - int(TacticsInterpolated);
  
  if (AlphaTactics == 0.0)
    SpriteWidgetTacticsBlob.Tints[TeamIndex] = ColorTactics[int(TacticsInterpolated)];
  else {
    SpriteWidgetTacticsBlob.Tints[TeamIndex] =
      ColorTactics[int(TacticsInterpolated)    ]   * (1.0 - AlphaTactics) + 
      ColorTactics[int(TacticsInterpolated) + 1]   *        AlphaTactics;
    SpriteWidgetTacticsBlob.Tints[TeamIndex].A =
      ColorTactics[int(TacticsInterpolated)    ].A * (1.0 - AlphaTactics) + 
      ColorTactics[int(TacticsInterpolated) + 1].A *        AlphaTactics;
    }

  if (TacticsInterpolated < 1.0 ||
      TacticsInterpolated > 3.0)
    SpriteWidgetTacticsBlob.Tints[TeamIndex].A =
    SpriteWidgetTacticsBlob.Tints[TeamIndex].A *
      (1.0 - (Abs(2.0 - TacticsInterpolated) - 1.0) * (Level.TimeSeconds % 0.3) / 0.6);

  if (TagTeam.GetTacticsAuto())
    SpriteWidgetTacticsAuto.Scale = FMin(1.0, SpriteWidgetTacticsAuto.Scale + TimeDelta * 3.0);
  else
    SpriteWidgetTacticsAuto.Scale = FMax(0.0, SpriteWidgetTacticsAuto.Scale - TimeDelta * 3.0);
  SpriteWidgetTacticsAuto.PosY = -0.016 * (1.0 - SpriteWidgetTacticsAuto.Scale);

  DrawSpriteWidget(Canvas, SpriteWidgetTacticsFill);
  DrawSpriteWidget(Canvas, SpriteWidgetTacticsTint);
  DrawSpriteWidget(Canvas, SpriteWidgetTacticsFrame);
  DrawSpriteWidget(Canvas, SpriteWidgetTacticsAuto);
  DrawSpriteWidget(Canvas, SpriteWidgetTacticsCircle);
  DrawSpriteWidget(Canvas, SpriteWidgetTacticsBlob);

  if (FontObjectTactics == None)
    FontObjectTactics = Font(DynamicLoadObject(FontTactics, Class'Font'));

  ShowTacticsIcon(Canvas, int(TacticsInterpolated), AlphaTactics);
  if (AlphaTactics > 0.0)
    ShowTacticsIcon(Canvas, int(TacticsInterpolated) + 1, AlphaTactics - 1.0);
  }


// ============================================================================
// ShowTacticsIcon
//
// Displays a tactics icon and the accompanying text, faded and scrolled to
// the given alpha. Negative alpha values mean that the icon is above its
// normal position, positive values mean that it is below.
// ============================================================================

simulated function ShowTacticsIcon(Canvas Canvas, int iTactics, float Alpha) {

  SpriteWidgetTacticsIcon[iTactics].Tints[TeamIndex].A = 255 - 255 * Abs(Alpha);
  SpriteWidgetTacticsIcon[iTactics].PosY = SizeIconTactics.Y * Alpha;
  DrawSpriteWidget(Canvas, SpriteWidgetTacticsIcon[iTactics]);
  
  Canvas.Font = FontObjectTactics;
  Canvas.FontScaleX = SizeTextTactics.X * HUDScale * Canvas.ClipX / 1600;
  Canvas.FontScaleY = SizeTextTactics.Y * HUDScale * Canvas.ClipY / 1200;
  Canvas.DrawScreenText(
    TextTactics[iTactics],
    HUDScale *  LocationTextTactics.X,
    HUDScale * (LocationTextTactics.Y + SizeIconTactics.Y * Alpha / 2.0),
    DP_MiddleRight);

  Canvas.FontScaleX = Canvas.Default.FontScaleX;
  Canvas.FontScaleY = Canvas.Default.FontScaleY;
  }


// ============================================================================
// ShowDisposition
//
// Updates and displays the player disposition for both teams.
// ============================================================================

simulated function ShowDisposition(Canvas Canvas) {

  local float TimeDelta;

  if (DispositionTeamRed                       == None &&
      PlayerOwner.GameReplicationInfo          != None &&
      PlayerOwner.GameReplicationInfo.Teams[0] != None) {
    DispositionTeamRed = new Class'JBDispositionTeam';
    DispositionTeamRed.Initialize(PlayerOwner.GameReplicationInfo.Teams[0]);
    }

  if (DispositionTeamBlue                      == None &&
      PlayerOwner.GameReplicationInfo          != None &&
      PlayerOwner.GameReplicationInfo.Teams[1] != None) {
    DispositionTeamBlue = new Class'JBDispositionTeam';
    DispositionTeamBlue.Initialize(PlayerOwner.GameReplicationInfo.Teams[1]);
    }

  if (TimeUpdateDisposition > 0.0)
    TimeDelta = Level.TimeSeconds - TimeUpdateDisposition;
  TimeUpdateDisposition = Level.TimeSeconds;
  
  DispositionTeamRed .Update(TimeDelta);
  DispositionTeamBlue.Update(TimeDelta);
  
  DispositionTeamRed .Draw(Canvas, HUDScale);
  DispositionTeamBlue.Draw(Canvas, HUDScale);
  }


// ============================================================================
// ShowCompass
//
// Displays the compass dots.
// ============================================================================

simulated function ShowCompass(Canvas Canvas) {

  local int nPlayersReleasable;
  local float AngleDot;
  local float TimeDelta;
  local vector LocationOwner;
  local GameObjective Objective;
  local JBTagObjective firstTagObjective;
  local JBTagObjective thisTagObjective;
  
  TimeDelta = Level.TimeSeconds - TimeUpdateCompass;
  TimeUpdateCompass = Level.TimeSeconds;
  
  if (PawnOwner != None)
    LocationOwner = PawnOwner.Location;
  else
    LocationOwner = PlayerOwner.Location;
  
  if (TagPlayerOwner != None)
    if (TagPlayerOwner.IsFree())
      AlphaCompass = FMin(1.0, AlphaCompass + TimeDelta * 2.0);
    else
      AlphaCompass = FMax(0.0, AlphaCompass - TimeDelta * 2.0);
  
  if (AlphaCompass == 0.0)
    return;
  
  firstTagObjective = JBGameReplicationInfo(PlayerOwner.GameReplicationInfo).firstTagObjective;
  for (thisTagObjective = firstTagObjective; thisTagObjective != None; thisTagObjective = thisTagObjective.nextTag) {
    Objective = thisTagObjective.GetObjective();
    
    switch (Objective.DefenderTeamIndex) {
      case 0:
        SpriteWidgetCompassDot.Tints[TeamIndex] = RedColor;
        SpriteWidgetCompassDot.PosX = -0.034;
        SpriteWidgetCompassDot.PosY =  0.048;
        break;

      case 1:
        SpriteWidgetCompassDot.Tints[TeamIndex] = BlueColor;
        SpriteWidgetCompassDot.PosX =  0.034;
        SpriteWidgetCompassDot.PosY =  0.048;
        break;
      }

    nPlayersReleasable = thisTagObjective.CountPlayersReleasable(True);

    if (nPlayersReleasable > 0) {
      thisTagObjective.ScaleDot -= 0.5 * nPlayersReleasable * TimeDelta;
      if (thisTagObjective.ScaleDot < 1.0)
        thisTagObjective.ScaleDot = (thisTagObjective.ScaleDot % 0.5) + 1.0;
      }

    else if (thisTagObjective.ScaleDot != 1.0) {
      thisTagObjective.ScaleDot -= 0.5 * TimeDelta;
      if (thisTagObjective.ScaleDot < 1.0)
        thisTagObjective.ScaleDot = 1.0;
      }

    AngleDot = ((rotator(Objective.Location - LocationOwner).Yaw - PlayerOwner.Rotation.Yaw) & 65535) * Pi / 32768;
    SpriteWidgetCompassDot.PosX +=  0.0305 * Sin(AngleDot) + 0.5;
    SpriteWidgetCompassDot.PosY += -0.0405 * Cos(AngleDot);
    
    SpriteWidgetCompassDot.Tints[TeamIndex] = SpriteWidgetCompassDot.Tints[TeamIndex] * (1.0 / thisTagObjective.ScaleDot);
    SpriteWidgetCompassDot.Tints[TeamIndex].A = 255 * AlphaCompass;
    SpriteWidgetCompassDot.TextureScale = Default.SpriteWidgetCompassDot.TextureScale * thisTagObjective.ScaleDot;
    
    DrawSpriteWidget(Canvas, SpriteWidgetCompassDot);
    }
  }


// ============================================================================
// ShowBuild
//
// Draws information about build time and date and the local player.
// ============================================================================

simulated function ShowBuild(Canvas Canvas) {

  Canvas.Font = GetConsoleFont(Canvas);

  Canvas.DrawColor = WhiteColor;
  Canvas.DrawColor.A = 64;
  
  Canvas.DrawScreenText(
    PlayerOwner.PlayerReplicationInfo.PlayerName $ ", Jailbreak 2003, build" @ Class'Jailbreak'.Default.Build,
    0.5, 0.94, DP_LowerMiddle);
  }


// ============================================================================
// ShowTeamScorePassA
//
// Draws team status and compass.
// ============================================================================

simulated function ShowTeamScorePassA(Canvas Canvas) {

  Super.ShowTeamScorePassA(Canvas);

  DrawSpriteWidget(Canvas, SpriteWidgetCompass[0]);
  DrawSpriteWidget(Canvas, SpriteWidgetCompass[1]);
  
  DrawSpriteWidget(Canvas, SpriteWidgetHandcuffs[0]);
  DrawSpriteWidget(Canvas, SpriteWidgetHandcuffs[1]);
  
  ShowTactics(Canvas);
  ShowCompass(Canvas);
  ShowDisposition(Canvas);

  ShowBuild(Canvas);
  }


// ============================================================================
// LayoutMessage
//
// Makes sure that no message overlaps the player icons at the screen top.
// ============================================================================

simulated function LayoutMessage(out HudLocalizedMessage Message, Canvas Canvas) {

  Super.LayoutMessage(Message, Canvas);
  
  Message.PosY = FMax(Message.PosY, 0.16 * HUDScale);
  }


// ============================================================================
// GetTagClientOwner
//
// Returns the JBTagClient actor for the local player.
// ============================================================================

simulated function JBTagClient GetTagClientOwner() {

  return Class'JBTagClient'.Static.FindFor(PlayerOwner);
  }


// ============================================================================
// Tick
//
// Monitors the speech menu in order to hack into it.
// ============================================================================

simulated function Tick(float TimeDelta) {

  HackSpeechMenu();  // hack into the speech menu

  Super.Tick(TimeDelta);
  }


// ============================================================================
// HackSpeechMenu
//
// Hacks into the speech menu in order to add a team tactics selection there.
// Monitors the menu and adds or changes menu entries depending on the menu's
// current state.
// ============================================================================

simulated function HackSpeechMenu() {

  local byte KeySubmenuOrder;
  local ExtendedConsole Console;

  Console = ExtendedConsole(Level.GetLocalPlayerController().Player.Console);

  if (Console.IsInState('SpeechMenuVisible')) {
    if (Console.SMState != SpeechMenuState || !bSpeechMenuVisible) {
      if (Console.SMState == SMS_Main && bSpeechMenuVisibleTactics) {
        if (Console.bSpeechMenuUseLetters)
          KeySubmenuOrder = Console.LetterKeys[3];
        else
          KeySubmenuOrder = Console.NumberKeys[3];

        Console.SMAcceptSound = None;  // disable opening sound
        Console.KeyEvent(EInputKey(KeySubmenuOrder), IST_Press, 0.0);
        Console.SMAcceptSound = Console.Default.SMAcceptSound;
        }

      ResetSpeechMenu(Console);

      switch (Console.SMState) {
        case SMS_Order:
          bSpeechMenuVisibleTactics = False;
          SetupSpeechMenuOrders(Console);
          break;
        
        case SMS_PlayerSelect:
          bSpeechMenuVisibleTactics = (Console.SMIndex == 1337);
          if (bSpeechMenuVisibleTactics)
            SetupSpeechMenuTactics(Console);
          break;
        
        default:
          bSpeechMenuVisibleTactics = False;
          break;
        }
    
      bSpeechMenuVisible = True;
      SpeechMenuState = Console.SMState;
      }
    }

  else if (bSpeechMenuVisible) {
    ResetSpeechMenu(Console);
    bSpeechMenuVisible        = False;
    bSpeechMenuVisibleTactics = False;
    }
  }


// ============================================================================
// ResetSpeechMenu
//
// Resets everything that was permanently changed in the speech menu while the
// tactics submenu was displayed.
// ============================================================================

private simulated function ResetSpeechMenu(ExtendedConsole Console) {

  local int iStateName;

  for (iStateName = 0; iStateName < ArrayCount(Console.SMStateName); iStateName++)
    Console.SMStateName[iStateName] = Console.Default.SMStateName[iStateName];
  }


// ============================================================================
// SetupSpeechMenuOrders
//
// Adds a team tactics menu item to the orders submenu of the speech menu.
// ============================================================================

private simulated function SetupSpeechMenuOrders(ExtendedConsole Console) {

  Console.SMNameArray [Console.SMArraySize] = TextMenuEntryTactics;
  Console.SMIndexArray[Console.SMArraySize] = 1337;

  Console.SMArraySize += 1;
  }


// ============================================================================
// SetupSpeechMenuTactics
//
// Sets up the tactics submenu of the speech menu.
// ============================================================================

private simulated function SetupSpeechMenuTactics(ExtendedConsole Console) {

  local int iOrderNameTactics;
  local JBGameReplicationInfo InfoGame;
  local JBTagTeam TagTeam;

  Console.SMState = SMS_Other;
  Console.SMStateName[Console.SMState] = TextMenuTitleTactics;

  InfoGame = JBGameReplicationInfo(PlayerOwner.GameReplicationInfo);

  Console.SMArraySize = ArrayCount(InfoGame.OrderNameTactics);
  for (iOrderNameTactics = 0; iOrderNameTactics < Console.SMArraySize; iOrderNameTactics++) {
    Console.SMNameArray [iOrderNameTactics] = TextOrderName[iOrderNameTactics];
    Console.SMIndexArray[iOrderNameTactics] = InfoGame.OrderNameTactics[iOrderNameTactics].iOrderName;
    }

  TagTeam = Class'JBTagTeam'.Static.FindFor(PawnOwner.PlayerReplicationInfo.Team);

  if (TagTeam.GetTacticsAuto())
    Console.HighlightRow = 0;
  else {
    switch (TagTeam.GetTactics()) {
      case 'Suicidal':    Console.HighlightRow = 1;  break;
      case 'Aggressive':  Console.HighlightRow = 2;  break;
      case 'Normal':      Console.HighlightRow = 3;  break;
      case 'Defensive':   Console.HighlightRow = 4;  break;
      case 'Evasive':     Console.HighlightRow = 5;  break;
      }
    }
  }


// ============================================================================
// exec TeamTactics
//
// Allows the player to change the current team tactics from the console.
// Replicated to the server via ExecTeamTactics in JBTagPlayer.
// ============================================================================

simulated exec function TeamTactics(string TextTactics, optional string TextTeam) {

  local name Tactics;
  local TeamInfo Team;

       if (TextTeam ~= Left("red",  Len(TextTeam))) Team = PlayerOwner.GameReplicationInfo.Teams[0];
  else if (TextTeam ~= Left("blue", Len(TextTeam))) Team = PlayerOwner.GameReplicationInfo.Teams[1];
  
       if (TextTactics ~= Left("auto",       Len(TextTactics))) Tactics = 'Auto';
  else if (TextTactics ~= Left("up",         Len(TextTactics))) Tactics = 'MoreAggressive';
  else if (TextTactics ~= Left("down",       Len(TextTactics))) Tactics = 'MoreDefensive';
  else if (TextTactics ~= Left("evasive",    Len(TextTactics))) Tactics = 'Evasive';
  else if (TextTactics ~= Left("defensive",  Len(TextTactics))) Tactics = 'Defensive';
  else if (TextTactics ~= Left("normal",     Len(TextTactics))) Tactics = 'Normal';
  else if (TextTactics ~= Left("aggressive", Len(TextTactics))) Tactics = 'Aggressive';
  else if (TextTactics ~= Left("suicidal",   Len(TextTactics))) Tactics = 'Suicidal';

  GetTagClientOwner().ExecTeamTactics(Tactics, Team);
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  TextMenuEntryTactics = "Team tactics";
  TextMenuTitleTactics = "Team Tactics"

  TextOrderName[0] = "[AUTO]";
  TextOrderName[1] = "Suicidal";
  TextOrderName[2] = "Aggressive";
  TextOrderName[3] = "Normal";
  TextOrderName[4] = "Defensive";
  TextOrderName[5] = "Evasive";

  LocationTextTactics = (X=0.155,Y=0.028);
  SizeIconTactics     = (X=0.042,Y=0.054);
  SizeTextTactics     = (X=1.200,Y=1.200);

  FontTactics     = "UT2003Fonts.jFontMedium";
  TextTactics[0]  = "evasive";
  TextTactics[1]  = "defensive";
  TextTactics[2]  = "normal";
  TextTactics[3]  = "aggressive";
  TextTactics[4]  = "suicidal";

  ColorTactics[0] = (R=000,G=255,B=000,A=192);
  ColorTactics[1] = (R=128,G=255,B=128,A=192);
  ColorTactics[2] = (R=192,G=192,B=192,A=192);
  ColorTactics[3] = (R=255,G=192,B=128,A=192);
  ColorTactics[4] = (R=255,G=192,B=000,A=192);

  SpriteWidgetCompass[0]     = (WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X1=368,Y1=352,X2=510,Y2=494),TextureScale=0.3,DrawPivot=DP_UpperRight,PosX=0.5,PosY=0.0,OffsetX=-2,OffsetY=6,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255));
  SpriteWidgetCompass[1]     = (WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X1=368,Y1=352,X2=510,Y2=494),TextureScale=0.3,DrawPivot=DP_UpperLeft,PosX=0.5,PosY=0.0,OffsetX=2,OffsetY=6,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255));
  SpriteWidgetCompassDot     = (WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X1=304,Y1=352,X2=336,Y2=384),TextureScale=0.3,DrawPivot=DP_MiddleMiddle,RenderStyle=STY_Alpha);
  SpriteWidgetHandcuffs[0]   = (WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X1=064,Y1=400,X2=160,Y2=507),TextureScale=0.3,DrawPivot=DP_UpperRight,PosX=0.5,PosY=0.0,OffsetX=-29,OffsetY=23,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=51),Tints[1]=(R=255,G=255,B=255,A=51));
  SpriteWidgetHandcuffs[1]   = (WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X2=064,Y1=400,X1=160,Y2=507),TextureScale=0.3,DrawPivot=DP_UpperLeft,PosX=0.5,PosY=0.0,OffsetX=29,OffsetY=23,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=51),Tints[1]=(R=255,G=255,B=255,A=51));

  SpriteWidgetTacticsBlob    = (WidgetTexture=Material'InterfaceContent.Hud.SkinA',TextureCoords=(X1=810,Y1=200,X2=1023,Y2=413),TextureScale=0.20,DrawPivot=DP_UpperLeft,PosX=0,PosY=0,OffsetX=-15,OffsetY=-28,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=0,A=255),Tints[1]=(R=255,G=255,B=0,A=255))
  SpriteWidgetTacticsCircle  = (WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X1=368,Y1=352,X2=510,Y2=494),TextureScale=0.23,DrawPivot=DP_UpperLeft,PosX=0,PosY=0,OffsetX=000,OffsetY=000,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255))
  SpriteWidgetTacticsFill    = (WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X1=016,Y1=016,X2=382,Y2=109),TextureScale=0.23,DrawPivot=DP_UpperLeft,PosX=0,PosY=0,OffsetX=098,OffsetY=010,RenderStyle=STY_Alpha,Tints[0]=(R=100,G=000,B=000,A=200),Tints[1]=(R=048,G=075,B=120,A=200))
  SpriteWidgetTacticsTint    = (WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X1=016,Y1=128,X2=382,Y2=211),TextureScale=0.23,DrawPivot=DP_UpperLeft,PosX=0,PosY=0,OffsetX=098,OffsetY=010,RenderStyle=STY_Alpha,Tints[0]=(R=100,G=000,B=000,A=100),Tints[1]=(R=037,G=066,B=102,A=150))
  SpriteWidgetTacticsFrame   = (WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X1=016,Y1=240,X2=382,Y2=333),TextureScale=0.23,DrawPivot=DP_UpperLeft,PosX=0,PosY=0,OffsetX=098,OffsetY=010,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255))
  SpriteWidgetTacticsIcon[0] = (WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X1=400,Y1=016,X2=502,Y2=100),TextureScale=0.20,DrawPivot=DP_UpperLeft,PosX=0,PosY=0,OffsetX=036,OffsetY=040,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255));
  SpriteWidgetTacticsIcon[1] = (WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X1=400,Y1=128,X2=496,Y2=223),TextureScale=0.20,DrawPivot=DP_UpperLeft,PosX=0,PosY=0,OffsetX=035,OffsetY=038,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255));
  SpriteWidgetTacticsIcon[2] = (WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X1=176,Y1=400,X2=252,Y2=498),TextureScale=0.20,DrawPivot=DP_UpperLeft,PosX=0,PosY=0,OffsetX=044,OffsetY=034,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255));
  SpriteWidgetTacticsIcon[3] = (WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X1=272,Y1=400,X2=351,Y2=488),TextureScale=0.20,DrawPivot=DP_UpperLeft,PosX=0,PosY=0,OffsetX=043,OffsetY=037,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255));
  SpriteWidgetTacticsIcon[4] = (WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X1=400,Y1=240,X2=497,Y2=332),TextureScale=0.20,DrawPivot=DP_UpperLeft,PosX=0,PosY=0,OffsetX=033,OffsetY=037,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255));
  SpriteWidgetTacticsAuto    = (WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X1=080,Y1=352,X2=288,Y2=383),TextureScale=0.23,DrawPivot=DP_UpperLeft,PosX=0,PosY=0,OffsetX=060,OffsetY=102,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255),ScaleMode=SM_Up,Scale=1.0)

  LHud1[3]       = (WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X1=368,Y1=352,X2=510,Y2=494));
  RHud1[3]       = (WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X1=368,Y1=352,X2=510,Y2=494));
  Adrenaline[3]  = (WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X1=368,Y1=352,X2=510,Y2=494));
  AdrenalineIcon = (OffsetX=-1,OffsetY=10);
  ScoreTeam[0]   = (OffsetX=-270,OffsetY=75);
  ScoreTeam[1]   = (OffsetX=180,OffsetY=75);
  LTeamHud[0]    = (OffsetX=-95);
  LTeamHud[1]    = (OffsetX=-95);
  LTeamHud[2]    = (OffsetX=-95);
  RTeamHud[0]    = (OffsetX=95);
  RTeamHud[1]    = (OffsetX=95);
  RTeamHud[2]    = (OffsetX=95);
  TeamSymbols[0] = (OffsetX=-600,OffsetY=90,PosY=0.014,TextureScale=0.075);
  TeamSymbols[1] = (OffsetX=600,OffsetY=90,PosY=0.014,TextureScale=0.075);
  }
