// ============================================================================
// JBInterfaceHUD
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Heads-up display for Jailbreak, showing team states and switch locations.
// ============================================================================


class JBInterfaceHUD extends HudBTeamDeathMatch
  notplaceable;


// ============================================================================
// Variables
// ============================================================================

var() SpriteWidget SpriteWidgetCompass[2];

var private float TimeUpdateCompass;
var private array<JBInventoryObjective> ListInventoryObjective;


// ============================================================================
// LinkActors
//
// Fills the ListObjective array with a list of objectives.
// ============================================================================

simulated function LinkActors() {

  local JBInventoryObjective thisInventory;
  
  if (ListInventoryObjective.Length == 0)
    foreach DynamicActors(Class'JBInventoryObjective', thisInventory)
      ListInventoryObjective[ListInventoryObjective.Length] = thisInventory;

  Super.LinkActors();
  }


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
// ShowTeamStatus
//
// Draws the number of jailed and free players of the given team at the
// current pen position.
// ============================================================================

simulated function ShowTeamStatus(Canvas Canvas, JBReplicationInfoTeam Team) {

  local int nPlayersOut;
  local int nPlayersTotal;
  local float OriginX;
  local float OriginY;

  Canvas.Font = GetMediumFontFor(Canvas);
  Canvas.FontScaleX = 0.7 * HUDScale;
  Canvas.FontScaleY = 0.7 * HUDScale;
  Canvas.DrawColor = WhiteColor;
  
  nPlayersOut   = Team.CountPlayersTotal() - Team.CountPlayersFree(True);
  nPlayersTotal = Team.CountPlayersTotal();

  OriginX = Canvas.CurX / Canvas.ClipX;
  OriginY = Canvas.CurY / Canvas.ClipY;
  
  Canvas.DrawScreenText(string(nPlayersOut),   OriginX, OriginY + 0.002 * HUDScale, DP_LowerRight);
  Canvas.DrawScreenText(string(nPlayersTotal), OriginX, OriginY - 0.002 * HUDScale, DP_UpperLeft);
  
  Canvas.FontScaleX = Canvas.Default.FontScaleX;
  Canvas.FontScaleY = Canvas.Default.FontScaleY;
  }


// ============================================================================
// ShowCompass
//
// Displays the compass dots.
// ============================================================================

simulated function ShowCompass(Canvas Canvas) {

  local int iInventory;
  local int nPlayersReleasable;
  local float AngleDot;
  local float OffsetX;
  local float OffsetY;
  local float ScaleDot;
  local float TimeUpdateCompassDelta;
  local vector LocationOwner;
  local GameObjective Objective;
  local JBInventoryObjective InventoryObjective;
  
  TimeUpdateCompassDelta = Level.TimeSeconds - TimeUpdateCompass;
  TimeUpdateCompass = Level.TimeSeconds;
  
  if (PawnOwner != None)
    LocationOwner = PawnOwner.Location;
  else
    LocationOwner = PlayerOwner.Location;
  
  for (iInventory = 0; iInventory < ListInventoryObjective.Length; iInventory++) {
    InventoryObjective = ListInventoryObjective[iInventory];
    Objective = InventoryObjective.GetObjective();
    
    switch (Objective.DefenderTeamIndex) {
      case 0:  Canvas.DrawColor = RedColor;   OffsetX = -0.033;  OffsetY = 0.048;  break;
      case 1:  Canvas.DrawColor = BlueColor;  OffsetX =  0.033;  OffsetY = 0.048;  break;
      }

    nPlayersReleasable = InventoryObjective.CountPlayersReleasable(True);

    ScaleDot = 1.0;
    if (nPlayersReleasable > 0) {
      InventoryObjective.ScaleDot -= 0.5 * TimeUpdateCompassDelta * nPlayersReleasable;
      if (InventoryObjective.ScaleDot < 1.0)
        InventoryObjective.ScaleDot = (InventoryObjective.ScaleDot % 0.5) + 1.0;
      ScaleDot = InventoryObjective.ScaleDot;
      }
    
    AngleDot = ((rotator(Objective.Location - LocationOwner).Yaw - PlayerOwner.Rotation.Yaw) & 65535) * Pi / 32768;
    
    Canvas.Style = ERenderStyle.STY_Alpha;
    SetRelativePos(Canvas, OffsetX + 0.0305 * Sin(AngleDot),
                           OffsetY - 0.0405 * Cos(AngleDot), DP_UpperMiddle);
    Canvas.CurX -= 12 * Canvas.ClipX * HUDScale * ScaleDot / 1600;
    Canvas.CurY -= 12 * Canvas.ClipX * HUDScale * ScaleDot / 1600;
    Canvas.DrawTile(Material'InterfaceContent.Hud.SkinA',
      24 * Canvas.ClipX * HUDScale * ScaleDot / 1600,
      24 * Canvas.ClipX * HUDScale * ScaleDot / 1600, 838, 238, 144, 144);
    }
  }


