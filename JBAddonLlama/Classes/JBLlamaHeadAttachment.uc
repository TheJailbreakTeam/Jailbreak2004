//=============================================================================
// JBLlamaHeadAttachment
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id: JBLlamaArrow.uc,v 1.2 2003/07/26 23:24:50 wormbo Exp $
//
// A llama head replacing a llama's original head.
//=============================================================================


class JBLlamaHeadAttachment extends InventoryAttachment;


//=============================================================================
// Imports
//=============================================================================

#exec obj load file=StaticMeshes\LlamaHead.usx package=JBAddonLlama.LlamaHead


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  DrawType=DT_StaticMesh
  StaticMesh=StaticMesh'JBAddonLlama.LlamaHead.LlamaHead'
  DrawScale=0.25
  AttachmentBone=head
}