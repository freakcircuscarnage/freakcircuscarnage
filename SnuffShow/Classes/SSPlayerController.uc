class SSPlayerController extends PlayerController
	config(IPNum);

var CameraAnim DamageCameraAnim;

var bool bCurrentCamAnimIsDamageShake;

var bool  bHoldDuck, bRunning;

var CameraAnimInst CameraAnimPlayer;
//var PostProcessSettings PostProcessModifier;
var PostProcessSettings CamOverridePostProcess;

var float FOVLinearZoomRate;

var array<SSPawn> PawnClasses;
var SSPawn CurrentPawnClass;
var SSPawn CurrentPawnClasses[5];
var int PawnClassesIndex, CurrentTeamIndex;
var float Stamina;

var config string IP;
var /*config*/ bool bSpectator, bHighScore;

//struct BaseCapture
//{
//	var bool bUseBase;
//	var SSCaptureBase CB;
//};

//var BaseCapture CurrentBase;

//struct repExplosion
//{
//	var ParticleSystem ExplosionParticle;
//	var SoundCue ExplosionSoundEffect;
//	var vector ExplosionLoc;
//};
//var repnotify repExplosion ExplosionReplication;

replication
{
	if(bNetOwner)
		PawnClassesIndex, CurrentPawnClasses, CurrentTeamIndex, Stamina, bRunning;

	if(bNetDirty)
		bSpectator, bHighScore;
}

//simulated event ReplicatedEvent(name VarName)
//{
//	if(VarName == NameOf(ExplosionReplication))
//	{
//		WorldInfo.MyEmitterPool.SpawnEmitter(ExplosionReplication.ExplosionParticle, ExplosionReplication.ExplosionLoc);
//	}

//	Super.ReplicatedEvent(VarName);
//}

//function SetBehindView(bool bNewBehindView)
//{
//	bBehindView = true;
//}

//simulated function PlayBeepSound();

//simulated function PlayerTick(float DeltaTime)
//{
//	super.PlayerTick(DeltaTime);

//	WorldInfo.Game.Broadcast(self, GroundPitch);
//}

exec function SetIP(string IPNum)
{
	IP = IPNum;
	SaveConfig();
}

exec function StartFire(optional byte FireModeNum)
{
	if(Pawn.PhysicsVolume.bNeutralZone)
		return;

	super.StartFire(FireModeNum);
}

exec function StopFire(optional byte FireModeNum)
{
	if(Pawn.PhysicsVolume.bNeutralZone || Pawn == none)
		return;

	super.StopFire(FireModeNum);
}

simulated exec function ToggleTranslocator()
{
	SSInventoryManager(Pawn.InvManager).SwitchLastWeapon();
}

function OnToggleMouseCursor(SeqAct_ToggleMouseCursor inAction)
{
	local GameViewportClient GVC;

	GVC = LocalPlayer(Player) != None ? LocalPlayer(Player).ViewportClient : None;
	if(GVC != None)
	{
		GVC.SetHardwareMouseCursorVisibility(inAction.InputLinks[0].bHasImpulse);
		WorldInfo.Game.Broadcast(self, "Mouse Change");
	}
}


////////////////// Depois ver isso /////////////////

exec function RechangeClasses(bool bRechangeTeam)
{
	if(class'Engine'.static.IsEditor())
		ServerRechangeClasses(bRechangeTeam);
}

reliable server function ServerRechangeClasses(bool bRechangeTeam)
{
	local int i;

	if(Pawn.Health == 0)
		return;

	Pawn.Suicide();
	CurrentPawnClass = none;
	PawnClassesIndex = 0;
	CurrentTeamIndex = 0;
	//SSGameInfo(WorldInfo.Game).SelectedPawnClass = none;

	for(i=0; i < PawnClasses.Length; i++)
	{
		PawnClasses.Remove(i, PawnClasses.Length);
		CurrentPawnClasses[i] = none;
	}

	GotoState('PlayerWaiting');

	if(bRechangeTeam)
		SSPlayerReplicationInfo(PlayerReplicationInfo).Team = none;

	else
		GetPawnClasses();
}

//simulated function PostBeginPlay()
//{
//	super.PostBeginPlay();

//	//SetTimer(0.5, false, 'SetWaiting');
	
//	//SetCurrentTeam();
//}

