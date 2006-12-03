// ============================================================================
// JBGameRulesArenaLockdown
// Copyright 2006 by Jrubzjeknf <rrvanolst@hotmail.com>
// $Id
//
// The only way to release your teammates is by winning the arena match!
// ============================================================================

class JBGameRulesArenaLockdown extends JBGameRules;

var JBInfoArena Arena;
var bool bMatchTied;

var bool bCrossBaseSpawning;
var byte SelectionMethod; // 0=FIFO, 1=Random

var protected Array<JBTagPlayer> RedPrisoners;    // All of red's prisoners
var protected Array<JBTagPlayer> BluePrisoners;   // All of blue's prisoners
var protected JBTagPlayer        RedChallenger;   // Red's arena player
var protected JBTagPlayer        BlueChallenger;  // Blue's arena player
var protected bool               bAttemptArenaMatch;

var Array<PlayerStart> PlayerStartArray;
var int TeamPlayerStartCount[2];


// ============================================================================
// NotifyRound
//
// Find the arena and jam all releases.
// ============================================================================

function NotifyRound()
{
  local JBInfoJail firstJail;
  local JBInfoJail thisJail;
  local NavigationPoint NP;

  Super.NotifyRound();

  if (Arena == None) {
    Arena = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstArena;

    if (Arena == None) {
      log("No arena found, aborting"@self);
      Destroy();
      return;
    }

    // Find all free playerstarts, and save them in an array. Also remember
    // how many free playerstarts each team has.
    if (bCrossBaseSpawning)
      for (NP = Level.NavigationPointList; NP != None; NP = NP.nextNavigationPoint)
        if (PlayerStart(NP) != None &&
           !Jailbreak(Level.Game).ContainsActorJail (NP) &&
           !Jailbreak(Level.Game).ContainsActorArena(NP)) {
          PlayerStartArray[PlayerStartArray.Length] = PlayerStart(NP);
          TeamPlayerStartCount[PlayerStart(NP).TeamNumber]++;
        }

    Arena.Tag = ''; // Prevent triggers from starting an arena match

    firstJail = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstJail;

    for (thisJail = firstJail; thisJail != None; thisJail = thisJail.nextJail) {
      thisJail.Jam(0);
      thisJail.Jam(1);
    }
  }

  if (bCrossBaseSpawning)
    MixUpPlayerStarts();

  // in case of leftovers.
  RedPrisoners .Length = 0;
  BluePrisoners.Length = 0;
}


// ============================================================================
// MixUpPlayerStarts
//
// Mixes up the free playerstarts.
// ============================================================================

function MixUpPlayerStarts()
{
  local int i, RandomTeamIndex;
  local int TeamIndexCountAssigned[2];

  for (i=0; i<PlayerStartArray.Length; i++) {
    RandomTeamIndex = Rand(2);

    // check if it's still possible to assign this team to the playerstart
    if (TeamIndexCountAssigned[RandomTeamIndex] == TeamPlayerStartCount[RandomTeamIndex])
      RandomTeamIndex = abs(RandomTeamIndex-1); // switch to other team

    TeamIndexCountAssigned[RandomTeamIndex]++;
    PlayerStartArray[i].TeamNumber = RandomTeamIndex;
  }
}


// ============================================================================
// NotifyPlayerJailed
//
// Add player to the proper Prisoner Array.
// ============================================================================

function NotifyPlayerJailed(JBTagPlayer TagPlayer)
{
  Super.NotifyPlayerJailed(TagPlayer);

  if (TagPlayer == None)
    return;

  switch(TagPlayer.GetTeam().TeamIndex) {
    case 0: RedPrisoners [RedPrisoners .Length] = TagPlayer; break;
    case 1: BluePrisoners[BluePrisoners.Length] = TagPlayer; break;
  }

  AttemptArenaMatch(TagPlayer.GetTeam());
}


// ============================================================================
// AttemptArenaMatch
//
// Tries to start an arena match.
// ============================================================================

function AttemptArenaMatch(TeamInfo Team)
{
  if (Team == None &&
      (Jailbreak(Level.Game).IsCaptured(Level.Game.GameReplicationInfo.Teams[0]) ||
       Jailbreak(Level.Game).IsCaptured(Level.Game.GameReplicationInfo.Teams[1]) )) // execution!
    return;

  if (!bAttemptArenaMatch &&
       (RedPrisoners.Length > 0 && BluePrisoners.Length > 0) &&
      !Jailbreak(Level.Game).IsCaptured(Team)) {
    if (Team == None) {
      bAttemptArenaMatch = True;
      bMatchTied = True;
      SetTimer(1, True); //looping, because the match ends after the arena players return to their jails
    } else
      if (Arena.GetStateName() == 'Waiting')
        SetTimer(1, False);
  }
}

// ============================================================================
// Timer
//
// Start an ArenaMatch. Removes arena players from their Prisoners Arrau.
// The added delay is to make sure someone who is running in and out of jail
// all the time triggers messages. 1 second should cut it.
// ============================================================================

event Timer()
{
  if (bMatchTied &&
      Arena.GetStateName() != 'Waiting') { // looping
    return;
  }

  RedChallenger  = FindChallenger(RedPrisoners);
  BlueChallenger = FindChallenger(BluePrisoners);

  /*RedChallenger  = FindRedChallenger();
  BlueChallenger = FindBlueChallenger();*/

  if (RedChallenger != None && BlueChallenger != None) {
    RemoveRedPrisonerFromArray (RedChallenger);
    RemoveBluePrisonerFromArray(BlueChallenger);
    Arena.MatchInit(RedChallenger.GetController(), BlueChallenger.GetController());
  }

  bAttemptArenaMatch = False;

  if (bMatchTied) {
    bMatchTied = False;
    SetTimer(0, False);
  }
}


