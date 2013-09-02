interface SSMinimapIconInterface;

/**
 * Renders an icon on the mini map
 *
 * @param		HUD									HUD to render to
 * @param		MinimapSize							Current mini map size
 * @param		MinimapLocationX					Icon X position
 * @param		MinimapLocationY					Icon Y position
 * @param		RenderingPlayerReplicationInfo		Player replication info of the player rendering this mini map icon
 * @network											Server and client
 */
simulated function RenderMinimapIcon(HUD HUD, int MinimapSize, int MinimapLocationX, int MinimapLocationY, PlayerReplicationInfo RenderingPlayerReplicationInfo);

/**
 * Returns the world location of this actor
 *
 * @return		Returns the world location of this actor
 * @network		Server and client
 */
simulated function Vector GetMinimapWorldLocation();