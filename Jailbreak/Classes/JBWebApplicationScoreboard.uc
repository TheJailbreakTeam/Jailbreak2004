// ============================================================================
// JBWebApplicationScoreboard
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBWebApplicationScoreboard.uc,v 1.3 2004-05-27 21:14:16 tarquin Exp $
//
// Serves the Jailbreak Web Scoreboard to web browsers.
// ============================================================================


class JBWebApplicationScoreboard extends WebApplication;


// ============================================================================
// Types
// ============================================================================

struct TInfoPlayer
{
  var string Name;                        // player name
  var int Score;                          // total score
  var string Info;                        // partial scores
};


struct TInfoTeam
{
  var string Name;                        // team name
  var int Score;                          // team score
  var array<TInfoPlayer> ListInfoPlayer;  // players on this team

  var string VarTemplateName;             // template var for team name
  var string VarTemplateScore;            // template var for team score
  var string VarTemplateHeaderLines;      // template var for header rowspan
  var string VarTemplateEntry;            // template var for entry in row
  var string FileTemplateEntry;           // template inc file for entry
  var string FileTemplateEntryNone;       // template inc file for no entry
};


// ============================================================================
// Configuration
// ============================================================================

var string PathSourceImages;              // source path for images
var string PathSourceTemplates;           // source path for template files
var string PathSourceStyles;              // source path for style sheets

var string FileTemplateScoreboard;        // main template for scoreboard
var string FileTemplateRow;               // template inc file for one row
var string FileTemplateMutators;          // template inc file for mutator list
var string FileTemplateMutatorsNone;      // template inc file for no mutators


// ============================================================================
// Variables
// ============================================================================

var private TInfoTeam InfoTeam[2];        // info for red and blue team


// ============================================================================
// Query
//
// If a file in the virtual image or styles directory was requested, delivers
// it. Otherwise redirects the browser to the canonical scoreboard address if
// applicable, or serves the Jailbreak Web Scoreboard.
// ============================================================================

function Query(WebRequest WebRequest, WebResponse WebResponse)
{
  if (Left(WebRequest.URI, 8) == "/images/")
    QueryImage(WebRequest, WebResponse);
  else if (Left(WebRequest.URI, 8) == "/styles/")
    QueryStyle(WebRequest, WebResponse);

  else if (WebRequest.URI != "/")
    WebResponse.Redirect(WebServer.ServerName $ Path $ "/");

  else
    QueryScoreboard(WebRequest, WebResponse);
}


// ============================================================================
// QueryImage
//
// Delivers an image that is cached by the browser.
// ============================================================================

function QueryImage(WebRequest WebRequest, WebResponse WebResponse)
{
  local string FileImage;
  local string MIMEType;

  FileImage = WebRequest.URI;
  while (InStr(FileImage, "/") >= 0)
    FileImage = Mid(FileImage, InStr(FileImage, "/") + 1);

       if (Right(FileImage, 4) ~= ".gif")  MIMEType = "image/gif";
  else if (Right(FileImage, 4) ~= ".jpe")  MIMEType = "image/jpeg";
  else if (Right(FileImage, 4) ~= ".jpg")  MIMEType = "image/jpeg";
  else if (Right(FileImage, 5) ~= ".jpeg") MIMEType = "image/jpeg";
  else if (Right(FileImage, 4) ~= ".png")  MIMEType = "image/png";

  if (MIMEType == "")
    WebResponse.HTTPError(404);

  else {
    WebResponse.SendStandardHeaders(MIMEType, True);
    WebResponse.IncludeBinaryFile(PathSourceImages $ "/" $ FileImage);
  }
}


// ============================================================================
// QueryStyle
//
// Delivers a style sheet that is cached by the browser.
// ============================================================================

function QueryStyle(WebRequest WebRequest, WebResponse WebResponse)
{
  local string FileStyle;
  local string MIMEType;

  FileStyle = WebRequest.URI;
  while (InStr(FileStyle, "/") >= 0)
    FileStyle = Mid(FileStyle, InStr(FileStyle, "/") + 1);

  if (Right(FileStyle, 4) ~= ".css")  MIMEType = "text/css";

  if (MIMEType == "")
    WebResponse.HTTPError(404);

  else {
    WebResponse.SendStandardHeaders(MIMEType, True);
    WebResponse.IncludeBinaryFile(PathSourceStyles $ "/" $ FileStyle);
  }
}


