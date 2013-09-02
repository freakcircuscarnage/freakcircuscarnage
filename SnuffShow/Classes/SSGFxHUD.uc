class SSGFxHUD extends GFxMoviePlayer;

var GFxObject Vida, StaminaMC, TeamScore, EnemyScore, Municao, ReservaMun, MinutoTxt, SegundoTxt, StatusMC, ScoreMC, 
	Root, WeaponsIconMC, DropWeapMC, ScorePlayersMC;
var SSPlayerController PC;
var SSGameReplicationInfo SGRI;

var float Estamina;
var int Minuto, Segundo;

var SSGFxMinimap Minimap;

var SSHUD theHUD;

//var array<GFxObject> KLMessages;

//simulated function CreateKLMessage(string Message)
//{
//	KLMessages.AddItem(Root.GetObject("LogStage").AttachMovie("KLMessage", 
//		"KLM"$string(KLMessages.Length)));

//	KLMessages[KLMessages.Length -1].SetPosition(0, 300 - (KLMessages.Length * 50));
//	KLMessages[KLMessages.Length -1].GetObject("KillLogMessage").SetText(Message);
//	//SGRI.bNewMessage = false;

//	//ActionScriptVoid("resetLayout");

//	//PC.WorldInfo.Game.Broadcast(PC, KLMessages[KLMessages.Length -1]);
//}

function MinimapActivate(SSGFxMinimap mc)
{
	Minimap = mc;
	mc.Init();
}

//function DestroyHitDirMC(GFxObject Icon)
//{
//	SSPawn(GetPC().Pawn).CheckHitDirName(Icon);
//}

function Init(optional LocalPlayer player)
{
	local SSMapInfo SSMapInfo;
	super.Init(player);

	Start();
	Advance(0.f);
	Vida = GetVariableObject("_root.VidaTxt");
	StaminaMC = GetVariableObject("_root.RBDisplay.Stamina");
	TeamScore = GetVariableObject("_root.TopDisplay.TeamScoreTxt");
	EnemyScore =  GetVariableObject("_root.TopDisplay.EnemyScoreTxt");
	Municao = GetVariableObject("_root.RBDisplay.MunicaoTxt");
	ReservaMun = GetVariableObject("_root.RBDisplay.MunReservaTxt");
	MinutoTxt = GetVariableObject("_root.TopDisplay.Minuto");
	SegundoTxt = GetVariableObject("_root.TopDisplay.Segundo");
	StatusMC = GetVariableObject("_root.RBDisplay.StatusMC");
	ScoreMC = GetVariableObject("_root.TopDisplay.ScoreMC");
	Root = GetVariableObject("_root");
	WeaponsIconMC = GetVariableObject("_root.RBDisplay.WeaponsIcon");
	DropWeapMC = GetVariableObject("_root.DropWeapon");
	ScorePlayersMC = GetVariableObject("_root.ScorePlayers");

	Root.GetObject("MinimapMC").SetVisible(false);
	Vida.SetVisible(false);
	DropWeapMC.SetVisible(false);
	ScorePlayersMC.SetVisible(false);

	SSMapInfo = SSMapInfo(GetPC().WorldInfo.GetMapInfo());

	Root.GetObject("TopDisplay").SetFloat("_alpha", SSMapInfo.MinimapOpacity);
	Root.GetObject("RBDisplay").SetFloat("_alpha", SSMapInfo.MinimapOpacity);
	Vida.SetFloat("_alpha", SSMapInfo.MinimapOpacity);

	PC = SSPlayerController(GetPC());
	SGRI = SSGameReplicationInfo(PC.WorldInfo.GRI);
}

function CheckPlayerScore(GFxObject MC, string PName, int PScore, int PKills, int PDeaths, SSPlayerController PCont)
{
	if(PName != "")
	{
		MC.GetObject("NameCharTxt").SetText(PName);
		MC.GetObject("PontosTxt").SetText(PScore);
		MC.GetObject("KillsTxt").SetText(PKills);
		MC.GetObject("DeathsTxt").SetText(PDeaths);

		if(PCont == PC)
		{
			MC.SetFloat("_xscale", 80);
			MC.SetFloat("_yscale", 80);
		}
		else
		{
			MC.SetFloat("_xscale", 60);
			MC.SetFloat("_yscale", 60);
		}
	}
}

