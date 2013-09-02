class SSAttachmentBase extends Actor
	hidecategories(Movement, Display, Attachment, Collision, Physics, Advanced, Debug, Mobile, Object)
	dependson(SSPawn);

//var protected SkeletalMeshComponent OverlayMesh;

struct native MaterialHitImpactEffect
{
	var(Weapon) name MaterialType;
	var(Weapon) SoundCue Sound;
	var(Weapon) ParticleSystem ParticleTemplate;
};

var SkeletalMeshComponent OwnerMesh;
var class<SSWeapBase> WeaponClass;
var UDKParticleSystemComponent MuzzleFlashEffect, MuzzleFlashEffect2;
var MaterialInstanceConstant AttachHiddenMat;
var float DistFactorForRefPose;

var(Weapon) SkeletalMeshComponent Mesh;
var(Weapon) int IndexHiddenMat;
var(Weapon) ParticleSystem MuzzleFlashEffectTemplate, MuzzleFlashEffectTemplate2;
var(Weapon) Name /*AttachmentSocket,*/ MuzzleFlashSocket, MuzzleFlashSocket2, HiddenMatName, WeapReloadAnim, WeapFireAnim;
var(Weapon) array<MaterialHitImpactEffect> ImpactEffects;
var(Weapon) ParticleSystem BloodEffect;
var(Weapon) SoundCue PawnHitSound;
var(Weapon) EWeapAnimType WeapAnimType;

var(Decal) MaterialInterface ImpactHit;
var(Decal) Name DecalDissolveParamName;
var(Decal) float DecalWidth, DecalHeight, DurationOfDecal;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();

	SetTimer(1.0, TRUE, 'CheckToForceRefPose');

	if(Mesh != None)
	{
		AttachHiddenMat = Mesh.CreateAndSetMaterialInstanceConstant(IndexHiddenMat); 
	}
}
function SetSkin(Material NewMaterial)
{
	local int i,Cnt;

	if(NewMaterial == None)	// Clear the materials
	{
		if(default.Mesh.Materials.Length > 0)
		{
			Cnt = Default.Mesh.Materials.Length;
			for (i=0;i<Cnt;i++)
			{
				Mesh.SetMaterial(i, Default.Mesh.GetMaterial(i));
			}
		}
		else if(Mesh.Materials.Length > 0)
		{
			Cnt = Mesh.Materials.Length;
			for (i=0; i < Cnt; i++)
			{
				Mesh.SetMaterial(i,none);
			}
		}
	}
	else
	{
		if(default.Mesh.Materials.Length > 0 || mesh.GetNumElements() > 0)
		{
			Cnt = default.Mesh.Materials.Length > 0 ? default.Mesh.Materials.Length : mesh.GetNumElements();
			for (i=0; i < Cnt; i++)
			{
				Mesh.SetMaterial(i,NewMaterial);
			}
		}
	}

	if(NewMaterial == None && Mesh != None)
	{
		Mesh.SetMaterial(IndexHiddenMat, AttachHiddenMat);
	}
}

