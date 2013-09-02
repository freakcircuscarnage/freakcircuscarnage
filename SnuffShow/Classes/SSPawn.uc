class SSPawn extends UDKPawn
	Implements(SSMinimapIconInterface)
	hidecategories(Swimming, UDKPawn, Movement, Debug, AI, Display,
		Attachment, Object, /*Collision,*/ Advanced, Mobile, Physics, TeamBeacon, Camera);

enum EWeapAnimType
{
	EWAT_Default,
	EWAT_Pistol,
	EWAT_DualPistols,
	EWAT_ShoulderRocket,
	EWAT_Stinger
};

struct RepAnim
{
	var bool Toggle;
	var name AnimName; 
	var float Rate;
	var float BlendInTime;
	var float BlendOutTime;
	var bool bLoop;
	var bool bOverride;
	var bool bStop;
	var SSPawn Pawn;
};

struct AmmoMeshHidden
{
	var bool bHiddenAmmoMesh;
	var StaticMesh CurrentAmmoMesh;

	structdefaultproperties
	{
		bHiddenAmmoMesh=true
	}
};

var PostProcessSettings BlurHealthSettings;

var array<UDKAnimNodeSeqWeap> WeaponTypeAnimNodes;
var array<UDKAnimBlendByWeapType> WeaponAnimTypes;

var array<Name> DeathMeshBreakableJoints;
var array<name> NoDriveBodies;

var ParticleSystemComponent NameEffect;

var(Pawn) StaticMeshComponent SMAmmo;
var(Pawn) name WeaponSocket;
var(Pawn) float Velocidade <UIMin=100.0 | UIMax=600.0 | ClampMin=100.0 | ClampMax=600.0>;
var(Pawn) array<SSWeapBase> InitWeapons;
var(Pawn) string PawnName;
var(Pawn) RadialBlurComponent RadialBlur;
var(Pawn) SoundCue SameTeamAnnounce;
var(Pawn) int HealthRecover;
var(Pawn) int HealthRecoverTime;
var(Pawn) name HipsName, HeadBone;
var(Pawn) float HeadRadius;
var(Pawn) float HeadHeight;
var(Pawn) float NewJumpZ;
var(Pawn) SkeletalMeshComponent FPMesh;

var DynamicLightEnvironmentComponent LightEnvironment;

var float StartDeathAnimTime;
var float TimeLastTookDeathAnimDamage;

var AnimNodeSlot FullBodyAnimSlot;
var AnimNodeSlot TopHalfAnimSlot;
//var	AnimNodeAimOffset AimNode;

var AnimNodeSlot FPFullBodyAnimSlot;
var AnimNodeSlot FPTopHalfAnimSlot;

var AnimNodeBlend RunningBlend;
var repnotify bool bRunning;
var repnotify AmmoMeshHidden RepAmmoMesh;
var repnotify RepAnim TopBodyRep;
var repnotify int CurrentWeapAnimNode, CurrentWeapAnimType;
var repnotify ImpactInfo ImpactTrace;
var repnotify bool bWeapReloaded;
var repnotify float AttachHiddenMatValue;
var repnotify class<SSAttachmentBase> WeaponAttachClass;
var repnotify SSAttachmentBase WeaponAttachArchetype;

var string CurrentAnimType;

var float DeathHipLinSpring;
var float DeathHipLinDamp;
var float DeathHipAngSpring;
var float DeathHipAngDamp;

var float RagdollLifespan;

var Vector2D LookDir;

var SSMapInfo SSMapInfo;

//var Vector ActorToPawnDirection, DirX, DirY, DirZ;

//var repnotify float AimView;

//var repnotify name MeleeAnim;

var SSAttachmentBase NewWeaponAttach;

var bool bInitSpawn, bReadyMeleeAttack;

var AudioComponent AnnouncementAudioComponent;
var SoundCue CurrentSoundAnnoucement;

var GFxObject PlayerIcon, IconDir;
//var array<SSGFxHitDirection> DamageIcon;
var array<ASValue> args;

var SkelControlLimb LeftAim;

//var SkeletalMeshComponent FPMesh;
//var	AnimNodeAimOffset FPAimNode;

struct HitDirection
{
	var Vector DmgLoc;
	var GFxObject IconHD;
	var Controller DmgInst;
};

var array<HitDirection> DamageIcon;
//var HitDirection DamageIcon[10];
//var byte DmgIconIndex;

//var array<GFxObject> KLMessages;

replication
{
	if(bNetDirty && !bNetOwner && Role == Role_Authority)
		WeaponAttachClass, WeaponAttachArchetype;

	if(bNetDirty)
		/*AimView,*/ ImpactTrace, bWeapReloaded, AttachHiddenMatValue, TopBodyRep, PlayerIcon, bRunning, RepAmmoMesh, CurrentAnimType,
			CurrentWeapAnimNode, CurrentWeapAnimType;	

	if(bNetOwner)
		bReadyMeleeAttack;
}

simulated event ReplicatedEvent(name VarName)
{
	if(VarName == NameOf(WeaponAttachClass) || VarName == NameOf(WeaponAttachArchetype))
	{
		AttachWeapon();
	}

	else if(VarName == NameOf(bRunning))
	{
		ClientSetRunningBlend(bRunning);
	}

	else if(VarName == NameOf(RepAmmoMesh))
	{
		ClientSetHiddenAmmoMesh(RepAmmoMesh.bHiddenAmmoMesh, RepAmmoMesh.CurrentAmmoMesh);
	}

	else if(VarName == NameOf(CurrentWeapAnimType) && CurrentWeapAnimType > -1)
	{
		ClientSetWeapAnimType(CurrentWeapAnimType);
	}

	else if(VarName == NameOf(CurrentWeapAnimNode) && CurrentWeapAnimNode > -1)
	{
		ClientSetWeapAnim(CurrentAnimType, CurrentWeapAnimNode);
	}

	//if(VarName == NameOf(AimView))
	//{
	//	ServerAimViewRotation();
	//}

	else if(VarName == NameOf(ImpactTrace))
	{
		PlayImpactEffects(ImpactTrace);
	}

	else if(VarName == NameOf(bWeapReloaded))
	{
		if(bWeapReloaded)
			ReloadingWeap();
	}

	else if(VarName == NameOf(AttachHiddenMatValue))
	{
		if(AttachHiddenMatValue >= 0)
		{
			HiddenMatChange(AttachHiddenMatValue);
			ClientHiddenMatChange(AttachHiddenMatValue);
		}
	}

	else if(VarName == NameOf(TopBodyRep)/* && TopBodyRep.AnimName != ''*/)
	{
		ClientePlayAnim(TopHalfAnimSlot, TopBodyRep.AnimName, TopBodyRep.Rate, TopBodyRep.BlendInTime, 
			TopBodyRep.BlendOutTime, TopBodyRep.bLoop, TopBodyRep.bOverride, TopBodyRep.bStop, TopBodyRep.Pawn);
	}

	Super.ReplicatedEvent(VarName);
}

simulated function SetRunningBlend(bool bRun)
{
	if(bRun)
		RunningBlend.SetBlendTarget(1.0, 0.15);
	else
		RunningBlend.SetBlendTarget(0.0, 0.15);

	bRunning = bRun;
}

reliable client function ClientSetRunningBlend(bool bRun)
{
	if(bRun)
		RunningBlend.SetBlendTarget(1.0, 0.15);
	else
		RunningBlend.SetBlendTarget(0.0, 0.15);
}

simulated function SetWeapAnim(EWeapAnimType AnimType)
{
	//local int i, j;
	//local UDKAnimBlendByWeapType WeapType;

	//for(i = 0; i < WeaponTypeAnimNodes.length; i++) 
	//{
	//	switch(AnimType)
	//	{
	//		case EWAT_Default:
	//			WeaponTypeAnimNodes[i].SetAnim(WeaponTypeAnimNodes[i].DefaultAnim);
	//			break;
	//		case EWAT_Pistol:
	//			WeaponTypeAnimNodes[i].SetAnim(WeaponTypeAnimNodes[i].SinglePistolAnim);
	//			break;
	//		case EWAT_DualPistols:
	//			WeaponTypeAnimNodes[i].SetAnim(WeaponTypeAnimNodes[i].DualPistolAnim);
	//			break;
	//		case EWAT_ShoulderRocket:
	//			WeaponTypeAnimNodes[i].SetAnim(WeaponTypeAnimNodes[i].ShoulderRocketAnim);
	//			break;
	//		case EWAT_Stinger:
	//			WeaponTypeAnimNodes[i].SetAnim(WeaponTypeAnimNodes[i].StingerAnim);
	//			break;
	//	}
	//}
	SetTimer(0.09, true, 'SetCurrentWeapAnimType');
	SetTimer(0.1, true, 'SetCurrentWeapAnimNode');
}

simulated function SetCurrentWeapAnimType()
{
	if(CurrentWeapAnimType < WeaponAnimTypes.Length) 
	{
		CurrentWeapAnimType++;

		if(Weapon != none)
			WeaponAnimTypes[CurrentWeapAnimType].SetBlendTarget(1.0, 0.1);
		else
			WeaponAnimTypes[CurrentWeapAnimType].SetBlendTarget(0.0, 0.1);
	}

	else
	{
		ClearTimer('SetCurrentWeapAnimType');
		CurrentWeapAnimType = -1;
	}
}

simulated function SetCurrentWeapAnimNode()
{
	if(CurrentWeapAnimNode < WeaponTypeAnimNodes.length) 
	{
		CurrentWeapAnimNode++;

		CurrentAnimType = string(NewWeaponAttach.WeapAnimType);

		switch(CurrentAnimType)
		{
			case "EWAT_Default":
				WeaponTypeAnimNodes[CurrentWeapAnimNode].SetAnim(WeaponTypeAnimNodes[CurrentWeapAnimNode].DefaultAnim);
				break;
			case "EWAT_Pistol":
				WeaponTypeAnimNodes[CurrentWeapAnimNode].SetAnim(WeaponTypeAnimNodes[CurrentWeapAnimNode].SinglePistolAnim);
				break;
			case "EWAT_DualPistols":
				WeaponTypeAnimNodes[CurrentWeapAnimNode].SetAnim(WeaponTypeAnimNodes[CurrentWeapAnimNode].DualPistolAnim);
				break;
			case "EWAT_ShoulderRocket":
				WeaponTypeAnimNodes[CurrentWeapAnimNode].SetAnim(WeaponTypeAnimNodes[CurrentWeapAnimNode].ShoulderRocketAnim);
				break;
			case "EWAT_Stinger":
				WeaponTypeAnimNodes[CurrentWeapAnimNode].SetAnim(WeaponTypeAnimNodes[CurrentWeapAnimNode].StingerAnim);
				break;
		}
	}

	else
	{
		ClearTimer('SetCurrentWeapAnimNode');
		CurrentWeapAnimNode = -1;
	}
}

reliable client function ClientSetWeapAnimType(int WeapType)
{
	WeaponAnimTypes[WeapType].SetBlendTarget(1.0, 0.1);

	//ClientSetWeapAnim(CurrentAnimType);
}

reliable client function ClientSetWeapAnim(optional string AnimType, optional int WeapNode)
{
	//local int i, j;
	//local UDKAnimBlendByWeapType WeapType;

	switch(CurrentAnimType)
	{
		case "EWAT_Default":
			WeaponTypeAnimNodes[WeapNode].SetAnim(WeaponTypeAnimNodes[WeapNode].DefaultAnim);
			break;
		case "EWAT_Pistol":
			WeaponTypeAnimNodes[WeapNode].SetAnim(WeaponTypeAnimNodes[WeapNode].SinglePistolAnim);
			break;
		case "EWAT_DualPistols":
			WeaponTypeAnimNodes[WeapNode].SetAnim(WeaponTypeAnimNodes[WeapNode].DualPistolAnim);
			break;
		case "EWAT_ShoulderRocket":
			WeaponTypeAnimNodes[WeapNode].SetAnim(WeaponTypeAnimNodes[WeapNode].ShoulderRocketAnim);
			break;
		case "EWAT_Stinger":
			WeaponTypeAnimNodes[WeapNode].SetAnim(WeaponTypeAnimNodes[WeapNode].StingerAnim);
			break;
	}
}

