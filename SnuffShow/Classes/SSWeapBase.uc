class SSWeapBase extends UDKWeapon
	hidecategories(Movement, Display, Attachment, Collision, Physics, Advanced, Debug, Mobile, Object);
	//abstract;

var UDKParticleSystemComponent MuzzleFlashEffect;
var bool bReloading, bActiveZoom, bZoomedSniper, bMeleeAttacking;
var int ZoomDistance;
var int ReserveAmmo, LastAmmo;
var ImpactInfo TraceImpact;
var MaterialInstanceConstant AttachHiddenMat;
var bool bHoldingGrenade;
var Pawn LastPawnTarget;

var Rotator RecoilOffset, TotalRecoil, RecoilDecline;

var(Weapon) name WeaponName;
var(Weapon) Object AttachmentArchetype;
var(Weapon) class<SSAttachmentBase> AttachmentClass;
var(Weapon) class<SSDroppedMesh> DroppedMeshClass;
var(Weapon) ParticleSystem MuzzleFlashEffectTemplate;
var(Weapon) SoundCue FireSound, EmptySound;
var(Weapon) CameraAnim FireCameraAnim;
var(Weapon) name MuzzleFlashSocket, HiddenMatName;
var(Weapon) float MuzzleFlashDuration, HiddenMatTimer;
var(Weapon) int IndexHiddenMat;
var(Weapon) repnotify int CurrentAmmoCount;
var(Weapon) int MaxAmmoCount, ShotCost, RecoilCount;
var(Weapon) float RecoilInterpSpeed, MaxRecoil, RecoilDeclineSpeed, RecoilDeclinePct;
var(Weapon) float ReloadTime, ReloadedTime, ReloadAnimRate;
var(Weapon) byte InventoryGroup, IconNumber;
var(Weapon) name FireAnimName, EquipAnimName, PutDownAnimName, ReloadAnimName, WeapReloadAnim, WeapFireAnim, MeleeAttackAnimName, 
	GrenadePreLaunchAnimName, GrenadeLaunchAnimName;
var(Weapon) float GrenadeLaunchAnimTime;
var(Weapon) int MeleeDamage;
var(Weapon) bool bRadialMelee, bDrawMeleeTrace, bIsInstantHit;
var(Weapon) float MeleeDamageRadius<editcondition=bRadialMelee>;
var(Weapon) EWeaponFireType NewWeaponFireType;
var(Weapon) class<DamageType> NewInstantHitDamageType<editcondition=bIsInstantHit>;
var(Weapon) class<Projectile> NewWeaponProjectiles<editcondition=!bIsInstantHit>;
var(Weapon) float CurrentGrenadeSpeed, GrenadeTimeExplode;
var(Weapon) Name NewFiringStatesArray;
var(Weapon) bool bAllowHeadShot<editcondition=bIsInstantHit>;
var(Weapon) bool bShotgunMode<editcondition=!bIsInstantHit>;
var(Weapon) int RandRotFire<editcondition=bShotgunMode>, ProjCount<editcondition=bShotgunMode>;
var(Weapon) bool bCanThrowWeap;
var(Weapon) StaticMesh AmmoMesh;

//var(Decal) MaterialInterface ImpactHit<editcondition=bIsInstantHit>;
//var(Decal) name DecalDissolveParamName;
//var(Decal) float DecalWidth, DecalHeight, DurationOfDecal;

var(HUD) const Texture2D CrosshairTexture;
var(HUD) Texture2D SniperCrosshair<editcondition=bZoomSniper>;
var(HUD) const float CrosshairRelativeSize;
var(HUD) const float CrosshairU;
var(HUD) const float CrosshairV;
var(HUD) const float CrosshairUL;
var(HUD) const float CrosshairVL;
var(HUD) const Color CrosshairColor;
var(HUD) const Color CrosshairFriedlyColor;
var(HUD) const Color CrosshairEnemyColor;

var(Zoom) float ZoomCount, ZoomTime;
var(Zoom) bool bZoomSniper;
var(Zoom) int SniperZoomCount<editcondition=bZoomSniper>;
var(Zoom) PostProcessSettings BlurSettings;

//var ForceFeedbackWaveform WeaponFireWaveForm;

replication
{
	// Server->Client properties
	if(bNetOwner)
		ReserveAmmo, LastAmmo, CurrentAmmoCount, InventoryGroup, LastPawnTarget;
}

simulated function PostBeginPlay()
{
	local SSPawn P;

	InstantHitDamageTypes[0] = NewInstantHitDamageType;
	WeaponFireTypes[0] = NewWeaponFireType;
	WeaponProjectiles[0] = NewWeaponProjectiles;
	FiringStatesArray[0] = NewFiringStatesArray;
	ReserveAmmo = MaxAmmoCount;
	
	foreach WorldInfo.AllPawns(class'SSPawn', P)
	{
		if(P != none)
			P.SetMIC(0);
	}

	if(WorldInfo.NetMode != NM_DedicatedServer && Mesh != None)
	{
		AttachHiddenMat = Mesh.CreateAndSetMaterialInstanceConstant(IndexHiddenMat);
	}

	BlurSettings.bOverride_EnableDOF = TRUE;
	BlurSettings.bEnableDOF = true;
	BlurSettings.bOverride_DOF_BlurKernelSize = true;
	BlurSettings.DOF_BlurKernelSize = 8.0;
	BlurSettings.bOverride_DOF_FocusInnerRadius = true;
	BlurSettings.DOF_FocusInnerRadius = 500;
	BlurSettings.bOverride_DOF_MaxNearBlurAmount = TRUE;
	BlurSettings.bOverride_DOF_MaxFarBlurAmount = TRUE;
	BlurSettings.DOF_MaxNearBlurAmount = 0.95;
	BlurSettings.DOF_MaxFarBlurAmount = 0.95;
	BlurSettings.bOverride_DOF_FalloffExponent = TRUE;
	BlurSettings.DOF_FalloffExponent = 0.6;
	BlurSettings.bOverride_DOF_FocusType = TRUE;
	BlurSettings.DOF_FocusType = FOCUS_Position;
	BlurSettings.bOverride_DOF_FocusPosition = TRUE;
	BlurSettings.bOverride_DOF_InterpolationDuration = TRUE;
	BlurSettings.DOF_InterpolationDuration = 0;

	super.PostBeginPlay();
}

