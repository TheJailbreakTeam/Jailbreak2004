// ============================================================================
// JBDefaultVoice
// Copyright 2007 by Wormbo <wormbo@planetjailbreak.com>
// $Id$
//
// Fallback class for pushing default voice pack to clients who downloaded
// Jailbreak from the game server.
// ============================================================================


class JBDefaultVoice extends Object;


// ============================================================================
// Import
// ============================================================================

#exec obj load file=JBVoiceGrrrl.uax


// ============================================================================
// Settings
// ============================================================================

var float Volume, Pause;
var Package VoicePackage;


// ============================================================================
// Macros
// ============================================================================

var string LastMan;
var string LastSecondSave;
var string TeamRed;
var string TeamBlue;
var string TeamCapturedRed;
var string TeamCapturedBlue;
var string TeamCapturedBoth;
var string TeamReleasedRed;
var string TeamReleasedBlue;
var string ArenaWarning;
var string ArenaStart;
var string ArenaCancelled;
var string ArenaEndTimeout;
var string ArenaEndWinner;
var string ArenaEndLoser;
var string GameStart;
var string GameOvertime;
var string GameOverWinnerRed;
var string GameOverWinnerBlue;
var string AddonLlamaStart;
var string AddonLlamaDisconnect;
var string AddonLlamaFragged;
var string AddonVengeanceStart;


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  // Settings
  Volume =  2.0
  Pause  = -0.150
  VoicePackage = JBVoiceGrrrl.Classic
  
  // Macros
  LastMan               = "LastMan"
  LastSecondSave        = "LastSecondSave"
  TeamRed               = "(red: TeamSelf) (blue: TeamEnemy) (spectator: TeamRed)"
  TeamBlue              = "(red: TeamEnemy) (blue: TeamSelf) (spectator: TeamBlue)"
  TeamCapturedRed       = "$TeamRed Captured"
  TeamCapturedBlue      = "$TeamBlue Captured"
  TeamCapturedBoth      = "Tied"
  TeamReleasedRed       = "$TeamRed Released"
  TeamReleasedBlue      = "$TeamBlue Released"
  ArenaWarning          = "ArenaWarning"
  ArenaStart            = "ArenaStart"
  ArenaCancelled        = "ArenaCancelled"
  ArenaEndTimeout       = "ArenaEndLoser"
  ArenaEndWinner        = "ArenaEndWinner"
  ArenaEndLoser         = "ArenaEndLoser"
  GameStart             = "GameStart"
  GameOvertime          = "GameOvertime"
  GameOverWinnerRed     = "(red: GameOverWinner) (blue: GameOverLoser) (spectator: GameOverRed)"
  GameOverWinnerBlue    = "(red: GameOverLoser) (blue: GameOverWinner) (spectator: GameOverBlue)"
  AddonLlamaStart       = "LlamaStart"
  AddonLlamaDisconnect  = "LlamaDisconnect"
  AddonLlamaFragged     = "LlamaFragged"
  AddonVengeanceStart   = "Vengeance"
}