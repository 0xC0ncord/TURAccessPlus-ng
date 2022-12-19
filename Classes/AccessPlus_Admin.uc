//==============================================================================
// AccessPlus_Admin.uc Created @ 2006
// Coded by 'Marco' and 'Eliot van uytfanghe'
//==============================================================================
class AccessPlus_Admin extends Admin;

var AccessPlus_Control uManager;
var bool bWasSilentLogin;
var class<Actor> StrToActorC;
var array<Actor> NeedDelete;
var string LastServerName;

event Created()
{
    Super.Created();
    uManager = AccessPlus_Control(Manager);
}

function DoLogin(string Username, string Password)
{
    // Don't get the cheaters scared!
    if(Password ~= "Silent" || Username ~= "Silent")
    {
        bWasSilentLogin = true;
        if(uManager.DidAdminLogin(Outer, Username, false))
            bAdmin = true;

        return;
    }
    else if(uManager.DidAdminLogin(Outer, Password, true))
        bAdmin = true;
}

function DoLogout()
{
    if(!bWasSilentLogin)
        Level.Game.Broadcast(uManager, uManager.GetAdminLogoutMessage(PlayerReplicationInfo));

    uManager.RemoveAdminPriv(Outer);
    bAdmin = false;
}

function bool CanDo(string Cmd)
{
    return uManager.MayExecute(Outer, Cmd);
}

exec function Admin(string CommandLine)
{
    if(!CanDo(CommandLine))
    {
        Note("You are not allowed to execute command"@CommandLine);
        return;
    }
    Outer.Admin(CommandLine);
}
//==============================================================================
// Usefull admin functions

// Gives back the Controller associated with a player ID
final function Controller findPlayerByID(int ID)
{
       local Controller C;

    for(C = Level.ControllerList; C != None; C = C.nextController)
    {
        if(C.PlayerReplicationInfo!=None && C.PlayerReplicationInfo.PlayerID==ID)
            return C;
    }
    return none;
}

final function array<Controller> SearchPlayers(string ID, optional out string NameTag)
{
       local array<Controller> CA;
    local Controller C;
    local bool bGetAll;
    local int i;

    NameTag = "";
    if(ID=="0" || int(ID)!=0)
    {
        CA.Length = 1;
        CA[0] = findPlayerByID(int(ID));
        if(CA[0]==None)
            CA.Length = 0;
        else if(CA[0].PlayerReplicationInfo!=None)
            NameTag = CA[0].PlayerReplicationInfo.PlayerName;
        else NameTag = string(CA[0]);
        return CA;
    }
    else if(ID~="Self" || ID=="")
    {
        CA.Length = 1;
        CA[0] = Outer;
        if(PlayerReplicationInfo.bIsFemale)
            NameTag = "herself";
        else NameTag = "himself";
        return CA;
    }
    bGetAll = (ID~="All");
    for(C = Level.ControllerList; C != None; C = C.nextController)
    {
        if((C.bIsPlayer && bGetAll && C.PlayerReplicationInfo!=None) || (C.PlayerReplicationInfo!=None && C.PlayerReplicationInfo.PlayerName~=ID))
        {
            if(!bGetAll)
            {
                if(NameTag=="")
                    NameTag = C.PlayerReplicationInfo.PlayerName;
                else NameTag = NameTag$","@C.PlayerReplicationInfo.PlayerName;
            }
            CA.Length = i+1;
            CA[i] = C;
            i++;
        }
    }
    if(bGetAll)
        NameTag = "everyone";
    return CA;
}

// A message shown to everyone notifying what a admin have done
function AdminBroadcast(coerce string Msg)
{
    Level.Game.Broadcast(Outer, GetAdmin(PlayerReplicationInfo)@Msg);
}

// Exec function messages like errors
function Note(coerce string Msg)
{
    ClientMessage(CreateColor(uManager.AdminTagColor)$"Note"@CreateColor(Class'HUD'.Default.GrayColor)$Msg);
}

function NoteError(coerce string Msg)
{
}

// A message only visible to admins
function AMessage(string Msg)
{
    ASay(":"@Msg);
}

// returns false if target is not found.
final function bool CheckControllers(array<Controller> C, optional bool bCheckPawn)
{
    if(C.Length == 0)
    {
        Note("Target not found");
        return false;
    }
    else if(bCheckPawn && (C.Length == 1 && C[0].Pawn == None))
    {
        Note("Target has no pawn");
        return false;
    }
    return true;
}

final function string GetAdmin(PlayerReplicationInfo PRI)
{
    return uManager.GetAdminLoginMessage(PRI);
}

final function Actor FindActor(name ATag)
{
    local Actor A;

    foreach AllActors(Class'Actor', A, ATag)
    {
        if(A.Tag == ATag || A.Name == ATag)
            return A;
    }
}

final function string CreateColor(Color Color)
{
    return uManager.MyMutator.MakeColorCode(Color);
}
//==============================================================================

//==============================================================================
// The help function for the noobs and anyone who can't remember the command names
function HelpMessage(coerce string Msg)
{
    ClientMessage(CreateColor(Class'HUD'.Default.RedColor)$Msg$CreateColor(Class'HUD'.Default.WhiteColor));
}

function CmdHelpMessage(coerce string Cmd, coerce string Info)
{
    ClientMessage(CreateColor(uManager.AdminTagColor)$Cmd$CreateColor(Class'HUD'.Default.WhiteColor)@CreateColor(Class'HUD'.Default.GrayColor)$Info$CreateColor(Class'HUD'.Default.WhiteColor));
}

exec function AdminHelp(string S)
{
    Help(S);
}

