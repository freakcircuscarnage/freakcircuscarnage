class SSProj_Shotgun extends UTProjectile;

function Init(vector Direction)
{
	super.Init(Direction);

	SetTimer(0.05,true,'DecreaseDamage');
}

function DecreaseDamage()
{
	Damage = Damage / 1.5;
	MomentumTransfer = MomentumTransfer / 1.5;
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
	ClearTimer('DecreaseDamage');

	//WorldInfo.Game.Broadcast(self, Damage);
	
	super.Explode(HitLocation, HitNormal);
}

DefaultProperties
{
	ProjFlightTemplate=ParticleSystem'Pacote_Particulas.Effects.Arrow_Dup'
	ProjExplosionTemplate=ParticleSystem'Pacote_Particulas.Impacto_12_Dup'
	MaxEffectDistance=7000.0

	Speed=3000
	MaxSpeed=7000
	AccelRate=10000.0

	Damage=50
	DamageRadius=0
	MomentumTransfer=10000
	CheckRadius=46.0

	MyDamageType=class'DmgType_Crushed'
	LifeSpan=2.0
	NetCullDistanceSquared=+144000000.0

	bCollideWorld=true
	DrawScale=0.4

	ExplosionDecal=MaterialInstanceTimeVarying'WP_FlakCannon.Decals.MITV_WP_FlakCannon_Impact_Decal01'
	DecalWidth=32.0
	DecalHeight=32.0

	ExplosionSound=SoundCue'A_Weapon_Link.Cue.A_Weapon_Link_ImpactCue'
}
