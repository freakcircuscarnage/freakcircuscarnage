class SSDamageType extends DamageType;

var CameraAnim DamageCameraAnim;

var bool bSeversHead;

var bool bNeverGibs, bAlwaysGibs;

var	name DeathAnim;

var	float DeathAnimRate;

var	bool bAnimateHipsForDeathAnim;

var bool bUseDamageBasedDeathEffects;

static function BoneBreaker(SSPawn ThePawn, SkeletalMeshComponent TheMesh, vector Impulse, vector HitLocation, name BoneName)
{
	local int NumBonesToPossiblyBreak;
	local int ConstraintIndex;

	NumBonesToPossiblyBreak = ThePawn.default.DeathMeshBreakableJoints.length;
	if(NumBonesToPossiblyBreak > 0)
	{
		BoneName = ThePawn.default.DeathMeshBreakableJoints[Rand(NumBonesToPossiblyBreak)];

		ConstraintIndex = TheMesh.FindConstraintIndex(BoneName);

		if (ConstraintIndex != INDEX_NONE)
		{
			TheMesh.PhysicsAssetInstance.Constraints[ConstraintIndex].TermConstraint();

			TheMesh.AddImpulse(Impulse, HitLocation, BoneName);
		}
	}
}

static function DoCustomDamageEffects(SSPawn ThePawn, class<SSDamageType> TheDamageType, const out TraceHitInfo HitInfo, vector HitLocation)
{
	//`log("UTDamageType base DoCustomDamageEffects should never be called");
	// ScriptTrace();
}

//static function SpawnGibEffects(UTGib Gib)
//{
//	local ParticleSystemComponent Effect;

//	if (default.GibTrail != None)
//	{
//		// we can't use the ParticleSystemComponentPool here as the trails are long lasting/infi so they will not call OnParticleSystemFinished
//		Effect = new(Gib) class'UTParticleSystemComponent';
//		Effect.SetTemplate(Default.GibTrail);
//		Gib.AttachComponent(Effect);
//	}
//}

//static function bool ShouldGib(UTPawn DeadPawn)
//{
//	if (DeadPawn.WorldInfo.IsConsoleBuild(CONSOLE_Mobile))
//	{
//		return true;
//	}
//	return ( !Default.bNeverGibs && (Default.bAlwaysGibs || (DeadPawn.AccumulateDamage > Default.AlwaysGibDamageThreshold) || ((DeadPawn.Health < Default.GibThreshold) && (DeadPawn.AccumulateDamage > Default.MinAccumulateDamageThreshold))) );
//}

DefaultProperties
{
	bAnimateHipsForDeathAnim=true
	DeathAnimRate=1.0
}
