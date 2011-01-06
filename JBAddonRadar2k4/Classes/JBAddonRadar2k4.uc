/******************************************************************************
JBAddonRadar2k4

Creation date: 2010-12-26 18:47
Last change: $Id: JBAddonRadar2k4.uc,v 1.1 2011-01-03 12:17:30 wormbo Exp $
Copyright © 2010, Wormbo

Draws an Onslaught-style radar map on the HUD.
******************************************************************************/

class JBAddonRadar2k4 extends JBAddon config cacheexempt;


//=============================================================================
// Imports
//=============================================================================

#exec obj load file="..\Textures\ONSInterface-TX.utx"

// imported again for compatibility with JB2004b and earlier
#exec texture import file=..\Jailbreak\Textures\PadlockMapIcon.tga dxt=5 mips=on alpha=on lodset=LODSET_Interface
#exec texture import file=..\Jailbreak\Textures\DeathIcon.tga dxt=5 mips=on alpha=on lodset=LODSET_Interface



//=============================================================================
// Variables
//=============================================================================

var() const editconst string Build;
var JBPanorama Panorama;
var bool bMapDisabled;
var Material BorderMat;
var float ColorPercent;
var JBGameReplicationInfo JBGRI;
var FinalBlend PlayerIcon;
var JBInteractionRadar RadarInteraction;
var PlayerController LocalPlayer;
var JBTagPlayer LocalTagPlayer;


/**
Ensure the Panorama actor, the JBGRI and the interaction for capturing the
ToggleRadarMap command are registered. Update the color pulse percentage.
*/
simulated function Tick(float deltaTime)
{
	if (Panorama == None) {
		foreach DynamicActors(class'JBPanorama', Panorama) {
			break;
		}
	}

	if (RadarInteraction == None && Level.NetMode != NM_DedicatedServer) {
		LocalPlayer = Level.GetLocalPlayerController();
		if (LocalPlayer != None) {
			RadarInteraction = JBInteractionRadar(LocalPlayer.Player.InteractionMaster.AddInteraction(string(class'JBInteractionRadar'), LocalPlayer.Player));
			RadarInteraction.RadarAddon = Self;
		}
	}

	if (JBGRI == None)
		JBGRI = JBGameReplicationInfo(Level.GRI);

	ColorPercent = 0.5f + Cos(Level.TimeSeconds * 2 * Pi) * 0.5f; // 1 cycle per second
}


/**
Positions and draws the HUD minimap, but only if the map has a panorama setup
and the player didn't turn it off.
*/
simulated function RenderOverlays(Canvas C)
{
	local float RadarWidth, CenterRadarPosX, CenterRadarPosY;

	if (LocalTagPlayer == None)
		LocalTagPlayer = class'JBTagPlayer'.static.FindFor(LocalPlayer.PlayerReplicationInfo);

	if (JBGRI != None && Panorama != None && !bMapDisabled && !JBGRI.bIsExecuting && (LocalTagPlayer == None || !LocalTagPlayer.IsInArena() && !LocaLTagPlayer.IsInJail())) {
		RadarWidth = 0.5 * class'ONSHUDOnslaught'.default.RadarScale * C.Viewport.Actor.MyHud.HUDScale * C.ClipX;
		CenterRadarPosX = (class'ONSHUDOnslaught'.default.RadarPosX * C.ClipX) - RadarWidth;
		CenterRadarPosY = (class'ONSHUDOnslaught'.default.RadarPosY * C.ClipY) + RadarWidth;
		DrawRadarMap(C, CenterRadarPosX, CenterRadarPosY, RadarWidth);
	}
}


