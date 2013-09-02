class SSGameInfo extends SimpleGame
	config(Game);

//var array<SSPawn> PawnClass;

//var SSPawn SelectedPawnClass;

var globalconfig int MinNetPlayers;

var const SSTeamInfo TeamInfoArchetypes[2];

var float ScoreCount;

var PlayerStart ChoosePS;

struct SpecCam
{
	var array<CameraActor> AllCams;
	var int CamsIndex;
	var PlayerController CamPC;
};

var SpecCam Cameras;

var array<SSPawn> AllPawns;
//var int PawnsIndex;

var() int ResetCountDown;
var() config int ResetTimeDelay;           // time (seconds) before restarting teams

struct Bases
{
	var name SectorName;
	var array<Note> SectorBase;
};

var array<Bases> SectorBases;

var int TempoJogo;

replication
{
	if(bNetDirty)
		TempoJogo;
}

function StartMatch()
{
	local Note NT;
	local int i, j, index, RandCount;
	local Vector SpawnLoc;
	local Rotator SpawnRot;

	super.StartMatch();

	foreach WorldInfo.AllActors(class'Note', NT)
	{
		if(SectorBases.Length == 0)
		{
			SectorBases.Insert(0, 1);
			SectorBases[0].SectorBase.AddItem(NT);
			SectorBases[0].SectorName = NT.Tag;
		}

		else
		{
			for (i = 0; i < SectorBases.length; i++)
			{
				if(SectorBases[i].SectorName == NT.Tag)
					SectorBases[i].SectorBase.AddItem(NT);

				else if(i == SectorBases.length -1)
				{
					index = SectorBases.length;
					SectorBases.Insert(index, 1);
					SectorBases[index].SectorName = NT.Tag;
					SectorBases[index].SectorBase.AddItem(NT);
					break;
				}
			}
		}
	}

	for (j = 0; j < SectorBases.length; j++)
	{
		RandCount = Rand(SectorBases[j].SectorBase.length);
		SpawnLoc = SectorBases[j].SectorBase[RandCount].Location;
		SpawnRot = SectorBases[j].SectorBase[RandCount].Rotation;
		Spawn(class'SSCaptureBase',,,SpawnLoc, SpawnRot);

		//WorldInfo.Game.Broadcast(self, SectorBases[j].SectorName@SectorBases[j].SectorBase.length@SectorBases[j].SectorBase[RandCount]);
	}
}

simulated function PostBeginPlay()
{
	local SSTeamInfo TI;
	local int i;

	super.PostBeginPlay();

	for(i=0; i < ArrayCount(TeamInfoArchetypes); i++)
	{
		TI = Spawn(TeamInfoArchetypes[i].class,,,,,TeamInfoArchetypes[i]);

		if (TI != None)
		{
			TI.TeamIndex = i;
			GameReplicationInfo.Teams.AddItem(TI);
		}
	}
}

//event InitGame(string Options, out string ErrorMessage)
//{
//	local string char, teamSelec;

//	char = ParseOption(Options, "CharNum");

//	teamSelec = ParseOption(Options, "TeamNum");

//	//SetCurrentTeam(teamSelec);
//	//`log("ParseOptionsTest"@char);
//}

event PlayerController Login(string Portal, string Options, const UniqueNetID UniqueID, out string ErrorMessage)
{
	local string char, teamSelec;
	local PlayerController PC;

	PC = super.Login(Portal, Options, UniqueID, ErrorMessage);

	char = ParseOption(Options, "CharNum");

	teamSelec = ParseOption(Options, "TeamNum");

	SSPlayerController(PC).bSpectator = bool(ParseOption(Options, "bSpec"));
	SSPlayerController(PC).bHighScore = bool(ParseOption(Options, "bHS"));
	//SSPlayerController(PC).SaveConfig();

	//if(char == "")
	//	char = "99";

	//if(teamSelec == "")
	//	teamSelec = "255";

	//if(char == "" || teamSelec == "")
	//	SSPlayerController(PC).SetTimer(1.0, false, 'SetWaiting');

	//else
	//{
		SetCurrentTeam(PC.PlayerReplicationInfo, int(teamSelec));
		SetPawnClass(PC, int(char));
	//}

	return PC;
}

