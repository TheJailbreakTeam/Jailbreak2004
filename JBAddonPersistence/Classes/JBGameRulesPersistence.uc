// ============================================================================
// JBGameRulesPersistence
// Copyright 2006 by Mitchell Davis <mitchelld02@yahoo.com>
//
// The game rules to allow weapons and other attributes to transfer over
// into the next round.
// ============================================================================

class JBGameRulesPersistence extends JBGameRules;

// ============================================================================
// Structures
// ============================================================================
struct TPersistWeapons
{
  var class<Weapon> PersistentWeapon;
  var int PrimaryAmmo;
  var int SecondaryAmmo;
};

struct TPersistence
{
  var string Owner;
  var int Adrenaline;
  var TPersistWeapons WeaponList[16];
};

// ============================================================================
// Variables
// ============================================================================
var private array<TPersistence> CapturerList;
var private int NumCapturers;
var private bool bNewRound;

// ============================================================================
// Functoins
// ============================================================================

// ============================================================================
// PreBeginPlay
//
// This function will be called on level start-up. This will initialize all
// values and set the timer.
// ============================================================================
function PreBeginPlay()
{
  NumCapturers = 0;
  bNewRound = false;
  SetTimer(1.0, true);
  Super.PreBeginPlay();
}

// ============================================================================
// Timer
//
// This function is called every second to determine if a new round has
// started. The reason for this approach is because in the function
// NotifyRound, each Controller's Pawn has not been created at that point.
// Using this approach allows the Pawns to be created so that their weapons
// may be carried over.
// ============================================================================
function Timer()
{
  local Controller t;

  if(bNewRound && NumCapturers > 0)
  {
    for(t = Level.ControllerList; t != None; t = t.nextController)
    {
      //loop through each controller's pawn and find one that is a player
      if(t.Pawn != None && t.Pawn.GetHumanReadableName() ~= CapturerList[0].Owner)
      {
        //once we find a player, carry over all weapons for that player.
        CarryOverWeapons();
        CleanUpArray();
        bNewRound = false;
        break;
      }
    }
  }
}

// ============================================================================
// NotifyExecutionEnd
//
// Called when the execution sequence has been completed, directly before the
// next round starts.
// ============================================================================
function NotifyExecutionEnd()
{
  Super.NotifyExecutionEnd();

  bNewRound = true;
}

// ============================================================================
// NotifyPlayerJailed
//
// Called when a player enters a jail, for instance by being spawned there
// after being killed, or by being sent there after losing an arena fight, or
// by simply physically walking into it.
// ============================================================================
function NotifyPlayerJailed(JBTagPlayer TagPlayer)
{
  local JBTagTeam thisTeam;

  thisTeam = class'JBTagTeam'.static.FindFor(TagPlayer.GetTeam());

  if(thisTeam.CountPlayersJailed() == thisTeam.CountPlayersTotal())
  {
    ExtractCapturingPlayers(thisTeam.GetTeam());
  }

  Super.NotifyPlayerJailed(TagPlayer);
}

// ============================================================================
// ExtractCapturingPlayers
//
// This function will extract the pawns associated with the capturing team and
// retrieve their inventory. This information will be recorded into a
// structure to easily handle moving over inventory to the next round.
// ============================================================================
function ExtractCapturingPlayers(TeamInfo Team)
{
  local Controller thisController;

  for(thisController = Level.ControllerList; thisController != None; thisController = thisController.NextController)
  {
    if((thisController.PlayerReplicationInfo != None) &&
       (thisController.PlayerReplicationInfo.Team != Team))
    {
      AddToList(thisController);
    }
  }
}

