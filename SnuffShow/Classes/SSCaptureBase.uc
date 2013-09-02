class SSCaptureBase extends DynamicSMActor
	implements(SSMinimapIconInterface);

var StaticMeshComponent Mesh;
var CylinderComponent CylinderComponent;
//var DynamicLightEnvironmentComponent LightEnvironment;

var byte CaptureTeamIndex, PendingTeamIndex;
var bool bRedCapture, bBlueCapture, bPlayerCanUse, bPlayCaptureSound, bFinishCapture;
var SSTeamInfo TI, PendingTI;

var int IconFrame;

var GFxObject IconBase;
var array<ASValue> args;

var /*repnotify*/ MaterialInstanceConstant MICLightColor[5];
var repnotify SoundCue NewSound;
var repnotify int NewLightColorIndex, LightColorIndex, FrameIndex;
var LinearColor LColor, RedLColor, BlueLColor;

var int OriginalFrame;

replication
{
	if(bNetDirty)
		IconBase, CaptureTeamIndex, bRedCapture, bBlueCapture, bPlayCaptureSound, bFinishCapture, NewLightColorIndex, LightColorIndex, LColor, 
			FrameIndex, OriginalFrame, PendingTeamIndex, NewSound;
}

simulated event ReplicatedEvent(name VarName)
{
	if(VarName == 'NewLightColorIndex')
	{
	   ClientSetMaterial(NewLightColorIndex);
	}

	else if(VarName == 'LightColorIndex' && LightColorIndex != -1)
	{
	   ClientChangeLightColor();
	}

	else if(VarName == 'FrameIndex')
	{
	   ClientChangeColor(FrameIndex);
	}

	//else if(VarName == 'NewSound')
	//{
	//   ClientPlayBaseSound(NewSound);
	//}

	super.ReplicatedEvent(VarName);
}

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	SetMaterial();	
}

reliable client function ClientSetMaterial(int index)
{
	if(Mesh != None)
	{
		MICLightColor[index] = Mesh.CreateAndSetMaterialInstanceConstant(index + 1);
		Mesh.SetMaterial(index + 1, MICLightColor[index]);

		if(index == 4)
			CheckLightColors();
	}
}

simulated function SetMaterial()
{
	local int i;

	if(Mesh != None)
	{
		for(i = 0; i < 5; i++)
		{
			MICLightColor[i] = Mesh.CreateAndSetMaterialInstanceConstant(i + 1);
			Mesh.SetMaterial(i + 1, MICLightColor[i]);
			NewLightColorIndex = i;
		}
	}
}

reliable client function CheckLightColors()
{
	local int i;

	for(i = 0; i < 5; i++)
	{
		MICLightColor[i].SetVectorParameterValue('LightColor', LColor);
	}
}

simulated function PlayBaseSound(SoundCue Sound)
{
	PlaySound(Sound);
	NewSound = Sound;
}

reliable client function ClientPlayBaseSound(SoundCue Sound)
{
	PlaySound(Sound);
}

simulated function RenderMinimapIcon(HUD HUD, int MinimapSize, int MinimapLocationX, int MinimapLocationY, PlayerReplicationInfo RenderingPlayerReplicationInfo)
{
	local SSMapInfo SSMapInfo;

	//local float ReajustImageMapSize;

	SSMapInfo = SSMapInfo(WorldInfo.GetMapInfo());
	if(SSMapInfo == None)
		return;

	//if(bPlayCaptureSound)
	//{
	//	bPlayCaptureSound = false;
	//	PlaySound(SoundCue'A_Gameplay.CTF.Cue.A_Gameplay_CTF_FlagAlarm_Cue');
	//}

	IconFrame = IconBase.GetInt("_currentframe");

	if(CaptureTeamIndex != 255 && IconFrame != CaptureTeamIndex + 2 && PendingTeamIndex == 255)
	{
		IconBase.GotoAndStopI(CaptureTeamIndex + 2);
	}

	if(bFinishCapture)
	{
		bFinishCapture = false;
		//PlaySound(SoundCue'A_Gameplay.CTF.Cue.A_Gameplay_CTF_EnemyFlagGrab01Cue');
		IconBase.GotoAndStopI(CaptureTeamIndex + 2);

		OriginalFrame = CaptureTeamIndex + 2;
	}

	if(IconBase == none)
	{
		if(SSHUD(HUD).HUDMovie.Minimap.Mapa.GetObject(string(self)) != none)
			SSHUD(HUD).DestroyPlayerIcons(string(self));

		IconBase = SSHUD(HUD).HUDMovie.Minimap.Mapa.AttachMovie("IconBase", string(self));
		//IconBase.GotoAndStopI(PlayerReplicationInfo.Team.TeamIndex + 1);
		IconBase.SetFloat("_xscale", SSMapInfo.IconSize);
		IconBase.SetFloat("_yscale", SSMapInfo.IconSize);
		IconBase.SetFloat("_x", MinimapLocationX);
		IconBase.SetFloat("_y", MinimapLocationY);

		OriginalFrame = IconBase.GetInt("_currentframe");

		//if(SSMapInfo.BaseTexture != none)
		//{
		//	//ReajustImageMapSize = (100 / SSMapInfo.BaseTexture.GetSurfaceWidth()) * IconBase.GetObject("BaseTex").GetFloat("_width");

		//	IconBase.SetString("ImageBase", "img://"$PathName(SSMapInfo.BaseTexture));
		//	//IconBase.GetObject("BaseTex").SetFloat("_xscale", ReajustImageMapSize);
		//	//IconBase.GetObject("BaseTex").SetFloat("_yscale", ReajustImageMapSize);
		//}

		//IconBase.ActionScriptVoid("Init");

		//if(CaptureTeamIndex != 255)
		//	IconBase.GotoAndStopI(CaptureTeamIndex + 2);
	}

	//if(IconBase != none)
	//{
	//	IconBase.SetFloat("_x", MinimapLocationX);
	//	IconBase.SetFloat("_y", MinimapLocationY);
	//}
}