simulated function SetPawnClass(PlayerController PC, int index)
{
	local SSTeamInfo SSTeamInfo;
	
	//if(index == 99)
	//{
	//	SSPlayerController(PC).SetTimer(0.5, false, 'SetWaiting');
	//	RestartPlayer(PC);
	//	return;
	//}

	SSTeamInfo = SSTeamInfo(PC.PlayerReplicationInfo.Team);
	if(SSTeamInfo != none)
	{
		if(SSTeamInfo.PawnArchetype[index] != none)
			SSPlayerController(PC).CurrentPawnClass = SSTeamInfo.PawnArchetype[index];
			//SelectedPawnClass = SSTeamInfo.PawnArchetype[index];

		PC.PlayerReplicationInfo.PlayerName = SSPlayerController(PC).CurrentPawnClass.PawnName;
		SSPlayerController(PC).SetInitialScore();
	}
}

simulated function SetCurrentTeam(PlayerReplicationInfo PRI, int TeamIndex)
{
	local SSPlayerReplicationInfo SSPlayerReplicationInfo;

	//if(TeamIndex == 255)
	//	return;

	SSPlayerReplicationInfo = SSPlayerReplicationInfo(PRI);
	if (SSPlayerReplicationInfo == None)
	{
		return;
	}

	SSPlayerReplicationInfo.SetPlayerTeam(GameReplicationInfo.Teams[TeamIndex/*Rand(2)*/]);
}

event AddDefaultInventory(Pawn Pawn)
{
	local SSInventoryManager SSInventoryManager;
	local int i;

	if (Pawn == None)
	{
		return;
	}

	SSInventoryManager = SSInventoryManager(Pawn.InvManager);
	if (SSInventoryManager == None)
	{
		return;
	}
	
	for(i=0;i < SSPawn(Pawn).InitWeapons.Length;i++)
		SSInventoryManager.CreateInventoryFromArchetype(SSPawn(Pawn).InitWeapons[i]);

	//WorldInfo.Game.Broadcast(self, Arma[0].Class);
}

function Pawn SpawnDefaultPawnFor(Controller NewPlayer, NavigationPoint StartSpot)
{
	local Rotator StartRotation;
	local SSTeamInfo SSTeamInfo;

	// Don't allow pawn to be spawned with any pitch or roll
	StartRotation.Yaw = StartSpot.Rotation.Yaw;

	//SetCurrentTeam(NewPlayer.PlayerReplicationInfo);

	// Check incoming variables
	if(NewPlayer != None && NewPlayer.PlayerReplicationInfo != None)
	{
		SSTeamInfo = SSTeamInfo(NewPlayer.PlayerReplicationInfo.Team);
		if (SSTeamInfo != None /*&& SSTeamInfo.PawnArchetype.Length < 1*/)
		{
			//if(SelectedPawnClass != none)
			//	return Spawn(SelectedPawnClass.Class,,, StartSpot.Location, StartRotation, SelectedPawnClass);

			if(SSPlayerController(NewPlayer).CurrentPawnClass != none)
			{
				NewPlayer.PlayerReplicationInfo.PlayerName = SSPlayerController(NewPlayer).CurrentPawnClass.PawnName;
				SSPlayerController(NewPlayer).SetInitialScore();

				if(ChoosePS != none)
					ChoosePS = none;

				return Spawn(SSPlayerController(NewPlayer).CurrentPawnClass.Class,,, StartSpot.Location, StartRotation, 
					SSPlayerController(NewPlayer).CurrentPawnClass);
			}
		}
	}

	// Abort if the default pawn archetype is none
	if(DefaultPawnClass == None)
	{
		return None;
	}

	//SpawnIndex = Rand(2);
	//WorldInfo.Game.Broadcast(self, GameReplicationInfo.Teams.Length);
	// Spawn and return the pawn
	return Spawn(DefaultPawnClass,,, StartSpot.Location, StartRotation);
}