simulated function RenderCrosshair(HUD HUD)
{
	local float CrosshairSize;
	local float TextuteScale;

	local vector2d HUDPos;
	local Vector LookOrig, LookDir, HitLocation, HitNormal/*, TargetPos*/;
	local Actor HitActor;

	HUDPos.X = HUD.SizeX * 0.5f;
	HUDPos.Y = HUD.SizeY * 0.5f;

	HUD.Canvas.DeProject(HUDPos, LookOrig, LookDir);
	HitActor = Trace(HitLocation, HitNormal, LookOrig + LookDir*50000, LookOrig, true);
	CrosshairSize = CrosshairRelativeSize * HUD.SizeX;

	if(HitActor != none && HitActor == Pawn(HitActor) && Pawn(HitActor).Health > 0)
	{
		//if(Pawn(HitActor).PlayerReplicationInfo.Team == Instigator.PlayerReplicationInfo.Team)
		//	HUD.Canvas.DrawColor = CrosshairFriedlyColor;
		//else
		//	HUD.Canvas.DrawColor = CrosshairEnemyColor;
		//TargetPos = HUD.Canvas.Project(Pawn(HitActor).Location + ((Pawn(HitActor).GetCollisionHeight() * vect(0,0,1)) + vect(0,0,10)));
		//HUD.Canvas.SetPos(TargetPos.X, TargetPos.Y);
		//HUD.Canvas.DrawText(SSPawn(HitActor).PawnName);

		if(Pawn(HitActor).PlayerReplicationInfo.Team != Instigator.PlayerReplicationInfo.Team)
		{
			LastPawnTarget = Pawn(HitActor);
			SetTarget(LastPawnTarget);
		}
	}

	else
	{
		if(LastPawnTarget != none)
			DestroyTarget();
	}

	if(bZoomSniper)
	{
		TextuteScale = 1.1 - ((1080 - HUD.Canvas.ClipY) / 1000);

		if(bActiveZoom)
		{
			//HUDPos.X = HUD.SizeX * 0.5f;
			//HUDPos.Y = HUD.SizeY * 0.5f;

			//HUD.Canvas.DeProject(HUDPos, LookOrig, LookDir);

			//HitActor = Trace(HitLocation, HitNormal, LookOrig + LookDir*50000, LookOrig, true);

			//CrosshairSize = CrosshairRelativeSize * HUD.SizeX;

			//if(HitActor == Pawn(HitActor) && Pawn(HitActor).Health > 0 && HitActor != none)
			//{
			//	if(Pawn(HitActor).PlayerReplicationInfo.Team == Instigator.PlayerReplicationInfo.Team)
			//		HUD.Canvas.DrawColor = CrosshairFriedlyColor;
			//	else
			//		HUD.Canvas.DrawColor = CrosshairEnemyColor;
			//}
			//else
				HUD.Canvas.DrawColor = CrosshairColor;
			HUD.Canvas.SetPos((HUD.Canvas.ClipX / 2) - (960 * TextuteScale), (HUD.Canvas.ClipY / 2) - (540 * TextuteScale));
			HUD.Canvas.DrawTexture(SniperCrosshair, TextuteScale);
		}
	}

	if(HUD == None || HUD.Canvas == None || CrosshairTexture == None || CrosshairRelativeSize <= 0.f 
		|| CrosshairUL <= 0.f || CrosshairVL <= 0.f || CrosshairColor.A == 0 /*|| bActiveZoom*/)
		return;

	//HUDPos.X = HUD.SizeX * 0.5f;
	//HUDPos.Y = HUD.SizeY * 0.5f;

	//HUD.Canvas.DeProject(HUDPos, LookOrig, LookDir);

	//HitActor = Trace(HitLocation, HitNormal, LookOrig + LookDir*50000, LookOrig, true);

	//CrosshairSize = CrosshairRelativeSize * HUD.SizeX;

	//if(HitActor == Pawn(HitActor) && Pawn(HitActor).Health > 0 && HitActor != none)
	//{
	//	if(Pawn(HitActor).PlayerReplicationInfo.Team == Instigator.PlayerReplicationInfo.Team)
	//		HUD.Canvas.DrawColor = CrosshairFriedlyColor;
	//	else
	//		HUD.Canvas.DrawColor = CrosshairEnemyColor;
	//}
	//else
		HUD.Canvas.DrawColor = CrosshairColor;

	HUD.Canvas.SetPos(HUDPos.X - (CrosshairSize * 0.5f), HUDPos.Y - (CrosshairSize * 0.25f));
	HUD.Canvas.DrawTile(CrosshairTexture, CrosshairSize, CrosshairSize, CrosshairU, CrosshairV, CrosshairUL, CrosshairVL);
}

reliable client function SetTarget(Pawn P)
{
	//local MaterialInstanceConstant MIC;

	//P.Mesh.SetMaterial(0, Material'Armas_01.RPG.Rocket_RPG_Mat');
	//MIC = P.Mesh.CreateAndSetMaterialInstanceConstant(0);
	//MIC.SetScalarParameterValue('RocketHidden', 0);
	SSPawn(P).SetMIC(2);

	SetTimer(0.1, false, 'DestroyTarget');
}

reliable client function DestroyTarget()
{
	if(LastPawnTarget != none)
	{
		//LastPawnTarget.Mesh.SetMaterial(0, LastPawnTarget.default.Mesh.Materials[0]);
		SSPawn(LastPawnTarget).SetMIC(0);
		LastPawnTarget = None;
	}
}

simulated function vector InstantFireEndTrace(vector StartTrace)
{
	return StartTrace + vector(GetAdjustedAim(StartTrace)) * GetTraceRange();
}

simulated function ProcessInstantHit(byte FiringMode, ImpactInfo Impact,optional int NumHits)
{
	//local MaterialInstanceTimeVarying MITV_Decal;

	if(bAllowHeadShot)
	{
		if(SSPawn(Impact.HitActor).TakeHeadShot(Impact,Impact.HitNormal))
		{
			InstantHitDamage[0] = 150 /*default.InstantHitDamage[0] * 2.5*/;
			InstantHitDamageTypes[0] = InstantHitDamageTypes[1];
		}

		else
		{
			InstantHitDamage[0] = default.InstantHitDamage[0];
			InstantHitDamageTypes[0] = default.InstantHitDamageTypes[0];
		}
	}

	//if(MaterialInstanceTimeVarying(ImpactHit) != none)
	//{
	//	MITV_Decal = new(self) class'MaterialInstanceTimeVarying';
	//	MITV_Decal.SetParent(ImpactHit);
	//	WorldInfo.MyDecalManager.SpawnDecal(MITV_Decal, Impact.HitLocation, rotator(-Impact.HitNormal), DecalWidth, DecalHeight, 10.0, FALSE);
	//	MITV_Decal.SetScalarStartTime(DecalDissolveParamName, DurationOfDecal);
	//}

	SSPawn(Instigator).PlayImpactEffects(Impact);
	SSPawn(Instigator).ImpactTrace = Impact;

	if(SSPawn(Impact.HitActor) != none && SSPawn(Impact.HitActor).Health <= 0)
		return;
	
	super.ProcessInstantHit(FiringMode, Impact, NumHits);
}

simulated function CustomFire()
{
	PlayMeleeAttack();
}

simulated function PlayMeleeAttack()
{
	if(MeleeAttackAnimName != '')
		SSPawn(Instigator).ePlayAnim(SSPawn(Instigator).TopHalfAnimSlot, MeleeAttackAnimName, 1.0, 0.05, 0.15, false, true);

	//if(Role < ROLE_Authority)
	//{
	//	ServereJump();
	//}

	bMeleeAttacking = true;
	SetTimer(0.03, true, 'MeleeAttack');

	//WorldInfo.Game.Broadcast(self, MeleeAnim);
}

