/*
Dynamic Actors System (Beta 3.0) [MySQL BlueG R41-4] by Zyzu

Credits:
a_samp: SAMP Team
a_mysql: BlueG
YSI/sscanf: Y-Less
ZCMD: Zeex
Streamer: Incognito
Design Create/Edit Panel: Nickk888

Information:

Server plugins required:

plugins streamer sscanf mysql

Optional install:

https://git.io/jit-plugin

Jit 2.4 released for windows or Jit 2.4.1 released for linux.

1. Extract/copy jit.so or jit.dll to <sever>/plugins/.
2. Add jit (Windows) or jit.so (Linux) to the plugins line of your server.cfg.

Commands:

/acreate - Create new actor
/aedit - You are editing an existing actor

*/
#include <a_samp>
#include <a_mysql>
#include <jit>
#include <YSI_Data\y_iterate>
#include <sscanf2>
#include <zcmd>
#include <streamer>

#define DEBUG false
#define function%0(%1) forward %0(%1); public %0(%1)
#define ADD_DIALOG_ID (2222)

//SETTINGS DATABASE
#define DB_HOST     "localhost"      //Host do bazy MySQL
#define DB_USER     "testowy"        //Nazwa użytkownika do bazy MySQL
#define DB_PASSWORD "123456"         //Hasło użytkownika do bazy MySQL
#define DB_DATABASE "actor_database" //Nazwa bazy MySQL

//DIALOG ID
#define D_ACCREATE      (ADD_DIALOG_ID + 0)
#define D_ACNAME        (ADD_DIALOG_ID + 1)
#define D_ACSKIN        (ADD_DIALOG_ID + 2)
#define D_ACEDIT        (ADD_DIALOG_ID + 3)
#define D_AENAME        (ADD_DIALOG_ID + 4)
#define D_AESKIN        (ADD_DIALOG_ID + 5)
#define D_ACTORANIM     (ADD_DIALOG_ID + 6)
#define D_ACTORANIM2    (ADD_DIALOG_ID + 7)

//LIMITES
#define MAX_ACTORS_RANGE 1.0
#define MAX_ANIMS 163

//Variable
new MySQL:SQL_ID;
new query[528];

//Iterators
new Iterator:Actor_Iter<MAX_ACTORS>;

//Enums
enum ACTOR_CREATE
{
    ae_IDActor,
    ac_name[34],
    Float:ac_posX,
    Float:ac_posY,
    Float:ac_posZ,
    Float:ac_posRot,
    ac_skinid,
    ac_qnumber,
    ac_animname[13],
    ac_Lib[16],
    ac_Namea[24]
}

new ActorCreate[MAX_PLAYERS][ACTOR_CREATE];

enum E_ACTOR
{
	aUID,
    aID,
	Text3D:a3DTextID,
	aName[34],
	Float:aPosX,
	Float:aPosY,
	Float:aPosZ,
	Float:aPosRot,
	aSkin,
	questnumber,
    aLib[16],
    aNamea[24]
}

new ActorCache[MAX_ACTORS][E_ACTOR];

enum animGameInfo
{
	aUID,
	aCommand[25],
	aLib[16],
	aNameAnim[24],
	Float:aSpeed,
	aOpt1,
	aOpt2,
	aOpt3,
	aOpt4,
	aOpt5,
	aAction
}
new AnimInfo[MAX_ANIMS][animGameInfo];

//Tables
static s_AnimationLibraries[][] = {
    !"AIRPORT",    !"ATTRACTORS",   !"BAR",            !"BASEBALL",
    !"BD_FIRE",    !"BEACH",        !"BENCHPRESS",        !"BF_INJECTION",
    !"BIKED",      !"BIKEH",        !"BIKELEAP",        !"BIKES",
    !"BIKEV",      !"BIKE_DBZ",     !"BMX",            !"BOMBER",
    !"BOX",        !"BSKTBALL",     !"BUDDY",            !"BUS",
    !"CAMERA",     !"CAR",          !"CARRY",            !"CAR_CHAT",
    !"CASINO",     !"CHAINSAW",     !"CHOPPA",            !"CLOTHES",
    !"COACH",      !"COLT45",       !"COP_AMBIENT",        !"COP_DVBYZ",
    !"CRACK",      !"CRIB",         !"DAM_JUMP",        !"DANCING",
    !"DEALER",     !"DILDO",        !"DODGE",            !"DOZER",
    !"DRIVEBYS",   !"FAT",          !"FIGHT_B",            !"FIGHT_C",
    !"FIGHT_D",    !"FIGHT_E",      !"FINALE",          !"FINALE2",
    !"FLAME",      !"FLOWERS",      !"FOOD",            !"FREEWEIGHTS",
    !"GANGS",      !"GHANDS",       !"GHETTO_DB",        !"GOGGLES",
    !"GRAFFITI",   !"GRAVEYARD",    !"GRENADE",          !"GYMNASIUM",
    !"HAIRCUTS",   !"HEIST9",       !"INT_HOUSE",        !"INT_OFFICE",
    !"INT_SHOP",   !"JST_BUISNESS", !"KART",            !"KISSING",
    !"KNIFE",      !"LAPDAN1",      !"LAPDAN2",          !"LAPDAN3",
    !"LOWRIDER",   !"MD_CHASE",     !"MD_END",          !"MEDIC",
    !"MISC",       !"MTB",          !"MUSCULAR",        !"NEVADA",
    !"ON_LOOKERS", !"OTB",          !"PARACHUTE",        !"PARK",
    !"PAULNMAC",   !"PED",          !"PLAYER_DVBYS",    !"PLAYIDLES",
    !"POLICE",     !"POOL",         !"POOR",            !"PYTHON",
    !"QUAD",       !"QUAD_DBZ",     !"RAPPING",          !"RIFLE",
    !"RIOT",       !"ROB_BANK",     !"ROCKET",          !"RUSTLER",
    !"RYDER",      !"SCRATCHING",   !"SHAMAL",          !"SHOP",
    !"SHOTGUN",    !"SILENCED",     !"SKATE",           !"SMOKING",
    !"SNIPER",     !"SPRAYCAN",     !"STRIP",           !"SUNBATHE",
    !"SWAT",       !"SWEET",        !"SWIM",            !"SWORD",
    !"TANK",       !"TATTOOS",      !"TEC",             !"TRAIN",
    !"TRUCK",      !"UZI",          !"VAN",             !"VENDING",
    !"VORTEX",     !"WAYFARER",     !"WEAPONS",            !"WUZI",
    !"WOP",        !"GFUNK",        !"RUNNINGMAN"
};

static SpeakTextActor[][] = {
    "{FFFFFF}Siemka co słychać? {B400FF}**uśmiecha się**{FFFFFF}", "{FFFFFF}Witam w czym mogę pomóc?",
    "{FFFFFF}Jak leci?", "{FFFFFF}Hmmm...",
    "{FFFFFF}Nie mam czasu, pogadaj z kimś innym.", "{FFFFFF}Ładne mam ubranie dzisiaj kupiłem.{B400FF}**puszcza oczko**{FFFFFF}",
    "{FFFFFF}Cześć.", "{FFFFFF}Co tam?",
    "{FFFFFF}Słyszałeś? Chyba coś wybuchło.", "{FFFFFF}Chyba pojadę na ryby."
};

main(){}

public OnFilterScriptInit()
{
    if(ConnectToDB())
    {
        Iter_Init(Actor_Iter);
        CreateTableMySQL();
        LoadAllCreateActor();
        LoadAllAnimations();
    }
    return 1;
}