//simulated function GrenadeExploded(ParticleSystem ExplosionEffect, SoundCue ExplosionSound, vector Loc)
//{
//	ExplosionReplication.ExplosionParticle = ExplosionEffect;
//	ExplosionReplication.ExplosionSoundEffect = ExplosionSound;
//	ExplosionReplication.ExplosionLoc = Loc;

//	WorldInfo.MyEmitterPool.SpawnEmitter(ExplosionEffect, Loc);
//	PlaySound(ExplosionSound,,,, Loc);
//}

simulated function SetWaiting()
{
	GotoState('PlayerWaiting');
}

simulated function GetPawnClasses()
{
	local SSTeamInfo SSTeamInfo;
	local int i;

	//GotoState('PlayerWaiting');

	SSTeamInfo = SSTeamInfo(PlayerReplicationInfo.Team);
	if(SSTeamInfo != none)
	{
		for(i=0; i < ArrayCount(SSTeamInfo.PawnArchetype); i++)
		{
			if(SSTeamInfo.PawnArchetype[i] != none)
			{
				PawnClasses.AddItem(SSTeamInfo.PawnArchetype[i]);
				CurrentPawnClasses[i] = SSTeamInfo.PawnArchetype[i];
				//WorldInfo.Game.Broadcast(self, "Pawn"@PawnClasses[i]@Pawn@GetStateName());
			}
		}

		if(SSTeamInfo.PawnArchetype[0] != none)
			CurrentPawnClass = SSTeamInfo.PawnArchetype[0];
	}
}

auto state PlayerWaiting
{
	ignores SeePlayer, HearNoise, NotifyBump, TakeDamage, PhysicsVolumeChange, SwitchToBestWeapon;

	exec function StartFire(optional byte FireModeNum)
	{
		//if(SSPlayerReplicationInfo(PlayerReplicationInfo).Team == none)
		//{
		//	SSGameInfo(WorldInfo.Game).SetCurrentTeam(PlayerReplicationInfo, CurrentTeamIndex);
		//	GetPawnClasses();
		//	//SSPlayerReplicationInfo(PlayerReplicationInfo).SetPlayerTeam(GameReplicationInfo.Teams[CurrentTeamIndex]);
		//}

		//else
		//{
		//	SSGameInfo(WorldInfo.Game).SelectedPawnClass = CurrentPawnClass;
		//	SSGameInfo(WorldInfo.Game).RestartPlayer(self);
		//	//WorldInfo.Game.Broadcast(self, "CurrentPawn"@CurrentPawnClass@PawnClassesIndex);
		//}

		if(class'Engine'.static.IsEditor())
			Clicked();
	}

	exec function NextWeapon()
	{
		if(SSPlayerReplicationInfo(PlayerReplicationInfo).Team == none)
		{
			CurrentTeamIndex = CurrentTeamIndex == 0 ? 1 : 0;
			SetCurrentTeamIndex(CurrentTeamIndex);
		}

		else
		{
			SelectNextPawn();
		}
	}

	exec function PrevWeapon()
	{
		if(SSPlayerReplicationInfo(PlayerReplicationInfo).Team == none)
		{
			CurrentTeamIndex = CurrentTeamIndex == 0 ? 1 : 0;
			SetCurrentTeamIndex(CurrentTeamIndex);
		}

		else
		{
			SelectPrevPawn();
		}
	}
}

reliable server function Clicked()
{
	if(SSPlayerReplicationInfo(PlayerReplicationInfo).Team == none)
	{
		//SSGameInfo(WorldInfo.Game).SetCurrentTeam(PlayerReplicationInfo, CurrentTeamIndex);
		SSPlayerReplicationInfo(PlayerReplicationInfo).SetPlayerTeam(SSGameInfo(WorldInfo.Game).GameReplicationInfo.Teams[CurrentTeamIndex]);
		GetPawnClasses();
	}

	else
	{
		//SSGameInfo(WorldInfo.Game).SelectedPawnClass = CurrentPawnClass;
		SSGameInfo(WorldInfo.Game).RestartPlayer(self);
	}
}

reliable server function SetCurrentTeamIndex(int index)
{
	CurrentTeamIndex = index;
}

reliable server function SelectNextPawn()
{
	if(PawnClassesIndex < (PawnClasses.Length - 1))
		PawnClassesIndex++;

	else
		PawnClassesIndex = 0;

	CurrentPawnClass = PawnClasses[PawnClassesIndex];

	//WorldInfo.Game.Broadcast(self, "CurrentPawn"@CurrentPawnClass.PawnName@PawnClassesIndex);
}