simulated function MeleeAttack()
{
    local actor traced;
	local ImpactInfo Impact;
    local vector hitlocation, hitnormal, traceEnd, traceStart, traceRadius;

	if(bRadialMelee)
	{
		 SkeletalMeshComponent(Mesh).GetSocketWorldLocationAndRotation('RadiusControl',  traceRadius);

		 if(bDrawMeleeTrace)
			DrawDebugSphere(traceRadius, MeleeDamageRadius, 20, 255,0,0);
	}

	else
	{
		SkeletalMeshComponent(Mesh).GetSocketWorldLocationAndRotation('StartControl',  traceStart);
		SkeletalMeshComponent(Mesh).GetSocketWorldLocationAndRotation('EndControl', traceEnd);

		if(bDrawMeleeTrace)
			drawdebugline(traceStart, traceEnd, 255,0,0);
	}

	if(!SSPawn(Instigator).TopHalfAnimSlot.bIsPlayingCustomAnim)
	{
		ClearTimer('MeleeAttack');
		bMeleeAttacking = false;
		SSPawn(Instigator).TopBodyRep.AnimName = '';
		return;
	}

	WeaponPlaySound(FireSound);

	if(bRadialMelee)
	{
		Foreach CollidingActors(class'actor', traced, MeleeDamageRadius, traceRadius)
		{
			if(traced != Owner && Pawn(traced) != none && SSPawn(Instigator).bReadyMeleeAttack)
			{
				Impact.HitActor = traced;
				Impact.HitLocation = traced.Location;
				Impact.HitNormal = Location - traced.Location;

				traced.TakeDamage(MeleeDamage, SSPlayerController(Instigator.Controller), traced.Location, Normal(Traced.Location - Owner.Location) * 10000, class'DmgType_Crushed');
				SSPawn(Instigator).PlayImpactEffects(Impact);
				SSPawn(Instigator).ImpactTrace = Impact;
				SSPawn(Instigator).bReadyMeleeAttack = false;
				ClearTimer('MeleeAttack');
				//break;
			}
		}
	}

	else
	{
		Foreach TraceActors(class'actor', traced, hitlocation, hitnormal, traceEnd, traceStart, vect(10,10,10))
		{
			if(traced != Owner && Pawn(traced) != none && SSPawn(Instigator).bReadyMeleeAttack)
			{
				Impact.HitActor = traced;
				Impact.HitLocation = hitlocation;
				Impact.HitNormal = hitnormal;

				traced.TakeDamage(MeleeDamage, SSPlayerController(Instigator.Controller), hitlocation, Normal(Traced.Location - Owner.Location) * 10000, class'DmgType_Crushed');
				SSPawn(Instigator).PlayImpactEffects(Impact);
				SSPawn(Instigator).ImpactTrace = Impact;
				SSPawn(Instigator).bReadyMeleeAttack = false;
				ClearTimer('MeleeAttack');
				//break;
			}
		}
	}
}

//simulated function SetInventoryGroup()
//{
//	local array<SSWeapBase> WeaponList;

//	SSInventoryManager(Instigator.InvManager).GetWeaponList(WeaponList);
//	InventoryGroup = WeaponList.Length;
//	WorldInfo.Game.Broadcast(self, self@InventoryGroup);
//}

simulated function WeaponPlaySound(SoundCue Sound)
{
	if(Sound != None && Instigator != None)
	{
		Instigator.PlaySound(Sound, false, true);
	}
}

simulated function ShakeView()
{
	local SSPlayerController PC;

	PC = SSPlayerController(Instigator.Controller);
	if(PC != None && LocalPlayer(PC.Player) != None /*&& CurrentFireMode < FireCameraAnim.length*/ && FireCameraAnim != None)
	{
		PC.PlayCameraAnim(FireCameraAnim, /*(GetZoomedState() > ZST_ZoomingOut) ? PC.GetFOVAngle() / PC.DefaultFOV :*/ 1.0);
	}

	// Play controller vibration
	//if( PC != None && LocalPlayer(PC.Player) != None )
	//{
	//	// only do rumble if we are a player controller
	//	SSPlayerController(Instigator.Controller).ClientPlayForceFeedbackWaveform(WeaponFireWaveForm);
	//}
}

simulated function AttachWeaponToPawn(Pawn NewPawn)
{
	local SSPawn SP;

	if(Mesh != None && NewPawn != None && NewPawn.Mesh != None)
	{
		SP = SSPawn(NewPawn);
		if(SP != None /*&& SP.Mesh.GetSocketByName(SP.WeaponSocket) != None*/)
		{
			//SP.Mesh.AttachComponentToSocket(Mesh, SP.WeaponSocket);
			//Mesh.SetLightEnvironment(SP.LightEnvironment);
			//Mesh.SetShadowParent(SP.Mesh);
			//SP.NewWeaponAttach = self;
			//AttachToPawn(SP);
			if(AttachmentArchetype != none && AttachmentArchetype.Class == class'SSAttachmentBase')
				SP.WeaponAttachArchetype = SSAttachmentBase(AttachmentArchetype);

			if(AttachmentClass != none)
				SP.WeaponAttachClass = AttachmentClass/*self.Class*/;

			SP.AttachWeapon();
			
			//SetSkin(SP.ReplicatedBodyMaterial);

			//InvManager.SetCurrentWeapon(Self);
			//InvManager.ServerSetCurrentWeapon(Self);

			//if (Role == ROLE_Authority && SP != None)
			//{
			//	SP.SSCurrentWeaponAttachmentClass = AttachmentClass;
			//	if (WorldInfo.NetMode == NM_ListenServer || WorldInfo.NetMode == NM_Standalone || (WorldInfo.NetMode == NM_Client && Instigator.IsLocallyControlled()))
			//	{
			//		SP.WeaponAttachmentChanged();
			//	}
			//}
		}
	}
}

simulated function AttachToPawn(Pawn NewPawn)
{
	local SSPawn SP;
		
	SP = SSPawn(NewPawn);
	if(SP != None && SP.FPMesh.GetSocketByName(SP.WeaponSocket) != None)
	{
		SP.FPMesh.AttachComponentToSocket(Mesh, SP.WeaponSocket);
		Mesh.SetLightEnvironment(SP.LightEnvironment);
		Mesh.SetShadowParent(SP.FPMesh);
	}

	if(MuzzleFlashSocket != '')
	{
		if (MuzzleFlashEffectTemplate != None)
		{
			MuzzleFlashEffect = new(self) class'UDKParticleSystemComponent';
			MuzzleFlashEffect.bAutoActivate = false;
			//MuzzleFlashEffect.SetOwnerNoSee(true);
			SkeletalMeshComponent(Mesh).AttachComponentToSocket(MuzzleFlashEffect, MuzzleFlashSocket);
			MuzzleFlashEffect.SetTemplate(MuzzleFlashEffectTemplate);
		}
	}
}