public OnFilterScriptExit()
{
    DestroyAllActors();
    mysql_close(SQL_ID);
    return 1;
}

public OnPlayerConnect(playerid)
{
    PreloadAllAnimLibs(playerid);
    ResetPlayerData(playerid);
    EnablePlayerCameraTarget(playerid, true);
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch(dialogid)
    {
        case D_ACCREATE:
        {
            if(response)
            {
                switch(listitem)
                {
                    case 0: ShowPlayerDialog(playerid, D_ACNAME, DIALOG_STYLE_INPUT, "Tworzenie aktora > nazwa", "Wpisz nazwe aktora\nNp: William Syd", "Potwierdź", "Anuluj");
                    case 5: ShowPlayerDialog(playerid, D_ACSKIN, DIALOG_STYLE_INPUT, "Tworzenie aktora > skin", "Wpisz ID skina\nNp: 271 - ryder", "Potwierdź", "Anuluj");
                    case 6:
                    {
                        if(ActorCreate[playerid][ac_qnumber] == 0)
                            ActorCreate[playerid][ac_qnumber] = 1,
                            CreateActors(playerid);
                        else
                            ActorCreate[playerid][ac_qnumber] = 0,
                            CreateActors(playerid);
                    }
                    case 7:
                    {
                        new list_anims[1237];
	
                        for(new anim_id = 0; anim_id < MAX_ANIMS; anim_id++)
                        {
                            if(strlen(AnimInfo[anim_id][aCommand]) == 0) break;
                            format(list_anims, sizeof(list_anims), "%s\n%s", list_anims, AnimInfo[anim_id][aCommand]);
                        }
                        
                        if(strlen( list_anims ) != 0) ShowPlayerDialog(playerid, D_ACTORANIM, DIALOG_STYLE_LIST, "Animacje", list_anims, "Ok", "Zamknij");
                        else SendClientMessage(playerid, -1, "Nie znaleziono animacji. Skontaktuj się z administracją serwera!");
                    }
                    case 8:
                    {
                        NewCreateActor(ActorCreate[playerid][ac_name], ActorCreate[playerid][ac_posX], ActorCreate[playerid][ac_posY], ActorCreate[playerid][ac_posZ], ActorCreate[playerid][ac_posRot], ActorCreate[playerid][ac_skinid], ActorCreate[playerid][ac_qnumber], ActorCreate[playerid][ac_Lib], ActorCreate[playerid][ac_Namea]);
                        CreateActors(playerid, true);
                    }
                }
            }
            else CreateActors(playerid, true);
            return 1;
        }

        case D_ACTORANIM:
        {
            new anim_id = listitem;
            format(ActorCreate[playerid][ac_Lib], 17, AnimInfo[anim_id][aLib]);
            format(ActorCreate[playerid][ac_Namea], 25, AnimInfo[anim_id][aNameAnim]);
            format(ActorCreate[playerid][ac_animname], 12, AnimInfo[anim_id][aCommand]);
            CreateActors(playerid);
            return 1;
        }

        case D_ACTORANIM2:
        {
            new anim_id = listitem;
            format(ActorCreate[playerid][ac_Lib], 16, AnimInfo[anim_id][aLib]);
            format(ActorCreate[playerid][ac_Namea], 24, AnimInfo[anim_id][aNameAnim]);
            format(ActorCreate[playerid][ac_animname], 12, AnimInfo[anim_id][aCommand]);
            EditActor(playerid);
            return 1;
        }

        case D_ACNAME:
        {
            if(response)
            {
                new name[33];
                if(!sscanf(inputtext, "s[33]", name))
                    format(ActorCreate[playerid][ac_name], 33, "%s", name),
                    CreateActors(playerid);
                else ShowPlayerDialog(playerid, D_ACNAME, DIALOG_STYLE_INPUT, "Tworzenie aktora > nazwa", "Wpisz nazwe aktora\nNp: William Syd\nBłedna nazwa!", "Potwierdź", "Anuluj");
            }
            return 1;
        }

        case D_ACSKIN:
        {
            if(response)
            {
                new id;
                if(!sscanf(inputtext, "i", id))
                    ActorCreate[playerid][ac_skinid] = id,
                    CreateActors(playerid);
                else ShowPlayerDialog(playerid, D_ACSKIN, DIALOG_STYLE_INPUT, "Tworzenie aktora > skin", "Wpisz ID skina\nNp: 172 - ryder\nBłędne ID", "Potwierdź", "Anuluj");
            }
            return 1;
        }

         case D_AENAME:
        {
            if(response)
            {
                new name[33];
                if(!sscanf(inputtext, "s[33]", name))
                    format(ActorCreate[playerid][ac_name], 33, "%s", name),
                    EditActor(playerid);
                else ShowPlayerDialog(playerid, D_AENAME, DIALOG_STYLE_INPUT, "Edycja aktora > nazwa", "Wpisz nazwe aktora\nNp: William Syd\nBłedna nazwa!", "Potwierdź", "Anuluj");
            }
            return 1;
        }

        case D_AESKIN:
        {
            if(response)
            {
                new id;
                if(!sscanf(inputtext, "i", id))
                    ActorCreate[playerid][ac_skinid] = id,
                    EditActor(playerid);
                else ShowPlayerDialog(playerid, D_AESKIN, DIALOG_STYLE_INPUT, "Edycja aktora > skin", "Wpisz ID skina\nNp: 172 - ryder\nBłędne ID", "Potwierdź", "Anuluj");
            }
            return 1;
        }

        case D_ACEDIT:
        {
            if(response)
            {
                query = "";
                switch(listitem)
                {
                    case 0: ShowPlayerDialog(playerid, D_AENAME, DIALOG_STYLE_INPUT, "Edycja aktora > nazwa", "Wpisz nazwe aktora\nNp: William Syd\nPozostawienie pola nie zmieniając nazwy zachowa starą nazwe Aktora.", "Potwierdź", "Anuluj");
                    case 1: ShowPlayerDialog(playerid, D_AESKIN, DIALOG_STYLE_INPUT, "Edycja aktora > skin", "Wpisz ID skina\nNp: 271 - ryder", "Potwierdź", "Anuluj");
                    case 2:
                    {
                        if(ActorCreate[playerid][ac_qnumber] == 0)
                            ActorCreate[playerid][ac_qnumber] = 1,
                            EditActor(playerid);
                        else
                            ActorCreate[playerid][ac_qnumber] = 0,
                            EditActor(playerid);
                    }
                    case 3:
                    {
                        new list_anims[1237];
	
                        for(new anim_id = 0; anim_id < MAX_ANIMS; anim_id++)
                        {
                            if(strlen(AnimInfo[anim_id][aCommand]) == 0) break;
                            format(list_anims, sizeof(list_anims), "%s\n%s", list_anims, AnimInfo[anim_id][aCommand]);
                        }
                        
                        if(strlen( list_anims ) != 0) ShowPlayerDialog(playerid, D_ACTORANIM2, DIALOG_STYLE_LIST, "Edycja Aktora Animacje", list_anims, "Ok", "Zamknij");
                        else SendClientMessage(playerid, -1, "Nie znaleziono animacji. Skontaktuj się z administracją serwera!");
                    }
                    case 4:
                    {
                        new string[328], id = ActorCreate[playerid][ae_IDActor];
                        if(strlen(ActorCreate[playerid][ac_name]) < 1)
                            format(ActorCreate[playerid][ac_name], 33, ActorCache[id][aName]);
                        else format(ActorCache[id][aName], 33, ActorCreate[playerid][ac_name]);

                        if(strlen(ActorCreate[playerid][ac_Lib]) < 1)
                            format(ActorCreate[playerid][ac_Lib], 16, ActorCache[id][aLib]);
                        else format(ActorCache[id][aLib], 16, ActorCreate[playerid][ac_Lib]);

                        if(strlen(ActorCreate[playerid][ac_Namea]) < 1)
                            format(ActorCreate[playerid][ac_Namea], 24, ActorCache[id][aNamea]);
                        else format(ActorCache[id][aNamea], 24, ActorCreate[playerid][ac_Namea]);
                        ActorCache[id][questnumber] = ActorCreate[playerid][ac_qnumber];

                        if(ActorCreate[playerid][ac_skinid] == 0)
                            ActorCreate[playerid][ac_skinid] = ActorCache[id][aSkin];

                        Streamer_SetIntData(STREAMER_TYPE_ACTOR, ActorCache[ActorCreate[playerid][ae_IDActor]][aID], E_STREAMER_MODEL_ID, ActorCreate[playerid][ac_skinid]);
                        if(ActorCache[id][questnumber] == 0) format(string, sizeof string, "{E6E6F0}%i. %s\n(Naciśnij N aby wejść w interakcje)", id, ActorCache[id][aName]);
                        else if(ActorCache[id][questnumber] == 1) format(string, sizeof string, "%i. %s{00EBFF}(Pracodawca){E6E6F0}\n(Naciśnij N aby wejść w interakcje)", id, ActorCache[id][aName]);
                        UpdateDynamic3DTextLabelText(ActorCache[id][a3DTextID], 0xE6E6E6F0, string);
                        
                        mysql_format(SQL_ID, query, sizeof query, "UPDATE `actor_database`.`actor` SET `name` = '%s', `skinid` = '%i', `qnumber` = '%i', `lib` = '%s', `namea` = '%s' WHERE  `UID` = '%i';",
                         ActorCreate[playerid][ac_name], ActorCreate[playerid][ac_skinid], ActorCreate[playerid][ac_qnumber], ActorCreate[playerid][ac_Lib], ActorCreate[playerid][ac_Namea], ActorCache[id][aUID]);
                        mysql_tquery(SQL_ID, query);
                        ClearDynamicActorAnimations(ActorCache[id][aID]);
                        if(strlen(ActorCache[id][aLib]) > 0) ApplyDynamicActorAnimation(ActorCache[id][aID], ActorCreate[playerid][ac_Lib], ActorCreate[playerid][ac_Namea], 4.1, 1, 0, 0, 0, 0);
                        EditActor(playerid, true);
                    }
                    case 5:
                    {
                        DeleteActor(playerid);
                    }
                }
            }
        }
    }
    return 0;
}