function RestartPlayer(Controller NewPlayer)
{
	local SSPlayerReplicationInfo SSPlayerReplicationInfo;

	if(SSPlayerController(NewPlayer).bSpectator)
	{
		if(!SSPlayerController(NewPlayer).bHighScore)
		{
			Cameras.CamPC = PlayerController(NewPlayer);
			//ChangeCameras();
		}

		else
			SSPlayerController(NewPlayer).SetTimer(3.0, false, 'ShowHS');
			//SSHUD(PlayerController(NewPlayer).myHUD).ShowHighScore();

		return;
	}

	// Check incoming variables
	if(NewPlayer == None || (NumPlayers < MinNetPlayers && WorldInfo.NetMode != NM_Standalone))
	{
		return;
	}

	// Grab the player replication info and check if the player has assigned a class archetype
	SSPlayerReplicationInfo = SSPlayerReplicationInfo(NewPlayer.PlayerReplicationInfo);
	if(SSPlayerReplicationInfo == None/* || SSPlayerReplicationInfo.ClassArchetype == None*/)
	{
		return;
	}

	// Proceed with restarting the player
	Super.RestartPlayer(NewPlayer);

	//WorldInfo.Game.Broadcast(self, NewPlayer.GetStateName());

	if(SSPlayerReplicationInfo.Team != none && NewPlayer.Pawn == none)
		SSPlayerController(NewPlayer).SetTimer(1.0, false, 'TryToRestartPlayer');
		//RestartPlayer(NewPlayer);
}

function ChangeCameras()
{
	//local SSPawn P;
	local CameraActor Cams;

	foreach WorldInfo.AllActors(class'CameraActor', Cams)
	{
		if(DynamicCameraActor(Cams) != none);

		else
			Cameras.AllCams.AddItem(Cams);
	}

	//foreach WorldInfo.AllPawns(class'SSPawn', P)
	//{
	//	AllPawns.AddItem(P);
	//}

	//Cameras.CamPC.SetViewTarget(AllPawns[0]);

	SetCameraSpec();
}

function SetCameraSpec()
{
	Cameras.CamPC.SetViewTarget(Cameras.AllCams[Cameras.CamsIndex]);

	if(Cameras.CamsIndex < Cameras.AllCams.Length - 1)
		Cameras.CamsIndex++;

	else if(Cameras.CamsIndex == Cameras.AllCams.Length - 1)
		Cameras.CamsIndex = 0;

	SetTimer(SSMapInfo(WorldInfo.GetMapInfo()).SetCameraTime, false, 'SetCameraSpec');
}

function NavigationPoint FindPlayerStart(Controller Player, optional byte InTeam, optional string IncomingName)
{
	local NavigationPoint N, BestStart;
	//local Teleporter Tel;

	// allow GameRulesModifiers to override playerstart selection
	//if (BaseMutator != None)
	//{
	//	N = BaseMutator.FindPlayerStart(Player, InTeam, IncomingName);
	//	if (N != None)
	//	{
	//		return N;
	//	}
	//}

	// if incoming start is specified, then just use it
	//if(incomingName!="")
	//{
	//	ForEach WorldInfo.AllNavigationPoints( class 'Teleporter', Tel )
	//		if( string(Tel.Tag)~=incomingName )
	//			return Tel;
	//}

	// always pick StartSpot at start of match
	//if (ShouldSpawnAtStartSpot(Player) &&
	//	(PlayerStart(Player.StartSpot) == None || RatePlayerStart(PlayerStart(Player.StartSpot), InTeam, Player) >= 0.0))
	//{
	//	return Player.StartSpot;
	//}

	BestStart = ChoosePlayerStart(Player, InTeam);

	if((BestStart == None) && (Player == None))
	{
		// no playerstart found, so pick any NavigationPoint to keep player from failing to enter game
		//`log("Warning - PATHS NOT DEFINED or NO PLAYERSTART with positive rating");
		ForEach AllActors(class 'NavigationPoint', N)
		{
			BestStart = N;
			break;
		}
	}
	return BestStart;
}

