class SSHighScore extends GFxMoviePlayer;

var GFxObject RedTeam, BlueTeam, MinutoTxt, SegundoTxt, Root;
var SSPlayerController PC;
var SSGameReplicationInfo SGRI;

var int Minuto, Segundo;

function Init(optional LocalPlayer player)
{
	super.Init(player);

	Start();
	Advance(0.f);
	Root = GetVariableObject("_root");
	RedTeam = GetVariableObject("_root.RedTeamTxt");
	BlueTeam = GetVariableObject("_root.BlueTeamTxt");
	MinutoTxt = GetVariableObject("_root.Minuto");
	SegundoTxt = GetVariableObject("_root.Segundo");

	PC = SSPlayerController(GetPC());
	SGRI = SSGameReplicationInfo(PC.WorldInfo.GRI);
}

function TickHUD()
{
	local string TeamScoreCount, EnemyScoreCount;

	Minuto = SGRI.RemainingTime / 60;
	Segundo = SGRI.RemainingTime % 60;

	TeamScoreCount = string(SSTeamInfo(SGRI.Teams[0]).ScoreTeam);
	EnemyScoreCount = string(SSTeamInfo(SGRI.Teams[1]).ScoreTeam);

	TeamScoreCount = Left("00000", 5 - Len(TeamScoreCount))$TeamScoreCount;
	EnemyScoreCount = Left("00000", 5 - Len(EnemyScoreCount))$EnemyScoreCount;

	MinutoTxt.SetText(Minuto);
	if(Segundo < 10)
		SegundoTxt.SetText("0"$Segundo);
	else
		SegundoTxt.SetText(Segundo);


	RedTeam.SetText(TeamScoreCount);
	BlueTeam.SetText(EnemyScoreCount);

	if(SGRI.RemainingTime == 0)
	{
		if(SSTeamInfo(SGRI.Teams[0]).ScoreTeam < SSTeamInfo(SGRI.Teams[1]).ScoreTeam)
			Root.GotoAndStopI(2);

		else
			Root.GotoAndStopI(3);
	}

	//PC.WorldInfo.Game.Broadcast(PC, SSTeamInfo(SGRI.Teams[0]));
}

DefaultProperties
{
	bDisplayWithHudOff=true
	MovieInfo=SwfMovie'HUDMenus.HighScore'
}