simulated function SetWeapAnimType(EWeapAnimType AnimType)
{
	CurrentAnimType = string(AnimType);
	SetWeapAnim(AnimType);

	if(AimNode != None)
	{
		switch(AnimType)
		{
			case EWAT_Default:
				AimNode.SetActiveProfileByName('Default');
				break;
			case EWAT_Pistol:
				AimNode.SetActiveProfileByName('SinglePistol');
				break;
			case EWAT_DualPistols:
				AimNode.SetActiveProfileByName('DualPistols');
				break;
			case EWAT_ShoulderRocket:
				AimNode.SetActiveProfileByName('ShoulderRocket');
				break;
			case EWAT_Stinger:
				AimNode.SetActiveProfileByName('Stinger');
				break;
		}
	}
}

function ePlayAnim(AnimNodeSlot NewAnimSlot, Name NewAnimName, float NewRate, float NewBlendInTime, float NewBlendOutTime, 
	bool NewbLoop, optional bool NewOverride, optional bool NewStop)
{
	local RepAnim NewRepAnim;

	NewRepAnim.Toggle = !TopBodyRep.Toggle;
	NewRepAnim.AnimName = NewAnimName;
	NewRepAnim.Rate = NewRate;
	NewRepAnim.BlendInTime = NewBlendInTime;
	NewRepAnim.BlendOutTime = NewBlendOutTime;
	NewRepAnim.bLoop = NewbLoop;
	NewRepAnim.bOverride = NewOverride;
	NewRepAnim.bStop = NewStop;
	NewRepAnim.Pawn = self;

	if(!NewStop)
	{
		TopHalfAnimSlot.PlayCustomAnim(NewAnimName, NewRate, NewBlendInTime, NewBlendOutTime, NewbLoop, NewOverride);
		FPTopHalfAnimSlot.PlayCustomAnim(NewAnimName, NewRate, NewBlendInTime, NewBlendOutTime, NewbLoop, NewOverride);
	}
	else
	{
		TopHalfAnimSlot.StopCustomAnim(NewBlendOutTime);
		FPTopHalfAnimSlot.StopCustomAnim(NewBlendOutTime);
	}
	// changing this var will make it get caught and replicated by ReplicatedEvent. remember repnotify on the declaration?
	TopBodyRep = NewRepAnim;

	if(Role < ROLE_Authority)
		ServerePlayAnim(NewAnimSlot, NewAnimName, NewRate, NewBlendInTime, NewBlendOutTime, NewbLoop, NewOverride, NewStop);

	WorldInfo.Game.Broadcast(self, FPTopHalfAnimSlot);
}

reliable server function ServerePlayAnim(AnimNodeSlot NewAnimSlot, Name NewAnimName, float NewRate, float NewBlendInTime, 
	float NewBlendOutTime, bool NewbLoop, optional bool NewOverride, optional bool NewStop)
{
	ePlayAnim(NewAnimSlot, NewAnimName, NewRate, NewBlendInTime, NewBlendOutTime, NewbLoop, NewOverride, NewStop);
}

reliable client function ClientePlayAnim(AnimNodeSlot NewAnimSlot, Name NewAnimName, float NewRate, float NewBlendInTime,
	float NewBlendOutTime, bool NewbLoop, optional bool NewOverride, optional bool NewStop, optional SSPawn PlayerPawn)
{
	if(!NewStop)
	{
		PlayerPawn.TopHalfAnimSlot.PlayCustomAnim(NewAnimName, NewRate, NewBlendInTime, NewBlendOutTime, NewbLoop, NewOverride);
		PlayerPawn.FPTopHalfAnimSlot.PlayCustomAnim(NewAnimName, NewRate, NewBlendInTime, NewBlendOutTime, NewbLoop, NewOverride);
	}
	else
	{
		PlayerPawn.TopHalfAnimSlot.StopCustomAnim(NewBlendOutTime);
		PlayerPawn.FPTopHalfAnimSlot.StopCustomAnim(NewBlendOutTime);
	}
}

simulated event Melee()
{
	bReadyMeleeAttack = true;
}

//reliable server function ServerPlayAnim()
//{
//	if(!SSPlayerController(Controller).IsMoveInputIgnored() && TopHalfAnimSlot != None)
//		TopHalfAnimSlot.PlayCustomAnim(MeleeAnim, 1.0, 0.35, 0.35, false, true);
//}

//var	/*repnotify*/ class<SSAttachmentBase> SSCurrentWeaponAttachmentClass;

//var	SSAttachmentBase SSCurrentWeaponAttachment;

//simulated function SetCharacterClassFromInfo(class<UTFamilyInfo> Info);

simulated function NotifyTeamChanged()
{
	local PlayerController PlayerController;
	local SSHUD SSHUD;

	PlayerController = PlayerController(Controller);
	if (PlayerController != None)
	{
		SSHUD = SSHUD(PlayerController.MyHUD);
		if (SSHUD != None)
		{
			SSHUD.NotifyTeamChanged();
		}
	}

	if(PlayerIcon != none)
		PlayerIcon.GotoAndStopI(PlayerReplicationInfo.Team.TeamIndex + 1);
}

reliable client function ClientPlaySound(SoundCue SoundAnnoucement)
{
	if(AnnouncementAudioComponent == none)
		AnnouncementAudioComponent = CreateAudioComponent(SoundAnnoucement, false, false);

	if(!AnnouncementAudioComponent.IsPlaying())
	{
		AnnouncementAudioComponent.SoundCue = SoundAnnoucement;
		AnnouncementAudioComponent.Play();
	}

	else
	{
		CurrentSoundAnnoucement = SoundAnnoucement;
		SetTimer(2.0, false, 'TryPlayAnnouncementAgain');
	}
	
	//PlaySound(CurrentSound, true, false);
}

simulated function TryPlayAnnouncementAgain()
{
	if(CurrentSoundAnnoucement != none)
		ClientPlaySound(CurrentSoundAnnoucement);

	//WorldInfo.Game.Broadcast(self, CurrentSoundAnnoucement);
}

event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> 
	DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	if(bInitSpawn || Health <= 0);

	else if((IsSameTeam(SSPawn(InstigatedBy.Pawn)) && SSMapInfo != none && !SSMapInfo.bAllowFriendlyFire && 
		InstigatedBy.Pawn != self))
	{
		SSPawn(InstigatedBy.Pawn).ClientPlaySound(SameTeamAnnounce);
	}

	else
	{
		super.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);

		//if(CheckValidHitDir(InstigatedBy, InstigatedBy.Pawn.Location))
			SetDamageIcon(InstigatedBy.Pawn.Location, InstigatedBy);

		//WorldInfo.Game.Broadcast(self, DamageIcon[DmgIconIndex -1].DmgInst@ DamageIcon[DmgIconIndex -1].DmgLoc@ DamageIcon[DmgIconIndex -1].IconHD);

		SetTimer(0.1, false, 'EnableHealthBlur');
		SetTimer(HealthRecoverTime, true, 'RecoverHealth');
	}

	//if(!IsTimerActive('RecoverHealth'))
	//	SetTimer(HealthRecoverTime, true, 'RecoverHealth');
}

reliable client function EnableHealthBlur()
{
	BlurHealthSettings.DOF_BlurKernelSize = ((default.Health - Health) / 20)/* * 2*/;
	LocalPlayer(PlayerController(Instigator.Controller).Player).OverridePostProcessSettings(BlurHealthSettings, -0.1f);
}

reliable client function DisableHealthBlur()
{
	LocalPlayer(PlayerController(Instigator.Controller).Player).ClearPostProcessSettingsOverride(-0.1f);
}

//reliable client function SetHealthBlurvalue(float Value)
//{
//	BlurHealthSettings.DOF_BlurKernelSize = Value;
//}

reliable client function SetDamageIcon(Vector DmgLocation, Controller DmgInstigator)
{
	local int index;

	//if(SSHUD(SSPlayerController(Controller).myHUD).HUDMovie.Root.GetObject("HD"$string(DmgInstigator)) != none)
	//	return;

	local int i;

	for(i = 0; i < DamageIcon.Length; i++)
	{
		if(DamageIcon[i].IconHD == SSHUD(SSPlayerController(Controller).myHUD).HUDMovie.Root.GetObject("HD"$string(DmgInstigator)))
		{
			DamageIcon[i].DmgLoc = DmgLocation;
			return;
		}
	}

	if(Health > 0)
	{
		index = DamageIcon.length;
		//DmgIconIndex++;

		DamageIcon.Insert(index, 1);
		DamageIcon[DamageIcon.Length -1].IconHD = SSHUD(SSPlayerController(Controller).myHUD).HUDMovie.Root.AttachMovie("HitDirection", 
			"HD"$string(DmgInstigator));
		DamageIcon[DamageIcon.Length-1].IconHD.SetFloat("_alpha", SSMapInfo.MinimapOpacity);
		DamageIcon[DamageIcon.Length -1].IconHD.SetPosition(960, 514);
		DamageIcon[DamageIcon.Length -1].DmgLoc = DmgLocation;
		DamageIcon[DamageIcon.Length-1].DmgInst = DmgInstigator;

		SetTimer(0.03, true, 'CalcHitDirection');
		//SetTimer(3.0, false, 'DestroyDamageIcon');
	}
}

function CalcHitDirection()
{
	local int i;
	local int CurrentLabel;
	local Rotator HitDir;

	for(i = 0; i < DamageIcon.Length; i++)
	{
		HitDir = (Rotation - Rotator(DamageIcon[i].DmgLoc - Location)) * 1.0;
		DamageIcon[i].IconHD.SetFloat("_rotation", (HitDir.Yaw * UnrRotToDeg) * -1);
		CurrentLabel = DamageIcon[i].IconHD.GetInt("_currentframe");

		if(CurrentLabel > 70)
			DestroyDamageIcon(DamageIcon[i]);
			//DamageIcon[i].DmgInst = none;
	}
	
	//WorldInfo.Game.Broadcast(self, "");
}

function bool CheckValidHitDir(Controller C, Vector DmgLocation)
{
	local int i;

	for(i = 0; i < DamageIcon.Length; i++)
	{
		if(DamageIcon[i].DmgInst == C)
		{
			DamageIcon[i].DmgLoc = DmgLocation;
			return false;
		}
	}

	return true;
}

reliable client function DestroyDamageIcon(HitDirection Icon)
{
	Icon.IconHD.Invoke("removeMovieClip", args);
	Icon.DmgInst = none;
	Icon.DmgLoc = vect(0,0,0);
}

