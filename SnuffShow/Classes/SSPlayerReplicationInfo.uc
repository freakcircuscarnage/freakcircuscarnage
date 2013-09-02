class SSPlayerReplicationInfo extends PlayerReplicationInfo;

// What class the player is
var SSPawn ClassArchetype;
var int Pontos;

var repnotify int Frags;

replication
{
	if(bNetDirty)
		Frags;
}

function SetPlayerTeam(TeamInfo NewTeam)
{
	local PlayerController PlayerController;
	local Actor Actor;

	Super.SetPlayerTeam(NewTeam);
	
	// Update all local actors that the local player has switched team
	ForEach LocalPlayerControllers(class'PlayerController', PlayerController)
	{
		if (PlayerController.PlayerReplicationInfo == Self)
		{
			ForEach AllActors(class'Actor', Actor)
			{
				Actor.NotifyLocalPlayerTeamReceived();
			}

			break;
		}
	}
}

function IncrementDeaths(optional int Amt = 1)
{
	Deaths += Amt;
	//WorldInfo.Game.Broadcast(self, "Death" @ Deaths);
}

defaultproperties
{
}
