class SSObjectiveInfo extends ReplicationInfo
	Implements(SSMinimapIconInterface);

struct SObjectiveInfo
{
	// World location of the Task
	var Vector ObjectiveLocation;
	// Texture icon of the Task
	var Texture2D ObjectiveIcon;
};

// Task information
var RepNotify SObjectiveInfo ObjectiveInfo;

replication
{
	// Initially send these variables from the server to the client
	if (bNetInitial && Role == Role_Authority)
		ObjectiveInfo;
}

simulated function RenderMinimapIcon(HUD HUD, int MinimapSize, int MinimapLocationX, int MinimapLocationY, PlayerReplicationInfo RenderingPlayerReplicationInfo)
{
	local SSMapInfo SSMapInfo;
	local int IconSize;

	SSMapInfo = SSMapInfo(WorldInfo.GetMapInfo());
	if (SSMapInfo == None)
	{
		return;
	}

	IconSize = SSMapInfo.IconSize;  // 8 padrão
	HUD.Canvas.SetPos(MinimapLocationX - (IconSize * 0.5f), MinimapLocationY - (IconSize * 0.5f));
	HUD.Canvas.SetDrawColor(255, 255, 255);
	HUD.Canvas.DrawTile(ObjectiveInfo.ObjectiveIcon, IconSize, IconSize, 0.f, 0.f, ObjectiveInfo.ObjectiveIcon.SizeX, ObjectiveInfo.ObjectiveIcon.SizeY);
}

/**
 * Returns the world location of this actor
 *
 * @return		Returns the world location of this actor
 * @network		Server and client
 */
simulated function Vector GetMinimapWorldLocation()
{
	return ObjectiveInfo.ObjectiveLocation;
}

DefaultProperties
{
}
