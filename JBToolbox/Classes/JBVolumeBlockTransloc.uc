// ============================================================================
// JBVolumeBlockTransloc
// Copyright 2004 by tarquin
// $Id: JBVolumeBlockTransloc.uc,v 1.1.2.1 2004/05/17 08:44:24 tarquin Exp $
//
// Destroys a translocator puck that tries to enter or 
// that is fired from inside.
// ============================================================================


class JBVolumeBlockTransloc extends Volume;


// ============================================================================
// Touch
// ============================================================================

simulated event Touch( Actor Other )
{
  local xEmitter MyDestroyEffect;
  
  if( TransBeacon(Other) != None ) {
    if( Level.NetMode != NM_DedicatedServer ) {
      MyDestroyEffect = Spawn(class'XEffects.SmallExplosion', self,,Other.Location);
    }
    if( Role == ROLE_Authority ) {
      Other.Destroy();
    }
  }
}


// ============================================================================
// Default properties
// ============================================================================

DefaultProperties
{
}

/*
  bClassBlocker     = True;
  BlockedClasses[0] = Class'XWeapons.TransBeacon';
  
  
re Volume: Use the Touch/Untouch events. That won't slow things down.

There, for instance, you could make "simulated event Touch" to have 
it spawn the puff of smoke client-side. Just take care only 
to *destroy* the transloc target *server-side*.



*/