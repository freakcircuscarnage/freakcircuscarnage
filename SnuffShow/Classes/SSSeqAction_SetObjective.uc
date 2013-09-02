class SSSeqAction_SetObjective extends SequenceAction;

// Objective location
var() const Vector ObjectiveLocation;
// Objective icon
var() const Texture2D ObjectiveIcon;

// Objective icon
var Object LinkedObjectiveIcon;
// Objective target location
var Object LinkedObjectiveLocation;
// Created Objective info
var Object LinkedObjectiveInfo;

/**
 * This is called when the Sequence Event is activated.
 *
 * @network			Server and client
 */
event Activated()
{
	local WorldInfo WorldInfo;
	local Actor LinkedActorObjectiveLocation;
	local Texture2D LinkedTextureObjectiveIcon;
	local SSObjectiveInfo SSObjectiveInfo;
	//local AssaultTeamInfo AssaultTeamInfo;
	//local int i;

	// Call the super activated
	Super.Activated();

	//// Get the world info
	WorldInfo = GetWorldInfo();
	//// If this is activated on the client, then abort (GameInfo is never replicated to clients and only exists on the server)
	//if (WorldInfo.Game == None || WorldInfo.GRI == None || WorldInfo.GRI.Teams.Length <= 0)
	//{
	//	return;
	//}

	//// Find the team info
	//for (i = 0; i < WorldInfo.GRI.Teams.Length; ++i)
	//{
	//	if (WorldInfo.GRI.Teams[i] != None && WorldInfo.GRI.Teams[i].TeamIndex == TeamIndex)
	//	{
	//		AssaultTeamInfo = AssaultTeamInfo(WorldInfo.GRI.Teams[i]);
	//		break;
	//	}
	//}

	//// Check the team info is valid
	//if (AssaultTeamInfo == None)
	//{
	//	return;
	//}

	// Copy the linked variable values to the member variables
	PublishLinkedVariableValues();

	// Spawn the Objective actor, and copy the properties across
	SSObjectiveInfo = WorldInfo.Spawn(class'SSObjectiveInfo');
	if (SSObjectiveInfo != None)
	{
		LinkedActorObjectiveLocation = Actor(LinkedObjectiveLocation);
		LinkedTextureObjectiveIcon = Texture2D(LinkedObjectiveIcon);

		// Set the properties of the Objective
		//SSObjectiveInfo.ObjectiveInfo.TeamIndex = TeamIndex;
		//SSObjectiveInfo.ObjectiveInfo.ObjectiveName = ObjectiveName;
		SSObjectiveInfo.ObjectiveInfo.ObjectiveLocation = (LinkedActorObjectiveLocation != None) ? LinkedActorObjectiveLocation.Location : ObjectiveLocation;
		SSObjectiveInfo.ObjectiveInfo.ObjectiveIcon = (LinkedTextureObjectiveIcon != None) ? LinkedTextureObjectiveIcon : ObjectiveIcon;
		//SSObjectiveInfo.ObjectiveInfo.ObjectiveOrder = ObjectiveOrder;

		// Add the Objective to the team info
		//AssaultTeamInfo.InsertSortObjective(SSObjectiveInfo);

		// Set the out Objective info
		LinkedObjectiveInfo = SSObjectiveInfo;
	}

	// Populate the linked variables with the member variables
	PopulateLinkedVariableValues();
}

DefaultProperties
{
	ObjName="Set Objective"
	ObjCategory="Misc"
	//bPlayerOnly=false

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="Objective Location",PropertyName=LinkedObjectiveLocation)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Object',LinkDesc="Objective Icon",PropertyName=LinkedObjectiveIcon)
	VariableLinks(2)=(ExpectedType=class'SeqVar_Object',LinkDesc="Objective Info",bWriteable=true,PropertyName=LinkedObjectiveInfo)
}