exec function Help(string S)
{
    if(S == "")
    {
        HelpMessage("-----------");
        HelpMessage("Use ('Help <Command Name>' for more info on a specific command)");
        HelpMessage(">> Global-Admin Commands <<");
        HelpMessage("GetGlobalAdminPassword :: SetGlobalAdminPassword");
        HelpMessage("CreateAdminAccount :: DeleteAdminAccount");
        HelpMessage("NameAdminAccount :: PrivilegesAdminAccount :: PasswordAdminAccount");
        HelpMessage("-----------");
        HelpMessage(">> Co-Admin Commands <<");
        HelpMessage("Fly :: Ghost :: Walk :: Spider :: Slap :: Fatality :: Rename :: Invis :: God :: HeadSize :: PlayerSize");
        HelpMessage("ChangeScore :: Fatality :: AllAmmo : AllWeapons :: Loaded :: GiveItem :: TeleP :: GotoP :: SetMonster");
        HelpMessage("FreakOut :: SetMonster :: CreateCombo :: AddToBody :: EnhancedPawn :: GotoA :: Teleport :: ForceTeam");
        HelpMessage("PlayerControl :: SetGameSpeed :: SetGravity :: CauseEvent :: Summon :: SkipObj");
        HelpMessage("MonsterFire :: AddMessagePoint :: SetTime :: AddTime :: AddMadDriver");
        HelpMessage("-----------");
        HelpMessage(">> Operational Commands <<");
        HelpMessage("GetID :: Kick :: KickBanN :: ListBans :: ListTempBans :: UnBan :: UnBanTemp");
        HelpMessage("AddServerPackage :: RemoveServerPackage :: ListServerPackages :: Set :: SetSave");
        HelpMessage("GetConnections :: GetAddress :: MapVote :: ReloadCache");
        HelpMessage("AdminMessage :: PrivateMessage");
        HelpMessage("-----------");
        return;
    }

    HelpMessage("<> = Required, || = Optional, ** = Global admin command");
    switch(Caps(S))
    {
        // Global Admin                                                       \\
        case "GETGLOBALADMINPASSWORD":
            CmdHelpMessage("** "$S, "- Displays current global admin password");
            break;

        case "SETGLOBALADMINPASSWORD":
            CmdHelpMessage("** "$S, "<string GlobalPassword> - Changes the current global admin password");
            break;

        case "CREATEADMINACCOUNT":
            CmdHelpMessage("** "$S, "<string PlayerID> - Create an admin account");
            break;

        case "DELETEADMINACCOUNT":
            CmdHelpMessage("** "$S, "<int AdminSlot> - Delete an admin account");
            break;

        case "NAMEADMINACCOUNT":
            CmdHelpMessage("** "$S, "<int AdminSlot> <string AdminName> - Change an admin account's name");
            CmdHelpMessage("Alternative Command", "SetACName");
            break;

        case "PASSWORDADMINACCOUNT":
            CmdHelpMessage("** "$S, "<int AdminSlot> <string AdminPassword> - Change an admin account's password");
            CmdHelpMessage("Alternative Command", "SetACPass");
            break;

        case "PRIVILEGESADMINACCOUNT":
            CmdHelpMessage("** "$S, "<int AdminSlot> <string Privileges> - Changes an admin account's privileges");
            CmdHelpMessage("** "$S, "<int AdminSlot> <All> - To block all admin commands for this admin account");
            CmdHelpMessage("Alternative Command", "SetACPriv");
            break;

        case "LISTADMINACCOUNTS":
            CmdHelpMessage("** "$S, "<None> - Displays a list of all admin accounts with info");
            break;
        //                                                                      \\

        // Gameplay affecting commands                                          \\
        case "FLY":
            CmdHelpMessage(S, "|string PlayerID| - Target player will feel lighter");
            CmdHelpMessage(S, "|Self| - Will automatically target you");
            break;

        case "GHOST":
            CmdHelpMessage(S, "|string PlayerID| - Target player will feel etheareal");
            CmdHelpMessage(S, "|Self| - Will automatically target you");
            break;

        case "SPIDER":
            CmdHelpMessage(S, "|string PlayerID| - Target player fingers will feel sticky");
            CmdHelpMessage(S, "|Self| - Will automatically target you");
            break;

        case "SLAP":
            CmdHelpMessage(S, "|string PlayerID| |int SlapDamage| - Slap target player");
            CmdHelpMessage(S, "|Self| - Will automatically target you");
            break;

        case "RENAME":
            CmdHelpMessage(S, "|string PlayerID| <string Name> - Changes target player name");
            CmdHelpMessage(S, "|Self| <Newbie> - Will automatically target you");
            break;

        case "GOD":
            CmdHelpMessage(S, "|string PlayerID| |bool bGodMode| - Make target player invurnable");
            CmdHelpMessage(S, "|Self| |true| - Will automatically target you");
            break;

        case "HEADSIZE":
            CmdHelpMessage(S, "|string PlayerID| <float Size> - Changes target player head size");
            CmdHelpMessage(S, "|Self| <0.25> - Will automatically target you");
            break;

        case "PLAYERSIZE":
            CmdHelpMessage(S, "|string PlayerID| <float Size> - Changes target player body size");
            CmdHelpMessage(S, "|Self| <2.0> - Will automatically target you");
            break;

        case "INVIS":
            CmdHelpMessage(S, "|string PlayerID| - Make target player invisible");
            CmdHelpMessage(S, "|Self| - Will automatically target you");
            break;

        case "FATALITY":
            CmdHelpMessage(S, "|string PlayerID| - Make target player blow up");
            CmdHelpMessage(S, "|Self| - Will automatically target you");
            break;

        case "CHANGESCORE":
            CmdHelpMessage(S, "|string PlayerID| <int Score> - Changes target player score");
            CmdHelpMessage(S, "|Self| <1337> - Will automatically target you");
            break;

        case "SETGAMESPEED":
            CmdHelpMessage(S, "<float SpeedScaling> - Changes the game speed");
            CmdHelpMessage(S, "<1.1> - For default speed scaling");
            break;

        case "SETGRAVITY":
            CmdHelpMessage(S, "<float Gravity> - Changes the world gravity");
            CmdHelpMessage(S, "<-950> - For default world gravity");
            break;

        case "SUMMON":
            CmdHelpMessage(S, "<string Class> <string Properties> - Spawns an actor of type <Class>");
            CmdHelpMessage("Example", S@"<RedeemerProjectile> <DrawScale=2/Damage=15>");
            break;

        case "PLAYERCONTROL":
            CmdHelpMessage(S, "|string PlayerID| <string Command> - Make target player execute <Command>");
            CmdHelpMessage(S, "|Self| <Say I'm admin yeah!> - Will automatically target you");
            CmdHelpMessage("Example", S@"<Michael Jackson> <Say Just beat it!>");
            CmdHelpMessage("Alternative Command", "RemotePlayerCommand");
            break;

        case "TELEP":
            CmdHelpMessage(S, "|string PlayerID| - Teleport target player to you");
            CmdHelpMessage(S, "|Self| - Will automatically target you");
            break;

        case "GOTOP":
            CmdHelpMessage(S, "|string PlayerID| - Teleport to target player");
            CmdHelpMessage(S, "|Self| - Will automatically target you");
            break;

        case "GOTOA":
            CmdHelpMessage(S, "|string PlayerID| <name ActorTag> |vector Offset| - Teleport target player to <class ActorToTeleportTo>");
            CmdHelpMessage(S, "|Self| <Mover1> - Will automatically target you");
            break;

        case "LOADED":
            CmdHelpMessage(S, "|string PlayerID| |bool bSuperWeapons| - Give target player all weapons and full ammo");
            CmdHelpMessage(S, "|Self| |true| - Will automatically target you");
            break;

        case "ALLAMMO":
            CmdHelpMessage(S, "|string PlayerID| - Make target player weapons full loaded");
            CmdHelpMessage(S, "|Self| - Will automatically target you");
            break;

        case "ALLWEAPONS":
            CmdHelpMessage(S, "|string PlayerID| |bool bSuperWeapons| - Give target player all weapons");
            CmdHelpMessage(S, "|Self| |true| - Will automatically target you");
            break;

        case "GIVEITEM":
            CmdHelpMessage(S, "|string PlayerID| <class Item> - Give target player an item");
            CmdHelpMessage(S, "|Self| <xWeapons.RocketLauncher> - Will automatically target you");
            break;

        case "SETMONSTER":
            CmdHelpMessage(S, "|string PlayerID| <byte MovementType> <class Monster> - Turn target player into an monster");
            CmdHelpMessage(S, "|Self| <0> <Skaarjpack.Warlord> - Will automatically target you");
            CmdHelpMessage("<byte MovementType>", "0 = WalkMode, 1 = FlyMode, 2 = SpiderMode");
            break;

        case "MONSTERFIRE":
            CmdHelpMessage(S, "<None> - Make you fire like a monster");
            break;

        case "SKIPOBJ":
            CmdHelpMessage(S, "<None> - Skips the current assault objective");
            break;

        case "CAUSEEVENT":
            CmdHelpMessage(S, "<name ActorTag> - Triggers an actor");
            CmdHelpMessage("Example", S@"<Mover>");
            break;

        case "FREAKOUT":
            CmdHelpMessage(S, "|string PlayerID| - Fake master server ban target player");
            break;

        case "ADDMADDRIVER":
            CmdHelpMessage(S, "<bool bCanFire> <byte AttackMode> <bool bMayIdle> <class Vehicle> - Spawn a vehicle with a mad driver(bot)");
            CmdHelpMessage("<byte AttackMode>", "0 = Strafe around, 1 = Try crush enemies, 2 = Stand still while attacking, 3 = Stay within a radius");
            CmdHelpMessage("Example", S@"<true> <1> <false> <Onslaught.ONSPRV>");

        case "SETTIME":
            CmdHelpMessage(S, "<float Time(Minutes)> - Sets the RoundTimeLimit of Assault");
            break;

        case "ADDTIME":
            CmdHelpMessage(S, "<float Time(Minutes)> - Adds time to the RoundTimeLimit of Assault");
            break;

        case "ADDMESSAGEPOINT":
            CmdHelpMessage(S, "<string Message> - Add a trigger showing a message on player colliding");
            break;

        case "DESTROYACTORS":
            CmdHelpMessage(S, "<class ClassTypeToDestroy> - Destroys all actors of <class ClassTypeToDestroy>");
            CmdHelpMessage("Alternative Command", "KillAll");
            break;
        //                                                                      \\

        // Admin server commands                                                \\

        // Kick related
        case "KICK":
            CmdHelpMessage(S, "<string PlayerID> - Kick target player");
            break;

        case "KICKBANN":
            CmdHelpMessage(S, "<string PlayerID> |Days| - Kick target player for |Days|");
            CmdHelpMessage("|Days|", "0 = Permamently banned, 7 = One week");
            break;

        case "LISTBANS":
            CmdHelpMessage(S, "<None> - Displays a list of currently banned players");
            break;

        case "LISTTEMPBANS":
            CmdHelpMessage(S, "<None> - Displays a list of currently temporary banned players");
            break;

        case "UNBAN":
            CmdHelpMessage(S, "<int BanSlot> - UnBan <int BanSlot>");
            break;

        case "UNBANTEMP":
            CmdHelpMessage(S, "<int TempBanSlot> - UnBanTemp <int TempBanSlot>");
            break;
        //

        case "PRIVATEMESSAGE":
            CmdHelpMessage(S, "<string PlayerID> <string Message> - Send a private message to target player");
            CmdHelpMessage("Alternative Command", "PSay");
            break;

        case "ADMINMESSAGE":
            CmdHelpMessage(S, "<string Message> - Send a message only admins can see");
            CmdHelpMessage("Alternative Command", "ASay");
            break;

        // Useful commands                                                        \\
        case "SHOWTAGS":
            CmdHelpMessage(S, "|float Radius| <class Type> - Show actor tags/events of <class Type> within |float Radius|");
            CmdHelpMessage("Example", S@"|1000| <Engine.Mover>");
            break;

        case "GETID":
            CmdHelpMessage(S, "<None> - Displays a id list of the current players");
            CmdHelpMessage("Alternative Command", "ListPlayerIDs");
            break;

        case "GETCONNECTIONS":
            CmdHelpMessage(S, "<string Type> - Display connected clients");
            CmdHelpMessage("<string Type>", "All = Display all clients, Active = Display all active clients, InActive = Display all inactive clients, Detail = Display detailed info");
            break;

        case "GETADDRESS":
            CmdHelpMessage(S, "<string PlayerID> - Displays GUID and IP of target player");
            break;

        case "RELOADCACHE":
            CmdHelpMessage(S, "<None> - Reload the server cache, e.g to see newly uploaded files without a restart");
            break;

        case "MAPVOTE":
            CmdHelpMessage(S, "<string Action> - Execute an action in VotingHandler");
            CmdHelpMessage("<string Action>", "Cancel = Cancel the current map votes, Begin = Force mid-game map voting");
            break;

        //                                                                      \\

        // Server configuration commands                                        \\
        case "ADDSERVERPACKAGE":
            CmdHelpMessage(S, "<string PackageName> - Add a serverpackage to the list");
            break;

        case "REMOVESERVERPACKAGE":
            CmdHelpMessage(S, "<string PackageName> - Remove a serverpackage of the list");
            break;

        case "LISTSERVERPACKAGES":
            CmdHelpMessage(S, "<None> - Displays all current serverpackages");
            break;

        case "SET":
            CmdHelpMessage(S, "<string Class> <string Property> <string Value> - Change an actor's property value");
            CmdHelpMessage("Example", S@"<Engine.Pawn> <JumpZ> <1024>");
            break;

        case "SETSAVE":
            CmdHelpMessage(S, "<string Class> <string Property> <string Value> - Change an actors property value and executes SaveConfig() for <string Class>");
            CmdHelpMessage("Example", S@"<Engine.GameInfo> <TimeLimit> <6000>");
            break;
        //                                                                      \\

        default:
            Note("No help info found for '" $ S $ "'");
            break;
    }
}
//==============================================================================

//==============================================================================
// Powerful gameplay admin commands

// Slap that guys bothering you and do 1 point of damage from him
exec function Slap(string PlayerID, optional int SlapDamage)
{
    local Array<Controller> C;
    local int i;
    local string S;

    if(!CanDo("Slap"))return;
    C = SearchPlayers(PlayerID,S);
    if(!CheckControllers(C, true))return;
    if(SlapDamage == 0)
        SlapDamage = 1;
    AdminBroadcast("PimpSlaps"@S@"like a bitch!");
    for(i=0; i<C.Length; i++)
    {
        if(C[i].Pawn==None) Continue;
        C[i].Pawn.ClientMessage("You've been Pimp slapped!");
        if(C[i].Pawn.Health>1)
            C[i].Pawn.TakeDamage(SlapDamage, Pawn, VRand()*20000, VRand()*20000, class'DamageType');
    }
}

// Change Player's Name
exec function Rename(int ID, string NewName)
{
    local Controller C;

    if(!CanDo("Rename")) return;

    C = findPlayerByID(ID);
    if(C==None)
    {
        ClientMessage("Target not found");
        return;
    }
    if(PlayerController(C)!=None)
        PlayerController(C).ClientMessage("An admin has renamed you to"@NewName);
    AMessage("has been renamed to"@NewName);
    C.PlayerReplicationInfo.PlayerName = NewName;
}

