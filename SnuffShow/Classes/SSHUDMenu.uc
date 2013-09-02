class SSHUDMenu extends HUD;

var SSGFxMenuteam HudMovie;
var() bool DrawMessages;

singular event Destroyed() 
{
	if (HudMovie != none) 
	{
		HudMovie.Close(true);
		HudMovie = none;
	}

	//super.Destroy();
}

simulated function PostBeginPlay()
{

	super.PostBeginPlay();
	HudMovie = new class'SSGFxMenuteam';
	HudMovie.SetTimingMode(TM_Real);
	HudMovie.Init(class'Engine'.static.GetEngine().GamePlayers[HudMovie.LocalPlayerOwnerIndex]);
}


event PostRender()
{
	Super.PostRender();

	//if(!SSPlayerControllerMenu(PlayerOwner).bTeamSelected)
	//	RenderSelectTeams(2.0);

	//if(SSPlayerControllerMenu(PlayerOwner).bTeamSelected)
	//	RenderSelectClasses(2.0);
}

function RenderSelectTeams(float TextScale)
{
	local SSPlayerControllerMenu PC;

	PC = SSPlayerControllerMenu(PlayerOwner);

	Canvas.SetPos(0, 0);
	Canvas.DrawColor = PC.CurrentTeamIndex == 0 ? MakeColor(255,0,0,255) : MakeColor(255,255,0,255);
	Canvas.DrawText("Team:Red",,TextScale,TextScale);

	Canvas.SetPos(0, 20 * TextScale);
	Canvas.DrawColor = PC.CurrentTeamIndex == 1 ? MakeColor(0,0,255,255) : MakeColor(255,255,0,255);
	Canvas.DrawText("Team:Blue",,TextScale,TextScale);
}

function RenderSelectClasses(float TextScale)
{
	local SSPlayerControllerMenu PC;
	local Color SelectColor;
	local byte TeamIndex;

	PC = SSPlayerControllerMenu(PlayerOwner);
	TeamIndex = PC.CurrentTeamIndex;
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

function SetVisible(bool bNewVisible)
{
	bShowHUD = bNewVisible;
	bShowHUD = true;
}

DefaultProperties
{
	DrawMessages=true
}
