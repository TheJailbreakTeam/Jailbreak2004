// ============================================================================
// JBAddonRadar
// Copyright 2004 by will
// $Id: JBAddonRadar.uc,v 1.2 2004-05-30 20:02:38 tarquin Exp $
//
// HUD radar map add-on for Jailbreak
// ============================================================================


Class JBAddonRadar extends JBAddon;


// ============================================================================
// Imports
// ============================================================================

#exec TEXTURE IMPORT NAME=ReleaseDot FILE=Textures\dot.tga MIPS=OFF FLAGS=2 LODSET=5 ALPHA=1
#exec TEXTURE IMPORT NAME=PlayerDot FILE=Textures\player.tga MIPS=OFF FLAGS=2 LODSET=5 ALPHA=1

// ============================================================================
// Variables
// ============================================================================

Var() const editconst string Build;
Var JBPanorama JBP;
Var Bool bDrawRadar;
Var Float XPos,YPos,Scale,MapScale,FadeTime;
Var Byte UseAlpha;

Simulated Function Tick(Float TimeDelta)
{
  If (Level.GetLocalPlayerController() != None)
    {
    Self.InitAddon();
    JBAddonRadarInteraction(Level.GetLocalPlayerController().Player.InteractionMaster.AddInteraction("JBAddonRadar.JBAddonRadarInteraction", Level.GetLocalPlayerController().Player)).Radar = Self;
    Disable('Tick');
    }
}

Simulated Function RenderOverlays(Canvas Canvas)
{
  If (JBP == None)
    ForEach AllActors(Class'JBPanorama', JBP)
      Break;

  If (Level.GetLocalPlayerController().Pawn == None)
    Return;

  If (!bDrawRadar)
    {
    If (UseAlpha > 0)
      UseAlpha -= 10;
    If (UseAlpha <= 0)
      Return;
    }
  Else
    {
    If (UseAlpha < 220)
      UseAlpha += 20;
    If (UseAlpha >= 220)
      UseAlpha = 220;
    }

  DrawMap(Canvas);
  DrawSwitch(Canvas);
  DrawMe(Canvas);
}

Simulated Function DrawMap(Canvas Canvas)
{
  Scale = 256 / JBP.TexturePanorama.USize * Canvas.ClipX / 640;
  Canvas.SetPos(XPos * Canvas.ClipX, YPos * Canvas.ClipY);
  Canvas.SetDrawColor(200, 200, 200, UseAlpha);
  Canvas.DrawIcon(JBP.TexturePanorama, Scale * MapScale);
}

Simulated Function DrawMe(Canvas Canvas)
{
  Local Vector V;
  //Local FinalBlend PlayerIcon;

  If (Level.GetLocalPlayerController().Pawn != None)
    {
    V = GetMapPosition(Canvas, Level.GetLocalPlayerController().Pawn.Location);

    //PlayerIcon = FinalBlend'ONSInterface-TX.CurrentPlayerIconFinal';

    //TexRotator(PlayerIcon.Material).Rotation.Yaw = 0 - Level.GetLocalPlayerController().Pawn.Rotation.Yaw - 16384;
    Canvas.SetPos(V.X-8, V.Y-8);
    Canvas.SetDrawColor(255, 255, 32, UseAlpha);
    //Canvas.DrawTile(PlayerIcon, 16 * Scale, 16 * Scale, 0, 0, 64, 64);
    Canvas.DrawIcon(Texture'PlayerDot', 1);
    }
}

Simulated Function DrawSwitch(Canvas Canvas)
{
  Local JBTagObjective G;
  Local Vector V;

  ForEach DynamicActors(Class'JBTagObjective', G)
    {
    V = GetMapPosition(Canvas, G.GetObjective().Location);
    Canvas.SetPos(V.X-4, V.Y-4);
    If (G.GetObjective().DefenderTeamIndex == 0)
      Canvas.SetDrawColor(255, 0, 0, UseAlpha);
    If (G.GetObjective().DefenderTeamIndex == 1)
      Canvas.SetDrawColor(0, 0, 255, UseAlpha);
    Canvas.DrawIcon(texture'ReleaseDot', 1);
    }
}

Simulated Function Vector GetMapPosition(Canvas Canvas, Vector V)
{
  Local Vector Result, MyMap, SBMap;
  Local Float X, Y;

  MyMap.X = XPos * Canvas.ClipX;
  MyMap.Y = YPos * Canvas.ClipY;
  SBMap.X = (Canvas.ClipX - Scale*JBP.TexturePanorama.USize) / 2;
  SBMap.Y = Canvas.ClipY - Scale*JBP.TexturePanorama.VSize + Scale*JBP.TexturePanorama.USize / 8;

  Result = JBP.CalcLocation(Canvas, V);

  X = (Result.X - SBMap.X)/(Scale * JBP.TexturePanorama.USize);
  Y = (Result.Y - SBMap.Y)/(Scale * JBP.TexturePanorama.VSize);

  Result.X = (Canvas.ClipX * XPos) + (X * Scale * MapScale * JBP.TexturePanorama.USize);
  Result.Y = (Canvas.ClipY * YPos) + (Y * Scale * MapScale * JBP.TexturePanorama.VSize);

  Return Result;
}

// ============================================================================
// Default Properties
// ============================================================================

DefaultProperties
{
  RemoteRole=ROLE_SimulatedProxy
  bAlwaysRelevant=True

  FriendlyName="Radar"
  Build="%%%%-%%-%% %%:%%"
  Description="Adds a radar to the upper-right of your screen.||You can toggle its visibility with the key used to toggle the Onslaught radar (default is F12)."
  bIsOverlay=True
  bDrawRadar=True

  XPos=0.675
  YPos=0.05
  MapScale=0.75
  FadeTime=0.75
}
