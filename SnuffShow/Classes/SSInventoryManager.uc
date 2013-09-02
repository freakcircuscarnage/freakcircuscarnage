class SSInventoryManager extends InventoryManager;

var byte LastWeaponIndex;

simulated function GetWeaponList(out array<SSWeapBase> WeaponList, optional bool bFilter, optional int GroupFilter, optional bool bNoEmpty)
{
	local SSWeapBase Weap;
	local int i;

	ForEach InventoryActors(class'SSWeapBase', Weap)
	{
		if((!bFilter || Weap.InventoryGroup == GroupFilter) /*&& (!bNoEmpty || Weap.HasAnyAmmo())*/)
		{
			if (WeaponList.Length>0)
			{
				// Find it's place and put it there.

				for (i=0;i<WeaponList.Length;i++)
				{
					//if (WeaponList[i].InventoryWeight > Weap.InventoryWeight)
					//{
						WeaponList.Insert(i,1);
						WeaponList[i] = Weap;
						break;
					//}
				}
				if (i==WeaponList.Length)
				{
					WeaponList.Length = WeaponList.Length+1;
					WeaponList[i] = Weap;
				}
			}
			else
			{
				WeaponList.Length = 1;
				WeaponList[0] = Weap;
			}
		}
	}
}

simulated function SwitchWeapon(byte NewGroup)
{
	local SSWeapBase CurrentWeapon;
	local array<SSWeapBase> WeaponList;
	local int NewIndex;

	LastWeaponIndex = SSWeapBase(Instigator.Weapon).InventoryGroup;

	// Get the list of weapons

   	GetWeaponList(WeaponList,true,NewGroup);

	// Exit out if no weapons are in this list.

	if(WeaponList.Length<=0)
		return;

	CurrentWeapon = SSWeapBase(PendingWeapon);
	if(CurrentWeapon == None)
	{
		CurrentWeapon = SSWeapBase(Instigator.Weapon);
	}

	if(CurrentWeapon == none || CurrentWeapon.InventoryGroup != NewGroup)
	{
		// Changing groups, so activate the first weapon in the array

		NewIndex = 0;
	}
	else
	{
		// Find the current weapon's position in the list and switch to the one above it

		for(NewIndex=0;NewIndex<WeaponList.Length;NewIndex++)
		{
			if (WeaponList[NewIndex] == CurrentWeapon)
				break;
		}
		NewIndex++;
		if(NewIndex>=WeaponList.Length)		// start the beginning if past the end.
			NewIndex = 0;
	}

	// Begin the switch process...

	//if (WeaponList[NewIndex].HasAnyAmmo())
	//{
		SetCurrentWeapon(WeaponList[NewIndex]);
	//}
}

simulated function SwitchLastWeapon()
{
	if(LastWeaponIndex != 255)
		SwitchWeapon(LastWeaponIndex);
}

simulated function Inventory CreateInventoryFromArchetype(Inventory InventoryArchetype, optional bool bDoNotActivate)
{
	local Inventory Inv;

	// Ensure that the inventory archetype is valid
	if(InventoryArchetype == None)
	{
		return None;
	}

	// Spawn the inventory 
	Inv = Spawn(InventoryArchetype.Class, Owner,,,, InventoryArchetype);
	if (Inv != None)
	{
		// If could not add the inventory, then destroy it
		if(!AddInventory(Inv, bDoNotActivate))
		{
			Inv.Destroy();
			return None;
		}
		// Could add the inventory item, return it
		else
		{
			return Inv;
		}
	}

	return None;
}

simulated function bool AddInventory(Inventory NewItem, optional bool bDoNotActivate)
{
	local bool bResult;
	local array<SSWeapBase> WeaponList;
	local int i, WeaponsCount;

	bResult = super.AddInventory(NewItem, bDoNotActivate);

	GetWeaponList(WeaponList);
	WeaponsCount = WeaponList.Length;

	for (i = 0; i < WeaponList.length; i++)
	{
		if(WeaponList[i].InventoryGroup == 11 || WeaponList[i].InventoryGroup == 12)
			WeaponsCount--;
	}

	//if(WeaponList.Length > SSPawn(Instigator).InitWeapons.Length)
	//	return false;

	//if(SSWeapBase(NewItem).InventoryGroup != SSWeapBase(InventoryChain).InventoryGroup)
	if(SSWeapBase(NewItem).FiringStatesArray[0] != 'GrenadeFiring')
		SSWeapBase(NewItem).InventoryGroup = WeaponsCount;

	//SSWeapBase(NewItem).SetInventoryGroup();
	
	return bResult;
}

//simulated function RemoveFromInventory(Inventory ItemToRemove)
//{	
//	Super.RemoveFromInventory(ItemToRemove);

//	WorldInfo.Game.Broadcast(self, "RemoveWeapon");
//}

DefaultProperties
{
	PendingFire(0)=0
	PendingFire(1)=0

	LastWeaponIndex=255
}