function DisableScores()
{
	ScorePlayersMC.GetObject("RedCharScore1").SetVisible(false);
	ScorePlayersMC.GetObject("RedCharScore2").SetVisible(false);
	ScorePlayersMC.GetObject("RedCharScore3").SetVisible(false);
	ScorePlayersMC.GetObject("RedCharScore4").SetVisible(false);
	ScorePlayersMC.GetObject("RedCharScore5").SetVisible(false);
	ScorePlayersMC.GetObject("RedCharScore6").SetVisible(false);
	ScorePlayersMC.GetObject("BlueCharScore1").SetVisible(false);
	ScorePlayersMC.GetObject("BlueCharScore2").SetVisible(false);
	ScorePlayersMC.GetObject("BlueCharScore3").SetVisible(false);
	ScorePlayersMC.GetObject("BlueCharScore4").SetVisible(false);
	ScorePlayersMC.GetObject("BlueCharScore5").SetVisible(false);
	ScorePlayersMC.GetObject("BlueCharScore6").SetVisible(false);
}

function SetRedPlayerScore(array<Pawn> SPC)
{
	local Pawn GreatValue;
	local int i, j, k;

	for(i = 0; i < SPC.Length; i++)
	{
		for(j = 0; j < SPC.Length; j++)
		{
			if(SSPlayerReplicationInfo(SPC[i].PlayerReplicationInfo).Frags > SSPlayerReplicationInfo(SPC[j].PlayerReplicationInfo).Frags || 
				(SSPlayerReplicationInfo(SPC[i].PlayerReplicationInfo).Frags == SSPlayerReplicationInfo(SPC[j].PlayerReplicationInfo).Frags &&
				SPC[i].PlayerReplicationInfo.Score > SPC[j].PlayerReplicationInfo.Score))
			{
				GreatValue = SPC[i];
				SPC[i] = SPC[j];
				SPC[j] = GreatValue;
			}
		}
	}

	for(k = 0; k < SPC.Length; k++)
	{
		ScorePlayersMC.GetObject("RedCharScore"$k+1).SetVisible(true);
		ScorePlayersMC.GetObject("RedCharScore"$k+1).GetObject("NameCharTxt").SetText(SPC[k].PlayerReplicationInfo.PlayerName);
		ScorePlayersMC.GetObject("RedCharScore"$k+1).GetObject("PontosTxt").SetText(SPC[k].PlayerReplicationInfo.Score);
		ScorePlayersMC.GetObject("RedCharScore"$k+1).GetObject("KillsTxt").SetText(SSPlayerReplicationInfo(SPC[k].PlayerReplicationInfo).Frags);
		ScorePlayersMC.GetObject("RedCharScore"$k+1).GetObject("DeathsTxt").SetText(SPC[k].PlayerReplicationInfo.Deaths);

		if(SPC[k].Controller == PC)
		{
			ScorePlayersMC.GetObject("RedCharScore"$k+1).SetFloat("_xscale", 80);
			ScorePlayersMC.GetObject("RedCharScore"$k+1).SetFloat("_yscale", 80);
		}
		else
		{
			ScorePlayersMC.GetObject("RedCharScore"$k+1).SetFloat("_xscale", 60);
			ScorePlayersMC.GetObject("RedCharScore"$k+1).SetFloat("_yscale", 60);
		}
	}
}

function SetBluePlayerScore(array<Pawn> SPC)
{
	local Pawn GreatValue;
	local int i, j, k;

	for(i = 0; i < SPC.Length; i++)
	{
		for(j = 0; j < SPC.Length; j++)
		{
			if(SPC[i].PlayerReplicationInfo.Score > SPC[j].PlayerReplicationInfo.Score)
			{
				GreatValue = SPC[i];
				SPC[i] = SPC[j];
				SPC[j] = GreatValue;
			}
		}
	}

	for(k = 0; k < SPC.Length; k++)
	{
		ScorePlayersMC.GetObject("BlueCharScore"$k+1).SetVisible(true);
		ScorePlayersMC.GetObject("BlueCharScore"$k+1).GetObject("NameCharTxt").SetText(SPC[k].PlayerReplicationInfo.PlayerName);
		ScorePlayersMC.GetObject("BlueCharScore"$k+1).GetObject("PontosTxt").SetText(SPC[k].PlayerReplicationInfo.Score);
		ScorePlayersMC.GetObject("BlueCharScore"$k+1).GetObject("KillsTxt").SetText(SSPlayerReplicationInfo(SPC[k].PlayerReplicationInfo).Frags);
		ScorePlayersMC.GetObject("BlueCharScore"$k+1).GetObject("DeathsTxt").SetText(SPC[k].PlayerReplicationInfo.Deaths);

		if(SPC[k].Controller == PC)
		{
			ScorePlayersMC.GetObject("BlueCharScore"$k+1).SetFloat("_xscale", 80);
			ScorePlayersMC.GetObject("BlueCharScore"$k+1).SetFloat("_yscale", 80);
		}
		else
		{
			ScorePlayersMC.GetObject("BlueCharScore"$k+1).SetFloat("_xscale", 60);
			ScorePlayersMC.GetObject("BlueCharScore"$k+1).SetFloat("_yscale", 60);
		}
	}
}

