class AccessPlus_BroadcastHandler extends BroadcastHandler;

var localized string strMutedMsg;

var AccessPlus_Control uManager;

function PostBeginPlay()
{
    uManager = AccessPlus_Control(Level.Game.AccessControl);
}

function bool HandlerAllowsBroadcast(Actor Broadcaster, int SentTextNum)
{
    if(
        PlayerController(Broadcaster) != None
        && uManager.PlayerIsMuted(PlayerController(Broadcaster).GetPlayerIDHash()) > 0
    )
    {
        PlayerController(Broadcaster).ClientMessage(strMutedMsg);
        return false;
    }

    return Super.HandlerAllowsBroadcast(Broadcaster, SentTextNum);
}

defaultproperties
{
    strMutedMsg="You are currently muted; your message was not sent."
}
