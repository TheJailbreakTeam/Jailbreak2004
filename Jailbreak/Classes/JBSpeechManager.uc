// ============================================================================
// JBSpeechManager
// Copyright 2004 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBSpeechManager.uc,v 1.6 2004/05/30 17:00:05 mychaeel Exp $
//
// Provides certain management functions for segmented speech output.
// ============================================================================


class JBSpeechManager extends JBSpeech
  config
  notplaceable;


// ============================================================================
// Types
// ============================================================================

struct TCacheSegment                          // caches sound segments
{
  var string Identifier;                      // sound segment identifier
  var array<TSegment> ListSegment;            // loaded sound segments
};


struct TCacheSetting                          // caches settings
{
  var string Section;                         // name of section to look in
  var string Setting;                         // name of setting to look for
  var string Value;                           // value of the setting
};


struct TInfoVoicePack                         // info on loaded voice pack
{
  var string Package;                         // sound package
  var string Group;                           // group within sound package
  
  var float Volume;                           // volume modifier for samples
  var float Pause;                            // default pause between segments
  
  var array<TCacheSegment> ListCacheSegment;  // cached sound segments
  var array<TCacheSetting> ListCacheSetting;  // cached settings
};


// ============================================================================
// Configuration
// ============================================================================

var protected config string VoicePack;        // package name of voice pack


// ============================================================================
// Variables
// ============================================================================

var TInfoVoicePack InfoVoicePack;             // info on current voice pack
var array<TInfoVoicePack> ListInfoVoicePack;  // info on all loaded voice packs

var private array<JBSpeechClient> ListQueueSpeechClient;  // announcement queue


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
// PostBeginPlay
//
// Loads the default voice pack, if any.
// ============================================================================

simulated event PostBeginPlay()
{
  if (VoicePack != "")
    LoadVoicePack(VoicePack);
}


// ============================================================================
// GetVoicePack
//
// Returns the currently selected voice pack.
// ============================================================================

static function string GetVoicePack()
{
  return Default.VoicePack;
}


// ============================================================================
// SetVoicePack
//
// Sets the voice pack configuration option and makes all currently running
// speech managers switch to it. Input is not validated.
// ============================================================================

static function SetVoicePack(string VoicePackNew)
{
  local JBSpeechManager thisSpeechManager;

  foreach Default.Class.AllObjects(Class'JBSpeechManager', thisSpeechManager) {
    thisSpeechManager.VoicePack =   VoicePackNew;
    thisSpeechManager.LoadVoicePack(VoicePackNew);
  }

  Default.VoicePack = VoicePackNew;
  StaticSaveConfig();
}


// ============================================================================
// LoadVoicePack
//
// Loads the given voice pack. If the same voice pack was loaded once before
// already, takes it from the voice pack cache instead. Returns whether the
// voice pack was successfully loaded and activated.
// ============================================================================

simulated function bool LoadVoicePack(string VoicePackNew, optional bool bNoFallbackToDefault)
{
  local int iCharSeparator;
  local int iInfoVoicePack;
  
  if (InfoVoicePack.Package ~= VoicePackNew)
    return True;

  for (iInfoVoicePack = 0; iInfoVoicePack < ListInfoVoicePack.Length; iInfoVoicePack++)
    if (ListInfoVoicePack[iInfoVoicePack].Package ~= VoicePackNew)
      break;

  if (iInfoVoicePack < ListInfoVoicePack.Length) {
    InfoVoicePack = ListInfoVoicePack[iInfoVoicePack];
  }
  else {
    if (IsVoicePackInstalled(VoicePackNew)) {
      iCharSeparator = InStr(VoicePackNew $ ".", ".");
  
      InfoVoicePack.Package = Left(VoicePackNew, iCharSeparator);
      InfoVoicePack.Group   = Mid (VoicePackNew, iCharSeparator + 1);
      InfoVoicePack.Volume  = float(GetSetting("Settings", "Volume", 1.0));
      InfoVoicePack.Pause   = float(GetSetting("Settings", "Pause"));
      InfoVoicePack.ListCacheSegment.Length = 0;
  
      ListInfoVoicePack[iInfoVoicePack] = InfoVoicePack;
    }
    else {
      if (bNoFallbackToDefault)
        return False;
      return LoadVoicePack("JBVoiceGrrrl.Classic", True);
    }
  }

  return True;
}


// ============================================================================
// IsVoicePackInstalled
//
// Returns whether a voice pack with the given name is installed.
// ============================================================================