function RecoverHealth()
{
	local int i;

	if(Health < default.Health)
	{
		Health = Clamp(Health + HealthRecover, 0, default.Health);

		if(Health < default.Health)
			EnableHealthBlur();

		else
		{
			for(i = 0; i < DamageIcon.Length; i++)
			{
				DamageIcon[i].IconHD.Invoke("removeMovieClip", args);
				DamageIcon[i].DmgInst = none;
				DamageIcon[i].DmgLoc = vect(0,0,0);
			}

			DamageIcon.Remove(0, DamageIcon.Length);
			//DmgIconIndex = 0;

			ClearTimer('CalcHitDirection');
			ClearTimer('RecoverHealth');

			DisableHealthBlur();
		}
	}

	//else
	//{
	//	for(i = 0; i < DamageIcon.Length; i++)
	//	{
	//		DamageIcon[i].IconHD.Invoke("removeMovieClip", args);
	//		DamageIcon[i].DmgInst = none;
	//		DamageIcon[i].DmgLoc = vect(0,0,0);
	//	}

	//	DamageIcon.Remove(0, DamageIcon.Length);
	//	//DmgIconIndex = 0;

	//	ClearTimer('CalcHitDirection');
	//	ClearTimer('RecoverHealth');

	//	DisableHealthBlur();
	//}
}

reliable client function UnHideDropWeapMC(int WeaponIcon)
{
	SSHUD(SSPlayerController(Controller).myHUD).HUDMovie.DropWeapMC.GetObject("WeapIcon").GotoAndStopI(WeaponIcon);
	SSHUD(SSPlayerController(Controller).myHUD).HUDMovie.DropWeapMC.SetVisible(true);
}

reliable client function HideDropWeapMC()
{
	SSHUD(SSPlayerController(Controller).myHUD).HUDMovie.DropWeapMC.SetVisible(false);
}

reliable client function SetDropWeapMCText(string Text)
{
	SSHUD(SSPlayerController(Controller).myHUD).HUDMovie.DropWeapMC.GetObject("CheckedWeapon").SetText(Text);
}

reliable client function CreateKLMessage(string KilledName, int WeaponIcon, string KillerName)
{
	local int i, index;
	local SSGameReplicationInfo SGRI;

	SGRI = SSGameReplicationInfo(WorldInfo.GRI);

	for(i = 0; i < SGRI.KLMessages.Length; i++)
	{
		SGRI.KLMessages[i].SetPosition(-110, 250 - ((i + 1) * 50));
	}

	index = SGRI.KillMessagesCount;

	SGRI.KLMessages.AddItem(SSHUD(SSPlayerController(Controller).myHUD).HUDMovie.Root.GetObject("LogStage").AttachMovie("KLMessage", 
		"KLM"$string(SGRI.KLMessages.Length)));
	SGRI.KLMessages[index].SetPosition(-110, 250/* - (KLMessages.Length * 50)*/);
	SGRI.KLMessages[index].GetObject("KilledName").SetText(KilledName);
	SGRI.KLMessages[index].GetObject("WeaponIcon").GotoAndStopI(WeaponIcon);
	SGRI.KLMessages[index].GetObject("KillerName").SetText(KillerName);

	SGRI.KillMessagesCount++;

	SGRI.SetTimer(3.0, false, 'DestroyKLMessage');
}

//reliable client function DestroyKLMessage()
//{
//	local int i;

//	//WorldInfo.Game.Broadcast(self, KLMessages.length@SSGameReplicationInfo(WorldInfo.GRI).KillMessagesCount);

//	for(i = 0; i < KLMessages.Length; i++)
//	{
//		KLMessages[i].Invoke("removeMovieClip", args);
//	}

//	KLMessages.Remove(0, KLMessages.Length);
//	SSGameReplicationInfo(WorldInfo.GRI).KillMessagesCount = 0;
//}

function ThrowWeaponOnDeath()
{
	if((SSMapInfo != none && !SSMapInfo.bAllPawnsCanDropWeap) || !SSWeapBase(Weapon).bCanThrowWeap)
	{
		SSWeapBase(Weapon).DetachToPawn(self, Mesh);
		NewWeaponAttach.DetachToPawn(Mesh);
	}

	else
		super.ThrowWeaponOnDeath();
}

//function ThrowActiveWeapon(optional bool bDestroyWeap)
//{
//	InvManager.DiscardInventory();
//	//Mesh.DetachComponent(Weapon.Mesh);

//	super.ThrowActiveWeapon(bDestroyWeap);
//}

simulated function SwitchWeapon(byte NewGroup)
{
	if(SSInventoryManager(InvManager) != None)
	{
		SSInventoryManager(InvManager).SwitchWeapon(NewGroup);
	}
}

simulated function PostBeginPlay()
{
	super.PostBeginPlay();

	SSMapInfo = SSMapInfo(WorldInfo.GetMapInfo());
	bInitSpawn = true;
	Mesh.AttachComponentToSocket(RadialBlur, 'BlurEffect');
	Mesh.AttachComponentToSocket(NameEffect, 'CameraView');

	SetSkin();

	SSPlayerController(Controller).IgnoreMoveInput(false);
	SSPlayerController(Controller).IgnoreLookInput(false);

	SetTimer(0.1, false, 'InitChanges');
	SetTimer(3.0, false, 'TurnOffGodMode');

	SetHealthBlur();

	Mesh.AttachComponentToSocket(SMAmmo, 'AmmoPoint');

	//InvManager.SetCurrentWeapon(InitWeapons[0]);
	//WorldInfo.Game.Broadcast(self, GroundSpeed);
}

simulated function SetHealthBlur()
{
	BlurHealthSettings.bOverride_EnableDOF = TRUE;
	BlurHealthSettings.bEnableDOF = true;
	BlurHealthSettings.bOverride_DOF_BlurKernelSize = true;
	BlurHealthSettings.DOF_BlurKernelSize = 1.0;
	BlurHealthSettings.bOverride_DOF_FocusInnerRadius = true;
	BlurHealthSettings.DOF_FocusInnerRadius = 30;
	BlurHealthSettings.bOverride_DOF_MaxNearBlurAmount = TRUE;
	BlurHealthSettings.bOverride_DOF_MaxFarBlurAmount = TRUE;
	BlurHealthSettings.DOF_MaxNearBlurAmount = 0.95;
	BlurHealthSettings.DOF_MaxFarBlurAmount = 0.95;
	BlurHealthSettings.bOverride_DOF_FalloffExponent = TRUE;
	BlurHealthSettings.DOF_FalloffExponent = 0.6;
	BlurHealthSettings.bOverride_DOF_FocusType = TRUE;
	BlurHealthSettings.DOF_FocusType = FOCUS_Distance;
	BlurHealthSettings.bOverride_DOF_FocusDistance = TRUE;
	BlurHealthSettings.bOverride_DOF_InterpolationDuration = TRUE;
	BlurHealthSettings.DOF_InterpolationDuration = 0;
}

simulated function SetSkin()
{
	local int i;

	for(i = 0; i < Mesh.SkeletalMesh.Materials.Length; i++)
	{
		BodyMaterialInstances[i] = Mesh.CreateAndSetMaterialInstanceConstant(i);
	}
	
	//BodyMaterialInstances[1] = Mesh.CreateAndSetMaterialInstanceConstant(1);
}

simulated function SetMIC(int Valor)
{
	local int i;

	for(i = 0; i < Mesh.SkeletalMesh.Materials.Length; i++)
	{
		BodyMaterialInstances[i].SetScalarParameterValue('Target', Valor);
	}
	//BodyMaterialInstances[1].SetScalarParameterValue('Target', Valor);
}


function bool DoJump(bool bUpdating)
{
	if(SSPlayerController(Controller).Stamina >= 1 && Physics != PHYS_Falling && !SSPlayerController(Controller).bHoldDuck)
	{
		SSPlayerController(Controller).Stamina -= 1;
		//SSPlayerController(Controller).ClearTimer('StaminaAdd');
		if(!SSPlayerController(Controller).IsTimerActive('ModifyStamina'))
			SSPlayerController(Controller).SetTimer(0.1, true, 'ModifyStamina');
		return super.DoJump(bUpdating);
	}

	return false;
}

simulated function InitChanges()
{
	//local SSPawn P;

	GroundSpeed = Velocidade;
	JumpZ = NewJumpZ;
	SSPlayerController(Controller).SwitchWeapon(0);
	//SetVisibleHUD(true);

	if(Mesh.bClothAwakeOnStartup)
		Mesh.SetEnableClothSimulation(true);

	//WorldInfo.Game.Broadcast(self, Role@WorldInfo.NetMode@RemoteRole);

	//foreach WorldInfo.AllPawns(class'SSPawn', P)
	//{
	//	if(P != self && P.PlayerReplicationInfo.Team.TeamIndex != PlayerReplicationInfo.Team.TeamIndex)
	//		SetVisibleName(true, P);
	//}
	//SetFPMesh();
}

simulated function FaceRotation(rotator NewRotation, float DeltaTime)
{
	local Rotator NewViewRotation;

	super.FaceRotation(NewRotation, DeltaTime);

	NewViewRotation = FPMesh.Rotation;
	NewViewRotation.Pitch = GetViewRotation().Pitch;

	FPMesh.SetRotation(NewViewRotation);

	//WorldInfo.Game.Broadcast(self, GetViewRotation().Yaw@FPMesh.Rotation.Yaw);
}

//reliable client function SetVisibleName(bool NewVisible, SSPawn P)
//{
//	P.NameEffect.SetHidden(NewVisible);
//}

simulated function RenderNames(HUD HUD)
{
	local SSPawn P;
	local Vector TargetPos, Distance;

	foreach WorldInfo.AllPawns(class'SSPawn', P)
	{
		if(P != self && P.PlayerReplicationInfo.Team == PlayerReplicationInfo.Team)
		{
			if(WorldInfo.TimeSeconds - P.LastRenderTime < 0.1)
			{
				//HUD.Canvas.Font = MultiFont'testespack.Fonts.FrakCircus';
				if(P.PlayerReplicationInfo.Team.TeamIndex == 0)
					HUD.Canvas.DrawColor = SSWeapBase(Weapon).CrosshairEnemyColor;
				else
					HUD.Canvas.DrawColor = SSWeapBase(Weapon).CrosshairFriedlyColor;

				Distance = (VSize2D(P.Location - Location) / 20) * vect(0,0,1);
				TargetPos = HUD.Canvas.Project(P.Location + (P.GetCollisionHeight() * vect(0,0,1)) + Distance);
				HUD.Canvas.SetPos(TargetPos.X - ((Len(P.PawnName) / 2) * 10), TargetPos.Y);
				////HUD.Canvas.TextSize(P.PawnName, );
				HUD.Canvas.DrawText(P.PawnName);
			}
		}
	}
}

reliable client function SetVisibleHUD(bool NewVisible)
{
	SSHUD(SSPlayerController(Controller).myHUD).SetHUDMovieVisible(NewVisible);

	if(NewVisible)
		SSHUD(SSPlayerController(Controller).myHUD).ResolutionChanged();
}

//function SetFPMesh()
//{
//	FPMesh.SetSkeletalMesh(Mesh.SkeletalMesh);
//	FPMesh.SetAnimTreeTemplate(Mesh.AnimTreeTemplate);
//	FPMesh.SetPhysicsAsset(Mesh.PhysicsAsset);
//	FPMesh.AnimSets[0] = Mesh.AnimSets[0];
//	FPMesh.AnimSets[1] = Mesh.AnimSets[1];
//	FPAimNode = AnimNodeAimOffset(FPMesh.FindAnimNode('AimNode'));
//}

reliable client function SetRadialBlurEnable(bool bEnable)
{
	RadialBlur.SetEnabled(bEnable);
}

simulated function TurnOffGodMode()
{
	bInitSpawn = false;
	//WorldInfo.Game.Broadcast(self, GroundSpeed);
}