// ============================================================================
// QueryScoreboard
//
// Creates the Jailbreak Web Scoreboard from templates and serves it.
// ============================================================================

function QueryScoreboard(WebRequest WebRequest, WebResponse WebResponse)
{
  local int iInfoPlayer;
  local int iInfoTeam;
  local int iRow;
  local int nHeaderLines;
  local int nInfoPlayerMax;
  local string ResultEntry;
  local string ResultEntries;
  local string ResultMutators;

  ReadListInfoPlayer();

  nInfoPlayerMax = 1;
  for (iInfoTeam = 0; iInfoTeam < ArrayCount(InfoTeam); iInfoTeam++) {
    nInfoPlayerMax = Max(nInfoPlayerMax, InfoTeam[iInfoTeam].ListInfoPlayer.Length);

    InfoTeam[iInfoTeam].Name  = Level.Game.GameReplicationInfo.Teams[iInfoTeam].TeamName;
    InfoTeam[iInfoTeam].Score = Level.Game.GameReplicationInfo.Teams[iInfoTeam].Score;
  }

  for (iRow = 0; iRow < nInfoPlayerMax; iRow++) {
    for (iInfoTeam = 0; iInfoTeam < ArrayCount(InfoTeam); iInfoTeam++) {
      ResultEntry = "";
      iInfoPlayer = InfoTeam[iInfoTeam].ListInfoPlayer.Length - nInfoPlayerMax + iRow;

      if (iInfoPlayer == -1 && InfoTeam[iInfoTeam].ListInfoPlayer.Length == 0)
        ResultEntry = WebResponse.LoadParsedUHTM(GetFileTemplate(InfoTeam[iInfoTeam].FileTemplateEntryNone));

      else if (iInfoPlayer >= 0) {
        WebResponse.Subst("Name",  EscapeHTML(InfoTeam[iInfoTeam].ListInfoPlayer[iInfoPlayer].Name));
        WebResponse.Subst("Score", EscapeHTML(InfoTeam[iInfoTeam].ListInfoPlayer[iInfoPlayer].Score));
        WebResponse.Subst("Info",  EscapeHTML(InfoTeam[iInfoTeam].ListInfoPlayer[iInfoPlayer].Info));
        ResultEntry = WebResponse.LoadParsedUHTM(GetFileTemplate(InfoTeam[iInfoTeam].FileTemplateEntry));
      }

      WebResponse.Subst(InfoTeam[iInfoTeam].VarTemplateEntry, ResultEntry);
    }

    ResultEntries = ResultEntries $ WebResponse.LoadParsedUHTM(GetFileTemplate(FileTemplateRow));
  }

  ResultMutators = GetMutators();
  if (ResultMutators == "")
    ResultMutators = "" $ WebResponse.LoadParsedUHTM(GetFileTemplate(FileTemplateMutatorsNone));
  else {
    WebResponse.Subst("Mutators", EscapeHTML(ResultMutators));
    ResultMutators = "" $ WebResponse.LoadParsedUHTM(GetFileTemplate(FileTemplateMutators)) $ "";
  }

  for (iInfoTeam = 0; iInfoTeam < ArrayCount(InfoTeam); iInfoTeam++) {
    nHeaderLines = nInfoPlayerMax - Max(1, InfoTeam[iInfoTeam].ListInfoPlayer.Length) + 1;

    WebResponse.Subst(InfoTeam[iInfoTeam].VarTemplateName,        EscapeHTML(InfoTeam[iInfoTeam].Name));
    WebResponse.Subst(InfoTeam[iInfoTeam].VarTemplateScore,       EscapeHTML(InfoTeam[iInfoTeam].Score));
    WebResponse.Subst(InfoTeam[iInfoTeam].VarTemplateHeaderLines, EscapeHTML(nHeaderLines));
  }

  WebResponse.Subst("URL",             WebServer.ServerURL $ Path $ "/");
  WebResponse.Subst("Entries",         ResultEntries);
  WebResponse.Subst("Mutators",        ResultMutators);
  WebResponse.Subst("ServerName",      EscapeHTML(Level.Game.GameReplicationInfo.ServerName));
  WebResponse.Subst("AdminName",       EscapeHTML(Level.Game.GameReplicationInfo.AdminName));
  WebResponse.Subst("AdminEmail",      EscapeHTML(Level.Game.GameReplicationInfo.AdminEmail));
  WebResponse.Subst("GameURL",         GetGameURL());
  WebResponse.Subst("GameTitle",       EscapeHTML(Class'JBInterfaceScores'.Static.GetGameTitle      (Level)));
  WebResponse.Subst("GameDescription", EscapeHTML(Class'JBInterfaceScores'.Static.GetGameDescription(Level)) @
                                       EscapeHTML(Class'JBInterfaceScores'.Static.GetGameLimits     (Level)));
  WebResponse.Subst("GameTime",        GetTime());

  WebResponse.IncludeUHTM(GetFileTemplate(FileTemplateScoreboard));
}


