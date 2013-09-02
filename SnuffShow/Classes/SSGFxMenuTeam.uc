class SSGFxMenuTeam extends GFxMoviePlayer;

var GFxObject MCHostJoin, MCTimes, MCIntegrantesVermelho, MCIntegrantesAzul, MCJogarVoltar;
var SSPlayerControllerMenu PC;

var string CharHUD, TeamHUD, IP;
var int Time, Char;
var bool bHost;

function Init(optional LocalPlayer Player)
{
	super.Init(Player);
	Start();
	Advance(0.f);
	
	MCHostJoin = GetVariableObject("_root.BTHostJoin");
	MCTimes = GetVariableObject("_root.BTTimes");
	MCIntegrantesVermelho = GetVariableObject("_root.BTIntegrantesVermelho");
	MCIntegrantesAzul = GetVariableObject("_root.BTIntegrantesAzul");
	MCJogarVoltar = GetVariableObject("_root.BTJogarVoltar");

	PC = SSPlayerControllerMenu(GetPC());
}

function SetIP(string Ipe)
{
	if(Ipe != "")
		IP = Ipe;
}

function SetTeam(int Team)
{
	TeamHUD = string(Team);
	Time = Team;
}

function SetChar(int Num)
{
	if(Time== 0)
	{
		CharHUD = string(Num);
	}
	else if(Time == 1)
	{   
		CharHUD = string(Num);
	}
}

function StartMatchHost()
{
	ConsoleCommand("open MapaDeTeste?CharNum="$CharHUD$"?TeamNum="$TeamHUD$"?listen=true"$"?dedicated");
}

function StartMatchJoin()
{
	ConsoleCommand("open"@IP@"?CharNum="$CharHUD$"?TeamNum="$TeamHUD);
}

DefaultProperties
{
	bDisplayWithHudOff=false
	MovieInfo=SwfMovie'HUDMenus.MenuPrincipal'
	IP="127.0.0.1"
}
