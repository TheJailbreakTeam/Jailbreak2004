// ============================================================================
// JBInterfaceScores
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Scoreboard for Jailbreak.
// ============================================================================


class JBInterfaceScores extends ScoreBoardTeamDeathMatch
  notplaceable;


// ============================================================================
// Imports
// ============================================================================

#exec texture import file=Textures\SpriteWidgetScores.dds mips=on alpha=on lodset=LODSET_Interface


// ============================================================================
// Types
// ============================================================================

// ========================================================
// TEntryPosition
//
// Describes a logical position of an entry in one of the
// scoreboard tables.
// ========================================================

struct TEntryPosition
{
  var bool bIsSet;                      // position stored here is valid

  var int iTable;                       // table containing entry
  var int iRow;                         // row in table for entry
  var bool bOutside;                    // coming from or going to outside
};


// ========================================================
// TEntryLayout
//
// Describes the layout of an entry at a given logical
// position, realized for the current canvas metrics.
// ========================================================

struct TEntryLayout
{
  var vector Location;                  // pivot location of whole entry

  var vector OffsetName;                // offset of player name
  var vector OffsetInfoGame;            // offset of orders and player status
  var vector OffsetInfoTime;            // offset of playing time
  var vector OffsetInfoNet;             // offset of network ping
  var vector OffsetScore;               // offset of main score display
  var vector OffsetStats;               // offset of stats bars
  var vector OffsetLine;                // offset of start of location line

  var Color ColorMain;                  // color base for name, score and line
  var Color ColorInfo;                  // color for additional information
};


// ========================================================
// TEntry
//
// Describes a single entry in the scoreboard and stores
// all information required to render it on the screen.
// ========================================================

struct TEntry
{
  var string Name;                      // player name
  var string InfoGame;                  // orders and player status
  var string InfoTime;                  // playing time
  var string InfoNet;                   // network ping
  var vector Location;                  // last known location
  var int iTeam;                        // team index

  var bool bIsFree;                     // player is not jailed or in arena
  var bool bIsLocal;                    // player is local on this machine

  var int Score;                        // total score
  var int ScorePartialAttack;           // partial score for frags in attack
  var int ScorePartialDefense;          // partial score for frags in defense
  var int ScorePartialRelease;          // partial score for released teammates
  var int nDeaths;                      // number of deaths

  var int Health;                       // last acknowledged player health
  var float FadeDamage;                 // fadeout ratio for damage indicator
  var float FadeMain;                   // fadeout ratio for name and position

  var float AlphaPosition;              // alpha between previous and current
  var TEntryPosition PositionPrevious;  // previous position; movement origin
  var TEntryPosition PositionCurrent;   // current position; movement target
  var TEntryPosition PositionPending;   // next target position when finished

  var JBTagPlayer TagPlayer;            // reference to player game info
};


// ========================================================
// TTableLayout
//
// Describes the layout for a table, realized for the
// current canvas metrics.
// ========================================================

struct TTableLayout
{
  var vector Location;                  // pivot location of whole table

  var int HeightEntry;                  // height of single entry
  var int SpacingEntry;                 // spacing between two entries
  var int WidthLineMain;                // width of main line
  var int WidthLineStats;               // width of secondard stats lines
  var int WidthBarStats;                // width of stats bars

  var vector OffsetLineStats[3];        // offset of stats lines
  var vector OffsetMain;                // offset of main content area
  var vector OffsetScore;               // offset of score area
};


// ========================================================
// TTable
//
// Describes a table on the scoreboard that provides a
// docking area for an arbitrary number of entries.
// ========================================================

struct TTable
{
  var int nEntries;                     // number of entries in this table
  var float nEntriesDisplayed;          // displayed number of entries

  var int iTable;                       // index of this table; left or right
  var Color ColorMain;                  // main color base
  var Color ColorMainLocal;             // main color base for local player
  var Color ColorInfo;                  // additional color
  var Color ColorInfoLocal;             // additional color for local player

  var TTableLayout Layout;              // current layout for this table
};


// ========================================================
// SpriteWidget
//
// Slim version of the same structure in HudBase. Defines
// the location and size of a sprite in a larger texture.
// ========================================================

struct SpriteWidget
{
  var Material WidgetTexture;           // texture to retrieve sprite from
  var IntBox TextureCoords;             // texture coordinates of sprite
  var float TextureScale;               // sprite scale relative to screen size

  var float PosX;                       // relative horizontal pivot location
  var float PosY;                       // relative vertical pivot location
  var int OffsetX;                      // scaled horizontal displacement
  var int OffsetY;                      // scaled vertical displacement
  var Color Color;                      // color to draw sprite with
};


// ========================================================
// RotatedWidget
//
// Structure describing a SpriteWidget that is rotated
// before it is drawn. (Attempts to extend that from the
// SpriteWidget struct above crash the game.)
// ========================================================

struct RotatedWidget
{
  var Material WidgetTexture;           // texture to retrieve sprite from
  var IntBox TextureCoords;             // texture coordinates of sprite
  var float TextureScale;               // sprite scale relative to screen size

  var float PosX;                       // relative horizontal pivot location
  var float PosY;                       // relative vertical pivot location
  var int OffsetX;                      // scaled horizontal displacement
  var int OffsetY;                      // scaled vertical displacement
  var Color Color;                      // color to draw sprite with

  var int Angle;                        // rotation angle in Unreal units
  var int OffsetCenterX;                // offset of rotation center, relative
  var int OffsetCenterY;                // to unrotated upper-left corner
  var int OffsetRotatedX;               // horizontal and vertical displacement
  var int OffsetRotatedY;               // scaled and rotated with the sprite
};


// ============================================================================
// Localization
// ============================================================================

var localized string TextGameBotmatch;       // instant action game
var localized string TextGameOnline;         // online game
var localized string TextSkill[8];           // bot skill used in botmatch
var localized string TextLimitPrefix;        // text before game limits
var localized string TextLimitTime;          // time limit in minutes
var localized string TextLimitScore;         // score limit in captures
var localized string TextLimitSuffix;        // text after game limits

var localized string TextInfoWaiting;        // player is waiting before match
var localized string TextInfoDead;           // player is dead
var localized string TextInfoArena;          // player is fighting in arena
var localized string TextInfoJail;           // player is in jail
var localized string TextOrdersUndisclosed;  // player is on enemy team
var localized string TextOrdersAttack;       // human player attacking
var localized string TextOrdersDefense;      // human player defending
var localized string TextOrdersFreelance;    // human player is freelancing
var localized string TextScoresNone;         // no kills or releases
var localized string TextScoresAttack;       // partial attack score
var localized string TextScoresDefense;      // partial defense score
var localized string TextScoresRelease;      // partial release score

var localized string TextRelationElapsed;    // displaying elapsed time
var localized string TextRelationRemaining;  // displaying remaining time
var localized string TextRelationOvertime;   // displaying overtime


// ============================================================================
// Variables
// ============================================================================

var JBPanorama Panorama;                // minimap panorama actor

var private bool bIsMatchRunning;       // normal gameplay running
var private float TimeUpdateDisplay;    // time of last scoreboard update

var private string TextTitle;           // human-readable map title
var private string TextSubtitle;        // description of current game

var private TTable Table[2];            // tables for red and blue teams

var private int iEntryOwner;            // index of scoreboard owner's entry
var private int ScorePartialMax;        // maximum partial score in all entries
var private array<TEntry> ListEntry;    // player entries for both tables

var Color ColorLineStats[3];            // color of stats background lines
var Color ColorBarStats[3];             // color of stats bars themselves
var SpriteWidget SpriteWidgetIconStats[3];  // icons for stats bar headers

var SpriteWidget SpriteWidgetDot;       // dot used for location splines
var SpriteWidget SpriteWidgetGradient;  // background gradient for scoreboard
var SpriteWidget SpriteWidgetPlayer;    // icon for player on minimap
var SpriteWidget SpriteWidgetDamage;    // damage fadeout for player on minimap

var Color ColorFill[2];                 // color for widget fills by team
var Color ColorTint[2];                 // color for widget tints by team

var Color ColorMarkerTie;               // color for marker on tie
var Color ColorMarkerCaptured[2];       // color for marker when team captured

var SpriteWidget SpriteWidgetClockAnchorFill;    // visual clock anchor fill
var SpriteWidget SpriteWidgetClockAnchorTint;    // visual clock anchor tint
var SpriteWidget SpriteWidgetClockAnchorFrame;   // visual clock anchor frame
var SpriteWidget SpriteWidgetClockCircle;        // clock background circle
var SpriteWidget SpriteWidgetClockFillFirst;     // complete fill, first half
var RotatedWidget RotatedWidgetClockFillFirst;   // gradual fill, first half
var RotatedWidget RotatedWidgetClockFillSecond;  // gradual fill, second half
var RotatedWidget RotatedWidgetClockTick;        // clock section tick
var RotatedWidget RotatedWidgetClockMarker;      // capture marker arrow

var private Font FontObjectMain;        // loaded font for name and score
var private Font FontObjectInfo;        // loaded font for additional info

var private int iTexRotatorPool;        // index into TexRotator object pool
var private float TimeTexRotatorPool;   // time of last TexRotator pool reset
var private array<TexRotator> ListTexRotatorPool;  // TexRotator object pool


// ============================================================================
// UpdatePrecacheMaterials
//
// Adds the sprite widget material to the global list of precached materials.
// ============================================================================

simulated function UpdatePrecacheMaterials()
{
  Level.AddPrecacheMaterial(Material'SpriteWidgetScores');
  Super.UpdatePrecacheMaterials();
}


// ============================================================================
// Init
//
// Finds the JBPanorama actor if there is one, and takes certain localized
// strings from other classes.
// ============================================================================

simulated function Init()
{
  foreach DynamicActors(Class'JBPanorama', Panorama)
    break;

  TextOrdersAttack      = Class'SquadAI'.Default.AttackString;
  TextOrdersDefense     = Class'SquadAI'.Default.DefendString;
  TextOrdersFreelance   = Class'SquadAI'.Default.FreelanceString;

  Super.Init();
}


