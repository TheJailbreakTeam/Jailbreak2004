// ============================================================================
// JBInterfaceHud
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBInterfaceHud.uc,v 1.10 2003/02/26 17:46:15 mychaeel Exp $
//
// Heads-up display for Jailbreak, showing team states and switch locations.
// ============================================================================


class JBInterfaceHud extends HudBTeamDeathMatch
  notplaceable;


// ============================================================================
// Imports
// ============================================================================

#exec texture import file=Textures\IconDot.tga mips=on alpha=on


// ============================================================================
// Localization
// ============================================================================

var localized string TextMenuEntryTactics;
var localized string TextMenuTitleTactics;
var localized string TextOrderName[6];


// ============================================================================
// Variables
// ============================================================================

var SpriteWidget SpriteWidgetCompass[2];

var bool bWidescreen;                        // display widescreen bars
var private float RatioWidescreen;           // widescreen scroll-in progress

var private float TimeUpdateCompass;         // last compass rendering
var private float TimeUpdateDisposition;     // last disposition rendering
var private float TimeUpdateWidescreen;      // last widescreen bar rendering

var private byte SpeechMenuState;            // current speech menu state
var private bool bSpeechMenuVisible;         // speech menu displayed
var private bool bSpeechMenuVisibleTactics;  // tactics submenu displayed

var private JBDispositionTeam DispositionTeamRed;   // red team disposition
var private JBDispositionTeam DispositionTeamBlue;  // blue team disposition


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
// Updates the size and draws the widescreen bars.
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
  local float OffsetX;
  local float OffsetY;
  local float ScaleDot;
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
  
  firstTagObjective = JBGameReplicationInfo(PlayerOwner.GameReplicationInfo).firstTagObjective;
  for (thisTagObjective = firstTagObjective; thisTagObjective != None; thisTagObjective = thisTagObjective.nextTag) {
    Objective = thisTagObjective.GetObjective();
    
    switch (Objective.DefenderTeamIndex) {
      case 0:  Canvas.DrawColor = RedColor;   OffsetX = -0.033;  OffsetY = 0.048;  break;
      case 1:  Canvas.DrawColor = BlueColor;  OffsetX =  0.033;  OffsetY = 0.048;  break;
      }

    nPlayersReleasable = thisTagObjective.CountPlayersReleasable(True);

    ScaleDot = 1.0;
    if (nPlayersReleasable > 0) {
      thisTagObjective.ScaleDot -= 0.5 * nPlayersReleasable * TimeDelta;
      if (thisTagObjective.ScaleDot < 1.0)
        thisTagObjective.ScaleDot = (thisTagObjective.ScaleDot % 0.5) + 1.0;
      ScaleDot = thisTagObjective.ScaleDot;
      }
    
    AngleDot = ((rotator(Objective.Location - LocationOwner).Yaw - PlayerOwner.Rotation.Yaw) & 65535) * Pi / 32768;
    
    Canvas.Style = ERenderStyle.STY_Alpha;
    SetRelativePos(Canvas, OffsetX + 0.0305 * Sin(AngleDot),
                           OffsetY - 0.0405 * Cos(AngleDot), DP_UpperMiddle);
    Canvas.CurX -= 12 * Canvas.ClipX * HUDScale * ScaleDot / 1600;
    Canvas.CurY -= 12 * Canvas.ClipX * HUDScale * ScaleDot / 1600;
    Canvas.DrawRect(Texture'IconDot',
      24 * Canvas.ClipX * HUDScale * ScaleDot / 1600,
      24 * Canvas.ClipX * HUDScale * ScaleDot / 1600);
    }
  }


// ============================================================================
// ShowBuild
//
// Draws information about build time and date and the local player.
// ============================================================================

simulated function ShowBuild(Canvas Canvas) {

  local vector SizeText;

  Canvas.Font = GetConsoleFont(Canvas);
  Canvas.DrawColor = WhiteColor;

  Canvas.TextSize("X", SizeText.X, SizeText.Y);
  SizeText.Y = int(SizeText.Y * 1.1);
  
  Canvas.CurX = 8;  Canvas.CurY = 8;                   Canvas.DrawText(PlayerOwner.PlayerReplicationInfo.PlayerName);
  Canvas.CurX = 8;  Canvas.CurY = 8 + SizeText.Y;      Canvas.DrawText("Jailbreak 2003, %%%%-%%-%% %%:%%");
  Canvas.CurX = 8;  Canvas.CurY = 8 + SizeText.Y * 2;  Canvas.DrawText("Not for release or distribution");
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
  
  LTeamHud[0].OffsetX = -95;  RTeamHud[0].OffsetX = 95;
  LTeamHud[1].OffsetX = -95;  RTeamHud[1].OffsetX = 95;
  LTeamHud[2].OffsetX = -95;  RTeamHud[2].OffsetX = 95;
  
  TeamSymbols[0].OffsetX      =  -600;  TeamSymbols[1].OffsetX      =   600;
  TeamSymbols[0].OffsetY      =    90;  TeamSymbols[1].OffsetY      =    90;
  TeamSymbols[0].PosY         = 0.014;  TeamSymbols[1].PosY         = 0.014;
  TeamSymbols[0].TextureScale = 0.075;  TeamSymbols[1].TextureScale = 0.075;

  ScoreTeam[0].OffsetX = -270;  ScoreTeam[1].OffsetX = 180;
  ScoreTeam[0].OffsetY =   75;  ScoreTeam[1].OffsetY =  75;
  
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

  TagTeam = Class'JBTagTeam'.Static.FindFor(PlayerOwner.PlayerReplicationInfo.Team);

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

  SpriteWidgetCompass[0] = (WidgetTexture=Material'InterfaceContent.Hud.SkinA',TextureCoords=(X2=0,Y1=880,X1=142,Y2=1023),TextureScale=0.3,DrawPivot=DP_UpperRight,PosX=0.5,PosY=0.0,OffsetX=-2,OffsetY=5,ScaleMode=SM_Right,Scale=1.0,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255));
  SpriteWidgetCompass[1] = (WidgetTexture=Material'InterfaceContent.Hud.SkinA',TextureCoords=(X2=0,Y1=880,X1=142,Y2=1023),TextureScale=0.3,DrawPivot=DP_UpperLeft,PosX=0.5,PosY=0.0,OffsetX=2,OffsetY=5,ScaleMode=SM_Right,Scale=1.0,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255));

  ScoreBg[0] = (TextureCoords=(X2=0,Y1=0,X1=0,Y2=0));
  ScoreBg[1] = (TextureCoords=(X2=0,Y1=0,X1=0,Y2=0));
  ScoreBg[2] = (TextureCoords=(X2=0,Y1=0,X1=0,Y2=0));
  ScoreBg[3] = (TextureCoords=(X2=0,Y1=0,X1=0,Y2=0));
  }
