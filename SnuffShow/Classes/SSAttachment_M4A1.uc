class SSAttachment_M4A1 extends SSAttachmentBase;

DefaultProperties
{
	Begin Object Name=SkeletalMeshComponent0 
		SkeletalMesh=SkeletalMesh'Armas_01.ColtM4A1.M4A1'
		Scale=0.65                                                  
		Rotation=(Yaw=16384)                                     
		Translation=(X=0.0,Y=10.0,Z=-10.0)                        
	End Object

	//WeapAnimType=EWAT_Default                                       

	MuzzleFlashSocket=MuzzleFlashSocket    
	MuzzleFlashEffectTemplate=ParticleSystem'Arma.Effects.Tiro'
	//MuzzleFlashDuration=0.33;                                       
	//MuzzleFlashLightClass=class'UTGame.UTRocketMuzzleFlashLight'       
	WeaponClass=class'SSWeap_M4A1'
}