simulated function bool IsVoicePackInstalled(string VoicePackTest)
{
  local int iEntry;
  local string Entry;

  if (DynamicLoadObject("Jailbreak.JBVoice", Class'Class', False) == None)
    return False;

  for (iEntry = 0; True; iEntry++) {
    Entry = GetNextInt("Jailbreak.JBVoice", iEntry);
    if (Entry ~= "")            return False;
    if (Entry ~= VoicePackTest) return True; 
  }
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
// Spawns a JBSpeechClient actor, parses the sequence definition and either
// queues it if another client is currently running or starts playing it.
// Returns whether playing the sequence was started or queued successfully.
// ============================================================================

simulated function bool Play(string Definition, optional string Tags)
{
  local JBSpeechClient SpeechClient;
  
  SpeechClient = Spawn(Class'JBSpeechClient', Self);
  
  if (SpeechClient.Parse(Definition, Tags)) {
    ListQueueSpeechClient[ListQueueSpeechClient.Length] = SpeechClient;
    if (ListQueueSpeechClient.Length > 1 || SpeechClient.Play())
      return True;
  }
  
  SpeechClient.Destroy();
  return False;
}


// ============================================================================
// NotifyFinishedPlaying
//
// Called by a client when it finished playing. Starts playing the next queued
// client if any is present.
// ============================================================================

simulated function NotifyFinishedPlaying(JBSpeechClient SpeechClient)
{
  if (SpeechClient != ListQueueSpeechClient[0])
    return;
  
  ListQueueSpeechClient.Remove(0, 1);
  if (ListQueueSpeechClient.Length > 0)
    ListQueueSpeechClient[0].Play();
}


// ============================================================================
// GetSetting
//
// Reads a setting from the voice pack's localization file from the given
// section; if a group within the voice pack is used, tries to load from the
// more specific section first before falling back to the generic.
// ============================================================================

simulated function string GetSetting(string Section, string Setting, optional coerce string ValueDefault)
{
  local int iCacheSetting;
  local string Value;
  
  for (iCacheSetting = 0; iCacheSetting < InfoVoicePack.ListCacheSetting.Length; iCacheSetting++)
    if (InfoVoicePack.ListCacheSetting[iCacheSetting].Section ~= Section &&
        InfoVoicePack.ListCacheSetting[iCacheSetting].Setting ~= Setting)
      return InfoVoicePack.ListCacheSetting[iCacheSetting].Value;

  if (InfoVoicePack.Group != "")
                   Value = Localize(Section $ "." $ InfoVoicePack.Group, Setting, InfoVoicePack.Package);
  if (Value == "") Value = Localize(Section,                             Setting, InfoVoicePack.Package);
  if (Value == "") Value = ValueDefault;

  InfoVoicePack.ListCacheSetting.Insert(iCacheSetting, 1);
  InfoVoicePack.ListCacheSetting[iCacheSetting].Section = Section;
  InfoVoicePack.ListCacheSetting[iCacheSetting].Setting = Setting;
  InfoVoicePack.ListCacheSetting[iCacheSetting].Value   = Value;
    
  return Value;
}


// ============================================================================
// GetSegment
//
// Returns the segment corresponding to the given identifier. Uses the cache
// if possible, and caches the retrieved segments for future use.
// ============================================================================

simulated function TSegment GetSegment(string Identifier)
{
  local int iCacheSegment;
  local int iSegment;
  local int iSegmentLoaded;
  local string Package;
  local string Group;
  local string Suffix;
  local Sound SoundLoaded;
  local TCacheSegment CacheSegment;
  local TSegment SegmentNone;
  
  for (iCacheSegment = 0; iCacheSegment < InfoVoicePack.ListCacheSegment.Length; iCacheSegment++)
    if (InfoVoicePack.ListCacheSegment[iCacheSegment].Identifier ~= Identifier)
      break;

  if (iCacheSegment < InfoVoicePack.ListCacheSegment.Length) {
    CacheSegment = InfoVoicePack.ListCacheSegment[iCacheSegment];
  }
  else {
    CacheSegment.Identifier = Identifier;

    Package = InfoVoicePack.Package;
    Group   = InfoVoicePack.Group;

    for (iSegmentLoaded = 0; True; iSegmentLoaded++) {
      if (iSegmentLoaded == 0)
             Suffix = "";
        else Suffix = "_" $ iSegmentLoaded;

      SoundLoaded = None;
      if (InStr(Identifier, ".") >= 0)
                                 SoundLoaded = DynamicLoadSound(                              Identifier $ Suffix);
      else {
        if (Group != "")         SoundLoaded = DynamicLoadSound(Package $ "." $ Group $ "_" $ Identifier $ Suffix);
        if (SoundLoaded == None) SoundLoaded = DynamicLoadSound(Package $ "."               $ Identifier $ Suffix);
      }

      if (SoundLoaded == None)
        if (iSegmentLoaded == 0) continue;
                            else break;
  
      iSegment = CacheSegment.ListSegment.Length;
      CacheSegment.ListSegment.Insert(iSegment, 1);
      CacheSegment.ListSegment[iSegment].Sound    =                  SoundLoaded;
      CacheSegment.ListSegment[iSegment].Duration = GetSoundDuration(SoundLoaded);
    }
    
    InfoVoicePack.ListCacheSegment[iCacheSegment] = CacheSegment;
  }
  
  if (CacheSegment.ListSegment.Length == 0)
    return SegmentNone;
  
  iSegment = Rand(CacheSegment.ListSegment.Length);
  return CacheSegment.ListSegment[iSegment];
}


// ============================================================================
// DynamicLoadSound
//
// Dynamically loads a sound object with the given fully qualified name and
// returns a reference to it. Returns None if the sound object was not found.
// ============================================================================

final static function Sound DynamicLoadSound(string Name)
{
  return Sound(DynamicLoadObject(Name, Class'Sound', True));
}


// ============================================================================
// Destroyed
//
// Destroys all queued JBSpeechClient actors.
// ============================================================================

event Destroyed()
{
  while (ListQueueSpeechClient.Length > 0) {
    ListQueueSpeechClient[0].Destroy();
    ListQueueSpeechClient.Remove(0, 1);
  }
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  VoicePack = "JBVoiceGrrrl.Classic";
}