// ============================================================================
// GetFileTemplate
//
// Returns the full relative path for the given template file name.
// ============================================================================

function string GetFileTemplate(string FileTemplate)
{
  return PathSourceTemplates $ "/" $ FileTemplate;
}


// ============================================================================
// GetGameURL
//
// Returns the server's address that can be used to join the game.
// ============================================================================

function string GetGameURL()
{
  local string GameURL;

  GameURL = Mid(WebServer.ServerURL, 7);  // strip protocol
  GameURL = Left(GameURL, InStr(GameURL $ ":", ":"));
  GameURL = "ut2004://" $ GameURL $ ":" $ Level.Game.GetServerPort();

  return GameURL;
}


// ============================================================================
// GetMutators
//
// Returns a list of mutators currently running on this server.
// ============================================================================

function string GetMutators()
{
  local string Mutators;
  local Mutator thisMutator;

  for (thisMutator = Level.Game.BaseMutator; thisMutator != None; thisMutator = thisMutator.NextMutator)
    if (thisMutator.bUserAdded &&
        thisMutator.FriendlyName != Class'Mutator'.Default.FriendlyName) {

      if (Mutators != "")
        Mutators = Mutators $ ", ";
      Mutators = Mutators $ thisMutator.FriendlyName;
    }

  return Mutators;
}


// ============================================================================
// GetTime
//
// Returns the ingame time.
// ============================================================================

function string GetTime()
{
  local int TotalTime, Minutes, Seconds;
  local string Head, Tail;

  if (!Level.Game.GameReplicationInfo.bMatchHasBegun) // Match hasnt started yet
    return "The game hasn't started yet";

  TotalTime = Level.Game.GameReplicationInfo.ElapsedTime;

  if (Level.Game.bGameEnded) { // Match has ended
    Head = "After";
    Tail = "the game has ended";
  } else {
    if (Level.Game.TimeLimit > 0) { // There's a time limit, count down instead
      Tail = "to go";
      TotalTime = Level.Game.TimeLimit*60 - TotalTime;

      if (TotalTime < 0) { // Overtime
        Tail = "in overtime";
        TotalTime = -TotalTime;
      }
    }
    else
      Tail = "passed";
  }

  Minutes = TotalTime / 60;
  Seconds = TotalTime % 60;

  return Head @ Minutes @ "minutes and" @ Seconds @ "seconds" @ Tail;
}


// ============================================================================
// ReadListInfoPlayer
//
// For both teams, fills the ListInfoPlayer array with a list of players and
// their corresponding information and sorts that list.
// ============================================================================

function ReadListInfoPlayer()
{
  local int iInfoTeam;
  local int iInfoPlayer;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  local PlayerReplicationInfo PlayerReplicationInfo;

  for (iInfoTeam = 0; iInfoTeam < ArrayCount(InfoTeam); iInfoTeam++)
    InfoTeam[iInfoTeam].ListInfoPlayer.Length = 0;

  firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag) {
    iInfoTeam = thisTagPlayer.GetTeam().TeamIndex;

    iInfoPlayer = InfoTeam[iInfoTeam].ListInfoPlayer.Length;
    InfoTeam[iInfoTeam].ListInfoPlayer.Length = InfoTeam[iInfoTeam].ListInfoPlayer.Length + 1;

    PlayerReplicationInfo = thisTagPlayer.GetPlayerReplicationInfo();
    InfoTeam[iInfoTeam].ListInfoPlayer[iInfoPlayer].Name  = PlayerReplicationInfo.PlayerName;
    InfoTeam[iInfoTeam].ListInfoPlayer[iInfoPlayer].Score = PlayerReplicationInfo.Score;
    InfoTeam[iInfoTeam].ListInfoPlayer[iInfoPlayer].Info  = Class'JBInterfaceScores'.Static.GetInfoScores(thisTagPlayer);
  }

  for (iInfoTeam = 0; iInfoTeam < ArrayCount(InfoTeam); iInfoTeam++)
    SortListInfoPlayer(InfoTeam[iInfoTeam].ListInfoPlayer, 0, InfoTeam[iInfoTeam].ListInfoPlayer.Length - 1);
}


