// ============================================================================
// JBAddonJailFightTally
// Copyright 2006 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBAddonTally.uc,v 1.13 2007-08-29 23:37:58 mychaeel Exp $
//
// Formerly known as JBAddonTally, renamed to prevent compatibility issues.
// When players are in jail, displays a jail fight score tally.
// ============================================================================


class JBAddonJailFightTally extends JBAddon
  cacheexempt;


// ============================================================================
// Replication
// ============================================================================

replication
{
  reliable if (Role == ROLE_Authority)
    nEntries, Entries, Players, bGameEnded;
}


// ============================================================================
// Types
// ============================================================================

struct TPlayer
{
  var string Name;                // cached player name
  var JBTagPlayer TagPlayer;      // owner of this entry
};


struct TEntry
{
  var byte iPlayer;               // reference into players array

  var int nKills;                 // number of kills  in jail fights
  var int nDeaths;                // number of deaths in jail fights
  var float LastKillTime;         // when the player last killed someone
  var float LastDeathTime;        // when the player was last killed
};


// ============================================================================
// Properties
// ============================================================================

var() const editconst string Build;


// ============================================================================
// Variables
// ============================================================================

var JBTagPlayer TagPlayerLocal;

var int nEntries;                 // current number of entries
var TEntry  Entries[32];          // tally entries
var TPlayer Players[32];          // non-movable player data

var float nEntriesFade;           // fade-in ratio of entire tally
var float TimeFade;               // last fade-in update

var HudBase.SpriteWidget SpriteWidgetEntry;
var HudBase.SpriteWidget SpriteWidgetBackground;

var bool bGameEnded;


// ============================================================================
// PostBeginPlay
//
// Creates and registers an instance of the game rule modifier class.
// ============================================================================

event PostBeginPlay()
{
  local JBGameRulesJailFightTally GameRulesTally;

  GameRulesTally = Spawn(class'JBGameRulesJailFightTally');
  GameRulesTally.Addon = Self;

  Level.Game.AddGameModifier(GameRulesTally);

  // Get notified when the game ends.
  Tag = 'EndGame';
}


// ============================================================================
// Trigger
//
// Called when the game ends.
// ============================================================================

event Trigger(Actor Other, Pawn EventInstigator)
{
  bGameEnded = True;
}


// ============================================================================
// AddToTally
//
// Adds a jail fight result to the score tally.
// ============================================================================

function AddToTally(JBTagPlayer TagPlayerKiller, JBTagPlayer TagPlayerVictim)
{
  local int iEntryKiller;
  local int iEntryVictim;

  iEntryKiller = FindOrCreateEntryFor(TagPlayerKiller);
  Entries[iEntryKiller].nKills += 1;
  Entries[iEntryKiller].LastKillTime = Level.TimeSeconds;

  while (iEntryKiller > 0 &&
         Entries[iEntryKiller - 1].nKills < Entries[iEntryKiller].nKills)
    SwapEntries(iEntryKiller, --iEntryKiller);

  iEntryVictim = FindOrCreateEntryFor(TagPlayerVictim);
  Entries[iEntryVictim].nDeaths += 1;
  Entries[iEntryVictim].LastDeathTime = Level.TimeSeconds;

  TouchEntry(iEntryKiller);
  TouchEntry(iEntryVictim);
}


// ============================================================================
// FindOrCreateEntryFor
//
// Returns the index of the score tally entry of the given player. If none
// exists, adds one to the list.
// ============================================================================

function int FindOrCreateEntryFor(JBTagPlayer TagPlayer)
{
  local int iEntry;

  for (iEntry = 0; iEntry < nEntries; ++iEntry)
    if (Players[Entries[iEntry].iPlayer].TagPlayer == TagPlayer)
      return iEntry;

  iEntry = nEntries++;

  if (nEntriesFade > 0.0 &&
      nEntriesFade == nEntries - 1)
    nEntriesFade = nEntries;

  Players[iEntry].TagPlayer = TagPlayer;
  Entries[iEntry].iPlayer   = iEntry;

  return iEntry;
}


// ============================================================================
// SwapEntries
//
// Swaps two entries in the score tally.
// ============================================================================