/**
Wrapper for JBPanorama.CalcLocation() that converts
scoreboard minimap coordinates to HUD radar map coordinates.
*/
simulated function vector CalcLocation(Canvas C, vector WorldLocation, float CenterPosX, float CenterPosY, float RadarWidth)
{
	local vector ScreenLocation, PanoramaOffset;

	// Panorama's calculated location
	ScreenLocation = Panorama.CalcLocation(C, WorldLocation);

	if (ScreenLocation == vect(0,0,0))
		return vect(0,0,0);

	// undo offset and scaling operations
	PanoramaOffset.X = C.ClipX * 0.5;
	PanoramaOffset.Y = C.ClipY - C.ClipX * 0.15;
	ScreenLocation -= PanoramaOffset;
	ScreenLocation /= 0.2 * C.ClipX;

	ScreenLocation *= RadarWidth;
	ScreenLocation.X = FClamp(ScreenLocation.X, -0.95 * RadarWidth, 0.95 * RadarWidth) + CenterPosX;
	ScreenLocation.Y = FClamp(ScreenLocation.Y, -0.95 * RadarWidth, 0.95 * RadarWidth) + CenterPosY;

	return ScreenLocation;
}


/**
Draws the background panorama image.
*/
simulated static function DrawMapImage(Canvas C, Material Image, float MapX, float MapY, float RadarWidth, float Alpha)
{
	local float MapUL, MapVL;
	local byte  SavedAlpha;

	if ( Image == None || C == None )
		return;

	MapUL = Image.MaterialUSize();
	MapVL = Image.MaterialVSize();
	SavedAlpha = C.DrawColor.A;
	C.DrawColor = class'HUD'.default.WhiteColor;
	C.DrawColor.A = Alpha;

	if (MapUL > MapVL) {
		C.SetPos(MapX - RadarWidth, MapY - RadarWidth * MapVL / MapUL);
		C.DrawTile(Image, 2 * RadarWidth, 2 * RadarWidth * MapVL / MapUL, 0, 0, MapUL, MapVL);
	}
	else {
		C.SetPos(MapX - RadarWidth * MapUL / MapVL, MapY - RadarWidth);
		C.DrawTile(Image, 2 * RadarWidth * MapUL / MapVL, 2 * RadarWidth, 0, 0, MapUL, MapVL);
	}

	C.DrawColor.A = SavedAlpha;
}


/**
Draws a lock icon for the specified objective.
*/
simulated function DrawObjective(Canvas C, JBTagObjective ObjectiveTag, float IconScaling, float CenterPosX, float CenterPosY, float RadarWidth)
{
	local HudCTeamDeathMatch HudCTeamDeathMatch;
	local GameObjective Objective;
	local vector LocationObjective;
	local float LockIconSize;

	if (Panorama == None || ObjectiveTag == None)
		return;

	HudCTeamDeathMatch = HudCTeamDeathMatch(C.Viewport.Actor.MyHud);
	if (HudCTeamDeathMatch != None) {
		Objective = ObjectiveTag.GetObjective();
		if (Objective == None || Objective.DefenderTeamIndex >= ArrayCount(HudCTeamDeathMatch.TeamSymbols))
			return; // neutral or no objective, don't draw

		LockIconSize = IconScaling * C.ClipX * HudCTeamDeathMatch.HUDScale * 0.015;

		LocationObjective = CalcLocation(C, Objective.Location, CenterPosX, CenterPosY, RadarWidth);

		C.DrawColor = HudCTeamDeathMatch.TeamSymbols[Abs(int(Class'Jailbreak'.Default.bReverseSwitchColors) - Objective.DefenderTeamIndex)].Tints[HudCTeamDeathMatch.TeamIndex];
		C.DrawColor.A = 255;
		if (ObjectiveTag.CountPlayersReleasable() > 0)
			C.DrawColor = C.DrawColor * ColorPercent + (C.DrawColor * 0.5) * (1.0 - ColorPercent); // pulse icon if relevant

		C.SetPos(LocationObjective.X - LockIconSize * 0.5, LocationObjective.Y - LockIconSize * 0.5);
		C.DrawTile(Material'PadlockMapIcon', LockIconSize, LockIconSize, 0, 0, 32, 32);
	}
}


