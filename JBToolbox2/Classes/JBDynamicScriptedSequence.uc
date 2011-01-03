/******************************************************************************
JBDynamicScriptedSequence

Creation date: 2010-12-28 11:53
Last change: $Id$
Copyright © 2010, Wormbo

Dynamically created UnrealScriptedSequence that is spawned by the map fixes to
improve AI behavior on certain maps.
It should be spawned during GameInfo.InitGame() and so its startup events are
called along with those of other actors in the map to ensure proper
initialization.
******************************************************************************/

class JBDynamicScriptedSequence extends UnrealScriptedSequence notplaceable;


var bool bInitialized;


function PostBeginPlay()
{
	if (bInitialized)
		Super.PostBeginPlay();
}

function BeginPlay()
{
	if (bInitialized)
		Super.BeginPlay();
}

function SetInitialState()
{
	if (!bInitialized)
		bInitialized = True;
	else
		Super.SetInitialState();
}


//=============================================================================
// Default values
//=============================================================================

defaultproperties
{
	bNoDelete = False
	bStatic   = False
}

