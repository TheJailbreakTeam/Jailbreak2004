// ============================================================================
// JBGameReplicationInfo
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBGameReplicationInfo.uc,v 1.11 2003/03/16 17:38:14 mychaeel Exp $
//
// Replicated information for the entire game.
// ============================================================================


class JBGameReplicationInfo extends GameReplicationInfo
  notplaceable;


// ============================================================================
// Replication
// ============================================================================

replication {

  reliable if (Role == ROLE_Authority && bNetInitial)
    OrderNameTactics;     // updated during initialization

  reliable if (Role == ROLE_Authority)
    bIsExecuting,         // updated at beginning and end of execution sequence
    TimeMatchStarted,     // updated when the match has started
    TimeMatchStopped,     // updated when the match ends or is interrupted
    TimeMatchCorrection,  // updated once a minute and after interruptions
    ListInfoCapture,      // updated on capture
    iInfoCaptureFirst,    // updated on capture when list full
    nInfoCaptures;        // updated on capture when list not full
  }


// ============================================================================
// Types
// ============================================================================

struct TOrderName {

  var name OrderName;  // name of order passed to SetOrders
  var int iOrderName;  // index into OrderName array in class Bot
  };


struct TInfoCapture {

  var int Time;        // elapsed game time on capture
  var TeamInfo Team;   // captured team or None on tie
  };


// ============================================================================
// Variables
// ============================================================================

var bool bIsExecuting;                   // set during an execution sequence

var JBInfoArena    firstArena;           // first arena in chain
var JBInfoJail     firstJail;            // first jail in chain
var JBTagObjective firstTagObjective;    // first objective tag in chain
var JBTagPlayer    firstTagPlayer;       // first player tag in chain

var TOrderName OrderNameTactics[6];      // registered tactics order names

var private float TimeMatchStarted;      // server time of match start
var private float TimeMatchStopped;      // server time of end or interruption
var private float TimeMatchCorrection;   // correction for match interruptions

var private TInfoCapture ListInfoCapture[32];  // round-robin list of captures
var private int iInfoCaptureFirst;       // index of first used list entry
var private int nInfoCaptures;           // number of used list entries

var private JBTagClient TagClientLocal;  // used for synchronized server time


// ============================================================================
// PostBeginPlay
//
// Registers order names for the custom team tactics menu in the speech menu.
// ============================================================================

simulated event PostBeginPlay() {

  if (Role == ROLE_Authority)
    RegisterOrderNames();

  Super.PostBeginPlay();
  }


// ============================================================================
// PostNetBeginPlay
//
// On both server and client creates the linked lists for jails and arenas.
// ============================================================================

simulated event PostNetBeginPlay() {

  local JBInfoArena thisArena;
  local JBInfoJail thisJail;
  
  foreach DynamicActors(Class'JBInfoArena', thisArena) {
    thisArena.nextArena = firstArena;
    firstArena = thisArena;
    }
  
  foreach DynamicActors(Class'JBInfoJail', thisJail) {
    thisJail.nextJail = firstJail;
    firstJail = thisJail;
    }

  Super.PostNetBeginPlay();
  }


// ============================================================================
// Timer
//
// Updates the client-side match timers.
// ============================================================================

simulated event Timer() {

  if (TagClientLocal == None)
    TagClientLocal = Class'JBTagClient'.Static.FindFor(Level.GetLocalPlayerController());

  UpdateMatchTimer();

  if (Level.NetMode == NM_Client && !bTeamSymbolsUpdated)
    TeamSymbolNotify();
  }


// ============================================================================
// RegisterOrderNames
//
// Registers the order names specified in the OrderNameTactics array. Finds
// empty slots in the OrderNames array in class Bot and initializes the order
// name indices in the OrderNameTactics array.
// ============================================================================

function RegisterOrderNames() {

  local int iOrderNameBot;
  local int iOrderNameTactics;
  local Class<Bot> ClassBot;
  
  ClassBot = Class'xBot';
  
  for (iOrderNameBot = 0; iOrderNameBot < ArrayCount(ClassBot.Default.OrderNames); iOrderNameBot++)
    if (ClassBot.Default.OrderNames[iOrderNameBot] == '') {
      OrderNameTactics[iOrderNameTactics++].iOrderName = iOrderNameBot;
      if (iOrderNameTactics == ArrayCount(OrderNameTactics))
        break;
      }
  }


// ============================================================================
// StartMatchTimer
//
// Starts or restarts the client-side match timer for all clients.
// ============================================================================

function StartMatchTimer() {

  if (TimeMatchStarted == 0.0)
    TimeMatchStarted = Level.TimeSeconds;

  TimeMatchStopped = 0.0;  // unstop timer
  }