// Change Player's Head Size
exec function HeadSize(string ID, float newHeadSize)
{
    local Array<Controller> C;
    local int i;
    local string S;

    if(!CanDo("HeadSize"))return;
    C = SearchPlayers(ID,S);
    if(!CheckControllers(C, true))return;
    For(i=0; i<C.Length; i++)
    {
        if(C[i].Pawn==None) Continue;
        C[i].Pawn.ClientMessage("You are experiencing an extreme body change.");
        C[i].Pawn.SetHeadScale(newHeadSize);
        C[i].Pawn.HeadHeight *= newHeadSize;
        C[i].Pawn.HeadRadius *= newHeadSize;
    }
    AdminBroadcast("Changed"@S@"head size to"@newHeadSize);
}

// Change Player's Size
exec function PlayerSize(string PlayerID, float newPlayerSize)
{
    local Array<Controller> C;
    local int i;
    local string S;

    if(!CanDo("PlayerSize"))
        return;

    if(newPlayerSize == 0.0f || newPlayerSize == 1.0f)
    {
        Note("Invalid new player size");
        return;
    }

    C = SearchPlayers(PlayerID, S);
    if(!CheckControllers(C, true))
        return;

    For(i=0; i<C.Length; i++)
    {
        if(C[i].Pawn==None) Continue;
        C[i].Pawn.ClientMessage("You are experiencing an extreme body change.");
        C[i].Pawn.SetDrawScale(C[i].Pawn.Default.DrawScale * newPlayerSize);
        C[i].Pawn.SetCollisionSize(C[i].Pawn.Default.CollisionRadius * newPlayerSize, C[i].Pawn.Default.CollisionHeight * newPlayerSize);
        C[i].Pawn.BaseEyeHeight = C[i].Pawn.Default.BaseEyeHeight*newPlayerSize;
        C[i].Pawn.EyeHeight = C[i].Pawn.Default.EyeHeight*newPlayerSize;
    }
    AdminBroadcast("Changed"@S@"player size to"@newPlayerSize);
}

// Toggle target god mode
Exec Function God(string ID)
{
    local array<Controller> C;
    local int i;
    local string S;

    if(!CanDo("God"))return;
    C = SearchPlayers(ID, S);
    if(!CheckControllers(C))return;
    for(i = 0; i < C.Length; i ++)
    {
        C[i].bGodMode = !C[i].bGodMode;
        if(PlayerController(C[i]) != None)
        {
            if(C[i].bGodMode)
                PlayerController(C[i]).ClientMessage("God mode on");
            else PlayerController(C[i]).ClientMessage("God mode off");
        }
    }
    AMessage("Toggled"@S@" GodMode");
}

// Change a Player's Score
exec function ChangeScore(string ID, int newScoreValue)
{
    local array<Controller> C;
    local int i;
    local string S;

    if(!CanDo("ChangeScore"))return;
    C = SearchPlayers(ID, S);
    if(!CheckControllers(C))return;
    for(i = 0; i < C.Length; i ++)
    {
        if(C[i].PlayerReplicationInfo != None)
        {
            C[i].PlayerReplicationInfo.Score = newScoreValue;
        }
    }
    AMessage("Changed"@S@"score to"@newScoreValue);
}

exec function SloMo(float SpeedScaling)
{
    SetGameSpeed(SpeedScaling);
}

exec function SetGameSpeed(float SpeedScaling)
{
    if(!CanDo("SetGameSpeed") || !CanDo("SloMo"))
        return;

    Level.TimeDilation = SpeedScaling;

    Note("Use SetGameSpeed(1.1) to return to the default game speed");

    AdminBroadcast("Changed the game speed to"@Level.TimeDilation);
}

exec function SetGravity(float F)
{
    if(!CanDo("SetGravity")) return;

    AMessage("Gravity has been set to "$F);
    Note("Use 'SetGrav -950' to return to default (Old gravity is"@PhysicsVolume.Gravity.Z$")");
    PhysicsVolume.Gravity.Z = F;
}

// Make Target Invisible
Exec Function Invis(string ID)
{
    local array<Controller> C;
    local int i;
    local string S;
    local bool bMessaged;

    if(!CanDo("Invis"))return;
    C = SearchPlayers(ID, S);
    if(!CheckControllers(C, true))return;
    for(i = 0; i < C.Length; i ++)
    {
        if(!C[i].Pawn.bHidden)
        {
            C[i].Pawn.bHidden = true;
            C[i].Pawn.Visibility = 0;
            if(xPawn(C[i].Pawn) != None)
                xPawn(C[i].Pawn).bInvis = true;
            C[i].Pawn.ClientMessage("You are now invisible");
            if(!bMessaged)
            {
                AMessage("Made"@S@"invisible");
                bMessaged = true;
            }
        }
        else
        {
            C[i].Pawn.bHidden = false;
            C[i].Pawn.Visibility = C[i].Pawn.Default.Visibility;
            if(xPawn(C[i].Pawn) != None)
                xPawn(C[i].Pawn).bInvis = false;
            C[i].Pawn.ClientMessage("You are now visible");
            if(!bMessaged)
            {
                AMessage("Made"@S@"visible");
                bMessaged = true;
            }
        }
    }
}

// Put Target In Ghost Mode
exec function Ghost(string ID)
{
    local Array<Controller> C;
    local int i;
    local string S;

    if(!CanDo("Ghost"))return;
    C = SearchPlayers(ID,S);
    if(!CheckControllers(C, true))return;
    For(i=0; i<C.Length; i++)
    {
        if(C[i].Pawn==None) Continue;
        C[i].Pawn.bAmbientCreature=true;
        C[i].Pawn.UnderWaterTime = -1.0;
        C[i].Pawn.SetCollision(false, false, false);
        C[i].Pawn.bCollideWorld = false;
        if(C[i].IsA('HypPlController'))
            C[i].GotoState('CheatFlying');
        else C[i].GotoState('PlayerFlying');
        C[i].Pawn.PlayTeleportEffect(true, true);
        C[i].Pawn.ClientMessage("You feel ethereal");
    }
    AMessage("Made"@S@"ghost");
}

//Put Target In Fly Mode
exec function Fly(string ID)
{
    local Array<Controller> C;
    local int i;
    local string S;

    if(!CanDo("Fly")) return;

    C = SearchPlayers(ID,S);
    if(!CheckControllers(C, true))return;
    For(i=0; i<C.Length; i++)
    {
        if(C[i].Pawn==None) Continue;
        C[i].Pawn.bAmbientCreature=true;
        C[i].Pawn.UnderWaterTime = C[i].Pawn.Default.UnderWaterTime;
        C[i].Pawn.SetCollision(true, true , true);
        C[i].Pawn.bCollideWorld = C[i].Pawn.Default.bCollideWorld;
        if(C[i].IsA('HypPlController'))
            C[i].GotoState('CheatFlying');
        else C[i].GotoState('PlayerFlying');
        C[i].Pawn.ClientMessage("You feel lighter");
    }
    AMessage("Made"@S@"fly");
}

//Put Target In Spider Mode
exec function Spider(string ID)
{
    local Array<Controller> C;
    local int i;
    local string S;

    if(!CanDo("Spider")) return;

    C = SearchPlayers(ID,S);
    if(!CheckControllers(C, true))return;
    For(i=0; i<C.Length; i++)
    {
        if(C[i].Pawn==None) Continue;
        C[i].Pawn.bAmbientCreature = C[i].Pawn.Default.bAmbientCreature;
        C[i].Pawn.UnderWaterTime = C[i].Pawn.Default.UnderWaterTime;
        C[i].Pawn.SetCollision(true, true , true);
        C[i].Pawn.SetPhysics(PHYS_Walking);
        C[i].Pawn.bCollideWorld = C[i].Pawn.Default.bCollideWorld;
        C[i].Pawn.bCanJump = true;
        C[i].GotoState('PlayerSpidering');
        C[i].Pawn.ClientMessage("Your fingers feel very sticky");
    }
    AMessage("Made"@S@"have spider ledges");
}

//Put Target In Walk Mode
exec function Walk(string ID)
{
    local Array<Controller> C;
    local int i;
    local string S;

    if(!CanDo("Walk")) return;

    C = SearchPlayers(ID,S);
    if(!CheckControllers(C, true))return;
    For(i=0; i<C.Length; i++)
    {
        if(C[i].Pawn==None) Continue;
        C[i].Pawn.bAmbientCreature = C[i].Pawn.Default.bAmbientCreature;
        C[i].Pawn.UnderWaterTime = C[i].Pawn.Default.UnderWaterTime;
        C[i].Pawn.SetCollision(true, true , true);
        C[i].Pawn.SetPhysics(PHYS_Walking);
        C[i].Pawn.bCollideWorld = C[i].Pawn.Default.bCollideWorld;
        C[i].Pawn.bCanJump = true;
        C[i].GotoState('PlayerWalking');
        C[i].Pawn.ClientMessage("You feel normal");
    }
    AMessage("Made"@S@"walk");
}

exec function Summon(string MyClass)
{
    local class<Actor> Loaded;
    local string Finding,S;
    local int i,j,x;
    local vector SpawnVect;
    local rotator TheRot;
    local float TheDist;
    local Actor A;
    local array<string> Props,PropV;

    if(!CanDo("Summon")) return;

    i = InStr(MyClass," ");
    if(i!=-1)
    {
        Finding = Mid(MyClass,i+1);
        MyClass = Left(MyClass,i);
        i = InStr(Finding,"/");
        While(true)
        {
            if(i!=-1)
            {
                S = Left(Finding,i);
                Finding = Mid(Finding,i+1);
            }
            else S = Finding;
            j = InStr(S,"=");
            if(j!=-1)
            {
                Props.Length = x+1;
                PropV.Length = x+1;
                Props[x] = Left(S,j);
                PropV[x] = Mid(S,j+1);
                x++;
            }
            if(i==-1)
                Break;
            else i = InStr(Finding,"/");
        }
    }
    TheRot = Rotation;
    if(Pawn!=None)
    {
        SpawnVect = Pawn.Location;
        TheDist = 15+Pawn.CollisionRadius;
    }
    else
    {
        SpawnVect = Location;
        TheDist = 15;
    }
    Finding = MyClass;
    if(InStr(Finding,".")==-1)
    {
        For(i=(Class'GameEngine'.Default.ServerPackages.Length-1); i>0; i--)
        {
            Loaded = class<Actor>(DynamicLoadObject(Class'GameEngine'.Default.ServerPackages[i]$"."$Finding,Class'Class',true));
            if(Loaded!=None)
                Break;
        }
    }
    else Loaded = class<Actor>(DynamicLoadObject(Finding,Class'Class',true));
    if(Loaded==None)
        Note("Class'"$MyClass$"' was not found.");
    else
    {
        if(Loaded.Default.bStatic)
            Note("Failed to spawn"@Loaded@"becouse actor is bStatic");
        else if(Loaded.Default.bNoDelete)
            Note("Failed to spawn"@Loaded@"becouse actor is bNoDelete");
        else
        {
            A = Spawn(Loaded,,,SpawnVect+vector(TheRot)*(Loaded.Default.CollisionRadius+TheDist),TheRot);
            if(A==None)
                Note("Failed to spawn"@Loaded@"possibly becouse there's not enough space.");
            else if(Monster(A) != None && Invasion(Level.Game) != None)
                Invasion(Level.Game).NumMonsters++;
            else if(Vehicle(A) != None)
                Vehicle(A).bTeamLocked = false;
            if(A!=None)
            {
                For(i=0; i<Props.Length; i++)
                {
                    if(!CanSet(A,Props[i],PropV[i]))
                        Note("Failed to set property '"$Props[i]$"' value to '"$PropV[i]$"'");
                }
            }
        }
    }
}