simulated function SetSkin(Material NewMaterial)
{
	local int i,Cnt;

	if(NewMaterial == None)
	{
		// Clear the materials
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
			for(i=0; i < Cnt; i++)
			{
				Mesh.SetMaterial(i, none);
			}
		}
	}
	else
	{
		// Set new material
		if(default.Mesh.Materials.Length > 0 || Mesh.GetNumElements() > 0)
		{
			Cnt = default.Mesh.Materials.Length > 0 ? default.Mesh.Materials.Length : Mesh.GetNumElements();
			for(i=0; i < Cnt; i++)
			{
				Mesh.SetMaterial(i, NewMaterial);
			}
		}
	}
}

//simulated function Tick(float DeltaTime)
//{
//	local vector MuzzleLoc;
//	local Rotator MuzzleRot;

//	SkeletalMeshComponent(Mesh).GetSocketWorldLocationAndRotation(MuzzleFlashSocket, MuzzleLoc, MuzzleRot);

//	DrawDebugSphere(MuzzleLoc, 20, 20, 255,0,0, false);

//	super.Tick(DeltaTime);

//	//WorldInfo.Game.Broadcast(self, self@MuzzleFlashEffect.bIsActive);
//}

//function ItemRemovedFromInvManager()
//{
//	DetachToPawn(Instigator, Instigator.Mesh);

//	//Destroy();

//	super.ItemRemovedFromInvManager();
//}

simulated function DetachToPawn(Pawn NewPawn, Skeletalmeshcomponent MeshCpnt)
{
	local SSPawn SP;

	MeshCpnt.DetachComponent(Mesh);
	Mesh.SetShadowParent(None);
	Mesh.SetLightEnvironment(None);
	SetHidden(true);
	SkeletalMeshComponent(Mesh).DetachComponent(MuzzleFlashEffect);

	SP = SSPawn(NewPawn);
	if(SP != None)
	{
		
		SP.WeaponAttachClass = none;
		SP.WeaponAttachArchetype = none;
		SP.AttachWeapon();
		SP.AttachHiddenMatValue = -1;

		//SP.WeaponAttachClass = none;

		//if(SP.NewWeaponAttach != none)
		//{
		//	SP.Mesh.DetachComponent(SP.NewWeaponAttach.Mesh);
		//	SP.NewWeaponAttach.Destroy();
		//}
	}
	//GotoState('');
	//SSPawn(NewPawn).WeaponAttachClass = none;
}

//simulated function AttachMuzzleFlash()
//{
//	local SkeletalMeshComponent SKMesh;

//	//bMuzzleFlashAttached = true;
//	SKMesh = SkeletalMeshComponent(Mesh);
//	if(SKMesh != none)
//	{
//		if (MuzzleFlashEffectTemplate != none)
//		{
//			SKMesh.AttachComponentToSocket(MuzzleFlashEffect, MuzzleFlashSocket);
//			MuzzleFlashEffect.SetTemplate(MuzzleFlashEffectTemplate);
//		}
//	}
//}

simulated state WeaponEquipping
{
	simulated function BeginState(Name PreviousStateName)
	{
		super.BeginState(PreviousStateName);

		if(EquipAnimName != '')
		{
			if(CurrentAmmoCount == 0 && FiringStatesArray[0] == 'GrenadeFiring')
				return;

			SSPawn(Instigator).ePlayAnim(SSPawn(Instigator).TopHalfAnimSlot, EquipAnimName, 1.0, 0.25, 0.25, false);
		}
	}

	simulated function WeaponEquipped()
	{
		if(CurrentAmmoCount == 0)
			SSPawn(Instigator).AttachHiddenMatValue = 0;

		if(bWeaponPutDown)
		{
			PutDownWeapon();
			return;
		}

		//ClearPendingFire(0);
		//ClearPendingFire(1);

		AttachWeaponToPawn(Instigator);
		//AttachMuzzleFlash();
		GotoState('Active');
		HasAmmo(0,0);
	}
}

simulated function PutDownWeapon()
{
	if(bMeleeAttacking)
		return;

	if(bReloading)
	{
		SSPawn(Instigator).ePlayAnim(SSPawn(Instigator).TopHalfAnimSlot,'', 1.0, 0.25, 0.25, false,,true);
		StopWeapAnim();

		SSPawn(Instigator).SMAmmo.SetHidden(true);
		SSPawn(Instigator).RepAmmoMesh.bHiddenAmmoMesh = true;
	}

	DetachToPawn(Instigator, SSPawn(Instigator).FPMesh);
	FinishZoom();
	ClearTimer('Reloaded');
	ClearTimer('SetHiddenMat');
	bReloading = false;
	SSPawn(Instigator).AttachHiddenMatValue = -1;
	if(PutDownAnimName != ''&& (FiringStatesArray[0] == 'GrenadeFiring' && CurrentAmmoCount > 0))
		SSPawn(Instigator).ePlayAnim(SSPawn(Instigator).TopHalfAnimSlot, PutDownAnimName, 1.0, 0.25, 0.25, false);
	super.PutDownWeapon();
}

simulated function HolderDied()
{
	FinishZoom();

	super.HolderDied();
}

//simulated function DropFrom(vector StartLocation, vector StartVelocity)
//{
//	DetachToPawn(Instigator);

//	super.DropFrom(StartLocation, StartVelocity);
//}

simulated function DropFrom(vector StartLocation, vector StartVelocity)
{
	local DroppedPickup P;

	DetachToPawn(Instigator, SSPawn(Instigator).FPMesh);

	if(Instigator != None && Instigator.InvManager != None)
	{
		Instigator.InvManager.RemoveFromInventory(Self);
	}

	// if cannot spawn a pickup, then destroy and quit
	if(/*DroppedPickupClass == None || DroppedPickupMesh == None*/DroppedMeshClass == None || CurrentAmmoCount <= 0)
	{
		Destroy();
		return;
	}

	P = Spawn(DroppedPickupClass,,, StartLocation);
	if(P == None)
	{
		Destroy();
		return;
	}

	P.SetPhysics(PHYS_Falling);
	P.Inventory	= self;
	//P.InventoryClass = class;
	SSDroppedPickup(P).WeapArchetype = DroppedMeshClass;
	P.Velocity = StartVelocity;
	P.Instigator = Instigator;
	P.SetPickupMesh(DroppedMeshClass.default.DroppedMesh);

	Instigator = None;
	GotoState('');
}

simulated function bool HasAmmo(byte FireModeNum, optional int Amount)
{
	if(CurrentAmmoCount == 0 && ReserveAmmo > 0)
	{
		if (Mesh.bAttached && !bReloading)
		{
			ReloadWeapon();
		}

		//return true;
	}

	return true;
}

