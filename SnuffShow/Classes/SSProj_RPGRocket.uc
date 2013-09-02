class SSProj_RPGRocket extends UTProjectile;

DefaultProperties
{
	ProjFlightTemplate=ParticleSystem'Armas_01.RPG.ProjetilRPG'//ParticleSystem'VH_Goliath.Effects.PS_Goliath_Cannon_Trail'
	ProjExplosionTemplate=ParticleSystem'Envy_Effects.VH_Deaths.P_VH_Death_SpecialCase_1_Base_Far'

	MaxExplosionLightDistance=+7000.0
	speed=5000.0
	MaxSpeed=15000.0
	Damage=150
	DamageRadius=500
	MomentumTransfer=120000
	MyDamageType=class'UTDmgType_Rocket'//class'UTDmgType_TankShell'
	LifeSpan=1.2
	AmbientSound=SoundCue'A_Weapon_RocketLauncher.Cue.A_Weapon_RL_Travel_Cue'//SoundCue'A_Weapon_RocketLauncher.Cue.A_Weapon_RL_Travel_Cue'
	ExplosionSound=SoundCue'A_Weapon_RocketLauncher.Cue.A_Weapon_RL_Impact_Cue'//SoundCue'A_Vehicle_Goliath.SoundCues.A_Vehicle_Goliath_Explode'
	RotationRate=(Roll=50000)
	//DesiredRotation=(Roll=30000)
	bCollideWorld=true
	ExplosionLightClass=class'UTGame.UTRocketExplosionLight'//class'UTGame.UTTankShellExplosionLight'
	ExplosionDecal=MaterialInstanceTimeVarying'WP_RocketLauncher.Decals.MITV_WP_RocketLauncher_Impact_Decal01'//MaterialInterface'VH_Goliath.Materials.DM_Goliath_Cannon_Decal'
	DecalWidth=350
	DecalHeight=350

	bWaitForEffects=true
	bAttachExplosionToVehicles=false
}