event StuckOnPawn(Pawn OtherPawn)
{
	WorldInfo.Game.Broadcast(self,"StuckOnPawn");
}
simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	local UDKAnimNodeSeqWeap BlendByWeaponType;
	local UDKAnimBlendByWeapType WeapType;

	if(SkelComp == Mesh)
	{
		//LeftLegControl = SkelControlFootPlacement(Mesh.FindSkelControl(LeftFootControlName));
		//RightLegControl = SkelControlFootPlacement(Mesh.FindSkelControl(RightFootControlName));
		//FeignDeathBlend = AnimNodeBlend(Mesh.FindAnimNode('FeignDeathBlend'));
		FullBodyAnimSlot = AnimNodeSlot(Mesh.FindAnimNode('FullBodySlot'));
		TopHalfAnimSlot = AnimNodeSlot(Mesh.FindAnimNode('TopHalfSlot'));

		//LeftHandIK = SkelControlLimb(mesh.FindSkelControl('LeftHandIK'));

		//RightHandIK = SkelControlLimb(mesh.FindSkelControl('RightHandIK'));

		//RootRotControl = SkelControlSingleBone(mesh.FindSkelControl('RootRot'));
		AimNode = AnimNodeAimOffset(mesh.FindAnimNode('AimNode')); 
		//GunRecoilNode = GameSkelCtrl_Recoil(mesh.FindSkelControl('GunRecoilNode'));
		//LeftRecoilNode = GameSkelCtrl_Recoil(mesh.FindSkelControl('LeftRecoilNode'));
		//RightRecoilNode = GameSkelCtrl_Recoil(mesh.FindSkelControl('RightRecoilNode'));

		//DrivingNode = UTAnimBlendByDriving(mesh.FindAnimNode('DrivingNode'));
		//VehicleNode = UTAnimBlendByVehicle(mesh.FindAnimNode('VehicleNode'));
		//HoverboardingNode = UTAnimBlendByHoverboarding(mesh.FindAnimNode('Hoverboarding'));

		//FlyingDirOffset = AnimNodeAimOffset(mesh.FindAnimNode('FlyingDirOffset'));


		LeftAim = SkelControlLimb(Mesh.FindSkelControl('LeftIKControl'));
		RunningBlend = AnimNodeBlend(Mesh.FindAnimNode('RunningBlend'));

		//FullBodyAnimSlot = AnimNodeSlot(FPMesh.FindAnimNode('FullBodySlot'));
		//TopHalfAnimSlot = AnimNodeSlot(FPMesh.FindAnimNode('TopHalfSlot'));
		//FPAimNode = AnimNodeAimOffset(FPMesh.FindAnimNode('AimNode'));
		//LeftAim = SkelControlLimb(FPMesh.FindSkelControl('LeftIKControl'));

		foreach mesh.AllAnimNodes(class'UDKAnimBlendByWeapType', WeapType) 
		{
			WeaponAnimTypes.AddItem(WeapType);
		}

		foreach Mesh.AllAnimNodes(class'UDKAnimNodeSeqWeap', BlendByWeaponType) 
		{
			WeaponTypeAnimNodes.AddItem(BlendByWeaponType);
		}
	}

	FPFullBodyAnimSlot = AnimNodeSlot(FPMesh.FindAnimNode('FullBodySlot'));
	FPTopHalfAnimSlot = AnimNodeSlot(FPMesh.FindAnimNode('TopHalfSlot'));
}

//simulated function SetAim()
//{
//}

//simulated function UpdateAimNode(rotator NewRotation)
//{
//}

//reliable server function ServerUpdateAimNode(rotator NewRotation)
//{
//}

//simulated function Tick(float DeltaTime)
//{
//	//local string URL;
//	//local OnlineSubsystem OnlineSub;

//	//if(SSWeapBase(Weapon).bReloading)
//	//{
//	//	LeftAim.SetSkelControlActive(true);

//	//	LeftAim.EffectorLocation = SkeletalMeshComponent(Weapon.Mesh).GetBoneLocation('Mag');
//	//}

//	//else
//	//	LeftAim.SetSkelControlActive(false);

//	super.Tick(DeltaTime);

//	////GetIPServer();

//	//OnlineSub = class'GameEngine'.static.GetOnlineSubsystem();
//	//OnlineSub.GameInterface.GetResolvedConnectString('Game',URL);

//	if(Role < ROLE_Authority)
//		WorldInfo.Game.Broadcast(self, PawnName);
//}

simulated function GetIPServer()
{
	local int IPServer, ServerPort;

	WorldInfo.Game.AccessControl.CachedAuthInt.GetServerAddr(IPServer, ServerPort);

	WorldInfo.Game.Broadcast(self, WorldInfo.Game.AccessControl.CachedAuthInt@IPServer);
}

simulated event StartCrouch(float HeightAdjust)
{	
	local vector MeshZ;
	local Vector LastLocZ;

	//HeightAdjust = 0;
	//Super.StartCrouch(HeightAdjust);

	MeshZ.Z -= HeightAdjust;
	LastLocZ = Location;
	//LastLocZ.Z = HeightAdjust;

	CollisionComponent.SetTranslation(MeshZ);
	SetLocation(LastLocZ);
}

simulated event EndCrouch(float HeightAdjust)
{
	local Vector LastLocZ;
	//OldZ += HeightAdjust;
	//Super.EndCrouch(HeightAdjust);

	//// offset mesh by height adjustment
	//CrouchMeshZOffset = 0.0;
	
	LastLocZ = Location;
	LastLocZ.Z -= HeightAdjust;

	CollisionComponent.SetTranslation(vect(0,0,0));
	SetLocation(LastLocZ);
}

reliable client function ClientSetHiddenAmmoMesh(bool NewVisible, StaticMesh NewMesh)
{
	SMAmmo.SetStaticMesh(NewMesh);
	SMAmmo.SetHidden(NewVisible);
}

simulated function WeaponFired(Weapon InWeapon, bool bViaReplication, optional vector HitLocation)
{
	if(NewWeaponAttach != none)
		NewWeaponAttach.PlayMuzzleEffect();

	super.WeaponFired(InWeapon, bViaReplication, HitLocation);
}

simulated function WeaponStoppedFiring(Weapon InWeapon, bool bViaReplication)
{
	if(NewWeaponAttach != none)
		NewWeaponAttach.StopMuzzleEffect();
}

simulated function PlayImpactEffects(ImpactInfo Impact)
{
	if(NewWeaponAttach != none)
		NewWeaponAttach.PlayImpactEffects(Impact);
}

simulated function ReloadingWeap()
{
	if(NewWeaponAttach != none)
		NewWeaponAttach.ReloadingWeap();
}

reliable server function HiddenMatChange(float Value)
{
	if(NewWeaponAttach != none)
	{
		NewWeaponAttach.HiddenMatChange(Value);
		ClientHiddenMatChange(Value);
	}

	//AttachHiddenMatValue = -1;
}

reliable client function ClientHiddenMatChange(float Value)
{
	if(NewWeaponAttach != none)
	{
		NewWeaponAttach.HiddenMatChange(Value);
	}

	AttachHiddenMatValue = -1;
}

simulated function AttachWeapon()
{
	//local int i;
	//local array<SSWeapBase> WeaponList;

	if(NewWeaponAttach != None)
	{
		NewWeaponAttach.DetachToPawn(Mesh);
		//Mesh.DetachComponent(NewWeaponAttach.Mesh);
		NewWeaponAttach.Destroy();
	}

	if(WeaponAttachClass != none)
	{
		NewWeaponAttach = Spawn(WeaponAttachClass,self);
		if(NewWeaponAttach != None)
		{
			NewWeaponAttach.AttachToPawn(Self);
			NewWeaponAttach.Instigator = Self;
		}
	}

	if(WeaponAttachArchetype != none)
	{
		NewWeaponAttach = Spawn(WeaponAttachArchetype.Class, self,,,,WeaponAttachArchetype);
		SSWeapBase(Weapon).AttachToPawn(self);
		if (NewWeaponAttach != None)
		{
			NewWeaponAttach.AttachToPawn(Self);
			NewWeaponAttach.SetSkin(ReplicatedBodyMaterial);
			NewWeaponAttach.Instigator = Self;
		}
	}
	
	//SSInventoryManager(InvManager).GetWeaponList(WeaponList);
   
	//for(i=0;i<WeaponList.Length;i++)
	//{
	//	WorldInfo.Game.Broadcast(self, self@WeaponList[i]);
	//}

	//WorldInfo.Game.Broadcast(self, WeaponAttachClass@NewWeaponAttach@Weapon.Class);
}

//simulated function Suicide()
//{
//	if(SSWeapBase(Weapon) != None)
//		DestroyWeapon();

//	KilledBy(self);
//}

exec function DestroyWeapon()
{
	SSWeapBase(Weapon).DetachToPawn(self, FPMesh);
	NewWeaponAttach.DetachToPawn(Mesh);

	InvManager.RemoveFromInventory(Weapon);
	ServerDestroyWeapon();
}

reliable server function ServerDestroyWeapon()
{
	InvManager.RemoveFromInventory(Weapon);
}

//simulated function ProcessViewRotation(float DeltaTime, out rotator out_ViewRotation, out Rotator out_DeltaRot)
//{
//	if(Weapon != none)
//		SSWeapBase(Weapon).ProcessViewRotation(DeltaTime, out_ViewRotation, out_DeltaRot);

//	out_ViewRotation += out_DeltaRot;
//	out_DeltaRot = rot(0,0,0);

//	if(PlayerController(Controller) != none)
//		out_ViewRotation = PlayerController(Controller).LimitViewRotation(out_ViewRotation, ViewPitchMin, ViewPitchMax);

//	//super.ProcessViewRotation(DeltaTime, out_ViewRotation, out_DeltaRot);
//}

//reliable server function ServerAimViewRotation()
//{
//	AimNode.Aim.Y = AimView;

//	WorldInfo.Game.Broadcast(self, RemoteViewPitch);
//}

//simulated function RenderMinimapIcon(HUD HUD, int MinimapSize, int MinimapLocationX, int MinimapLocationY, PlayerReplicationInfo RenderingPlayerReplicationInfo)
//{
//	//local SSMapInfo SSMapInfo;
//	local int IconSize;

//	local Texture2D PawnIcon;

//	local Rotator PawnIconRot;

//	// Check if I am dead
//	if(Health <= 0)
//	{
//		return;
//	}

//	// Get the SS map info
//	//SSMapInfo = SSMapInfo(WorldInfo.GetMapInfo());
//	if(SSMapInfo == None)
//	{
//		return;
//	}

//	IconSize = SSMapInfo.IconSize;  // 8 padrão
//	HUD.Canvas.SetPos(MinimapLocationX - (IconSize * 0.5f), MinimapLocationY - (IconSize * 0.5f));
//	HUD.Canvas.SetDrawColor(255, 255, 255);

//	PawnIcon = PlayerReplicationInfo.Team.TeamIndex == 1 ? SSMapInfo.MinimapBluePawnTexture : SSMapInfo.MinimapRedPawnTexture;
//	PawnIconRot.Yaw = SSMapInfo.MinimapPawnIconRotation * DegToUnrRot;
//	//if(PlayerReplicationInfo.Team.TeamIndex == 0)
//	//	PawnIcon = SSMapInfo.MinimapRedPawnTexture;

//	//else if(PlayerReplicationInfo.Team.TeamIndex == 1)
//	//	PawnIcon = SSMapInfo.MinimapBluePawnTexture;

//	//else
//	//	PawnIcon = SSMapInfo.MinimapRedPawnTexture;

