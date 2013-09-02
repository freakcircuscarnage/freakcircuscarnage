class SSGameReplicationInfo extends GameReplicationInfo;

struct PlayersScore
{
	var string NamePlayer;
	var int ScorePlayer, KillsPlayer, DeathsPlayer;
	var SSPlayerController CurrentPlayer;

	structdefaultproperties
	{
		ScorePlayer=-1
	}
};

//var PlayersScore PSRed[6], PSBlue[6];

var PlayersScore RFistPlace, RSecondPlace, RThirdPlace, RFourthPlace, RFifthPlace, RSixthPlace;
var PlayersScore BFistPlace, BSecondPlace, BThirdPlace, BFourthPlace, BFifthPlace, BSixthPlace;

//var string KillMessages;
var int KillMessagesCount;
var array<GFxObject> KLMessages;
var array<ASValue> args;
//var bool bNewMessage;

replication
{
	if (bNetDirty)
		/*KillMessages,*/ KillMessagesCount, RFistPlace, RSecondPlace, RThirdPlace, RFourthPlace, RFifthPlace, RSixthPlace,
			BFistPlace, BSecondPlace, BThirdPlace, BFourthPlace, BFifthPlace, BSixthPlace;
}

simulated function DestroyKLMessage()
{
	local int i;

	//WorldInfo.Game.Broadcast(self, KLMessages.length@SSGameReplicationInfo(WorldInfo.GRI).KillMessagesCount);

	for(i = 0; i < KLMessages.Length; i++)
	{
		KLMessages[i].Invoke("removeMovieClip", args);
	}

	KLMessages.Remove(0, KLMessages.Length);
	KillMessagesCount = 0;
}

simulated event Timer()
{
	super.Timer();
}

