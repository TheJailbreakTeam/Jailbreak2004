// ============================================================================
// JBRelease
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBRelease.uc,v 1.1.1.1 2002/11/16 20:35:10 mychaeel Exp $
//
// Marks a spot bots approach to release their teammates.
// ============================================================================


class JBRelease extends GameObjective
  placeable;


// ============================================================================
// Properties
// ============================================================================

var() byte Team;
var() name TagAttachJails;


// ============================================================================
// Variables
// ============================================================================

var array<JBInfoJail> ListInfoJail;  // jails opened by this release


// ============================================================================
// PostBeginPlay
//
// Initializes the ListInfoJail array. If not owned by an actor (true for
// JBRelease actors placed in the map by level designers), uses the
// TagAttachJails property; otherwise, uses the owner's Tag property to find
// attached jails. Resets the actor's owner to None afterwards.
// ============================================================================

event PostBeginPlay() {

  if (Owner == None)
    FindJails(TagAttachJails);
  else
    FindJails(Owner.Tag);
  
  SetOwner(None);
  }


// ============================================================================
// FindJails
// 
// Fills the ListInfoJail array with references to JBInfoJail actors whose Tag
// property matches the given name. If none are found, takes the value of the
// given name out of consideration.
// ============================================================================

function FindJails(name TagAttach) {

  local JBInfoJail thisJail;

  ListInfoJail.Length = 0;

  foreach DynamicActors(Class'JBInfoJail', thisJail, TagAttach)
    if (ThisJail.CanRelease(Team))
      ListInfoJail[ListInfoJail.Length] = thisJail;
  
  if (ListInfoJail.Length > 0)
    return;
  
  foreach DynamicActors(Class'JBInfoJail', thisJail)
    if (ThisJail.CanRelease(Team))
      ListInfoJail[ListInfoJail.Length] = thisJail;
  }


// ============================================================================
// CountPlayersJailed
//
// Returns the number of imprisoned players of this team in jails that can be
// opened by this release. Bot code uses this value to determine the best
// attack target for bots.
// ============================================================================

function int CountPlayersJailed() {

  local int iJail;
  local int nPlayersJailed;
  
  nPlayersJailed = 0;
  
  for (iJail = 0; iJail < ListInfoJail.Length; iJail++)
    nPlayersJailed += ListInfoJail[iJail].CountPlayers(Team);
  
  return nPlayersJailed;
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  TagAttachJails = 'JBInfoJail';
  
  RemoteRole = ROLE_SimulatedProxy;
  bStatic = False;
  bAlwaysRelevant = True;
  }