//	// Render the icon for myself
//	if(RenderingPlayerReplicationInfo == PlayerReplicationInfo)
//	{		
//		if (SSMapInfo.MinimapPlayerPawnTexture != None)
//		{
//			//HUD.Canvas.DrawTile(SSMapInfo.MinimapPlayerPawnTexture, IconSize, IconSize, 0.f, 0.f, SSMapInfo.MinimapPlayerPawnTexture.SizeX, SSMapInfo.MinimapPlayerPawnTexture.SizeY);
//			HUD.Canvas.DrawRotatedTile(SSMapInfo.MinimapPlayerPawnTexture, (Rotation - PawnIconRot), IconSize, 
//				IconSize, 0.f, 0.f, SSMapInfo.MinimapPlayerPawnTexture.SizeX, SSMapInfo.MinimapPlayerPawnTexture.SizeY);
//		}
//	}
//	else
//	{
//	//	// Render the icon for an enemy
//		if(RenderingPlayerReplicationInfo.Team != PlayerReplicationInfo.Team && !SSMapInfo.bRenderEnemies)
//		{
//			//if (SSMapInfo.MinimapEnemyPawnTexture != None)
//			//{
//			//	HUD.Canvas.DrawTile(SSMapInfo.MinimapEnemyPawnTexture, IconSize, IconSize, 0.f, 0.f, SSMapInfo.MinimapEnemyPawnTexture.SizeX, SSMapInfo.MinimapEnemyPawnTexture.SizeY);
//			//}
//		}
//		// Render the icon for a friend
//		else
//		{
//			if(SSMapInfo.MinimapRedPawnTexture != None)
//			{
//				HUD.Canvas.DrawRotatedTile(PawnIcon, (Rotation - PawnIconRot), IconSize, IconSize, 0.f, 0.f, 
//					SSMapInfo.MinimapRedPawnTexture.SizeX, SSMapInfo.MinimapRedPawnTexture.SizeY);

//				//HUD.Canvas.DrawTile(PawnIcon, IconSize, IconSize, 0.f, 0.f, SSMapInfo.MinimapRedPawnTexture.SizeX, 
//				//	SSMapInfo.MinimapRedPawnTexture.SizeY);
//			}
//		}
//	}
//}

simulated function RenderMinimapIcon(HUD HUD, int MinimapSize, int MinimapLocationX, int MinimapLocationY, PlayerReplicationInfo RenderingPlayerReplicationInfo)
{
	//local SSMapInfo SSMapInfo;
	local Rotator PawnIconRot;

	if(Health <= 0)
	{
		//HUD.Canvas.SetPos(0, 0);
		//HUD.Canvas.DrawColor = MakeColor(255,0,0,255);
		//HUD.Canvas.DrawText(SSGameReplicationInfo(WorldInfo.GRI).KillMessages,,1.0,1.0);

		//if(SSGameReplicationInfo(WorldInfo.GRI).bNewMessage)
		//{
		//	SSHUD(HUD).HUDMovie.CreateKLMessage(SSGameReplicationInfo(WorldInfo.GRI).KillMessages);
		//	SSGameReplicationInfo(WorldInfo.GRI).bNewMessage = false;
		//}

		if(SSHUD(HUD).HUDMovie.Minimap.Mapa.GetObject(string(self)) != none)
			SSHUD(HUD).DestroyPlayerIcons(string(self));

		if(SSHUD(HUD).HUDMovie.Minimap.Mapa.GetObject(string(self)$"Dir") != none)
			SSHUD(HUD).DestroyPlayerIcons(string(self)$"Dir");
		return;
	}   

	SSMapInfo = SSMapInfo(WorldInfo.GetMapInfo());
	if(SSMapInfo == None)
		return;

	PawnIconRot.Yaw = Rotation.Yaw - (SSMapInfo.MinimapPawnIconRotation * DegToUnrRot);

	if(RenderingPlayerReplicationInfo == PlayerReplicationInfo)
	{	
		if(IconDir == none && GetStateName() != 'Dying')
		{
			if(SSHUD(HUD).HUDMovie.Minimap.Mapa.GetObject(string(self)$"Dir") != none)
			{
				SSHUD(HUD).DestroyPlayerIcons(string(self)$"Dir");
				DestroyIcons();
			}

			IconDir = SSHUD(HUD).HUDMovie.Minimap.Mapa.AttachMovie("IconDirection", string(self)$"Dir");
			IconDir.SetFloat("_xscale", SSMapInfo.IconSize);
			IconDir.SetFloat("_yscale", SSMapInfo.IconSize);
		}

		if(IconDir != none)
		{
			IconDir.SetFloat("_x", MinimapLocationX);
			IconDir.SetFloat("_y", MinimapLocationY);
			IconDir.SetFloat("_rotation", PawnIconRot.Yaw * UnrRotToDeg);
		}

		if(PlayerIcon == none && GetStateName() != 'Dying')
		{
			if(SSHUD(HUD).HUDMovie.Minimap.Mapa.GetObject(string(self)) != none)
			{
				SSHUD(HUD).DestroyPlayerIcons(string(self));
				DestroyIcons();
			}

			PlayerIcon = SSHUD(HUD).HUDMovie.Minimap.Mapa.AttachMovie("IconPlayer", string(self));
			PlayerIcon.GotoAndStopI(PlayerReplicationInfo.Team.TeamIndex + 1);
			PlayerIcon.SetFloat("_xscale", SSMapInfo.IconSize * 1.5);
			PlayerIcon.SetFloat("_yscale", SSMapInfo.IconSize * 1.5);

			//WorldInfo.Game.Broadcast(self, "NewPlayerIcon"@self@PlayerIcon@Health@GetStateName());
		}

		if(PlayerIcon != none)
		{
			PlayerIcon.SetFloat("_x", MinimapLocationX);
			PlayerIcon.SetFloat("_y", MinimapLocationY);
		}
	}
	else
	{
		if(RenderingPlayerReplicationInfo.Team != PlayerReplicationInfo.Team && !SSMapInfo.bRenderEnemies)
		{
			if(SSHUD(HUD).HUDMovie.Minimap.Mapa.GetObject(string(self)) != none)
			{
				SSHUD(HUD).DestroyPlayerIcons(string(self));
				DestroyIcons();
			}
		}

		else
		{
			if(PlayerIcon == none && GetStateName() != 'Dying')
			{
				if(SSHUD(HUD).HUDMovie.Minimap.Mapa.GetObject(string(self)) != none)
				{
					SSHUD(HUD).DestroyPlayerIcons(string(self));
					DestroyIcons();
				}

				PlayerIcon = SSHUD(HUD).HUDMovie.Minimap.Mapa.AttachMovie("IconFriendly", string(self));
				PlayerIcon.GotoAndStopI(PlayerReplicationInfo.Team.TeamIndex + 1);
				PlayerIcon.SetFloat("_xscale", SSMapInfo.IconSize);
				PlayerIcon.SetFloat("_yscale", SSMapInfo.IconSize);

				//WorldInfo.Game.Broadcast(self, "NewFriendlyIcon"@self@PlayerIcon@Health@GetStateName());
			}

			if(PlayerIcon != none)
			{
				PlayerIcon.SetFloat("_x", MinimapLocationX);
				PlayerIcon.SetFloat("_y", MinimapLocationY);
			}
		}
	}
}

simulated function Vector GetMinimapWorldLocation()
{
	return Location;
}

simulated function DestroyIcons()
{
	if(PlayerIcon != none)
	{
		PlayerIcon.Invoke("removeMovieClip", args);
		//SSHUD(SSPlayerController(Controller).myHUD).HUDMovie.Minimap.Mapa.GetObject(string(self)).Invoke("removeMovieClip", args);
		PlayerIcon = none;
	}

	if(IconDir != none)
	{
		IconDir.Invoke("removeMovieClip", args);
		IconDir = none;
	}

	//WorldInfo.Game.Broadcast(self, self@PlayerIcon);
}

simulated function RenderStats(HUD HUD, float TextScale)
{
	//local SSWeapBase W;
	//local int TeamEnemy;
	//local float CurrentStamina;

	//HUD.Canvas.SetPos(0, 0);
	//HUD.Canvas.DrawColor = MakeColor(255,0,0,255);
	//HUD.Canvas.DrawText("Health:"$Health,,TextScale,TextScale);

	HUD.Canvas.SetPos(0, 60 * TextScale);
	HUD.Canvas.DrawColor = MakeColor(0,155,155,255);
	HUD.Canvas.DrawText("Name:"$PawnName,,TextScale,TextScale);

	//HUD.Canvas.SetPos(0, 80 * TextScale);
	//HUD.Canvas.DrawColor = MakeColor(255,255,0,255);
	//HUD.Canvas.DrawText("Score:"$int(PlayerReplicationInfo.Score),,TextScale,TextScale);

	//HUD.Canvas.SetPos(0, 100 * TextScale);
	//HUD.Canvas.DrawColor = MakeColor(255,255,0,255);
	//HUD.Canvas.DrawText("Kills:"$SSPlayerReplicationInfo(PlayerReplicationInfo).Frags,,TextScale,TextScale);

	//HUD.Canvas.SetPos(0, 120 * TextScale);
	//HUD.Canvas.DrawColor = MakeColor(255,255,0,255);
	//HUD.Canvas.DrawText("Deaths:"$PlayerReplicationInfo.Deaths,,TextScale,TextScale);

	//HUD.Canvas.SetPos(0, 140 * TextScale);
	//HUD.Canvas.DrawColor = MakeColor(255,255,0,255);
	//HUD.Canvas.DrawText("Team Score:"$SSTeamInfo(PlayerReplicationInfo.Team).ScoreTeam,,TextScale,TextScale);

	//HUD.Canvas.SetPos(0, 160 * TextScale);
	//HUD.Canvas.DrawColor = MakeColor(255,255,0,255);
	//TeamEnemy = PlayerReplicationInfo.Team.TeamIndex == 0? 1: 0;
	//HUD.Canvas.DrawText("Team Score Enemy:"$SSTeamInfo(WorldInfo.GRI.Teams[TeamEnemy]).ScoreTeam,,TextScale,TextScale);

	//HUD.Canvas.SetPos(0, 180 * TextScale);
	//HUD.Canvas.DrawColor = MakeColor(255,165,0,255);

	//CurrentStamina = SSPlayerController(Controller).Stamina;
	//if(CurrentStamina > 5 && CurrentStamina <= 6)
	//	HUD.Canvas.DrawText("Stamina:"$"======"@CurrentStamina,,TextScale,TextScale);
	//else if(CurrentStamina > 4 && CurrentStamina <= 5)
	//	HUD.Canvas.DrawText("Stamina:"$"====="@CurrentStamina,,TextScale,TextScale);
	//else if(CurrentStamina > 3 && CurrentStamina <= 4)
	//	HUD.Canvas.DrawText("Stamina:"$"===="@CurrentStamina,,TextScale,TextScale);
	//else if(CurrentStamina > 2 && CurrentStamina <= 3)
	//	HUD.Canvas.DrawText("Stamina:"$"==="@CurrentStamina,,TextScale,TextScale);
	//else if(CurrentStamina > 1 && CurrentStamina <= 2)
	//	HUD.Canvas.DrawText("Stamina:"$"=="@CurrentStamina,,TextScale,TextScale);
	//else if(CurrentStamina > 0.2 && CurrentStamina <= 1)
	//	HUD.Canvas.DrawText("Stamina:"$"="@CurrentStamina,,TextScale,TextScale);
	//else if(CurrentStamina <= 0.2)
	//	HUD.Canvas.DrawText("Stamina:"@CurrentStamina,,TextScale,TextScale);
	////HUD.Canvas.DrawText("Stamina:"$SSPlayerController(Controller).Stamina,,TextScale,TextScale);

	//W = SSWeapBase(Weapon);
	//if(W != none)
	//{
	//	HUD.Canvas.SetPos(0, 20 * TextScale);
	//	HUD.Canvas.DrawColor = MakeColor(0,0,255,255);
	//	HUD.Canvas.DrawText("Ammo:"$W.CurrentAmmoCount,,TextScale,TextScale);
	//	HUD.Canvas.SetPos(0, 40 * TextScale);
	//	HUD.Canvas.DrawColor = MakeColor(0,0,255,255);
	//	HUD.Canvas.DrawText("ReserveAmmo:"$W.ReserveAmmo,,TextScale,TextScale);
	//}
}