function SetRedPlayersScore(string NameP, int ScoreP, int KillsP, int DeathsP, SSPlayerController P)
{
	local PlayersScore /*ChangePS,*/ PS;

	PS.NamePlayer = NameP;
	PS.ScorePlayer = ScoreP;
	PS.KillsPlayer = KillsP;
	PS.DeathsPlayer = DeathsP;
	PS.CurrentPlayer = P;

	if(PS.CurrentPlayer == RFistPlace.CurrentPlayer)
	{
		PS.ScorePlayer += RFistPlace.ScorePlayer;
		RFistPlace = RSecondPlace;
		RSecondPlace = RThirdPlace;
		RThirdPlace = RFourthPlace;
		RFourthPlace = RFifthPlace;
		RFifthPlace = RSixthPlace;
		RSixthPlace.NamePlayer = "";
		RSixthPlace.ScorePlayer = 0;
		RSixthPlace.KillsPlayer = 0;
		RSixthPlace.DeathsPlayer = 0;
		RSixthPlace.CurrentPlayer = none;
	}

	else if(PS.CurrentPlayer == RSecondPlace.CurrentPlayer)
	{
		PS.ScorePlayer += RSecondPlace.ScorePlayer;
		RSecondPlace = RThirdPlace;
		RThirdPlace = RFourthPlace;
		RFourthPlace = RFifthPlace;
		RFifthPlace = RSixthPlace;
		RSixthPlace.NamePlayer = "";
		RSixthPlace.ScorePlayer = 0;
		RSixthPlace.KillsPlayer = 0;
		RSixthPlace.DeathsPlayer = 0;
		RSixthPlace.CurrentPlayer = none;
	}

	else if(PS.CurrentPlayer == RThirdPlace.CurrentPlayer)
	{
		PS.ScorePlayer += RThirdPlace.ScorePlayer;
		RThirdPlace = RFourthPlace;
		RFourthPlace = RFifthPlace;
		RFifthPlace = RSixthPlace;
		RSixthPlace.NamePlayer = "";
		RSixthPlace.ScorePlayer = 0;
		RSixthPlace.KillsPlayer = 0;
		RSixthPlace.DeathsPlayer = 0;
		RSixthPlace.CurrentPlayer = none;
	}

	else if(PS.CurrentPlayer == RFourthPlace.CurrentPlayer)
	{
		PS.ScorePlayer += RFourthPlace.ScorePlayer;
		RFourthPlace = RFifthPlace;
		RFifthPlace = RSixthPlace;
		RSixthPlace.NamePlayer = "";
		RSixthPlace.ScorePlayer = 0;
		RSixthPlace.KillsPlayer = 0;
		RSixthPlace.DeathsPlayer = 0;
		RSixthPlace.CurrentPlayer = none;
	}

	else if(PS.CurrentPlayer == RFifthPlace.CurrentPlayer)
	{
		PS.ScorePlayer += RFistPlace.ScorePlayer;
		RFifthPlace = RSixthPlace;
		RSixthPlace.NamePlayer = "";
		RSixthPlace.ScorePlayer = 0;
		RSixthPlace.KillsPlayer = 0;
		RSixthPlace.DeathsPlayer = 0;
		RSixthPlace.CurrentPlayer = none;
	}

	else if(PS.CurrentPlayer == RSixthPlace.CurrentPlayer)
	{
		PS.ScorePlayer += RSixthPlace.ScorePlayer;
		RSixthPlace.NamePlayer = "";
		RSixthPlace.ScorePlayer = 0;
		RSixthPlace.KillsPlayer = 0;
		RSixthPlace.DeathsPlayer = 0;
		RSixthPlace.CurrentPlayer = none;
	}



	if(PS.ScorePlayer > RFistPlace.ScorePlayer)
	{
		if(RFistPlace.ScorePlayer != 0)
		{
			RSixthPlace = RFifthPlace;
			RFifthPlace = RFourthPlace;
			RFourthPlace = RThirdPlace;
			RThirdPlace = RSecondPlace;
			RSecondPlace = RFistPlace;
		}

		RFistPlace = PS;
	}

	else if(PS.ScorePlayer > RSecondPlace.ScorePlayer && PS.ScorePlayer <= RFistPlace.ScorePlayer)
	{
		if(RSecondPlace.ScorePlayer != 0)
		{
			RSixthPlace = RFifthPlace;
			RFifthPlace = RFourthPlace;
			RFourthPlace = RThirdPlace;
			RThirdPlace = RSecondPlace;
		}

		RSecondPlace = PS;
	}

	else if(PS.ScorePlayer > RThirdPlace.ScorePlayer && PS.ScorePlayer <= RSecondPlace.ScorePlayer)
	{
		if(RThirdPlace.ScorePlayer != 0)
		{
			RSixthPlace = RFifthPlace;
			RFifthPlace = RFourthPlace;
			RFourthPlace = RThirdPlace;
		}

		RThirdPlace = PS;
	}

	else if(PS.ScorePlayer > RFourthPlace.ScorePlayer && PS.ScorePlayer <= RThirdPlace.ScorePlayer)
	{
		if(RFourthPlace.ScorePlayer != 0)
		{
			RSixthPlace = RFifthPlace;
			RFifthPlace = RFourthPlace;
		}

		RFourthPlace = PS;
	}

	else if(PS.ScorePlayer > RFifthPlace.ScorePlayer && PS.ScorePlayer <= RFourthPlace.ScorePlayer)
	{
		if(RFifthPlace.ScorePlayer != 0)
		{
			RSixthPlace = RFifthPlace;
		}

		RFifthPlace = PS;
	}

	else if(PS.ScorePlayer > RSixthPlace.ScorePlayer && PS.ScorePlayer <= RFifthPlace.ScorePlayer)
	{
		RSixthPlace = PS;
	}
}