function PlayerStart ChoosePlayerStart(Controller Player, optional byte InTeam)
{
	local PlayerStart P, BestStart;
	local byte Team;
	local int i;
	local array<playerstart> PlayerStarts, CurrentTeamPlayerStarts;

	if(ChoosePS != none)
		return ChoosePS;

	// use InTeam if player doesn't have a team yet
	Team = ((Player != None) && (Player.PlayerReplicationInfo != None) && (Player.PlayerReplicationInfo.Team != None) )
			? byte(Player.PlayerReplicationInfo.Team.TeamIndex)
			: InTeam;

	// Find best playerstart
	foreach WorldInfo.AllNavigationPoints(class'PlayerStart', P)
	{
		if(P.bEnabled)
			PlayerStarts[PlayerStarts.Length] = P;

		for(i=0; i<PlayerStarts.Length; i++)
		{
			P = PlayerStarts[i];
			
			if(Team == 255)
				CurrentTeamPlayerStarts.AddItem(P);

			else if(P.TeamIndex == Team && P.TeamIndex != 255)
				CurrentTeamPlayerStarts.AddItem(P);

			//WorldInfo.Game.Broadcast(self,CurrentTeamPlayerStarts[i]@CurrentTeamPlayerStarts[i].TeamIndex@Team);
		}

		BestStart = CurrentTeamPlayerStarts[Rand(CurrentTeamPlayerStarts.Length)];
	}
	return BestStart;
}

//function MatchTimer();


/********************************************
 * primeiros testes com o sistema de pontuação
**/

function Killed(Controller Killer, Controller KilledPlayer, Pawn KilledPawn, class<DamageType> damageType)
{
	//local SSPlayerController PC;

	local SSPawn P;

	//SSPawn(KilledPlayer.Pawn).DestroyIcons();

    if(KilledPlayer != None && KilledPlayer.bIsPlayer)
	{
		KilledPlayer.PlayerReplicationInfo.IncrementDeaths();
		KilledPlayer.PlayerReplicationInfo.SetNetUpdateTime(FMin(KilledPlayer.PlayerReplicationInfo.NetUpdateTime, WorldInfo.TimeSeconds + 0.3 * FRand()));
		//BroadcastDeathMessage(Killer, KilledPlayer, damageType);
		
	}

	if(damageType == class'SSDmgType_HeadShot')
	{
		ScoreCount = 20.f;
		//PlayerController(KilledPlayer).ClientPlaySound(SoundCue'TestesPack.Sounds.Headshot_Announcement');
		//PlayerController(Killer).ClientPlaySound(SoundCue'TestesPack.Sounds.Headshot_Announcement');
		SSPawn(KilledPlayer.Pawn).ClientPlaySound(SoundCue'TestesPack.Sounds.Headshot_Announcement');
		SSPawn(Killer.Pawn).ClientPlaySound(SoundCue'TestesPack.Sounds.Headshot_Announcement');
	}

	else if(damageType == class'UTDmgType_Grenade')
		ScoreCount = 15.f;

	else if(damageType == class'SSDmgType_Melee')
		ScoreCount = 30.f;

	else
		ScoreCount = 10.f;

	if(KilledPlayer != None)
	{
		ScoreKill(Killer, KilledPlayer);
	}

	//foreach WorldInfo.AllControllers(class'SSPlayerController', PC)
	//{
	//	SSHUD(PC.myHUD).HUDMovie.CreateKLMessage();
	//	//WorldInfo.Game.Broadcast(self, "Controles"@PC);
	//}

	//SSGameReplicationInfo(GameReplicationInfo).KillMessages = SSPawn(KilledPlayer.Pawn).PawnName@"Morto por:"@
	//	string(SSWeapBase(Killer.Pawn.Weapon).WeaponName)@"Player:"@SSPawn(Killer.Pawn).PawnName;
	//SSGameReplicationInfo(GameReplicationInfo).KillMessagesCount++;

	//WorldInfo.Game.Broadcast(self, SSPawn(KilledPlayer.Pawn).PawnName@"Killed By:"@damageType@"Player:"@SSPawn(Killer.Pawn).PawnName);

	DiscardInventory(KilledPawn, Killer);
    //NotifyKilled(Killer, KilledPlayer, KilledPawn, damageType);

	if(damageType == class'DmgType_Suicided')
		return;

	foreach WorldInfo.AllPawns(class'SSPawn', P)
	{
		if(Killer == none)
			Killer = KilledPlayer;

		//if(damageType == class'UTDmgType_Rocket')
		

		P.CreateKLMessage(SSPawn(KilledPlayer.Pawn).PawnName, SSWeapBase(Killer.Pawn.Weapon).IconNumber, SSPawn(Killer.Pawn).PawnName);
		//WorldInfo.Game.Broadcast(self, "Controles"@PC);
	}
}

/***
 * * ScoreKill
 */