// ============================================================================
// UpdateScoreBoard
//
// Draws Jailbreak's scoreboard and tactics display on the screen.
// ============================================================================

simulated event UpdateScoreBoard(Canvas Canvas)
{
  local int iEntry;
  local int iTable;
  local int HeightTables;
  local float TimeDelta;

  UpdateGRI();

  if (TimeUpdateDisplay > 0.0)
    TimeDelta = Level.TimeSeconds - TimeUpdateDisplay;
  TimeUpdateDisplay = Level.TimeSeconds;

  FontObjectMain = GetSmallerFontFor(Canvas, 2);
  FontObjectInfo = GetSmallFontFor(Canvas.ClipX, 1);

  UpdateListEntry();

  for (iTable = 0; iTable < ArrayCount(Table); iTable++) {
    MoveTable(Table[iTable], TimeDelta);
    Table[iTable].Layout = CalcTableLayout(Canvas, Table[iTable]);
    HeightTables = Max(HeightTables, Canvas.ClipY - Table[iTable].Layout.Location.Y);
  }

  DrawGradient(Canvas, HeightTables);
  DrawHeader(Canvas);
  DrawClock(Canvas);

  bIsMatchRunning = GRI.bMatchHasBegun                  &&
                    !UnrealPlayer(Owner).bDisplayWinner &&
                    !UnrealPlayer(Owner).bDisplayLoser  &&
                    !JBGameReplicationInfo(GRI).bIsExecuting;

  if (bIsMatchRunning || !GRI.bMatchHasBegun)
    DrawPanorama(Canvas);

  for (iTable = 0; iTable < ArrayCount(Table); iTable++)
    DrawTable(Canvas, Table[iTable]);

  for (iEntry = 0; iEntry < ListEntry.Length; iEntry++) {
    MoveEntry(ListEntry[iEntry], TimeDelta);
    DrawEntry(Canvas, ListEntry[iEntry]);
  }

  DrawCrosshair(Canvas);
}


// ============================================================================
// DrawGradient
//
// Draws a scoreboard background gradient for the given table height.
// ============================================================================

simulated function DrawGradient(Canvas Canvas, int HeightTables)
{
  HeightTables = Max(HeightTables, Canvas.ClipX / 5);

  Canvas.DrawColor = SpriteWidgetGradient.Color;
  Canvas.SetPos(0, Canvas.ClipY - HeightTables * 2);
  Canvas.DrawTile(
    SpriteWidgetGradient.WidgetTexture,
    Canvas.ClipX,
    HeightTables * 2,
    SpriteWidgetGradient.TextureCoords.X1,
    SpriteWidgetGradient.TextureCoords.Y1,
    SpriteWidgetGradient.TextureCoords.X2 - SpriteWidgetGradient.TextureCoords.X1,
    SpriteWidgetGradient.TextureCoords.Y2 - SpriteWidgetGradient.TextureCoords.Y1);
}


// ============================================================================
// DrawHeader
//
// Draws the scoreboard header showing general map information.
// ============================================================================

simulated function DrawHeader(Canvas Canvas)
{
  if (TextTitle == "")
    TextTitle = GetGameTitle(Level);

  Canvas.Font = GetSmallerFontFor(Canvas, 0);
  Canvas.SetDrawColor(255, 255, 255);
  Canvas.DrawScreenText(TextTitle, 0.050, 0.050, DP_UpperLeft);

  if (TextSubtitle == "")
    TextSubtitle = GetGameDescription(Level) @ GetGameLimits(Level);

  Canvas.Font = GetSmallFontFor(Canvas.ClipX, 0);
  Canvas.SetDrawColor(255, 255, 255);
  Canvas.DrawScreenText(TextSubtitle, 0.050, 0.110, DP_UpperLeft);
}


// ============================================================================
// GetGameTitle
//
// Returns the current level's title. If the mapper didn't set a title,
// processes the map package name to create one.
// ============================================================================

static function string GetGameTitle(LevelInfo Level)
{
  local int iChar;
  local int iCharSeparator;
  local string TextTitle;

  if (Level.Title != Level.Default.Title)
    return Level.Title;

  TextTitle = string(Level);
  TextTitle = Left(TextTitle, InStr(TextTitle, "."));

  iCharSeparator = InStr(TextTitle, "-");
  if (iCharSeparator >= 0)
    TextTitle = Mid(TextTitle, iCharSeparator + 1);

  for (iChar = 0; iChar < Len(TextTitle); iChar++)
    if (Caps(Mid(TextTitle, iChar, 1)) < "A" ||
        Caps(Mid(TextTitle, iChar, 1)) > "Z")
      break;

  TextTitle = Left(TextTitle, iChar);

  for (iChar = Len(TextTitle) - 1; iChar > 0; iChar--)
    if (Mid(TextTitle, iChar, 1) >= "A" &&
        Mid(TextTitle, iChar, 1) <= "Z")
      TextTitle = Left(TextTitle, iChar) @ Mid(TextTitle, iChar);

  return TextTitle;
}


// ============================================================================
// GetGameReplicationInfo
//
// Returns a reference to the GameReplicationInfo actor corresponding to the
// given LevelInfo object.
// ============================================================================

static function GameReplicationInfo GetGameReplicationInfo(LevelInfo Level)
{
  if (Level.Game != None)
    return Level.Game.GameReplicationInfo;

  return Level.GetLocalPlayerController().GameReplicationInfo;
}


// ============================================================================
// GetGameDescription
//
// Returns a description of the current type of game.
// ============================================================================

static function string GetGameDescription(LevelInfo Level)
{
  local int iSkill;

  if (Level.NetMode != NM_Standalone)
    return Default.TextGameOnline @ GetGameReplicationInfo(Level).ServerName;

  iSkill = Level.Game.GameDifficulty;
  if (Level.Game.CurrentGameProfile != None)
    iSkill = Level.Game.CurrentGameProfile.BaseDifficulty;

  return Default.TextSkill[iSkill] @ Default.TextGameBotmatch;
}


// ============================================================================
// GetGameLimits
//
// Returns a description of the game limits.
// ============================================================================

static function string GetGameLimits(LevelInfo Level)
{
  local string TextLimits;

  if (GetGameReplicationInfo(Level).TimeLimit > 0)
    TextLimits = GetGameReplicationInfo(Level).TimeLimit @ Default.TextLimitTime;

  if (GetGameReplicationInfo(Level).GoalScore > 0) {
    if (TextLimits != "")
      TextLimits = TextLimits $ ", ";
    TextLimits = TextLimits $ GetGameReplicationInfo(Level).GoalScore @ Default.TextLimitScore;
  }

  return Default.TextLimitPrefix $ TextLimits $ Default.TextLimitSuffix;
}


// ============================================================================
// DrawClock
//
// Draws the clock that shows the current game time and the time of recent
// captures, and the textual time display that goes with it.
// ============================================================================

simulated function DrawClock(Canvas Canvas)
{
  local int iCapture;
  local int iTeam;
  local int nCaptures;
  local int nSecondsMax;
  local int nSecondsCurrent;
  local int nSecondsDisplayed;
  local int nSecondsInterval;
  local int nSecondsTick;
  local int TimeCapture;
  local string TextTime;
  local string TextRelation;
  local TeamInfo TeamCaptured;

  if (PlayerController(Owner).PlayerReplicationInfo.Team != None)
    iTeam = PlayerController(Owner).PlayerReplicationInfo.Team.TeamIndex;

  SpriteWidgetClockAnchorFill.Color = ColorFill[iTeam];
  SpriteWidgetClockAnchorTint.Color = ColorTint[iTeam];

  DrawSpriteWidget(Canvas, SpriteWidgetClockAnchorFill);
  DrawSpriteWidget(Canvas, SpriteWidgetClockAnchorTint);
  DrawSpriteWidget(Canvas, SpriteWidgetClockAnchorFrame);

  DrawSpriteWidget(Canvas, SpriteWidgetClockCircle);

  if (GRI.TimeLimit > 0) {
    nSecondsMax = 60 * GRI.TimeLimit;

    TextRelation = TextRelationRemaining;
    if (GRI.ElapsedTime > nSecondsMax)
      TextRelation = TextRelationOvertime;
    TextTime = FormatTime(Abs(nSecondsMax - GRI.ElapsedTime));
  }

  else {
    nSecondsMax = 60 * 12;
    while (nSecondsMax <= GRI.ElapsedTime)
      nSecondsMax *= 2;

    TextRelation = TextRelationElapsed;
    TextTime = FormatTime(GRI.ElapsedTime);
  }

  nSecondsInterval  = nSecondsMax / 15 + 59;
  nSecondsInterval -= nSecondsInterval % 60;

  nSecondsCurrent = GRI.ElapsedTime;
  nSecondsDisplayed = nSecondsCurrent % nSecondsMax;

  for (nSecondsTick = 0; nSecondsTick < nSecondsMax; nSecondsTick += nSecondsInterval) {
    RotatedWidgetClockTick.Angle = -65536 * nSecondsTick / nSecondsMax;
    DrawRotatedWidget(Canvas, RotatedWidgetClockTick);
  }

  if (nSecondsDisplayed < nSecondsMax / 2) {
    RotatedWidgetClockFillFirst.Angle = -65536 * nSecondsDisplayed / nSecondsMax;
    DrawRotatedWidget(Canvas, RotatedWidgetClockFillFirst);
  }

  else {
    RotatedWidgetClockFillSecond.Angle = -65536 * nSecondsDisplayed / nSecondsMax;
    DrawSpriteWidget(Canvas, SpriteWidgetClockFillFirst);
    DrawRotatedWidget(Canvas, RotatedWidgetClockFillSecond);
  }

  Canvas.SetDrawColor(255, 255, 255);
  Canvas.Font = GetSmallFontFor(Canvas.ClipX, 0);
  Canvas.DrawScreenText(TextTime,     0.930, 0.100, DP_LowerMiddle);
  Canvas.DrawScreenText(TextRelation, 0.930, 0.100, DP_UpperMiddle);

  nCaptures = JBGameReplicationInfo(GRI).CountCaptures();

  for (iCapture = 0; iCapture < nCaptures; iCapture++) {
    TimeCapture  = JBGameReplicationInfo(GRI).GetCaptureTime(iCapture);
    TeamCaptured = JBGameReplicationInfo(GRI).GetCaptureTeam(iCapture);

    RotatedWidgetClockMarker.Angle = -65536 * TimeCapture / nSecondsMax;
    RotatedWidgetClockMarker.Color = ColorMarkerTie;

    if (TeamCaptured != None)
      RotatedWidgetClockMarker.Color = ColorMarkerCaptured[TeamCaptured.TeamIndex];

    DrawRotatedWidget(Canvas, RotatedWidgetClockMarker);
  }
}