simulated function AttachToPawn(SSPawn OwnerPawn)
{
	//local SSWeapBase SW;
	//SetWeaponOverlayFlags(OwnerPawn);

	if(OwnerPawn.Mesh != None)
	{
		// Attach Weapon mesh to player skelmesh
		if(Mesh != None)
		{
			OwnerMesh = OwnerPawn.Mesh;
			//AttachmentSocket = OwnerPawn.WeaponSocket;

			// Weapon Mesh Shadow
			Mesh.SetShadowParent(OwnerPawn.Mesh);
			Mesh.SetLightEnvironment(OwnerPawn.LightEnvironment);

			//if (OwnerPawn.ReplicatedBodyMaterial != None)
			//{
			//	SetSkin(OwnerPawn.ReplicatedBodyMaterial);
			//}

			//if(OwnerPawn.Weapon != none)
			//{
			//	SW = SSWeapBase(OwnerPawn.Weapon);
			//	MuzzleFlashSocket = SW.MuzzleFlashSocket;

			//	Mesh.SetSkeletalMesh(SkeletalMeshComponent(SW.Mesh).SkeletalMesh);
			//	Mesh.SetScale(SW.Mesh.Scale);
			//	Mesh.SetTranslation(SW.Mesh.Translation);
			//	Mesh.SetRotation(SW.Mesh.Rotation);
			//}

			OwnerPawn.Mesh.AttachComponentToSocket(Mesh, OwnerPawn.WeaponSocket);
		}

		//if (OverlayMesh != none)
		//{
		//	OwnerPawn.Mesh.AttachComponentToSocket(OverlayMesh, OwnerPawn.WeaponSocket);
		//}
	}

	//if (OwnerPawn.ReplicatedBodyMaterial != None)
	//{
	//	SetSkin(OwnerPawn.ReplicatedBodyMaterial);
	//	WorldInfo.Game.Broadcast(self, "AttachSkin");
	//}

	if(MuzzleFlashSocket != '')
	{
		//MuzzleFlashEffectTemplate = SW.MuzzleFlashEffectTemplate;

		if(MuzzleFlashEffectTemplate != None)
		{
			MuzzleFlashEffect = new(self) class'UDKParticleSystemComponent';
			MuzzleFlashEffect.bAutoActivate = false;
			//MuzzleFlashEffect.SetOwnerNoSee(true);
			Mesh.AttachComponentToSocket(MuzzleFlashEffect, MuzzleFlashSocket);
			MuzzleFlashEffect.SetTemplate(MuzzleFlashEffectTemplate);
		}
	}

	if(MuzzleFlashSocket2 != '')
	{
		//MuzzleFlashEffectTemplate = SW.MuzzleFlashEffectTemplate;

		if(MuzzleFlashEffectTemplate2 != None)
		{
			MuzzleFlashEffect2 = new(self) class'UDKParticleSystemComponent';
			MuzzleFlashEffect2.bAutoActivate = false;
			//MuzzleFlashEffect.SetOwnerNoSee(true);
			Mesh.AttachComponentToSocket(MuzzleFlashEffect2, MuzzleFlashSocket2);
			MuzzleFlashEffect2.SetTemplate(MuzzleFlashEffectTemplate2);
		}
	}

	OwnerPawn.SetWeapAnimType(WeapAnimType);

	GotoState('CurrentlyAttached');
}

state CurrentlyAttached
{
}

simulated function DetachToPawn(SkeletalMeshComponent MeshCpnt)
{
	//SetSkin(None);

	// Weapon Mesh Shadow
	if(Mesh != None)
	{
		Mesh.SetShadowParent(None);
		Mesh.SetLightEnvironment(None);
		// muzzle flash effects
		if(MuzzleFlashEffect != None)
		{
			Mesh.DetachComponent(MuzzleFlashEffect);
		}
		if(MuzzleFlashEffect2 != None)
		{
			Mesh.DetachComponent(MuzzleFlashEffect2);
		}
	}
	if(MeshCpnt != None)
	{
		// detach weapon mesh from player skelmesh
		if(Mesh != None)
		{
			MeshCpnt.DetachComponent(mesh);
		}

		//if (OverlayMesh != none)
		//{
		//	MeshCpnt.DetachComponent(OverlayMesh);
		//}
	}

	GotoState('');
}

simulated function PlayMuzzleEffect()
{
	if(MuzzleFlashEffect != none)
		MuzzleFlashEffect.ActivateSystem();

	if(MuzzleFlashEffect2 != none)
		MuzzleFlashEffect2.ActivateSystem();

	if(WeapFireAnim != '')
		PlayWeapAnim(WeapFireAnim);
	
	//if(AttachHiddenMat != none)
	//	AttachHiddenMat.SetScalarParameterValue(HiddenMatName, 0);
}

simulated function StopMuzzleEffect()
{
	if(MuzzleFlashEffect != none)
		MuzzleFlashEffect.DeactivateSystem();

	if(MuzzleFlashEffect2 != none)
		MuzzleFlashEffect2.DeactivateSystem();
}

simulated function MaterialHitImpactEffect GetImpactEffect(PhysicalMaterial HitMaterial)
{
	local int i;
	local UTPhysicalMaterialProperty PhysicalProperty;

	if(HitMaterial != None)
		PhysicalProperty = UTPhysicalMaterialProperty(HitMaterial.GetPhysicalMaterialProperty(class'UTPhysicalMaterialProperty'));

	if(PhysicalProperty != None && PhysicalProperty.MaterialType != 'None')
	{
		i = ImpactEffects.Find('MaterialType', PhysicalProperty.MaterialType);
		if (i != -1)
		{
			return ImpactEffects[i];
		}
	}

	return ImpactEffects[0];
}

