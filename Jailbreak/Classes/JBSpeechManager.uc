// ============================================================================
// JBSpeechManager
// Copyright 2004 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Provides certain management functions for segmented speech output.
// ============================================================================


class JBSpeechManager extends JBSpeech
  config
  notplaceable;


// ============================================================================
// Types
// ============================================================================

struct TCacheSegment
{
  var string Identifier;
  var TSegment Segment;
};


// ============================================================================
// Configuration
// ============================================================================

var config string DefaultPackage;   // default package for sound objects
var config float DefaultPause;      // default pause between segments


// ============================================================================
// Variables
// ============================================================================

var private array<TCacheSegment> ListCacheSegment;   // segment cache


// ============================================================================
// SpawnFor
//
// Finds or spawns and returns a JBSpeechManager object for the given level.
// ============================================================================

static function JBSpeechManager SpawnFor(LevelInfo Level)
{
  local JBSpeechManager thisSpeechManager;

  foreach Level.DynamicActors(Class'JBSpeechManager', thisSpeechManager)
    return thisSpeechManager;

  return Level.Spawn(Class'JBSpeechManager', Level.GetLocalPlayerController());
}


// ============================================================================
// PlayFor
//
// Plays the given sequence definition for the local player in the given level.
// Returns whether playing the sequence was successfully started.
// ============================================================================

static function bool PlayFor(LevelInfo Level, string Definition, optional string Tags)
{
  local JBSpeechManager SpeechManager;
  
  SpeechManager = Static.SpawnFor(Level);
  return SpeechManager.Play(Definition, Tags);
}


// ============================================================================
// Play
//
// Spawns a JBSpeechClient actor, parses the sequence definition and starts
// playing it. Returns whether playing the sequence was started successfully.
// ============================================================================

simulated function bool Play(string Definition, optional string Tags)
{
  local JBSpeechClient SpeechClient;
  
  SpeechClient = Spawn(Class'JBSpeechClient', Self);
  
  if (SpeechClient.Parse(Definition, Tags) &&
      SpeechClient.Play())
    return True;
  
  SpeechClient.Destroy();
  return False;
}


// ============================================================================
// GetSegment
//
// Returns the segment corresponding to the given identifier. Uses the cache
// if possible, and caches the retrieved segment for future use.
// ============================================================================

simulated function TSegment GetSegment(string Identifier)
{
  local int iSegment;
  local TCacheSegment CacheSegment;
  
  if (InStr(Identifier, ".") < 0)
    Identifier = DefaultPackage $ "." $ Identifier;
  
  for (iSegment = 0; iSegment < ListCacheSegment.Length; iSegment++)
    if (ListCacheSegment[iSegment].Identifier ~= Identifier)
      return ListCacheSegment[iSegment].Segment;
  
  CacheSegment.Identifier = Identifier;
  CacheSegment.Segment.Sound = Sound(DynamicLoadObject(Identifier, Class'Sound'));
  
  if (CacheSegment.Segment.Sound != None)
    CacheSegment.Segment.Duration = GetSoundDuration(CacheSegment.Segment.Sound);
  
  ListCacheSegment[ListCacheSegment.Length] = CacheSegment;
  return CacheSegment.Segment;
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  DefaultPackage = "JBAudio.Speech";
  DefaultPause = -0.300;
}