simulated function ReloadWeapon()
{
	if(CurrentAmmoCount < default.CurrentAmmoCount && ReserveAmmo > 0 && !bReloading)
	{
		//if(IsFiring())
		//{
		//	EndFire(0);
		//	//SetPendingFire(0);
		//}

		//GotoState('WeaponReloading');
		bReloading = true;
		SSPawn(Instigator).bWeapReloaded = true;

		if(HiddenMatTimer > 0)
			SetTimer(HiddenMatTimer, false, 'SetHiddenMat');
		else
			SetHiddenMat();

		//if(WeapReloadAnim != '')
		//	PlayWeapAnim(WeapReloadAnim);

		SSPawn(Instigator).ReloadingWeap();

		//if(AttachHiddenMat != none)
		//	AttachHiddenMat.SetScalarParameterValue(HiddenMatName, 0);

		//SSPawn(Instigator).AttachHiddenMatValue = 0;

		FinishZoom();

		if(ReloadAnimName != '')
			SSPawn(Instigator).ePlayAnim(SSPawn(Instigator).TopHalfAnimSlot, ReloadAnimName, ReloadAnimRate, 0.15, 0.15, false, true);

		SetTimer(ReloadTime, false, 'Reloaded');
	}
}

reliable client function PlayWeapAnim(name AnimName)
{
	PlayWeaponAnimation(AnimName, 0.0);
}

reliable client function StopWeapAnim()
{
	StopWeaponAnimation();
}

simulated function Reloaded()
{
	//GotoState('Active');

	if(!bShotgunMode)
	{
		LastAmmo =  default.CurrentAmmoCount - CurrentAmmoCount;
		CurrentAmmoCount = Clamp(CurrentAmmoCount + ReserveAmmo,0, default.CurrentAmmoCount);
		ReserveAmmo = Clamp(ReserveAmmo - LastAmmo,0,default.MaxAmmoCount);
	}

	else if(CurrentAmmoCount < default.CurrentAmmoCount)
	{
		CurrentAmmoCount++;
		ReserveAmmo--;
	}

	bReloading = false;
	SSPawn(Instigator).bWeapReloaded = false;

	if(bShotgunMode)
	{
		SetTimer(ReloadTime / 2.5, false,'ReloadWeapon');
		return;
	}

	//SSPawn(Instigator).ePlayAnim(SSPawn(Instigator).TopHalfAnimSlot,'', 1.0, 0.25, 0.25, false,,true);

	if(PendingFire(0))
		GotoState(FiringStatesArray[0]);

	//if(AttachHiddenMat != none)
	//	AttachHiddenMat.SetScalarParameterValue(HiddenMatName, 1);

	//WorldInfo.Game.Broadcast(self, "ReserveAmmo"@ReserveAmmo);
}

reliable client function ClientSetHiddenMat(float Value)
{
	if(AttachHiddenMat != none)
		AttachHiddenMat.SetScalarParameterValue(HiddenMatName, Value);

	if(Value == 0)
	{
		if(AmmoMesh != none)
		{
			SSPawn(Instigator).SMAmmo.SetStaticMesh(AmmoMesh);
			SSPawn(Instigator).SMAmmo.SetHidden(false);
		}
	}

	else if(Value == 1)
	{
		if(AmmoMesh != none)
			SSPawn(Instigator).SMAmmo.SetHidden(true);
	}
}

function ConsumeAmmo(byte FireModeNum)
{
	AddAmmo(-ShotCost);
}

simulated function int AddAmmo(int Amount)
{
	CurrentAmmoCount = Clamp(CurrentAmmoCount + Amount,0,CurrentAmmoCount);
	ReserveAmmo = Clamp(ReserveAmmo + Clamp(Amount, 0, Amount),0,MaxAmmoCount);

	//if (UTInventoryManager(InvManager) == None || UTInventoryManager(InvManager).bInfiniteAmmo)
	//{
	//	if(ReserveAmmo <= 0)
	//		ReserveAmmo = MaxAmmoCount;
	//}

	return CurrentAmmoCount;
}

simulated function FireAmmunition()
{
	local Rotator ViewRotation;

	//if(AmmoCount == 0 && ReserveAmmo > 0)
	//{
	//	if (Mesh.bAttached && !bReloading)
	//		ReloadWeapon();
	//}

	/*else*/ if(CurrentAmmoCount == 0 || bReloading)
	{
		if(!bReloading)
			WeaponPlaySound(EmptySound);
		return;
	}

	if(Instigator.PhysicsVolume.bNeutralZone)
	{
		EndFire(0);
		return;
	}

	super.FireAmmunition();

	ClearTimer('ReloadWeapon');

	if(CurrentAmmoCount == 0 && ReserveAmmo == 0 && WeaponFireTypes[0] == EWFT_Projectile)
	{
		if(HiddenMatTimer > 0)
			SetTimer(HiddenMatTimer, false, 'SetHiddenMat');
		else
			SetHiddenMat();
	}

	//////////////////////// função de recoil  ///////////////////////////

	//SetWeaponRecoil(RecoilCount);

	ViewRotation = Instigator.GetViewRotation();

	ViewRotation.Pitch += RecoilCount;
	ViewRotation.Yaw += Rand(RecoilCount / 10) - Rand(RecoilCount / 10);

	SSPlayerController(Instigator.Controller).SetRotation(ViewRotation);
	/////////////////////////////////////////////////////////////////////

	ActivateMuzzleFlash();

	WeaponPlaySound(FireSound);

	if(FireAnimName != '')
		SSPawn(Instigator).ePlayAnim(SSPawn(Instigator).TopHalfAnimSlot, FireAnimName, 1.0, 0.15, 0.15, false, true);

	if(WeapFireAnim != '')
		PlayWeapAnim(WeapFireAnim);

	//PlayerController(Instigator.Controller).ClientPlayForceFeedbackWaveform(WeaponFireWaveForm);

	ShakeView();
}

simulated function SetWeaponRecoil(int PitchRecoil)
{
	local int YawRecoil;

	YawRecoil = (0.5 - FRand()) * PitchRecoil;
	RecoilOffset.Pitch += PitchRecoil;
	RecoilOffset.Yaw += YawRecoil;
}

simulated function ProcessViewRotation(float DeltaTime, out rotator out_ViewRotation, out rotator out_DeltaRot)
{
	local Rotator DeltaRecoil;
	local float DeltaPitch, DeltaYaw;

	if(RecoilOffset != rot(0,0,0))
	{
		DeltaRecoil.Pitch = RecoilOffset.Pitch - FInterpTo(RecoilOffset.Pitch, 0, DeltaTime, RecoilInterpSpeed);
		DeltaRecoil.Yaw = RecoilOffset.Yaw - FInterpTo(RecoilOffset.Yaw, 0, DeltaTime, RecoilInterpSpeed);

		TotalRecoil.Pitch += DeltaRecoil.Pitch;

		if(TotalRecoil.Pitch > MaxRecoil)
		{
			if(DeltaRecoil.Pitch > 0)
			{
				RecoilOffset -= DeltaRecoil;

				out_DeltaRot.Pitch += 1;
				out_DeltaRot.Yaw += DeltaRecoil.Yaw;
			}
		}

		else
		{
			RecoilDecline += DeltaRecoil;
			RecoilOffset -= DeltaRecoil;
			out_DeltaRot += DeltaRecoil;
		}

		if(RecoilDecline == rot(0,0,0))
			RecoilOffset = rot(0,0,0);
	}

	else
	{
		if(RecoilDecline != rot(0,0,0))
		{
			TotalRecoil = rot(0,0,0);

			DeltaPitch = RecoilDecline.Pitch - FInterpTo(RecoilDecline.Pitch, 0, DeltaTime, RecoilDeclineSpeed);
			DeltaYaw = RecoilDecline.Yaw - FInterpTo(RecoilDecline.Yaw, 0, DeltaTime, RecoilDeclineSpeed);

			out_DeltaRot.Pitch -= DeltaPitch * RecoilDeclinePct;
			out_DeltaRot.Yaw -= DeltaYaw * RecoilDeclinePct;

			RecoilDecline.Pitch -= DeltaPitch;
			RecoilDecline.Yaw -= DeltaYaw;

			if(Abs(DeltaPitch) < 1.0)
				RecoilDecline = rot(0,0,0);
		}
	}

	WorldInfo.Game.Broadcast(self, RecoilOffset@RecoilDecline);
}

