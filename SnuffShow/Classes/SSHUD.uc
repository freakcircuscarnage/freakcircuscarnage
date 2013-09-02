class SSHUD extends HUD;

// Material instance constant used for the mini map
var MaterialInstanceConstant MinimapMaterialInstanceConstant;
var SSGFxHUD HUDMovie;
var SSHighScore HighScoreMovie;
var SSGFxPauseMenu	PauseMenuMovie;
var int ViewX, ViewY;
var bool bShowingScore, bShowHUDMovie, bInitMinimap;

//var array<GFxObject> KLMessages;

var array<ASValue> args;

//simulated function CreateKLMessage()
//{
//	KLMessages.AddItem(HUDMovie.GetVariableObject("_root").AttachMovie("KLMessage", 
//		"KLM"$string(KLMessages.Length)));

//	KLMessages[KLMessages.Length -1].SetPosition(400, 800 - (KLMessages.Length * 50));

//	//WorldInfo.Game.Broadcast(self, self@"Morto");
//}

//replication
//{
//	if(bNetDirty)
//		ViewX, ViewY;
//}

singular event Destroyed()
{
	if(HUDMovie != none)
	{
		HUDMovie.Close(true);
		HUDMovie = none;
	}
}

simulated function PostBeginPlay()
{
	super.PostBeginPlay();

	CreateHUDMovie();

	//HUDMovie = New() class'SSGFxHUD';
	//HUDMovie.SetTimingMode(TM_Real);
	//HUDMovie.Init(class'Engine'.static.GetEngine().GamePlayers[HUDMovie.LocalPlayerOwnerIndex]);
}

 function ResolutionChanged()
{
	//super.ResolutionChanged();

	RemoveMovies();
	CreateHUDMovie();
}

function CreateHUDMovie()
{
	HudMovie = new class'SSGFxHUD';
	HudMovie.SetTimingMode(TM_Real);
	HudMovie.Init(class'Engine'.static.GetEngine().GamePlayers[HudMovie.LocalPlayerOwnerIndex]);

	HUDMovie.theHUD = self;
	//HUDMovie.ScorePlayersMC.SetFloat("_width", Canvas.ClipX);

	NotifyTeamChanged();

	if(HUDMovie != none)
		bShowHUDMovie = true;

	//WorldInfo.Game.Broadcast(self, HUDMovie.ScorePlayersMC.GetFloat("_width")@Canvas.ClipX);
}

exec function ShowHighScore()
{
	HighScoreMovie = new class'SSHighScore';
	HighScoreMovie.SetTimingMode(TM_Real);
	HighScoreMovie.Init(class'Engine'.static.GetEngine().GamePlayers[HighScoreMovie.LocalPlayerOwnerIndex]);

	SetVisible(false);
}

function RemoveMovies()
{
	local SSPawn P;
	local SSCaptureBase CB;

	if(HUDMovie != None)
	{
		HUDMovie.Close(true);
		HUDMovie = None;

		foreach PlayerOwner.WorldInfo.AllPawns(class'SSPawn', P)
		{
			P.DestroyIcons();
		}

		foreach PlayerOwner.WorldInfo.AllActors(class'SSCaptureBase', CB)
		{
			CB.DestroyIcons();
		}
	}

	//Super.RemoveMovies();
}

exec function SetShowScores(bool bEnableShowScores)
{
	if(SSWeapBase(PlayerOwner.Pawn.Weapon) != none)
	{
		if(SSWeapBase(PlayerOwner.Pawn.Weapon).bZoomedSniper)
			return;
	}

	if((HUDMovie != none && bShowHUD && bShowHUDMovie) || (SSPlayerController(PlayerOwner).IsInState('RoundEnded') && !SSPlayerController(PlayerOwner).bSpectator)
		/* && PlayerOwner.Pawn != none*/)
	{
		bShowHUD = true;
		bShowingScore = bEnableShowScores;
		
		//HUDMovie.Root.GotoAndStopI(int(bEnableShowScores) + 1);

		HUDMovie.Root.GetObject("TopDisplay").SetVisible(!bEnableShowScores);
		HUDMovie.Root.GetObject("RBDisplay").SetVisible(!bEnableShowScores);
		HUDMovie.Minimap.SetVisible(!bEnableShowScores);
		HUDMovie.Vida.SetVisible(false);
		HUDMovie.ScorePlayersMC.SetVisible(bEnableShowScores);

		if(bEnableShowScores)
			CheckAllScores();

		else
			HUDMovie.DisableScores();
	}
}

