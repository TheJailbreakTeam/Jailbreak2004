/******************************************************************************
JBInteractionRadar

Creation date: 2010-12-27 00:03
Last change: $Id$
Copyright © 2010, Wormbo
Website: http://www.koehler-homepage.de/Wormbo/
Feel free to reuse this code. Send me a note if you found it helpful or want
to report bugs/provide improvements.
Please ask for permission first, if you intend to make money off reused code.
******************************************************************************/

class JBInteractionRadar extends Interaction;


//=============================================================================
// Variables
//=============================================================================

var JBAddonRadar2k4 RadarAddon;


/**
Unregister at map change.
*/
event NotifyLevelChange()
{
	RadarAddon = None;
	Master.RemoveInteraction(Self);
}


/**
Toggle the radar map on/off.
*/
exec function ToggleRadarMap()
{
	RadarAddon.bMapDisabled = !RadarAddon.bMapDisabled;
}


//=============================================================================
// Default values
//=============================================================================

defaultproperties
{
	bActive = False
}