simulated function SetHiddenMat()
{
	if(AttachHiddenMat != none)
		AttachHiddenMat.SetScalarParameterValue(HiddenMatName, 0);

	ClientSetHiddenMat(0);

	SSPawn(Instigator).AttachHiddenMatValue = 0;

	if(ReserveAmmo > 0)
	{
		if(ReloadedTime > 0)
			SetTimer(ReloadedTime, false, 'ResetHiddenMat');

		else
			ResetHiddenMat();

		if(AmmoMesh != none)
		{
			SSPawn(Instigator).SMAmmo.SetStaticMesh(AmmoMesh);
			SSPawn(Instigator).SMAmmo.SetHidden(false);

			SSPawn(Instigator).RepAmmoMesh.bHiddenAmmoMesh = false;
			SSPawn(Instigator).RepAmmoMesh.CurrentAmmoMesh = AmmoMesh;
		}
	}

	//ClientSetHiddenMaterial();
}

////reliable client function ClientSetHiddenMaterial()
////{
////	if(AmmoMesh != none)
////	{
////		SSPawn(Instigator).SMAmmo.SetStaticMesh(AmmoMesh);
////		SSPawn(Instigator).SMAmmo.SetHidden(false);
////	}
////}

simulated function ResetHiddenMat()
{
	if(AttachHiddenMat != none)
		AttachHiddenMat.SetScalarParameterValue(HiddenMatName, 1);

	ClientSetHiddenMat(1);

	SSPawn(Instigator).AttachHiddenMatValue = 1;

	if(AmmoMesh != none)
	{
		SSPawn(Instigator).SMAmmo.SetHidden(true);
		SSPawn(Instigator).RepAmmoMesh.bHiddenAmmoMesh = true;
	}

	//ClientResetHiddenMat();
}

//reliable client function ClientResetHiddenMat()
//{
//	if(AmmoMesh != none)
//		SSPawn(Instigator).SMAmmo.SetHidden(true);
//}

simulated function Projectile ProjectileFire()
{
	local int i;

	local Projectile NewChunk;

	local vector SpawnPos, AimDir;

	local Rotator rot;

	if(bShotgunMode)
	{
		SpawnPos = Instigator.GetWeaponStartTraceLocation();
		AimDir = Vector(GetAdjustedAim(SpawnPos));

		for(i = 0; i < ProjCount; i++)
		{
			//rot = rotator(Normal(Velocity) + VRand());
			rot = rotator(AimDir);
			rot.Pitch += (Rand(RandRotFire) - Rand(RandRotFire));
			rot.Yaw += (Rand(RandRotFire) - Rand(RandRotFire));

			NewChunk = Spawn(GetProjectileClass(),, '', SpawnPos);
			if(NewChunk != None)
			{
				NewChunk.Init(vector(rot));
			}
		}
	}

	return super.ProjectileFire();
}

simulated function ActivateMuzzleFlash()
{
	if(MuzzleFlashEffect != none)
	{
		if(IsTimerActive('DeactivateMuzzleFlash'))
			ClearTimer('DeactivateMuzzleFlash');

		MuzzleFlashEffect.ActivateSystem();
		SetTimer(MuzzleFlashDuration, false, 'DeactivateMuzzleFlash');
	}
}

simulated function DeactivateMuzzleFlash()
{
	MuzzleFlashEffect.DeactivateSystem();
}

simulated function bool CanThrow()
{
	return bCanThrowWeap;
}

simulated function BeginFire(byte FireModeNum)
{
	if(FireModeNum == 1)
	{
		if(!bZoomSniper)
			BeginZoom();

		else if(bZoomSniper)
		{
			if(ZoomDistance < SniperZoomCount && SSPlayerController(Instigator.Controller).GetFOVAngle() == ZoomCount)
			{
				ZoomCount /= (3.6 + SniperZoomCount) / SniperZoomCount;

				bZoomedSniper = true;
				BeginZoom();
				ZoomDistance++;
			}

			else if(ZoomDistance >= SniperZoomCount)
			{
				FinishZoom();
			}
		}
	}

	//if(FireModeNum == 0 && AmmoCount == 0 && ReserveAmmo > 0)
	//{
	//	if ((Mesh.bAttached || UTPawn(Instigator).CurrentWeaponAttachmentClass == AttachmentClass)  && !IsInState('WeaponReloading'))
	//		GotoState('WeaponReloading');
	//}

	else 
		super.BeginFire(FireModeNum);
}

simulated function StartFire(byte FireModeNum)
{
	if(/*SSPawn(Instigator).RadialBlur.bEnabled*/SSPlayerController(Instigator.Controller).bRunning);

	else
		super.StartFire(FireModeNum);
}

simulated function StopFire(byte FireModeNum)
{
	if(/*SSPawn(Instigator).RadialBlur.bEnabled*/SSPlayerController(Instigator.Controller).bRunning && !bHoldingGrenade);

	else
		super.StopFire(FireModeNum);
}

reliable server function ServerStopFire(byte FireModeNum)
{
	if(FireModeNum == 1 && !bZoomSniper)
		FinishZoom();

	super.ServerStopFire(FireModeNum);
}

simulated function EndFire(byte FireModeNum)
{
	if(FireModeNum == 1 && !bZoomSniper)
		FinishZoom();

	//if(FireModeNum == 0 && AmmoCount == 0 && ReserveAmmo > 0)
	//{
	//	//
	//}

	else 
		super.EndFire(FireModeNum);
}