function CheckAllScores()
{
	local array<Pawn> RPC, BPC;
	local Pawn CurrentPC;

	foreach PlayerOwner.WorldInfo.AllPawns(class'Pawn', CurrentPC)
	{
		if(CurrentPC.Health > 0)
		{
			if(SSTeamInfo(CurrentPC.PlayerReplicationInfo.Team) == WorldInfo.GRI.Teams[0])
				RPC.AddItem(CurrentPC);

			else if(SSTeamInfo(CurrentPC.PlayerReplicationInfo.Team) == WorldInfo.GRI.Teams[1])
				BPC.AddItem(CurrentPC);
		}
	}

	if(RPC.Length != 0)
		HUDMovie.SetRedPlayerScore(RPC);

	if(BPC.Length != 0)
		HUDMovie.SetBluePlayerScore(BPC);

	//WorldInfo.Game.Broadcast(self, RPC.Length@BPC.Length);
}

function SetHUDMovieVisible(bool NewVisible)
{
	HUDMovie.Root.GetObject("TopDisplay").SetVisible(NewVisible);
	HUDMovie.Root.GetObject("RBDisplay").SetVisible(NewVisible);
	HUDMovie.Minimap.SetVisible(NewVisible);

	bShowHUDMovie = NewVisible;
}

event PostRender()
{
	if(class'Engine'.static.IsEditor())
		Super.PostRender();

	else
	{
		RenderDelta = WorldInfo.TimeSeconds - LastHUDRenderTime;

		if(SizeX != Canvas.SizeX || SizeY != Canvas.SizeY)
		{
			PreCalcValues();
		}
	}
	if(!bShowingScore)
	{
		RenderMiniMap();

		RenderCrosshair();

		SSPawn(PlayerOwner.Pawn).RenderNames(self);
	}

	//RenderKillMessages();

	//RenderStats();

	if((ViewX != Canvas.ClipX) || (ViewY != Canvas.ClipY))
	{
		ResolutionChanged();
		ViewX = Canvas.ClipX;
		ViewY = Canvas.ClipY;
	}

	if(class'Engine'.static.IsEditor())
	{
		if(SSPlayerController(PlayerOwner).IsInState('PlayerWaiting') && SSPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo).Team == none)
			RenderSelectTeams(2.0);

		if(SSPlayerController(PlayerOwner).IsInState('PlayerWaiting') && SSPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo).Team != none)
			RenderSelectClasses(2.0);
	}

	if(PlayerOwner.Pawn == none && bShowHUDMovie && SSPlayerController(PlayerOwner).GetStateName() != 'RoundEnded')
		SetHUDMovieVisible(false);
		//bShowHUD = false;

	if(PlayerOwner.Pawn != none && !bShowHUDMovie && HighScoreMovie == none && !SSPlayerController(PlayerOwner).bSpectator)
	{
		ResolutionChanged();
		SetHUDMovieVisible(true);
		//bShowHUD = true;
	}

	if(HUDMovie != none)
		HUDMovie.TickHUD();

	if(HUDMovie.Segundo == 0 && WorldInfo.GRI.RemainingTime % 60 != 0)
		ResolutionChanged();

	if(HighScoreMovie != none)
		HighScoreMovie.TickHUD();

	LastHUDRenderTime = WorldInfo.TimeSeconds;
}

//reliable client function RenderKillMessages()
//{
//	if(SSGameReplicationInfo(WorldInfo.GRI).KillMessages != "" && SSGameReplicationInfo(WorldInfo.GRI).bNewMessage)
//	{
//		Canvas.SetPos(0, 0);
//		Canvas.DrawColor = MakeColor(255,0,0,255);
//		Canvas.DrawText(SSGameReplicationInfo(WorldInfo.GRI).KillMessages,,2.0,2.0);
//	}
//}

function RenderSelectTeams(float TextScale)
{
	local SSPlayerController PC;

	PC = SSPlayerController(PlayerOwner);

	Canvas.SetPos(0, 0);
	Canvas.DrawColor = PC.CurrentTeamIndex == 0 ? MakeColor(255,0,0,255) : MakeColor(255,255,0,255);
	Canvas.DrawText("Team:Red",,TextScale,TextScale);

	Canvas.SetPos(0, 20 * TextScale);
	Canvas.DrawColor = PC.CurrentTeamIndex == 1 ? MakeColor(0,0,255,255) : MakeColor(255,255,0,255);
	Canvas.DrawText("Team:Blue",,TextScale,TextScale);
}