// ============================================================================
// SortListInfoPlayer
//
// Sorts the given array of player infos, using a QuickSort implementation.
// ============================================================================

function SortListInfoPlayer(out array<TInfoPlayer> ListInfoPlayer, int iInfoPlayerStart, int iInfoPlayerEnd)
{
  local int iInfoPlayerLeft;
  local int iInfoPlayerRight;
  local TInfoPlayer InfoPlayerMiddle;
  local TInfoPlayer InfoPlayerSwapped;

  if (iInfoPlayerStart >= iInfoPlayerEnd)
    return;

  iInfoPlayerLeft  = iInfoPlayerStart;
  iInfoPlayerRight = iInfoPlayerEnd;

  InfoPlayerMiddle = ListInfoPlayer[(iInfoPlayerStart + iInfoPlayerEnd) / 2];

  while (iInfoPlayerLeft < iInfoPlayerRight) {
    while (iInfoPlayerLeft  < iInfoPlayerEnd   && IsInfoPlayerInOrder(ListInfoPlayer[iInfoPlayerLeft], InfoPlayerMiddle))  iInfoPlayerLeft  += 1;
    while (iInfoPlayerStart < iInfoPlayerRight && IsInfoPlayerInOrder(InfoPlayerMiddle, ListInfoPlayer[iInfoPlayerRight])) iInfoPlayerRight -= 1;

    if (iInfoPlayerLeft < iInfoPlayerRight) {
      InfoPlayerSwapped                = ListInfoPlayer[iInfoPlayerLeft];
      ListInfoPlayer[iInfoPlayerLeft]  = ListInfoPlayer[iInfoPlayerRight];
      ListInfoPlayer[iInfoPlayerRight] = InfoPlayerSwapped;
    }

    iInfoPlayerLeft  += 1;
    iInfoPlayerRight -= 1;
  }

  SortListInfoPlayer(ListInfoPlayer, iInfoPlayerStart, iInfoPlayerRight);
  SortListInfoPlayer(ListInfoPlayer, iInfoPlayerLeft,  iInfoPlayerEnd);
}


// ============================================================================
// IsInfoPlayerInOrder
//
// Checks whether the two given player info variables are in the correct order
// for the scoreboard. If both match, they are considered not to be in the
// right order for the sake of the sorting algorithm.
// ============================================================================

function bool IsInfoPlayerInOrder(TInfoPlayer InfoPlayer1, TInfoPlayer InfoPlayer2)
{
  return (InfoPlayer1.Score >  InfoPlayer2.Score ||
         (InfoPlayer1.Score == InfoPlayer2.Score &&
            InfoPlayer1.Name < InfoPlayer2.Name));
}


// ============================================================================
// EscapeHTML
//
// Escapes characters with a special meaning in HTML.
// ============================================================================

function string EscapeHTML(coerce string Text)
{
  Level.ReplaceText(Text, "<",  "&lt;");
  Level.ReplaceText(Text, ">",  "&gt;");
  Level.ReplaceText(Text, "&",  "&amp;");
  Level.ReplaceText(Text, "\"", "&quot;");

  return Text;
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  PathSourceImages    = "JailbreakWebScoreboard";
  PathSourceTemplates = "JailbreakWebScoreboard";
  PathSourceStyles    = "JailbreakWebScoreboard";

  FileTemplateScoreboard   = "scoreboard.htm";
  FileTemplateRow          = "scoreboard_row.inc";
  FileTemplateMutators     = "scoreboard_mutators.inc";
  FileTemplateMutatorsNone = "scoreboard_mutators_none.inc";

  InfoTeam[0] = (VarTemplateName="TeamNameRed",VarTemplateScore="TeamScoreRed",VarTemplateHeaderLines="HeaderLinesRed",VarTemplateEntry="EntryRed",FileTemplateEntry="scoreboard_entry_red.inc",FileTemplateEntryNone="scoreboard_entry_none_red.inc");
  InfoTeam[1] = (VarTemplateName="TeamNameBlue",VarTemplateScore="TeamScoreBlue",VarTemplateHeaderLines="HeaderLinesBlue",VarTemplateEntry="EntryBlue",FileTemplateEntry="scoreboard_entry_blue.inc",FileTemplateEntryNone="scoreboard_entry_none_blue.inc");
}
