class SSTeamInfo extends TeamInfo
	hidecategories(Object, Display, Attachment, Physics, Mobile, Advanced, Debug);

var(Team) SSPawn PawnArchetype[5];

var repnotify int ScoreTeam;

replication
{
	if(bNetDirty)
		ScoreTeam;
}

DefaultProperties
{
}