function ScoreKill(Controller Killer, Controller Other)
{
	local SSPlayerReplicationInfo KPRI, OPRI;

	KPRI = SSPlayerReplicationInfo(Killer.PlayerReplicationInfo);
	OPRI = SSPlayerReplicationInfo(Other.PlayerReplicationInfo);
	/*if((killer == Other) || (killer == None))
	{
		if((Other!=None) && (Other.PlayerReplicationInfo != None))
		{
			Other.PlayerReplicationInfo.Score -= 1;
			Other.PlayerReplicationInfo.bForceNetUpdate = TRUE;
			//WorldInfo.Game.Broadcast(self, "Score" @ Other.PlayerReplicationInfo.Score);
		}
	}
	else*/ if(KPRI != None && Other.PlayerReplicationInfo.Team != KPRI.Team)
	{
		KPRI.Score += ScoreCount;
		SSTeamInfo(KPRI.Team).ScoreTeam += ScoreCount;
		//Killer.PlayerReplicationInfo.Kills++;
		KPRI.Frags++;
		//Other.PlayerReplicationInfo.Deaths++;
		KPRI.bForceNetUpdate = TRUE;

		if(KPRI.Team.TeamIndex == 0)
			SSGameReplicationInfo(WorldInfo.GRI).SetRedPlayersScore(KPRI.PlayerName, ScoreCount, KPRI.Frags, KPRI.Deaths, SSPlayerController(Killer));

		else if(KPRI.Team.TeamIndex == 1)
			SSGameReplicationInfo(WorldInfo.GRI).SetBluePlayersScore(KPRI.PlayerName, ScoreCount, KPRI.Frags, KPRI.Deaths, SSPlayerController(Killer));

		if(OPRI.Team.TeamIndex == 0)
			SSGameReplicationInfo(WorldInfo.GRI).SetRedPlayersScore(OPRI.PlayerName, 0, OPRI.Frags, OPRI.Deaths, SSPlayerController(Other));

		else if(OPRI.Team.TeamIndex == 1)
			SSGameReplicationInfo(WorldInfo.GRI).SetBluePlayersScore(OPRI.PlayerName, 0, OPRI.Frags, OPRI.Deaths, SSPlayerController(Other));
	}

	if(Killer != None || MaxLives > 0)
	{
		CheckScore(Killer.PlayerReplicationInfo);
	}
}

function Logout(Controller Exiting)
{
	local SSPlayerReplicationInfo EPRI;

	super.Logout(Exiting);

	EPRI = SSPlayerReplicationInfo(Exiting.PlayerReplicationInfo);

	if(EPRI.Team.TeamIndex == 0)
		SSGameReplicationInfo(WorldInfo.GRI).SetRedPlayersScore("", -10000, 0, 0, SSPlayerController(Exiting));

	else if(EPRI.Team.TeamIndex == 1)
		SSGameReplicationInfo(WorldInfo.GRI).SetBluePlayersScore("", -10000, 0, 0, SSPlayerController(Exiting));
}

/**
 * parada para o multiplayer funcionar 
 **/

function InitGameReplicationInfo()
{
	local GameReplicationInfo GRI;
	
	Super.InitGameReplicationInfo();

	GRI = GameReplicationInfo;
	GRI.GoalScore = GoalScore;
	GRI.TimeLimit = TimeLimit;
	GameReplicationInfo.RemainingTime = 60 * TimeLimit;
	//GRI.MinNetPlayers = MinNetPlayers;
	//GRI.bConsoleServer = (WorldInfo.bUseConsoleInput || WorldInfo.IsConsoleBuild());

	//`log("TimeLimit" @ TimeLimit);
	//`log("Remaining time" @ GameReplicationInfo.RemainingTime);
}

