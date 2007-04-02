//=============================================================================
// JBGameRulesLlamaHunt
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id: JBGameRulesLlamaHunt.uc,v 1.12 2007-02-14 09:56:42 wormbo Exp $
//
// The JBGameRules class for Llama Hunt used to get Jailbreak notifications.
//=============================================================================


class JBGameRulesLlamaHunt extends JBGameRules;


//=============================================================================
// variables
//=============================================================================

var private array<JBTagPlayer> PlayersKilledByLlama;  // list of players recently killed by a llama
var private PlayerController   LlamaSuicidedLast;     // a llama dying through 'Suicided' might try to reconnect

var JBAddonLlama MyLlamaAddon;


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
// NetDamage
//
// Prevents the llama from hurting anyone and teammates from hurting the llama.
//=============================================================================

function int NetDamage(int OriginalDamage, int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
  if (instigatedBy != None &&
     (instigatedBy.FindInventoryType(class'JBLlamaTag') != None ||
      (injured != None &&
       injured.FindInventoryType(class'JBLlamaTag') != None &&
       injured.GetTeamNum() == instigatedBy.GetTeamNum()))) {
    Momentum = vect(0,0,0);
    return 0;
  }

  return Super.NetDamage(OriginalDamage,Damage,injured,instigatedBy,HitLocation,Momentum,DamageType);
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
  //log("Disconnect:"@ControllerPlayer@ControllerPlayer.Pawn);
  if ( !class'JBAddonLlama'.default.bLlamaizeOnJailDisconnect && bIsLlama != 0 )
    bIsLlama = 0;

  if ( bIsLlama == 0 && ControllerPlayer == LlamaSuicidedLast ) {
    bIsLlama = 1;
    BroadcastLocalizedMessage(class'JBLlamaMessage', 4, ControllerPlayer.PlayerReplicationInfo);
  }

  if ( bIsLlama == 0 && class'JBAddonLlama'.static.IsLlama(ControllerPlayer) ) {
    bIsLlama = 1;
    BroadcastLocalizedMessage(class'JBLlamaMessage', 4, ControllerPlayer.PlayerReplicationInfo);
  }

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
  if ( bIsLlama && MyLlamaAddon != None )
    MyLlamaAddon.Llamaize(ControllerPlayer);

  Super.NotifyPlayerReconnect(ControllerPlayer, bIsLlama);
}


//=============================================================================
// OverridePickupQuery
//
// Don't allow the Llama to pick up anything.
//=============================================================================

function bool OverridePickupQuery(Pawn Other, Pickup Item, out byte bAllowPickup)
{
  if ( class'JBAddonLlama'.static.IsLlama(Other)
      && Other.PlayerReplicationInfo != None
      && !Other.PlayerReplicationInfo.bBot ) {
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
  return Super.CanRelease(Team, PawnInstigator, Objective)
      && !class'JBAddonLlama'.static.IsLlama(PawnInstigator);
}


//=============================================================================
// CanSendToJail
//
// Makes sure free players killed by the Llama aren't send to jail.
//=============================================================================

function bool CanSendToJail(JBTagPlayer TagPlayer)
{
  //log(Level.TimeSeconds@"CanSendToJail"@TagPlayer@TagPlayer.GetController());
  return Super.CanSendToJail(TagPlayer) && (!TagPlayer.IsFree()
    || !WasKilledByLlama(TagPlayer)
    && !class'JBAddonLlama'.static.IsLlama(TagPlayer));
}


//=============================================================================
// ScoreKill
//
// Checks whether a player was killed by a llama so that player doesn't restart
// in jail, if he's not on the same team as the llama.
//=============================================================================

function ScoreKill(Controller Killer, Controller Killed)
{
  local bool bKillerIsLlama, bKilledIsLlama;

  //log(Level.TimeSeconds@"ScoreKill"@Killer@Killed);

  bKilledIsLlama = class'JBAddonLlama'.static.IsLlama(Killed);
  bKillerIsLlama = class'JBAddonLlama'.static.IsLlama(Killer);

  if ( bKillerIsLlama && !bKilledIsLlama &&
       Killer.GetTeamNum() != Killed.GetTeamNum())
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
// Awards adrenaline, health and shield points to the llama killer, if he's not
// on the same team as the llama.
//=============================================================================

protected function ScoreLlamaKill(Controller Killer, Controller Killed)
{
  if (Killer.GetTeamNum() == Killed.GetTeamNum())
    return;

  Killer.AwardAdrenaline(class'JBAddonLlama'.default.RewardAdrenaline);
  if ( Killer.Pawn != None ) {
    Killer.Pawn.GiveHealth(class'JBAddonLlama'.default.RewardHealth, Min(199, Killer.Pawn.HealthMax * 2.0));
    Killer.Pawn.AddShieldStrength(class'JBAddonLlama'.default.RewardShield);
  }

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

function bool CanSendToArena(JBTagPlayer TagPlayer, JBInfoArena Arena, out byte bForceSendToArena)
{
  if ( class'JBAddonLlama'.static.IsLlama(TagPlayer) )
    return false;
  return Super.CanSendToArena(TagPlayer, Arena, bForceSendToArena);
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
    //log(PlayersKilledByLlama[i]);
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
  warn("This function should no longer be used!");
  return class'JBAddonLlama'.static.IsLlama(TagPlayer);
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