function TickHUD()
{
	local int TeamEnemy, WeapIconFrame;
	local string TeamScoreCount, EnemyScoreCount;

	if(theHUD.bShowingScore)
	{
		//Kills.SetText(SSPlayerReplicationInfo(PC.PlayerReplicationInfo).Frags);
		//Deaths.SetText(PC.PlayerReplicationInfo.Deaths);
		//Pontos.SetText(int(PC.PlayerReplicationInfo.Score));
		////NameChar.SetText(SGRI.RFistPlace.ScorePlayer@SGRI.RSecondPlace.ScorePlayer@SGRI.RThirdPlace.ScorePlayer@SGRI.RFourthPlace.ScorePlayer
		////	@SGRI.RFifthPlace.ScorePlayer@SGRI.RSixthPlace.ScorePlayer);
		//NameChar.SetText(PC.PlayerReplicationInfo.PlayerName);


		////////////////////////////////////////////////////////////// Red Score /////////////////////////////////////////////////////////////////////
		//CheckPlayerScore(ScorePlayersMC.GetObject("RedCharScore1"), SGRI.RFistPlace.NamePlayer, SGRI.RFistPlace.ScorePlayer, SGRI.RFistPlace.KillsPlayer, 
		//	SGRI.RFistPlace.DeathsPlayer, SGRI.RFistPlace.CurrentPlayer);
		
		//CheckPlayerScore(ScorePlayersMC.GetObject("RedCharScore2"), SGRI.RSecondPlace.NamePlayer, SGRI.RSecondPlace.ScorePlayer, SGRI.RSecondPlace.KillsPlayer, 
		//	SGRI.RSecondPlace.DeathsPlayer, SGRI.RSecondPlace.CurrentPlayer);
		
		//CheckPlayerScore(ScorePlayersMC.GetObject("RedCharScore3"), SGRI.RThirdPlace.NamePlayer, SGRI.RThirdPlace.ScorePlayer, SGRI.RThirdPlace.KillsPlayer, 
		//	SGRI.RThirdPlace.DeathsPlayer, SGRI.RThirdPlace.CurrentPlayer);

		//CheckPlayerScore(ScorePlayersMC.GetObject("RedCharScore4"), SGRI.RFourthPlace.NamePlayer, SGRI.RFourthPlace.ScorePlayer, SGRI.RFourthPlace.KillsPlayer, 
		//	SGRI.RFourthPlace.DeathsPlayer, SGRI.RFourthPlace.CurrentPlayer);

		//CheckPlayerScore(ScorePlayersMC.GetObject("RedCharScore5"), SGRI.RFifthPlace.NamePlayer, SGRI.RFifthPlace.ScorePlayer, SGRI.RFifthPlace.KillsPlayer, 
		//	SGRI.RFifthPlace.DeathsPlayer, SGRI.RFifthPlace.CurrentPlayer);

		//CheckPlayerScore(ScorePlayersMC.GetObject("RedCharScore6"), SGRI.RSixthPlace.NamePlayer, SGRI.RSixthPlace.ScorePlayer, SGRI.RSixthPlace.KillsPlayer, 
		//	SGRI.RSixthPlace.DeathsPlayer, SGRI.RSixthPlace.CurrentPlayer);

		////////////////////////////////////////////////////////// Blue Score /////////////////////////////////////////////////////////////////////////
		//CheckPlayerScore(ScorePlayersMC.GetObject("BlueCharScore1"), SGRI.BFistPlace.NamePlayer, SGRI.BFistPlace.ScorePlayer, SGRI.BFistPlace.KillsPlayer, 
		//	SGRI.BFistPlace.DeathsPlayer, SGRI.BFistPlace.CurrentPlayer);
		
		//CheckPlayerScore(ScorePlayersMC.GetObject("BlueCharScore2"), SGRI.BSecondPlace.NamePlayer, SGRI.BSecondPlace.ScorePlayer, SGRI.BSecondPlace.KillsPlayer, 
		//	SGRI.BSecondPlace.DeathsPlayer, SGRI.BSecondPlace.CurrentPlayer);
		
		//CheckPlayerScore(ScorePlayersMC.GetObject("BlueCharScore3"), SGRI.BThirdPlace.NamePlayer, SGRI.BThirdPlace.ScorePlayer, SGRI.BThirdPlace.KillsPlayer, 
		//	SGRI.BThirdPlace.DeathsPlayer, SGRI.BThirdPlace.CurrentPlayer);

		//CheckPlayerScore(ScorePlayersMC.GetObject("BlueCharScore4"), SGRI.BFourthPlace.NamePlayer, SGRI.BFourthPlace.ScorePlayer, SGRI.BFourthPlace.KillsPlayer, 
		//	SGRI.BFourthPlace.DeathsPlayer, SGRI.BFourthPlace.CurrentPlayer);

		//CheckPlayerScore(ScorePlayersMC.GetObject("BlueCharScore5"), SGRI.BFifthPlace.NamePlayer, SGRI.BFifthPlace.ScorePlayer, SGRI.BFifthPlace.KillsPlayer, 
		//	SGRI.BFifthPlace.DeathsPlayer, SGRI.BFifthPlace.CurrentPlayer);

		//CheckPlayerScore(ScorePlayersMC.GetObject("BlueCharScore6"), SGRI.BSixthPlace.NamePlayer, SGRI.BSixthPlace.ScorePlayer, SGRI.BSixthPlace.KillsPlayer, 
		//	SGRI.BSixthPlace.DeathsPlayer, SGRI.BSixthPlace.CurrentPlayer);
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	}

	else
	{
		Estamina = PC.Stamina * 3;

		Minuto = SGRI.RemainingTime / 60;
		Segundo = SGRI.RemainingTime % 60;

		//PC.WorldInfo.Game.Broadcast(PC, PC.WorldInfo.GRI.RemainingTime);

		TeamEnemy = PC.PlayerReplicationInfo.Team.TeamIndex == 0? 1: 0;
		TeamScoreCount = string(SSTeamInfo(PC.PlayerReplicationInfo.Team).ScoreTeam);
		EnemyScoreCount = string(SSTeamInfo(SGRI.Teams[TeamEnemy]).ScoreTeam);

		TeamScoreCount = Left("00000", 5 - Len(TeamScoreCount))$TeamScoreCount;
		EnemyScoreCount = Left("00000", 5 - Len(EnemyScoreCount))$EnemyScoreCount;

		StaminaMC.SetVisible(true);
		StaminaMC.GotoAndStopI(Estamina);
		
		Vida.SetText(PC.Pawn.Health);
		TeamScore.SetText(TeamScoreCount);
		EnemyScore.SetText(EnemyScoreCount);
		Municao.SetText(SSWeapBase(PC.Pawn.Weapon).CurrentAmmoCount);
		ReservaMun.SetText(SSWeapBase(PC.Pawn.Weapon).ReserveAmmo);
		MinutoTxt.SetText(Minuto);
		if(Segundo < 10)
			SegundoTxt.SetText("0"$Segundo);
		else
			SegundoTxt.SetText(Segundo);


		WeapIconFrame = WeaponsIconMC.GetInt("_currentframe");

		if(SSWeapBase(PC.Pawn.Weapon).IconNumber != WeapIconFrame)
			WeaponsIconMC.GotoAndStopI(SSWeapBase(PC.Pawn.Weapon).IconNumber);
	}

	//if(SGRI.KillMessages != "" && SGRI.bNewMessage)
	//{
	//	CreateKLMessage();
	//}

	//PC.WorldInfo.Game.Broadcast(PC, SSGameReplicationInfo(PC.WorldInfo.GRI).KillMessages);

	//if(TeamEnemy == 0)
	//{
	//	StatusMC.GotoAndStopI(2);
	//	ScoreMC.GotoAndStopI(2);
	//}
	//else
	//{
	//	StatusMC.GotoAndStopI(1);
	//	ScoreMC.GotoAndStopI(1);
	//}
}

DefaultProperties
{
	bDisplayWithHudOff=false
	MovieInfo=SwfMovie'HUDMenus.HUD'
}