reliable client function BeginZoom()
{
	if(!IsInState('WeaponPuttingDown') && !bReloading && WeaponFireTypes[0] != EWFT_Custom && 
		FiringStatesArray[0] != 'GrenadeFiring')
	{
		//WorldInfo.Game.Broadcast(self, "ZoomIn");
		bActiveZoom = true;
		SSPlayerController(Instigator.Controller).StartZoom(ZoomCount, ZoomTime);

		if(!bZoomedSniper)
			SetTimer(0.1, true, 'GetFireTrace');
		//LocalPlayer(PlayerController(Instigator.Controller).Player).OverridePostProcessSettings(BlurSettings, -0.1f);
		//Mesh.SetTranslation(ZoomPosition);
	}

	if(bZoomedSniper)
	{
		Mesh.SetOwnerNoSee(true);
		Instigator.Mesh.SetOwnerNoSee(true);
		SSHUD(SSPlayerController(Instigator.Controller).myHUD).HUDMovie.Root.SetVisible(false);
		SSPlayerInput(SSPlayerController(Instigator.Controller).PlayerInput).GamePadSensitive /= SniperZoomCount * 1.5; // 2 padrão;
	}
}

reliable client function FinishZoom()
{
	if(bActiveZoom)
	{
		//WorldInfo.Game.Broadcast(self, UberEffect);
		bActiveZoom = false;
		//Mesh.SetTranslation(Mesh.default.Translation);
		SSPlayerController(Instigator.Controller).StartZoom(90, ZoomTime);
		SSPlayerController(Instigator.Controller).DefaultFOV = 90;
		//UberEffect.BlurKernelSize = 0.0;
		//SSPlayerController(Instigator.Controller).PostProcessModifier.DOF_BlurKernelSize = 0.0;
		//SSPlayerController(Instigator.Controller).PostProcessModifier.DOF_FocusType = FOCUS_Distance;
		ClearTimer('GetFireTrace');
		LocalPlayer(PlayerController(Instigator.Controller).Player).ClearPostProcessSettingsOverride(0.1f);

		if(bZoomedSniper)
		{
			Mesh.SetOwnerNoSee(false);
			Instigator.Mesh.SetOwnerNoSee(false);
			SSHUD(SSPlayerController(Instigator.Controller).myHUD).HUDMovie.Root.SetVisible(true);
			bZoomedSniper = false;
			ZoomDistance = 0;
			ZoomCount = 90;
			SSPlayerInput(SSPlayerController(Instigator.Controller).PlayerInput).GamePadSensitive = 1.0;
		}
	}
}

reliable client function GetFireTrace()
{
	local actor traced;
	local vector hitlocation, hitnormal, tracedEnd, tracedStart;
	local Rotator SocketRot;

	//local vector OutCamLoc;
	//local Rotator OutCamRot;

	//local LocalPlayer PC;

	SkeletalMeshComponent(Mesh).GetSocketWorldLocationAndRotation(MuzzleFlashSocket, tracedStart, SocketRot);
	tracedEnd = /*tracedStart + vector(SocketRot)*5000*/InstantFireEndTrace(tracedStart);

	Foreach TraceActors(class'actor', traced, hitlocation, hitnormal, tracedEnd, tracedStart, vect(0,0,0))
	{
		if(traced != Owner)
		{
			//WorldInfo.Game.Broadcast(self, PC.PlayerCamera);
			break;
		}
	}

	if(CheckValidFireTrace())
	{
		BlurSettings.DOF_FocusPosition = hitlocation;
		LocalPlayer(PlayerController(Instigator.Controller).Player).OverridePostProcessSettings(BlurSettings, -0.1f);
	}

	//PC = LocalPlayer(PlayerController(Instigator.Controller).Player);

	//UberEffect = UberPostProcessEffect(PC.PlayerPostProcess.FindPostProcessEffect('Uber'));

	//if(UberEffect != none)
	//{
	//	//WorldInfo.Game.Broadcast(self, UberEffect);
	//	UberEffect.FocusPosition = hitlocation;
	//	UberEffect.BlurKernelSize = 8.0;
	//}

	//UTPlayerController(Instigator.Controller).GetPlayerViewPoint(OutCamLoc, OutCamRot);

	//SetRotation(OutCamRot);
}

//function GivenTo(Pawn thisPawn, optional bool bDoNotActivate)
//{
//	super.GivenTo(thisPawn, bDoNotActivate);

//	WorldInfo.Game.Broadcast(self, ReserveAmmo);
//}

//simulated function Tick(float DeltaTime)
//{
//	super.Tick(DeltaTime);

//	if(FiringStatesArray[0] == 'GrenadeFiring')
//		WorldInfo.Game.Broadcast(self, GetStateName());
//}

simulated function bool CheckValidFireTrace()
{
	if(SSPawn(Instigator).Health >= SSPawn(Instigator).default.Health)
		return true;

	return false;
}

simulated function vector GetPhysicalFireStartLoc(optional vector AimDir)
{
	local Vector SocketLocation;
	local Rotator SocketRotation;

	SkeletalMeshComponent(Mesh).GetSocketWorldLocationAndRotation(MuzzleFlashSocket, SocketLocation, SocketRotation);
	
	return SocketLocation;
}

//simulated function Tick(float DeltaTime)
//{
//	super.Tick(DeltaTime);

//	if(FiringStatesArray[0] == 'GrenadeFiring')
//		WorldInfo.Game.Broadcast(self, GetStateName()@CurrentGrenadeSpeed);
//}

simulated function SendToFiringState(byte FireModeNum)
{
	if(bReloading)
		return;

	super.SendToFiringState(FireModeNum);
}

