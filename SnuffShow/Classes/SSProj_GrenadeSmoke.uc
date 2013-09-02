class SSProj_GrenadeSmoke extends SSProj_Grenade;

simulated function SpawnExplosionEffects(vector HitLocation, vector HitNormal)
{
	HitNormal = vect(0,0,0);

	super.SpawnExplosionEffects(HitLocation, HitNormal);
}

DefaultProperties
{
	ProjFlightTemplate=ParticleSystem'Armas_01.Granadas.ProjetilGranadaFumaca'

	ProjExplosionTemplate=ParticleSystem'Armas_01.Granadas.SmokeGrenadeExplosion'
	ExplosionLightClass=None

	speed=600
	MaxSpeed=1200.0
	Damage=10.0
	DamageRadius=40
	MomentumTransfer=0
	MyDamageType=class'UTDmgType_Grenade'
	LifeSpan=0.0
	ExplosionSound=SoundCue'A_Weapon_RocketLauncher.Cue.A_Weapon_RL_Impact_Cue'
	ExplosionDecal=None

	SpinCount=30000

	CustomGravityScaling=0.7
}