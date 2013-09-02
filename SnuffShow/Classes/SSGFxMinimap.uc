class SSGFxMinimap extends GFxObject;

var GFxObject Imagem, ImagemRot, Mapa, Contorno;
var SSMapInfo SSMapInfo;

function Init()
{
	local float ReajustImageMapSize;
	//local ASDisplayInfo  DI;
	
	Mapa = GetObject("Map");
	ImagemRot = Mapa.GetObject("ImageRotation");
	Imagem = ImagemRot.GetObject("Image");
	Contorno = Mapa.GetObject("Contour");

	SSMapInfo = SSMapInfo(GetPC().WorldInfo.GetMapInfo());
	//SetPosition(SSMapInfo.MinimapPosition.X, SSMapInfo.MinimapPosition.Y);
	//Mapa.SetFloat("_xscale", SSMapInfo.MinimapSize);
	//Mapa.SetFloat("_yscale", SSMapInfo.MinimapSize);
	Mapa.SetFloat("_alpha", SSMapInfo.MinimapOpacity);
	ImagemRot.SetFloat("_rotation", SSMapInfo.MinimapTextureRotation);
	SetFloat("AngleRotation", SSMapInfo.MinimapAngleRotation);

	if(SSMapInfo.MinimapTexture != none)
	{
		ReajustImageMapSize = (100 / SSMapInfo.MinimapTexture.GetSurfaceWidth()) * Imagem.GetFloat("_width");

		SetString("ImageMap", "img://"$PathName(SSMapInfo.MinimapTexture));
		Imagem.SetFloat("_xscale", ReajustImageMapSize);
		Imagem.SetFloat("_yscale", ReajustImageMapSize);
	}

	ActionScriptVoid("Init");
}

DefaultProperties
{
}