reliable server function SelectPrevPawn()
{
	if(PawnClassesIndex > 0)
		PawnClassesIndex--;

	else
		PawnClassesIndex = PawnClasses.Length - 1;

	CurrentPawnClass = PawnClasses[PawnClassesIndex];

	//WorldInfo.Game.Broadcast(self, "CurrentPawn"@CurrentPawnClass.PawnName@PawnClassesIndex);
}

simulated function StartZoom(float NewDesiredFOV, float NewZoomRate)
{
	FOVLinearZoomRate = NewZoomRate;
	DesiredFOV = NewDesiredFOV;

	// clear out any nonlinear zoom info
	//bNonlinearZoomInterpolation = FALSE;
	//FOVNonlinearZoomInterpSpeed = 0.f;
}

function AdjustFOV(float DeltaTime)
{
	local float DeltaFOV;

	if (FOVAngle != DesiredFOV && CameraAnimPlayer.bFinished)
	{
		// do linear interpolation
		if (FOVLinearZoomRate > 0.0)
		{
			DeltaFOV = FOVLinearZoomRate * DeltaTime;

			if (FOVAngle > DesiredFOV)
			{
				FOVAngle = FMax(DesiredFOV, (FOVAngle - DeltaFOV));
			}
			else
			{
				FOVAngle = FMin(DesiredFOV, (FOVAngle + DeltaFOV));
			}
		}
		else
		{
			FOVAngle = DesiredFOV;
		}

		DefaultFOV = FOVAngle;
	}
}

//reliable client function PlayGameAnnouncement()
//{
//}

//simulated function SetCurrentTeam()
//{
//	local SSPlayerReplicationInfo SSPlayerReplicationInfo;

//	SSPlayerReplicationInfo = SSPlayerReplicationInfo(PlayerReplicationInfo);
//	if (SSPlayerReplicationInfo == None)
//	{
//		return;
//	}

//	SSPlayerReplicationInfo.SetPlayerTeam(SSGameInfo(WorldInfo.Game).TeamInfoArchetypes[1]);
//}

exec function SwithGrenade()
{
	local int i;
	local array<SSWeapBase> WeaponList;

	SSInventoryManager(SSPawn(Pawn).InvManager).GetWeaponList(WeaponList);
   
	if(SSWeapBase(Pawn.Weapon).InventoryGroup != 11)
	{
		for (i=0;i<WeaponList.Length;i++)
		{
			if(WeaponList[i].InventoryGroup == 11)
			{
				SSPawn(Pawn).InvManager.SetCurrentWeapon(WeaponList[i]);
				break;
			}

			else
				continue;
		}		
	}

	else if(SSWeapBase(Pawn.Weapon).InventoryGroup != 12)
	{
		for (i=0;i<WeaponList.Length;i++)
		{
			if(WeaponList[i].InventoryGroup == 12)
			{
				SSPawn(Pawn).InvManager.SetCurrentWeapon(WeaponList[i]);
				break;
			}

			else
				continue;
		}		
	}
}

function bool PerformedUseAction()
{
	local SSCaptureBase CB;

	if(CheckBaseCapture(CB))
	{
		//if(CB.CaptureTeamIndex != PlayerReplicationInfo.Team.TeamIndex)
		if((CB.PendingTeamIndex == 255 && CB.CaptureTeamIndex == PlayerReplicationInfo.Team.TeamIndex) || 
			(CB.PendingTeamIndex != 255 && CB.PendingTeamIndex == PlayerReplicationInfo.Team.TeamIndex))
			return false;
		//{
			//SetTimer(4.0, false, 'CaptureBase');

			if(CB.IsTimerActive('InitCapture'))
			{
				CB.FinishCapture();
			}

			CB.PendingTI = SSTeamInfo(PlayerReplicationInfo.Team);
			//CB.IconBase.GotoAndStopI(PlayerReplicationInfo.Team.TeamIndex + 2);
			//CB.AddScore(PlayerReplicationInfo);
			CB.PendingTeamIndex = PlayerReplicationInfo.Team.TeamIndex;

			if(!CB.IsTimerActive('ResetLightColors'))
			{
				CB.LColor = PlayerReplicationInfo.Team.TeamIndex == 0 ? CB.RedLColor : CB.BlueLColor;
				//CB.bPlayCaptureSound = true;
				CB.PlayBaseSound(SoundCue'A_Gameplay.CTF.Cue.A_Gameplay_CTF_FlagAlarm_Cue');
				CB.InitCapture();
			}
			//PlaySound(SoundCue'A_Gameplay.CTF.Cue.A_Gameplay_CTF_EnemyFlagGrab01Cue');
		//}

		return true;
	}

	//SSPawn(Pawn).ThrowActiveWeapon(false);

	//if(CurrentBase.bUseBase && CurrentBase.CB.CaptureTeamIndex != PlayerReplicationInfo.Team.TeamIndex)
	//{
	//	//WorldInfo.Game.Broadcast(self, "Base");
	//	CurrentBase.CB.CaptureTeamIndex = PlayerReplicationInfo.Team.TeamIndex;

	//	CurrentBase.CB.TI = SSTeamInfo(PlayerReplicationInfo.Team);
	//	CurrentBase.CB.IconBase.GotoAndStopI(PlayerReplicationInfo.Team.TeamIndex + 2);
	//	CurrentBase.CB.AddScore(PlayerReplicationInfo);

	//	if(PlayerReplicationInfo.Team.TeamIndex == 0)
	//		CurrentBase.CB.bRedCapture = true;
	//	else if(PlayerReplicationInfo.Team.TeamIndex == 0)
	//		CurrentBase.CB.bBlueCapture = true;

	//	return true;
	//}

	return super.PerformedUseAction();
}