// ============================================================================
// FindChallenger
//
// Find a challenger in the given array.
// break down the Prisoners array if humans are favored for an arena match.
// Loop from the end to the start and bump humans to the top of the array, so
// the chronological order is perserved, only then split up in humans and bots.
// ============================================================================

function JBTagPlayer FindChallenger(array<JBTagPlayer> Prisoners)
{
  local int i, RandomPick;
  local int HumanCount;
  local string s;

  for (i=0; i<Prisoners.Length; i++)
    s @= Prisoners[i].GetController().GetHumanReadableName();
  log(Jailbreak(Level.Game).bFavorHumansForArena@"BEFORE:"@s);
  s = "";

  if (Jailbreak(Level.Game).bFavorHumansForArena)
    for (i=0; i<Prisoners.Length; i++) {
      if (Prisoners[i] != None &&
          Prisoners[i].GetController() != None) {
        if (PlayerController(Prisoners[i].GetController()) != None) { // Human!
          Prisoners.Insert(0,1);
          Prisoners[HumanCount] = Prisoners[i+1];
          HumanCount++;
          Prisoners.Remove(i+1,1);
        }
      } else { // No JBTagPlayer or Controller - remove from the array
        Prisoners.Remove(i, 1);
        i--;
      }
    }


  for (i=0; i<Prisoners.Length; i++)
    s @= Prisoners[i].GetController().GetHumanReadableName();
  log(Jailbreak(Level.Game).bFavorHumansForArena@"after :"@s);



  // find a challenger
  switch (SelectionMethod) { // 0=FIFO, 1=Random
    case 0:
      while (Prisoners.Length > 0) {
        if (HumanCount > 0)
          RandomPick = Rand(HumanCount);
        else
          RandomPick = Rand(Prisoners.Length);

        if (ValidateChallenger(Prisoners[RandomPick].GetController()))
          return Prisoners[RandomPick];
        else
          Prisoners.Remove(RandomPick, 1);
      } break;

    case 1:
      for (i=0; i<Prisoners.Length; i++)
        if (ValidateChallenger(Prisoners[i].GetController()))
          return Prisoners[i];
  }

  return None;
}


/*function JBTagPlayer FindBlueChallenger()
{
  local int i;

  for (i=0; i<BluePrisoners.Length; i++) {
    if (BluePrisoners[i] == None ||
        BluePrisoners[i].GetController() == None) {
      BluePrisoners.Remove(i, 1);
      i--;
      continue;
    }
    if (ValidateChallenger(BluePrisoners[i].GetController()))
      return BluePrisoners[i];
  }

  return None;
}*/


// ============================================================================
// ValidateChallenger
//
// Whether or not the challenger can actually enter the Arena.
// ============================================================================

function bool ValidateChallenger(Controller Challenger)
{
  return (Arena.CanFight(Challenger) && !Arena.IsExcluded(Challenger));
}


// ============================================================================
// NotifyArenaEnd
//
// Release the winner's team. Add the loser(s) to the array again
// ============================================================================

function NotifyArenaEnd(JBInfoArena Arena, JBTagPlayer TagPlayerWinner)
{
  local JBInfoJail firstJail;
  local JBInfoJail thisJail;

  if (TagPlayerWinner != None) //not a tie
  {
    firstJail = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstJail;

    for (thisJail = firstJail; thisJail != None; thisJail = thisJail.nextJail)
      thisJail.ForceRelease(TagPlayerWinner.GetTeam(), TagPlayerWinner.GetController());
  } else
    AttemptArenaMatch(None);

    Super.NotifyArenaEnd(Arena, TagPlayerWinner);
}


// ============================================================================
// NotifyPlayerReleased
//
// Remove player from the correct Prisoners Array.
// ============================================================================

function NotifyPlayerReleased(JBTagPlayer TagPlayer, JBInfoJail Jail)
{
  switch(TagPlayer.GetTeam().TeamIndex) {
    case 0: RemoveRedPrisonerFromArray (TagPlayer); break;
    case 1: RemoveBluePrisonerFromArray(TagPlayer); break;
  }

  Super.NotifyPlayerReleased(TagPlayer, Jail);
}


// ============================================================================
// RemoveRedPrisoner / RemoveBluePrisoner
//
// Remove player from the Prisoners Array.
// ============================================================================

function RemoveRedPrisonerFromArray(JBTagPlayer TagPlayer)
{
  local int i;

  for (i=0; i<RedPrisoners.Length; i++)
    if (RedPrisoners[i] == TagPlayer) {
      RedPrisoners.Remove(i, 1);
      return;
    }
}


function RemoveBluePrisonerFromArray(JBTagPlayer TagPlayer)
{
  local int i;

  for (i=0; i<BluePrisoners.Length; i++)
    if (BluePrisoners[i] == TagPlayer) {
      BluePrisoners.Remove(i, 1);
      return;
    }
}


// ============================================================================
// RemoveRedPrisoner / RemoveBluePrisoner
//
// Remove player from the Prisoners Array.
// ============================================================================

function NotifyJailClosed(JBInfoJail Jail, TeamInfo Team)
{
  AttemptArenaMatch(Team);

  Super.NotifyJailClosed(Jail, Team);
}
