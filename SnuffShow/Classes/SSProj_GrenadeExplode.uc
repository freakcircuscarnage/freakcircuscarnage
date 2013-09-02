class SSProj_GrenadeExplode extends SSProj_Grenade;

DefaultProperties
{
	ProjFlightTemplate=ParticleSystem'Armas_01.Granadas.ProjetilGranada'

	ProjExplosionTemplate=ParticleSystem'Envy_Effects.VH_Deaths.P_VH_Death_SMALL_Near'
	ExplosionLightClass=class'UTGame.UTRocketExplosionLight'

	speed=600
	MaxSpeed=1200.0
	Damage=150.0
	DamageRadius=300
	MomentumTransfer=50000
	MyDamageType=class'UTDmgType_Grenade'
	LifeSpan=0.0
	ExplosionSound=SoundCue'A_Weapon_RocketLauncher.Cue.A_Weapon_RL_Impact_Cue'
	ExplosionDecal=MaterialInstanceTimeVarying'WP_RocketLauncher.Decals.MITV_WP_RocketLauncher_Impact_Decal01'
}
