// ============================================================================
// JBVolumeBlockTransloc
// Copyright 2004 by tarquin
// $Id: JBVolumeBlockTransloc.uc,v 1.2 2004/05/17 08:45:07 tarquin Exp $
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
