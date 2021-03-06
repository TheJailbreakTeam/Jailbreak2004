// ============================================================================
// JBBlueWhisp
// Copyright 2006 by Jrubzjeknf <rrvanolst@hotmail.com>
// $Id$
//
// Supports nostalgia mode.
// ============================================================================


class JBBlueWhisp extends BlueWhisp;


// ============================================================================
// PostNetBeginPlay
//
// Determines the color of the whisp, depending on the defenderindex and
// ============================================================================

simulated function PostNetBeginPlay()
{
  if (Class'Jailbreak'.Default.bReverseSwitchColors) {
    mColorRange[0].R = 255;
    mColorRange[1].R = 255;
    mColorRange[0].B = 40;
    mColorRange[1].B = 40;
  }

  Super.PostNetBeginPlay();
}