// ============================================================================
// FormatTime
//
// Formats a given number of seconds as a string specifying hours, minutes and
// seconds. Somewhat similar to the overwritten superclass method, but sticks
// to one leading zero max.
// ============================================================================

simulated function string FormatTime(int nSeconds)
{
  local int nHours;
  local int nMinutes;
  local string TextFormatted;

  nHours   = nSeconds / 3600;  nSeconds = nSeconds % 3600;
  nMinutes = nSeconds /   60;  nSeconds = nSeconds %   60;

  if (nHours > 0) {
    TextFormatted = nHours $ ":";

    if (nMinutes < 10)
      TextFormatted = TextFormatted $ "0";
  }

  TextFormatted = TextFormatted $ nMinutes $ ":";

  if (nSeconds < 10)
    TextFormatted = TextFormatted $ "0";
  TextFormatted = TextFormatted $ nSeconds;

  return TextFormatted;
}


// ============================================================================
// DrawCrosshair
//
// Draws the current crosshair if appropriate.
// ============================================================================

simulated function DrawCrosshair(Canvas Canvas)
{
  local Hud Hud;

  Hud = PlayerController(Owner).myHUD;

  if (Hud.PawnOwner        != None &&
      Hud.PawnOwner.Weapon != None)
    Hud.DrawCrosshair(Canvas);
}


// ============================================================================
// DrawPanorama
//
// Draws the map panorama on the screen. Individual player locations are drawn
// later when the player entries are rendered on the screen.
// ============================================================================

simulated function DrawPanorama(Canvas Canvas)
{
  if (Panorama != None)
    Panorama.Draw(Canvas);
  else
    if (Level.NetMode == NM_Standalone)
      Class'JBPanorama'.Static.DrawStatus(Canvas, Class'JBPanorama'.Default.TextSetup);
}


// ============================================================================
// UpdateListEntry
//
// Updates the list of displayed entries. Removes entries that have completely
// moved out; adds entries for players who joined; sorts all entries and
// updates their positions. Also updates iEntryOwner and ScorePartialMax.
// ============================================================================

simulated function UpdateListEntry()
{
  local int iEntry;
  local int iEntryNew;
  local int iTable;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;

  firstTagPlayer = JBGameReplicationInfo(GRI).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    thisTagPlayer.bIsInScoreboard = False;

  for (iEntry = 0; iEntry < ListEntry.Length; iEntry++) {
    if (ListEntry[iEntry].TagPlayer != None)
      ListEntry[iEntry].TagPlayer.bIsInScoreboard = True;

    if (!UpdateEntry(ListEntry[iEntry]))
      SetEntryPosition(
        ListEntry[iEntry],
        ListEntry[iEntry].PositionCurrent.iTable,
        ListEntry[iEntry].PositionCurrent.iRow,
        True);
  }

  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    if (thisTagPlayer.GetTeam() != None &&
       !thisTagPlayer.bIsInScoreboard) {

      iEntryNew = ListEntry.Length;
      ListEntry.Insert(iEntryNew, 1);
      ListEntry[iEntryNew].TagPlayer = thisTagPlayer;

      UpdateEntry(ListEntry[iEntryNew]);
    }

  for (iEntry = ListEntry.Length - 1; iEntry >= 0; iEntry--)
    if (ListEntry[iEntry].AlphaPosition == 1.0   &&
        ListEntry[iEntry].PositionCurrent.bIsSet &&
        ListEntry[iEntry].PositionCurrent.bOutside)
      ListEntry.Remove(iEntry, 1);

  SortListEntry(0, ListEntry.Length - 1);

  for (iTable = 0; iTable < ArrayCount(Table); iTable++)
    Table[iTable].nEntries = 0;

  iEntryOwner = -1;  // owner not found
  ScorePartialMax = 0;

  for (iEntry = 0; iEntry < ListEntry.Length; iEntry++) {
    if (ListEntry[iEntry].PositionCurrent.bIsSet &&
        ListEntry[iEntry].PositionCurrent.bOutside)
      continue;

    if (ListEntry[iEntry].bIsLocal)
      iEntryOwner = iEntry;

    ScorePartialMax = Max(ScorePartialMax,
      Max(ListEntry[iEntry].ScorePartialAttack,
      Max(ListEntry[iEntry].ScorePartialDefense,
          ListEntry[iEntry].ScorePartialRelease)));

    SetEntryPosition(
      ListEntry[iEntry],
      ListEntry[iEntry].iTeam,
      Table[ListEntry[iEntry].iTeam].nEntries);

    if (!ListEntry[iEntry].PositionCurrent.bOutside)
      Table[ListEntry[iEntry].PositionCurrent.iTable].nEntries += 1;
  }
}


// ============================================================================
// SetEntryPosition
//
// Sets the given entry's next position.
// ============================================================================

simulated function SetEntryPosition(out TEntry Entry, int iTable, int iRow, optional bool bOutside)
{
  if (Entry.PositionCurrent.bIsSet) {
    if (Entry.PositionCurrent.iTable   != iTable ||
        Entry.PositionCurrent.iRow     != iRow   ||
        Entry.PositionCurrent.bOutside != bOutside) {

      if (Entry.AlphaPosition == 1.0) {
        Entry.AlphaPosition = 0.0;
        Entry.PositionPrevious = Entry.PositionCurrent;

        Entry.PositionCurrent.iTable   = iTable;
        Entry.PositionCurrent.iRow     = iRow;
        Entry.PositionCurrent.bOutside = bOutside;

        Entry.PositionPending.bIsSet   = False;
      }

      else {
        Entry.PositionPending.bIsSet   = True;
        Entry.PositionPending.iTable   = iTable;
        Entry.PositionPending.iRow     = iRow;
        Entry.PositionPending.bOutside = bOutside;
      }
    }
  }

  else {
    Entry.PositionCurrent.bIsSet   = True;
    Entry.PositionCurrent.iTable   = iTable;
    Entry.PositionCurrent.iRow     = iRow;
    Entry.PositionCurrent.bOutside = bOutside;

    Entry.AlphaPosition = 0.0;
    Entry.PositionPrevious = Entry.PositionCurrent;
    Entry.PositionPrevious.bOutside = True;
  }
}


// ============================================================================
// SortListEntry
//
// Sorts all entries using a QuickSort implementation.
// ============================================================================

private simulated function SortListEntry(int iEntryStart, int iEntryEnd)
{
  local int iEntryLeft;
  local int iEntryRight;
  local TEntry EntryMiddle;
  local TEntry EntrySwapped;

  if (iEntryStart >= iEntryEnd)
    return;

  iEntryLeft  = iEntryStart;
  iEntryRight = iEntryEnd;

  EntryMiddle = ListEntry[(iEntryStart + iEntryEnd) / 2];

  while (iEntryLeft < iEntryRight) {
    while (iEntryLeft  < iEntryEnd   && IsEntryInOrder(ListEntry[iEntryLeft], EntryMiddle))  iEntryLeft  += 1;
    while (iEntryStart < iEntryRight && IsEntryInOrder(EntryMiddle, ListEntry[iEntryRight])) iEntryRight -= 1;

    if (iEntryLeft < iEntryRight) {
      EntrySwapped           = ListEntry[iEntryLeft];
      ListEntry[iEntryLeft]  = ListEntry[iEntryRight];
      ListEntry[iEntryRight] = EntrySwapped;
    }

    iEntryLeft  += 1;
    iEntryRight -= 1;
  }

  SortListEntry(iEntryStart, iEntryRight);
  SortListEntry(iEntryLeft,  iEntryEnd);
}


// ============================================================================
// IsEntryInOrder
//
// Checks and returns whether two given entries are in the correct order.
// ============================================================================

simulated function bool IsEntryInOrder(TEntry Entry1, TEntry Entry2)
{
  return (Entry1.Score >  Entry2.Score ||
         (Entry1.Score == Entry2.Score &&
           (Entry1.nDeaths <  Entry2.nDeaths ||
           (Entry1.nDeaths == Entry2.nDeaths &&
             Entry1.Name < Entry2.Name))));
}


// ============================================================================
// UpdateEntry
//
// Updates an entry. Returns whether the given player is still in the game.
// ============================================================================

