//=============================================================================
// JBGameRulesLlamaHunt
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id: JBGameRulesLlamaHunt.uc,v 1.2 2003/07/26 23:24:48 wormbo Exp $
//
// The JBGameRules class for Llama Hunt used to get Jailbreak notifications.
//=============================================================================


class JBGameRulesLlamaHunt extends JBGameRules;


//=============================================================================
// variables
//=============================================================================

var private array<JBTagPlayer> PlayersKilledByLlama;  // list of players recently killed by a llama
var private PlayerController   LlamaSuicidedLast;     // a llama dying through 'Suicided' might try to reconnect


//=============================================================================
// delegate OnLlamaReconnect
//
// Called when a llama reconnects to get out of jail.
//=============================================================================

delegate OnLlamaReconnect(PlayerController ControllerPlayer);


//=============================================================================
// PreventDeath
//
// Saves a reference to the PlayerController of a llama dying through damage
// type 'Suicided'.
//=============================================================================

function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> damageType, vector HitLocation)
{
  if ( PlayerController(Killed.Controller) != None && damageType == class'Suicided'
      && Killed.FindInventoryType(class'JBLlamaTag') != None ) {
    LlamaSuicidedLast = PlayerController(Killed.Controller);
    SetTimer(0.1, False); // will reset LlamaSuicidedLast to None
  }
  return Super.PreventDeath(Killed,Killer, damageType,HitLocation);
}


//=============================================================================
// Timer
//
// Resets LlamaSuicidedLast so only suicides belonging to a disconnect are
// checked in NotifyPlayerDisconnect().
//=============================================================================

function Timer()
{
  LlamaSuicidedLast = None;
}


//=============================================================================
// NotifyPlayerDisconnect
//
// Make sure llamas and players about to be llamaized stay llamas when they
// reconnect.
//=============================================================================

function NotifyPlayerDisconnect(PlayerController ControllerPlayer, out byte bIsLlama)
{
  log("Disconnect:"@ControllerPlayer@ControllerPlayer.Pawn);
  
  if ( bIsLlama == 0 && ControllerPlayer == LlamaSuicidedLast )
    bIsLlama = 1;
  
  if ( bIsLlama == 0 && ControllerPlayer.Pawn == None
      && IsLlamaPending(class'JBTagPlayer'.static.FindFor(ControllerPlayer.PlayerReplicationInfo)) )
    bIsLlama = 1;
  
  //log(Level.TimeSeconds@"NotifyPlayerDisconnect"@ControllerPlayer@bIsLlama);
  Super.NotifyPlayerDisconnect(ControllerPlayer, bIsLlama);
}


//=============================================================================
// NotifyPlayerReconnect
//
// Checks whether the disconnecting player is jailed and marks him as llama in
// case he or she reconnects.
//=============================================================================

function NotifyPlayerReconnect(PlayerController ControllerPlayer, bool bIsLlama)
{
  if ( bIsLlama )
    OnLlamaReconnect(ControllerPlayer);
  
  Super.NotifyPlayerReconnect(ControllerPlayer, bIsLlama);
}


//=============================================================================
// OverridePickupQuery
//
// Don't allow the Llama to pick up health, armor or adrenaline.
//=============================================================================

function bool OverridePickupQuery(Pawn Other, Pickup Item, out byte bAllowPickup)
{
	if ( Item.IsA('TournamentPickup') && Other.FindInventoryType(class'JBLlamaTag') != None ) {
	  bAllowPickup = 0;
	  return true;
	}
	
	return Super.OverridePickupQuery(Other, Item, bAllowPickup);
}


//=============================================================================
// CanRelease
//
// Makes sure the Llama doesn't release his or her team mates.
//=============================================================================

function bool CanRelease(TeamInfo Team, Pawn PawnInstigator, GameObjective Objective)
{
  return Super.CanRelease(Team, PawnInstigator, Objective) && (PawnInstigator == None
      || PawnInstigator.FindInventoryType(class'JBLlamaTag') == None);
}


//=============================================================================
// CanSendToJail
//
// Makes sure players killed by the Llama aren't send to jail unless they were
// killed in jail.
//=============================================================================

function bool CanSendToJail(JBTagPlayer TagPlayer)
{
  //log(Level.TimeSeconds@"CanSendToJail"@TagPlayer@TagPlayer.GetController());
  return Super.CanSendToJail(TagPlayer) && !WasKilledByLlama(TagPlayer)
      && !IsLlamaPending(TagPlayer);
}


//=============================================================================
// ScoreKill
//
// Checks whether a player was killed by a llama so that player doesn't restart
// in jail.
//=============================================================================