simulated function bool TakeHeadShot(ImpactInfo Impact, Vector HitNormal)
{
	if(IsLocationOnHead(Impact, 1.0f))
		return true;
		
	return false;
}

function bool IsLocationOnHead(const out ImpactInfo Impact, float AdditionalScale)
{
	local vector HeadLocation;
	local float Distance;

	if (HeadBone == '')
	{
		return False;
	}

	Mesh.ForceSkelUpdate();
	HeadLocation = Mesh.GetBoneLocation(HeadBone) + vect(0,0,1) * HeadHeight;

	// Find distance from head location to bullet vector
	Distance = PointDistToLine(HeadLocation, Impact.RayDir, Impact.HitLocation);

	return (Distance < (HeadRadius * AdditionalScale));
}

simulated function vector GetViewCam()
{
	local Vector SocketLoc;

	FPMesh.GetSocketWorldLocationAndRotation('CameraView', SocketLoc);

	return SocketLoc;
}

simulated function float GetViewFOV()
{
	return SSPlayerController(Controller).DefaultFOV;
}

simulated function bool CalcCamera(float fDeltaTime, out vector out_CamLoc, out rotator out_CamRot, out float out_FOV)
{
	out_CamLoc = GetViewCam();
	out_CamRot = GetViewRotation();

	//ViewRotation = Instigator.GetViewRotation();

	//ViewRotation.Pitch += Rand(10) - Rand(10);
	//SSPlayerController(Instigator.Controller).SetRotation(ViewRotation);

	//if(bFeigningDeath || FeignDeathBlend.Child2WeightTarget > 0.0)
	//	out_CamRot = SocketRot;

	if(!SSPlayerController(Controller).bSpectator)
		out_FOV = GetViewFOV();

	return true;
}

//simulated function WeaponAttachmentChanged()
//{
//	if ((SSCurrentWeaponAttachment == None || SSCurrentWeaponAttachment.Class != CurrentWeaponAttachmentClass) && Mesh.SkeletalMesh != None)
//	{
//		// Detach/Destroy the current attachment if we have one
//		if (SSCurrentWeaponAttachment != None)
//		{
//			SSCurrentWeaponAttachment.DetachFrom(Mesh);
//			SSCurrentWeaponAttachment.Destroy();
//		}
		
//		if (SSCurrentWeaponAttachmentClass!=None)
//		{
//			SSCurrentWeaponAttachment = Spawn(SSCurrentWeaponAttachmentClass,self);
//			SSCurrentWeaponAttachment.Instigator = self;
//		}
		
//		else
//			SSCurrentWeaponAttachment = none;

//		// If all is good, attach it to the Pawn's Mesh.
//		if (SSCurrentWeaponAttachment != None)
//		{
//			SSCurrentWeaponAttachment.AttachTo(self);
//			//SSCurrentWeaponAttachment.SetSkin(ReplicatedBodyMaterial);
//			SSCurrentWeaponAttachment.ChangeVisibility(bWeaponAttachmentVisible);
//		}
//	}

//	super.WeaponAttachmentChanged();
//}

//simulated function SetWeaponAttachmentVisibility(bool bAttachmentVisible)
//{
//	if (SSCurrentWeaponAttachment != None)
//	{
//		SSCurrentWeaponAttachment.ChangeVisibility(bAttachmentVisible);
//	}

//	super.SetWeaponAttachmentVisibility(bAttachmentVisible);
//}

simulated event PlayFootStepSound(int FootDown)
{
	local SoundCue FootSound;

	FootSound = SoundCue'A_Character_Footsteps.FootSteps.A_Character_Footstep_StoneCue';
	PlaySound(FootSound, false, true,,, true);
}

simulated event Destroyed()
{
	super.Destroyed();

	//if (SSCurrentWeaponAttachment != None)
	//{
	//	SSCurrentWeaponAttachment.DetachFrom(Mesh);
	//	SSCurrentWeaponAttachment.Destroy();
	//}
}

simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
	local vector ApplyImpulse, ShotDir;
	local TraceHitInfo HitInfo;
	//local PlayerController PC;
	local bool /*bPlayersRagdoll,*/ bUseHipSpring;
	local class<SSDamageType> SSDamageType;
	local RB_BodyInstance HipBodyInst;
	local int HipBoneIndex;
	local matrix HipMatrix;
	//local class<UDKEmitCameraEffect> CameraEffect;
	//local name HeadShotSocketName;
	//local SkeletalMeshSocket SMS;

	bCanTeleport = false;
	bReplicateMovement = false;
	bTearOff = true;
	bPlayedDeath = true;
	//bForcedFeignDeath = false;
	//bPlayingFeignDeathRecovery = false;

	HitDamageType = DamageType; // these are replicated to other clients
	TakeHitLocation = HitLoc;

	// make sure I don't have an active weaponattachment
	//CurrentWeaponAttachmentClass = None;
	//WeaponAttachmentChanged();

	//if (WorldInfo.NetMode == NM_DedicatedServer)
	//{
 //		SSDamageType = class<SSDamageType>(DamageType);
	//	// tell clients whether to gib
	//	bTearOffGibs = (SSDamageType != None && ShouldGib(SSDamageType));
	//	bGibbed = bGibbed || bTearOffGibs;
	//	GotoState('Dying');
	//	return;
	//}

	 //Is this the local player's ragdoll?
	//ForEach LocalPlayerControllers(class'PlayerController', PC)
	//{
	//	if(pc.ViewTarget == self)
	//	{
	//		//if (UTHud(pc.MyHud)!=none)
	//		//	UTHud(pc.MyHud).DisplayHit(HitLoc, 100, DamageType);
	//		bPlayersRagdoll = true;
	//		break;
	//	}
	//}
	//if ((WorldInfo.TimeSeconds - LastRenderTime > 3) && !bPlayersRagdoll)
	//{
	//	if (WorldInfo.NetMode == NM_ListenServer || WorldInfo.IsRecordingDemo())
	//	{
	//		if (WorldInfo.Game.NumPlayers + WorldInfo.Game.NumSpectators < 2 && !WorldInfo.IsRecordingDemo())
	//		{
	//			Destroy();
	//			return;
	//		}
	//		//bHideOnListenServer = true;

	//		// check if should gib (for clients)
	//		SSDamageType = class<SSDamageType>(DamageType);
	//		//if (SSDamageType != None && ShouldGib(SSDamageType))
	//		//{
	//		//	bTearOffGibs = true;
	//		//	bGibbed = true;
	//		//}
	//		TurnOffPawn();
	//		return;
	//	}
	//	else
	//	{
	//		// if we were not just controlling this pawn,
	//		// and it has not been rendered in 3 seconds, just destroy it.
	//		Destroy();
	//		return;
	//	}
	//}

	SSDamageType = class<SSDamageType>(DamageType);
	//if (SSDamageType != None && !class'UTGame'.static.UseLowGore(WorldInfo) && ShouldGib(SSDamageType))
	//{
	//	SpawnGibs(SSDamageType, HitLoc);
	//}
	//else
	//{
		CheckHitInfo(HitInfo, Mesh, Normal(TearOffMomentum), TakeHitLocation);

	//	// check to see if we should do a CustomDamage Effect
	//	if(SSDamageType != None)
	//	{
	//		if(SSDamageType.default.bUseDamageBasedDeathEffects)
	//		{
	//			SSDamageType.static.DoCustomDamageEffects(self, SSDamageType, HitInfo, TakeHitLocation);
	//		}

	//		if(UTPlayerController(PC) != none)
	//		{
	//			CameraEffect = SSDamageType.static.GetDeathCameraEffectVictim(self);
	//			if (CameraEffect != None)
	//			{
	//				UTPlayerController(PC).ClientSpawnCameraEffect(CameraEffect);
	//			}
	//		}
	//	}

		if(SSDamageType != None)
		{
			if(SSDamageType.default.bUseDamageBasedDeathEffects)
			{
				SSDamageType.static.DoCustomDamageEffects(self, SSDamageType, HitInfo, TakeHitLocation);
			}
		}

		//bBlendOutTakeHitPhysics = false;

		// Turn off hand IK when dead.
		//SetHandIKEnabled(false);

		// if we had some other rigid body thing going on, cancel it
		if (Physics == PHYS_RigidBody)
		{
			//@note: Falling instead of None so Velocity/Acceleration don't get cleared
			setPhysics(PHYS_Falling);
		}

		PreRagdollCollisionComponent = CollisionComponent;
		CollisionComponent = Mesh;

		Mesh.MinDistFactorForKinematicUpdate = 0.f;

		// If we had stopped updating kinematic bodies on this character due to distance from camera, force an update of bones now.
		if(Mesh.bNotUpdatingKinematicDueToDistance)
		{
			Mesh.ForceSkelUpdate();
			Mesh.UpdateRBBonesFromSpaceBases(TRUE, TRUE);
		}

		Mesh.PhysicsWeight = 1.0;

		if(SSDamageType != None && SSDamageType.default.DeathAnim != '' /*&& (FRand() > 0.5)*/)
		{
			// Don't want to use stop player and use hip-spring if in the air (eg PHYS_Falling)
			if(Physics == PHYS_Walking && SSDamageType.default.bAnimateHipsForDeathAnim)
			{
				SetPhysics(PHYS_None);
				bUseHipSpring=true;
			}
			else
			{
				SetPhysics(PHYS_RigidBody);
				// We only want to turn on 'ragdoll' collision when we are not using a hip spring, otherwise we could push stuff around.
				SetPawnRBChannels(TRUE);
			}

			Mesh.PhysicsAssetInstance.SetAllBodiesFixed(FALSE);

			// Turn on angular motors on skeleton.
			Mesh.bUpdateJointsFromAnimation = TRUE;
			Mesh.PhysicsAssetInstance.SetNamedMotorsAngularPositionDrive(false, false, NoDriveBodies, Mesh, true);
			Mesh.PhysicsAssetInstance.SetAngularDriveScale(1.0f, 1.0f, 0.0f);

			// If desired, turn on hip spring to keep physics character upright
			if(bUseHipSpring)
			{
				HipBodyInst = Mesh.PhysicsAssetInstance.FindBodyInstance(HipsName, Mesh.PhysicsAsset);
				HipBoneIndex = Mesh.MatchRefBone(HipsName);
				HipMatrix = Mesh.GetBoneMatrix(HipBoneIndex);
				HipBodyInst.SetBoneSpringParams(DeathHipLinSpring, DeathHipLinDamp, DeathHipAngSpring, DeathHipAngDamp);
				HipBodyInst.bMakeSpringToBaseCollisionComponent = FALSE;
				HipBodyInst.EnableBoneSpring(TRUE, TRUE, HipMatrix);
				HipBodyInst.bDisableOnOverextension = TRUE;
				HipBodyInst.OverextensionThreshold = 100.f;
			}

			FullBodyAnimSlot.PlayCustomAnim(SSDamageType.default.DeathAnim, SSDamageType.default.DeathAnimRate, 0.05, -1.0, false, false);
			SetTimer(0.1, true, 'DoingDeathAnim');
			StartDeathAnimTime = WorldInfo.TimeSeconds;
			TimeLastTookDeathAnimDamage = WorldInfo.TimeSeconds;
			//DeathAnimDamageType = SSDamageType;
		}
		else
		{
			SetPhysics(PHYS_RigidBody);
			Mesh.PhysicsAssetInstance.SetAllBodiesFixed(FALSE);
			SetPawnRBChannels(TRUE);

			if(TearOffMomentum != vect(0,0,0))
			{
				ShotDir = normal(TearOffMomentum);
				ApplyImpulse = ShotDir * DamageType.default.KDamageImpulse;

				// If not moving downwards - give extra upward kick
				if (Velocity.Z > -10)
				{
					ApplyImpulse += Vect(0,0,1)*DamageType.default.KDeathUpKick;
				}
				Mesh.AddImpulse(ApplyImpulse, TakeHitLocation, HitInfo.BoneName, true);
			}
		}
		GotoState('Dying');

		//if (WorldInfo.NetMode != NM_DedicatedServer && SSDamageType != None && SSDamageType.default.bSeversHead && !bDeleteMe)
		//{
		//	SpawnHeadGib(SSDamageType, HitLoc);

		//	if ( !class'UTGame'.Static.UseLowGore(WorldInfo) )
		//	{
		//		HeadShotSocketName = GetFamilyInfo().default.HeadShotGoreSocketName;
		//		SMS = Mesh.GetSocketByName( HeadShotSocketName );
		//		if( SMS != none )
		//		{
		//			HeadshotNeckAttachment = new(self) class'StaticMeshComponent';
		//			HeadshotNeckAttachment.SetActorCollision( FALSE, FALSE );
		//			HeadshotNeckAttachment.SetBlockRigidBody( FALSE );

		//			Mesh.AttachComponentToSocket( HeadshotNeckAttachment, HeadShotSocketName );
		//			HeadshotNeckAttachment.SetStaticMesh( GetFamilyInfo().default.HeadShotNeckGoreAttachment );
		//			HeadshotNeckAttachment.SetLightEnvironment( LightEnvironment );
		//		}
		//	}
		//}
	//}
}

