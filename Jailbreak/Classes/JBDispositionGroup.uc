// ============================================================================
// JBDispositionGroup
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Manages the disposition of a group of players on a team. Takes care of
// their visual arrangement of the icons on the screen and of drawing them.
// ============================================================================


class JBDispositionGroup extends Object
  abstract;


// ============================================================================
// Variables
// ============================================================================

var protected JBDispositionTeam DispositionTeam;
var protected GameReplicationInfo GameReplicationInfo;

var protected int nPlayersRequired;
var protected array<JBDispositionPlayer> ListDispositionPlayer;


// ============================================================================
// Initialize
//
// Initializes this object.
// ============================================================================

function Initialize(JBDispositionTeam DispositionTeamOwner) {

  DispositionTeam = DispositionTeamOwner;
  GameReplicationInfo = DispositionTeamOwner.Team.Level.GetLocalPlayerController().GameReplicationInfo;
  }


// ============================================================================
// AddIconForFadein
// AddIconForChange
//
// Called when an icon is added to this group either because a player joined
// or when an icon changed from another group into this one.
// ============================================================================

delegate AddIconForFadein(JBDispositionPlayer DispositionPlayer);
delegate AddIconForChange(JBDispositionPlayer DispositionPlayer);


// ============================================================================
// RemoveIconForChange
// RemoveIconForFadeout
//
// Called when an icon is removed from this group either when it changes into
// a different group or because a player left.
// ============================================================================

delegate JBDispositionPlayer RemoveIconForChange();
delegate JBDispositionPlayer RemoveIconForFadeout();


// ============================================================================
// Recount
//
// Iterates over all players and checks how many of them are part of this
// group. Call this function before calling IsIconRequired and IsIconSurplus.
// ============================================================================

function Recount() {

  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  
  nPlayersRequired = 0;
  
  firstTagPlayer = JBReplicationInfoGame(GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    if (BelongsToGroup(thisTagPlayer))
      nPlayersRequired++;
  }


// ============================================================================
// BelongsToGroup
//
// Checks and returns whether the given player belongs to this group.
// ============================================================================

function bool BelongsToGroup(JBTagPlayer TagPlayer) {

  return (TagPlayer.GetTeam() == DispositionTeam.Team);
  }


// ============================================================================
// Setup
//
// Checks and updates the target positions of all icons in this group. Must be
// implemented in subclasses.
// ============================================================================

function Setup();


// ============================================================================
// Move
//
// Moves all icons in this group.
// ============================================================================

function Move(float TimeDelta) {

  local int iDisposition;
  
  for (iDisposition = 0; iDisposition < ListDispositionPlayer.Length; iDisposition++)
    ListDispositionPlayer[iDisposition].Move(TimeDelta);
  }


// ============================================================================
// Draw
//
// Draws all icons in this group on the given canvas.
// ============================================================================

function Draw(Canvas Canvas, float ScaleGlobal) {

  local int iDisposition;
  
  for (iDisposition = 0; iDisposition < ListDispositionPlayer.Length; iDisposition++)
    ListDispositionPlayer[iDisposition].Draw(Canvas, ScaleGlobal);
  }


// ============================================================================
// IsIconRequired
// IsIconSurplus
//
// Checks and returns whether more icons are required by this group to
// represent its members, or if more icons are currently in this group than
// necessary.
// ============================================================================

function bool IsIconRequired() { return (ListDispositionPlayer.Length < nPlayersRequired); }
function bool IsIconSurplus()  { return (ListDispositionPlayer.Length > nPlayersRequired); }


// ============================================================================
// AddIconToStart
//
// Adds the given icon to the start of the list.
// ============================================================================

protected function AddIconToStart(JBDispositionPlayer DispositionPlayer) {

  ListDispositionPlayer.Insert(0, 1);
  ListDispositionPlayer[0] = DispositionPlayer;
  }


// ============================================================================
// AddIconToEnd
//
// Adds the given icon to the end of the list.
// ============================================================================

protected function AddIconToEnd(JBDispositionPlayer DispositionPlayer) {

  ListDispositionPlayer[ListDispositionPlayer.Length] = DispositionPlayer;
  }


// ============================================================================
// RemoveIconFromStart
//
// Removes one icon from the start of the list and returns a reference to it.
// ============================================================================

protected function JBDispositionPlayer RemoveIconFromStart() {

  local JBDispositionPlayer DispositionPlayer;
  
  if (ListDispositionPlayer.Length == 0)
    return None;
  
  DispositionPlayer = ListDispositionPlayer[0];
  ListDispositionPlayer.Remove(0, 1);
  
  return DispositionPlayer;
  }


// ============================================================================
// RemoveIconFromEnd
//
// Removes one icon from the end of the list and returns a reference to it.
// ============================================================================

protected function JBDispositionPlayer RemoveIconFromEnd() {

  local JBDispositionPlayer DispositionPlayer;
  
  if (ListDispositionPlayer.Length == 0)
    return None;
  
  DispositionPlayer = ListDispositionPlayer[ListDispositionPlayer.Length - 1];
  ListDispositionPlayer.Remove(ListDispositionPlayer.Length - 1, 1);
  
  return DispositionPlayer;
  }
