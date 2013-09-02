class SSPlayerInput extends PlayerInput;

var float GamePadSensitive;

event PlayerInput(float DeltaTime)
{
	super.PlayerInput(DeltaTime);

	// Mouse sensitivity doesn't have any effect on Xbox 360 controller, so we have to hack it =)
	//if(bUsingGamePad)
	//{
		aTurn *= GamePadSensitive;
		aLookup *= GamePadSensitive;
	//}
}

DefaultProperties
{
	GamePadSensitive=1.0
}