simulated function bool UpdateEntry(out TEntry Entry)
{
  local int HealthCurrent;
  local TeamPlayerReplicationInfo TeamPlayerReplicationInfo;

  if (Entry.TagPlayer == None)
    return False;

  TeamPlayerReplicationInfo = TeamPlayerReplicationInfo(Entry.TagPlayer.GetPlayerReplicationInfo());
  if (TeamPlayerReplicationInfo == None)
    return False;

  Entry.Name    = TeamPlayerReplicationInfo.PlayerName;
  Entry.Score   = TeamPlayerReplicationInfo.Score;
  Entry.nDeaths = TeamPlayerReplicationInfo.Deaths;
  Entry.iTeam   = TeamPlayerReplicationInfo.Team.TeamIndex;

  Entry.bIsFree  = Entry.TagPlayer.IsFree();
  Entry.bIsLocal = Entry.TagPlayer.GetController() == Owner;
  Entry.Location = Entry.TagPlayer.GetLocationPawn();

  if (UnrealPlayer(Owner).bDisplayWinner ||
      UnrealPlayer(Owner).bDisplayLoser  ||
      JBGameReplicationInfo(GRI).bIsExecuting)
    Entry.InfoGame = GetInfoScores(Entry.TagPlayer);
  else
    Entry.InfoGame = GetInfoOrders(Entry.TagPlayer);

  while (Right(Entry.InfoGame, 1) == " ")
    Entry.InfoGame = Left(Entry.InfoGame, Len(Entry.InfoGame) - 1);

  if (Level.NetMode != NM_Standalone && !TeamPlayerReplicationInfo.bBot) {
    Entry.InfoTime = FormatTime(GRI.ElapsedTime - TeamPlayerReplicationInfo.StartTime);
    Entry.InfoNet = TeamPlayerReplicationInfo.Ping @ "ms";
  }

  HealthCurrent = Entry.TagPlayer.GetHealth(True);
  if (Entry.Health > HealthCurrent && Entry.FadeDamage == 0.0)
    Entry.FadeDamage = 1.0;
  Entry.Health = HealthCurrent;

  Entry.ScorePartialAttack  = Entry.TagPlayer.ScorePartialAttack;
  Entry.ScorePartialDefense = Entry.TagPlayer.ScorePartialDefense;
  Entry.ScorePartialRelease = Entry.TagPlayer.ScorePartialRelease;

  return True;
}


// ============================================================================
// GetInfoOrders
//
// Returns a string describing the given player's current orders.
// ============================================================================

simulated function string GetInfoOrders(JBTagPlayer TagPlayer)
{
  local int iTeamPlayer;
  local GameObjective GameObjective;
  local TeamPlayerReplicationInfo TeamPlayerReplicationInfo;

  TeamPlayerReplicationInfo = TeamPlayerReplicationInfo(TagPlayer.GetPlayerReplicationInfo());

  if (TeamPlayerReplicationInfo.bWaitingPlayer)
    return TextInfoWaiting;

  if (TagPlayer.GetHealth(True) <= 0)
    return TextInfoDead;

  if (TagPlayer.IsInArena()) return TextInfoArena;
  if (TagPlayer.IsInJail())  return TextInfoJail;

  iTeamPlayer = TeamPlayerReplicationInfo.Team.TeamIndex;

  if (iEntryOwner >= 0 && ListEntry[iEntryOwner].iTeam != iTeamPlayer)
    return TextOrdersUndisclosed;

  if (TeamPlayerReplicationInfo.Squad != None)
    return TeamPlayerReplicationInfo.Squad.GetOrderStringFor(TeamPlayerReplicationInfo);

  GameObjective = TagPlayer.GetObjectiveGuessed();
  if (GameObjective == None)
    return TextOrdersFreelance;

  if (GameObjective.DefenderTeamIndex == iTeamPlayer)
    return TextOrdersDefense @ GameObjective.ObjectiveName;
  else
    return TextOrdersAttack  @ GameObjective.ObjectiveName;
}


// ============================================================================
// GetInfoScores
//
// Returns a string describing the given player's partial scores.
// ============================================================================

static function string GetInfoScores(JBTagPlayer TagPlayer)
{
  local string TextInfoScores;

  if (TagPlayer.ScorePartialAttack > 0)
    TextInfoScores = TagPlayer.ScorePartialAttack @ Default.TextScoresAttack;

  if (TagPlayer.ScorePartialDefense > 0) {
    if (TextInfoScores != "")
      TextInfoScores = TextInfoScores $ ", ";
    TextInfoScores = TextInfoScores $ TagPlayer.ScorePartialDefense @ Default.TextScoresDefense;
  }

  if (TagPlayer.ScorePartialRelease > 0) {
    if (TextInfoScores != "")
      TextInfoScores = TextInfoScores $ ", ";
    TextInfoScores = TextInfoScores $ TagPlayer.ScorePartialRelease @ Default.TextScoresRelease;
  }

  if (TextInfoScores != "")
    return TextInfoScores;

  return Default.TextScoresNone;
}


// ============================================================================
// CalcTableLayout
//
// Realizes and returns a layout for the given table.
// ============================================================================

simulated function TTableLayout CalcTableLayout(Canvas Canvas, TTable Table)
{
  local int OffsetBarHorz;
  local int OffsetStatsHorz;
  local int SpacingStatsHorz;
  local vector SizeText;
  local TTableLayout Layout;

  Canvas.Font = FontObjectMain;  Canvas.TextSize("X", SizeText.X, SizeText.Y);  Layout.HeightEntry  = SizeText.Y;
  Canvas.Font = FontObjectInfo;  Canvas.TextSize("X", SizeText.X, SizeText.Y);  Layout.HeightEntry += SizeText.Y;

  Layout.SpacingEntry = Min(Layout.HeightEntry * 0.4, Canvas.ClipY * 0.7 / Table.nEntriesDisplayed - Layout.HeightEntry);

  Layout.WidthLineMain  = Canvas.ClipX * 0.003;
  Layout.WidthLineStats = Canvas.ClipX * 0.002;
  Layout.WidthBarStats  = Canvas.ClipX * 0.006;

  Layout.WidthBarStats += (Layout.WidthBarStats - Layout.WidthLineStats) % 2;

  SpacingStatsHorz =  Layout.WidthBarStats + Layout.WidthLineStats;
  OffsetBarHorz    = (Layout.WidthBarStats - Layout.WidthLineStats) / 2;

  switch (Table.iTable) {
    case 0:  OffsetStatsHorz = -3 * SpacingStatsHorz - OffsetBarHorz - Layout.WidthLineStats;  break;
    case 1:  OffsetStatsHorz =      SpacingStatsHorz + OffsetBarHorz + Layout.WidthLineMain;   break;
  }

  Layout.OffsetLineStats[0].X = OffsetStatsHorz;
  Layout.OffsetLineStats[1].X = OffsetStatsHorz +     SpacingStatsHorz;
  Layout.OffsetLineStats[2].X = OffsetStatsHorz + 2 * SpacingStatsHorz;

  Layout.OffsetLineStats[0].Y = Canvas.ClipY * -0.010;
  Layout.OffsetLineStats[1].Y = Canvas.ClipY * -0.050;
  Layout.OffsetLineStats[2].Y = Canvas.ClipY * -0.026;

  switch (Table.iTable) {
    case 0:  Layout.Location.X = Canvas.ClipX * 0.100;                         break;
    case 1:  Layout.Location.X = Canvas.ClipX * 0.900 - Layout.WidthLineMain;  break;
  }

  Layout.Location.Y = int(Canvas.ClipY * 0.960 - Table.nEntriesDisplayed * (Layout.HeightEntry + Layout.SpacingEntry));

  switch (Table.iTable) {
    case 0:  Layout.OffsetMain.X = Canvas.ClipX *  0.014 + Layout.WidthLineMain;  break;
    case 1:  Layout.OffsetMain.X = Canvas.ClipX * -0.010;                         break;
  }

  switch (Table.iTable) {
    case 0:  Layout.OffsetScore.X = Layout.OffsetLineStats[0].X - SpacingStatsHorz - OffsetBarHorz;                          break;
    case 1:  Layout.OffsetScore.X = Layout.OffsetLineStats[2].X + SpacingStatsHorz + OffsetBarHorz + Layout.WidthLineStats;  break;
  }

  return Layout;
}


// ============================================================================
// CalcEntryLayout
//
// Realizes and returns a layout for the given entry at the specified table
// position.
// ============================================================================

