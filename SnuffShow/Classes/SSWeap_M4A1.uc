class SSWeap_M4A1 extends SSWeapBase;

DefaultProperties
{
	Begin Object Name=MySkeletalMeshComponent
		SkeletalMesh=SkeletalMesh'Armas_01.ColtM4A1.M4A1'     
		//AnimSets(0)=AnimSet'Armas_01.AK47.AK_AnimSet'
		Scale=0.65
		Rotation=(Yaw=16384)               
		Translation=(X=0.0,Y=10.0,Z=-10.0)
    End Object

	//Begin Object Class=SkeletalMeshComponent Name=PickupMesh
	//	SkeletalMesh=SkeletalMesh'Armas_01.ColtM4A1.M4A1'
	//	Scale=0.65
	//	bOnlyOwnerSee=false
	//	CastShadow=false
	//	bForceDirectLightMap=true
	//	bCastDynamicShadow=false
	//	CollideActors=false
	//	BlockRigidBody=false
	//	MaxDrawDistance=6000
	//	bForceRefPose=1
	//	bUpdateSkelWhenNotRendered=false
	//	bIgnoreControllersWhenNotRendered=true
	//	bAcceptsStaticDecals=FALSE
	//	bAcceptsDynamicDecals=FALSE
	//End Object
	//DroppedPickupMesh=PickupMesh
	//PickupFactoryMesh=PickupMesh
	//PivotTranslation=(Y=-25.0)

	AttachmentClass=class'SSAttachment_M4A1'

	InstantHitMomentum(0)=+1000.0                                
    WeaponFireTypes(0)=EWFT_InstantHit

	InstantHitDamage(0)=40                                       
    FireInterval(0)=+0.12                                      
    InstantHitDamageTypes(0)=class'DmgType_Crushed'

	//FireCameraAnim=CameraAnim'fx_hiteffects.DamageViewShake'

	EquipTime=+0.6                                               
    PutDownTime=+0.45 
	ReloadTime=+2.0

	AmmoCount=30
	MaxAmmoCount=90

	RecoilCount=150

	MuzzleFlashSocket=MuzzleFlashSocket
	MuzzleFlashEffectTemplate=ParticleSystem'Arma.Effects.Tiro'
	MuzzleFlashDuration=0.45

	FireSound=SoundCue'Armas_01.ColtM4A1.M4A1_Shoot_Cue'
	EmptySound=SoundCue'KismetGame_Assets.Sounds.S_WeaponPickup_01_Cue'

	//ImpactHit=MaterialInstanceTimeVarying'WP_FlakCannon.Decals.MITV_WP_FlakCannon_Impact_Decal01'

	//DecalWidth=32.0
	//DecalHeight=32.0
	//DecalDissolveParamName="DissolveAmount"
	//DurationOfDecal=20.0

	CrosshairTexture=Texture2D'UI_HUD.HUD.UTCrossHairs'
	CrosshairRelativeSize=0.0425
	CrosshairU=64
	CrosshairV=0
	CrosshairUL=64
	CrosshairVL=64
	CrosshairColor=(R=255,G=255,B=255,A=255)
}