/**
Draws a dot icon for the specified player.
*/
simulated function DrawPlayer(Canvas C, JBTagPlayer PlayerTag, float IconScaling, float CenterPosX, float CenterPosY, float RadarWidth)
{
	local HudCTeamDeathMatch HudCTeamDeathMatch;
	local vector LocationPlayer;
	local float DotSize;
	local bool bIsLlama;

	if (Panorama == None || PlayerTag == None || !PlayerTag.IsFree())
		return;

	HudCTeamDeathMatch = HudCTeamDeathMatch(C.Viewport.Actor.MyHud);
	if (HudCTeamDeathMatch != None) {
		bIsLlama = class'JBAddonLlama'.static.IsLlama(PlayerTag);
		if (!LocalPlayer.PlayerReplicationInfo.bOnlySpectator && LocalPlayer.PlayerReplicationInfo.Team != PlayerTag.GetTeam() && !bIsLlama)
			return; // non-llama opponent

		DotSize = IconScaling * C.ClipX * HudCTeamDeathMatch.HUDScale * 0.005;

		LocationPlayer = CalcLocation(C, PlayerTag.GetLocationPawn(), CenterPosX, CenterPosY, RadarWidth);

		if (bIsLlama && PlayerTag.GetHealth(true) > 0)
			DotSize *= 2;
		C.SetPos(LocationPlayer.X - DotSize * 0.5, LocationPlayer.Y - DotSize * 0.5);
		if (PlayerTag.GetHealth(true) > 0) {
			C.DrawColor = HudCTeamDeathMatch.TeamSymbols[PlayerTag.GetTeam().TeamIndex].Tints[HudCTeamDeathMatch.TeamIndex];
			C.DrawColor.A = 255;
			C.DrawTile(
				class'JBInterfaceScores'.default.SpriteWidgetPlayer.WidgetTexture,
				DotSize,
				DotSize,
				class'JBInterfaceScores'.default.SpriteWidgetPlayer.TextureCoords.X1,
				class'JBInterfaceScores'.default.SpriteWidgetPlayer.TextureCoords.Y1,
				class'JBInterfaceScores'.default.SpriteWidgetPlayer.TextureCoords.X2 - class'JBInterfaceScores'.default.SpriteWidgetPlayer.TextureCoords.X1,
				class'JBInterfaceScores'.default.SpriteWidgetPlayer.TextureCoords.Y2 - class'JBInterfaceScores'.default.SpriteWidgetPlayer.TextureCoords.Y1);
			if (bIsLlama) {
				C.SetDrawColor(0,0,0);
				C.SetPos(LocationPlayer.X - DotSize * 0.5, LocationPlayer.Y - DotSize * 0.5);
				C.DrawTile(Texture'LLama', DotSize, DotSize, 0, 0, Texture'LLama'.USize, Texture'LLama'.VSize);
			}
		}
		else { // death icon
			C.SetDrawColor(0,0,0);
			C.DrawTile(
				class'JBInterfaceScores'.default.SpriteWidgetPlayer.WidgetTexture,
				DotSize,
				DotSize,
				class'JBInterfaceScores'.default.SpriteWidgetPlayer.TextureCoords.X1,
				class'JBInterfaceScores'.default.SpriteWidgetPlayer.TextureCoords.Y1,
				class'JBInterfaceScores'.default.SpriteWidgetPlayer.TextureCoords.X2 - class'JBInterfaceScores'.default.SpriteWidgetPlayer.TextureCoords.X1,
				class'JBInterfaceScores'.default.SpriteWidgetPlayer.TextureCoords.Y2 - class'JBInterfaceScores'.default.SpriteWidgetPlayer.TextureCoords.Y1);
			C.DrawColor = HudCTeamDeathMatch.TeamSymbols[PlayerTag.GetTeam().TeamIndex].Tints[HudCTeamDeathMatch.TeamIndex];
			C.DrawColor.A = 255;
			C.SetPos(LocationPlayer.X - DotSize * 0.5, LocationPlayer.Y - DotSize * 0.5);
			C.DrawTile(Texture'DeathIcon', DotSize, DotSize, 0, 0, 32, 32);
		}
	}
}


