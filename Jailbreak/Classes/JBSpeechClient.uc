// ============================================================================
// JBSpeechClient
// Copyright 2004 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBSpeechClient.uc,v 1.1 2004/02/29 21:01:29 mychaeel Exp $
//
// Parses and interprets a speech sequence definition and plays it.
// 
// A speech sequence definition is a whitespace-separated list of sound
// object names which are played one after each other in the order they appear
// in the list. In addition, you can add the following extra control tokens:
//
//   (tag: ...)   Conditional. The sequence following the colon within the
//                parentheses is played only if the tag is included in the
//                comma-separated tag list passed to the Parse function. Tags
//                are case-insensitive. Whitespace around tags in the list is
//                not permitted.
//
//   +...ms       Inserts a pause before playing the next sound in the
//   +...%        sequence. If a percentage is given, it relates to the
//                duration of the last sound segment which was played.
//
//   -...ms       Inserts a negative pause before playing the next sound in
//   -...%        the sequence; in other words, the next sound overlaps the
//                one preceding it. As the entire sequence definition is
//                parsed at once before anything is played, you can completely
//                reorder the time line of sounds played if you like.
//
//   @...ms       Moves the time pointer to the specified time so that the
//                next sound segment will be played at exactly that time. It
//                is possible to use a percentage with this statement as well,
//                but it still relates to the duration of last sound played.
//
// Whitespace between tokens is generally ignored other than serving as a
// token separator. The parser dumps a diagnostic error message into the log
// file when a syntax error is encountered.
// ============================================================================


class JBSpeechClient extends JBSpeech
  notplaceable;


// ============================================================================
// Variables
// ============================================================================

var private array<TSegment> ListSegment;   // sound segment timeline
var private bool bParsingSucceeded;        // parsing yielded valid timeline
var private int iSegmentPlayed;            // last played segment
var private float DelayPlayed;             // delay between segments

var transient string DefinitionOriginal;   // unaltered original definition
var transient string DefinitionRemainder;  // definition during parsing


// ============================================================================
// Parse
//
// Parses and interprets a segmented speech definition and plays it. The given
// space-separated list of tags is used to evaluate conditional sections
// within the definition. Returns whether the definition was successfully
// parsed. This function is not reentrant.
// ============================================================================