function SetBluePlayersScore(string NameP, int ScoreP, int KillsP, int DeathsP, SSPlayerController P)
{
	local PlayersScore /*ChangePS,*/ PS;

	PS.NamePlayer = NameP;
	PS.ScorePlayer = ScoreP;
	PS.KillsPlayer = KillsP;
	PS.DeathsPlayer = DeathsP;
	PS.CurrentPlayer = P;

	if(PS.CurrentPlayer == BFistPlace.CurrentPlayer)
	{
		PS.ScorePlayer += BFistPlace.ScorePlayer;
		BFistPlace = BSecondPlace;
		BSecondPlace = BThirdPlace;
		BThirdPlace = BFourthPlace;
		BFourthPlace = BFifthPlace;
		BFifthPlace = BSixthPlace;
		BSixthPlace.NamePlayer = "";
		BSixthPlace.ScorePlayer = 0;
		BSixthPlace.KillsPlayer = 0;
		BSixthPlace.DeathsPlayer = 0;
		BSixthPlace.CurrentPlayer = none;
	}

	else if(PS.CurrentPlayer == BSecondPlace.CurrentPlayer)
	{
		PS.ScorePlayer += BSecondPlace.ScorePlayer;
		BSecondPlace = BThirdPlace;
		BThirdPlace = BFourthPlace;
		BFourthPlace = BFifthPlace;
		BFifthPlace = BSixthPlace;
		BSixthPlace.NamePlayer = "";
		BSixthPlace.ScorePlayer = 0;
		BSixthPlace.KillsPlayer = 0;
		BSixthPlace.DeathsPlayer = 0;
		BSixthPlace.CurrentPlayer = none;
	}

	else if(PS.CurrentPlayer == BThirdPlace.CurrentPlayer)
	{
		PS.ScorePlayer += BThirdPlace.ScorePlayer;
		BThirdPlace = BFourthPlace;
		BFourthPlace = BFifthPlace;
		BFifthPlace = BSixthPlace;
		BSixthPlace.NamePlayer = "";
		BSixthPlace.ScorePlayer = 0;
		BSixthPlace.KillsPlayer = 0;
		BSixthPlace.DeathsPlayer = 0;
		BSixthPlace.CurrentPlayer = none;
	}

	else if(PS.CurrentPlayer == BFourthPlace.CurrentPlayer)
	{
		PS.ScorePlayer += BFourthPlace.ScorePlayer;
		BFourthPlace = BFifthPlace;
		BFifthPlace = BSixthPlace;
		BSixthPlace.NamePlayer = "";
		BSixthPlace.ScorePlayer = 0;
		BSixthPlace.KillsPlayer = 0;
		BSixthPlace.DeathsPlayer = 0;
		BSixthPlace.CurrentPlayer = none;
	}

	else if(PS.CurrentPlayer == BFifthPlace.CurrentPlayer)
	{
		PS.ScorePlayer += BFifthPlace.ScorePlayer;
		BFifthPlace = BSixthPlace;
		BSixthPlace.NamePlayer = "";
		BSixthPlace.ScorePlayer = 0;
		BSixthPlace.KillsPlayer = 0;
		BSixthPlace.DeathsPlayer = 0;
		BSixthPlace.CurrentPlayer = none;
	}

	else if(PS.CurrentPlayer == BSixthPlace.CurrentPlayer)
	{
		PS.ScorePlayer += BSixthPlace.ScorePlayer;
		BSixthPlace.NamePlayer = "";
		BSixthPlace.ScorePlayer = 0;
		BSixthPlace.KillsPlayer = 0;
		BSixthPlace.DeathsPlayer = 0;
		BSixthPlace.CurrentPlayer = none;
	}



	if(PS.ScorePlayer > BFistPlace.ScorePlayer)
	{
		if(BFistPlace.ScorePlayer != 0)
		{
			BSixthPlace = BFifthPlace;
			BFifthPlace = BFourthPlace;
			BFourthPlace = BThirdPlace;
			BThirdPlace = BSecondPlace;
			BSecondPlace = BFistPlace;
		}

		BFistPlace = PS;
	}

	else if(PS.ScorePlayer > BSecondPlace.ScorePlayer && PS.ScorePlayer <= BFistPlace.ScorePlayer)
	{
		if(BSecondPlace.ScorePlayer != 0)
		{
			BSixthPlace = BFifthPlace;
			BFifthPlace = BFourthPlace;
			BFourthPlace = BThirdPlace;
			BThirdPlace = BSecondPlace;
		}

		BSecondPlace = PS;
	}

	else if(PS.ScorePlayer > BThirdPlace.ScorePlayer && PS.ScorePlayer <= BSecondPlace.ScorePlayer)
	{
		if(BThirdPlace.ScorePlayer != 0)
		{
			BSixthPlace = BFifthPlace;
			BFifthPlace = BFourthPlace;
			BFourthPlace = BThirdPlace;
		}

		BThirdPlace = PS;
	}

	else if(PS.ScorePlayer > BFourthPlace.ScorePlayer && PS.ScorePlayer <= BThirdPlace.ScorePlayer)
	{
		if(BFourthPlace.ScorePlayer != 0)
		{
			BSixthPlace = BFifthPlace;
			BFifthPlace = BFourthPlace;
		}

		BFourthPlace = PS;
	}

	else if(PS.ScorePlayer > BFistPlace.ScorePlayer && PS.ScorePlayer <= BFourthPlace.ScorePlayer)
	{
		if(BFistPlace.ScorePlayer != 0)
		{
			BSixthPlace = BFifthPlace;
		}

		BFifthPlace = PS;
	}

	else if(PS.ScorePlayer > BSixthPlace.ScorePlayer && PS.ScorePlayer <= BFifthPlace.ScorePlayer)
	{
		BSixthPlace = PS;
	}
}

DefaultProperties
{
}