function ScoreKill(Controller Killer, Controller Killed)
{
  local bool bKillerIsLlama, bKilledIsLlama;
  
  //log(Level.TimeSeconds@"ScoreKill"@Killer@Killed);
  
  bKilledIsLlama = Killed.Pawn != None && Killed.Pawn.FindInventoryType(class'JBLlamaTag') != None;
  bKillerIsLlama = Killer != None && Killer.Pawn != None && Killer.Pawn.FindInventoryType(class'JBLlamaTag') != None;
  
  if ( bKillerIsLlama && !bKilledIsLlama )
    KilledByLlama(Killed);
  else if ( bKilledIsLlama ) {
    if ( !bKillerIsLlama && Killer != None )
      ScoreLlamaKill(Killer, Killed);
    else
      LlamaSuicided(Killed);
  }
  
  Super.ScoreKill(Killer, Killed);
}


//=============================================================================
// KilledByLlama
//
// The player was killed by a llama. Prevent respawning him/her in jail later.
//=============================================================================

protected function KilledByLlama(Controller Killer)
{
  //log(Level.TimeSeconds@"KilledByLlama"@Killer);
  PlayersKilledByLlama[PlayersKilledByLlama.Length] = class'JBTagPlayer'.static.FindFor(Killer.PlayerReplicationInfo);
}


//=============================================================================
// ScoreLlamaKill
//
// Awards adrenaline and (if the pawn is alive) health to the llama killer.
//=============================================================================

protected function ScoreLlamaKill(Controller Killer, Controller Killed)
{
  Killer.AwardAdrenaline(class'JBAddonLlama'.default.RewardAdrenaline);
  if ( Killer.Pawn != None )
    Killer.Pawn.GiveHealth(class'JBAddonLlama'.default.RewardHealth, Min(199, Killer.Pawn.HealthMax * 2.0));
  
  BroadcastLocalizedMessage(class'JBLlamaMessage', 2, Killed.PlayerReplicationInfo, Killer.PlayerReplicationInfo);
}


//=============================================================================
// LlamaSuicided
//
// The llama suicided.
//=============================================================================

protected function LlamaSuicided(Controller Killed)
{
  BroadcastLocalizedMessage(class'JBLlamaMessage', 3, Killed.PlayerReplicationInfo);
}


//=============================================================================
// CanSendToArena
//
// Makes sure Llamas aren't allowed to fight for their freedom in the arena.
//=============================================================================

function bool CanSendToArena(JBTagPlayer TagPlayer, JBInfoArena Arena)
{
  if ( TagPlayer.GetPawn() != None && TagPlayer.GetPawn().FindInventoryType(class'JBLlamaTag') != None )
    return false;
  else
    return Super.CanSendToArena(TagPlayer, Arena);
}


//=============================================================================
// WasKilledByLlama
//
// Returns whether a player was killed by a llama.
//=============================================================================

protected function bool WasKilledByLlama(JBTagPlayer TagPlayer)
{
  local int i;

  //log(Level.TimeSeconds@"WasKilledByLlama"@TagPlayer@TagPlayer.GetController());
  
  for (i = 0; i < PlayersKilledByLlama.Length; i++) {
    log(PlayersKilledByLlama[i]);
    if ( PlayersKilledByLlama[i] == TagPlayer ) {
      PlayersKilledByLlama.Remove(i, 1);
      return true;
    }
  }
  
  return false;
}


//=============================================================================
// IsLlamaPending
//
// Returns whether a player will restart as llama.
//=============================================================================

protected function bool IsLlamaPending(JBTagPlayer TagPlayer)
{
  local JBLlamaPendingTag thisLlamaPendingTag;
  local Controller ControllerPlayer;
  
  ControllerPlayer = TagPlayer.GetController();
  
  if ( ControllerPlayer == None )
    return false;
  
  foreach ControllerPlayer.ChildActors(class'JBLlamaPendingTag', thisLlamaPendingTag)
    return true;
  
  return false;
}


//=============================================================================
// FindLlamaHuntRules
//
// Returns an existing JBGameRulesLlamaHunt actor or spawns and registers a new
// one if nothing was found.
//=============================================================================

static function JBGameRulesLlamaHunt FindLlamaHuntRules(Actor Requester)
{
  local JBGameRules thisJBGameRules;
  
  if ( Requester == None ) {
    // can't work without an actor reference
    Warn("No requesting actor specified.");
    return None;
  }
  
  if ( JailBreak(Requester.Level.Game) == None ) {
    // doesn't work without Jailbreak
    log("Not a Jailbreak game.", 'LlamaHunt');
    return None;
  }
  
  for (thisJBGameRules = JailBreak(Requester.Level.Game).GetFirstJBGameRules();
       thisJBGameRules != None;
       thisJBGameRules = thisJBGameRules.GetNextJBGameRules()) {
    if ( JBGameRulesLlamaHunt(thisJBGameRules) != None )
      return JBGameRulesLlamaHunt(thisJBGameRules);
  }
  
  // no JBGameRulesLlamaHunt found, spawn a new one and register it
  thisJBGameRules = Requester.Spawn(Default.Class);
  if ( Requester.Level.Game.GameRulesModifiers == None )
    Requester.Level.Game.GameRulesModifiers = thisJBGameRules;
  else
    Requester.Level.Game.GameRulesModifiers.AddGameRules(thisJBGameRules);
  
  return JBGameRulesLlamaHunt(thisJBGameRules);
}