function RenderSelectClasses(float TextScale)
{
	local SSPlayerController PC;
	local Color SelectColor;
	local byte TeamIndex;

	PC = SSPlayerController(PlayerOwner);
	TeamIndex = SSPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo).Team.TeamIndex;
	SelectColor = TeamIndex == 0 ? MakeColor(255,0,0,255) : MakeColor(0,0,255,255);

	Canvas.SetPos(0, 0);
	Canvas.DrawColor = SelectColor;
	Canvas.DrawText("Team:"$TeamIndex == 0 ? "Red" : "Blue",,TextScale,TextScale);

	if(PC.CurrentPawnClasses[0] != none)
	{
		Canvas.SetPos(0, 20 * TextScale);
		Canvas.DrawColor = PC.PawnClassesIndex == 0 ? SelectColor : MakeColor(255,255,0,255);
		Canvas.DrawText("1:"$PC.CurrentPawnClasses[0].PawnName,,TextScale,TextScale);
	}

	if(PC.CurrentPawnClasses[1] != none)
	{
		Canvas.SetPos(0, 40 * TextScale);
		Canvas.DrawColor = PC.PawnClassesIndex == 1 ? SelectColor : MakeColor(255,255,0,255);
		Canvas.DrawText("2:"$PC.CurrentPawnClasses[1].PawnName,,TextScale,TextScale);
	}

	if(PC.CurrentPawnClasses[2] != none)
	{
		Canvas.SetPos(0, 60 * TextScale);
		Canvas.DrawColor = PC.PawnClassesIndex == 2 ? SelectColor : MakeColor(255,255,0,255);
		Canvas.DrawText("3:"$PC.CurrentPawnClasses[2].PawnName,,TextScale,TextScale);
	}

	if(PC.CurrentPawnClasses[3] != none)
	{
		Canvas.SetPos(0, 80 * TextScale);
		Canvas.DrawColor = PC.PawnClassesIndex == 3 ? SelectColor : MakeColor(255,255,0,255);
		Canvas.DrawText("4:"$PC.CurrentPawnClasses[3].PawnName,,TextScale,TextScale);
	}

	if(PC.CurrentPawnClasses[4] != none)
	{
		Canvas.SetPos(0, 100 * TextScale);
		Canvas.DrawColor = PC.PawnClassesIndex == 4 ? SelectColor : MakeColor(255,255,0,255);
		Canvas.DrawText("5:"$PC.CurrentPawnClasses[4].PawnName,,TextScale,TextScale);
	}
}

function RenderStats()
{
	local SSPawn SSPawn;
	//local SSWeapBase W;

	if (PlayerOwner == None || SSWeapBase(PlayerOwner.Pawn.Weapon).bZoomedSniper)
		return;

	SSPawn = SSPawn(PlayerOwner.Pawn);
	if (SSPawn == None || SSPawn.Health <= 0/* || LocalPlayer(SSPlayerController(SSPawn.Controller).Player) != None*/)
		return;

	SSPawn.RenderStats(self, 1.3);

	//Canvas.SetPos(0, 0);
	//Canvas.DrawColor = MakeColor(255,0,0,255);
	//Canvas.DrawText("Time:"$WorldInfo.GRI.RemainingTime @ WorldInfo.GRI.TimeLimit,,2.5,2.5);

	//W = SSWeapBase(SSPawn.Weapon);
	//if(W != none)
	//{
	//	Canvas.SetPos(0, 50);
	//	Canvas.DrawColor = MakeColor(255,255,0,255);
	//	Canvas.DrawText("Ammo:"$W.AmmoCount,,2.5,2.5);
	//}
}

//function RenderMiniMap()
//{
//	local SSMapInfo SSMapInfo;
//	local Actor Actor;
//	local SSMinimapIconInterface SSMinimapIconInterface;
//	local Vector MinimapLocation;
//	local float MinimapPosX, MinimapPosY, MinimapSize;

//	// Ensure the player owner and the players pawn is valid
//	if (PlayerOwner == None || PlayerOwner.Pawn == None || SSWeapBase(PlayerOwner.Pawn.Weapon).bZoomedSniper)
//	{
//		return;
//	}