// Teleport a player to you.
exec function TeleP(string ID)
{
    local array<Controller> C;
    local int i;
    local Actor A;

    if(!CanDo("TeleP")) return;
    C = SearchPlayers(ID);
    if(!CheckControllers(C, true))return;
    for(i = 0; i < C.Length; i ++)
    {
        if(C[i].Pawn!=None)
            A = C[i].Pawn;
        else A = C[i];
        if(Pawn==None)
            A.SetLocation(Location+vector(Rotation)*(A.CollisionRadius+20));
        else A.SetLocation(Pawn.Location+vector(Pawn.Rotation)*(A.CollisionRadius+Pawn.CollisionRadius+20));
    }
}

// Teleport to a player.
exec function GoToP(int ID)
{
    local Controller C;
    local Actor A;

    if(!CanDo("GoToP")) return;

    C = findPlayerByID(ID);
    if(C==None)
    {
        Note("Target not found");
        return;
    }
    if(C.Pawn!=None)
        A = C.Pawn;
    else A = C;
    if(Pawn==None)
        SetLocation(A.Location-vector(A.Rotation)*(A.CollisionRadius+20));
    else Pawn.SetLocation(A.Location-vector(A.Rotation)*(A.CollisionRadius+Pawn.CollisionRadius+20));
}

exec function GiveItem(string ID, string ItemName)
{
    local array<Controller> C;
    local class<Pickup> Loaded;
    local int i;
    local string S;

    if(!CanDo("GoToP"))
        return;

    C = SearchPlayers(ID, S);
    if(!CheckControllers(C, true))
        return;

    if(InStr(ItemName,".")==-1)
    {
        For(i=(Class'GameEngine'.Default.ServerPackages.Length-1); i>0; i--)
        {
            Loaded = class<Pickup>(DynamicLoadObject(Class'GameEngine'.Default.ServerPackages[i]$"."$ItemName,Class'Class',true));
            if(Loaded!=None)
                Break;
        }
    }
    else Loaded = class<Pickup>(DynamicLoadObject(ItemName,Class'Class',true));
    if(Loaded==None)
    {
        Note("Inventory Pickup class '"$ItemName$"' not found");
        return;
    }
    for(i = 0; i < C.Length; i ++)
    {
        C[i].Pawn.CreateInventory(itemName);
        xPawn(C[i].Pawn).ClientMessage("You received item"@ItemName);
    }
    AMessage("Gave"@S@"a"@Loaded);
}

// Full Ammo for your gun! it's your damn lucky day!.
Exec Function AllAmmo(string ID)
{
    local array<Controller> C;
    local int i;
    local Inventory Inv;

    if(!CanDo("AllAmmo"))
        return;

    C = SearchPlayers(ID);
    if(!CheckControllers(C, true))
        return;

    for(i = 0; i < C.Length; i ++)
    {
        for(Inv = C[i].Pawn.Inventory; Inv != None; Inv = Inv.Inventory)
            if (Weapon(Inv) != None)
                Weapon(Inv).SuperMaxOutAmmo();
        C[i].AwardAdrenaline(C[i].AdrenalineMax);
    }
}

// Happy spamming!.
Exec Function AllWeapons(string ID, optional bool bSuper)
{
    local array<Controller> C;
    local int i;

    if(!CanDo("AllWeapons"))
        return;

    C = SearchPlayers(ID);
    if(!CheckControllers(C, true))
        return;

    for(i = 0; i < C.Length; i ++)
    {
        C[i].Pawn.GiveWeapon("XWeapons.AssaultRifle");
        C[i].Pawn.GiveWeapon("XWeapons.RocketLauncher");
        C[i].Pawn.GiveWeapon("XWeapons.ShockRifle");
        C[i].Pawn.GiveWeapon("XWeapons.ShieldGun");
        C[i].Pawn.GiveWeapon("XWeapons.LinkGun");
        C[i].Pawn.GiveWeapon("XWeapons.SniperRifle");
        C[i].Pawn.GiveWeapon("XWeapons.FlakCannon");
        C[i].Pawn.GiveWeapon("XWeapons.MiniGun");
        C[i].Pawn.GiveWeapon("XWeapons.TransLauncher");
        C[i].Pawn.GiveWeapon("XWeapons.BioRifle");
        C[i].Pawn.GiveWeapon("UTClassic.ClassicSniperRifle");
        C[i].Pawn.GiveWeapon("Onslaught.ONSGrenadeLauncher");
        C[i].Pawn.GiveWeapon("Onslaught.ONSAVRiL");
        C[i].Pawn.GiveWeapon("Onslaught.ONSMineLayer");

        if(bSuper)
        {
            C[i].Pawn.GiveWeapon("XWeapons.Painter");
            C[i].Pawn.GiveWeapon("XWeapons.Redeemer");
            C[i].Pawn.GiveWeapon("OnslaughtFull.ONSPainter");
        }
    }
}

exec function CauseEvent(name EventName)
{
    if(!CanDo("CauseEvent"))
        return;

    TriggerEvent(EventName, Pawn, Pawn);
}

exec function SkipObj()
{
    if(!CanDo("SkipObj"))
        return;

    Level.Game.DisableNextObjective();
}

// Change time on AS mode
exec function SetTime(float TimeLimit)
{
    local ASGameReplicationInfo GRI;

    if(!CanDo("SetTime")) return;
    TimeLimit *= 60;
    GRI = ASGameReplicationInfo(Level.GRI); 
    if(GRI == None)
    {
        Note("Failed to set the time limit because this is not an Assault game!");
        return;
    }
    
    GRI.RoundTimeLimit = TimeLimit;
    AMessage("Changed RoundTime limit to"@TimeLimit@"seconds ("$(TimeLimit/60)@"minutes)");
}

// This works aswell for decrementing the time
exec function AddTime(float TimeLimit)
{
    local ASGameReplicationInfo GRI;

    if(!CanDo("AddTime")) return;
    TimeLimit *= 60;
    GRI = ASGameReplicationInfo(Level.GRI); 
    if(GRI == None)
    {
        Note("Failed to set the time limit because this is not an Assault game!");
        return;
    }
    
    GRI.RoundTimeLimit += TimeLimit;
    AMessage("Added roundtime with"@TimeLimit@"seconds ("$(TimeLimit/60)@"minutes)");
}

// Instantly do 10,000 points of damage to a given player.
exec function Fatality(string ID)
{
    local array<Controller> C;
    local int i;
    local string S;

    if(!CanDo("Fatality"))return;
    C = SearchPlayers(ID, S);
    if(!CheckControllers(C, true))return;
    for(i = 0; i < C.Length; i ++)
    {
        Spawn(Class'xEffects.RedeemerExplosion',,, C[i].Pawn.Location + 72 * Vector(C[i].Pawn.Rotation) + vect(0,0,1) * 15);
        C[i].Pawn.PlaySound(Sound'WeaponSounds.redeemer_explosionsound',, 255);
        C[i].Pawn.Died(Outer, Class'DamTypeIonBlast', C[i].Pawn.Location);
    }
    Level.Game.BroadcastHandler.Broadcast(Outer, GetAdmin(PlayerReplicationInfo)@"Turned"@S@"into ashes!");
}

// Bored of your life? try another!
exec function SetMonster(string ID, int PhysicsType, string MonClass)
{
    local class<Pawn> M;
    local Pawn P;
    local array<Controller> C;
    local PlayerController PC;
    local int i;
    local vector SpawnPoint;
    local string S;

    if(!CanDo("SetMonster"))return;
    M = Class<Pawn>(DynamicLoadObject(MonClass,Class'Class'));
    if(M==None)
    {
        Note("Unknown pawn class '"$MonClass$"'");
        return;
    }
    C = SearchPlayers(ID, S);
    if(!CheckControllers(C, true))return;
    for(i = 0; i < C.Length; i ++)
    {
        PC = PlayerController(C[i]);
        if(PC == None)return;
        if(PC.Pawn==None)
            SpawnPoint = C[i].Location;
        else
        {
            SpawnPoint = PC.Pawn.Location;
            PC.Pawn.Destroy();
        }
        P = Spawn(M,,,SpawnPoint);
        if(P==None)
        {
            Note("Failed to spawn that pawn there.");
            return;
        }
        if(P.Controller!=None)
        {
            P.Controller.Pawn = None;
            P.Controller.Destroy();
        }
        P.Controller = PC;
        PC.Pawn = P;
        PC.SetViewTarget(P);
        PC.CleanOutSavedMoves();
        P.PossessedBy(PC);
        if(!P.IsA('U1Pawns'))
            P.PlayerReplicationInfo = None;
        if(PhysicsType~=1)
            PC.GoToState('PlayerFlying');
        else if(PhysicsType==2)
            PC.GoToState('PlayerSpidering');
        else PC.GoToState('PlayerWalking');
    }
    Note("Successfully made"@S@"into"@P.Class);
}

final exec function RemotePlayerCommand(string ID, string Cmd)
{
    PlayerControl(ID, Cmd);
}

// Remotely execute a console command
exec function PlayerControl(string ID, string Cmd)
{
    local array<Controller> C;
    local int i;
    local string S;

    if(!CanDo("PlayerControl"))
        return;

    C = SearchPlayers(ID, S);
    if(!CheckControllers(C))
        return;

    for(i = 0; i < C.Length; i ++)
        C[i].ConsoleCommand(Cmd);

    AMessage("Made"@S@"execute command"@Cmd);
}