simulated function TEntryLayout CalcEntryLayout(Canvas Canvas, TEntry Entry, TEntryPosition Position)
{
  local float AlphaHighlight;
  local vector SizeTextName;
  local vector SizeTextInfoGame;
  local vector SizeTextInfoTime;
  local vector SizeTextInfoNet;
  local vector SizeTextScore;
  local TEntryLayout LayoutEntry;
  local TTableLayout LayoutTable;

  Canvas.Font = FontObjectMain;  Canvas.TextSize(Entry.Name,     SizeTextName    .X, SizeTextName    .Y);
  Canvas.Font = FontObjectInfo;  Canvas.TextSize(Entry.InfoGame, SizeTextInfoGame.X, SizeTextInfoGame.Y);
  Canvas.Font = FontObjectInfo;  Canvas.TextSize(Entry.InfoTime, SizeTextInfoTime.X, SizeTextInfoTime.Y);
  Canvas.Font = FontObjectInfo;  Canvas.TextSize(Entry.InfoNet,  SizeTextInfoNet .X, SizeTextInfoNet .Y);
  Canvas.Font = FontObjectMain;  Canvas.TextSize(Entry.Score,    SizeTextScore   .X, SizeTextScore   .Y);

  LayoutTable = Table[Position.iTable].Layout;

  LayoutEntry.Location = LayoutTable.Location;
  LayoutEntry.Location.Y += Position.iRow * (LayoutTable.HeightEntry + LayoutTable.SpacingEntry);

  if (Position.bOutside)
    switch (Position.iTable) {
      case 0:  LayoutEntry.Location.X -= Canvas.ClipX * 0.500;  break;
      case 1:  LayoutEntry.Location.X += Canvas.ClipX * 0.500;  break;
    }

  LayoutEntry.OffsetName     = LayoutTable.OffsetMain;
  LayoutEntry.OffsetScore    = LayoutTable.OffsetScore;
  LayoutEntry.OffsetInfoTime = LayoutTable.OffsetScore + SizeTextName.Y * vect(0.0, 1.1, 0.0);
  LayoutEntry.OffsetInfoGame = LayoutTable.OffsetMain  + SizeTextName.Y * vect(0.0, 1.1, 0.0);
  LayoutEntry.OffsetInfoNet  = LayoutTable.OffsetMain  + SizeTextName.Y * vect(0.0, 1.1, 0.0);
  LayoutEntry.OffsetLine     = LayoutTable.OffsetMain  + SizeTextName.Y * vect(0.0, 0.5, 0.0);
  LayoutEntry.OffsetStats    = LayoutTable.OffsetLineStats[0];

  LayoutEntry.OffsetStats.X -= (LayoutTable.WidthBarStats - LayoutTable.WidthLineStats) / 2;
  LayoutEntry.OffsetStats.Y = 0;

  switch (Position.iTable) {
    case 0:
      if (Entry.InfoGame != "")
        LayoutEntry.OffsetInfoNet.X += Canvas.ClipX * 0.016;
      LayoutEntry.OffsetScore   .X -= SizeTextScore   .X;
      LayoutEntry.OffsetInfoNet .X += SizeTextInfoGame.X;
      LayoutEntry.OffsetInfoTime.X -= SizeTextInfoTime.X + Canvas.ClipX * 0.002;
      LayoutEntry.OffsetLine    .X += SizeTextName    .X + Canvas.ClipX * 0.008;
      break;

    case 1:
      if (Entry.InfoGame != "")
        LayoutEntry.OffsetInfoNet.X -= Canvas.ClipX * 0.016;
      LayoutEntry.OffsetName    .X -= SizeTextName    .X;
      LayoutEntry.OffsetInfoGame.X -= SizeTextInfoGame.X;
      LayoutEntry.OffsetInfoNet .X -= SizeTextInfoGame.X + SizeTextInfoNet.X;
      LayoutEntry.OffsetInfoTime.X +=                      Canvas.ClipX * 0.002;
      LayoutEntry.OffsetLine    .X -= SizeTextName    .X + Canvas.ClipX * 0.008;
      break;
  }

  if (Entry.bIsLocal) {
    AlphaHighlight = FClamp(Sin(Level.TimeSeconds * 10.0), 0.0, 1.0);

    LayoutEntry.ColorMain =        AlphaHighlight  * Table[Position.iTable].ColorMainLocal +
                            (1.0 - AlphaHighlight) * Table[Position.iTable].ColorMain;
    LayoutEntry.ColorInfo =        AlphaHighlight  * Table[Position.iTable].ColorInfoLocal +
                            (1.0 - AlphaHighlight) * Table[Position.iTable].ColorInfo;
  }

  else {
    LayoutEntry.ColorMain = Table[Position.iTable].ColorMain;
    LayoutEntry.ColorInfo = Table[Position.iTable].ColorInfo;
  }

  if (Position.bOutside) {
    LayoutEntry.ColorMain.A = 0;
    LayoutEntry.ColorInfo.A = 0;
  }

  return LayoutEntry;
}


// ============================================================================
// InterpolateEntryLayout
//
// Interpolates between two entry layouts and returns the result.
// ============================================================================

simulated function TEntryLayout InterpolateEntryLayout(float Alpha, TEntryLayout Layout1, TEntryLayout Layout2)
{
  local TEntryLayout LayoutInterpolated;

  LayoutInterpolated.Location = Layout1.Location + Alpha * (Layout2.Location - Layout1.Location);

  if (Layout1.Location.X == Layout2.Location.X)
    LayoutInterpolated.Location.X += (Layout1.Location.Y - Layout2.Location.Y) * (0.25 - Square(Alpha - 0.5));

  LayoutInterpolated.OffsetName     = Layout1.OffsetName     + Alpha * (Layout2.OffsetName     - Layout1.OffsetName);
  LayoutInterpolated.OffsetInfoGame = Layout1.OffsetInfoGame + Alpha * (Layout2.OffsetInfoGame - Layout1.OffsetInfoGame);
  LayoutInterpolated.OffsetInfoTime = Layout1.OffsetInfoTime + Alpha * (Layout2.OffsetInfoTime - Layout1.OffsetInfoTime);
  LayoutInterpolated.OffsetInfoNet  = Layout1.OffsetInfoNet  + Alpha * (Layout2.OffsetInfoNet  - Layout1.OffsetInfoNet);
  LayoutInterpolated.OffsetScore    = Layout1.OffsetScore    + Alpha * (Layout2.OffsetScore    - Layout1.OffsetScore);
  LayoutInterpolated.OffsetStats    = Layout1.OffsetStats    + Alpha * (Layout2.OffsetStats    - Layout1.OffsetStats);
  LayoutInterpolated.OffsetLine     = Layout1.OffsetLine     + Alpha * (Layout2.OffsetLine     - Layout1.OffsetLine);

  LayoutInterpolated.ColorMain   =        (1.0 - Alpha) * Layout1.ColorMain   + Alpha * Layout2.ColorMain;
  LayoutInterpolated.ColorMain.A = FClamp((1.0 - Alpha) * Layout1.ColorMain.A + Alpha * Layout2.ColorMain.A, 0, 255);

  LayoutInterpolated.ColorInfo   =        (1.0 - Alpha) * Layout1.ColorInfo   + Alpha * Layout2.ColorInfo;
  LayoutInterpolated.ColorInfo.A = FClamp((1.0 - Alpha) * Layout1.ColorInfo.A + Alpha * Layout2.ColorInfo.A, 0, 255);

  return LayoutInterpolated;
}


// ============================================================================
// MoveTable
//
// Gradually moves the table layout to accommodate the current requirements.
// ============================================================================

simulated function MoveTable(out TTable Table, float TimeDelta)
{
  Table.nEntriesDisplayed += (Table.nEntries - Table.nEntriesDisplayed) * FMin(1.0, 4.0 * TimeDelta);
}


// ============================================================================
// MoveEntry
//
// Gradually moves an entry from its previous to its current position. When
// a movement is finished and another movement is pending, initiates that
// movement.
// ============================================================================

simulated function MoveEntry(out TEntry Entry, float TimeDelta)
{
  if (!bIsMatchRunning)
    Entry.FadeMain = 1.0;
  else
    if (Entry.Health > 0 && Entry.bIsFree)
         Entry.FadeMain = FMin(1.0, Entry.FadeMain + 2.0 * TimeDelta);
    else Entry.FadeMain = FMax(0.0, Entry.FadeMain - 2.0 * TimeDelta);

  Entry.FadeDamage    = FMax(0.0, Entry.FadeDamage    - 2.0 * TimeDelta);
  Entry.AlphaPosition = FMin(1.0, Entry.AlphaPosition + 2.0 * TimeDelta);

  if (Entry.AlphaPosition < 1.0 ||
     !Entry.PositionPending.bIsSet)
    return;

  Entry.PositionPrevious = Entry.PositionCurrent;
  Entry.PositionCurrent  = Entry.PositionPending;

  Entry.PositionPending.bIsSet = False;

  if (TimeDelta < 1.0)  // otherwise skip movement
    Entry.AlphaPosition = 0.0;
}


// ============================================================================
// DrawTable
//
// Realizes the layout of the given table for the current screen metrics and
// draws the table.
// ============================================================================

simulated function DrawTable(Canvas Canvas, out TTable Table)
{
  local int iStats;
  local int WidthShadow;
  local int WidthTick;
  local string TextScore;
  local vector LocationStats;
  local vector LocationLineMain;
  local vector LocationTextScore;
  local vector ScaleIconStats;
  local vector SizeTextScore;
  local vector SizeIconStats;

  Table.Layout = CalcTableLayout(Canvas, Table);

  WidthTick = Canvas.ClipX * 0.010;
  if (Table.iTable == 1)
    WidthTick = Table.Layout.WidthLineMain - WidthTick;

  WidthShadow = Table.Layout.WidthLineMain * 2/3;

  LocationLineMain = Table.Layout.Location;
  LocationLineMain.Y -= Canvas.ClipY * 0.010;

  Canvas.SetDrawColor(0, 0, 0);  // shadow
  Canvas.SetPos(LocationLineMain.X + WidthShadow, LocationLineMain.Y + WidthShadow);
  Canvas.DrawRect(Texture'BlackTexture', Table.Layout.WidthLineMain, Canvas.ClipY - Canvas.CurY);
  Canvas.SetPos(LocationLineMain.X + WidthShadow, LocationLineMain.Y + WidthShadow);
  Canvas.DrawRect(Texture'BlackTexture', WidthTick, Table.Layout.WidthLineMain);

  Canvas.DrawColor = Table.ColorMain;
  Canvas.SetPos(LocationLineMain.X, LocationLineMain.Y);
  Canvas.DrawRect(Texture'WhiteTexture', Table.Layout.WidthLineMain, Canvas.ClipY - Canvas.CurY);
  Canvas.SetPos(LocationLineMain.X, LocationLineMain.Y);
  Canvas.DrawRect(Texture'WhiteTexture', WidthTick, Table.Layout.WidthLineMain);

  for (iStats = 0; iStats < 3; iStats++) {
    LocationStats = Table.Layout.Location + Table.Layout.OffsetLineStats[iStats];

    Canvas.DrawColor = ColorLineStats[iStats];
    Canvas.SetPos(LocationStats.X, LocationStats.Y);
    Canvas.DrawRect(Texture'WhiteTexture', Table.Layout.WidthLineStats, Canvas.ClipY - Canvas.CurY);

    ScaleIconStats.X = SpriteWidgetIconStats[iStats].TextureScale * Canvas.ClipX / 640;
    ScaleIconStats.Y = SpriteWidgetIconStats[iStats].TextureScale * Canvas.ClipY / 480;

    SizeIconStats = ScaleIconStats;
    SizeIconStats.X *= Abs(SpriteWidgetIconStats[iStats].TextureCoords.X2 - SpriteWidgetIconStats[iStats].TextureCoords.X1);
    SizeIconStats.Y *= Abs(SpriteWidgetIconStats[iStats].TextureCoords.Y2 - SpriteWidgetIconStats[iStats].TextureCoords.Y1);

    Canvas.DrawColor = SpriteWidgetIconStats[iStats].Color;
    Canvas.SetPos(
      LocationStats.X - SizeIconStats.X / 2 + SpriteWidgetIconStats[iStats].OffsetX * ScaleIconStats.X,
      LocationStats.Y - SizeIconStats.Y     + SpriteWidgetIconStats[iStats].OffsetY * ScaleIconStats.Y);
    Canvas.DrawTile(
      SpriteWidgetIconStats[iStats].WidgetTexture,
      SizeIconStats.X,
      SizeIconStats.Y,
      SpriteWidgetIconStats[iStats].TextureCoords.X1,
      SpriteWidgetIconStats[iStats].TextureCoords.Y1,
      SpriteWidgetIconStats[iStats].TextureCoords.X2 - SpriteWidgetIconStats[iStats].TextureCoords.X1,
      SpriteWidgetIconStats[iStats].TextureCoords.Y2 - SpriteWidgetIconStats[iStats].TextureCoords.Y1);
  }

  TextScore = string(int(GRI.Teams[Table.iTable].Score));

  Canvas.Font = GetSmallerFontFor(Canvas, 0);
  Canvas.TextSize(TextScore, SizeTextScore.X, SizeTextScore.Y);

  LocationTextScore = Table.Layout.Location;
  LocationTextScore.Y -= Canvas.ClipY * 0.010 + SizeTextScore.Y;

  switch (Table.iTable) {
    case 0:  LocationTextScore.X += Canvas.ClipX * 0.020;                    break;
    case 1:  LocationTextScore.X -= Canvas.ClipX * 0.020 + SizeTextScore.X;  break;
  }

  Canvas.DrawColor = Table.ColorMain;
  Canvas.SetPos(LocationTextScore.X, LocationTextScore.Y);
  Canvas.DrawTextClipped(TextScore);
}