/**
Draws the radar map, consisting of a black background, the panorama image,
switch and local player locationa and a border.
*/
simulated function DrawRadarMap(Canvas C, float CenterPosX, float CenterPosY, float RadarWidth)
{
	local float PlayerIconSize;
	local vector HUDLocation, DirectionLocation;
	local Actor A;
	local plane SavedModulation;
	local JBTagObjective ObjectiveTag;
	local JBTagPlayer PlayerTag;

	SavedModulation = C.ColorModulate;

	C.ColorModulate.X = 1;
	C.ColorModulate.Y = 1;
	C.ColorModulate.Z = 1;
	C.ColorModulate.W = 1;

	// Make sure that the canvas style is alpha
	C.Style = ERenderStyle.STY_Alpha;

	C.SetDrawColor(0,0,0,0.75*class'ONSHUDOnslaught'.default.RadarTrans);
	C.SetPos(CenterPosX - RadarWidth, CenterPosY - RadarWidth);
	C.DrawTile(Material'BlackTexture',
		RadarWidth * 2.0,
		RadarWidth * 2.0,
		0,
		0,
		8,
		8);


	DrawMapImage(C, Panorama.TexturePanorama, CenterPosX, CenterPosY, RadarWidth, class'ONSHUDOnslaught'.default.RadarTrans);

	for (ObjectiveTag = JBGRI.firstTagObjective; ObjectiveTag != None; ObjectiveTag = ObjectiveTag.nextTag) {
		DrawObjective(C, ObjectiveTag, class'ONSHUDOnslaught'.default.IconScale, CenterPosX, CenterPosY, RadarWidth);
	}

	for (PlayerTag = JBGRI.firstTagPlayer; PlayerTag != None; PlayerTag = PlayerTag.nextTag) {
		DrawPlayer(C, PlayerTag, class'ONSHUDOnslaught'.default.IconScale, CenterPosX, CenterPosY, RadarWidth);
	}

	// Draw PlayerIcon
	if (C.Viewport.Actor.MyHud.PawnOwner != None)
		A = C.Viewport.Actor.MyHud.PawnOwner;
	else if (C.Viewport.Actor.MyHud.PlayerOwner.IsInState('Spectating'))
		A = C.Viewport.Actor.MyHud.PlayerOwner;
	else
		A = C.Viewport.Actor.MyHud.PlayerOwner.Pawn;

	if (A != None) {
		PlayerIconSize = class'ONSHUDOnslaught'.default.IconScale * C.ClipX * C.Viewport.Actor.MyHud.HUDScale * 0.0125;
		HUDLocation = CalcLocation(C, A.Location, CenterPosX, CenterPosY, RadarWidth);
		DirectionLocation = CalcLocation(C, A.Location + 100.0 * vector(A.Rotation), CenterPosX, CenterPosY, RadarWidth);
		DirectionLocation -= HUDLocation;
		TexRotator(PlayerIcon.Material).Rotation.Yaw = -16384 - 32768 * Atan(DirectionLocation.Y, DirectionLocation.X) / Pi;
		C.SetPos(HUDLocation.X - PlayerIconSize * 0.5, HUDLocation.Y - PlayerIconSize * 0.5);
		C.SetDrawColor(40,255,40);
		C.DrawTile(PlayerIcon, PlayerIconSize, PlayerIconSize, 0, 0, PlayerIcon.MaterialUSize(), PlayerIcon.MaterialVSize());
	}

	// Draw Border
	C.SetDrawColor(200,200,200);
	C.SetPos(CenterPosX - RadarWidth, CenterPosY - RadarWidth);
	C.DrawTile(BorderMat,
		RadarWidth * 2.0,
		RadarWidth * 2.0,
		0,
		0,
		256,
		256);

	C.ColorModulate = SavedModulation;
}


//=============================================================================
// Default values
//=============================================================================

defaultproperties
{
	FriendlyName = "Radar"
	Description = "Adds the minimap from the scoreboard to the HUD as Onslaught-style radar map."
	Build = "%%%%-%%-%% %%:%%"
	bAddToServerPackages = True
	bIsOverlay = True
	BorderMat = Material'ONSInterface-TX.MapBorderTex'
	PlayerIcon = FinalBlend'CurrentPlayerIconFinal'
}