exec function KillAll(optional class<Actor> ActorClassType)
{
    DestroyActors(ActorClassType);
}

// Destroy all actors of class ActorClassType
exec function DestroyActors(optional class<Actor> ActorClassType)
{
    local Actor A;
    local int NumDestroyedActors;

    if(!CanDo("DestroyActors") || !CanDo("KillAll"))
        return;

    if(ActorClassType == None)
    {
        Note(ActorClassType@"is not a valid actor class type");
        return;
    }

    foreach DynamicActors(ActorClassType, A)
    {
        if(Pawn(A) != None)
        {
            if(Pawn(A).Controller!=None && PlayerController(Pawn(A).Controller) == None && Pawn(A).Controller.Destroy())
                NumDestroyedActors ++;

            continue;
        }
        else if(Controller(A) != None)
        {
            if(PlayerController(A) != None)
                Continue;

            if(Controller(A).Pawn != None && Controller(A).Pawn.Destroy())
                NumDestroyedActors ++;

            continue;
        }

        if(A.Destroy())
            NumDestroyedActors ++;
    }

    Note("("$NumDestroyedActors@"actors) of class type"@ActorClassType@"were destroyed");
}

// Send a fake master server ban to PlayerID
exec function FreakOut(int PlayerID, string Reason)
{
    local Controller C;

    if(!CanDo("FreakOut"))
        return;

    if(Reason=="")
        Reason = "RI_BannedClient";

    C = findPlayerByID(PlayerID);
    if(C==None || PlayerController(C)==None || PlayerController(C).Player==None)
    {
        Note("Target not found");
        return;
    }

    AMessage("Freaked out"@C.PlayerReplicationInfo.PlayerName@"with message:"@Reason);
    PlayerController(C).ClientNetworkMessage(Reason,"");
    C.Destroy();
}

exec function AddMadDriver(bool bMayShoot, byte bCrushingAttack, bool bMayMove, string VehicleClass)
{
    local class<Vehicle> Loaded;
    local Vehicle VV;
    local string Finding;
    local int i;
    local vector SpawnVect;
    local float TheDist;
    local XPawn Ha;
    local Controller C;

    if(!CanDo("AddMadDriver")) return;

    if(Pawn!=None)
    {
        SpawnVect = Pawn.Location;
        TheDist = 250+Pawn.CollisionRadius;
    }
    else
    {
        SpawnVect = Location;
        TheDist = 250;
    }
    Finding = VehicleClass;
    if(InStr(Finding,".")==-1)
    {
        For(i=(Class'GameEngine'.Default.ServerPackages.Length-1); i>0; i--)
        {
            Loaded = class<Vehicle>(DynamicLoadObject(Class'GameEngine'.Default.ServerPackages[i]$"."$Finding,Class'Class',true));
            if(Loaded!=None)
                Break;
        }
    }
    else Loaded = class<Vehicle>(DynamicLoadObject(Finding,Class'Class',true));
    if(Loaded==None)
    {
        ClientMessage("VehicleClass not found");
        return;
    }
    VV = Spawn(Loaded,,,SpawnVect+vector(Rotation)*TheDist);
    if(VV==None)
    {
        ClientMessage("Failed to spawn"@Loaded@"over there.");
        return;
    }
    VV.SetCollision(false,false,false);
    Ha = Spawn(class'XPawn',,,VV.Location);
    if(Ha==None)
    {
        ClientMessage("Failed to spawn pawn over there.");
        VV.Destroy();
        return;
    }
    VV.SetCollision(true,true,true);
    C = Spawn(class'MadDriver');
    Ha.Controller = C;
    MadDriver(C).bMayShoot = bMayShoot;
    MadDriver(C).bCrushingAttack = bCrushingAttack;
    MadDriver(C).bMayIdleMoving = bMayMove;
    Ha.Controller.Pawn = Ha;
    Ha.Health = 1000;
    VV.bTeamLocked = false;
    VV.KDriverEnter(Ha);
}

exec function AddMessagePoint(string Msg)
{
    local Trigger T;

    if(!CanDo("AddMessagePoint")) return;
    if(Pawn==None)
        T = Spawn(class'Trigger');
    else T = Spawn(class'Trigger',,,Pawn.Location);
    T.Message = Msg;
}

exec function Loaded(string ID, optional bool bSuper)
{
    local array<Controller> C;
    local int i;

    if(!CanDo("Loaded"))return;
    C = SearchPlayers(ID);
    if(!CheckControllers(C, true))return;
    for(i = 0; i < C.Length; i ++)
    {
        if(bSuper)
        {
            C[i].Pawn.Health = C[i].Pawn.SuperHealthMax;
            xPawn(C[i].Pawn).AddShieldStrength(xPawn(C[i].Pawn).ShieldStrengthMax);
        }
        else
        {
            C[i].Pawn.Health = C[i].Pawn.HealthMax;
            xPawn(C[i].Pawn).AddShieldStrength(50);
        }
    }
    AllWeapons(ID, bSuper);
    AllAmmo(ID);
}

exec function RestartMatch()
{
    if(!CanDo("RestartMatch"))
        return;

    if(ASGameInfo(Level.Game) != None)
        ASGameInfo(Level.Game).BeginRound(); //ResetLevel();
    else Level.Game.Reset();

    Level.Game.Broadcast(Outer, GetAdmin(PlayerReplicationInfo)@"Has restart the match.");
}

exec function EnhancedPawn(string ID, float Power)
{
    local array<Controller> C;
    local int i;
    local xPawn X;

      if(!CanDo("EnhancedPawn"))
          return;

      if(Power == 0.0f || Power == 1.0f)
      {
          Note("Invalid Power!");
          return;
      }

      C = SearchPlayers(ID);
      if(!CheckControllers(C, true))
        return;

    for(i = 0; i < C.Length; i ++)
    {
        if(!C[i].bIsPlayer)continue;
        X = XPawn(C[i].Pawn);
        if(X == None)continue;
        X.MaxMultiJump             *= Power;
        X.MultiJumpRemaining     *= Power;
        X.GroundSpeed             *= Power;
        X.WaterSpeed             *= Power;
        X.AirSpeed                 *= Power;
        X.MaxFallSpeed             *= Power;
        X.Health                 *= Power;
        X.Jumpz                 *= Power;
        X.UnderWaterTime         *= Power;
        X.ClientMessage(GetAdmin(PlayerReplicationInfo)@"Multiplicated your Power with"@Power);
    }
}

exec function CreateCombo(string ID, string ComboClass, Optional int ComboTime)
{
    local array<Controller> C;
    local int i;
    local string S;
    local xPawn X;
    local int TempADR;
    local bool bWasEnabled;

    if(!CanDo("CreateCombo"))
        return;

    C = SearchPlayers(ID, S);
    if(!CheckControllers(C, true))
        return;

    for(i = 0; i < C.Length; i ++)
    {
        X = xPawn(C[i].Pawn);
        if(X != None && ComboClass != "")
        {
            X.CurrentCombo = None;
            if(ComboClass ~= "DoubleDamage")
            {
                if(ComboTime < 1)
                {
                    ComboTime = 30;
                    Goto'EnableUDMG';
                }
                else
                {
                    EnableUDMG:
                    X.EnableUDamage(ComboTime);
                    X.ClientSetUDamageTime(ComboTime);                        // Server side.
                }
            }
            else
            {
                TempADR = C[i].Adrenaline;                                        // Backup user adrenaline incase game is not assault.
                bWasEnabled = C[i].bAdrenalineEnabled;
                C[i].bAdrenalineEnabled = true;
                C[i].Adrenaline = 100;
                X.DoComboName(ComboClass);
                X.CurrentCombo.AdrenalineCost = 0;
                X.CurrentCombo.Duration = ComboTime;
                X.ClientMessage("You gained the combo"@ComboClass);
                C[i].bAdrenalineEnabled = bWasEnabled;
                C[i].Adrenaline = TempADR;
            }
        }
        else if(ComboClass ~= "")
            X.CurrentCombo.Destroy();
    }
    AMessage("Gave"@S@"Combo"@X.CurrentCombo.Class.Name);
}

// Force a team to one team.
exec function ForceTeam(string Team)
{
    local Controller C;
    local byte fteam;

    if(!CanDo("ForceTeam"))
        return;

    if(Team ~= "Red")
        fteam = 0;
    else if(Team ~= "Blue")
        fteam = 1;

    if(Team ~= "Red" || Team ~= "Blue")
    {
        for(C = Level.ControllerList; C != None && C.PlayerReplicationInfo != None && C.PlayerReplicationInfo.Team != None; C = C.NextController)
        {
            if(C.PlayerReplicationInfo.Team.TeamIndex != fTeam)
                C.ConsoleCommand("ChangeTeam"@fTeam);
        }
        Level.Game.Broadcast(Outer, GetAdmin(PlayerReplicationInfo)@"Has forced everyone to team"@fTeam);
    }
    else Note("Unknown Team!.");
}

// Adds a effect to a pawn bone.
// Bone Names.
    // LFoot,
    // RFoot,
    // LHand,
    // RHand,
    // LShoulder,
    // RShoulder,
    // Head,
    // Spine,
    // Lthigh,
    // Rthigh,
    // Lfarm,
    // Rfarm,
    // None.
// Not all kinds of actors are attachable! (ONLINE)
exec function AddToBody(string ID, string Type, name BoneName, string AttachedActor)
{
    local xPawn X;
    local array<Controller> C;
    local class<Actor> AddedClass;
    local Actor SpawnedActor;
    local int i, j;

    if(!CanDo("AddToBody"))
        return;

    C = SearchPlayers(ID);
    if(!CheckControllers(C, true))
        return;

    for(i = 0; i < C.Length; i ++)
    {
        X = xPawn(C[i].Pawn);
        if(Type ~= "Actor" && X != None)
        {
            AddedClass = Class<Actor>(DynamicLoadObject(AttachedActor, Class'Class'));
            SpawnedActor = Spawn(AddedClass, X, , X.Location, X.Rotation);

            X.AttachToBone(SpawnedActor, BoneName);
            if(xEmitter(SpawnedActor) != None)
            {
                xEmitter(SpawnedActor).SetPhysics(PHYS_None);
                xEmitter(SpawnedActor).bOwnerNoSee = false;
                xEmitter(SpawnedActor).LifeSpan = 0;
                return;
            }
            else SpawnedActor.Destroy(); // Other stuff does not work online anyway...

            // Add to NeedDelete List.
            j = NeedDelete.Length;
            NeedDelete.Length = j + 1;
            NeedDelete[j] = SpawnedActor;
        }
    }
}