function SwapEntries(int iEntry1, int iEntry2)
{
  local TEntry EntryTemp;

  EntryTemp        = Entries[iEntry1];
  Entries[iEntry1] = Entries[iEntry2];
  Entries[iEntry2] = EntryTemp;
}


// ============================================================================
// TouchEntry
//
// Makes a dummy modification to an entry. Works around an engine bug which
// would otherwise not replicate that entry.
// ============================================================================

function TouchEntry(int iEntry)
{
  Entries[iEntry] = Entries[iEntry];
}


// ============================================================================
// RenderOverlays
//
// Displays the jail fight score tally when the local player is in jail.
// ============================================================================

simulated function RenderOverlays(Canvas Canvas)
{
  local float KillTime;
  local float DeathTime;
  local int iEntry;
  local int Offset;
  local String ScoreKills;
  local String ScoreEfficiency;
  local Vector LocationCurrentEntry;
  local Vector LocationCurrentText;
  local Vector LocationCurrentBackground;
  local Vector SizeEntry;
  local Vector SizeBackground;
  local Vector SizeScoreKills;
  local Vector SizeScoreEfficiency;
  local TEntry EntryCurrent;
  local TPlayer PlayerCurrent;
  local PlayerReplicationInfo PlayerReplicationInfo;

  if (PlayerControllerLocal == None)
    PlayerControllerLocal = Level.GetLocalPlayerController();

  if (TagPlayerLocal == None)
    TagPlayerLocal = Class'JBTagPlayer'.Static.FindFor(Level.GetLocalPlayerController().PlayerReplicationInfo);

  if (PlayerControllerLocal.myHUD.bHideHUD)
    return;

  if (((TagPlayerLocal != None && TagPlayerLocal.IsInJail()) || bGameEnded) && !JBGameReplicationInfo.bIsExecuting)
       nEntriesFade = FMin(nEntries, nEntriesFade + (Level.TimeSeconds - TimeFade) * 4.0);
  else nEntriesFade = FMax(0.0,      nEntriesFade - (Level.TimeSeconds - TimeFade) * 4.0);

  TimeFade = Level.TimeSeconds;

  if (nEntriesFade > 0.0) {
    Canvas.Style = ERenderStyle.STY_Alpha;
    Canvas.Font = PlayerControllerLocal.myHUD.ScoreBoard.GetSmallFontFor(Canvas.ClipX, 0);

    Canvas.TextSize(" 999",  SizeScoreKills     .X, SizeScoreKills     .Y);
    Canvas.TextSize(" 100%", SizeScoreEfficiency.X, SizeScoreEfficiency.Y);

    SizeBackground.X = SpriteWidgetBackground.TextureScale * (SpriteWidgetBackground.TextureCoords.X2 - SpriteWidgetBackground.TextureCoords.X1) * (Canvas.SizeX / 640);
    SizeBackground.Y = SizeScoreKills.Y * 1.2;

    SizeEntry.Y = SizeScoreKills.Y * 1.4;

    LocationCurrentEntry.X = SpriteWidgetEntry.PosX * Canvas.SizeX;
    LocationCurrentEntry.Y = SpriteWidgetEntry.PosY * Canvas.SizeY;

    LocationCurrentBackground.X = SpriteWidgetBackground.PosX * Canvas.SizeX;
    LocationCurrentBackground.Y = SpriteWidgetBackground.PosY * Canvas.SizeY;

    for (iEntry = 0; iEntry < nEntries; ++iEntry) {
      EntryCurrent  = Entries[iEntry];
      PlayerCurrent = Players[EntryCurrent.iPlayer];

      if (PlayerCurrent.TagPlayer != None) {
        PlayerReplicationInfo = PlayerCurrent.TagPlayer.GetPlayerReplicationInfo();
        if (PlayerReplicationInfo != None)
          PlayerCurrent.Name = PlayerReplicationInfo.PlayerName;
      }

      if (Players[EntryCurrent.iPlayer] != PlayerCurrent)
        Players[EntryCurrent.iPlayer] = PlayerCurrent;

      if (iEntry <= nEntriesFade - 1.0)
             Offset = 0;
        else Offset = Canvas.ClipX * 0.5 * (1.0 - FMax(0.0, nEntriesFade - iEntry));

      Canvas.DrawColor = SpriteWidgetBackground.Tints[0];

      Canvas.SetPos(
        LocationCurrentBackground.X - SizeBackground.X + Offset,
        LocationCurrentBackground.Y);

      Canvas.DrawTile(
        SpriteWidgetBackground.WidgetTexture,
        SizeBackground.X,
        SizeBackground.Y,
        SpriteWidgetBackground.TextureCoords.X1,
        SpriteWidgetBackground.TextureCoords.Y1,
        SpriteWidgetBackground.TextureCoords.X2 - SpriteWidgetBackground.TextureCoords.X1,
        SpriteWidgetBackground.TextureCoords.Y2 - SpriteWidgetBackground.TextureCoords.Y2);

      Canvas.DrawColor = SpriteWidgetEntry.Tints[0];

      // Applying a color change due to a recent kill and/or death
      if (Level.TimeSeconds - EntryCurrent.LastKillTime <= 2 || Level.TimeSeconds - EntryCurrent.LastDeathTime <= 2) {
        KillTime = Level.TimeSeconds - EntryCurrent.LastKillTime;
        DeathTime = Level.TimeSeconds - EntryCurrent.LastDeathTime;
        Canvas.DrawColor.R -= 192 * (1 - FClamp((KillTime - 1)/1, 0, 1));
        Canvas.DrawColor.G -= 192 * (1 - FClamp((DeathTime - 1)/1, 0, 1));
        Canvas.DrawColor.B -= 192 * (1 - FClamp((FMin(KillTime, DeathTime) - 1)/1, 0, 1));
        Canvas.DrawColor.A += 64  * (1 - FClamp((FMin(KillTime, DeathTime) - 1)/1, 0, 1));
        log(Canvas.DrawColor.A);
      }

      /*     if (EntryCurrent.nDeaths < EntryCurrent.nKills) ScoreDelta = "+" $ (EntryCurrent.nKills  - EntryCurrent.nDeaths);
      else if (EntryCurrent.nDeaths > EntryCurrent.nKills) ScoreDelta = "-" $ (EntryCurrent.nDeaths - EntryCurrent.nKills);
      else                                                 ScoreDelta = "0";*/

      ScoreKills = String(EntryCurrent.nKills);

      ScoreEfficiency = (EntryCurrent.nKills * 100 / (EntryCurrent.nKills + EntryCurrent.nDeaths)) $ "%";

      LocationCurrentText.X = LocationCurrentEntry.X + Offset;
      LocationCurrentText.Y = LocationCurrentEntry.Y;

                                                       DrawTextRightAligned(Canvas, ScoreEfficiency,    LocationCurrentText.X, LocationCurrentText.Y);
      LocationCurrentText.X -= SizeScoreEfficiency.X;  DrawTextRightAligned(Canvas, ScoreKills,         LocationCurrentText.X, LocationCurrentText.Y);
      LocationCurrentText.X -= SizeScoreKills     .X;  DrawTextRightAligned(Canvas, PlayerCurrent.Name, LocationCurrentText.X, LocationCurrentText.Y);

      LocationCurrentEntry     .Y += SizeEntry.Y;
      LocationCurrentBackground.Y += SizeEntry.Y;
    }
  }
}


// ============================================================================
// DrawTextRightAligned
//
// Draws right-aligned text at the given screen coordinates.
// ============================================================================

simulated function DrawTextRightAligned(Canvas Canvas, coerce String Text, float X, float Y)
{
  local Vector SizeText;

  Canvas.TextSize(Text, SizeText.X, SizeText.Y);
  Canvas.SetPos(X - SizeText.X, Y);
  Canvas.DrawTextClipped(Text);
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  Build="%%%%-%%-%% %%:%%"

  SpriteWidgetEntry      = (PosX=0.970000,PosY=0.105000,Tints[0]=(B=255,G=255,R=255,A=191))
  SpriteWidgetBackground = (WidgetTexture=Texture'HUDContent.Generic.HUD',TextureCoords=(X1=168,Y1=211,X2=334,Y2=255),TextureScale=0.530000,PosX=1.000000,PosY=0.100000,Tints[0]=(A=255))

  FriendlyName = "Jail Fight Tally"
  Description  = "Maintains and displays a score tally for jail fights."

  bAlwaysRelevant = True
  RemoteRole = ROLE_SimulatedProxy
  bIsOverlay = True
}
