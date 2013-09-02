class SSDroppedPickup extends DroppedPickup;

var	repnotify class<SSDroppedMesh> WeapArchetype;

replication
{
	if(Role==ROLE_Authority)
		WeapArchetype;
}

simulated event ReplicatedEvent(name VarName)
{
	if(VarName == 'WeapArchetype')
	{
		SetPickupMesh(WeapArchetype.default.DroppedMesh);
	}
	
	else
	{
		super.ReplicatedEvent(VarName);
	}
}

function bool CheckFullInventory(Pawn P)
{
	local array<SSWeapBase> WeaponList;
	local int i, CurrentWeaponsCount, WeaponsCount;

	SSInventorymanager(SSPawn(P).InvManager).GetWeaponList(WeaponList);

	CurrentWeaponsCount = WeaponList.Length;
	WeaponsCount = SSMapInfo(WorldInfo.GetMapInfo()).InventoryCount;
	//WeaponsCount = SSPawn(P).InitWeapons.Length;

	for (i = 0; i < WeaponList.length; i++)
	{
		if(WeaponList[i].InventoryGroup == 11 || WeaponList[i].InventoryGroup == 12)
		{
			WeaponsCount--;
			CurrentWeaponsCount--;
		}
	}

	return CurrentWeaponsCount > WeaponsCount;
}

auto state Pickup
{
	function bool ValidTouch(Pawn Other)
	{
		// make sure its a live player
		if(Other == None || !Other.bCanPickupInventory || (Other.DrivenVehicle == None && Other.Controller == None))
		{
			WorldInfo.Game.Broadcast(self, "CanPick");
			return false;
		}

		// make sure thrower doesn't run over own weapon
		if((Physics == PHYS_Falling) && (Other == Instigator) && (Velocity.Z > 0))
		{
			return false;
		}

		// make sure not touching through wall
		if(!FastTrace(Other.Location, Location))
		{
			SetTimer(0.5, false, nameof(RecheckValidTouch));
			return false;
		}

		// make sure game will let player pick me up
		if(/*Other != Instigator && */Other != None && Other.InvManager != None/*WorldInfo.Game.PickupQuery(Other, Inventory.class, self)*/)
		{
			return true;
		}
		return false;
	}

	/**
	Pickup was touched through a wall.  Check to see if touching pawn is no longer obstructed
	*/
	//function RecheckValidTouch()
	//{
	//	CheckTouching();
	//}

	// When touched by an actor.
	event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
	{
		local Pawn P;

		// If touched by a player pawn, let him pick this up.
		P = Pawn(Other);
		if(P != None && ValidTouch(P))
		{
			GiveTo(P);
		}

		//WorldInfo.Game.Broadcast(self, "DropWeap"@SSWeapBase(Inventory).AmmoCount);
	}

	//event Timer()
	//{
	//	GotoState('FadeOut');
	//}

	//function CheckTouching()
	//{
	//	local Pawn P;

	//	foreach TouchingActors(class'Pawn', P)
	//	{
	//		Touch( P, None, Location, vect(0,0,1) );
	//	}
	//}

	//event BeginState(Name PreviousStateName)
	//{
	//	super.BeginState(PreviousStateName);
	//	//AddToNavigation();
	//	//if( LifeSpan > 0.f )
	//	//{
	//	//	SetTimer(LifeSpan - 1, false);
	//	//}
	//}

//	event EndState(Name NextStateName)
//	{
//		RemoveFromNavigation();
//	}

//Begin:
//		CheckTouching();
}

//State FadeOut /*extends Pickup*/
//{
//	simulated event BeginState(Name PreviousStateName)
//	{
//		super.BeginState(PreviousStateName);

//		WorldInfo.Game.Broadcast(self, "AmmoOfDropped"@SSWeapBase(Inventory).AmmoCount);
//	}
//}

simulated function GiveTo(Pawn P)
{
	local int i;
	local array<SSWeapBase> WeaponList;

	SSInventoryManager(P.InvManager).GetWeaponList(WeaponList);

	SSPawn(P).UnHideDropWeapMC(SSWeapBase(Inventory).IconNumber);
	SSPawn(P).SetTimer(3.0, false, 'HideDropWeapMC');
   
	//WorldInfo.Game.Broadcast(self, SSWeapBase(Inventory).PendingFire(0));
	for (i=0;i<WeaponList.Length;i++)
	{
		//WorldInfo.Game.Broadcast(self, WeaponList[i].ReserveAmmo);
		if(WeaponList[i].DroppedMeshClass == SSWeapBase(Inventory).DroppedMeshClass)
		{
			if(WeaponList[i].ReserveAmmo < WeaponList[i].default.MaxAmmoCount)
			{
				SSPawn(P).SetDropWeapMCText("Arma Recarregada");
				WeaponList[i].AddAmmo(SSWeapBase(Inventory).CurrentAmmoCount);
				PickedUpBy(P);
			}

			else
				SSPawn(P).SetDropWeapMCText("Inventário Cheio");

			return;
		}

		else
			continue;
	}

	//WorldInfo.Game.Broadcast(self, "DropWeap"@SSWeapBase(Inventory).CurrentAmmoCount);
	//WorldInfo.Game.Broadcast(self, "DropWeap"@Inventory.Class);

	if(CheckFullInventory(P))
	{
		SSPawn(P).SetDropWeapMCText("Inventário Cheio");
		return;
	}

	SSPawn(P).SetDropWeapMCText("Arma Adquirida");

	super.GiveTo(P);
}

DefaultProperties
{
}
