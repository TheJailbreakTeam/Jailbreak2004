// ============================================================================
// JBSpeech
// Copyright 2004 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Common abstract base class for segmented speech classes. Contains common
// type declarations.
// ============================================================================


class JBSpeech extends Info
  abstract
  notplaceable;


// ============================================================================
// Types
// ============================================================================

struct TSegment
{
  var Sound Sound;      // sound object
  var float Time;       // absolute starting time for this segment
  var float Duration;   // total duration of sound
};


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  RemoteRole = ROLE_SimulatedProxy;
  bOnlyRelevantToOwner = True;
}
