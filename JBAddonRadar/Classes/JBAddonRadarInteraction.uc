Class JBAddonRadarInteraction Extends Interaction;

Var JBAddonRadar Radar;

Function Bool KeyEvent(EInputKey Key, EInputAction Action, FLOAT Delta)
{
	Local String KeyBind;
	if ((Action == IST_Press) && (Key == IK_F12))
		{
	        KeyBind = ViewportOwner.Actor.ConsoleCommand("KEYNAME" @ Key);
	        KeyBind = ViewportOwner.Actor.ConsoleCommand("KEYBINDING" @ KeyBind);
		If (KeyBind ~= "ToggleRadarMap")
			Radar.bDrawRadar = !Radar.bDrawRadar;
		}
	
	Return False;
}

Function NotifyLevelChange()
{
	Master.RemoveInteraction(Self);
}

DefaultProperties
{
	bActive=True
}