simulated function ChangeColor()
{
	local int CurrentFrame;

	CurrentFrame = IconBase.GetInt("_currentframe");

	if(CurrentFrame != PendingTeamIndex + 2)
		FrameIndex = PendingTeamIndex + 2;

	else
		FrameIndex = OriginalFrame;

	IconBase.GotoAndStopI(FrameIndex);

	//WorldInfo.Game.Broadcast(self, CurrentFrame@PendingTeamIndex + 2);
}

reliable client function ClientChangeColor(int Frame)
{
	IconBase.GotoAndStopI(Frame);
}

simulated function Vector GetMinimapWorldLocation()
{
	return Location;
}

simulated function DestroyIcons()
{
	if(IconBase != none)
	{
		IconBase.Invoke("removeMovieClip", args);
		IconBase = none;
	}
}

simulated function InitCapture()
{
	if(LightColorIndex < 4)
	{
		LightColorIndex++;
		ChangeLightColor(LightColorIndex);
		ChangeColor();
		SetTimer(1.0, false, 'InitCapture');

		if(LightColorIndex == 4)
		{
			//CheckFinishCapture();
			TI = PendingTI;
			CaptureTeamIndex = PendingTeamIndex;
			PendingTeamIndex = 255;
			PendingTI = none;
			bFinishCapture = true;
			PlayBaseSound(SoundCue'A_Gameplay.CTF.Cue.A_Gameplay_CTF_EnemyFlagGrab01Cue');
			AddScore();
		}

		//else if(IsTimerActive('AddScore'))
		//	ClearTimer('AddScore');
	}

	else
	{
		//ClearTimer('InitCapture');
		LightColorIndex=-1;
	}
}

simulated function FinishCapture()
{
	ClearTimer('InitCapture');
	LightColorIndex = -1;
	CheckFinishCapture();
}

simulated function CheckFinishCapture()
{
	if(CaptureTeamIndex == 255)
	{
		LColor = default.LColor;
		ResetLightColors();

		return;
	}

	else if(CaptureTeamIndex == 0 && LColor == BlueLColor)
	{
		LColor = RedLColor;
		ResetLightColors();

		return;
	}

	else if(CaptureTeamIndex == 1 && LColor == RedLColor)
	{
		LColor = BlueLColor;
		ResetLightColors();

		return;
	}

	bFinishCapture = true;
}

simulated function ResetLightColors()
{
	if(LightColorIndex < 4)
	{
		LightColorIndex++;
		ChangeLightColor(LightColorIndex);
		SetTimer(0.3, false, 'ResetLightColors');
	}

	else
	{
		LightColorIndex = -1;

		if(PendingTeamIndex != CaptureTeamIndex)
		{
			LColor = PendingTeamIndex == 0 ? RedLColor : BlueLColor;
			InitCapture();
			bPlayCaptureSound = true;
		}

		else
			bFinishCapture = true;
	}
}