//	// Get the SS map info
//	SSMapInfo = SSMapInfo(WorldInfo.GetMapInfo());
//	if (SSMapInfo == None)
//	{
//		return;
//	}

//	//WorldInfo.Game.Broadcast(self, "rolando");

//	// Create the minimap material instance constant if it doesn't exist
//	if (MinimapMaterialInstanceConstant == None)
//	{
//		MinimapMaterialInstanceConstant = new () class'MaterialInstanceConstant';
//		if (MinimapMaterialInstanceConstant != None)
//		{
//			// Set the minimap material instance parent
//			MinimapMaterialInstanceConstant.SetParent(SSMapInfo.MinimapMaterial);
//			// Set the map texture
//			MinimapMaterialInstanceConstant.SetTextureParameterValue('Map', SSMapInfo.MinimapTexture);
//			// Set the map texture rotation
//			MinimapMaterialInstanceConstant.SetScalarParameterValue('MapRotation', SSMapInfo.MinimapTextureRotation);
//			// Set the map opacity
//			MinimapMaterialInstanceConstant.SetScalarParameterValue('MapOpacity', SSMapInfo.MinimapOpacity);
//		}

//		// Assign the team color to the minimap
//		NotifyTeamChanged();
//	}

//	// Define the size of the minimap
//	MinimapSize = SSMapInfo.MinimapSize; // 256.f padrão
//	//MinimapPosX = Canvas.ClipX - MinimapSize;
//	//MinimapPosY = 0;
//	if(SSMapInfo.MinimapPosition == 0 || SSMapInfo.MinimapPosition > 3)
//	{
//		MinimapPosX = 0;
//		MinimapPosY = 0;
//	}
//	else if(SSMapInfo.MinimapPosition == 1)
//	{
//		MinimapPosX = Canvas.ClipX - MinimapSize;
//		MinimapPosY = 0;
//	}
//	else if(SSMapInfo.MinimapPosition == 2)
//	{
//		MinimapPosX = 50;
//		MinimapPosY = Canvas.ClipY - MinimapSize;
//	}
//	else if(SSMapInfo.MinimapPosition == 3)
//	{
//		MinimapPosX = Canvas.ClipX - MinimapSize;
//		MinimapPosY = Canvas.ClipY - MinimapSize;
//	}

//	// Check the minimap material instance constant is valid
//	if (MinimapMaterialInstanceConstant != None)
//	{
//		// Draw the mini map at the top right hand corner
//		Canvas.SetPos(MinimapPosX, MinimapPosY);
//		Canvas.DrawMaterialTile(MinimapMaterialInstanceConstant, MinimapSize, MinimapSize, 0.f, 0.f, 1.f, 1.f);
//	}

//	// Draw all of the minimap icons
//	ForEach DynamicActors(class'Actor', Actor, class'SSMinimapIconInterface')
//	{
//		SSMinimapIconInterface = SSMinimapIconInterface(Actor);
//		if(SSMinimapIconInterface != None)
//		{			
//			MinimapLocation = ((SSMapInfo.MinimapWorldCenterLocation - SSMinimapIconInterface.GetMinimapWorldLocation()) / SSMapInfo.MinimapWorldExtent) * MinimapSize;
//			SSMinimapIconInterface.RenderMinimapIcon(Self, MinimapSize, MinimapPosX + (MinimapSize * 0.5f) + MinimapLocation.X, MinimapPosY + (MinimapSize * 0.5f) + MinimapLocation.Y, PlayerOwner.PlayerReplicationInfo);
//			//WorldInfo.Game.Broadcast(self, MinimapLocation);
//		}
//	}
//}

function RenderMiniMap()
{
	local SSMapInfo SSMapInfo;
	local Actor Actor;
	local SSMinimapIconInterface SSMinimapIconInterface;
	local Vector MinimapLocation;
	local float MinimapSize;

	if(PlayerOwner == None || PlayerOwner.Pawn == None)
		return;

	SSMapInfo = SSMapInfo(WorldInfo.GetMapInfo());
	if(SSMapInfo == None)
		return;

	if(!bInitMinimap)
	{
		NotifyTeamChanged();
		bInitMinimap = true;
	}

	MinimapSize = HUDMovie.Minimap.Imagem.GetFloat("_width");
	//HUDMovie.Mapa.SetPosition(Canvas.ClipX, Canvas.ClipY);

	ForEach DynamicActors(class'Actor', Actor, class'SSMinimapIconInterface')
	{
		SSMinimapIconInterface = SSMinimapIconInterface(Actor);
		if(SSMinimapIconInterface != None)
		{			
			MinimapLocation = ((SSMapInfo.MinimapWorldCenterLocation - SSMinimapIconInterface.GetMinimapWorldLocation()) / SSMapInfo.MinimapWorldExtent) * MinimapSize;
			SSMinimapIconInterface.RenderMinimapIcon(Self, MinimapSize, MinimapLocation.X, MinimapLocation.Y, PlayerOwner.PlayerReplicationInfo);
		}
	}
}