#define PRESSED(%0) \
	(((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))
public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if(PRESSED(KEY_NO)) // Key 'N'
    {
        new string[248];
        new actorid = (GetPlayerCameraTargetDynActor(playerid)-1);
        if(IsValidDynamicActor(ActorCache[actorid][aID]))
        {
            if(ActorCache[actorid][questnumber] == 0)
            {
                format(string, sizeof string, "%s mówi: %s", ActorCache[actorid][aName], SpeakTextActor[random(sizeof SpeakTextActor)]);
                SendClientMessage(playerid, -1, string);
            }
            else if(ActorCache[actorid][questnumber] == 1)
            {
                format(string, sizeof string, "%s mówi: Cześć jestem pracodawcą możesz tutaj zaimplementować swój skrypt na prace.", ActorCache[actorid][aName]);
                SendClientMessage(playerid, -1, string);
            }
        }
        return 1;
    }
    return 1;
}

//CMD

#if DEBUG == true
CMD:chatclear(playerid)
{
    for(new i; i < 100; i++)
        SendClientMessage(playerid, -1, " ");
    return 1;
}

#endif

CMD:acreate(playerid, params[])
{
    CreateActors(playerid);
    return 1;
}

CMD:aedit(playerid, params[])
{
    new id;
    if(!sscanf(params, "i", id))
        if(IsValidDynamicActor(ActorCache[id][aID]))
            ActorCreate[playerid][ae_IDActor] = id,
            EditActor(playerid);
        else SendClientMessage(playerid, -1, "[BŁAD] Niepoprawne {FF0000}ID{FFFFFF} Aktora");
    else SendClientMessage(playerid, -1, "[BŁAD] Niepoprawne {FF0000}ID{FFFFFF} Aktora");
    return 1;
}

//stocki
stock CreateActors(playerid, bool:clear = false)
{
    new string[428];
    if(clear)
    {
        format(ActorCreate[playerid][ac_name], 34, "");
        format(ActorCreate[playerid][ac_animname], 12, "");
        ActorCreate[playerid][ac_skinid] = 0;
        ActorCreate[playerid][ac_qnumber] = 0;
        return 1;
    }
    GetPlayerPos(playerid, ActorCreate[playerid][ac_posX], ActorCreate[playerid][ac_posY], ActorCreate[playerid][ac_posZ]);
    GetPlayerFacingAngle(playerid, ActorCreate[playerid][ac_posRot]);
    format(string, sizeof string, "%sOpcja\tWartość\n", string);
    format(string, sizeof string, "%s{FFFFFF}Nazwa aktora:\t{00B9FF}%s\n", string, ActorCreate[playerid][ac_name]);
    format(string, sizeof string, "%s{FFFFFF}Pozycja X:\t{00B9FF}%0.2f\n", string, ActorCreate[playerid][ac_posX]);
    format(string, sizeof string, "%s{FFFFFF}Pozycja Y:\t{00B9FF}%0.2f\n", string, ActorCreate[playerid][ac_posY]);
    format(string, sizeof string, "%s{FFFFFF}Pozycja Z:\t{00B9FF}%0.2f\n", string, ActorCreate[playerid][ac_posZ]);
    format(string, sizeof string, "%s{FFFFFF}Rotacja:\t{00B9FF}%0.2f\n", string, ActorCreate[playerid][ac_posRot]);
    format(string, sizeof string, "%s{FFFFFF}Skin ID:\t{00B9FF}%i\n", string, ActorCreate[playerid][ac_skinid]);
    format(string, sizeof string, "%s{FFFFFF}Rola aktora:\t{00B9FF}%s\n", string, (ActorCreate[playerid][ac_qnumber] == 0) ? ("Statysta") : ("Pracodawca"));
    format(string, sizeof string, "%s{FFFFFF}Animacja:\t{00B9FF}%s{FFFFFF}(Nie wybieraj animacji jeżeli chcesz aby aktor jej nie posiadał)\n", string, ActorCreate[playerid][ac_animname]);
    format(string, sizeof string, "%s{00B9FF}Stwórz...", string);
    ShowPlayerDialog(playerid, D_ACCREATE, DIALOG_STYLE_TABLIST_HEADERS, "Tworzenie aktora", string, "Ok", "Anuluj");
    return 1;
}