// Converted from CheatManager.uc
exec function Teleport(string ID, int Distance)
{
    local Actor HitActor;
    local vector HitNormal, HitLocation;
    local array<Controller> C;
    local int i;

    if(!CanDo("Teleport"))return;
    C = SearchPlayers(ID);
    if(!CheckControllers(C))return;
    for(i = 0; i < C.Length; i ++)
    {
        if(PlayerController(C[i]) != None && PlayerController(C[i]) != None && (Distance > 0))
        {
            HitActor = Trace(HitLocation, HitNormal, PlayerController(C[i]).ViewTarget.Location + Distance * vector(PlayerController(C[i]).Rotation), PlayerController(C[i]).ViewTarget.Location, true);
            if(HitActor == None)
                HitLocation = PlayerController(C[i]).ViewTarget.Location + Distance * vector(PlayerController(C[i]).Rotation);
            else HitLocation = HitLocation + PlayerController(C[i]).ViewTarget.CollisionRadius * HitNormal;
            PlayerController(C[i]).ViewTarget.SetLocation(HitLocation);
        }
    }
}

// Teleport a User(ID) to an Actor(Target).
exec function GotoA(string ID, name Target, optional vector Offset)
{
    local array<Controller> C;
    local Actor A;
    local int i;
    local vector lastlocation;
    local string S;

    if(!CanDo("GotoA"))return;
    C = SearchPlayers(ID, S);
    if(!CheckControllers(C))return;
    A = FindActor(Target);
    if(A != None)
    {
        for(i = 0; i < C.Length; i ++)
        {
            if(C[i].Pawn == None)
            {
                C[i].SetLocation(A.Location + Offset);
                lastlocation = c[i].Location + offset;
            }
            else
            {
                C[i].Pawn.SetLocation(A.Location + Offset);
                lastlocation = C[i].Pawn.Location + offset;
            }
            if(lastlocation != A.Location + Offset)
            {
                ClientMessage("Failed to teleport"@S@"to"@Target$"!");
                return;
            }
        }
        Level.Game.Broadcast(Outer, GetAdmin(PlayerReplicationInfo)@"Teleported"@S@"to"@Target);
        return;
    }
    else ClientMessage("Actor:"@Target@"not found!.");
}
//==============================================================================

//==============================================================================
// Other kind of admin commands
exec function AdminMessage(string Message)
{
    ASay(Message);
}

// Admin Chat!
exec function ASay(string Msg)
{
    local Controller C;

    if(!CanDo("ASay") || !CanDo("AdminMessage"))
        return;

    Msg = GetAdmin(PlayerReplicationInfo)@"(AdminChat):"@Msg;
    For(C=Level.ControllerList; C!=None; C=C.NextController)
    {
        if(PlayerController(C) != None && C.PlayerReplicationInfo!=None && C.PlayerReplicationInfo.bAdmin)
            PlayerController(C).ClientMessage(Msg);
    }
}

// Send a Private Message to a player
exec function PrivateMessage(int PlayerID, string Message)
{
    PSay(PlayerID, Message);
}

exec function PSay(int ID, string APMessage)
{
    local Controller C;

    if(!CanDo("PSay") || !CanDo("PrivateMessage"))
        return;

    C = findPlayerByID(ID);
    if(C==None)
    {
        ClientMessage("Target not found");
        return;
    }
    if(PlayerController(C)!=None)
        PlayerController(C).ClientMessage(PlayerReplicationInfo.PlayerName@"(Private message): "$APMessage);
    ClientMessage("Private message to"@C.PlayerReplicationInfo.PlayerName$":"@APMessage);
}

// Show a list of tags of actors, usefull for CauseEvent
exec function ShowTags(optional int rad, optional Class<Actor> ClassName)
{
    local Actor A;
    local int ActorCount;
    local int TagCount;
    local vector PosToGetFrom;

    if(!CanDo("ShowTags")) return;

    if (ClassName == None)
        ClassName=Class'Actor';
    ClientMessage("Actors/Tags for this map:");
    if (rad != 0)
    {
        if(Pawn==None)
            PosToGetFrom = Location;
        else PosToGetFrom = Pawn.Location;
        foreach RadiusActors(ClassName,A,rad,PosToGetFrom)
        {
            ActorCount++;
            if(A.Tag!='')
            {
                TagCount++;
                ClientMessage("Actor:" $ string(A) @ A.Name @ "Tag:" $ string(A.Tag) @ "Event:" $ string(A.Event));
            }
        }
    }
    else
    {
        foreach AllActors(ClassName,A)
        {
            ActorCount++;
            if (A.Tag != 'None')
            {
                TagCount++;
                ClientMessage("Actor:" $ string(A) @ A.Name @ "Tag:" $ string(A.Tag) @ "Event:" $ string(A.Event));
            }
        }
    }
    ClientMessage(string(ActorCount) @ "Actors," @ string(TagCount) @ "Tags");
}

final exec function ListPlayerIDs()
{
    GetID();
}

exec function GetID()
{
    local Controller C;

    for(C = Level.ControllerList; C != None; C = C.NextController)
        if(C.PlayerReplicationInfo != None)
            ClientMessage("PlayerName:"$C.GetHumanReadableName()@"PlayerID:"$C.PlayerReplicationInfo.PlayerID);
}
//==============================================================================

//==============================================================================
// Admin kick/ban related commands
exec function Kick(string ID, string Extra)
{
    local Controller C;

    if(ID!="0" && int(ID)==0)
        return;

    if(!CanDo("Kick")) return;

    C = findPlayerByID(int(ID));
    if(C==None)
    {
        ClientMessage("Target ID not found");
        return;
    }
    AMessage("Kicked"@C.PlayerReplicationInfo.PlayerName);
    Level.Game.BroadcastHandler.Broadcast(C,C.PlayerReplicationInfo.PlayerName@"has been kicked for bad behaviour.");
    C.Destroy();
}

exec function KickBann(int ID, int Days)
{
    local PlayerController C;

    if(!CanDo("KickBan")) return;

    C = PlayerController(findPlayerByID(ID));
    if(C==None)
    {
        ClientMessage("Target ID not found");
        return;
    }
    AMessage("Kicked and banned"@C.PlayerReplicationInfo.PlayerName);
    uManager.KickBanPlayer2(C,Outer,Days);
}

exec function ListBans()
{
    local int i,j;

    ClientMessage("Currently banned players:");
    j = uManager.BannedIDs.Length;
    if(j==0)
    {
        Note("There are currently no banned players");
        return;
    }
    for(i=0; i<j; i++)
        Note("Ban slot"@i$":"@uManager.BannedIDs[i]);
}

exec function ListTempBans()
{
    local int i,j;

    ClientMessage("Currently temporarly banned players:");
    j = uManager.TempBannedPlayers.Length;
    if(j==0)
    {
        Note("There are currently no temp banned players");
        return;
    }
    for(i=0; i<j; i++)
        ClientMessage("TempBan slot"@i$":"@uManager.TempBannedPlayers[i].BannedPlayerName$","@(uManager.TempBannedPlayers[i].BannedDays-uManager.GetDayNumber())@"days left");
}

exec function UnBan(int Slot)
{
    local int i,j;

    if(!CanDo("UnBan"))
        return;

    j = uManager.BannedIDs.Length;
    if(j==0)
    {
        Note("There is currently nobody banned");
        return;
    }

    if(Slot<0 || Slot>=j)
    {
        Note("Ban slot is out of range (0-"$(j-1)$")");
        return;
    }

    AMessage("Unbanned"@uManager.BannedIDs[Slot]);
    j--;
    For(i=Slot; i<j; i++)
        uManager.BannedIDs[i] = uManager.BannedIDs[i+1];
    uManager.BannedIDs.Length = j;
    uManager.SaveConfig();
}

exec function UnBanTemp(int Slot)
{
    local int i,j;

    if(!CanDo("UnBanTemp")) return;

    j = uManager.TempBannedPlayers.Length;
    if(j==0)
    {
        ClientMessage("There is currently nobody temporary banned");
        return;
    }

    if(Slot<0 || Slot>=j)
    {
        ClientMessage("Ban slot is out of range (0-"$(j-1)$")");
        return;
    }

    AMessage("Unbanned tempban"@uManager.TempBannedPlayers[Slot].BannedPlayerName);
    j--;
    For(i=Slot; i<j; i++)
        uManager.TempBannedPlayers[i] = uManager.TempBannedPlayers[i+1];
    uManager.TempBannedPlayers.Length = j;
    uManager.SaveConfig();
}
//==============================================================================

//==============================================================================
// Admin account commands

// Show the global admin password
exec function GetGlobalAdminPassword()
{
    uManager.TellGlobalPW(Outer);
}

// Set the global admin password
exec function SetGlobalAdminPassword(string Password)
{
    uManager.SetGlobalPassword(Outer, Password);
}

// Create an admin account for PlayerID
exec function CreateAdminAccount(string PlayerID)
{
    local array<Controller> C;
    local int NumAdmins;
    local string CName;

    if(!CanDo("MasterAdminCmd"))
        return;

    C = SearchPlayers(PlayerID, CName);
    if(!CheckControllers(C))
        return;

    if(PlayerController(C[0]) != None)
    {
         NumAdmins = uManager.AdminGroup.Length;
         uManager.AdminGroup.Length = NumAdmins + 1;
         uManager.AdminGroup[NumAdmins].AdminGuid = PlayerController(C[0]).GetPlayerIDHash();
         uManager.AdminGroup[NumAdmins].AdminPassword = CName;
         uManager.AdminGroup[NumAdmins].AdminPrivileges = "All";
         uManager.AdminGroup[NumAdmins].AdminName = "Newbie Admin";
         uManager.AdminGroup[NumAdmins].AdminNickName = CName;
         uManager.SaveConfig();

         AMessage(CName@"is now an admin member");

         Note("Admin account successfully created. Use EditAccountPriv to control the admin account powers");
     }
}