auto State PendingMatch
{
	function bool MatchIsInProgress()
	{
		return false;
	}

	/**
	 * Tells all of the currently connected clients to register with arbitration.
	 * The clients will call back to the server once they have done so, which
	 * will tell this state to see if it is time for the server to register with
	 * arbitration.
	 */
	function StartMatch()
	{

		//WorldInfo.Game.Broadcast(self, NumPlayers);

		if (bUsingArbitration)
		{
			StartArbitrationRegistration();
		}
		else if(NumPlayers >= MinNetPlayers || WorldInfo.NetMode == NM_Standalone)
		{
			Global.StartMatch();
			GotoState('MatchInProgress');
		}
	}

	/**
	 * Kicks off the async tasks of having the clients register with
	 * arbitration before the server does. Sets a timeout for when
	 * all slow to respond clients get kicked
	 */
	function StartArbitrationRegistration()
	{
		local PlayerController PC;
		local UniqueNetId HostId;
		local OnlineGameSettings GameSettings;

		if (!bHasArbitratedHandshakeBegun)
		{
			// Tell PreLogin() to reject new connections
			bHasArbitratedHandshakeBegun = true;

			// Get the host id from the game settings in case splitscreen works with arbitration
			GameSettings = GameInterface.GetGameSettings(PlayerReplicationInfoClass.default.SessionName);
			HostId = GameSettings.OwningPlayerId;

			PendingArbitrationPCs.Length = 0;
			// Iterate the controller list and tell them to register with arbitration
			foreach WorldInfo.AllControllers(class'PlayerController', PC)
			{
				// Skip notifying local PCs as they are handled automatically
				if (!PC.IsLocalPlayerController())
				{
					PC.ClientSetHostUniqueId(HostId);
					PC.ClientRegisterForArbitration();
					// Add to the pending list
					PendingArbitrationPCs[PendingArbitrationPCs.Length] = PC;
				}
				else
				{
					// Add them as having completed arbitration
					ArbitrationPCs[ArbitrationPCs.Length] = PC;
				}
			}
			// Start the kick timer
			SetTimer( ArbitrationHandshakeTimeout,false,nameof(ArbitrationTimeout) );
		}
	}

	/**
	 * Does the registration for the server. This must be done last as it
	 * includes all the players info from their registration
	 */
	function RegisterServerForArbitration()
	{
		if (GameInterface != None)
		{
			GameInterface.AddArbitrationRegistrationCompleteDelegate(ArbitrationRegistrationComplete);
			GameInterface.RegisterForArbitration(PlayerReplicationInfoClass.default.SessionName);
		}
		else
		{
			// Fake as working without subsystem
			ArbitrationRegistrationComplete(PlayerReplicationInfoClass.default.SessionName,true);
		}
	}

	/**
	 * Callback from the server that starts the match if the registration was
	 * successful. If not, it goes back to the menu
	 *
	 * @param SessionName the name of the session this is for
	 * @param bWasSuccessful whether the registration worked or not
	 */
	function ArbitrationRegistrationComplete(name SessionName,bool bWasSuccessful)
	{
		// Clear the delegate so we don't leak with GC
		GameInterface.ClearArbitrationRegistrationCompleteDelegate(ArbitrationRegistrationComplete);
		if (bWasSuccessful)
		{
			// Start the match
			StartArbitratedMatch();
		}
		else
		{
			ConsoleCommand("Disconnect");
		}
	}

	/**
	 * Handles kicking any clients that haven't completed handshaking
	 */
	function ArbitrationTimeout()
	{
		local int Index;

		// Kick any pending players
		for (Index = 0; Index < PendingArbitrationPCs.Length; Index++)
		{
			AccessControl.KickPlayer(PendingArbitrationPCs[Index],GameMessageClass.Default.MaxedOutMessage);
		}
		PendingArbitrationPCs.Length = 0;
		// Do the server registration now that any remaining clients are kicked
		RegisterServerForArbitration();
	}

	/**
	 * Called once arbitration has completed and kicks off the real start of the match
	 */
	function StartArbitratedMatch()
	{
		bNeedsEndGameHandshake = true;
		// Start the match
		Global.StartMatch();

		//coisa que acrescentei
		GotoState('MatchInProgress');
	}

	/**
	 * Removes the player controller from the pending list. Kicks that PC if it
	 * failed to register for arbitration. Starts the match if all clients have
	 * completed their registration
	 *
	 * @param PC the player controller to mark as done
	 * @param bWasSuccessful whether the PC was able to register for arbitration or not
	 */
	function ProcessClientRegistrationCompletion(PlayerController PC,bool bWasSuccessful)
	{
		local int FoundIndex;

		// Search for the specified PC and remove if found
		FoundIndex = PendingArbitrationPCs.Find(PC);
		if (FoundIndex != INDEX_NONE)
		{
			PendingArbitrationPCs.Remove(FoundIndex,1);
			if (bWasSuccessful)
			{
				// Add to the completed list
				ArbitrationPCs[ArbitrationPCs.Length] = PC;
			}
			else
			{
				AccessControl.KickPlayer(PC,GameMessageClass.Default.MaxedOutMessage);
			}
		}
		// Start the match if all clients have responded
		if (PendingArbitrationPCs.Length == 0)
		{
			// Clear the kick timer
			SetTimer( 0,false,nameof(ArbitrationTimeout) );
			RegisterServerForArbitration();
		}
	}

	event EndState(name NextStateName)
	{
		// Clear the kick timer
		SetTimer(0,false,nameof(ArbitrationTimeout));

		if(GameInterface != None )
		{
			GameInterface.ClearArbitrationRegistrationCompleteDelegate(ArbitrationRegistrationComplete);
		}
	}
}

