//=============================================================================
// JBLlamaHeadAttachment
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id: JBLlamaHeadAttachment.uc,v 1.1 2003/07/27 18:27:39 wormbo Exp $
//
// A llama head replacing a llama's original head.
//=============================================================================


class JBLlamaHeadAttachment extends InventoryAttachment;


//=============================================================================
// Imports
//=============================================================================

#exec Obj Load File=StaticMeshes\LlamaHead.usx Package=JBAddonLlama.LlamaHead


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  DrawType=DT_StaticMesh
  StaticMesh=StaticMesh'LlamaHead'
  DrawScale=0.075
  PrePivot=(Z=60)
  AttachmentBone=head
}