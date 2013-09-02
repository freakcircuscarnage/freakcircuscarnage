// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class SSSeqAct_AddScore extends SequenceAction;

var() float Value;
var() bool bAddToPlayer;

event Activated()
{
	local SeqVar_Object Target;

	foreach LinkedVariables(class'SeqVar_Object',Target,"Target")
	{
		if(PlayerReplicationInfo(Target.GetObjectValue()) != none && bAddToPlayer)
			PlayerReplicationInfo(Target.GetObjectValue()).Score += Value;

		if(SSTeamInfo(PlayerReplicationInfo(Target.GetObjectValue()).Team) != none)
			SSTeamInfo(PlayerReplicationInfo(Target.GetObjectValue()).Team).ScoreTeam += Value;
	}
}

defaultproperties
{
	ObjName="Add Score"
	ObjCategory="SS Actions"

	VariableLinks(0)=(ExpectedType=class'SeqVar_Float',LinkDesc="Value",PropertyName=Value)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Object',LinkDesc="Target")
	VariableLinks(2)=(ExpectedType=class'SeqVar_Bool',LinkDesc="bAddToPlayer",PropertyName=bAddToPlayer)
}