function CaptureBase(SSCaptureBase CurrentBase)
{
	local SSCaptureBase CB;

	if(CheckBaseCapture(CB))
	{
		CB.TI = SSTeamInfo(PlayerReplicationInfo.Team);
		//CB.AddScore(PlayerReplicationInfo);
		CB.CaptureTeamIndex = PlayerReplicationInfo.Team.TeamIndex;
	}
}

function bool CheckBaseCapture(optional out SSCaptureBase CurrentBase)
{
	local SSCaptureBase CB;

	foreach Pawn.CollidingActors(class'SSCaptureBase', CB, 100)
	{
		CurrentBase = CB;
		//WorldInfo.Game.Broadcast(self, CurrentBase@CurrentBase.bPlayerCanUse);
		return CB.bPlayerCanUse;
	}
}

simulated exec function Reload()
{
	Recarregar();
}

reliable server function Recarregar()
{
	SSWeapBase(SSPawn(Pawn).Weapon).ReloadWeapon();
}

simulated exec function Run()
{
	if(Stamina >= 0.1 && !bHoldDuck && VSize(Pawn.Velocity) != 0)
	{
		Correr();
		SSPawn(Pawn).SetRadialBlurEnable(true);

		if(SSWeapBase(Pawn.Weapon) != none)
		{
			if(Pawn.IsFiring() && !SSWeapBase(Pawn.Weapon).bHoldingGrenade)
			{
				SSWeapBase(Pawn.Weapon).ServerStopFire(0);
				SSWeapBase(Pawn.Weapon).EndFire(0);
			}

			if(SSWeapBase(Pawn.Weapon).bActiveZoom)
			{
				SSWeapBase(Pawn.Weapon).FinishZoom();
			}
		}
	}
}

reliable server function Correr()
{
	Pawn.GroundSpeed *= 1.5;
	SSPawn(Pawn).SetRunningBlend(true);
	bRunning = true;
	SetTimer(0.1, true, 'ModifyStamina');
	//SetTimer(0.1, true, 'StaminaReduce');
	//ClearTimer('StaminaAdd');
}

simulated function ModifyStamina()
{
	if(bRunning)
	{
		if(Stamina >= 0.1 && VSize(Pawn.Velocity) != 0)
			Stamina -= 0.1;

		if(Stamina <= 0.1 || VSize(Pawn.Velocity) == 0 || Pawn.Health <= 0)
		{
			StopRun();
			//ClearTimer('StaminaReduce');
		}
	}

	else
	{
		if(Stamina <= default.Stamina - 0.1)
		{
			if(Pawn.Physics != PHYS_Falling)
				Stamina += 0.1;
		}

		else
			ClearTimer('ModifyStamina');
	}
}

//simulated function StaminaReduce()
//{
//	ClearTimer('StaminaAdd');
//	if(Stamina >= 0.1 && VSize(Pawn.Velocity) != 0)
//		Stamina -= 0.1;

//	if(Stamina <= 0.1 || VSize(Pawn.Velocity) == 0 || Pawn.Health <= 0)
//	{
//		StopRun();
//		//ClearTimer('StaminaReduce');
//	}
//	//WorldInfo.Game.Broadcast(self, Pawn.GroundSpeed@Stamina);
//}

