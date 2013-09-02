class SSDroppedMesh extends Object
	abstract;

var PrimitiveComponent DroppedMesh;

DefaultProperties
{
	Begin Object Class=SkeletalMeshComponent Name=PickupMesh
		bOnlyOwnerSee=false
		CastShadow=false
		bForceDirectLightMap=true
		bCastDynamicShadow=false
		CollideActors=false
		BlockRigidBody=false
		MaxDrawDistance=6000
		bForceRefPose=1
		bUpdateSkelWhenNotRendered=false
		bIgnoreControllersWhenNotRendered=true
		bAcceptsStaticDecals=FALSE
		bAcceptsDynamicDecals=FALSE
	End Object
	DroppedMesh=PickupMesh
}
