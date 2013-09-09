class SSPlayerControllerMenu extends UTPlayerController;

// Boomchacalaca

var repnotify string CharIndex, TeamIndex;
var repnotify bool bTeamSelected;
var array<SSPawn> PawnClasses, RedPawnClasses, BluePawnClasses;
var repnotify SSPawn CurrentPawnClasses[5];
var SSPawn CurrentPawnClass;
var repnotify int PawnClassesIndex, CurrentTeamIndex;

var OnlineGameInterface myGameInterface;
var OnlineGameSearch SearchSettings;
var OnlineGameSettings GameSettings;
var transient UIDataStore_OnlineGameSettings SettingsDataStore;

replication
{
	if(bNetOwner)
		PawnClassesIndex, CurrentTeamIndex, bTeamSelected, CharIndex, TeamIndex, CurrentPawnClasses;
}

simulated function GetPawnClasses()
{
	local int i;

	if(CurrentTeamIndex == 0)
	{
		for(i = 0; i < RedPawnClasses.length; i++)
		{
			PawnClasses.AddItem(RedPawnClasses[i]);
			CurrentPawnClasses[i] = PawnClasses[i];
		}
	}

	else
	{
		for(i = 0; i < BluePawnClasses.length; i++)
		{
			PawnClasses.AddItem(BluePawnClasses[i]);
			CurrentPawnClasses[i] = PawnClasses[i];
		}
	}
}
auto state PlayerWaiting
{
	ignores SeePlayer, HearNoise, NotifyBump, TakeDamage, PhysicsVolumeChange, SwitchToBestWeapon;

	exec function StartFire(optional byte FireModeNum)
	{
		//Clicked();
	}

	exec function NextWeapon()
	{
		if(!bTeamSelected)
		{
			CurrentTeamIndex = CurrentTeamIndex == 0 ? 1 : 0;
			SetCurrentTeamIndex(CurrentTeamIndex);

			//WorldInfo.Game.Broadcast(self, "CurrentTeam"@CurrentTeamIndex);
		}

		else
		{
			SelectNextPawn();
		}
	}

	exec function PrevWeapon()
	{
		if(!bTeamSelected)
		{
			CurrentTeamIndex = CurrentTeamIndex == 0 ? 1 : 0;
			SetCurrentTeamIndex(CurrentTeamIndex);

			//WorldInfo.Game.Broadcast(self, "CurrentTeam"@CurrentTeamIndex);
		}

		else
		{
			SelectPrevPawn();
		}
	}
}

reliable server function Clicked()
{
	if(!bTeamSelected)
	{
		bTeamSelected = true;
		TeamIndex = string(CurrentTeamIndex);
		GetPawnClasses();
	}

	//if(TeamIndex == string(1))
	//	OnJoinOnlineGameComplete('Game', true);

	else
	{
		CharIndex = string(PawnClassesIndex);
		OnGameCreated('Game', true);
		//ConsoleCommand("open mapa1?CharNum="$CharIndex$"?TeamNum="$TeamIndex$"?listen=true"$"?bIsLanMatch=true");
		//OpenNativeMatchmakingUI();
	}
}

exec function HostGame(int TheTeam, int TheChar)
{
	TeamIndex = string(TheTeam);
	CharIndex = string(TheChar);

	OpenNativeMatchmakingUI();

	OnCreateOnlineGameComplete('Game', true);
}