simulated singular function bool Parse(string Definition, optional string Tags)
{
  local float Time;
  local int iCharParenOpen;
  local int iCharParenClose;
  local int iSegment;
  local int nLevelEntered;
  local int nLevelSkipped;
  local int Pause;
  local string Direction;
  local string Identifier;
  local string Tag;
  local string Unit;
  local JBSpeechManager SpeechManager;
  local TSegment Segment;

  SpeechManager = JBSpeechManager(Owner);

  if (SpeechManager == None) {
    Log("JBSpeechClient not owned by JBSpeechManager. Unable to parse:" @ Definition, 'JBSpeech');
    return False;
  }
  
  DefinitionOriginal  = Definition;
  DefinitionRemainder = Definition;
  
  iSegment = -1;
  ListSegment.Length = 0;

  bParsingSucceeded = False;
  
  while (True) {
    DefinitionRemainder = TrimWhitespaceBefore(DefinitionRemainder);
    if (DefinitionRemainder == "")
      break;
    
    switch (Left(DefinitionRemainder, 1)) {
    
      // ==================================================
      // opening parenthesis starts conditional clause
      // ==================================================
    
      case "(":
        DefinitionRemainder = TrimWhitespaceBefore(DefinitionRemainder, 1);

        if (!IsCharIdentifier(Left(DefinitionRemainder, 1)))
          return ErrorOnParsing("Invalid tag in conditional clause");
        Tag = ParseIdentifier(DefinitionRemainder);
        DefinitionRemainder = TrimWhitespaceBefore(DefinitionRemainder);

        if (Left(DefinitionRemainder, 1) != ":")
          return ErrorOnParsing("Expected \":\" after tag in conditional clause");
        DefinitionRemainder = TrimWhitespaceBefore(DefinitionRemainder, 1);
        
        if (IsStringInList(Tag, Tags)) {
          nLevelEntered += 1;
        }

        else {
          nLevelSkipped = 1;
          while (nLevelSkipped > 0) {
            iCharParenOpen  = InStr(DefinitionRemainder, "(");
            iCharParenClose = InStr(DefinitionRemainder, ")");
            
            if (iCharParenClose < 0) {
              DefinitionRemainder = "";
              return ErrorOnParsing("Missing \")\" at end of definition");
            }
            
            if (iCharParenOpen >= 0 && iCharParenClose > iCharParenOpen)
                   { nLevelSkipped += 1; DefinitionRemainder = Mid(DefinitionRemainder, iCharParenOpen  + 1); }
              else { nLevelSkipped -= 1; DefinitionRemainder = Mid(DefinitionRemainder, iCharParenClose + 1); }
          }
        }
        
        break;


      // ==================================================
      // closing parenthesis ends conditional clause
      // ==================================================

      case ")":
        if (nLevelEntered == 0)
          return ErrorOnParsing("Unexpected \")\" outside conditional clause");

        nLevelEntered -= 1;
        DefinitionRemainder = Mid(DefinitionRemainder, 1);
        break;


      // ==================================================
      // pause, overlap or set
      // ==================================================

      case "+":
      case "-":
      case "@":
        Direction = Left(DefinitionRemainder, 1);
        DefinitionRemainder = TrimWhitespaceBefore(DefinitionRemainder, 1);
        
        if (!IsCharNumber(Left(DefinitionRemainder, 1)))
          return ErrorOnParsing("Number expected, non-numeric character found");
        Pause = ParseNumber(DefinitionRemainder);
        DefinitionRemainder = TrimWhitespaceBefore(DefinitionRemainder);
        
        Unit = Left(DefinitionRemainder, 1);
        if (IsCharIdentifier(Unit))
          Unit = ParseIdentifier(DefinitionRemainder);
        else
          DefinitionRemainder = Mid(DefinitionRemainder, 1);
        
        if (!IsStringInList(Unit, "%,ms"))
          return ErrorOnParsing("Unit \"%\" or \"ms\" expected", Unit);

        if (Unit == "%") {
          if (iSegment < 0)
            return ErrorOnParsing("Relative unit \"%\" not supported at start of sequence", Unit);
          Pause *= ListSegment[iSegment].Duration * 10.0;
        }
        
             if (Direction == "+") Time += Pause / 1000.0;
        else if (Direction == "-") Time -= Pause / 1000.0;
        else if (Direction == "@") Time  = Pause / 1000.0;
        break;


      // ==================================================
      // sound identifier
      // ==================================================

      default:
        if (!IsCharIdentifier(Left(DefinitionRemainder, 1)))
          return ErrorOnParsing("Identifier expected, invalid character found");
        Identifier = ParseIdentifier(DefinitionRemainder);

        Segment = SpeechManager.GetSegment(Identifier);
        if (Segment.Sound == None)
          return ErrorOnParsing("Invalid identifier; sound object not found", Identifier);

        if (iSegment < 0)
          iSegment = 0;
        while (iSegment > 0                  && ListSegment[iSegment - 1].Time >  Time) iSegment--;
        while (iSegment < ListSegment.Length && ListSegment[iSegment    ].Time <= Time) iSegment++;
        
        ListSegment.Insert(iSegment, 1);
        ListSegment[iSegment] = Segment;
        ListSegment[iSegment].Time = Time;

        Time += Segment.Duration + Class'JBSpeechManager'.Default.DefaultPause;
        break;
    }
  }

  if (nLevelEntered > 0)
    return ErrorOnParsing("Missing \")\" at end of definition");

  bParsingSucceeded = True;
  return True;
}


// ============================================================================
// ErrorOnParsing
//
// Outputs a parser error message into the log indicating the place where the
// parsing error occurred. Uses the global variables DefinitionOriginal and
// DefinitionRemainder. Returns false.
// ============================================================================