// ============================================================================
// SynchronizeMatchTimer
//
// Resynchronized the client-side match timer with the actual game time for
// all clients.
// ============================================================================

function SynchronizeMatchTimer(float TimeMatchElapsed) {

  TimeMatchElapsed *= Level.TimeDilation;

  if (TimeMatchStopped == 0.0)
    TimeMatchCorrection = TimeMatchElapsed - (Level.TimeSeconds - TimeMatchStarted);
  else
    TimeMatchCorrection = TimeMatchElapsed - (TimeMatchStopped - TimeMatchStarted);
  }


// ============================================================================
// StopMatchTimer
//
// Stops the client-side match timer for all clients. You can resume it later
// by calling StartMatchTimer again.
// ============================================================================

function StopMatchTimer() {

  TimeMatchStopped = Level.TimeSeconds;
  }


// ============================================================================
// UpdateMatchTimer
//
// Updates ElapsedTime and RemainingTime client-side. Calculates the times on
// the fly using the synchronized server time in JBTagClient as a reference.
// Sets the timer to hit the next second boundary as precisely as possible.
//
//   * If TimeMatchStarted is non-zero and TimeMatchStopped is zero, the match
//     is running and both ElapsedTime and RemainingTime are updated.
//
//   * If TimeMatchStopped is non-zero, the match has ended or has been
//     temporarily interrupted and both ElapsedTime and RemainingTime remain
//     at a fixed value.
//
// TimeMatchCorrection accounts for time spend while the match was interrupted
// like during execution sequences.
// ============================================================================

private simulated function UpdateMatchTimer() {

  local float TimeMatchElapsed;

  if (TagClientLocal == None)
    return;
  
  if (TimeMatchStarted != 0.0) {
    if (TimeMatchStopped != 0.0)
      TimeMatchElapsed = TimeMatchStopped - TimeMatchStarted;
    else
      TimeMatchElapsed = TagClientLocal.GetServerTime() - TimeMatchStarted;

    TimeMatchElapsed += TimeMatchCorrection;
    TimeMatchElapsed /= Level.TimeDilation;
    
    ElapsedTime = TimeMatchElapsed;
    if (TimeLimit > 0)
      RemainingTime = Max(0, TimeLimit * 60 - ElapsedTime);
    }

  if (TimeMatchStarted != 0.0 &&
      TimeMatchStopped == 0.0)
    SetTimer((1.0 - TimeMatchElapsed % 1.0) * Level.TimeDilation, False);
  else
    SetTimer(0.3, False);
  }


// ============================================================================
// AddCapture
//
// Records a capture in the list and replicates it to clients.
// ============================================================================

function AddCapture(int TimeCapture, TeamInfo TeamCaptured) {

  local int iInfoCapture;

  if (nInfoCaptures < ArrayCount(ListInfoCapture))
    nInfoCaptures += 1;
  else
    iInfoCaptureFirst += 1;  // overwrite oldest entry

  iInfoCapture = (iInfoCaptureFirst + nInfoCaptures - 1) % ArrayCount(ListInfoCapture);

  ListInfoCapture[iInfoCapture].Time = TimeCapture;
  ListInfoCapture[iInfoCapture].Team = TeamCaptured;
  }


// ============================================================================
// CountCaptures
//
// Returns the number of recorded captures that are present in the list.
// ============================================================================

simulated function int CountCaptures() {

  return nInfoCaptures;
  }


// ============================================================================
// GetCaptureTime
//
// Returns the capture time of the given recorded capture.
// ============================================================================

simulated function int GetCaptureTime(int iCapture) {

  local int iInfoCapture;

  if (iCapture < 0 ||
      iCapture >= nInfoCaptures)
    return -1;

  iInfoCapture = (iInfoCaptureFirst + iCapture) % ArrayCount(ListInfoCapture);
  return ListInfoCapture[iInfoCapture].Time;
  }


// ============================================================================
// GetCaptureTeam
//
// Returns the captured team of the given recorded capture.
// ============================================================================

simulated function TeamInfo GetCaptureTeam(int iCapture) {

  local int iInfoCapture;

  if (iCapture < 0 ||
      iCapture >= nInfoCaptures)
    return None;

  iInfoCapture = (iInfoCaptureFirst + iCapture) % ArrayCount(ListInfoCapture);
  return ListInfoCapture[iInfoCapture].Team;
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  OrderNameTactics[0] = (OrderName=TacticsAuto);
  OrderNameTactics[1] = (OrderName=TacticsSuicidal);
  OrderNameTactics[2] = (OrderName=TacticsAggressive);
  OrderNameTactics[3] = (OrderName=TacticsNormal);
  OrderNameTactics[4] = (OrderName=TacticsDefensive);
  OrderNameTactics[5] = (OrderName=TacticsEvasive);
  }