stock EditActor(playerid, bool:clear = false)
{
    new string[428];
    if(clear)
    {
        format(ActorCreate[playerid][ac_name], 34, "");
        format(ActorCreate[playerid][ac_animname], 12, "");
        format(ActorCreate[playerid][ac_Lib], 16, "");
        format(ActorCreate[playerid][ac_Namea], 24, "");
        ActorCreate[playerid][ac_skinid] = 0;
        ActorCreate[playerid][ac_qnumber] = 0;
        ActorCreate[playerid][ac_skinid] = 0;
        return 1;
    }
    format(string, sizeof string, "%sOpcja\tWartość\n", string);
    format(string, sizeof string, "%s{FFFFFF}Nazwa aktora:\t{00B9FF}%s{FFFFFF}(Nie zmieniając nazwy, nazwa pozostanie taka sama)\n", string, ActorCreate[playerid][ac_name]);
    format(string, sizeof string, "%s{FFFFFF}Skin ID:\t{00B9FF}%i{FFFFFF}(Nie zmieniając skina skin pozostanie taki sam)\n", string, ActorCreate[playerid][ac_skinid]);
    format(string, sizeof string, "%s{FFFFFF}Rola aktora:\t{00B9FF}%s\n", string, (ActorCreate[playerid][ac_qnumber] == 0) ? ("Statysta") : ("Pracodawca"));
    format(string, sizeof string, "%s{FFFFFF}Animacja:\t{00B9FF}%s{FFFFFF}(Nie wybierając innej animacji animacja pozostanie ta sama)\n", string, ActorCreate[playerid][ac_animname]);
    format(string, sizeof string, "%s{00B9FF}Edytuj...\n", string);
    format(string, sizeof string, "%s{00B9FF}Usuń...", string);
    ShowPlayerDialog(playerid, D_ACEDIT, DIALOG_STYLE_TABLIST_HEADERS, "Edycja aktora", string, "Ok", "Anuluj");
    return 1;
}

stock DeleteActor(playerid)
{
    query = "";
    new id = ActorCreate[playerid][ae_IDActor];
    mysql_format(SQL_ID, query, sizeof query, "DELETE FROM `actor_database`.`actor` WHERE `UID` = '%i'", ActorCache[id][aUID]);
	mysql_tquery(SQL_ID, query);

    DestroyDynamicActor(ActorCache[id][aID]);
    DestroyDynamic3DTextLabel(ActorCache[id][a3DTextID]);
    format(ActorCache[id][aName], 34, "");
    format(ActorCache[id][aLib], 17, "");
    format(ActorCache[id][aNamea], 25, "");
    ActorCache[id][aUID]                 = -1;
    ActorCache[id][aPosX]                = -1;
    ActorCache[id][aPosY]                = -1;
    ActorCache[id][aPosZ]                = -1;
    ActorCache[id][aPosRot]              = -1;
    ActorCache[id][aSkin]                = -1;
    ActorCache[id][questnumber]          = -1;
    ActorCache[id][a3DTextID]            = Text3D:-1;
    Iter_Remove(Actor_Iter, id);
    return 1;
}

stock NewCreateActor(name[], Float:posX, Float:posY, Float:posZ, Float:posRot, skinid, qnumber = -1, libAnim[] = "SWEET", NameAnim[] = "")
{
    query = "";
    mysql_format(SQL_ID, query, sizeof query, "INSERT INTO actor SET name = '%s', posx = '%f', posy = '%f', posz = '%f', posrot = '%f', skinid = '%i', qnumber = '%i', lib = '%s', namea = '%s'", 
    name, posX, posY, posZ, posRot, skinid, qnumber, libAnim, NameAnim);
	mysql_tquery(SQL_ID, query, "LoadCreateActor");
    
    return 1;
}

stock LoadAllCreateActor()
{
    query = "";
    mysql_format(SQL_ID, query, sizeof query, "SELECT * FROM actor LIMIT %i", MAX_ACTORS);
    mysql_tquery(SQL_ID, query, "OnLoadAllCreateActor");
    return 1;
}

stock LoadAllAnimations()
    return mysql_tquery(SQL_ID, "SELECT * FROM anims", "LoadAnimations");

stock DestroyAllActors()
{
    foreach(new i : Actor_Iter)
    {
        DestroyDynamicActor(i);
        DestroyDynamic3DTextLabel(ActorCache[i][a3DTextID]);
        format(ActorCache[i][aName], 34, "");
        format(ActorCache[i][aLib], 17, "");
        format(ActorCache[i][aNamea], 25, "");
        ActorCache[i][aUID]                 = -1;
        ActorCache[i][aPosX]                = -1;
        ActorCache[i][aPosY]                = -1;
        ActorCache[i][aPosZ]                = -1;
        ActorCache[i][aPosRot]              = -1;
        ActorCache[i][aSkin]                = -1;
        ActorCache[i][questnumber]          = -1;
        ActorCache[i][a3DTextID]            = Text3D:-1;
    }
    Iter_Clear(Actor_Iter);
    return 1;
}

stock ConnectToDB()
{
    mysql_log();

	new MySQLOpt: option_id = mysql_init_options();
	mysql_set_option(option_id, AUTO_RECONNECT, true);
	SQL_ID = mysql_connect(DB_HOST, DB_USER, DB_PASSWORD, DB_DATABASE, option_id);

	if(SQL_ID == MYSQL_INVALID_HANDLE || mysql_errno(SQL_ID) != 0)
	{
		print("[INIT] MySQL nie mogl nawiazac polaczenia z baza danych. Blokuje dostep do serwera!");
		SendRconCommand("password errormysql");
		SendRconCommand("hostname [BLAD BAZY DANYCH]");
		return 0;
	}
	mysql_set_charset("cp1250_polish_ci", SQL_ID);
	print("[INIT] MySQL nawiazal polaczenie z baza danych. Wczytuje dane...");
    print("---------------------------------");
    print("Actors System by Zyzu Actived");
    print("---------------------------------");
	return 1;
}