simulated function TurnOffPawn()
{
	// hide everything, turn off collision
	if(Physics == PHYS_RigidBody)
	{
		Mesh.SetHasPhysicsAssetInstance(FALSE);
		Mesh.PhysicsWeight = 0.f;
		SetPhysics(PHYS_None);
	}
	if(!IsInState('Dying')) // so we don't restart Begin label and possibly play dying sound again
	{
		GotoState('Dying');
	}
	SetPhysics(PHYS_None);
	SetCollision(false, false);
	//@warning: can't set bHidden - that will make us lose net relevancy to everyone
	Mesh.SetHidden(true);

	//if (OverlayMesh != None)
	//{
	//	OverlayMesh.SetHidden(true);
	//}
}

simulated function DoingDeathAnim()
{
	local RB_BodyInstance HipBodyInst;
	local matrix DummyMatrix;
	local AnimNodeSequence SlotSeqNode;
	//local float TimeSinceDeathAnimStart, MotorScale;
	//local bool bStopAnim;


	//if(DeathAnimDamageType.default.MotorDecayTime != 0.0)
	//{
	//	TimeSinceDeathAnimStart = WorldInfo.TimeSeconds - StartDeathAnimTime;
	//	MotorScale = 1.0 - (TimeSinceDeathAnimStart/DeathAnimDamageType.default.MotorDecayTime);

	//	// If motors are scaled to zero, stop death anim
	//	if(MotorScale <= 0.0)
	//	{
	//		bStopAnim = TRUE;
	//	}
	//	// If non-zero, scale motor strengths
	//	else
	//	{
	//		Mesh.PhysicsAssetInstance.SetAngularDriveScale(MotorScale, MotorScale, 0.0f);
	//	}
	//}

	// If we want to stop animation after a certain
	//if(DeathAnimDamageType != None &&
	//	DeathAnimDamageType.default.StopAnimAfterDamageInterval != 0.0 &&
	//	(WorldInfo.TimeSeconds - TimeLastTookDeathAnimDamage) > DeathAnimDamageType.default.StopAnimAfterDamageInterval)
	//{
	//	bStopAnim = TRUE;
	//}


	// If done playing custom death anim - turn off bone motors.
	SlotSeqNode = AnimNodeSequence(FullBodyAnimSlot.Children[1].Anim);
	if(!SlotSeqNode.bPlaying /*|| bStopAnim*/)
	{
		SetPhysics(PHYS_RigidBody);
		Mesh.PhysicsAssetInstance.SetAllMotorsAngularPositionDrive(false, false);
		HipBodyInst = Mesh.PhysicsAssetInstance.FindBodyInstance(HipsName, Mesh.PhysicsAsset);
		HipBodyInst.EnableBoneSpring(FALSE, FALSE, DummyMatrix);

		// Ensure we have ragdoll collision on at this point
		SetPawnRBChannels(TRUE);

		ClearTimer('DoingDeathAnim');
		//DeathAnimDamageType = None;
	}
}

simulated function SetPawnRBChannels(bool bRagdollMode)
{
	Mesh.SetRBChannel((bRagdollMode) ? RBCC_Pawn : RBCC_Untitled3);
	Mesh.SetRBCollidesWithChannel(RBCC_Default, bRagdollMode);
	Mesh.SetRBCollidesWithChannel(RBCC_Pawn, bRagdollMode);
	Mesh.SetRBCollidesWithChannel(RBCC_Vehicle, bRagdollMode);
	Mesh.SetRBCollidesWithChannel(RBCC_Untitled3, true);
	Mesh.SetRBCollidesWithChannel(RBCC_BlockingVolume, bRagdollMode);
}

function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	DisablePawnProperties();

	return Super.Died(Killer, DamageType, HitLocation);
}

reliable client function DisablePawnProperties()
{
	local int i;

	for(i = 0; i < DamageIcon.Length; i++)
	{
		DamageIcon[i].IconHD.Invoke("removeMovieClip", args);
		DamageIcon[i].DmgInst = none;
		DamageIcon[i].DmgLoc = vect(0,0,0);
	}

	Mesh.SetOwnerNoSee(false);

	DamageIcon.Remove(0, DamageIcon.Length);

	//DestroyIcons();
	SSPlayerController(Controller).Stamina = SSPlayerController(Controller).default.Stamina;
	SSPlayerController(Controller).bRunning = false;
	//DestroyWeapon();

	//SetVisibleHUD(false);

	ClearTimer('CalcHitDirection');
	ClearTimer('RecoverHealth');

	DisableHealthBlur();

	SSPlayerController(Controller).DefaultFOV = 90;

	if(Mesh.bClothAwakeOnStartup)
		Mesh.SetEnableClothSimulation(false);
}

simulated State Dying
{
ignores OnAnimEnd, Bump, HitWall, HeadVolumeChange, PhysicsVolumeChange, Falling, BreathTimer, FellOutOfWorld;

	//exec simulated function FeignDeath();
	//reliable server function ServerFeignDeath();

	event bool EncroachingOn(Actor Other)
	{
		// don't abort moves in ragdoll
		return false;
	}

	event Timer()
	{
		local PlayerController PC;
		local bool bBehindAllPlayers;
		local vector ViewLocation;
		local rotator ViewRotation;

		// let the dead bodies stay if the game is over
		if(WorldInfo.GRI != None && WorldInfo.GRI.bMatchIsOver)
		{
			LifeSpan = 0.0;
			return;
		}

		if(!PlayerCanSeeMe())
		{
			Destroy();
			return;
		}
		// go away if not viewtarget
		//@todo FIXMESTEVE - use drop detail, get rid of backup visibility check
		bBehindAllPlayers = true;
		ForEach LocalPlayerControllers(class'PlayerController', PC)
		{
			if((PC.ViewTarget == self) || (PC.ViewTarget == Base))
			{
				if (LifeSpan < 3.5)
					LifeSpan = 3.5;
				SetTimer(2.0, false);
				return;
			}

			PC.GetPlayerViewPoint(ViewLocation, ViewRotation);
			if(((Location - ViewLocation) dot vector(ViewRotation) > 0))
			{
				bBehindAllPlayers = false;
				break;
			}
		}
		if(bBehindAllPlayers)
		{
			Destroy();
			return;
		}
		SetTimer(2.0, false);
	}

	simulated function bool CalcCamera(float fDeltaTime, out vector out_CamLoc, out rotator out_CamRot, out float out_FOV)
	{
		local Vector SocketLoc;
		local Rotator SocketRot;

		Mesh.GetSocketWorldLocationAndRotation('CameraView', SocketLoc, SocketRot);

		out_CamLoc = SocketLoc;
		out_CamRot = SocketRot;

		return true;
	}

	simulated event Landed(vector HitNormal, Actor FloorActor)
	{
		local vector BounceDir;

		if(Velocity.Z < -500)
		{
			BounceDir = 0.5 * (Velocity - 2.0*HitNormal*(Velocity dot HitNormal));
			TakeDamage((1-Velocity.Z/30), Controller, Location, BounceDir, class'DmgType_Crushed');
		}
	}

	//simulated event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
	//{
	//	local Vector shotDir, ApplyImpulse,BloodMomentum;
	//	local class<UTDamageType> UTDamage;
	//	local UTEmit_HitEffect HitEffect;

		//if ( class'UTGame'.Static.UseLowGore(WorldInfo) )
		//{
		//	if ( !bGibbed )
		//	{
		//		UTDamage = class<UTDamageType>(DamageType);
		//		if (UTDamage != None && ShouldGib(UTDamage))
		//		{
		//			bTearOffGibs = true;
		//			bGibbed = true;
		//		}
		//	}
		//	return;
		//}

		// When playing death anim, we keep track of how long since we took that kind of damage.
		//if(DeathAnimDamageType != None)
		//{
		//	if(DamageType == DeathAnimDamageType)
		//	{
		//		TimeLastTookDeathAnimDamage = WorldInfo.TimeSeconds;
		//	}
		//}

		//if (!bGibbed && (InstigatedBy != None || EffectIsRelevant(Location, true, 0)))
		//{
		//	UTDamage = class<UTDamageType>(DamageType);

		//	// accumulate damage taken in a single tick
		//	if ( AccumulationTime != WorldInfo.TimeSeconds )
		//	{
		//		AccumulateDamage = 0;
		//		AccumulationTime = WorldInfo.TimeSeconds;
		//	}
		//	AccumulateDamage += Damage;

		//	Health -= Damage;
		//	if ( UTDamage != None )
		//	{
		//		if ( ShouldGib(UTDamage) )
		//		{
		//			if ( bHideOnListenServer || (WorldInfo.NetMode == NM_DedicatedServer) )
		//			{
		//				bTearOffGibs = true;
		//				bGibbed = true;
		//				return;
		//			}
		//			SpawnGibs(UTDamage, HitLocation);
		//		}
		//		else if ( !bHideOnListenServer && (WorldInfo.NetMode != NM_DedicatedServer) )
		//		{
		//			CheckHitInfo( HitInfo, Mesh, Normal(Momentum), HitLocation );
		//			UTDamage.Static.SpawnHitEffect(self, Damage, Momentum, HitInfo.BoneName, HitLocation);

		//			if ( UTDamage.default.bCausesBlood && !class'UTGame'.Static.UseLowGore(WorldInfo)
		//				&& ((PlayerController(Controller) == None) || (WorldInfo.NetMode != NM_Standalone)) )
		//			{
		//				BloodMomentum = Momentum;
		//				if ( BloodMomentum.Z > 0 )
		//					BloodMomentum.Z *= 0.5;
		//				HitEffect = Spawn(GetFamilyInfo().default.BloodEmitterClass,self,, HitLocation, rotator(BloodMomentum));
		//				HitEffect.AttachTo(Self,HitInfo.BoneName);
		//			}

		//			if ( (UTDamage.default.DamageOverlayTime > 0) && (UTDamage.default.DamageBodyMatColor != class'UTDamageType'.default.DamageBodyMatColor) )
		//			{
		//				SetBodyMatColor(UTDamage.default.DamageBodyMatColor, UTDamage.default.DamageOverlayTime);
		//			}

		//			if( (Physics != PHYS_RigidBody) || (Momentum == vect(0,0,0)) || (HitInfo.BoneName == '') )
		//				return;

		//			shotDir = Normal(Momentum);
		//			ApplyImpulse = (DamageType.Default.KDamageImpulse * shotDir);

		//			if( UTDamage.Default.bThrowRagdoll && (Velocity.Z > -10) )
		//			{
		//				ApplyImpulse += Vect(0,0,1)*DamageType.default.KDeathUpKick;
		//			}
		//			// AddImpulse() will only wake up the body for the bone we hit, so force the others to wake up
		//			Mesh.WakeRigidBody();
		//			Mesh.AddImpulse(ApplyImpulse, HitLocation, HitInfo.BoneName, true);
		//		}
		//	}
		//}
	//}

	/** Tick only if bio death effect */
	//simulated event Tick(FLOAT DeltaSeconds)
	//{
	//	local float BurnLevel;
	//	local int i;
	//	local MaterialInstanceConstant MyMIC;

	//	// tick only if bio death effect
	//	if(!bKilledByBio || (Mesh == None))
	//	{
	//		Disable('Tick');
	//	}
	//	else
	//	{
	//		// first, how far into the burn are we: (scale of 0-9.9)
	//		BurnLevel = FMin(((WorldInfo.TimeSeconds-DeathTime)/BioBurnAwayTime*10.0),9.9);
	//		for(i=0; i<Mesh.Materials.Length; i++ )
	//		{
	//			MyMIC = MaterialInstanceConstant(Mesh.Materials[i]);
	//			if (MyMIC != None)
	//			{
	//				MyMIC.SetScalarParameterValue(BioEffectName, BurnLevel);
	//			}
	//		}
	//		if(BurnLevel >= 9.9)
	//		{
	//			BioBurnAway.DeactivateSystem();
	//			bKilledByBio = FALSE; // no need to loop this in anymore.
	//			Disable('Tick');
	//		}
	//	}
	//}

	simulated event Tick(FLOAT DeltaSeconds)
	//simulated function CheckPhysics()
	{
		//if(AnimNodeSequence(FullBodyAnimSlot.Children[1].Anim) != none)
		//{
			if(!AnimNodeSequence(FullBodyAnimSlot.Children[1].Anim).bPlaying && Physics != PHYS_RigidBody)
			{
				if(class'Engine'.static.IsEditor())
					WorldInfo.Game.Broadcast(self,"FUUU");

				SetPhysics(PHYS_RigidBody);
			}
		//}

		//else if(Physics != PHYS_RigidBody)
		//	SetPhysics(PHYS_RigidBody);

		//WorldInfo.Game.Broadcast(self, Physics);

		//SetTimer(0.1, false, 'CheckPhysics');
	}

	simulated function BeginState(Name PreviousStateName)
	{
		Super.BeginState(PreviousStateName);
		//CustomGravityScaling = 1.0;
		//DeathTime = WorldInfo.TimeSeconds;
		CylinderComponent.SetActorCollision(false, false);

		//if (bTearOff && (bHideOnListenServer || (WorldInfo.NetMode == NM_DedicatedServer)))
		//	LifeSpan = 1.0;
		//else
		//{
			if(Mesh != None)
			{
				Mesh.SetTraceBlocking(true, true);
				Mesh.SetActorCollision(true, false);

				// Move into post so that we are hitting physics from last frame, rather than animated from this
				Mesh.SetTickGroup(TG_PostAsyncWork);
			}
			SetTimer(2.0, false);
			LifeSpan = RagDollLifeSpan;
		//}

		DisablePawnProperties();

		//SetTimer(0.1, false, 'CheckPhysics');
	}

	simulated function EndState(Name PreviousStateName)
	{
		Disable('Tick');
		Super.EndState(PreviousStateName);
	}
}