// ============================================================================
// CarryOverWeapons
//
// Runs through the list of controllers on this level to determine who was on
// the capturing team in the previous round. If they were on that team, they
// will receive their inventory back.
// ============================================================================
function CarryOverWeapons()
{
  local int i, j;
  local Controller thisController;


  for(i = 0; i < CapturerList.Length; i++)
  {
    Log(CapturerList[i].Owner $ " is the current Capturer.");
    for(thisController = Level.ControllerList; thisController != None; thisController = thisController.NextController)
    {
      if((thisController.Pawn != None) &&
         (thisController.Pawn.GetHumanReadableName() ~= CapturerList[i].Owner))
      {
        //We will set the adrenaline first
        SetAdrenaline(thisController, CapturerList[i].Adrenaline);
        //Loop through all the weapons in the structure array and add them
        //to the Pawn.
        for(j = 0; j < 16; j++)
        {
          PersistWeapon(thisController.Pawn, CapturerList[i].WeaponList[j]);
        }
      }
    }
  }

  bNewRound = false;
}

// ============================================================================
// SetAdrenaline
//
// This function will set the current controller's adrenaline to the amount
// available from the previous round. The game already handles this, but in the
// case where a player is in mid Combo, this will make sure that the player
// receives what is left of the combo.
// ============================================================================
function bool SetAdrenaline(Controller C, int Adrenaline)
{
  C.Adrenaline = Adrenaline;

  return true;
}

// ============================================================================
// PersistWeapon
//
// This function will spawn the weapon and add the weapon to the Pawn's
// inventory.
// ============================================================================
function bool PersistWeapon(Pawn P, TPersistWeapons Weapon)
{
  local Weapon W;
  local Inventory Inv;

  if(Weapon.PersistentWeapon == None)
    return false;

  W = P.Spawn(Weapon.PersistentWeapon);

  if(W == None)
    return false;

  //if the weapon is the assault rifle, consume all ammo first, then add
  //ammunition from the Weapon structure.
  if(W.Class == class'XWeapons.AssaultRifle')
  {
    for(Inv = P.Inventory; Inv != None; Inv = Inv.Inventory)
    {
      if(Inv.Class == class'XWeapons.AssaultRifle')
      {
        Weapon(Inv).ConsumeAmmo(0, 100);
        Weapon(Inv).ConsumeAmmo(1, 4);
        Weapon(Inv).AddAmmo(Weapon.PrimaryAmmo, 0);
        Weapon(Inv).AddAmmo(Weapon.SecondaryAmmo, 1);
      }
    }
  }
  //If the weapon is the shield gun or the translocator,
  //don't add it to the inventory
  else if((W.Class == class'XWeapons.ShieldGun') ||
          (W.Class == class'XWeapons.TransLauncher'))
  {
    return true;
  }
  else
  {
    W.AddAmmo(Weapon.PrimaryAmmo, 0);
    W.ClientWeaponSet(true);    //Prevent weapons to appear funky on next round
    P.AddInventory(W);
  }

  return true;
}

// ============================================================================
// AddToList
//
// Adds information about the capturing pawns into the TPersistance structure
// to carry over into the next round.
// Param:    Capturer - The controller that is on the capturing team.
//                      Used to extract adrenaline.
// ============================================================================
function AddToList(Controller Capturer)
{
  local int i;
  local Pawn P;
  local Inventory Inv;

  P = Capturer.Pawn;

  CapturerList.Insert(NumCapturers, 1);
  CapturerList[NumCapturers].Owner = P.GetHumanReadableName();
  CapturerList[NumCapturers].Adrenaline = Capturer.Adrenaline;

  //Loop through the inventory list and extract all inventory that are weapons
  i = 0;
  for(Inv = P.Inventory; Inv != None; Inv = Inv.Inventory)
  {
    if((Inv != None) &&
       (Inv.IsA('Weapon')))
    {
      CapturerList[NumCapturers].WeaponList[i].PersistentWeapon = Weapon(Inv).Class;
      CapturerList[NumCapturers].WeaponList[i].PrimaryAmmo = Weapon(Inv).AmmoAmount(0);
      CapturerList[NumCapturers].WeaponList[i].SecondaryAmmo = Weapon(Inv).AmmoAmount(1);
    }
    i++;
  }

  NumCapturers++;     //Increment array
}

// ============================================================================
// CleanUpArray
//
// Empty out the array each round.
// ============================================================================
function CleanUpArray()
{
  if(CapturerList.Length > 0)
  {
    CapturerList.Remove(0, CapturerList.Length);
    NumCapturers = 0;
  }
}

defaultproperties
{
}