stock PreloadAllAnimLibs(playerid)
{
    ApplyAnimation(playerid,"BOMBER","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"RAPPING","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"SHOP","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"BEACH","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"SMOKING","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"FOOD","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"ON_LOOKERS","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"DEALER","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"CRACK","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"CARRY","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"COP_AMBIENT","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"PARK","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"INT_HOUSE","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"FOOD","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"PED","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"SWEET","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"FREEWEIGHTS","null",0.0,0,0,0,0,0);

    ApplyAnimation(playerid,"AIRPORT","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"Attractors","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"BAR","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"BASEBALL","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"BD_FIRE","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"benchpress","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"BF_injection","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"BLOWJOBZ","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"BOX","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"BSKTBALL","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"BUDDY","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"CAMERA","null",0.0,0,0,0,0,0);
    ApplyAnimation(playerid,"CARRY","null",0.0,0,0,0,0,0);

    ClearAnimations(playerid);
    return 1;
}

stock static PreloadActorAnimations(actorid){
    for(new i = 0; i < sizeof(s_AnimationLibraries); i ++){
        ApplyDynamicActorAnimation(actorid, s_AnimationLibraries[i], "null", 0.0, 0, 0, 0, 0, 0);
    }
}

stock ResetPlayerData(playerid)
{
	static const null_players[ACTOR_CREATE];
	ActorCreate[playerid] =  null_players;
	return 1;
}

stock CreateTableMySQL()
{
    mysql_tquery(SQL_ID, "CREATE TABLE IF NOT EXISTS `actor` ( \
	`UID` INT(11) NOT NULL AUTO_INCREMENT, \
	`name` TINYTEXT NOT NULL COLLATE 'utf8mb4_general_ci', \
	`posx` FLOAT(12) NOT NULL, \
	`posy` FLOAT(12) NOT NULL, \
	`posz` FLOAT(12) NOT NULL, \
	`posrot` FLOAT(12) NOT NULL, \
	`skinid` FLOAT(12) NOT NULL, \
	`qnumber` INT(11) NOT NULL DEFAULT '0', \
	`lib` VARCHAR(16) NULL DEFAULT 'SWEET' COLLATE 'utf8mb4_general_ci', \
	`namea` VARCHAR(24) NULL DEFAULT 'null' COLLATE 'utf8mb4_general_ci', \
	PRIMARY KEY (`UID`) USING BTREE)");

    mysql_tquery(SQL_ID, "CREATE TABLE IF NOT EXISTS `anims` ( \
	`uid` SMALLINT(5) UNSIGNED NOT NULL AUTO_INCREMENT, \
	`cmd` VARCHAR(12) NOT NULL COLLATE 'utf8_unicode_ci', \
	`lib` VARCHAR(16) NOT NULL COLLATE 'utf8_unicode_ci', \
	`name` VARCHAR(24) NOT NULL COLLATE 'utf8_unicode_ci', \
	`speed` FLOAT(12) NOT NULL, \
	`loop/sa` TINYINT(4) NOT NULL, \
	`lockx` TINYINT(4) NOT NULL, \
	`locky` TINYINT(4) NOT NULL, \
	`freeze` TINYINT(4) NOT NULL, \
	`time` SMALLINT(4) NOT NULL, \
	`action` TINYINT(3) UNSIGNED NOT NULL DEFAULT '1', \
	PRIMARY KEY (`uid`) USING BTREE)");

    mysql_tquery(SQL_ID, "REPLACE INTO `anims` (`uid`, `cmd`, `lib`, `name`, `speed`, `loop/sa`, `lockx`, `locky`, `freeze`, `time`, `action`) VALUES \
	(1, 'idz1', 'PED', 'WALK_gang1', 4.1, 1, 1, 1, 1, 1, 1), \
	(2, 'idz2', 'PED', 'WALK_gang2', 4.1, 1, 1, 1, 1, 1, 1), \
	(3, 'idz3', 'PED', 'WOMAN_walksexy', 4, 1, 1, 1, 1, 1, 1), \
	(4, 'idz4', 'PED', 'WOMAN_walkfatold', 4, 1, 1, 1, 1, 1, 1), \
	(5, 'idz5', 'PED', 'Walk_Wuzi', 4, 1, 1, 1, 1, 1, 1), \
	(6, 'idz6', 'PED', 'WALK_player', 6, 1, 1, 1, 1, 1, 1), \
	(7, 'stopani', 'CARRY', 'crry_prtial', 4, 0, 0, 0, 0, 0, 0), \
	(8, 'pa', 'KISSING', 'gfwave2', 6, 0, 0, 0, 0, 0, 0), \
	(9, 'zmeczony', 'PED', 'IDLE_tired', 4, 1, 0, 0, 0, 0, 1), \
	(10, 'umyjrece', 'INT_HOUSE', 'wash_up', 4, 0, 0, 0, 0, 0, 0), \
	(11, 'medyk', 'MEDIC', 'CPR', 4, 0, 0, 0, 0, 0, 0), \
	(12, 'ranny', 'SWEET', 'Sweet_injuredloop', 4, 1, 0, 0, 1, 1, 1), \
	(13, 'salutuj', 'ON_LOOKERS', 'lkup_in', 4, 0, 1, 1, 1, 0, 1), \
	(14, 'wtf', 'RIOT', 'RIOT_ANGRY', 4, 0, 1, 1, 1, 1, 1), \
	(15, 'spoko', 'GANGS', 'prtial_gngtlkD', 4, 0, 0, 0, 0, 0, 0), \
	(16, 'napad', 'SHOP', 'ROB_Loop_Threat', 4, 1, 0, 0, 1, 1, 1), \
	(17, 'krzeslo', 'ped', 'SEAT_idle', 5, 1, 0, 0, 1, 1, 1), \
	(18, 'szukaj', 'COP_AMBIENT', 'Copbrowse_loop', 4, 1, 0, 0, 0, 0, 1), \
	(19, 'lornetka', 'ON_LOOKERS', 'shout_loop', 4, 1, 0, 0, 0, 0, 1), \
	(20, 'oh', 'MISC', 'plyr_shkhead', 4, 0, 0, 0, 0, 0, 0), \
	(21, 'oh2', 'OTB', 'wtchrace_lose', 4, 0, 1, 1, 0, 0, 0), \
	(22, 'wyciagnij', 'FOOD', 'SHP_Tray_Lift', 4, 0, 0, 0, 0, 0, 0), \
	(23, 'zdziwiony', 'PED', 'facsurp', 4, 0, 1, 1, 1, 1, 1), \
	(24, 'recemaska', 'POLICE', 'crm_drgbst_01', 6, 1, 0, 0, 1, 0, 1), \
	(25, 'krzeslojem', 'FOOD', 'FF_Sit_Eat1', 4, 1, 0, 0, 0, 0, 1), \
	(26, 'gogo', 'RIOT', 'RIOT_CHANT', 4, 1, 1, 1, 1, 0, 1), \
	(27, 'czekam', 'GRAVEYARD', 'prst_loopa', 4, 1, 0, 0, 1, 1, 1), \
	(28, 'garda', 'FIGHT_D', 'FightD_IDLE', 4, 1, 1, 1, 1, 0, 1), \
	(29, 'barman2', 'BAR', 'BARman_idle', 4, 0, 0, 0, 0, 0, 0), \
	(30, 'fotel', 'INT_HOUSE', 'LOU_Loop', 4, 1, 0, 0, 1, 1, 1), \
	(31, 'napraw', 'CAR', 'Fixn_Car_Loop', 4, 1, 0, 0, 1, 1, 1), \
	(32, 'barman', 'BAR', 'Barserve_loop', 4, 1, 0, 0, 0, 0, 1), \
	(33, 'opieraj', 'GANGS', 'leanIDLE', 4, 1, 0, 0, 1, 1, 1), \
	(34, 'bar.nalej', 'BAR', 'Barserve_glass', 4, 0, 0, 0, 0, 0, 0), \
	(35, 'ramiona', 'COP_AMBIENT', 'Coplook_loop', 4, 1, 0, 0, 1, 0, 1), \
	(36, 'bar.wez', 'BAR', 'Barserve_bottle', 4, 0, 0, 0, 0, 0, 0), \
	(37, 'chowaj', 'ped', 'cower', 3, 1, 0, 0, 0, 0, 1), \
	(38, 'wez', 'BAR', 'Barserve_give', 4, 0, 0, 0, 0, 0, 0), \
	(39, 'fuck', 'ped', 'fucku', 4, 0, 0, 0, 0, 0, 0), \
	(40, 'klepnij', 'SWEET', 'sweet_ass_slap', 6, 0, 0, 0, 0, 0, 0), \
	(41, 'cmon', 'RYDER', 'RYD_Beckon_01', 4, 0, 1, 1, 0, 0, 1), \
	(42, 'daj', 'DEALER', 'DEALER_DEAL', 8, 0, 0, 0, 0, 0, 0), \
	(43, 'pij', 'VENDING', 'VEND_Drink2_P', 4, 1, 1, 1, 1, 0, 1), \
	(44, 'start', 'CAR', 'flag_drop', 4, 0, 0, 0, 0, 0, 0), \
	(45, 'karta', 'HEIST9', 'Use_SwipeCard', 4, 0, 0, 0, 0, 0, 0), \
	(46, 'spray', 'GRAFFITI', 'spraycan_fire', 4, 1, 0, 0, 0, 0, 1), \
	(47, 'odejdz', 'POLICE', 'CopTraf_Left', 4, 0, 0, 0, 0, 0, 0), \
	(48, 'fotelk', 'JST_BUISNESS', 'girl_02', 4, 1, 0, 0, 1, 1, 1), \
	(49, 'chodz', 'POLICE', 'CopTraf_Come', 4, 0, 0, 0, 0, 0, 0), \
	(50, 'stop', 'POLICE', 'CopTraf_Stop', 4, 0, 0, 0, 0, 0, 0);");

    mysql_tquery(SQL_ID, "REPLACE INTO `anims` (`uid`, `cmd`, `lib`, `name`, `speed`, `loop/sa`, `lockx`, `locky`, `freeze`, `time`, `action`) VALUES \
	(51, 'drapjaja', 'MISC', 'Scratchballs_01', 4, 1, 0, 0, 0, 0, 1), \
	(52, 'opieraj2', 'MISC', 'Plyrlean_loop', 4, 1, 0, 0, 0, 0, 1), \
	(53, 'walekonia', 'PAULNMAC', 'wank_loop', 4, 1, 0, 0, 0, 0, 1), \
	(54, 'popchnij', 'GANGS', 'shake_cara', 4, 0, 0, 0, 0, 0, 0), \
	(55, 'rzuc', 'GRENADE', 'WEAPON_throwu', 3, 0, 0, 0, 0, 0, 0), \
	(56, 'rap1', 'RAPPING', 'RAP_A_Loop', 4, 1, 0, 0, 0, 0, 1), \
	(57, 'rap2', 'RAPPING', 'RAP_C_Loop', 4, 1, 0, 0, 0, 0, 1), \
	(58, 'rap3', 'RAPPING', 'RAP_B_Loop', 4, 1, 0, 0, 0, 0, 1), \
	(59, 'rap4', 'GANGS', 'prtial_gngtlkH', 4, 1, 0, 0, 1, 1, 1), \
	(60, 'glowka', 'WAYFARER', 'WF_Fwd', 4, 0, 0, 0, 0, 0, 0), \
	(61, 'skop', 'FIGHT_D', 'FightD_G', 4, 0, 0, 0, 0, 0, 0), \
	(62, 'siad', 'BEACH', 'ParkSit_M_loop', 4, 1, 0, 0, 0, 0, 1), \
	(63, 'krzeslo2', 'FOOD', 'FF_Sit_Loop', 4, 1, 0, 0, 0, 0, 1), \
	(64, 'krzeslo3', 'INT_OFFICE', 'OFF_Sit_Idle_Loop', 4, 1, 0, 0, 0, 0, 1), \
	(65, 'krzeslo4', 'INT_OFFICE', 'OFF_Sit_Bored_Loop', 4, 1, 0, 0, 0, 0, 1), \
	(66, 'krzeslo5', 'INT_OFFICE', 'OFF_Sit_Type_Loop', 4, 1, 0, 0, 0, 0, 1), \
	(67, 'padnij', 'PED', 'KO_shot_front', 4, 0, 1, 1, 1, 0, 1), \
	(68, 'padaczka', 'PED', 'FLOOR_hit_f', 4, 1, 0, 0, 0, 0, 1), \
	(69, 'unik', 'PED', 'EV_dive', 4, 0, 1, 1, 1, 0, 1), \
	(70, 'ranny3', 'CRACK', 'crckdeth2', 4, 1, 0, 0, 0, 0, 1), \
	(71, 'bomb', 'BOMBER', 'BOM_Plant', 4, 0, 0, 0, 0, 0, 1), \
	(72, 'cpaj', 'SHOP', 'ROB_Shifty', 4, 0, 0, 0, 0, 0, 1), \
	(73, 'rece', 'ROB_BANK', 'SHP_HandsUp_Scr', 4, 0, 1, 1, 1, 1, 1), \
	(74, 'tancz1', '-', '-', 0, 5, 0, 0, 0, 0, 2), \
	(75, 'tancz2', '-', '-', 0, 6, 0, 0, 0, 0, 2), \
	(76, 'tancz3', '-', '-', 0, 7, 0, 0, 0, 0, 2), \
	(77, 'tancz4', '-', '-', 0, 8, 0, 0, 0, 0, 2), \
	(78, 'tancz5', 'STRIP', 'STR_Loop_A', 2, 1, 0, 0, 0, 0, 1), \
	(79, 'pijak', 'PED', 'WALK_DRUNK', 4, 1, 1, 1, 1, 1, 1), \
	(80, 'nie', 'GANGS', 'Invite_No', 4, 0, 0, 0, 0, 0, 0), \
	(81, 'lokiec', 'CAR', 'Sit_relaxed', 4, 1, 1, 1, 1, 0, 1), \
	(82, 'go', 'RIOT', 'RIOT_PUNCHES', 4, 0, 0, 0, 0, 0, 0), \
	(83, 'stack1', 'GHANDS', 'gsign2LH', 4, 0, 0, 0, 0, 0, 0), \
	(84, 'lez3', 'BEACH', 'ParkSit_W_loop', 4, 1, 0, 0, 0, 0, 1), \
	(85, 'lez1', 'BEACH', 'bather', 4, 1, 0, 0, 0, 0, 1), \
	(86, 'lez2', 'BEACH', 'Lay_Bac_Loop', 4, 1, 0, 0, 0, 0, 1), \
	(87, 'padnij2', 'PED', 'KO_skid_front', 4, 0, 1, 1, 1, 0, 1), \
	(88, 'bat', 'CRACK', 'Bbalbat_Idle_01', 4, 1, 1, 1, 1, 1, 1), \
	(89, 'bat2', 'CRACK', 'Bbalbat_Idle_02', 4, 0, 1, 1, 1, 1, 1), \
	(90, 'stack2', 'GHANDS', 'gsign2', 4, 0, 1, 1, 1, 1, 1), \
	(91, 'stack3', 'GHANDS', 'gsign4', 4, 0, 1, 1, 1, 1, 1), \
	(92, 'taichi', 'PARK', 'Tai_Chi_Loop', 4, 1, 0, 0, 0, 0, 1), \
	(93, 'kosz1', 'BSKTBALL', 'BBALL_idleloop', 4, 1, 0, 0, 0, 0, 1), \
	(94, 'kosz2', 'BSKTBALL', 'BBALL_Jump_Shot', 4, 0, 0, 0, 0, 0, 1), \
	(95, 'kosz3', 'BSKTBALL', 'BBALL_pickup', 4, 0, 0, 0, 0, 0, 1), \
	(96, 'kosz4', 'BSKTBALL', 'BBALL_def_loop', 4, 1, 0, 0, 0, 0, 1), \
	(97, 'kosz5', 'BSKTBALL', 'BBALL_Dnk', 4, 0, 0, 0, 0, 0, 1), \
	(98, 'papieros', 'SMOKING', 'M_smklean_loop', 4, 1, 0, 0, 0, 0, 1), \
	(99, 'wymiotuj', 'FOOD', 'EAT_Vomit_P', 3, 0, 0, 0, 0, 0, 1), \
	(100, 'fuck2', 'RIOT', 'RIOT_FUKU', 4, 0, 0, 0, 0, 0, 0);");

    mysql_tquery(SQL_ID, "REPLACE INTO `anims` (`uid`, `cmd`, `lib`, `name`, `speed`, `loop/sa`, `lockx`, `locky`, `freeze`, `time`, `action`) VALUES \
	(101, 'koks', 'PED', 'IDLE_HBHB', 4, 1, 0, 0, 1, 0, 1), \
	(102, 'idz7', 'PED', 'WOMAN_walkshop', 4, 1, 1, 1, 1, 1, 1), \
	(103, 'cry', 'GRAVEYARD', 'mrnF_loop', 4, 1, 0, 0, 1, 0, 1), \
	(104, 'rozciagaj', 'PLAYIDLES', 'stretch', 4, 0, 0, 0, 0, 0, 1), \
	(105, 'cellin', '-', '-', 0, 11, 0, 0, 0, 0, 2), \
	(106, 'cellout', '-', '-', 0, 13, 0, 0, 0, 0, 2), \
	(107, 'bagaznik', 'POOL', 'POOL_Place_White', 4, 0, 0, 0, 1, 0, 1), \
	(108, 'wywaz', 'GANGS', 'shake_carK', 4, 0, 0, 0, 0, 0, 0), \
	(109, 'skradajsie', 'PED', 'Player_Sneak', 6, 1, 1, 1, 1, 1, 1), \
	(110, 'przycisk', 'CRIB', 'CRIB_use_switch', 4, 0, 0, 0, 0, 0, 1), \
	(111, 'tancz6', 'DANCING', 'DAN_down_A', 4, 1, 0, 0, 0, 0, 1), \
	(112, 'tancz7', 'DANCING', 'DAN_left_A', 4, 1, 0, 0, 0, 0, 1), \
	(113, 'idz8', 'PED', 'walk_shuffle', 4, 1, 1, 1, 1, 1, 1), \
	(114, 'stack4', 'LOWRIDER', 'prtial_gngtlkB', 4, 0, 0, 0, 0, 0, 1), \
	(115, 'stack5', 'LOWRIDER', 'prtial_gngtlkC', 4, 0, 1, 1, 1, 1, 1), \
	(116, 'stack6', 'lowrider', 'prtial_gngtlkD', 4, 0, 0, 0, 0, 0, 0), \
	(117, 'stack7', 'lowrider', 'prtial_gngtlkE', 4, 0, 0, 0, 0, 0, 1), \
	(118, 'stack8', 'lowrider', 'prtial_gngtlkF', 4, 0, 0, 0, 0, 0, 1), \
	(119, 'stack9', 'lowrider', 'prtial_gngtlkG', 4, 0, 0, 0, 0, 0, 1), \
	(120, 'stack10', 'lowrider', 'prtial_gngtlkH', 4, 0, 1, 1, 1, 1, 1), \
	(121, 'tancz8', 'DANCING', 'dnce_m_d', 4, 1, 0, 0, 0, 0, 1), \
	(122, 'kasjer', 'INT_SHOP', 'shop_cashier', 4, 0, 0, 0, 0, 0, 1), \
	(123, 'idz9', 'wuzi', 'wuzi_walk', 4, 1, 1, 1, 1, 1, 1), \
	(124, 'taxi', 'misc', 'hiker_pose', 4, 0, 0, 0, 1, 0, 1), \
	(125, 'wskaz', 'on_lookers', 'pointup_loop', 4, 0, 0, 0, 1, 0, 1), \
	(126, 'wskaz2', 'on_lookers', 'point_loop', 4, 0, 0, 0, 1, 0, 1), \
	(127, 'podpisz', 'otb', 'betslp_loop', 4, 0, 0, 0, 0, 0, 1), \
	(132, 'jedz', 'FOOD', 'EAT_Burger', 4.1, 0, 0, 0, 0, 0, 1), \
	(133, 'dealer', 'DEALER', 'DEALER_IDLE', 4.1, 1, 1, 1, 1, 0, 1), \
	(134, 'dealer2', 'DEALER', 'DEALER_IDLE_01', 4.1, 1, 1, 1, 0, 0, 1), \
	(135, 'dealer3', 'DEALER', 'DEALER_IDLE_02', 4.1, 1, 1, 1, 0, 0, 1), \
	(136, 'dealer4', 'DEALER', 'DEALER_IDLE_03', 4.1, 1, 1, 1, 0, 0, 1), \
	(137, 'siad2', 'ATTRACTORS', 'Stepsit_loop', 4.1, 1, 1, 1, 0, 0, 1), \
	(138, 'lokiec2', 'CAR', 'Tap_hand', 4.1, 1, 1, 1, 0, 0, 1), \
	(139, 'preload', 'COLT45', 'colt45_reload', 4.1, 0, 0, 0, 0, 1000, 1), \
	(140, 'mysl', 'COP_AMBIENT', 'Coplook_think', 4.1, 1, 1, 1, 0, 0, 1), \
	(141, 'zegarek', 'COP_AMBIENT', 'Coplook_watch', 4.1, 0, 0, 0, 0, 1000, 1), \
	(142, 'crack2', 'CRACK', 'crckidle1', 4.1, 1, 1, 1, 1, 0, 1), \
	(143, 'crack3', 'CRACK', 'crckidle2', 4.1, 1, 1, 1, 1, 0, 1), \
	(144, 'crack4', 'CRACK', 'crckidle3', 4.1, 1, 1, 1, 1, 0, 1), \
	(145, 'crack5', 'CRACK', 'crckidle4', 4.1, 1, 1, 1, 1, 0, 1), \
	(146, 'gang1', 'GANGS', 'prtial_gngtlkA', 4.1, 1, 1, 1, 1, 0, 1), \
	(147, 'gang2', 'GANGS', 'prtial_gngtlkB', 4.1, 1, 1, 1, 1, 0, 1), \
	(148, 'gang3', 'GANGS', 'prtial_gngtlkC', 4.1, 1, 1, 1, 1, 0, 1);");

    mysql_tquery(SQL_ID, "REPLACE INTO `anims` (`uid`, `cmd`, `lib`, `name`, `speed`, `loop/sa`, `lockx`, `locky`, `freeze`, `time`, `action`) VALUES \
	(149, 'gang4', 'GANGS', 'prtial_gngtlkD', 4.1, 1, 1, 1, 1, 0, 1), \
	(150, 'gang5', 'GANGS', 'prtial_gngtlkE', 4.1, 1, 1, 1, 1, 0, 1), \
	(151, 'gang6', 'GANGS', 'prtial_gngtlkF', 4.1, 1, 1, 1, 1, 0, 1), \
	(152, 'gang7', 'GANGS', 'prtial_gngtlkG', 4.1, 1, 1, 1, 1, 0, 1), \
	(153, 'gang8', 'GANGS', 'prtial_gngtlkH', 4.1, 1, 1, 1, 1, 0, 1), \
	(154, 'czekaj2', 'GRAVEYARD', 'mrnM_loop', 4.1, 1, 1, 1, 1, 0, 1), \
	(155, 'hide', 'PED', 'cower', 4.1, 1, 1, 1, 0, 0, 1), \
	(156, 'papieros2', 'LOWRIDER', 'F_smklean_loop', 4.1, 1, 1, 1, 0, 0, 1), \
	(157, 'kreload', 'RIFLE', 'RIFLE_load', 4.1, 0, 0, 0, 0, 1000, 1), \
	(158, 'stack11', 'GHANDS', 'gsign1', 4, 0, 0, 0, 0, 0, 0), \
	(159, 'stack12', 'GHANDS', 'gsign1LH', 4, 0, 0, 0, 0, 0, 0), \
	(160, 'stack13', 'GHANDS', 'gsign3', 4, 0, 0, 0, 0, 0, 0), \
	(161, 'stack14', 'GHANDS', 'gsign5', 4, 0, 0, 0, 0, 0, 0), \
	(162, 'stack15', 'GHANDS', 'gsign5LH', 4, 0, 0, 0, 0, 0, 0), \
	(163, 'ranny2', 'CRACK', 'crckdeth1', 4, 1, 0, 0, 0, 0, 1), \
	(166, 'ranny4', 'CRACK', 'crckidle3', 4, 1, 0, 0, 0, 0, 1), \
	(167, 'ranny5', 'CRACK', 'crckidle4', 4, 1, 0, 0, 0, 0, 1), \
	(168, '.bronidz', 'POLICE', 'Cop_move_FWD', 6, 1, 0, 0, 0, 0, 1);");
    return 1;
}

function OnLoadAllCreateActor()
{
    if(cache_num_rows() > 0)
    {
        new string[128], tick = GetTickCount();
        for(new i, j = cache_num_rows(); i < j; i++)
        {
            new id = Iter_Free(Actor_Iter);
            if(id > -1)
            {
                cache_get_value_int(i, "UID", ActorCache[id][aUID]);
                cache_get_value_name(i, "name", ActorCache[id][aName]);
                cache_get_value_float(i, "posx", ActorCache[id][aPosX]);
                cache_get_value_float(i, "posy", ActorCache[id][aPosY]);
                cache_get_value_float(i, "posz", ActorCache[id][aPosZ]);
                cache_get_value_float(i, "posrot", ActorCache[id][aPosRot]);
                cache_get_value_int(i, "skinid", ActorCache[id][aSkin]);
                cache_get_value_int(i, "qnumber", ActorCache[id][questnumber]);
                cache_get_value_name(i, "lib", ActorCache[id][aLib]);
                cache_get_value_name(i, "namea", ActorCache[id][aNamea]);

                if(ActorCache[id][questnumber] == 0) format(string, sizeof string, "{E6E6F0}%i. %s\n(Naciśnij N aby wejść w interakcje)", id, ActorCache[id][aName]);
                else if(ActorCache[id][questnumber] == 1) format(string, sizeof string, "%i. %s{00EBFF}(Pracodawca){E6E6F0}\n(Naciśnij N aby wejść w interakcje)", id, ActorCache[id][aName]);
                ActorCache[id][aID] = CreateDynamicActor(ActorCache[id][aSkin], ActorCache[id][aPosX], ActorCache[id][aPosY], ActorCache[id][aPosZ], ActorCache[id][aPosRot], true, 100.0, 0, 0, -1);
                PreloadActorAnimations(ActorCache[id][aID]);
                ActorCache[id][a3DTextID] = CreateDynamic3DTextLabel(string, 0xE6E6E6F0, ActorCache[id][aPosX], ActorCache[id][aPosY], ActorCache[id][aPosZ] + 1.065, 6.0);
                Iter_Add(Actor_Iter, id);
                if(strlen(ActorCache[id][aLib]) > 0) ApplyDynamicActorAnimation(ActorCache[id][aID], ActorCache[id][aLib], ActorCache[id][aNamea], 4.1, 1, 0, 0, 0, 0);
                #if DEBUG true
                printf("[DEBUG] Free Iter ID: %i", id);
                #endif
            }
            else
            {
                print("[INIT] Brak wolnych slotów w Iteratorze.");
                break;
            }
        }
        printf("[INIT] Załadowano %i aktorów w %ims.", cache_num_rows(), GetTickCount() - tick);
    }
    else print("[INIT] Brak aktorów w bazie danych.");
    return 1;
}

function LoadCreateActor()
{
    if(cache_insert_id() > 0)
    {
        query = "";
        mysql_format(SQL_ID, query, sizeof query, "SELECT * FROM actor WHERE `UID` = '%i'", cache_insert_id());
		mysql_tquery(SQL_ID, query, "OnLoadCreateActor");
    }
    return 1;
}

function OnLoadCreateActor()
{
    if(cache_num_rows() > 0)
    {
        new string[128];
        new id = Iter_Free(Actor_Iter);
        if(id > -1)
        {
            cache_get_value_int(0, "UID", ActorCache[id][aUID]);
            cache_get_value_name(0, "name", ActorCache[id][aName]);
            cache_get_value_float(0, "posx", ActorCache[id][aPosX]);
            cache_get_value_float(0, "posy", ActorCache[id][aPosY]);
            cache_get_value_float(0, "posz", ActorCache[id][aPosZ]);
            cache_get_value_float(0, "posrot", ActorCache[id][aPosRot]);
            cache_get_value_int(0, "skinid", ActorCache[id][aSkin]);
            cache_get_value_int(0, "qnumber", ActorCache[id][questnumber]);
            cache_get_value_name(0, "lib", ActorCache[id][aLib]);
            cache_get_value_name(0, "namea", ActorCache[id][aNamea]);

            if(ActorCache[id][questnumber] == 0) format(string, sizeof string, "{E6E6F0}%i. %s\n(Naciśnij N aby wejść w interakcje)", id, ActorCache[id][aName]);
            else if(ActorCache[id][questnumber] == 1) format(string, sizeof string, "%i. %s{00EBFF}(Pracodawca){E6E6F0}\n(Naciśnij N aby wejść w interakcje)", id, ActorCache[id][aName]);
            ActorCache[id][aID] = CreateDynamicActor(ActorCache[id][aSkin], ActorCache[id][aPosX], ActorCache[id][aPosY], ActorCache[id][aPosZ], ActorCache[id][aPosRot], true, 100.0, 0, 0, -1);
            PreloadActorAnimations(ActorCache[id][aID]);
            ActorCache[id][a3DTextID] = CreateDynamic3DTextLabel(string, 0xE6E6E6F0, ActorCache[id][aPosX], ActorCache[id][aPosY], ActorCache[id][aPosZ] + 1.065, 6.0);
            Iter_Add(Actor_Iter, id);
            if(strlen(ActorCache[id][aLib]) > 0) ApplyDynamicActorAnimation(ActorCache[id][aID], ActorCache[id][aLib], ActorCache[id][aNamea], 4.1, 1, 0, 0, 0, 0);
        }
        else print("[INIT] Brak wolnych slotów w Iteratorze.");
    }
    return 1;
}

function LoadAnimations()
{
	if(cache_num_rows() > 0)
	{
		new tick = GetTickCount();
		for(new i, j = cache_num_rows(); i < j; i++)
		{
			cache_get_value_int(i, "uid", AnimInfo[i][aUID]);
			cache_get_value_name(i, "cmd", AnimInfo[i][aCommand]);
			cache_get_value_name(i, "lib", AnimInfo[i][aLib]);
			cache_get_value_name(i, "name", AnimInfo[i][aNameAnim]);
			cache_get_value_float(i, "speed", AnimInfo[i][aSpeed]);
			cache_get_value_int(i, "loop/sa", AnimInfo[i][aOpt1]);
			cache_get_value_int(i, "lockx", AnimInfo[i][aOpt2]);
			cache_get_value_int(i, "locky", AnimInfo[i][aOpt3]);
			cache_get_value_int(i, "freeze", AnimInfo[i][aOpt4]);
			cache_get_value_int(i, "time", AnimInfo[i][aOpt5]);
			cache_get_value_int(i, "action", AnimInfo[i][aAction]);
		}
		printf("[INIT] Wczytano %d animacji/e w %ims.", cache_num_rows(), GetTickCount() - tick);
	}
    else print("[INIT] Brak animacji w bazie danych.");
	return 1;
}