// ============================================================================
// DrawEntry
//
// Draws the given entry at its current position in its current layout.
// Interpolates between layouts if the positions are changing.
// ============================================================================

simulated function DrawEntry(Canvas Canvas, TEntry Entry)
{
  local int iStats;
  local int HeightBarStats;
  local int HeightBarStatsMax;
  local int HeightBarStatsMin;
  local int ScorePartial;
  local float iTableEntry;
  local float iTableOwner;
  local vector LocationPlayer;
  local vector LocationStats;
  local TEntry EntryOwner;
  local TEntryLayout LayoutEntry;
  local TTableLayout LayoutTable;

  LayoutEntry = CalcEntryLayout(Canvas, Entry, Entry.PositionCurrent);
  if (Entry.AlphaPosition < 1.0)
    LayoutEntry = InterpolateEntryLayout(Entry.AlphaPosition,
                    CalcEntryLayout(Canvas, Entry, Entry.PositionPrevious), LayoutEntry);

  LayoutTable = Table[Entry.PositionCurrent.iTable].Layout;

  Canvas.DrawColor   =        LayoutEntry.ColorMain;
  Canvas.DrawColor.A = FClamp(LayoutEntry.ColorMain.A * (0.5 + 0.5 * Entry.FadeMain), 0, 255);
  Canvas.Font = FontObjectMain;

  Canvas.SetPos(
    LayoutEntry.Location.X + LayoutEntry.OffsetName.X,
    LayoutEntry.Location.Y + LayoutEntry.OffsetName.Y);
  Canvas.DrawTextClipped(Entry.Name);

  Canvas.SetPos(
    LayoutEntry.Location.X + LayoutEntry.OffsetScore.X,
    LayoutEntry.Location.Y + LayoutEntry.OffsetScore.Y);
  Canvas.DrawTextClipped(Entry.Score);

  Canvas.DrawColor   =        LayoutEntry.ColorInfo;
  Canvas.DrawColor.A = FClamp(LayoutEntry.ColorInfo.A * (0.5 + 0.5 * Entry.FadeMain), 0, 255);
  Canvas.Font = FontObjectInfo;

  Canvas.SetPos(
    LayoutEntry.Location.X + LayoutEntry.OffsetInfoGame.X,
    LayoutEntry.Location.Y + LayoutEntry.OffsetInfoGame.Y);
  Canvas.DrawTextClipped(Entry.InfoGame);

  Canvas.DrawColor   = LayoutEntry.ColorInfo;
  Canvas.DrawColor.A = LayoutEntry.ColorInfo.A / 4;

  Canvas.SetPos(
    LayoutEntry.Location.X + LayoutEntry.OffsetInfoTime.X,
    LayoutEntry.Location.Y + LayoutEntry.OffsetInfoTime.Y);
  Canvas.DrawTextClipped(Entry.InfoTime);

  Canvas.SetPos(
    LayoutEntry.Location.X + LayoutEntry.OffsetInfoNet.X,
    LayoutEntry.Location.Y + LayoutEntry.OffsetInfoNet.Y);
  Canvas.DrawTextClipped(Entry.InfoNet);

  LocationStats = LayoutEntry.Location + LayoutEntry.OffsetStats;

  for (iStats = 0; iStats < 3; iStats++) {
    switch (iStats) {
      case 0:  ScorePartial = Entry.ScorePartialAttack;   break;
      case 1:  ScorePartial = Entry.ScorePartialDefense;  break;
      case 2:  ScorePartial = Entry.ScorePartialRelease;  break;
    }

    if (iStats > 0)
      LocationStats.X += LayoutTable.OffsetLineStats[iStats    ].X -
                         LayoutTable.OffsetLineStats[iStats - 1].X;

    HeightBarStatsMin = Max(1, LayoutTable.WidthBarStats / 2);
    HeightBarStatsMax = LayoutTable.HeightEntry - HeightBarStatsMin;
    HeightBarStats = HeightBarStatsMin + HeightBarStatsMax * ScorePartial / Max(6, ScorePartialMax);

    Canvas.DrawColor = ColorBarStats[iStats];
    Canvas.SetPos(
      LocationStats.X,
      LocationStats.Y + LayoutTable.HeightEntry - HeightBarStats);
    Canvas.DrawRect(Texture'WhiteTexture', LayoutTable.WidthBarStats, HeightBarStats);
  }

  if (Panorama != None && bIsMatchRunning && Entry.FadeMain > 0) {
    Canvas.DrawColor   =        LayoutEntry.ColorMain;
    Canvas.DrawColor.A = FClamp(LayoutEntry.ColorMain.A * Entry.FadeMain, 0, 255);

    if (iEntryOwner >= 0) {
      EntryOwner = ListEntry[iEntryOwner];

      iTableOwner = EntryOwner.PositionCurrent .iTable *        EntryOwner.AlphaPosition +
                    EntryOwner.PositionPrevious.iTable * (1.0 - EntryOwner.AlphaPosition);
      iTableEntry = Entry     .PositionCurrent .iTable *        Entry     .AlphaPosition +
                    Entry     .PositionPrevious.iTable * (1.0 - Entry     .AlphaPosition);

      Canvas.DrawColor.A = FClamp(Canvas.DrawColor.A * (1.0 - Abs(iTableEntry - iTableOwner)), 0, 255);
    }

    if (Canvas.DrawColor.A > 0) {
      LocationPlayer = Panorama.CalcLocation(Canvas, Entry.Location);

      DrawSpline(Canvas,
        LayoutEntry.Location + LayoutEntry.OffsetLine,
        LocationPlayer);

      if (Entry.FadeDamage > 0.0) {
        SpriteWidgetDamage.PosX = LocationPlayer.X / Canvas.ClipX;
        SpriteWidgetDamage.PosY = LocationPlayer.Y / Canvas.ClipY;

        SpriteWidgetDamage.Color   =        Canvas.DrawColor;
        SpriteWidgetDamage.Color.A = FClamp(Canvas.DrawColor.A * Entry.FadeDamage, 0, 255);
        SpriteWidgetDamage.TextureScale = Default.SpriteWidgetDamage.TextureScale * (3.0 - Entry.FadeDamage * 2.0);

        DrawSpriteWidget(Canvas, SpriteWidgetDamage);
      }
    }
  }
}


// ============================================================================
// DrawSpriteWidget
//
// Draws a SpriteWidget sprite on the given canvas. The sprite's pivot point
// is assumed to be its upper-left corner.
// ============================================================================

simulated function DrawSpriteWidget(Canvas Canvas, SpriteWidget SpriteWidget)
{
  local vector LocationWidget;
  local vector ScaleWidget;
  local vector SizeWidget;

  ScaleWidget.X = SpriteWidget.TextureScale * Canvas.ClipX / 640;
  ScaleWidget.Y = SpriteWidget.TextureScale * Canvas.ClipY / 480;
  SizeWidget.X  = Abs(SpriteWidget.TextureCoords.X2 - SpriteWidget.TextureCoords.X1) * ScaleWidget.X;
  SizeWidget.Y  = Abs(SpriteWidget.TextureCoords.Y2 - SpriteWidget.TextureCoords.Y1) * ScaleWidget.Y;

  LocationWidget.X = SpriteWidget.PosX * Canvas.ClipX + SpriteWidget.OffsetX * ScaleWidget.X;
  LocationWidget.Y = SpriteWidget.PosY * Canvas.ClipY + SpriteWidget.OffsetY * ScaleWidget.Y;

  Canvas.DrawColor = SpriteWidget.Color;
  Canvas.SetPos(
    LocationWidget.X,
    LocationWidget.Y);
  Canvas.DrawTile(
    SpriteWidget.WidgetTexture,
    SizeWidget.X,
    SizeWidget.Y,
    SpriteWidget.TextureCoords.X1,
    SpriteWidget.TextureCoords.Y1,
    SpriteWidget.TextureCoords.X2 - SpriteWidget.TextureCoords.X1,
    SpriteWidget.TextureCoords.Y2 - SpriteWidget.TextureCoords.Y1);
}


// ============================================================================
// DrawRotatedWidget
//
// Draws a RotatedWidget sprite on the given Canvas. The sprite's pivot point
// is assumed to be the point it is rotated about.
// ============================================================================