state MatchInProgress
{
	function bool MatchIsInProgress()
	{
		return true;
	}

	function Timer()
	{
		Global.Timer();
		
		if(TimeLimit > 0)
		{
			//GameReplicationInfo.bStopCountDown = false;

			//GameReplicationInfo.RemainingTime--;

			TempoJogo = GameReplicationInfo.RemainingTime;
			
			if(GameReplicationInfo.RemainingTime <= 0)
			{
				GotoState('MatchOver');
				//WorldInfo.Game.Broadcast(self,"Indo para o fim da partida");
				GameReplicationInfo.RemainingTime = 0;
			}
		}
	}

	function BeginState(Name PreviousStateName)
	{
		local PlayerReplicationInfo PRI;

		GameReplicationInfo.bStopCountDown = false;

		if(PreviousStateName != 'RoundOver')
		{
			foreach DynamicActors(class'PlayerReplicationInfo', PRI)
			{
				PRI.StartTime = 0;
			}
			GameReplicationInfo.ElapsedTime = 0;
			bWaitingToStartMatch = false;
		}
	}
}

State MatchOver
{
	function RestartPlayer(Controller aPlayer)
	{
		if(Role < ROLE_Authority);

		else
			RestartGame();
	}
	//function ScoreKill(Controller Killer, Controller Other) {}

	event PostLogin(PlayerController NewPlayer)
	{
		Global.PostLogin(NewPlayer);

		//NewPlayer.GameHasEnded(EndGameFocus);
	}

	function Timer()
	{
		Global.Timer();
	}

	function BeginState(Name PreviousStateName)
	{
		//local Pawn P;

		GameReplicationInfo.bStopCountDown = true;
		//foreach WorldInfo.AllPawns(class'Pawn', P)
		//{
		//	P.TurnOff();
		//	//SSHUD(SSPlayerController(P.Controller).myHUD).ShowHighScore();
		//}

		ShowScore();
		//SetTimer(3.0, false,'FimDOJogo');
	}

	function ResetLevel()
	{
		RestartGame();
	}

	function TrocaMapa()
	{
		ConsoleCommand("open MenuTest");
	}

	function FimDOJogo()
	{
		//local Controller C;

		//foreach WorldInfo.AllControllers(class'Controller', C)
		//{
		//	if(Role < ROLE_Authority)
		//		C.ConsoleCommand("Disconnect");
		//}
		GotoState('PendingMatch');
	}

	function ShowScore()
	{		
		local Controller C;

		foreach WorldInfo.AllControllers(class'Controller', C)
		{
			SSPlayerController(C).GameHasEnded();
		}
	}
}

DefaultProperties
{
	bRestartLevel=false
	HUDType=class'SnuffShow.SSHUD'
	//bUseClassicHUD=true
	DefaultPawnClass=none//class'SnuffShow.SSPawn'
	PlayerControllerClass=class'SnuffShow.SSPlayerController'
	PlayerReplicationInfoClass=class'SSPlayerReplicationInfo'
	GameReplicationInfoClass=class'SSGameReplicationInfo'
	TeamInfoArchetypes(0)=SSTeamInfo'Archetypes.TeamInfos.SSTeamInfo_Red'
	TeamInfoArchetypes(1)=SSTeamInfo'Archetypes.TeamInfos.SSTeamInfo_Blue'
	//DefaultInventory(1)=SSWeap_AK47
	//bGivePhysicsGun=false
}