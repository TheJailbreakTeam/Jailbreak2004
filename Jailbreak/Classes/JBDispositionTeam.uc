// ============================================================================
// JBDispositionTeam
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBDispositionTeam.uc,v 1.2 2003/06/15 21:31:32 mychaeel Exp $
//
// Manages the icon groups of one team.
// ============================================================================


class JBDispositionTeam extends Object;


// ============================================================================
// Variables
// ============================================================================

var TeamInfo Team;

var private JBDispositionGroup DispositionGroupJail;
var private JBDispositionGroup DispositionGroupFree;
var private array<JBDispositionPlayer> ListDispositionPlayerFadeout;


// ============================================================================
// Initialize
//
// Initializes this object and creates its icon groups.
// ============================================================================

function Initialize(TeamInfo NewTeam)
{
  Team = NewTeam;

  DispositionGroupJail = new Class'JBDispositionGroupJail';  DispositionGroupJail.Initialize(Self);
  DispositionGroupFree = new Class'JBDispositionGroupFree';  DispositionGroupFree.Initialize(Self);
}


// ============================================================================
// Update
//
// Updates all icon groups and moves icons from one group to another if
// necessary. Updates the icon positions and fades out leftover icons.
// ============================================================================

function Update(float TimeDelta)
{
  local int iDisposition;

  DispositionGroupJail.Recount();
  DispositionGroupFree.Recount();

  while (DispositionGroupJail.IsIconSurplus() &&
         DispositionGroupFree.IsIconRequired())
    DispositionGroupFree.AddIconForChange(DispositionGroupJail.RemoveIconForChange());

  while (DispositionGroupFree.IsIconSurplus() &&
         DispositionGroupJail.IsIconRequired())
    DispositionGroupJail.AddIconForChange(DispositionGroupFree.RemoveIconForChange());

  while (DispositionGroupFree.IsIconSurplus()) AddIconFadeout(DispositionGroupFree.RemoveIconForFadeout());
  while (DispositionGroupJail.IsIconSurplus()) AddIconFadeout(DispositionGroupJail.RemoveIconForFadeout());

  while (DispositionGroupFree.IsIconRequired()) DispositionGroupFree.AddIconForFadein(CreateIcon());
  while (DispositionGroupJail.IsIconRequired()) DispositionGroupJail.AddIconForFadein(CreateIcon());

  for (iDisposition = ListDispositionPlayerFadeout.Length - 1; iDisposition >= 0; iDisposition--)
    if (ListDispositionPlayerFadeout[iDisposition].Fadeout(TimeDelta))
      ListDispositionPlayerFadeout.Remove(iDisposition, 1);

  DispositionGroupFree.Setup();  DispositionGroupFree.Move(TimeDelta);
  DispositionGroupJail.Setup();  DispositionGroupJail.Move(TimeDelta);
}


// ============================================================================
// Draw
//
// Draws all icons for this team on the given canvas.
// ============================================================================

function Draw(Canvas Canvas)
{
  local int iDisposition;

  for (iDisposition = 0; iDisposition < ListDispositionPlayerFadeout.Length; iDisposition++)
    ListDispositionPlayerFadeout[iDisposition].Draw(Canvas);

  DispositionGroupFree.Draw(Canvas);
  DispositionGroupJail.Draw(Canvas);
}


// ============================================================================
// CreateIcon
//
// Creates a new icon and returns a reference to it.
// ============================================================================

function JBDispositionPlayer CreateIcon()
{
  local JBDispositionPlayer DispositionPlayer;

  DispositionPlayer = new Class'JBDispositionPlayer';
  DispositionPlayer.DispositionTeam = Self;

  return DispositionPlayer;
}


// ============================================================================
// AddIconFadeout
//
// Adds an icon to the fadeout queue.
// ============================================================================

function AddIconFadeout(JBDispositionPlayer DispositionPlayer)
{
  ListDispositionPlayerFadeout[ListDispositionPlayerFadeout.Length] = DispositionPlayer;
}