reliable client function DestroyPlayerIcons(string IconName)
{
	HUDMovie.Minimap.Mapa.GetObject(IconName).Invoke("removeMovieClip", args);

	//WorldInfo.Game.Broadcast(self, IconName);
}

simulated function NotifyLocalPlayerTeamReceived()
{
	NotifyTeamChanged();
}

function NotifyTeamChanged()
{
	//local AssaultTeamInfo AssaultTeamInfo;
	local SSPlayerReplicationInfo PRI;
	local Color OverrideTeamColor;
	local LinearColor LC;

	// Update the minimap material instance constant
	if (PlayerOwner != None && PlayerOwner.PlayerReplicationInfo != None)
	{
		PRI = SSPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo);
		//AssaultTeamInfo = AssaultTeamInfo(PlayerOwner.PlayerReplicationInfo.Team);
		//if (AssaultTeamInfo != None)
		//{
		if(PRI != None)
		{
			if(PRI.Team.TeamIndex == 0)
				OverrideTeamColor = MakeColor(255,0,0,255);

			if(PRI.Team.TeamIndex == 1)
				OverrideTeamColor = MakeColor(0,0,255,255);

			LC = ColorToLinearColor(OverrideTeamColor);
			MinimapMaterialInstanceConstant.SetVectorParameterValue('TeamColor', LC);
		}
		//}

		if(HUDMovie != none)
		{
			HUDMovie.StatusMC.GotoAndStopI(PRI.Team.TeamIndex + 1);
			HUDMovie.ScoreMC.GotoAndStopI(PRI.Team.TeamIndex + 1);
			//HUDMovie.Root.GetObject("MinimapMC").GotoAndStopI(PRI.Team.TeamIndex + 1);
			HUDMovie.Minimap.Contorno.GotoAndStopI(PRI.Team.TeamIndex + 1);
		}
	}
}

function RenderCrosshair()
{
	local SSWeapBase SSWeap;

	// Abort if the player owner is none, player owner's pawn is none or the Canvas is none
	if (PlayerOwner == None || PlayerOwner.Pawn == None || Canvas == None)
	{
		return;
	}

	// Forwards the render crosshair call to the weapon
	SSWeap = SSWeapBase(PlayerOwner.Pawn.Weapon);
	if (SSWeap != None)
	{
		SSWeap.RenderCrosshair(Self);
	}
}

function DisplayConsoleMessages()
{
 	local int Idx;

	for (Idx = 0; Idx < ConsoleMessages.Length; Idx++)
    {
		ConsoleMessages[Idx].TextColor = ConsoleColor;
    }

	super.DisplayConsoleMessages();
}

exec function ShowMenu()
{
	if(PauseMenuMovie != None && PauseMenuMovie.bMovieIsOpen)
		ClosePauseMenu();

	else
	{
		if (PauseMenuMovie == None)
		{
			PauseMenuMovie = new class'SSGFxPauseMenu';
			PauseMenuMovie.MovieInfo = SwfMovie'HUDMenus.EscMenu';
			PauseMenuMovie.bEnableGammaCorrection = FALSE;
			PauseMenuMovie.LocalPlayerOwnerIndex = class'Engine'.static.GetEngine().GamePlayers.Find(LocalPlayer(PlayerOwner.Player));
			PauseMenuMovie.SetTimingMode(TM_Real);
		}

		SetVisible(false);
		PauseMenuMovie.Start();
		PauseMenuMovie.AddFocusIgnoreKey('Escape');
	}
}

function ClosePauseMenu()
{
	PauseMenuMovie.Close(false);
    SetVisible(true);
}

function SetVisible(bool bNewVisible)
{
	//bEnableActorOverlays = bNewVisible;
	bShowHUD = bNewVisible;
}


DefaultProperties
{
	ConsoleColor=(R=255,G=0,B=0,A=255)
}