simulated function DrawRotatedWidget(Canvas Canvas, RotatedWidget RotatedWidget)
{
  local float AngleInRadian;
  local float SinAngle;
  local float CosAngle;
  local vector OffsetWidgetRotated;
  local vector LocationWidget;
  local vector ScaleWidget;
  local vector SizeWidget;
  local TexRotator TexRotator;

  if (TimeTexRotatorPool != Level.TimeSeconds)
    iTexRotatorPool = 0;
  else
    iTexRotatorPool += 1;

  TimeTexRotatorPool = Level.TimeSeconds;
  if (iTexRotatorPool >= ListTexRotatorPool.Length)
    ListTexRotatorPool[iTexRotatorPool] = new Class'TexRotator';

  TexRotator = ListTexRotatorPool[iTexRotatorPool];

  TexRotator.Material        = RotatedWidget.WidgetTexture;
  TexRotator.UOffset         = RotatedWidget.OffsetCenterX + RotatedWidget.TextureCoords.X1;
  TexRotator.VOffset         = RotatedWidget.OffsetCenterY + RotatedWidget.TextureCoords.Y1;
  TexRotator.Rotation.Yaw    = RotatedWidget.Angle;
  TexRotator.Rotation.Pitch  = 0;
  TexRotator.Rotation.Roll   = 0;
  TexRotator.TexRotationType = TR_FixedRotation;

  ScaleWidget.X = RotatedWidget.TextureScale * Canvas.ClipX / 640;
  ScaleWidget.Y = RotatedWidget.TextureScale * Canvas.ClipY / 480;
  SizeWidget.X  = Abs(RotatedWidget.TextureCoords.X2 - RotatedWidget.TextureCoords.X1) * ScaleWidget.X;
  SizeWidget.Y  = Abs(RotatedWidget.TextureCoords.Y2 - RotatedWidget.TextureCoords.Y1) * ScaleWidget.Y;

  if (RotatedWidget.OffsetRotatedX != 0 ||
      RotatedWidget.OffsetRotatedY != 0) {

    AngleInRadian = Pi * RotatedWidget.Angle / 32768;
    SinAngle = Sin(AngleInRadian);
    CosAngle = Cos(AngleInRadian);

    OffsetWidgetRotated.X = RotatedWidget.OffsetRotatedX * CosAngle + RotatedWidget.OffsetRotatedY * SinAngle;
    OffsetWidgetRotated.Y = RotatedWidget.OffsetRotatedY * CosAngle - RotatedWidget.OffsetRotatedX * SinAngle;
  }

  LocationWidget.X = RotatedWidget.PosX * Canvas.ClipX;
  LocationWidget.Y = RotatedWidget.PosY * Canvas.ClipY;
  LocationWidget.X += (OffsetWidgetRotated.X + RotatedWidget.OffsetX - RotatedWidget.OffsetCenterX) * ScaleWidget.X;
  LocationWidget.Y += (OffsetWidgetRotated.Y + RotatedWidget.OffsetY - RotatedWidget.OffsetCenterY) * ScaleWidget.Y;

  Canvas.DrawColor = RotatedWidget.Color;
  Canvas.SetPos(
    LocationWidget.X,
    LocationWidget.Y);
  Canvas.DrawTile(
    TexRotator,
    SizeWidget.X,
    SizeWidget.Y,
    RotatedWidget.TextureCoords.X1,
    RotatedWidget.TextureCoords.Y1,
    RotatedWidget.TextureCoords.X2 - RotatedWidget.TextureCoords.X1,
    RotatedWidget.TextureCoords.Y2 - RotatedWidget.TextureCoords.Y1);
}


// ============================================================================
// DrawSpline
//
// Draws a dotted spline starting with a horizontal tangent and ending sloped
// towards the end point. As UnrealScript execution performance suffers more
// from a high number of statements than from optimizing code towards
// efficient use of integer numbers, we're just using float vector maths here.
// ============================================================================

simulated function DrawSpline(Canvas Canvas, vector LocationStart, vector LocationEnd)
{
  local byte AlphaColorDraw;
  local int iSegment;
  local float AlphaSpline;
  local float DistanceDots;
  local float DistanceDotLast;
  local float DistanceDotNext;
  local float DistanceSegment;
  local float LengthSegment;
  local float LengthTotal;
  local vector LocationDot;
  local vector LocationMiddle;
  local vector LocationSegment;
  local vector VectorSegment;
  local vector ScaleDot;
  local vector ScalePlayer;
  local vector SizeDot;
  local vector SizePlayer;
  local array<float> ListLengthSegment;
  local array<vector> ListLocationSegment;

  LocationStart.Z = 0;
  LocationEnd  .Z = 0;

  LocationMiddle.X = LocationStart.X + (LocationEnd.X - LocationStart.X) * 0.75;
  LocationMiddle.Y = LocationStart.Y;

  for (AlphaSpline = 0.0; AlphaSpline <= 1.0; AlphaSpline += 0.0625) {
    iSegment = ListLocationSegment.Length;

    ListLocationSegment[iSegment] =
      (1.0 - AlphaSpline) * (LocationStart +        AlphaSpline  * (LocationMiddle - LocationStart)) +
             AlphaSpline  * (LocationEnd   + (1.0 - AlphaSpline) * (LocationMiddle - LocationEnd));

    if (iSegment > 0) {
      LengthSegment = VSize(ListLocationSegment[iSegment    ] -
                            ListLocationSegment[iSegment - 1]);

      ListLengthSegment[iSegment - 1] = LengthSegment;
      LengthTotal += LengthSegment;
    }
  }

  AlphaColorDraw = Canvas.DrawColor.A;
  Canvas.DrawColor.A = AlphaColorDraw / 2;

  ScaleDot.X = SpriteWidgetDot.TextureScale * Canvas.ClipX / 640;
  ScaleDot.Y = SpriteWidgetDot.TextureScale * Canvas.ClipY / 480;
  SizeDot.X  = Abs(SpriteWidgetDot.TextureCoords.X2 - SpriteWidgetDot.TextureCoords.X1) * ScaleDot.X;
  SizeDot.Y  = Abs(SpriteWidgetDot.TextureCoords.Y2 - SpriteWidgetDot.TextureCoords.Y1) * ScaleDot.Y;

  ScalePlayer.X = SpriteWidgetPlayer.TextureScale * Canvas.ClipX / 640;
  ScalePlayer.Y = SpriteWidgetPlayer.TextureScale * Canvas.ClipY / 480;
  SizePlayer.X  = Abs(SpriteWidgetPlayer.TextureCoords.X2 - SpriteWidgetPlayer.TextureCoords.X1) * ScalePlayer.X;
  SizePlayer.Y  = Abs(SpriteWidgetPlayer.TextureCoords.Y2 - SpriteWidgetPlayer.TextureCoords.Y1) * ScalePlayer.Y;

  DistanceDots    = SizeDot   .X * 1.5;  // distance between dots
  DistanceDotLast = SizePlayer.X * 0.5;  // distance between last dot and line end

  for (iSegment = 0; iSegment < ListLengthSegment.Length; iSegment++) {
    if (LengthTotal < DistanceDotLast)
      break;

    LengthSegment = ListLengthSegment[iSegment];
    if (LengthSegment == 0.0)
      continue;

    LocationSegment =  ListLocationSegment[iSegment];
    VectorSegment   = (ListLocationSegment[iSegment + 1] - LocationSegment) / LengthSegment;

    DistanceSegment = 0.0;

    while (LengthSegment >= DistanceDotNext &&
           LengthTotal   >= DistanceDotLast) {

      DistanceSegment += DistanceDotNext;

      LocationDot = LocationSegment + VectorSegment * DistanceSegment;
      LocationDot -= SizeDot / 2;

      Canvas.SetPos(
        LocationDot.X,
        LocationDot.Y);
      Canvas.DrawTile(
        SpriteWidgetDot.WidgetTexture,
        SizeDot.X,
        SizeDot.Y,
        SpriteWidgetDot.TextureCoords.X1,
        SpriteWidgetDot.TextureCoords.Y1,
        SpriteWidgetDot.TextureCoords.X2 - SpriteWidgetDot.TextureCoords.X1,
        SpriteWidgetDot.TextureCoords.Y2 - SpriteWidgetDot.TextureCoords.Y1);

      LengthSegment -= DistanceDotNext;
      LengthTotal   -= DistanceDotNext;

      DistanceDotNext = DistanceDots;
    }

    DistanceDotNext -= LengthSegment;
    LengthTotal     -= LengthSegment;
  }

  Canvas.DrawColor.A = AlphaColorDraw;

  Canvas.SetPos(
    LocationEnd.X - SizePlayer.X / 2,
    LocationEnd.Y - SizePlayer.Y / 2);
  Canvas.DrawTile(
    SpriteWidgetPlayer.WidgetTexture,
    SizePlayer.X,
    SizePlayer.Y,
    SpriteWidgetPlayer.TextureCoords.X1,
    SpriteWidgetPlayer.TextureCoords.Y1,
    SpriteWidgetPlayer.TextureCoords.X2 - SpriteWidgetPlayer.TextureCoords.X1,
    SpriteWidgetPlayer.TextureCoords.Y2 - SpriteWidgetPlayer.TextureCoords.Y1);
}


// ============================================================================
// DrawLine
//
// Draws a line connecting two points on the screen, using one horizontal and
// one vertical segment and ending in a dot. Dead code; used to be used to
// connect player names with their locations on the minimap.
// ============================================================================