simulated function bool ErrorOnParsing(string Message, optional string DefinitionRollback)
{
  local int LengthIndentation;
  local string Chunk;
  local string Indentation;
  
  Chunk = "-";
  LengthIndentation = Len(DefinitionOriginal)
                    - Len(DefinitionRemainder)
                    - Len(DefinitionRollback);

  while (LengthIndentation > 0) {
    if ((LengthIndentation & 1) == 1)
      Indentation = Indentation $ Chunk;
    
    LengthIndentation = LengthIndentation >> 1;
    if (LengthIndentation > 0)
      Chunk = Chunk $ Chunk;
  }

  Log("Parser error:" @ Message, 'JBSpeech');
  Log("  " $ DefinitionOriginal, 'JBSpeech');
  Log("  " $ Indentation $ "^",  'JBSpeech');
  
  return False;
}


// ============================================================================
// IsStringInList
//
// Checks whether the given string is present in the given comma-separated
// list of strings. Both string and list are case-insensitive.
// ============================================================================

static function bool IsStringInList(string Tag, string List)
{
  return (InStr("," $ Caps(List) $ ",",
                "," $ Caps(Tag)  $ ",") >= 0);
}


// ============================================================================
// ParseNumber
//
// Assuming that the given string starts with a numeric character, finds the
// end of the number, removes it from the string and returns its value.
// ============================================================================

static final function int ParseNumber(out string String)
{
  local int nCharNumber;
  local int Number;
  
  for (nCharNumber = 1; nCharNumber < Len(String); nCharNumber++)
    if (!IsCharNumber(Mid(String, nCharNumber, 1)))
      break;
  
  Number = int(Left(String, nCharNumber));
  String =     Mid (String, nCharNumber);
  
  return Number;
}


// ============================================================================
// ParseIdentifier
//
// Assuming that the given string starts with an identifier character, finds
// the end of that identifier, removes it from the string and returns the
// identifier.
// ============================================================================

static final function string ParseIdentifier(out string String)
{
  local int nCharIdentifier;
  local string Identifier;
  
  for (nCharIdentifier = 1; nCharIdentifier < Len(String); nCharIdentifier++)
    if (!IsCharIdentifier(Mid(String, nCharIdentifier, 1)))
      break;
  
  Identifier = Left(String, nCharIdentifier);
  String     = Mid (String, nCharIdentifier);
  
  return Identifier;
}


// ============================================================================
// TrimWhitespace
//
// Trims leading and trailing whitespace from the given string and returns
// the trimmed string.
// ============================================================================

static final function string TrimWhitespace(string String)
{
  return TrimWhitespaceBefore(TrimWhitespaceAfter(String));
}


// ============================================================================
// TrimWhitespaceBefore
//
// Trims leading whitespace from the given string and returns the trimmed
// string without the leading whitespace. Optionally skips additional chars
// at the string start.
// ============================================================================

static final function string TrimWhitespaceBefore(string String, optional int nCharSkip)
{
  local int nCharWhitespace;
  
  for (nCharWhitespace = nCharSkip; nCharWhitespace < Len(String); nCharWhitespace++)
    if (!IsCharWhitespace(Mid(String, nCharWhitespace, 1)))
      break;
  
  return Mid(String, nCharWhitespace);
}


// ============================================================================
// TrimWhitespaceAfter
//
// Trims trailing whitespace from the given string and returns the trimmed
// string without the trailing whitespace.
// ============================================================================

static final function string TrimWhitespaceAfter(string String)
{
  local int nCharRemainder;
  
  for (nCharRemainder = Len(String); nCharRemainder > 0; nCharRemainder--)
    if (IsCharWhitespace(Mid(String, nCharRemainder - 1, 1)))
      break;
  
  return Left(String, nCharRemainder);
}


// ============================================================================
// IsCharWhitespace
//
// Checks and returns whether the given character is whitespace.
// ============================================================================

static final function bool IsCharWhitespace(string Char)
{
  return Char == Chr( 9) ||
         Char == Chr(32);
}


// ============================================================================
// IsCharNumber
//
// Checks and returns whether the given character is part of a number.
// ============================================================================

static final function bool IsCharNumber(string Char)
{
  return (Char >= "0" && Char <= "9");
}


// ============================================================================
// IsCharIdentifier
//
// Checks and returns whether the given character is part of an identifier.
// ============================================================================

static final function bool IsCharIdentifier(string Char)
{
  return (Char >= "0" && Char <= "9") ||
         (Char >= "A" && Char <= "Z") ||
         (Char >= "a" && Char <= "z") ||
          Char == "."                 ||
          Char == "_";
}