DefaultProperties
{
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=TRUE
		bIsCharacterLightEnvironment=TRUE
		bUseBooleanEnvironmentShadowing=FALSE
		InvisibleUpdateTime=1
		MinTimeBetweenFullUpdates=0.2
	End Object
	Components.Add(MyLightEnvironment)
	LightEnvironment=MyLightEnvironment

	//Begin Object Class=SkeletalMeshComponent Name=WPawnSkeletalMeshComponent01
	//	DepthPriorityGroup=SDPG_Foreground
	//	bOnlyOwnerSee=true
	//End Object
	//FPMesh=WPawnSkeletalMeshComponent01
	//Components.Add(WPawnSkeletalMeshComponent01)

	Begin Object Class=SkeletalMeshComponent Name=WPawnSkeletalMeshComponent
		SkeletalMesh=SkeletalMesh'BarataTest.Mesh.Player' //SkeletalMesh'CH_IronGuard_Male.Mesh.SK_CH_IronGuard_MaleA'
		AnimSets(0)=AnimSet'CH_AnimHuman.Anims.K_AnimHuman_AimOffset'
		AnimSets(1)=AnimSet'CH_AnimHuman.Anims.K_AnimHuman_BaseMale'
		PhysicsAsset=PhysicsAsset'CH_AnimCorrupt.Mesh.SK_CH_Corrupt_Male_Physics'
		AnimTreeTemplate=AnimTree'BarataTest.Anims.BotAnimTree' //AnimTree'CH_AnimHuman_Tree.AT_CH_Human'

		//SkeletalMesh=SkeletalMesh'Personagem.Personagem'
		//AnimSets(0)=AnimSet'Personagem.Personagem_Animset'
		//PhysicsAsset=PhysicsAsset'Personagem.Personagem_Physics'
		//AnimTreeTemplate=AnimTree'Personagem.Personagem_AnimTree'

		bOwnerNoSee=true
		bCacheAnimSequenceNodes=false
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		CastShadow=true
		BlockRigidBody=true
		bUpdateSkelWhenNotRendered=true
		bIgnoreControllersWhenNotRendered=false
		bUpdateKinematicBonesFromAnimation=true
		bCastDynamicShadow=true
		RBChannel=RBCC_Untitled3
		RBCollideWithChannels=(Untitled3=true/*,Cloth=true*/)
		LightEnvironment=MyLightEnvironment
		bAcceptsDynamicDecals=false
		bHasPhysicsAssetInstance=true
		TickGroup=TG_PreAsyncWork
		MinDistFactorForKinematicUpdate=0.2f
		bChartDistanceFactor=true
		RBDominanceGroup=20
		bUseOnePassLightingOnTranslucency=true
		bPerBoneMotionBlur=true
		//ClothRBChannel=RBCC_Cloth
		//bClothAwakeOnStartup=true;
	End Object
	Mesh=WPawnSkeletalMeshComponent
	Components.Add(WPawnSkeletalMeshComponent)

	Begin Object Class=SkeletalMeshComponent Name=FPawnSkeletalMeshComponent
		SkeletalMesh=SkeletalMesh'BarataTest.Mesh.Player'
		AnimSets(0)=AnimSet'CH_AnimHuman.Anims.K_AnimHuman_AimOffset'
		AnimSets(1)=AnimSet'CH_AnimHuman.Anims.K_AnimHuman_BaseMale'
		PhysicsAsset=PhysicsAsset'CH_AnimCorrupt.Mesh.SK_CH_Corrupt_Male_Physics'
		AnimTreeTemplate=AnimTree'BarataTest.Anims.BotAnimTree'

		bOnlyOwnerSee=true
		bCacheAnimSequenceNodes=false
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		CastShadow=true
		//BlockRigidBody=true
		bUpdateSkelWhenNotRendered=true
		bIgnoreControllersWhenNotRendered=false
		bUpdateKinematicBonesFromAnimation=true
		bCastDynamicShadow=true
		//RBChannel=RBCC_Untitled3
		//RBCollideWithChannels=(Untitled3=true)
		LightEnvironment=MyLightEnvironment
		bAcceptsDynamicDecals=false
		//bHasPhysicsAssetInstance=true
		TickGroup=TG_PreAsyncWork
		MinDistFactorForKinematicUpdate=0.2f
		bChartDistanceFactor=true
		//RBDominanceGroup=20
		bUseOnePassLightingOnTranslucency=true
		bPerBoneMotionBlur=true
		DepthPriorityGroup=SDPG_Foreground
	End Object
	FPMesh=FPawnSkeletalMeshComponent
	Components.Add(FPawnSkeletalMeshComponent)

	Begin Object Name=CollisionCylinder
		CollisionRadius=+0030.000000
		CollisionHeight=+0054.000000
	End Object
	CylinderComponent=CollisionCylinder


	 Begin Object Class=StaticMeshComponent Name=ObjectMesh
		StaticMesh=StaticMesh'WP_ShockRifle.Mesh.S_Sphere_Good'
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
        CastShadow=true
        bCastDynamicShadow=true
        LightEnvironment=MyLightEnvironment
		CollideActors=false
		BlockActors=false
        scale=1.0
		HiddenGame=true
    End Object
	SMAmmo=ObjectMesh
    Components.add(ObjectMesh)


	CrouchHeight=35.0
	CrouchRadius=30.0

	bCanCrouch=true
	bCanTeleport=false
	bCanPickupInventory=true

	MaxStepHeight=26.0
	WalkableFloorZ=0.78
	SlopeBoostFriction=0.2

	//CamOffset=(X=20.0,Y=16.0,Z=-13.0)

	bReplicateRigidBodyLocation=true
	bRunPhysicsWithNoController=true

	ViewPitchMin=-9000                       // rotação mínima da camera (para baixo)
	ViewPitchMax=10000                           // rotação máxima da camera (para cima)

	MaxYawAim=2000

	MaxFallSpeed=800

	bRunning=false

	//DeathMeshBreakableJoints=("b_LeftArm","b_RightArm","b_LeftLegUpper","b_RightLegUpper"/*,"b_Neck"*/)

	InventoryManagerClass=class'SSInventoryManager'

	//InventoryManagerClass=class'UTInventoryManager'
	ControllerClass=None

	//GroundSpeed=440
	//Velocidade=440

	NewJumpZ=+300

	WeaponSocket=WeaponPoint
	HeadBone=b_Head

	DeathHipLinSpring=10000.0
	DeathHipLinDamp=500.0
	DeathHipAngSpring=10000.0
	DeathHipAngDamp=500.0

	RagdollLifespan=10.0

	HeadRadius=+9.0
	HeadHeight=5.0

	HealthRecover=10
	HealthRecoverTime=2

	bAlwaysRelevant=true

	CurrentWeapAnimNode=-1
	CurrentWeapAnimType=-1
	AttachHiddenMatValue=-1
	bReplicateHealthToAll=true

	Begin Object Class=RadialBlurComponent Name=RadialBlurComp
		BlurFalloffExponent=2
		BlurScale=0.35
		DistanceFalloffExponent=22
		bEnabled=false
  	End Object
 	RadialBlur=RadialBlurComp
 	Components.Add(RadialBlurComp)

	//Begin Object Class=ParticleSystemComponent Name=ParticleSystemComponent2
	//	bAutoActivate=true
	//	Template=ParticleSystem'WP_ShockRifle.Particles.P_WP_ShockRifle_Ball'
	//	bOwnerNoSee=true
	//	AlwaysLoadOnClient=true
	//	AlwaysLoadOnServer=true
	//End Object
	//NameEffect=ParticleSystemComponent2
	//Components.Add(ParticleSystemComponent2)
	
	//TakeHitPhysicsBlendOutSpeed=0.5
}