simulated function ChangeLightColor(int Index)
{
	//local LinearColor LColor;

	//LightColorIndex = Index;

	//if(CaptureTeamIndex == 0)
	//{
	//	LColor.R = 10.0;
	//	LColor.G = 0.0;
	//	LColor.B = 0.0;
	//}

	//else
	//{
	//	LColor.R = 0.0;
	//	LColor.G = 0.0;
	//	LColor.B = 10.0;
	//}

	MICLightColor[LightColorIndex].SetVectorParameterValue('LightColor', LColor);
	//MICLightColor[LightColorIndex - 1].SetScalarParameterValue('LightColor', LightColorIndex);
	//WorldInfo.Game.Broadcast(self, LightColorIndex@CaptureTeamIndex);
}

reliable client function ClientChangeLightColor()
{
	//local LinearColor LColor;

	//LColor.A = 1.0;

	//if(CaptureTeamIndex == 0)
	//	LColor.R = 10.0;

	//else
	//	LColor.B = 10.0;

	MICLightColor[LightColorIndex].SetVectorParameterValue('LightColor', LColor);
	//MICLightColor[LightColorIndex - 1].SetScalarParameterValue('LightColor', LightColorIndex);
	//WorldInfo.Game.Broadcast(self, LightColorIndex);
}

event Attach(Actor Other)
{
	if(SSPawn(Other) != none)
	{
		bPlayerCanUse = true;
	}
}

event Detach(Actor Other)
{
	if(SSPawn(Other) != none)
	{
		bPlayerCanUse = false;
	}
}

//event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
//{
//	if(SSPawn(Other) != none)
//	{
//		//SSPlayerController(Pawn(Other).Controller).CurrentBase.bUseBase = true;
//		//SSPlayerController(Pawn(Other).Controller).CurrentBase.CB = self;
//		bPlayerCanUse = true;
//		WorldInfo.Game.Broadcast(self, self@bPlayerCanUse);
//	}
//}

//event UnTouch(Actor Other)
//{
//	if(SSPawn(Other) != none)
//	{
//		//SSPlayerController(Pawn(Other).Controller).CurrentBase.bUseBase = false;
//		//SSPlayerController(Pawn(Other).Controller).CurrentBase.CB = none;
//		bPlayerCanUse = false;
//		WorldInfo.Game.Broadcast(self, self@bPlayerCanUse);
//	}
//}

function AddScore(optional PlayerReplicationInfo PRI)
{
	//if(CaptureTeamIndex != PRI.Team.TeamIndex)
	//	TI.ScoreTeam += 100;

	if(!bRedCapture && TI.TeamIndex == 0)
	{
		bRedCapture = true;
		TI.ScoreTeam += 100;
	}

	else if(!bBlueCapture && TI.TeamIndex == 1)
	{
		bBlueCapture = true;
		TI.ScoreTeam += 100;
	}

	else
		TI.ScoreTeam += 1;

	//WorldInfo.Game.Broadcast(self, SSTeamInfo(PRI.Team).ScoreTeam);

	if(SSGameInfo(WorldInfo.Game).GetStateName() != 'MatchOver')
		SetTimer(1.0, false, 'AddScore');
}

DefaultProperties
{
	//Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
	//	bEnabled=true
	//End Object
	//Components.Add(MyLightEnvironment)
	//LightEnvironment=MyLightEnvironment

	Begin Object class=StaticMeshComponent Name=BaseMesh
		//StaticMesh=StaticMesh'HU_Deco3.SM.Mesh.S_HU_Deco_SM_StorageTanks03'
		StaticMesh=StaticMesh'teste_martelo.Mesh.F_Martelo_Dup'
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		LightEnvironment=MyLightEnvironment
		//Rotation=(Pitch=0,Yaw=0,Roll=16384)
	End Object
	Mesh=BaseMesh
	Components.Add(BaseMesh)

	Begin Object Class=CylinderComponent Name=CollisionCylinder
		CollisionRadius=+0050.000000
		CollisionHeight=+0050.000000
		CollideActors=true
		Translation=(X=40,Y=0,Z=100)
	End Object
	CylinderComponent=CollisionCylinder
	Components.Add(CollisionCylinder)

	bCollideActors=true
	bBlockActors=true

	bMovable=false

	LColor=(A=1.0,R=0.974,G=0.908,B=0.17)
	RedLColor=(A=1.0,R=255.0,G=0.0,B=0.0)
	BlueLColor=(A=1.0,R=0.0,G=0.0,B=255.0)

	PendingTeamIndex=255
	CaptureTeamIndex=255
	LightColorIndex=-1
	NewLightColorIndex=-1

	bOnlyDirtyReplication=true
	NetUpdateFrequency=8
	Role=ROLE_Authority
	RemoteRole=ROLE_SimulatedProxy
	NetPriority=+1.4
	bReplicateMovement=false
	bUpdateSimulatedPosition=false
	bNetInitialRotation=true

	bAlwaysRelevant=true
}