// ============================================================================
// ShowTeamScorePassA
//
// Draws team status and compass.
// ============================================================================

simulated function ShowTeamScorePassA(Canvas Canvas) {

  local JBReplicationInfoGame InfoGame;

  Super.ShowTeamScorePassA(Canvas);

  InfoGame = JBReplicationInfoGame(Level.GRI);

  DrawSpriteWidget(Canvas, SpriteWidgetCompass[0]);
  DrawSpriteWidget(Canvas, SpriteWidgetCompass[1]);
  
  LTeamHud[0].OffsetX = -95;  RTeamHud[0].OffsetX = 95;
  LTeamHud[1].OffsetX = -95;  RTeamHud[1].OffsetX = 95;
  LTeamHud[2].OffsetX = -95;  RTeamHud[2].OffsetX = 95;
  
  TeamSymbols[0].TextureScale = 0.075;  TeamSymbols[1].TextureScale = 0.075;
  TeamSymbols[0].OffsetX      = -600;   TeamSymbols[1].OffsetX      = 600;
  TeamSymbols[0].OffsetY      =   90;   TeamSymbols[1].OffsetY      =  90;
  ScoreTeam  [0].OffsetX      = -270;   ScoreTeam  [1].OffsetX      = 180;
  ScoreTeam  [0].OffsetY      =   75;   ScoreTeam  [1].OffsetY      =  75;
  
  SetRelativePos(Canvas, -0.033, 0.051, DP_UpperMiddle);
  ShowTeamStatus(Canvas, JBReplicationInfoTeam(InfoGame.Teams[0]));

  SetRelativePos(Canvas, 0.035, 0.051, DP_UpperMiddle);
  ShowTeamStatus(Canvas, JBReplicationInfoTeam(InfoGame.Teams[1]));

  ShowCompass(Canvas);
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  SpriteWidgetCompass[0] = (WidgetTexture=Material'InterfaceContent.Hud.SkinA',TextureCoords=(X2=0,Y1=880,X1=142,Y2=1023),TextureScale=0.3,DrawPivot=DP_UpperRight,PosX=0.5,PosY=0.0,OffsetX=-2,OffsetY=5,ScaleMode=SM_Right,Scale=1.0,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255));
  SpriteWidgetCompass[1] = (WidgetTexture=Material'InterfaceContent.Hud.SkinA',TextureCoords=(X2=0,Y1=880,X1=142,Y2=1023),TextureScale=0.3,DrawPivot=DP_UpperLeft,PosX=0.5,PosY=0.0,OffsetX=2,OffsetY=5,ScaleMode=SM_Right,Scale=1.0,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255));

  ScoreBg[0] = (TextureCoords=(X2=0,Y1=0,X1=0,Y2=0));
  ScoreBg[1] = (TextureCoords=(X2=0,Y1=0,X1=0,Y2=0));
  ScoreBg[2] = (TextureCoords=(X2=0,Y1=0,X1=0,Y2=0));
  ScoreBg[3] = (TextureCoords=(X2=0,Y1=0,X1=0,Y2=0));
  }
