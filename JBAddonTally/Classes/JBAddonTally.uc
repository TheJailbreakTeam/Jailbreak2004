// ============================================================================
// JBAddonTally
// Copyright 2006 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBAddonTally.uc,v 1.7 2006-07-15 20:22:56 mychaeel Exp $
//
// When players are in jail, displays a jail fight score tally.
// ============================================================================


class JBAddonTally extends JBAddon
  cacheexempt;


// ============================================================================
// Replication
// ============================================================================

replication
{
  reliable if (Role == ROLE_Authority)
    nEntries, Entries, Players;
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
};


// ============================================================================
// Properties
// ============================================================================

var() const editconst string Build;


// ============================================================================
// Variables
// ============================================================================

var PlayerController PlayerControllerLocal;
var JBTagPlayer TagPlayerLocal;

var int nEntries;                 // current number of entries
var TEntry  Entries[32];          // tally entries
var TPlayer Players[32];          // non-movable player data

var HudBase.SpriteWidget SpriteWidgetEntry;
var HudBase.SpriteWidget SpriteWidgetBackground;


// ============================================================================
// PostBeginPlay
//
// Creates and registers an instance of the game rule modifier class.
// ============================================================================

event PostBeginPlay()
{
  local JBGameRulesTally GameRulesTally;

  GameRulesTally = Spawn(Class'JBGameRulesTally');
  GameRulesTally.Addon = Self;
  
  Level.Game.AddGameModifier(GameRulesTally);
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

  while (iEntryKiller > 0 &&
         Entries[iEntryKiller - 1].nKills - Entries[iEntryKiller - 1].nDeaths <
         Entries[iEntryKiller    ].nKills - Entries[iEntryKiller    ].nDeaths)
    SwapEntries(iEntryKiller, --iEntryKiller);

  iEntryVictim = FindOrCreateEntryFor(TagPlayerVictim);
  Entries[iEntryVictim].nDeaths += 1;

  while (iEntryVictim < nEntries - 1 &&
         Entries[iEntryVictim + 1].nKills - Entries[iEntryVictim + 1].nDeaths >
         Entries[iEntryVictim    ].nKills - Entries[iEntryVictim    ].nDeaths)
    SwapEntries(iEntryVictim, ++iEntryVictim);

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
  Players[iEntry].TagPlayer = TagPlayer;
  Entries[iEntry].iPlayer   = iEntry;

  while (iEntry > 0 &&
         Entries[iEntry - 1].nKills - Entries[iEntry - 1].nDeaths < 0)
    SwapEntries(iEntry, --iEntry);

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
  local int iEntry;
  local int iTeam;
  local String ScoreDelta;
  local String ScoreEfficiency;
  local Vector LocationCurrentEntry;
  local Vector LocationCurrentText;
  local Vector LocationCurrentBackground;
  local Vector SizeEntry;
  local Vector SizeBackground;
  local Vector SizeScoreDelta;
  local Vector SizeScoreEfficiency;
  local TEntry EntryCurrent;
  local TPlayer PlayerCurrent;
  local PlayerReplicationInfo PlayerReplicationInfo;

  if (TagPlayerLocal == None)
    TagPlayerLocal = Class'JBTagPlayer'.Static.FindFor(PlayerControllerLocal.PlayerReplicationInfo);

  if (TagPlayerLocal.IsInJail()) {
    Canvas.Style = ERenderStyle.STY_Alpha;
    Canvas.Font = PlayerControllerLocal.myHUD.ScoreBoard.GetSmallFontFor(Canvas.ClipX, 0);

    Canvas.TextSize(" +00",  SizeScoreDelta     .X, SizeScoreDelta     .Y);
    Canvas.TextSize(" 100%", SizeScoreEfficiency.X, SizeScoreEfficiency.Y);
  
    SizeBackground.X = SpriteWidgetBackground.TextureScale * (SpriteWidgetBackground.TextureCoords.X2 - SpriteWidgetBackground.TextureCoords.X1) * (Canvas.SizeX / 640);
    SizeBackground.Y = SizeScoreDelta.Y * 1.2;
  
    SizeEntry.Y = SizeScoreDelta.Y * 1.4;
  
    LocationCurrentEntry.X = SpriteWidgetEntry.PosX * Canvas.SizeX;
    LocationCurrentEntry.Y = SpriteWidgetEntry.PosY * Canvas.SizeY;
  
    LocationCurrentBackground.X = SpriteWidgetBackground.PosX * Canvas.SizeX;
    LocationCurrentBackground.Y = SpriteWidgetBackground.PosY * Canvas.SizeY;
  
    iTeam = PlayerControllerLocal.PlayerReplicationInfo.Team.TeamIndex;
  
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

      Canvas.DrawColor = SpriteWidgetBackground.Tints[iTeam];
  
      Canvas.SetPos(
        LocationCurrentBackground.X - SizeBackground.X,
        LocationCurrentBackground.Y);
  
      Canvas.DrawTile(
        SpriteWidgetBackground.WidgetTexture,
        SizeBackground.X,
        SizeBackground.Y,
        SpriteWidgetBackground.TextureCoords.X1,
        SpriteWidgetBackground.TextureCoords.Y1,
        SpriteWidgetBackground.TextureCoords.X2 - SpriteWidgetBackground.TextureCoords.X1,
        SpriteWidgetBackground.TextureCoords.Y2 - SpriteWidgetBackground.TextureCoords.Y2);
  
      Canvas.DrawColor = SpriteWidgetEntry.Tints[iTeam];

           if (EntryCurrent.nDeaths < EntryCurrent.nKills) ScoreDelta = "+" $ (EntryCurrent.nKills  - EntryCurrent.nDeaths);
      else if (EntryCurrent.nDeaths > EntryCurrent.nKills) ScoreDelta = "-" $ (EntryCurrent.nDeaths - EntryCurrent.nKills);
      else                                                 ScoreDelta = "0";

      ScoreEfficiency = (EntryCurrent.nKills * 100 / (EntryCurrent.nKills + EntryCurrent.nDeaths)) $ "%";

      LocationCurrentText = LocationCurrentEntry;      DrawTextRightAligned(Canvas, ScoreEfficiency,    LocationCurrentText.X, LocationCurrentText.Y);
      LocationCurrentText.X -= SizeScoreEfficiency.X;  DrawTextRightAligned(Canvas, ScoreDelta,         LocationCurrentText.X, LocationCurrentText.Y);
      LocationCurrentText.X -= SizeScoreDelta     .X;  DrawTextRightAligned(Canvas, PlayerCurrent.Name, LocationCurrentText.X, LocationCurrentText.Y);
  
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
// state Startup
//
// Waits for a tick to ensure that the local player controller has been
// spawned if any is spawned at all, then registers this actor as an overlay.
// ============================================================================

auto simulated state Startup
{
  Begin:
    Sleep(0.0001);
    
    PlayerControllerLocal = Level.GetLocalPlayerController();
    if (PlayerControllerLocal != None)
      JBInterfaceHud(PlayerControllerLocal.myHud).RegisterOverlay(Self);

} // state Startup


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  Build                  = "%%%%-%%-%% %%:%%"

  FriendlyName           = "Jail Fight Tally"
  Description            = "Maintains and displays a score tally for jail fights."

  SpriteWidgetEntry      = (PosX=0.970,PosY=0.105,Tints[0]=(R=255,G=255,B=255,A=192),Tints[1]=(R=255,G=255,B=255,A=192));
  SpriteWidgetBackground = (PosX=1.000,PosY=0.100,Tints[0]=(R=000,G=000,B=000,A=255),Tints[1]=(R=000,G=000,B=000,A=255),WidgetTexture=Texture'HudContent.Generic.HUD',TextureCoords=(X1=168,Y1=211,X2=334,Y2=255),TextureScale=0.53)

  RemoteRole             = ROLE_SimulatedProxy
  bAlwaysRelevant        = True
  bIsOverlay             = False  // buggy in SP2
}