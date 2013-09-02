class SSMapInfo extends MapInfo
	hidecategories(Object);

// Material to use for the mini map
//var(Minimap) const MaterialInterface MinimapMaterial;
// Texture to use for the mini map
var(Minimap) const Texture2D MinimapTexture, BaseTexture;
// World center location for transforming world location for the mini map
var(Minimap) const Vector MinimapWorldCenterLocation;
// World extent to use for transforming world location for the mini map
var(Minimap) const float MinimapWorldExtent;
// Degrees to rotate the mini map texture
var(Minimap) const float MinimapTextureRotation;
// Minimap icon for friendly pawns
//var(Minimap) const Texture2D MinimapRedPawnTexture;
// Minimap icon for enemy pawns
//var(Minimap) const Texture2D MinimapBluePawnTexture;
// Minimap icon for players pawn
//var(Minimap) const Texture2D MinimapPlayerPawnTexture;

var(Minimap) const float MinimapAngleRotation;

var(Minimap) const float MinimapPawnIconRotation;
// Minimap size of icons 
var(Minimap) const int IconSize;
// Minimap size 
//var(Minimap) const float MinimapSize;
// Minimap position in canvas
//var(Minimap) const int MinimapPosition;
// Minimap opacity control 
var(Minimap) const float MinimapOpacity;

var(Minimap) const bool bRenderEnemies;

var(Pawn) const bool bAllPawnsCanDropWeap;
var(Pawn) const bool bAllowFriendlyFire;
var(Pawn) const int InventoryCount;
var(Pawn) const float RespawnTime;

var(Spectator) const float SetCameraTime;

defaultproperties
{
	IconSize=120
	//MinimapSize=256.0
	//MinimapPosition=1
	MinimapOpacity=100.0
	bAllPawnsCanDropWeap=true
	bAllowFriendlyFire=true
	bRenderEnemies=true
	SetCameraTime=3.0
	InventoryCount=99
	RespawnTime=5.0
}