simulated function PlayImpactEffects(ImpactInfo Impact)
{
	local MaterialInstanceTimeVarying MITV_Decal;
	local MaterialHitImpactEffect ImpactEffect;
	local SSPawn P;

	P = SSPawn(Owner);

	if((P != None) && EffectIsRelevant(Impact.HitLocation, false, 4000))
	{
		if(MaterialInstanceTimeVarying(ImpactHit) != none)
		{
			MITV_Decal = new(self) class'MaterialInstanceTimeVarying';
			MITV_Decal.SetParent(ImpactHit);
			WorldInfo.MyDecalManager.SpawnDecal(MITV_Decal, Impact.HitLocation, rotator(-Impact.HitNormal), DecalWidth, DecalHeight, 10.0, FALSE);
			MITV_Decal.SetScalarStartTime(DecalDissolveParamName, DurationOfDecal);
		}

		if(SSPawn(Impact.HitActor) != None)
		{
			//if(!SSMapInfo(WorldInfo.GetMapInfo()).bAllowFriendlyFire && 
			//	Pawn(Impact.HitActor).PlayerReplicationInfo.Team == Instigator.PlayerReplicationInfo.Team);

			//else
			//{
				if(BloodEffect != None)
					WorldInfo.MyEmitterPool.SpawnEmitter(BloodEffect, Impact.HitLocation, Rotator(Impact.HitNormal));

				if(PawnHitSound != none)
					PlaySound(PawnHitSound, true,,, Impact.HitLocation);
			//}
		}

		else if(Impact.HitActor != none)
		{
			ImpactEffect = GetImpactEffect(Impact.HitInfo.PhysMaterial);

			if(ImpactEffect.ParticleTemplate != none)
				WorldInfo.MyEmitterPool.SpawnEmitter(ImpactEffect.ParticleTemplate, Impact.HitLocation, Rotator(Impact.HitNormal), Impact.HitActor);

			if(ImpactEffect.Sound  != None)
				PlaySound(ImpactEffect.Sound, true,,, Impact.HitLocation);
		}
	}
}

simulated function ReloadingWeap()
{
	//if(AttachHiddenMat != none)
	//{
	//	AttachHiddenMat.SetScalarParameterValue(HiddenMatName, 1);
	//}
	//if(WeapReloadAnim != '')
	//	PlayWeapAnim(WeapReloadAnim);
}

simulated function PlayWeapAnim(name AnimName)
{
	Mesh.PlayAnim(AnimName, 0.0);
}

simulated function HiddenMatChange(float Value)
{
	if(AttachHiddenMat != none)
	{
		AttachHiddenMat.SetScalarParameterValue(HiddenMatName, Value);
	}
}

simulated function CheckToForceRefPose()
{
	if((WorldInfo.TimeSeconds - Mesh.LastRenderTime) > 1.0 || Mesh.MaxDistanceFactor < DistFactorForRefPose)
	{
		if(Mesh.bForceRefpose == 0)
		{
			Mesh.SetForceRefPose(TRUE);
		}
	}
	else
	{
		if(Mesh.bForceRefpose != 0)
		{
			Mesh.SetForceRefPose(FALSE);
		}
	}
}

//simulated function ChangeVisibility(bool bIsVisible)
//{
//	if (Mesh != None)
//	{
//		Mesh.SetHidden(!bIsVisible);
//	}

//	if (OverlayMesh != none)
//	{
//		OverlayMesh.SetHidden(!bIsVisible);
//	}
//}

DefaultProperties
{
	Begin Object class=AnimNodeSequence Name=MeshSequenceA
	End Object

	Begin Object Class=SkeletalMeshComponent Name=SkeletalMeshComponent0
		bOwnerNoSee=true
		bOnlyOwnerSee=false
		CollideActors=false
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		MaxDrawDistance=4000
		bForceRefPose=1
		bUpdateSkelWhenNotRendered=false
		bIgnoreControllersWhenNotRendered=true
		bOverrideAttachmentOwnerVisibility=true
		bAcceptsDynamicDecals=FALSE
		Animations=MeshSequenceA
		CastShadow=true
		bCastDynamicShadow=true
		bPerBoneMotionBlur=true
	End Object
	Mesh=SkeletalMeshComponent0
	//Components.Add(SkeletalMeshComponent0)

	TickGroup=TG_DuringAsyncWork
	NetUpdateFrequency=10
	RemoteRole=ROLE_None
	bReplicateInstigator=true
	//MaxImpactEffectDistance=4000.0
	//MaxFireEffectDistance=5000.0
	//bAlignToSurfaceNormal=true
	//MuzzleFlashDuration=0.3
	//MuzzleFlashColor=(R=255,G=255,B=255,A=255)
	//MaxDecalRangeSQ=16000000.0
	DistFactorForRefPose=0.14

	ImpactHit=MaterialInstanceTimeVarying'WP_FlakCannon.Decals.MITV_WP_FlakCannon_Impact_Decal01'

	DecalWidth=32.0
	DecalHeight=32.0
	DecalDissolveParamName="DissolveAmount"
	DurationOfDecal=20.0
}