//simulated function StaminaAdd()
//{
//	if(Stamina <= default.Stamina - 0.1)
//		Stamina += 0.1;

//	if(Stamina == default.Stamina)
//		ClearTimer('StaminaAdd');

//	//WorldInfo.Game.Broadcast(self, Pawn.GroundSpeed@Stamina);
//}

simulated exec function StopRun()
{
	SSPawn(Pawn).SetRadialBlurEnable(false);
	PararCorrer();
}

reliable server function PararCorrer()
{
	Pawn.GroundSpeed = SSPawn(Pawn).Velocidade;
	//SetTimer(2.0, false, 'DelayRecoverStamina');
	bRunning = false;
	SSPawn(Pawn).SetRunningBlend(false);
	//ClearTimer('StaminaReduce');
	//WorldInfo.Game.Broadcast(self, "Parou"@Pawn.GroundSpeed@Stamina);

	//WorldInfo.DefaultPostProcessSettings.DOF_BlurKernelSize = 16;
	//WorldInfo.DefaultPostProcessSettings.DOF_FocusInnerRadius = 20;
	//WorldInfo.Game.Broadcast(self, WorldInfo.DefaultPostProcessSettings.DOF_BlurKernelSize);
}

//simulated function DelayRecoverStamina()
//{
	//if(!IsTimerActive('StaminaAdd'))
	//	SetTimer(0.2, true, 'StaminaAdd');
//}

event InitInputSystem()
{
	super.InitInputSystem();

	CameraAnimPlayer = new(self) class'CameraAnimInst';
}

simulated exec function SwitchWeapon(byte T)
{
	if (SSPawn(Pawn) != None)
		SSPawn(Pawn).SwitchWeapon(t);
}

function NotifyTakeHit(Controller InstigatedBy, vector HitLocation, int Damage, class<DamageType> damageType, vector Momentum)
{
	local int iDam;

	Super.NotifyTakeHit(InstigatedBy,HitLocation,Damage,DamageType,Momentum);

	iDam = Clamp(Damage,0,250);
	if(iDam > 0 && Pawn != None)
	{
		ClientPlayTakeHit(hitLocation - Pawn.Location, iDam, damageType);
	}
}

unreliable client function ClientPlayTakeHit(vector HitLoc, byte Damage, class<DamageType> DamageType)
{
	DamageShake(Damage, DamageType);
	HitLoc += Pawn.Location;
}

function DamageShake(int Damage, class<DamageType> DamageType)
{
	local float BlendWeight;
	local class<SSDamageType> SSDamage;
	local CameraAnim AnimToPlay;

	SSDamage = class<SSDamageType>(DamageType);
	if (SSDamage != None && SSDamage.default.DamageCameraAnim != None)
	{
		AnimToPlay = SSDamage.default.DamageCameraAnim;
	}
	else
	{
		AnimToPlay = DamageCameraAnim;
	}
	if (AnimToPlay != None)
	{
		// don't override other anims unless it's another, weaker damage anim
		BlendWeight = FClamp(Damage / 200.0, 0.0, 1.0);
		if(CameraAnimPlayer != None && (CameraAnimPlayer.bFinished ||
						(bCurrentCamAnimIsDamageShake && CameraAnimPlayer.CurrentBlendWeight < BlendWeight)))
		{
			PlayCameraAnim(AnimToPlay, BlendWeight,,,,, true);
		}
	}
}

function PlayCameraAnim(CameraAnim AnimToPlay, optional float Scale=1.f, optional float Rate=1.f,
			optional float BlendInTime, optional float BlendOutTime, optional bool bLoop, optional bool bIsDamageShake)
{
	local Camera MatineeAnimatedCam;

	MatineeAnimatedCam = PlayerCamera;
	if (MatineeAnimatedCam != None)
	{
		MatineeAnimatedCam.PlayCameraAnim(AnimToPlay, Rate, Scale, BlendInTime, BlendOutTime, bLoop, FALSE);
	}
	else if (CameraAnimPlayer != None)
	{
		CamOverridePostProcess = class'CameraActor'.default.CamOverridePostProcess;
		CameraAnimPlayer.Play(AnimToPlay, self, Rate, Scale, BlendInTime, BlendOutTime, bLoop, false);
	}

	bCurrentCamAnimIsDamageShake = bIsDamageShake;
}