// ============================================================================
// Play
//
// Plays a previously parsed sound sequence by entering state Playing. Fails
// if parsing failed before. Returns whether playing was successfully started.
// ============================================================================

simulated function bool Play()
{
  local PlayerController PlayerController;

  if (!bParsingSucceeded)
    return ErrorOnPlaying("No successfully parsed sequence present");

  if (Level.GetLocalPlayerController() == None)
    return ErrorOnPlaying("Unable to play sequence on dedicated servers");

  if (IsInState('Playing'))
    return ErrorOnPlaying("Sequence is playing already");

  PlayerController = Level.GetLocalPlayerController();
  if (PlayerController.AnnouncerLevel >= 2)
    GotoState('Playing');

  return True;
}


// ============================================================================
// ErrorOnPlaying
//
// Outputs an error message. Uses the global DefinitionOriginal variable if it
// is set. Returns false.
// ============================================================================

simulated function bool ErrorOnPlaying(string Message)
{
  Log("Playing error:" @ Message, 'JBSpeech');

  if (DefinitionOriginal != "")
    Log("  " $ DefinitionOriginal, 'JBSpeech');

  return False;
}


// ============================================================================
// FinishedPlaying
// delegate OnFinishedPlaying
//
// Called when playing the sequence has finished. The default implementation
// destroys this actor. Set this delegate to None in order to keep the actor
// around after playing the sequence.
// ============================================================================

simulated function FinishedPlaying(JBSpeechClient SpeechClient)
{
  SpeechClient.Destroy();
}

simulated delegate OnFinishedPlaying(JBSpeechClient SpeechClient);


// ============================================================================
// PlayAnnouncement
//
// Plays a sound segment. Replaces the PlayAnnouncement function declared in
// PlayerController in order to allow for sounds to overlap.
// ============================================================================

simulated function PlayAnnouncement(Sound Sound)
{
  local float Attenuation;
  local PlayerController PlayerController;

  PlayerController = Level.GetLocalPlayerController();
  PlayerController.LastPlaySound  = Level.TimeSeconds;
  PlayerController.LastPlaySpeech = Level.TimeSeconds;
  
  Attenuation = FClamp(0.1 + float(PlayerController.AnnouncerVolume) * 0.225, 0.2, 1.0);
  Sound = PlayerController.CustomizeAnnouncer(Sound);
  
  PlaySound(Sound, SLOT_None, Attenuation);
}


// ============================================================================
// state Playing
//
// Plays the previously parsed sound sequence. Keeps this actor aligned with
// the local player's viewpoint to ensure unclipped playback if the viewpoint
// changes during playback.
// ============================================================================

simulated state Playing
{
  // ================================================================
  // Tick
  //
  // Keeps this actor aligned with the local player's viewpoint.
  // ================================================================

  simulated event Tick(float TimeDelta)
  {
    local vector LocationViewpoint;
    local rotator RotationViewpoint;
    local Actor ActorViewpoint;
    local PlayerController PlayerController;
    
    PlayerController = Level.GetLocalPlayerController();
    PlayerController.PlayerCalcView(ActorViewpoint, LocationViewpoint, RotationViewpoint);

    if (Location != LocationViewpoint)
      SetLocation(LocationViewpoint);
  }


  // ================================================================
  // State Code
  // ================================================================

  Begin:

    for (iSegmentPlayed = 0; iSegmentPlayed < ListSegment.Length; iSegmentPlayed++) {
      PlayAnnouncement(ListSegment[iSegmentPlayed].Sound);
      
      if (iSegmentPlayed < ListSegment.Length - 1)
        DelayPlayed = ListSegment[iSegmentPlayed + 1].Time
                    - ListSegment[iSegmentPlayed    ].Time;
      else
        DelayPlayed = ListSegment[iSegmentPlayed].Duration;

      if (DelayPlayed > 0)
        Sleep(DelayPlayed * Level.TimeDilation);
    }

    OnFinishedPlaying(Self);
    GotoState('');

} // state Playing


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  OnFinishedPlaying = FinishedPlaying;
}