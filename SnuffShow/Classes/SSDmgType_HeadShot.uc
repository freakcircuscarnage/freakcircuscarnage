class SSDmgType_HeadShot extends SSDamageType;

//static function DoCustomDamageEffects(SSPawn ThePawn, class<SSDamageType> TheDamageType, const out TraceHitInfo HitInfo, vector HitLocation)
//{
//	local SkeletalMeshComponent PawnMesh;
//	local vector Impulse;
//	local vector ShotDir;

//	PawnMesh = ThePawn.Mesh;
//	ShotDir = Normal(ThePawn.TearOffMomentum);

//	Impulse = ShotDir * Min(TheDamageType.default.KDamageImpulse, 10);

//	BoneBreaker(ThePawn, PawnMesh, Impulse, HitLocation, HitInfo.BoneName);
//}

DefaultProperties
{
	bSeversHead=true
	bNeverGibs=true
	DeathAnim=Headshot01
	//bUseDamageBasedDeathEffects=true
}