function CheckJumpOrDuck()
{
	super.CheckJumpOrDuck();

	if(Pawn.Physics != PHYS_Falling && Pawn.bCanCrouch)
	{
		// crouch if pressing duck
		Pawn.ShouldCrouch(bDuck != 0);
	}
}

simulated exec function Duck()
{
	//HeightAdjust = 0;
	//Super.StartCrouch(HeightAdjust);

	if(Pawn != none && !bRunning && Pawn.Physics != PHYS_Falling)
	{
		//if (bHoldDuck)
		//{
		//	bHoldDuck=false;
		//	bDuck=0;
		//	return;
		//}

		bDuck = 1;
		bHoldDuck = true;
	}
}

simulated exec function UnDuck()
{
	if(bHoldDuck)
	{
		bDuck = 0;
		bHoldDuck = false;
	}
}

state Dead
{
ignores SeePlayer, HearNoise, KilledBy, NextWeapon, PrevWeapon, StartFire, StartAltFire, StopFire, StopAltFire, CheckJumpOrDuck;

Begin:
	SetTimer(SSMapInfo(WorldInfo.GetMapInfo()).RespawnTime, false, 'ServerReStartPlayer');
}

state RoundEnded
{
ignores SeePlayer, HearNoise, KilledBy, NotifyBump, HitWall, NotifyHeadVolumeChange, NotifyPhysicsVolumeChange, Falling, TakeDamage, Suicide;

	function BeginState(Name PreviousStateName)
	{
		local Pawn P;

		//Super.BeginState(PreviousStateName);

		myHUD.SetShowScores(true);

		if(Pawn != None)
		{
			Pawn.TurnOff();
			StopFiring();
		}

		bFrozen = TRUE;

		ForEach DynamicActors(class'Pawn', P)
		{
			P.TurnOff();
		}

		if(SSPawn(Pawn).Weapon != none)
			SSWeapBase(SSPawn(Pawn).Weapon).FinishZoom();

		SetTimer(1.0, false,'FimDOJogo');
	}

	function FimDOJogo()
	{
		if(bHighScore)
		{
			//ConsoleCommand("open"@IP$"?bSpec=true?bHS=true");
		}

		if(Role < ROLE_Authority)
			SetTimer(15.0, true,'RestartClientP');

		else
		{
			//ServerReStartGame();
			SetTimer(1.0, true,'TryRestartServer');
		}
	}

	function TryRestartServer()
	{
		WorldInfo.Game.Broadcast(self, SSGameInfo(WorldInfo.Game).NumPlayers);

		if(SSGameInfo(WorldInfo.Game).NumPlayers == 0)
		{
			ClearTimer('TryRestartServer');
			ServerReStartGame();
		}
	}

	exec function StartFire(optional byte FireModeNum)
	{
		if(Role < ROLE_Authority)
			ConsoleCommand("Disconnect");
	}

	function CheckJumpOrDuck()
	{
		if(Role < ROLE_Authority)
			ConsoleCommand("Disconnect");
	}

	function bool PerformedUseAction()
	{
		if(Role < ROLE_Authority)
			ConsoleCommand("Disconnect");

		return true;
	}
}

reliable client function RestartClientP()
{
	if(Role < ROLE_Authority && !bHighScore)
		ConsoleCommand("Disconnect");
}

reliable client function ShowHS()
{
	SSHUD(myHUD).ShowHighScore();
}

reliable client function TryToRestartPlayer()
{
	SSGameInfo(WorldInfo.Game).RestartPlayer(self);
}

/*reliable client*/ function SetInitialScore()
{
	local SSPlayerReplicationInfo PRI;

	if(!bSpectator)
	{
		PRI = SSPlayerReplicationInfo(PlayerReplicationInfo);

		if(PRI.Team.TeamIndex == 0)
			SSGameReplicationInfo(WorldInfo.GRI).SetRedPlayersScore(PRI.PlayerName, 0, PRI.Frags, PRI.Deaths, self);

		else if(PRI.Team.TeamIndex == 1)
			SSGameReplicationInfo(WorldInfo.GRI).SetBluePlayersScore(PRI.PlayerName, 0, PRI.Frags, PRI.Deaths, self);
	}
}

DefaultProperties
{
	//bBehindView = true
	DamageCameraAnim=CameraAnim'fx_hiteffects.DamageViewShake'
	CheatClass=class'CheatManager'

	DesiredFOV=90.000000
	DefaultFOV=90.000000
	FOVAngle=90.000

	Stamina=45  //6 sugestão do Osmar

	InputClass=class'SnuffShow.SSPlayerInput'
}
