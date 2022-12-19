//==============================================================================
// MadDriver.uc Created @ 2007
// Coded by 'Marco'
//==============================================================================
Class MadDriver extends AIController;

var Actor DesiredMove;
var bool bMayShoot,bMayIdleMoving;
var byte bCrushingAttack;
var vector InitialPosition;

Auto state WaitingToTrigger
{
Begin:
    Sleep(1);
    if(ONSVehicle(Pawn)!=None)
        ONSVehicle(Pawn).bEjectPassengersWhenFlipped = false;
    InitialPosition = Pawn.Location;
    GoToState('WakeUp');
}

State WakeUp
{
    function PickDest()
    {
        if(DesiredMove==None)
            DesiredMove = FindRandomDest();
        if(DesiredMove==None)
            return;
        if(ActorReachable(DesiredMove))
        {
            MoveTarget = DesiredMove;
            DesiredMove = None;
        }
        else MoveTarget = FindPathToward(DesiredMove);
    }
    function SeePlayer(Pawn Seen)
    {
        if(MayAttackEnemy(Seen))
        {
            Vehicle(Pawn).ServerPlayHorn(Rand(2));
            Enemy = Seen;
            GoToState('RAMTHEENEMY');
        }
    }
    function DamageAttitudeTo(Pawn Other, float Dam)
    {
        SeePlayer(Other);
    }
    function HearNoise(float Loudness, Actor NoiseMaker)
    {
        if(FastTrace(Pawn.Location,NoiseMaker.Instigator.Location))
            SeePlayer(NoiseMaker.Instigator);
    }
Begin:
    Focus = None;
    if(!bMayIdleMoving)
    {
        Vehicle(Pawn).Steering = 0;
        Vehicle(Pawn).Throttle = 0;
        Vehicle(Pawn).Rise = 0;
        Stop;
    }
    PickDest();
    if(MoveTarget==None)
        MoveTo(Pawn.Location+VRand()*1500);
    else MoveToward(MoveTarget);
    GoTo'Begin';
}
function bool MayAttackEnemy(Pawn Other)
{
    if(Other==None || Other==Pawn || Other==Enemy || Other.Health<=0)
        return false;
    if(Other.Controller==None)
    {
        if(Other.Class==Class'XPawn')
            return false;
        else return true;
    }
    if(Other.Controller.Class==Class || (Vehicle(Other)!=None && Monster(Vehicle(Other).Driver)!=None))
        return false;
    return true;
}
state RAMTHEENEMY
{
Ignores EnemyNotVisible;

    function SeePlayer(Pawn Seen)
    {
        if(MayAttackEnemy(Seen))
        {
            Vehicle(Pawn).ServerPlayHorn(Rand(2));
            Enemy = Seen;
        }
    }
    function EndState()
    {
        StopFiring();
        SetTimer(0,false);
    }
    function Timer()
    {
        Focus = Enemy;
        StopFiring();
        if(Enemy==None || !LineOfSightTo(Enemy))
            return;
        bFire = 1;
        if (Pawn != None)    
            Pawn.ChooseFireAt(Enemy);
    }
    function BeginState()
    {
        if(bMayShoot)
        {
            Timer();
            SetTimer(6,true);
        }
    }
Begin:
    if(Enemy==None || Enemy.Health<=0)
    {
GiveUp:
        Enemy = None;
        GoToState('WakeUp');
    }
    if(LineOfSightTo(Enemy))
    {
        Focus = Enemy;
        if(bCrushingAttack==1)
            MoveToward(Enemy);
        else if(bCrushingAttack==0) MoveTo(Pawn.Location+VRand()*600,Enemy);
        else if(bCrushingAttack==2) Sleep(1.5+FRand()*2);
        else if(bCrushingAttack==3) MoveTo(InitialPosition+VRand()*600,Enemy);
    }
    else if(bCrushingAttack!=0 && bCrushingAttack!=1)
        GoTo'GiveUp';
    else
    {
        Focus = None;
        MoveTarget = FindPathToward(Enemy);
        if(MoveTarget==None)
            GoTo'GiveUp';
        else MoveToward(MoveTarget);
    }
    GoTo'Begin';
}