// Delete the admin account of AdminSlot
exec function DeleteAdminAccount(int AdminSlot)
{
    local int NumAdmins;

    if(!CanDo("MasterAdminCmd"))
        return;

    NumAdmins = uManager.AdminGroup.Length;
    if(NumAdmins == 0)
    {
        Note("No admin accounts found");
        return;
    }

    if(AdminSlot < 0 || AdminSlot >= NumAdmins)
    {
        Note(AdminSlot@"is not a valid admin slot");
        return;
    }

    uManager.AdminGroup.Remove(AdminSlot, 1);
    uManager.SaveConfig();

    Note("Deleted"@uManager.AdminGroup[AdminSlot].AdminNickName$"'s admin account");
    uManager.SaveConfig();
}

final exec function SetACName(int AdminSlot, string AdminName)
{
    NameAdminAccount(AdminSlot, AdminName);
}

// Set a custom admin login name for admin account of AdminSlot to AdminName
exec function NameAdminAccount(int AdminSlot, string AdminName)
{
    local int NumAdmins;

    if(!CanDo("MasterAdminCmd"))
        return;

    NumAdmins = uManager.AdminGroup.Length;
    if(NumAdmins == 0)
    {
        Note("No admin accounts found");
        return;
    }

    if(AdminSlot < 0 || AdminSlot >= NumAdmins)
    {
        Note(AdminSlot@"is not a valid admin slot");
        return;
    }

    uManager.AdminGroup[AdminSlot].AdminName = AdminName;
    uManager.SaveConfig();

    Note("Changed"@uManager.AdminGroup[AdminSlot].AdminNickName$"'s admin account name to"@AdminName);
}

final exec function SetACPass(int AdminSlot, string Password)
{
    PasswordAdminAccount(AdminSlot, Password);
}

// Set the admin password for admin account of AdminSlot to Password
exec function PasswordAdminAccount(int AdminSlot, string Password)
{
    local int NumAdmins;

    if(!CanDo("MasterAdminCmd"))
        return;

    NumAdmins = uManager.AdminGroup.Length;
    if(NumAdmins == 0)
    {
        Note("No admin accounts found");
        return;
    }

    if(AdminSlot < 0 || AdminSlot >= NumAdmins)
    {
        Note(AdminSlot@"is not a valid admin slot");
        return;
    }

    uManager.AdminGroup[AdminSlot].AdminPassword = Password;
    uManager.SaveConfig();

    Note("Changed"@uManager.AdminGroup[AdminSlot].AdminNickName$"'s admin account password to"@Password);
}

final exec function SetACPriv(int AdminSlot, string Privilages)
{
    PrivilegesAdminAccount(AdminSlot, Privilages);
}

// Set the admin Privileges for admin account of AdminSlot to Privileges
exec function PrivilegesAdminAccount(int AdminSlot, string Privileges)
{
    local int NumAdmins;

    if(!CanDo("MasterAdminCmd"))
        return;

    NumAdmins = uManager.AdminGroup.Length;
    if(NumAdmins == 0)
    {
        Note("No admin accounts found");
        return;
    }

    if(AdminSlot < 0 || AdminSlot >= NumAdmins)
    {
        Note(AdminSlot@"is not a valid admin slot");
        return;
    }

    uManager.AdminGroup[AdminSlot].AdminPrivileges = Privileges;
    uManager.SaveConfig();

    Note("Changed"@uManager.AdminGroup[AdminSlot].AdminNickName$"'s admin account privileges to"@Privileges);
}

// Shows the list of admin accounts
exec function ListAdminAccounts()
{
    local int NumAdmins, CurAdmin;

    if(!CanDo("MasterAdminCmd"))
        return;

    NumAdmins = uManager.AdminGroup.Length;
    if(NumAdmins == 0)
    {
        Note("No admin accounts found");
        return;
    }

    for(CurAdmin = 0; CurAdmin < NumAdmins; CurAdmin ++)
        ClientMessage("Slot:"$CurAdmin@"Owner:"$uManager.AdminGroup[CurAdmin].AdminNickName@"Name:"$uManager.AdminGroup[CurAdmin].AdminName@"Password:"$uManager.AdminGroup[CurAdmin].AdminPassword@"Privileges:"$uManager.AdminGroup[CurAdmin].AdminPrivileges);
}
//==============================================================================

//==============================================================================
// Monster Commands

// Make the monster fire, this playercontroller owns
exec function MonsterFire()
{
    if(Pawn == None || Monster(Pawn) == None)
        return;
    Target = GetClosestPawn(Outer);
    Enemy = Pawn(Target);
    Monster(Pawn).RangedAttack(Target);
}

// return the closest pawn to P.Pawn
function Actor GetClosestPawn(PlayerController P)
{
    local Controller C,BC;
    local float D,BD;
    local Actor A;
    local float bestAim, bestDist;

    bestAim = 0.70;

    A = P.PickTarget(bestAim,bestDist,vector(P.Rotation),P.Pawn.Location,10000);
    if(A!=None)
        return A;
    For(C=Level.ControllerList; C!=None; C=C.NextController)
    {
        if(C!=P && C.Pawn!=None)
        {
            D = VSize(C.Pawn.Location-P.Pawn.Location);
            if(D<BD || BD==0)
            {
                BD = D;
                BC = C;
            }
        }
    }
    if(BC!=None)
        return BC.Pawn;
}
//==============================================================================

// SetTextProperty
exec function Set(string Cmd)
{
    local int i,f,su;
    local string P;
    local Actor A,AA;

    if(!CanDo("Set")) return;
    i = InStr(Cmd," ");
    if(i==-1)
    {
        Note("Missing class to set");
        return;
    }
    P = Left(Cmd,i);
    StrToActorC = None;
    ConsoleCommand("StringToActor"@P);
    if(StrToActorC==None)
    {
        foreach AllActors(Class'Actor',A)
        {
            if(string(A.Name)~=P)
                AA = A;
        }
        if(AA==None)
        {
            Note("Unrecognized class '"$P$"'");
            return;
        }
    }
    Cmd = Mid(Cmd,i+1);
    i = InStr(Cmd," ");
    if(i==-1)
    {
        Note("Missing property value");
        return;
    }
    P = Left(Cmd,i);
    Cmd = Mid(Cmd,i+1);
    if(AA!=None)
    {
        if(CanSet(AA,P,Cmd))
            Note("Changed value '"$P$"' to '"$Cmd$"' on"@AA);
        else Note("Failed to change value '"$P$"' to '"$Cmd$"' on"@AA);
        return;
    }
    foreach AllActors(StrToActorC,A)
    {
        if(CanSet(A,P,Cmd))
            su++;
        else f++;
    }
    Note("Changed value '"$P$"' to '"$Cmd$"' on"@StrToActorC$","@f@"failures,"@su@"success.");
}

// SetTextProperty + SaveConfig
exec function SetSave(string Cmd)
{
    local int i,f,su;
    local string P;
    local Actor A,AA;

    if(!CanDo("Set") || !CanDo("SetSave"))
        return;

    i = InStr(Cmd," ");
    if(i==-1)
    {
        Note("Missing class to set");
        return;
    }
    P = Left(Cmd,i);
    StrToActorC = None;
    ConsoleCommand("StringToActor"@P);
    if(StrToActorC==None)
    {
        foreach AllActors(Class'Actor',A)
        {
            if(string(A.Name)~=P)
                AA = A;
        }
        if(AA==None)
        {
            Note("Unrecognized class '"$P$"'");
            return;
        }
    }
    Cmd = Mid(Cmd,i+1);
    i = InStr(Cmd," ");
    if(i==-1)
    {
        Note("Missing property value");
        return;
    }
    P = Left(Cmd,i);
    Cmd = Mid(Cmd,i+1);
    if(AA!=None)
    {
        if(CanSet(AA,P,Cmd))
            Note("Changed value '"$P$"' to '"$Cmd$"' on"@AA);
        else Note("Failed to change value '"$P$"' to '"$Cmd$"' on"@AA);
        return;
    }
    foreach AllActors(StrToActorC,A)
    {
        if(CanSet(A,P,Cmd))
        {
            A.SaveConfig();
            su++;
        }
        else f++;
    }
    Note("Changed value '"$P$"' to '"$Cmd$"' on"@StrToActorC$","@f@"failures (and saved),"@su@"success.");
}

// Collision, DrawScale Const bypass
function bool CanSet(Actor Other, string Property, string NewVal)
{
    local float Relat;

    if(Property~="DrawScale")
    {
        Relat = float(NewVal)/Other.DrawScale;
        Other.SetCollisionSize(Other.CollisionRadius*Relat,Other.CollisionHeight*Relat);
        Other.SetDrawScale(float(NewVal));
        return true;
    }
    else if(Property~="CollisionHeight")
    {
        Other.SetCollisionSize(Other.CollisionRadius,float(NewVal));
        return true;
    }
    else if(Property~="CollisionRadius")
    {
        Other.SetCollisionSize(float(NewVal),Other.CollisionHeight);
        return true;
    }
    else if(Property~="DrawScale3D")
    {
        Other.SetDrawScale3D(TurnStrToVect(NewVal,Other.DrawScale3D));
        return true;
    }
    return Other.SetPropertyText(Property,NewVal);
}

function vector TurnStrToVect(string S, optional vector InitVal, optional out byte ErrorLevel)
{
    local int i,j;
    local string D,DV;

    ErrorLevel = 0;
    if(Len(S)<2)
    {
        ErrorLevel = 255;
        return InitVal;
    }
    i = InStr(S,",");
    While(i!=-1)
    {
        D = Left(S,i);
        j = InStr(D,"=");
        if(j==-1)
            ErrorLevel++;
        else
        {
            DV = Left(D,j);
            D = Mid(D,j+1);
            if(DV~="X")
                InitVal.X = float(D);
            else if(DV~="Y")
                InitVal.Y = float(D);
            else if(DV~="Z")
                InitVal.Z = float(D);
            else ErrorLevel++;
        }
        S = Mid(S,i+1);
        i = InStr(S,",");
    }
    S = Left(S,Len(S)-1);
    j = InStr(S,"=");
    if(j==-1)
        ErrorLevel++;
    else
    {
        DV = Left(S,j);
        D = Mid(S,j+1);
        if(DV~="X")
            InitVal.X = float(D);
        else if(DV~="Y")
            InitVal.Y = float(D);
        else if(DV~="Z")
            InitVal.Z = float(D);
        else ErrorLevel++;
    }
    return InitVal;
}

// Hack
exec function StringToActor(class<Actor> AC)
{
    StrToActorC = AC;
}

//==============================================================================
// Server configuration commands
exec function ListServerPackages()
{
    local int i,j;

    ClientMessage("Current serverpackages:");
    j = Class'GameEngine'.Default.ServerPackages.Length;
    For(i=0; i<j; i++)
        ClientMessage("Package"@(i+1)$":"@Class'GameEngine'.Default.ServerPackages[i]);
}

