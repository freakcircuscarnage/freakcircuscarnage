class SSWeap_AK47 extends SSWeapBase;

DefaultProperties
{
	 Begin Object Name=MySkeletalMeshComponent
		SkeletalMesh=SkeletalMesh'Armas_01.AK47.AK47'     
		//AnimSets(0)=AnimSet'Armas_01.AK47.AK_AnimSet'
		Scale=0.6
		Rotation=(Yaw=16384)               
		Translation=(X=0.0,Y=10.0,Z=-10.0)
    End Object

	//Begin Object Class=SkeletalMeshComponent Name=PickupMesh
	//	SkeletalMesh=SkeletalMesh'Armas_01.AK47.AK47' 
	//	Scale=0.6
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

	AttachmentClass=class'SSAttachment_AK47'

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

	InventoryGroup=1

	MuzzleFlashSocket=MuzzleFlashSocket
	MuzzleFlashEffectTemplate=ParticleSystem'Armas_01.AK47.AK47_MuzzleEffect'
	MuzzleFlashDuration=0.45

	FireSound=SoundCue'Armas_01.AK47.AK47_SingleShot_Cue'
	EmptySound=SoundCue'KismetGame_Assets.Sounds.S_WeaponPickup_01_Cue'

	//ImpactHit=MaterialInstanceTimeVarying'WP_FlakCannon.Decals.MITV_WP_FlakCannon_Impact_Decal01'

	//DecalWidth=32.0
	//DecalHeight=32.0
	//DecalDissolveParamName="DissolveAmount"
	//DurationOfDecal=20.0

	CrosshairTexture=Texture2D'UI_HUD.HUD.UTCrossHairs'
	CrosshairRelativeSize=0.0425
	CrosshairU=128
	CrosshairV=0
	CrosshairUL=64
	CrosshairVL=64
	CrosshairColor=(R=255,G=255,B=255,A=255)
}
