class SSAttachment_AK47 extends SSAttachmentBase;

defaultproperties
{
	Begin Object Name=SkeletalMeshComponent0 
		SkeletalMesh=SkeletalMesh'Armas_01.AK47.AK47'
		Scale=0.6                                                  
		Rotation=(Yaw=16384)                                     
		Translation=(X=0.0,Y=10.0,Z=-10.0)                        
	End Object

	//WeapAnimType=EWAT_Default                                       

	MuzzleFlashSocket=MuzzleFlashSocket
	MuzzleFlashEffectTemplate=ParticleSystem'Armas_01.AK47.AK47_MuzzleEffect'
	//MuzzleFlashDuration=0.33;                                       
	//MuzzleFlashLightClass=class'UTGame.UTRocketMuzzleFlashLight'       
	WeaponClass=class'SSWeap_AK47'                         
}