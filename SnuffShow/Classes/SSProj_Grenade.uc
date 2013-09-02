class SSProj_Grenade extends UTProjectile;
	
var float TimeExplode, SpinCount;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	//SetTimer(TimeExplode+FRand()*0.5,false);                  //Grenade begins unarmed
	RandSpin(SpinCount);
}

//function ActivateTimer()
//{
//	SetTimer(TimeExplode,false);
//}

function Init(vector Direction)
{
	SetRotation(Rotator(Direction));

	Velocity = Speed * Direction;
	TossZ = TossZ + (FRand() * TossZ / 2.0) - (TossZ / 4.0);
	Velocity.Z += TossZ;
	Acceleration = AccelRate * Normal(Velocity);

	//SetPhysics(PHYS_Falling);

	SetTimer(TimeExplode,false);
}

simulated function Timer()
{
	Explode(Location, vect(0,0,1));
}

event TakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	Explode(HitLocation, vect(0,0,1));

	//else
		//Super.TakeDamage(Damage, EventInstigator, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
}

simulated event HitWall(vector HitNormal, Actor Wall, PrimitiveComponent WallComp)
{
	bBlockedByInstigator = true;

	if(WorldInfo.NetMode != NM_DedicatedServer)
	{
		PlaySound(ImpactSound, true);
	}

	// check to make sure we didn't hit a pawn

	if(Pawn(Wall) == none)
	{
		Velocity = 0.75*((Velocity dot HitNormal) * HitNormal * -2.0 + Velocity);   // Reflect off Wall w/damping
		Speed = VSize(Velocity);

		if(Velocity.Z > 400)
		{
			Velocity.Z = 0.5 * (400 + Velocity.Z);
		}
		// If we hit a pawn or we are moving too slowly, explod

		if(Speed < 20 || Pawn(Wall) != none)
		{
			ImpactedActor = Wall;
			SetPhysics(PHYS_None);
		}
	}
	else if(Wall != Instigator) 	// Hit a different pawn, just explode
	{
		Explode(Location, HitNormal);
	}
}

simulated function PhysicsVolumeChange(PhysicsVolume NewVolume)
{
	if(WaterVolume(NewVolume) != none)
	{
		Velocity *= 0.25;
	}

	Super.PhysicsVolumeChange(NewVolume);
}

DefaultProperties
{
	TimeExplode=3.0

	SpinCount=100000

	DecalWidth=128.0
	DecalHeight=128.0
	bCollideWorld=true
	bProjTarget=True
	bBounce=true
	TossZ=+145.0
	Physics=PHYS_Falling
	//Physics=PHYS_None
	CheckRadius=36.0

	ImpactSound=SoundCue'A_Weapon_RocketLauncher.Cue.A_Weapon_RL_GrenadeFloor_Cue'

	bNetTemporary=False
	bWaitForEffects=false

	CustomGravityScaling=0.5

	Begin Object Name=CollisionCylinder
		CollisionRadius=16
		CollisionHeight=16
		AlwaysLoadOnClient=True
		AlwaysLoadOnServer=True
		BlockNonZeroExtent=true
		BlockZeroExtent=true
		BlockActors=true
		CollideActors=true
	End Object
}