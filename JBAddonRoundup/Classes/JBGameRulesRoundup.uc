// ============================================================================
// JBGameRulesHunt
//
// The rules for the hunt add-on.
// ============================================================================
class JBGameRulesHunt extends JBGameRules;

// ============================================================================
// Variables
// ============================================================================
var byte around;

function AddGameRules(GameRules GR)
{
	around = 1;
	Super.AddGameRules(GR);
}

function NotifyExecutionCommit(TeamInfo Team)
{
	around++;
	Super.NotifyExecutionCommit(Team);
}

function int HuntingTeam()
{
	if( around % 2 == 1 )
		return 0;
	else
		return 1;
}

// ============================================================================
// CanRelease
//
// Called when a player attempts to release a team by activating a release
// switch. Returning False will prevent the release; in that case the
// objectives for this jail will remain disabled for a short time before
// they are activated again.
// ============================================================================
function bool CanRelease(TeamInfo Team, Pawn PawnInstigator, GameObjective Objective)
{
	if( UnrealTeamInfo(PawnInstigator.GetTeam()).TeamIndex == HuntingTeam() )
		return false;
	else
  		return Super.CanRelease(Team, PawnInstigator, Objective);
}

// ============================================================================
// CanSendToJail
//
// Called when a player is about to be sent to jail by the game. Not called
// for players who simply physically enter jail or are sent back to jail after
// losing an arena fight. Returning False will restart the player in freedom.
// ============================================================================
function bool CanSendToJail(JBTagPlayer TagPlayer)
{

	if( UnrealTeamInfo(TagPlayer.GetTeam()).TeamIndex == HuntingTeam() )
	{
		JBBotTeam(UnrealTeamInfo(TagPlayer.GetTeam()).AI).SetTactics('Suicidal');
		return false;
	}
	else
		return Super.CanSendToJail(TagPlayer);
}

// ============================================================================
// CanSendToArena
//
// Called to check whether a jailed player can be sent to the given arena. If
// this function returns False during the arena countdown for a player already
// scheduled for a fight in the given arena, the match will be cancelled.
// ============================================================================
function bool CanSendToArena(JBTagPlayer TagPlayer, JBInfoArena Arena)
{
	if( (!TagPlayer.IsInJail() || TagPlayer.IsInArena() ) && UnrealTeamInfo(TagPlayer.GetTeam()).TeamIndex == 1 - HuntingTeam() )
		return false;
	else if( UnrealTeamInfo(TagPlayer.GetTeam()).TeamIndex == HuntingTeam() )
    		return true;
  	else
    		return Super.CanSendToArena(TagPlayer, Arena);
}

// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
}