simulated state GrenadeFiring
{
	simulated function Projectile ProjectileFire()
	{
		local vector		StartTrace, EndTrace, RealStartLoc, AimDir;
		local ImpactInfo	TestImpact;
		local Projectile	SpawnedProjectile;

		if(Role == ROLE_Authority)
		{
			// This is where we would start an instant trace. (what CalcWeaponFire uses)
			StartTrace = Instigator.GetWeaponStartTraceLocation();
			AimDir = Vector(GetAdjustedAim(StartTrace));

			// this is the location where the projectile is spawned.
			RealStartLoc = GetPhysicalFireStartLoc(AimDir);

			if(StartTrace != RealStartLoc)
			{
				// if projectile is spawned at different location of crosshair,
				// then simulate an instant trace where crosshair is aiming at, Get hit info.
				EndTrace = StartTrace + AimDir * GetTraceRange();
				TestImpact = CalcWeaponFire(StartTrace, EndTrace);

				// Then we realign projectile aim direction to match where the crosshair did hit.
				AimDir = Normal(TestImpact.HitLocation - RealStartLoc);
			}

			// Spawn projectile
			SpawnedProjectile = Spawn(GetProjectileClass(), Self,, RealStartLoc);
			if(SpawnedProjectile != None && !SpawnedProjectile.bDeleteMe)
			{
				if(Instigator.Health <= 0)
					SpawnedProjectile.Speed = 0;
				else
					SpawnedProjectile.Speed += CurrentGrenadeSpeed;

				if(SSProj_Grenade(SpawnedProjectile) != none)
					SSProj_Grenade(SpawnedProjectile).TimeExplode = GrenadeTimeExplode;
				//if(GrenadeTimeExplode > 0)
				//	SSPawn(Instigator).ePlayAnim(SSPawn(Instigator).TopHalfAnimSlot, GrenadeLaunchAnimName, 1.0, 0.15, 0.15, false);
				if(GrenadeTimeExplode <= 0)
				{
					SpawnedProjectile.SetPhysics(PHYS_NONE);
					SpawnedProjectile.SetBase(Instigator,,Instigator.Mesh, 'b_RightHand');
					SpawnedProjectile.SetHardAttach(true);
					if(SSProj_Grenade(SpawnedProjectile) != none)
						SSProj_Grenade(SpawnedProjectile).TimeExplode = 0.05;
				}
				SpawnedProjectile.Init(AimDir);

				//WorldInfo.Game.Broadcast(self, GetStateName()@SpawnedProjectile.Speed@Instigator.Health@SSProj_Grenade(SpawnedProjectile).TimeExplode);
			}

			// Return it up the line
			return SpawnedProjectile;
		}

		return None;
	}

	simulated event bool IsFiring()
	{
		return true;
	}

	simulated function BeginFire(byte FireModeNum);

	simulated function IncreaseSpeed()
	{
		CurrentGrenadeSpeed += 50;

		if(GrenadeTimeExplode >= 0.5)
			GrenadeTimeExplode -= 0.5;

		else
			//EndFire(0);
			TossGrenade();
	}

	simulated function EndFire(byte FireModeNum)
	{
		//local vector WeapLoc;

		if(FireModeNum == 0 && CurrentAmmoCount > 0/*&& GrenadeTimeExplode > 0*/)
		{
			//FireAmmunition();
			if(GrenadeLaunchAnimName != '')
				SSPawn(Instigator).ePlayAnim(SSPawn(Instigator).TopHalfAnimSlot, GrenadeLaunchAnimName, 1.0, 0.15, 0.25, false);
			SetTimer(GrenadeLaunchAnimTime, false, 'TossGrenade');
		}
		else
		{
			GotoState('Active');
			ClearTimer(nameof(RefireCheckTimer));
			HasAmmo(0,0);
		}
		//else if(GetProjectileClass() == class'SSProj_GrenadeExplode')
		//{
		//	//WeaponPlaySound(class'SSProj_GrenadeExplode'.default.ExplosionSound);
		//	//IncrementFlashCount();
		//	//ActivateMuzzleFlash();
		//	SkeletalMeshComponent(Mesh).GetSocketWorldLocationAndRotation(MuzzleFlashSocket, WeapLoc);
		//	ConsumeAmmo(0);
		//	SSPlayerController(Instigator.Controller).GrenadeExploded(ParticleSystem'Envy_Effects.VH_Deaths.P_VH_Death_SMALL_Near', 
		//		class'SSProj_GrenadeExplode'.default.ExplosionSound, WeapLoc);

		//	HurtRadius(class'SSProj_GrenadeExplode'.default.Damage, class'SSProj_GrenadeExplode'.default.DamageRadius, 
		//		class'UTDmgType_Grenade', class'SSProj_GrenadeExplode'.default.MomentumTransfer, SSPawn(Instigator).Location);

		//	//WorldInfo.Game.Broadcast(self, SSPawn(Instigator).Location@Instigator.Location);
		//}

		Global.EndFire(FireModeNum);
	}

	simulated function TossGrenade()
	{
		FireAmmunition();
		SetTimer(GetFireInterval(0), false, 'FinishGrenadeState');
	}

	simulated function FinishGrenadeState()
	{
		GotoState('Active');
		ClearTimer(nameof(RefireCheckTimer));
		HasAmmo(0,0);
	}

	//simulated function ActivateMuzzleFlash()
	//{
	//	if(GrenadeTimeExplode <= 0)
	//		global.ActivateMuzzleFlash();
	//}

	simulated function BeginState(Name NextStateName)
	{
		if(CurrentFireMode == 0)
		{
			if(GrenadePreLaunchAnimName != '' && CurrentAmmoCount > 0)
				SSPawn(Instigator).ePlayAnim(SSPawn(Instigator).TopHalfAnimSlot, GrenadePreLaunchAnimName, 1.0, 0.15, 0.15, false);

			bHoldingGrenade = true;
			SetTimer(0.5, true, 'IncreaseSpeed');
		}
	}

	simulated function EndState(Name NextStateName)
	{
		ClearTimer('IncreaseSpeed');
		bHoldingGrenade = false;
		CurrentGrenadeSpeed = 0.0;
		GrenadeTimeExplode = default.GrenadeTimeExplode;
		Global.EndState(NextStateName);
	}

	simulated function HolderDied()
	{
		if(GrenadeTimeExplode > 0)
			FireAmmunition();

		global.HolderDied();
	}
}

DefaultProperties
{
	Begin Object class=AnimNodeSequence Name=MeshSequenceA
		bCauseActorAnimEnd=true
	End Object

	Begin Object Class=SkeletalMeshComponent Name=MySkeletalMeshComponent
		Animations=MeshSequenceA
		bUpdateSkelWhenNotRendered=false
		bIgnoreControllersWhenNotRendered=true
		bAcceptsDynamicDecals=true
		CastShadow=true
		TickGroup=TG_DuringASyncWork
		bOnlyOwnerSee=true
		DepthPriorityGroup=SDPG_Foreground
		//AlwaysLoadOnClient=true
		//AlwaysLoadOnServer=true
	End Object
	Mesh=MySkeletalMeshComponent
	Components.Add(MySkeletalMeshComponent)

	//Begin Object Class=UDKParticleSystemComponent Name=MuzzleEffect
	//	bAutoActivate=false
	//End Object
	//MuzzleFlashEffect=MuzzleEffect
	//Components.Add(MuzzleEffect)

	FiringStatesArray(0)="WeaponFiring"
	FiringStatesArray(1)="WeaponFiring"

	InstantHitMomentum(0)=+1000.0
    WeaponFireTypes(0)=EWFT_InstantHit

	InstantHitDamage(0)=40
    FireInterval(0)=+1.0

    InstantHitDamageTypes(0)=class'SSDamageType'
	InstantHitDamageTypes(1)=class'SSDmgType_HeadShot'

	ShotCost=1

	MaxRecoil=600
	RecoilInterpSpeed=10
	RecoilDeclineSpeed=10
	RecoilDeclinePct=1

	bCanThrowWeap=true
	bAllowHeadShot=true

	SniperZoomCount=3
	GrenadeTimeExplode=3

	HiddenMatTimer=0.1
	GrenadeLaunchAnimTime=0.2

	ReloadAnimRate=1.0

	NewFiringStatesArray=WeaponFiring

	DroppedPickupClass=class'SSDroppedPickup'
	CrosshairFriedlyColor=(R=0,G=155,B=255,A=255)
	CrosshairEnemyColor=(R=255,G=0,B=0,A=255)


	//Begin Object Class=ForceFeedbackWaveform Name=ForceFeedbackWaveformShooting1
	//	Samples(0)=(LeftAmplitude=90,RightAmplitude=40,LeftFunction=WF_Constant,RightFunction=WF_LinearDecreasing,Duration=0.1200)
	//End Object
	//WeaponFireWaveForm=ForceFeedbackWaveformShooting1
}