exec function JoinGame(int TheTeam, int TheChar)
{
	TeamIndex = string(TheTeam);
	CharIndex = string(TheChar);

	OpenNativeMatchmakingUI();

	OnJoinOnlineGameComplete('Game', true);
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

simulated function PostBeginPlay()
{
	super.PostBeginPlay();

	SearchSettings = new class'OnlineGameSearch';
    GameSettings = new class'OnlineGameSettings';
	SettingsDataStore = UIDataStore_OnlineGameSettings(class'UIRoot'.static.StaticResolveDataStore('UTGameSettings'));

    OnlineSuppliedUIInterface(OnlineSub.GetNamedInterface('SuppliedUI')).ShowMatchmakingUI(0, SearchSettings, GameSettings);

	SetTimer(0.1, false, 'InitPlayer');
}

simulated function InitPlayer()
{
	GotoState('PlayerWaiting');
	//WorldInfo.Game.Broadcast(self, GetStateName());
}

function ClearCreateOnlineGameDelegates()
{
    OnlineSub.GameInterface.ClearCreateOnlineGameCompleteDelegate(OnCreateOnlineGameComplete);
}

function OnGameCreated(name SessionName,bool bWasSuccessful)
{
	local OnlineGameSettings LocalGameSettings;
	local string TravelURL;
	//local OnlineSubsystem OnlineSub;
	local OnlineGameInterface GameInterface;
	//local string Mutators;
	//local int OutValue;
	local string OutStringValue;
	local UIDataStore_Registry Registry;

	Registry = UIDataStore_Registry(class'UIRoot'.static.StaticResolveDataStore('Registry'));

	// Figure out if we have an online subsystem registered
	OnlineSub = class'GameEngine'.static.GetOnlineSubsystem();
	if(OnlineSub != None)
	{
		// Grab the game interface to verify the subsystem supports it
		GameInterface = OnlineSub.GameInterface;
		if (GameInterface != None)
		{
			// Clear the delegate we set.
			GameInterface.ClearCreateOnlineGameCompleteDelegate(OnGameCreated);

			// If we were successful, then travel.
			if(bWasSuccessful)
			{
				// Setup server options based on server type.
				LocalGameSettings = SettingsDataStore.GetCurrentGameSettings();

				//LocalGameSettings.bIsDedicated = StringListDataStore.GetCurrentValueIndex('DedicatedServer') == 1;

				// append options from the OnlineGameSettings class
				LocalGameSettings.BuildURL(TravelURL);

				// Append Extra Common Options
				//TravelURL $= GetCommonOptionsURL();

				Registry.GetData("SelectedMap", OutStringValue);
				TravelURL = "open MapaDeTeste?CharNum="$CharIndex$"?TeamNum="$TeamIndex$"?listen=true"$"?bIsLanMatch=true";

				// Do the server travel.
				ConsoleCommand(TravelURL);
			}
		}
	}
}
 
function OnCreateOnlineGameComplete(name SessionName,bool bWasSuccessful)
{
    local string URL;
    if(!bWasSuccessful)
    {
        ClearCreateOnlineGameDelegates();
        return;
    }

    URL = "open MapaDeTeste?CharNum="$CharIndex$"?TeamNum="$TeamIndex$"?listen=true"$"?bIsLanMatch=true";
    ConsoleCommand(URL);

    ClearCreateOnlineGameDelegates();
}
 
function ClearJoinOnlineDelegates()
{
    OnlineSub.GameInterface.ClearJoinOnlineGameCompleteDelegate(OnInviteJoinComplete);
}
 
function OnJoinOnlineGameComplete(name SessionName,bool bWasSuccessful)
{
    local string URL;

	SearchSettings.bIsLanQuery = true;
	//SearchSettings.Results;

	//WorldInfo.Game.Broadcast(self, SearchSetting.Results[0]);

    if(!bWasSuccessful || OnlineSub == none || OnlineSub.GameInterface == none)
    {
        ClearJoinOnlineDelegates();
        return;
    }

    if(OnlineSub.GameInterface.GetResolvedConnectString(SessionName, URL))
    {
        // allow game to override
        URL = ModifyClientURL(URL);

        `Log("Resulting url is ("$URL$")");
        // Open a network connection to it
        ClientTravel(URL, TRAVEL_Absolute);
    }
    ClearJoinOnlineDelegates();
}
 
function OpenNativeMatchmakingUI()
{
    //local OnlineSuppliedUIInterface OSI;

    if(OnlineSub == none)
        OnlineSub = class'GameEngine'.static.GetOnlineSubsystem();

    if(OnlineSub == none)
        return;

    if(OnlineSub.GameInterface == none)
        return;

    //OSI = OnlineSuppliedUIInterface(OnlineSub.GetNamedInterface('SuppliedUI'));
   
    //if(OSI == none)
    //        return;

    OnlineSub.GameInterface.AddCreateOnlineGameCompleteDelegate(OnCreateOnlineGameComplete);
    OnlineSub.GameInterface.AddJoinOnlineGameCompleteDelegate(OnInviteJoinComplete);

	//OnlineSub.GameInterface.FindOnlineGames
	//OSI.ShowMatchmakingUI(0,SearchSettings, GameSettings);

	//OnCreateOnlineGameComplete('Game', true);

    WorldInfo.Game.Broadcast(self, "Misteltein!");
}

DefaultProperties
{
	RedPawnClasses(0)=SSPawn'Archetypes.Pawns.SSPawn_1'
	RedPawnClasses(1)=SSPawn'Archetypes.Pawns.SSPawn_2'
	RedPawnClasses(2)=SSPawn'Archetypes.Pawns.SSPawn_3'
	RedPawnClasses(3)=SSPawn'Archetypes.Pawns.SSPawn_4'
	RedPawnClasses(4)=SSPawn'Archetypes.Pawns.SSPawn_5'
	BluePawnClasses(0)=SSPawn'Archetypes.Pawns.SSPawn_A'
	BluePawnClasses(1)=SSPawn'Archetypes.Pawns.SSPawn_B'
	BluePawnClasses(2)=SSPawn'Archetypes.Pawns.SSPawn_C'
	BluePawnClasses(3)=SSPawn'Archetypes.Pawns.SSPawn_D'
	BluePawnClasses(4)=SSPawn'Archetypes.Pawns.SSPawn_E'
}