exec function AddServerPackage(string PckgNmn)
{
    local int j;
    local GameEngine GE;

    if(!CanDo("AddPackage")) return;
    j = InStr(PckgNmn,"."); // Never put file extension on serverpackage!
    if(j!=-1)
        PckgNmn = Left(PckgNmn,j);
    j = Class'GameEngine'.Default.ServerPackages.Length;
    Class'GameEngine'.Default.ServerPackages.Length = j+1;
    Class'GameEngine'.Default.ServerPackages[j] = PckgNmn;
    Class'GameEngine'.Static.StaticSaveConfig();
    foreach AllObjects(Class'GameEngine',GE)
        GE.ServerPackages = Class'GameEngine'.Default.ServerPackages;
    AMessage("Added serverpackage:"@PckgNmn);
}

exec function RemoveServerPackage(string PckgNmn)
{
    local int j,i;
    local GameEngine GE;
    local bool bGot;

    if(!CanDo("RemovePackage")) return;
    j = Class'GameEngine'.Default.ServerPackages.Length;
    For(i=0; i<j; i++)
    {
        if(Class'GameEngine'.Default.ServerPackages[i]~=PckgNmn)
        {
            j--;
            Class'GameEngine'.Default.ServerPackages.Remove(i,1);
            bGot = true;
            Break;
        }
    }
    if(!bGot)
    {
        ClientMessage("Package was not found in serverpackages");
        return;
    }
    Class'GameEngine'.Static.StaticSaveConfig();
    foreach AllObjects(Class'GameEngine',GE)
        GE.ServerPackages = Class'GameEngine'.Default.ServerPackages;
    AMessage("Removed serverpackage:"@PckgNmn);
}

exec function MapVote(string Cmd)
{
    local xVotingHandler V;
    local int i;

    if(!CanDo("MapVote")) return;
    V = xVotingHandler(Level.Game.VotingHandler);
    if(V==None)
        return;
    if(Cmd~="Cancel")
    {
        V.bMidGameVote = false;
        V.settimer(0,false);
        For(i=0; i<V.MVRI.Length; i++)
            if(V.MVRI[i]!=None && V.MVRI[i].MapVote>-1 && V.MVRI[i].GameVote>-1)
            {
                V.UpdateVoteCount(V.MVRI[i].MapVote,V.MVRI[i].GameVote,-V.MVRI[i].VoteCount);
                V.MVRI[i].MapVote = -1;
                V.MVRI[i].GameVote = -1;
                V.MVRI[i].VoteCount = 0;
            }
        V.TallyVotes(false);
        Level.Game.Broadcast(Outer,"Mapvoting has been canceled");
        AMessage("Mapvoting canceled");
    }
    else if(Cmd~="Begin")
    {
        AMessage("Started mapvoting");
        Level.Game.Broadcast(V,V.lmsgMidGameVote);
        V.bMidGameVote = true;
        // Start voting count-down timer
        V.TimeLeft = V.VoteTimeLimit;
        V.ScoreBoardTime = 1;
        V.settimer(1,true);
    }
    else
    {
        ClientMessage("Unknown mapvoting action!");
        Help("MapVote");
    }
}
exec function GetConnections(string Type)
{
    local FileChannel FC;
    local NetConnection N;
    local int i,j;
    local array<AccessPlus.SocketDataPacketType> Soc;

    if(!CanDo("GetConnections")) return;
    if(Type~="All" || Type=="")
    {
        ClientMessage("Current connections in server:");
        foreach AllObjects(Class'FileChannel',FC)
            i++;
        foreach AllObjects(Class'NetConnection',N)
        {
            if(N.Actor==None)
                j++;
            else ClientMessage("Active client:"@N.Actor.GetPlayerNetworkAddress()@N.Actor.PlayerReplicationInfo.PlayerName);
        }
        ClientMessage(i@"client(s) downloading off server now."@j@"inactive client(s) on the server");
    }
    else if(Type~="Active")
    {
        ClientMessage("Current active clients in server:");
        foreach AllObjects(Class'NetConnection',N)
        {
            if(N.Actor!=None)
                ClientMessage("Active client:"@N.Actor.GetPlayerNetworkAddress()@N.Actor.PlayerReplicationInfo.PlayerName);
        }
    }
    else if(Type~="InActive")
    {
        ClientMessage("Current inactive clients in server:");
        foreach AllObjects(Class'NetConnection',N)
        {
            if(N.Actor==None)
                i++;
        }
        ClientMessage(i@"inactive client(s) on the server.");
    }
    else if(Type~="DL")
    {
        foreach AllObjects(Class'FileChannel',FC)
            i++;
        ClientMessage(i@"client(s) downloading off server now.");
    }
    else if(Type~="Detail") // Sloooooow....
    {
        uManager.MyMutator.GetSocketsCon(Soc);
        ClientMessage("Full client detail log:");
        For(i=0; i<Soc.Length; i++)
        {
            if(Soc[i].DLFile!="")
                ClientMessage("#"$i$":"@Soc[i].PlayerIP@Soc[i].PlayerName@"State:"@Soc[i].ConnectionState@"File:"@Soc[i].DLFile@"Chan: Text:"@Soc[i].TextChannels@"Actor:"@Soc[i].ActorChannels@"File:"@Soc[i].FileChannels@"Other:"@Soc[i].OtherChannels);
            else ClientMessage("#"$i$":"@Soc[i].PlayerIP@Soc[i].PlayerName@"State:"@Soc[i].ConnectionState@"Channels: Text:"@Soc[i].TextChannels@"Actor:"@Soc[i].ActorChannels@"File:"@Soc[i].FileChannels@"Other:"@Soc[i].OtherChannels);
        }
    }
    else Help("GetConnections");
}

exec function ReloadCache()
{
    if(!CanDo("ReloadCache")) return;
    Class'CacheManager'.Static.InitCache();
    ClientMessage("Server cache has been reinitilized.");
}

exec function GetAddress(string ID)
{
    local array<Controller> C;
    local int i;

    if(!CanDo("GetAddress"))return;
    C = SearchPlayers(ID);
    if(!CheckControllers(C))return;
    for(i = 0; i < C.Length; i ++)
    {
        ClientMessage("Name:"@C[i].PlayerReplicationInfo.PlayerName$","@"IP:"@PlayerController(C[i]).GetPlayerNetworkAddress()$","@"ID:"@PlayerController(C[i]).GetPlayerIDHash());
    }
}

// Parent commands moved to here to add priv support.
exec function RestartMap()
{
    if(!CanDo("RestartMap"))return;
    RestartCurrentMap();
}

exec function NextMap()
{
    if(!CanDo("NextMap"))return;
    GotoNextMap();
}

exec function Map(string Cmd)
{
    if(!CanDo("Map"))return;
    Super.Map(Cmd);
}

exec function Maplist(string Cmd, string Extra)
{
    if(!CanDo("MapList"))return;
    MaplistCommand(Cmd, Extra);
}

exec function Switch(string URL)
{
    if(!CanDo("Switch"))return;
    DoSwitch(URL);
}

exec function PlayerList()
{
    if(CanDo("PlayerList"))
        Super.PlayerList();
}

exec function Open(string URL)
{
    if(CanDo("Open"))
        DoSwitch(URL);
}

// Restarts Server (Actualy crashes ;)).
/*exec function Exit()
{
    if(!CanDo("Exit"))return;
    Level.Game.Broadcast(Outer, "Server Closing by request.");
    Assert(false);
}*/

// BTimesMute features, moved to here
exec function AddMapActor(string ActorClass)
{
    local vector SpawnLocation;
    local class<Actor> SpawnActor;
    local Actor Actor;
    local int NumActors;

    if(Pawn == None)
        SpawnLocation = Location+(vector(Rotation)*90);
    else SpawnLocation = Pawn.Location+(vector(Pawn.Rotation)*90);

    SpawnActor = Class<Actor>(DynamicLoadObject(ActorClass, Class'Class', false));
    if(SpawnActor == None)
    {
        ClientMessage("Unrecognized class'"$ActorClass$"'");
        return;
    }

    Actor = Spawn(SpawnActor, Level, 'MapActor', SpawnLocation, Rotation);
    if(Actor == None)
    {
        ClientMessage("Failed to spawn class'"$ActorClass$"'");
        return;
    }

    NumActors = uManager.MyMutator.MapActors.Length;
    uManager.MyMutator.MapActors.Length = NumActors + 1;
    uManager.MyMutator.MapActors[NumActors].ActorClass = ActorClass;
    uManager.MyMutator.MapActors[NumActors].MapName = uManager.MyMutator.CurrentMapName;
    uManager.MyMutator.MapActors[NumActors].Location = Actor.Location;
    uManager.MyMutator.MapActors[NumActors].Rotation = Actor.Rotation;
    uManager.MyMutator.SaveConfig();

    Level.Game.Broadcast(Outer, GetAdmin(PlayerReplicationInfo)@"Added MapActor"@ActorClass);
}

exec function FlushMapActors()
{
    local int CurMapActor, NumMapActors, CurMapNumActors;
    local Actor Actor;

    NumMapActors = uManager.MyMutator.MapActors.Length;
    if(NumMapActors == 0)
        return;

    for(CurMapActor = 0; CurMapActor < NumMapActors; ++ CurMapActor)
    {
        if(uManager.MyMutator.MapActors[CurMapActor].MapName ~= uManager.MyMutator.CurrentMapName)
        {
            CurMapNumActors ++;
            uManager.MyMutator.MapActors.Remove(CurMapActor, 1);
            CurMapActor --;
            NumMapActors --;
            continue;
        }
    }

    if(CurMapNumActors == 0)
    {
        ClientMessage("No actors found to remove from this map");
        return;
    }

    foreach DynamicActors(Class'Actor', Actor, 'MapActor')
        Actor.Destroy();

    uManager.MyMutator.SaveConfig();

    Level.Game.Broadcast(Outer, GetAdmin(PlayerReplicationInfo)@"Removed all MapActors");
}
//==============================================================================

//==============================================================================
// Used to remove attached actors after owner is dead.
event Tick(float f)
{
    local int i, j;

    Super.Tick(f);
    j = NeedDelete.Length;
    if(j > 0)
    {
        for(i = 0; i < j; i ++)
        {
            if(NeedDelete[i] != None && NeedDelete[i].Owner == None)
                NeedDelete[i].Destroy();
        }
    }
    else Disable('Tick');
}

defaultproperties
{
}
