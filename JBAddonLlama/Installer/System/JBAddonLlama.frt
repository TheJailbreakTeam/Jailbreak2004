[Public]
Object=(Class=Class,MetaClass=Jailbreak.JBAddon,Name=JBAddonLlama.JBAddonLlama)

[JBAddonLlama]
RewardAdrenalineText="Adr�naline obtenue pour avoir tu� un lama"
RewardAdrenalineDesc="Les joueurs qui tuent un lama gagnent autant en adr�naline."
RewardHealthText="Sant� obtenue pour avoir tu� un lama"
RewardHealthDesc="Les joueurs qui tuent un lama gagnent autant en sant�."
RewardShieldText="Bouclier obtenu pour avoir tu� un lama"
RewardShieldDesc="Les joueurs qui tuent un lama gagnent autant en bouclier."
MaximumLlamaDurationText="Dur�e maximum d'une chasse au lama"
MaximumLlamaDurationDesc="Dur�e de vie maximum d'un lama. Le lama meurt s'il n'est pas tu� avant la fin de la chasse."
LlamaizeOnJailDisconnectText="Rendre lama tout prisonnier se d�connectant"
LlamaizeOnJailDisconnectDesc="Rendre lamas les joueurs qui tentent de se d�connecter pour �chapper � la prison."
FriendlyName="Chasse au Lama"
Description="Transforme les tricheurs en lamas et permet aux autres joueurs de leur faire joyeusement la chasse."

[JBDamageTypeLlamaDied]
DeathString="%o ne voulait plus jouer au lama."
FemaleSuicide="%o ne voulait plus jouer au lama femelle."
MaleSuicide="%o ne voulait plus jouer au lama."

[JBDamageTypeLlamaLaser]
DeathString="%o a �t� roti."
FemaleSuicide="%o a �t� rotie."
MaleSuicide="%o a �t� roti."

[JBDamageTypeLlamaLightning]
DeathString="%o a �t� frapp� par la foudre."
FemaleSuicide="%o a �t� frapp�e par la foudre."
MaleSuicide="%o a �t� frapp� par la foudre."

[JBGUIPanelConfigLlama]
LlamaKillRewardLabel.Caption="R�compenses pour avoir tu� un Lama :"
chkLlamaizeOnJailDisconnect.Caption="Rendre lama tout prisonnier se d�connectant"
chkLlamaizeOnJailDisconnect.Hint="Rendre lamas les joueurs qui tentent de se d�connecter pour �chapper � la prison."
trkMaximumLlamaDuration.Caption="Dur�e de la Chasse au Lama"
trkMaximumLlamaDuration.Hint="Dur�e maximum d'une chasse au lama."
trkRewardAdrenaline.Caption="Adr�naline"
trkRewardAdrenaline.Hint="Adr�naline obtenue pour avoir tu� un lama."
trkRewardHealth.Caption="Sant�"
trkRewardHealth.Hint="Sant� obtenue pour avoir tu� un lama."
trkRewardShield.Caption="Bouclier"
trkRewardShield.Hint="Bouclier obtenu pour avoir tu� un lama."

[JBLlamaHelpMessage]
HelpMessageLines[0]="Syntaxe : 'mutate llama <param�tre>' ou 'mutate unllama <nom du joueur>'"
HelpMessageLines[1]=" <param�tre> peut �tre le nom d'un joueur ou 'config' suivi d'un second param�tre."
HelpMessageLines[2]=" Des param�tres additionnels pour 'config' peuvent �tre 'health', 'shield', 'adrenaline' et 'duration', chacun suivi de sa nouvelle valeur."

[JBLlamaMessage]
TextLlamaHuntStart="Tuez %llama% et vous serez r�compens�s."
TextLlamaCaught="%llama% s'est fait choper par %killer% !"
TextLlamaDied="%llama% s'est fait sauter !"
TextLlamaDisconnected="%llama% a d�camp� !"

