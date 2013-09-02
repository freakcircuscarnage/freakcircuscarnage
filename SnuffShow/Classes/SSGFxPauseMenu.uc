class SSGFxPauseMenu extends GFxMoviePlayer;

function bool Start(optional bool StartPaused = false)
{
    super.Start();
    Advance(0);

	return true;
}

function Sair()
{
	SSPlayerController(GetPC()).ConsoleCommand("Disconnect");
}

function Continuar()
{
    SSHUD(GetPC().MyHUD).ClosePauseMenu();
}

DefaultProperties
{
	bEnableGammaCorrection=false
	bCaptureInput=true
}