simulated function DrawLine(Canvas Canvas, vector LocationStart, vector LocationEnd)
{
  local byte AlphaColorDraw;
  local int WidthLine;
  local vector ScaleDot;
  local vector SizeDot;

  WidthLine = Canvas.ClipX * 0.002;

  LocationStart.Y = int(LocationStart.Y - WidthLine / 2);
  LocationEnd  .X = int(LocationEnd  .X - WidthLine / 2);

  AlphaColorDraw = Canvas.DrawColor.A;
  Canvas.DrawColor.A = AlphaColorDraw / 2;

  if (LocationStart.Y + WidthLine >= LocationEnd.Y &&
      LocationStart.Y             <= LocationEnd.Y) {

    Canvas.SetPos(LocationStart.X, LocationStart.Y);
    Canvas.DrawRect(Texture'WhiteTexture', LocationEnd.X - LocationStart.X, WidthLine);
  }

  else {
    Canvas.SetPos(LocationStart.X, LocationStart.Y);
    if (LocationStart.X < LocationEnd.X)
      LocationStart.X -= WidthLine;
    Canvas.DrawRect(Texture'WhiteTexture', LocationEnd.X - LocationStart.X, WidthLine);

    if (LocationStart.Y < LocationEnd.Y)
      LocationStart.Y += WidthLine;
    Canvas.SetPos(LocationEnd.X, LocationStart.Y);
    Canvas.DrawRect(Texture'WhiteTexture', WidthLine, LocationEnd.Y - LocationStart.Y);
  }

  Canvas.DrawColor.A = AlphaColorDraw;

  ScaleDot.X = SpriteWidgetPlayer.TextureScale * Canvas.ClipX / 640;
  ScaleDot.Y = SpriteWidgetPlayer.TextureScale * Canvas.ClipY / 480;

  SizeDot.X = int(Abs(SpriteWidgetPlayer.TextureCoords.X2 - SpriteWidgetPlayer.TextureCoords.X1) * ScaleDot.X);
  SizeDot.Y = int(Abs(SpriteWidgetPlayer.TextureCoords.Y2 - SpriteWidgetPlayer.TextureCoords.Y1) * ScaleDot.Y);
  SizeDot.X += (SizeDot.X - WidthLine) % 2;
  SizeDot.Y += (SizeDot.Y - WidthLine) % 2;

  Canvas.SetPos(
    LocationEnd.X + (WidthLine - SizeDot.X) / 2,
    LocationEnd.Y              - SizeDot.Y  / 2);
  Canvas.DrawTile(
    SpriteWidgetPlayer.WidgetTexture,
    SizeDot.X,
    SizeDot.Y,
    SpriteWidgetPlayer.TextureCoords.X1,
    SpriteWidgetPlayer.TextureCoords.Y1,
    SpriteWidgetPlayer.TextureCoords.X2 - SpriteWidgetPlayer.TextureCoords.X1,
    SpriteWidgetPlayer.TextureCoords.Y2 - SpriteWidgetPlayer.TextureCoords.Y1);
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  TextGameBotmatch = "Botmatch";
  TextGameOnline   = "Online Match on";

  TextSkill[0] = "Novice";
  TextSkill[1] = "Average";
  TextSkill[2] = "Experienced";
  TextSkill[3] = "Skilled";
  TextSkill[4] = "Adept";
  TextSkill[5] = "Masterful";
  TextSkill[6] = "Inhuman";
  TextSkill[7] = "Godlike";

  TextLimitPrefix = " [";
  TextLimitTime   = "minutes";
  TextLimitScore  = "captures";
  TextLimitSuffix = " max]";

  TextInfoWaiting = "waiting";
  TextInfoDead    = "dead";
  TextInfoArena   = "arena";
  TextInfoJail    = "jailed";

  TextOrdersUndisclosed = "undisclosed";
  TextOrdersAttack      = "attacking";
  TextOrdersDefense     = "defending";
  TextOrdersFreelance   = "Sweeper";
  TextScoresNone        = "";
  TextScoresAttack      = "attack";
  TextScoresDefense     = "defense";
  TextScoresRelease     = "release";

  TextRelationElapsed   = "played";
  TextRelationRemaining = "to play";
  TextRelationOvertime  = "overtime";

  Table[0] = (iTable=0,ColorMain=(R=255,G=000,B=000,A=255),ColorMainLocal=(R=255,G=160,B=160,A=255),ColorInfo=(R=255,G=255,B=255,A=255),ColorInfoLocal=(R=255,G=255,B=255,A=255));
  Table[1] = (iTable=1,ColorMain=(R=000,G=000,B=255,A=255),ColorMainLocal=(R=160,G=160,B=255,A=255),ColorInfo=(R=255,G=255,B=255,A=255),ColorInfoLocal=(R=255,G=255,B=255,A=255));

  ColorLineStats[0] = (R=255,G=000,B=000,A=064);
  ColorLineStats[1] = (R=255,G=255,B=000,A=064);
  ColorLineStats[2] = (R=000,G=255,B=000,A=064);

  ColorBarStats[0]  = (R=128,G=000,B=000,A=255);
  ColorBarStats[1]  = (R=128,G=128,B=000,A=255);
  ColorBarStats[2]  = (R=000,G=128,B=000,A=255);

  SpriteWidgetIconStats[0] = (WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X1=272,Y1=400,X2=351,Y2=488),TextureScale=0.10,OffsetX=06,OffsetY=10,Color=(R=255,G=000,B=000,A=128));
  SpriteWidgetIconStats[1] = (WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X1=400,Y1=128,X2=496,Y2=223),TextureScale=0.10,OffsetX=06,OffsetY=10,Color=(R=255,G=255,B=000,A=128));
  SpriteWidgetIconStats[2] = (WidgetTexture=Material'SpriteWidgetScores',TextureCoords=(X1=342,Y1=87,X2=428,Y2=174),TextureScale=0.10,OffsetX=26,OffsetY=0,Color=(R=000,G=255,B=000,A=128));

  SpriteWidgetDot      = (WidgetTexture=Material'SpriteWidgetScores',TextureCoords=(X1=112,Y1=304,X2=176,Y2=368),TextureScale=0.04);
  SpriteWidgetPlayer   = (WidgetTexture=Material'SpriteWidgetScores',TextureCoords=(X1=112,Y1=304,X2=176,Y2=368),TextureScale=0.09);
  SpriteWidgetDamage   = (WidgetTexture=Material'SpriteWidgetScores',TextureCoords=(X1=112,Y1=304,X2=176,Y2=368),TextureScale=0.09,OffsetX=-32,OffsetY=-32);
  SpriteWidgetGradient = (WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X1=128,Y1=351,X2=129,Y2=353),Color=(R=0,G=0,B=0,A=128));

  ColorFill[0] = (R=100,G=000,B=000,A=200);
  ColorFill[1] = (R=048,G=075,B=120,A=200);
  ColorTint[0] = (R=100,G=000,B=000,A=100);
  ColorTint[1] = (R=037,G=066,B=102,A=150);

  ColorMarkerTie         = (R=128,G=128,B=128,A=255);
  ColorMarkerCaptured[0] = (R=000,G=000,B=255,A=255);
  ColorMarkerCaptured[1] = (R=255,G=000,B=000,A=255);

  SpriteWidgetClockAnchorFill  = (WidgetTexture=Material'InterfaceContent.Hud.SkinA',TextureCoords=(X1=610,Y1=763,X2=455,Y2=891),TextureScale=0.3,PosX=1.00,PosY=0.00,OffsetX=-153,OffsetY=000);
  SpriteWidgetClockAnchorTint  = (WidgetTexture=Material'InterfaceContent.Hud.SkinA',TextureCoords=(X1=454,Y1=763,X2=299,Y2=891),TextureScale=0.3,PosX=1.00,PosY=0.00,OffsetX=-155,OffsetY=000);
  SpriteWidgetClockAnchorFrame = (WidgetTexture=Material'InterfaceContent.Hud.SkinA',TextureCoords=(X1=298,Y1=763,X2=143,Y2=891),TextureScale=0.3,PosX=1.00,PosY=0.00,OffsetX=-153,OffsetY=000,Color=(R=255,G=255,B=255,A=255));
  SpriteWidgetClockCircle      = (WidgetTexture=Material'SpriteWidgetScores',TextureCoords=(X1=016,Y1=016,X2=272,Y2=272),TextureScale=0.3,PosX=0.99,PosY=0.02,OffsetX=-256,OffsetY=000,Color=(R=255,G=255,B=255,A=255));
  SpriteWidgetClockFillFirst   = (WidgetTexture=Material'SpriteWidgetScores',TextureCoords=(X1=400,Y1=496,X2=288,Y2=272),TextureScale=0.3,PosX=0.99,PosY=0.02,OffsetX=-128,OffsetY=016,Color=(R=056,G=056,B=056,A=255));
  RotatedWidgetClockFillFirst  = (WidgetTexture=Material'SpriteWidgetScores',TextureCoords=(X1=400,Y1=272,X2=512,Y2=496),TextureScale=0.3,PosX=0.99,PosY=0.02,OffsetX=-127,OffsetY=128,OffsetCenterX=000,OffsetCenterY=112,Color=(R=056,G=056,B=056,A=255));
  RotatedWidgetClockFillSecond = (WidgetTexture=Material'SpriteWidgetScores',TextureCoords=(X1=288,Y1=272,X2=400,Y2=496),TextureScale=0.3,PosX=0.99,PosY=0.02,OffsetX=-127,OffsetY=128,OffsetCenterX=112,OffsetCenterY=112,Color=(R=056,G=056,B=056,A=255));
  RotatedWidgetClockTick       = (WidgetTexture=Material'SpriteWidgetScores',TextureCoords=(X1=112,Y1=448,X2=176,Y2=512),TextureScale=0.3,PosX=0.99,PosY=0.02,OffsetX=-127,OffsetY=128,OffsetCenterX=032,OffsetCenterY=032,OffsetRotatedX=0,OffsetRotatedY=-121,Color=(R=255,G=255,B=255,A=255));
  RotatedWidgetClockMarker     = (WidgetTexture=Material'SpriteWidgetScores',TextureCoords=(X1=112,Y1=384,X2=176,Y2=448),TextureScale=0.3,PosX=0.99,PosY=0.02,OffsetX=-127,OffsetY=128,OffsetCenterX=032,OffsetCenterY=032,OffsetRotatedX=0,OffsetRotatedY=-118,Color=(R=255,A=255));
}