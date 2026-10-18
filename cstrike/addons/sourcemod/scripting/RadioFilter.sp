#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <clientprefs>
#include <string>

#undef REQUIRE_PLUGIN
#include <shavit/partner>
#define REQUIRE_PLUGIN

#pragma semicolon 1
#pragma newdecls required

#define _RADIO_FILTER_NAME          "RadioFilter"
#define _RADIO_FILTER_AUTHOR        "Lojka, Mee;w"
#define _RADIO_FILTER_DESCRIPTION   "Allows to filter clients that will recieve radio messages"
#define _RADIO_FILTER_VERSION       "v0.2-r0"
#define _RADIO_FILTER_URL           "https://github.com/herbary/radio-filter"

#define _RADIO_FILTER_GAMECONF_FILE                                             "RadioFilter.games"
#define _RADIO_FILTER_GAMECONF_CCSPLAYER__CONSTRUCTRADIOFILTER                  "CCSPlayer::ConstructRadioFilter"
#define _RADIO_FILTER_GAMECONF_CRECIPIENTFILTER__ADDRECIPIENT                   "CRecipientFilter::AddRecipient"
#define _RADIO_FILTER_GAMECONF_CRECIPIENTFILTER__REMOVERECIPIENTBYPLAYERINDEX   "CRecipientFilter::RemoveRecipientByPlayerIndex"
#define _RADIO_FILTER_GAMECONF_CRECIPIENTFILTER__GETRECIPIENTCOUNT              "CRecipientFilter::GetRecipientCount"
#define _RADIO_FILTER_GAMECONF_CRECIPIENTFILTER__GETRECIPIENTINDEX              "CRecipientFilter::GetRecipientIndex"

#define _RADIO_FILTER_MENU_TITLE                        "Radio Filter\n "
#define _RADIO_FILTER_MENU_SELECT "*"
#define _RADIO_FILTER_MENU_ALLOW_ALL                    "Allow All"
#define _RADIO_FILTER_MENU_ALLOW_ALL_DESCRIPTION        "Receive from:\n  • Yourself\n  • Anyone\n  • Partner"
#define _RADIO_FILTER_MENU_ALLOW_ALL_SELECT "a"
#define _RADIO_FILTER_MENU_SELF_ONLY                    "Self Only"
#define _RADIO_FILTER_MENU_SELF_ONLY_DESCRIPTION        "Receive from:\n  • Yourself"
#define _RADIO_FILTER_MENU_SELF_ONLY_SELECT "s"
#define _RADIO_FILTER_MENU_PARTNER_ONLY                 "Partner Only"
#define _RADIO_FILTER_MENU_PARTNER_ONLY_DESCRIPTION     "Receive from:\n  • Yourself\n  • Partner"
#define _RADIO_FILTER_MENU_PARTNER_ONLY_SELECT "p"
#define _RADIO_FILTER_MENU_SPEC_MODE                    "Spec Mode [%s]"
#define _RADIO_FILTER_MENU_INFO_MODE                    "Info Mode [%s]"
#define _RADIO_FILTER_MENU_SPEC_MODE_SELECT "e"
#define _RADIO_FILTER_MENU_INFO_MODE_SELECT "i"
#define _RADIO_FILTER_MENU_TMATCH "Match"
#define _RADIO_FILTER_MENU_TNONE "None"
#define _RADIO_FILTER_MENU_TSTATIC "Static"
#define _RADIO_FILTER_MENU_TDYNAMIC "Dynamic"

#define _RADIO_FILTER_COOKIE_DESCRIPTION_IMPL(%1) "[" ... _RADIO_FILTER_NAME ... " @ " ... _RADIO_FILTER_AUTHOR ... "] " ... %1

#define _RADIO_FILTER_COOKIE_NAME               "radio_filter"
#define _RADIO_FILTER_COOKIE_DESCRIPTION        _RADIO_FILTER_COOKIE_DESCRIPTION_IMPL("0 :: Allow All / 1 :: Self Only / 2 :: Partner Only")
#define _RADIO_FILTER_COOKIE_ALLOW_ALL          0
#define _RADIO_FILTER_COOKIE_SELF_ONLY          1
#define _RADIO_FILTER_COOKIE_PARTNER_ONLY       2
#define _RADIO_FILTER_COOKIE_COUNT              3
#define _RADIO_FILTER_COOKIE_DEFAULT            _RADIO_FILTER_COOKIE_ALLOW_ALL
#define _RADIO_FILTER_COOKIE_MIN                _RADIO_FILTER_COOKIE_ALLOW_ALL
#define _RADIO_FILTER_COOKIE_MAX                _RADIO_FILTER_COOKIE_PARTNER_ONLY

#define _RADIO_FILTER_COOKIE_SPEC_NAME          "radio_filter_spec"
#define _RADIO_FILTER_COOKIE_SPEC_DESCRIPTION    _RADIO_FILTER_COOKIE_DESCRIPTION_IMPL("0 :: Allow All / 1 :: Self Only / 2 :: Partner Only / 3 :: Match")
#define _RADIO_FILTER_COOKIE_SPEC_ALLOW_ALL     0
#define _RADIO_FILTER_COOKIE_SPEC_SELF_ONLY     1
#define _RADIO_FILTER_COOKIE_SPEC_PARTNER_ONLY  2
#define _RADIO_FILTER_COOKIE_SPEC_MATCH         3
#define _RADIO_FILTER_COOKIE_SPEC_COUNT         4
#define _RADIO_FILTER_COOKIE_SPEC_DEFAULT       _RADIO_FILTER_COOKIE_SPEC_MATCH

#define _RADIO_FILTER_COOKIE_INFO_NAME          "radio_filter_info"
#define _RADIO_FILTER_COOKIE_INFO_DESCRIPTION   _RADIO_FILTER_COOKIE_DESCRIPTION_IMPL("0 :: None / 1 :: Option / 2 :: Title")
#define _RADIO_FILTER_COOKIE_INFO_NONE          0
#define _RADIO_FILTER_COOKIE_INFO_STATIC        1
#define _RADIO_FILTER_COOKIE_INFO_DYNAMIC       2
#define _RADIO_FILTER_COOKIE_INFO_COUNT         3
#define _RADIO_FILTER_COOKIE_INFO_DEFAULT       _RADIO_FILTER_COOKIE_INFO_STATIC

// _RADIO_FILTER_CHAT_SOUND
// +-----------------------
// |
// | 0 :: Mute
// | 1 :: Play
// |
// | WARNING:
// |  As a side effect `0` also suppresses console output of the message
// +--------------------------------------------------------------------

#define _RADIO_FILTER_CHAT_SOUND            1
#define _RADIO_FILTER_CHAT_TAG              ">>"
#define _RADIO_FILTER_CHAT_COLOR_HEX        "\x07"
#define _RADIO_FILTER_CHAT_COLOR_WHITE      _RADIO_FILTER_CHAT_COLOR_HEX ... "FFFFFF"
#define _RADIO_FILTER_CHAT_COLOR_DARK_RED   _RADIO_FILTER_CHAT_COLOR_HEX ... "8F0007"
#define _RADIO_FILTER_CHAT_COLOR_COPPER     _RADIO_FILTER_CHAT_COLOR_HEX ... "C98363"
#define _RADIO_FILTER_CHAT_PREFIX           _RADIO_FILTER_CHAT_COLOR_DARK_RED ... _RADIO_FILTER_CHAT_TAG ... " "

#define _RADIO_FILTER_MESSAGE_SET _RADIO_FILTER_CHAT_PREFIX ... _RADIO_FILTER_CHAT_COLOR_WHITE ... "You have set radio filter to" ... _RADIO_FILTER_CHAT_COLOR_COPPER ... " %d" ... _RADIO_FILTER_CHAT_COLOR_WHITE ... " (" ... _RADIO_FILTER_CHAT_COLOR_COPPER ... "%s" ... _RADIO_FILTER_CHAT_COLOR_WHITE ... ")"

#define _RADIO_FILTER_PARTNER_UNKNOWN -1

Handle g_hCRecipientFilter__AddRecipient;
Handle g_hCRecipientFilter__RemoveRecipientByPlayerIndex;
Handle g_hCRecipientFilter__GetRecipientCount;
Handle g_hCRecipientFilter__GetRecipientIndex;

public Plugin myinfo = {
    name = _RADIO_FILTER_NAME,
    author = _RADIO_FILTER_AUTHOR,
    description = _RADIO_FILTER_DESCRIPTION,
    version = _RADIO_FILTER_VERSION,
    url = _RADIO_FILTER_URL
};

bool g_bLateLoaded = false;

Cookie g_ckRadioFilter;
Cookie g_ckSpecMode;
Cookie g_ckInfoMode;

int g_iRadioFilter[MAXPLAYERS + 1];
int g_iSpecMode[MAXPLAYERS + 1];
int g_iInfoMode[MAXPLAYERS + 1];

char g_szModes[_RADIO_FILTER_COOKIE_COUNT][64];
char g_szSpecModes[_RADIO_FILTER_COOKIE_SPEC_COUNT][64];
char g_szInfoModes[_RADIO_FILTER_COOKIE_INFO_COUNT][64];
char g_szDescriptions[_RADIO_FILTER_COOKIE_COUNT][128];

Menu g_hMenu[MAXPLAYERS + 1];

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int err_max)
{
    g_bLateLoaded = late;
    return APLRes_Success;
}

public void OnPluginStart()
{
    RadioFilter_InitGameData();

    RadioFilter_CreateGlobals();
    RadioFilter_CreateCookies();
    RadioFilter_CreateCommands();

    if (!g_bLateLoaded)
    {
        return;
    }
    for (int client = 1; client <= MaxClients; ++client)
    {
        if (IsClientInGame(client))
        {
            OnClientPutInServer(client);
        }
        if (AreClientCookiesCached(client))
        {
            OnClientCookiesCached(client);
        }
    }
}

public void OnClientPutInServer(int client)
{
    g_hMenu[client] = null;

    RadioFilter_InitLocals(client);
}

public void OnClientCookiesCached(int client)
{
    RadioFilter_InitLocals(client);
}

// void CCSPlayer::ConstructRadioFilter( CRecipientFilter& filter )
public MRESReturn DHook_CCSPlayer__ConstructRadioFilter(int sender, DHookParam hParams)
{
    M_CRecipientFilter filter = view_as<M_CRecipientFilter>(hParams.GetAddress(1));

    int count = filter.GetRecipientCount();
    for (int slot = count - 1; slot >= 0; --slot)
    {
        int client = filter.GetRecipientIndex(slot);
        if (RadioFilter_IsAllowed(client, sender))
        {
            continue;
        }

        filter.RemoveRecipient(client);
    }

    return MRES_Supercede;
}

static bool RadioFilter_IsAllowed(int client, int sender)
{
    if (!RadioFilter_IsPlayerInGame(client))
    {
        return false;
    }
    if (!RadioFilter_IsPlayerInGame(sender))
    {
        return false;
    }
    if (client == sender)
    {
        return true;
    }

    int filter = g_iRadioFilter[client];
    if (IsClientObserver(client) && g_iSpecMode[client] != _RADIO_FILTER_COOKIE_SPEC_MATCH)
    {
        filter = g_iSpecMode[client];
    }

    if (filter == _RADIO_FILTER_COOKIE_ALLOW_ALL)
    {
        return true;
    }
    if (filter == _RADIO_FILTER_COOKIE_SELF_ONLY)
    {
        return false;
    }

    int partner = RadioFilter_GetPartner(client);
    if (partner != _RADIO_FILTER_PARTNER_UNKNOWN && partner == sender)
    {
        return true;
    }

    if (!IsClientObserver(client))
    {
        return false;
    }

    int mode = GetEntProp(client, Prop_Send, "m_iObserverMode");
    if (mode < 4 || mode > 6)
    {
        return false;
    }

    int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
    if (!RadioFilter_IsPlayerInGame(target))
    {
        return false;
    }
    if (target == sender)
    {
        return true;
    }

    partner = RadioFilter_GetPartner(target);
    if (partner != _RADIO_FILTER_PARTNER_UNKNOWN && partner == sender)
    {
        return true;
    }

    return false;
}

static Action Command_Radio(int client, int argc)
{
    if (!RadioFilter_IsPlayerInGame(client))
    {
        return Plugin_Handled;
    }

    if (argc == 0)
    {
        Menu_Radio(client);
        return Plugin_Handled;
    }

    char arg[64] = "";
    GetCmdArg(1, arg, sizeof(arg));

    TrimString(arg);
    StripQuotes(arg);

    int mode = -1;
    int c = StringToIntEx(arg, mode);
    if (c <= 0)
    {
        Menu_Radio(client);
        return Plugin_Handled;
    }

    if (mode < _RADIO_FILTER_COOKIE_MIN || mode > _RADIO_FILTER_COOKIE_MAX)
    {
        Menu_Radio(client);
        return Plugin_Handled;
    }
    bool changed = RadioFilter_SetCookie(client, mode);

    bool flag = true;
    if (argc > 1)
    {
        char arg2[64] = "";
        GetCmdArg(2, arg2, sizeof(arg2));

        TrimString(arg2);
        StripQuotes(arg2);

        int j = 1;
        int l = StringToIntEx(arg2, j);

        flag = !(l > 0 && j == 0);
    }
    if (flag)
    {
        char szMessage[256] = "";
        FormatEx(szMessage, sizeof(szMessage), _RADIO_FILTER_MESSAGE_SET, mode, g_szModes[mode]);
        if (szMessage[0] != '\0')
        {
            RadioFilter_SayText2(client, szMessage);
        }
    }

    if (changed && g_hMenu[client] != null)
    {
        Menu_Radio(client);
    }

    return Plugin_Handled;
}

static void Menu_Radio(int client)
{
    if (!RadioFilter_IsPlayerInGame(client))
    {
        return;
    }

    Menu menu = new Menu(MenuHandler_Radio);
    menu.SetTitle(_RADIO_FILTER_MENU_TITLE);

    char szItem[256];

    if (g_iInfoMode[client] == _RADIO_FILTER_COOKIE_INFO_DYNAMIC)
    {
        if (g_iRadioFilter[client] == _RADIO_FILTER_COOKIE_ALLOW_ALL)
        {
            FormatEx(szItem, sizeof(szItem), "%s %s\n \n%s\n ", _RADIO_FILTER_MENU_ALLOW_ALL, _RADIO_FILTER_MENU_SELECT, _RADIO_FILTER_MENU_ALLOW_ALL_DESCRIPTION);
        }
        else if (g_iRadioFilter[client] == _RADIO_FILTER_COOKIE_SELF_ONLY)
        {
            FormatEx(szItem, sizeof(szItem), "%s\n ", _RADIO_FILTER_MENU_ALLOW_ALL);
        }
        else
        {
            strcopy(szItem, sizeof(szItem), _RADIO_FILTER_MENU_ALLOW_ALL);
        }
    }
    else
    {
        if (g_iRadioFilter[client] == _RADIO_FILTER_COOKIE_ALLOW_ALL)
        {
            FormatEx(szItem, sizeof(szItem), "%s %s", _RADIO_FILTER_MENU_ALLOW_ALL, _RADIO_FILTER_MENU_SELECT);
        }
        else
        {
            strcopy(szItem, sizeof(szItem), _RADIO_FILTER_MENU_ALLOW_ALL);
        }
    }
    menu.AddItem(_RADIO_FILTER_MENU_ALLOW_ALL_SELECT, szItem);

    if (g_iInfoMode[client] == _RADIO_FILTER_COOKIE_INFO_DYNAMIC)
    {
        if (g_iRadioFilter[client] == _RADIO_FILTER_COOKIE_SELF_ONLY)
        {
            FormatEx(szItem, sizeof(szItem), "%s %s\n \n%s\n ", _RADIO_FILTER_MENU_SELF_ONLY, _RADIO_FILTER_MENU_SELECT, _RADIO_FILTER_MENU_SELF_ONLY_DESCRIPTION);
        }
        else if (g_iRadioFilter[client] == _RADIO_FILTER_COOKIE_PARTNER_ONLY)
        {
            FormatEx(szItem, sizeof(szItem), "%s\n ", _RADIO_FILTER_MENU_SELF_ONLY);
        }
        else
        {
            strcopy(szItem, sizeof(szItem), _RADIO_FILTER_MENU_SELF_ONLY);
        }
    }
    else
    {
        if (g_iRadioFilter[client] == _RADIO_FILTER_COOKIE_SELF_ONLY)
        {
            FormatEx(szItem, sizeof(szItem), "%s %s", _RADIO_FILTER_MENU_SELF_ONLY, _RADIO_FILTER_MENU_SELECT);
        }
        else
        {
            strcopy(szItem, sizeof(szItem), _RADIO_FILTER_MENU_SELF_ONLY);
        }
    }
    menu.AddItem(_RADIO_FILTER_MENU_SELF_ONLY_SELECT, szItem);

    if (g_iInfoMode[client] == _RADIO_FILTER_COOKIE_INFO_DYNAMIC)
    {
        if (g_iRadioFilter[client] == _RADIO_FILTER_COOKIE_PARTNER_ONLY)
        {
            FormatEx(szItem, sizeof(szItem), "%s %s\n \n%s", _RADIO_FILTER_MENU_PARTNER_ONLY, _RADIO_FILTER_MENU_SELECT, _RADIO_FILTER_MENU_PARTNER_ONLY_DESCRIPTION);
        }
        else
        {
            strcopy(szItem, sizeof(szItem), _RADIO_FILTER_MENU_PARTNER_ONLY);
        }
    }
    else
    {
        if (g_iRadioFilter[client] == _RADIO_FILTER_COOKIE_PARTNER_ONLY)
        {
            FormatEx(szItem, sizeof(szItem), "%s %s", _RADIO_FILTER_MENU_PARTNER_ONLY, _RADIO_FILTER_MENU_SELECT);
        }
        else
        {
            strcopy(szItem, sizeof(szItem), _RADIO_FILTER_MENU_PARTNER_ONLY);
        }
    }
    if (g_iInfoMode[client] == _RADIO_FILTER_COOKIE_INFO_STATIC)
    {
        Format(szItem, sizeof(szItem), "%s\n \n%s", szItem, g_szDescriptions[g_iRadioFilter[client]]);
    }
    Format(szItem, sizeof(szItem), "%s\n ", szItem);
    menu.AddItem(_RADIO_FILTER_MENU_PARTNER_ONLY_SELECT, szItem);

    FormatEx(szItem, sizeof(szItem), _RADIO_FILTER_MENU_SPEC_MODE, g_szSpecModes[g_iSpecMode[client]]);
    menu.AddItem(_RADIO_FILTER_MENU_SPEC_MODE_SELECT, szItem);

    FormatEx(szItem, sizeof(szItem), _RADIO_FILTER_MENU_INFO_MODE, g_szInfoModes[g_iInfoMode[client]]);
    menu.AddItem(_RADIO_FILTER_MENU_INFO_MODE_SELECT, szItem);

    menu.ExitBackButton = false;
    menu.ExitButton = true;

    menu.Display(client, MENU_TIME_FOREVER);
    g_hMenu[client] = menu;
}

static void MenuHandler_Radio(Menu menu, MenuAction action, int client, int index)
{
    if (action == MenuAction_End)
    {
        delete menu;
        return;
    }
    if (action == MenuAction_Cancel)
    {
        g_hMenu[client] = null;
        return;
    }
    if (action != MenuAction_Select)
    {
        return;
    }
    if (!RadioFilter_IsPlayerInGame(client))
    {
        return;
    }

    char szInfo[8];
    if (!menu.GetItem(index, szInfo, sizeof(szInfo)))
    {
        return;
    }

    if (szInfo[0] == _RADIO_FILTER_MENU_ALLOW_ALL_SELECT[0])
    {
        MenuSelect_AllowAll(client);
    }
    else if (szInfo[0] == _RADIO_FILTER_MENU_SELF_ONLY_SELECT[0])
    {
        MenuSelect_SelfOnly(client);
    }
    else if (szInfo[0] == _RADIO_FILTER_MENU_PARTNER_ONLY_SELECT[0])
    {
        MenuSelect_PartnerOnly(client);
    }
    else if (szInfo[0] == _RADIO_FILTER_MENU_SPEC_MODE_SELECT[0])
    {
        MenuSelect_SpecMode(client);
    }
    else if (szInfo[0] == _RADIO_FILTER_MENU_INFO_MODE_SELECT[0])
    {
        MenuSelect_InfoMode(client);
    }

    Menu_Radio(client);
}

static void MenuSelect_AllowAll(int client)
{
    RadioFilter_SetCookie(client, _RADIO_FILTER_COOKIE_ALLOW_ALL);
}

static void MenuSelect_SelfOnly(int client)
{
    RadioFilter_SetCookie(client, _RADIO_FILTER_COOKIE_SELF_ONLY);
}

static void MenuSelect_PartnerOnly(int client)
{
    RadioFilter_SetCookie(client, _RADIO_FILTER_COOKIE_PARTNER_ONLY);
}

static void MenuSelect_SpecMode(int client)
{
    RadioFilter_CycleCookie(client, g_ckSpecMode, g_iSpecMode, _RADIO_FILTER_COOKIE_SPEC_COUNT);
}

static void MenuSelect_InfoMode(int client)
{
    RadioFilter_CycleCookie(client, g_ckInfoMode, g_iInfoMode, _RADIO_FILTER_COOKIE_INFO_COUNT);
}

static bool RadioFilter_SetCookie(int client, int value)
{
    if (!RadioFilter_IsPlayerInGame(client))
    {
        return false;
    }
    if (g_iRadioFilter[client] == value)
    {
        return false;
    }

    g_iRadioFilter[client] = value;
    g_ckRadioFilter.SetInt(client, g_iRadioFilter[client]);
    return true;
}

static void RadioFilter_CycleCookie(int client, Cookie cookie, int storage[MAXPLAYERS + 1], int count)
{
    if (!RadioFilter_IsPlayerInGame(client))
    {
        return;
    }

    storage[client] = (storage[client] + 1) % count;
    cookie.SetInt(client, storage[client]);
}

static void RadioFilter_InitGameData()
{
    GameData hGameData = new GameData(_RADIO_FILTER_GAMECONF_FILE);
    if (hGameData == null) {
        delete hGameData;
        SetFailState("Failed to load \"%s\" GameData", _RADIO_FILTER_GAMECONF_FILE);
        return;
    }

    DynamicDetour hCCSPlayer__ConstructRadioFilter = new DynamicDetour(Address_Null, CallConv_THISCALL, ReturnType_Void, ThisPointer_CBaseEntity);
    if (hCCSPlayer__ConstructRadioFilter == null)
    {
        delete hGameData;
        SetFailState("Failed to create \"%s\" DynamicDetour", _RADIO_FILTER_GAMECONF_CCSPLAYER__CONSTRUCTRADIOFILTER);
        return;
    }
    if (!hCCSPlayer__ConstructRadioFilter.SetFromConf(hGameData, SDKConf_Signature, _RADIO_FILTER_GAMECONF_CCSPLAYER__CONSTRUCTRADIOFILTER))
    {
        delete hGameData;
        SetFailState("Failed to find \"%s\" signature", _RADIO_FILTER_GAMECONF_CCSPLAYER__CONSTRUCTRADIOFILTER);
        return;
    }
    hCCSPlayer__ConstructRadioFilter.AddParam(HookParamType_ObjectPtr);
    if (!hCCSPlayer__ConstructRadioFilter.Enable(Hook_Post, DHook_CCSPlayer__ConstructRadioFilter))
    {
        delete hGameData;
        SetFailState("Failed to enable \"%s\" detour", _RADIO_FILTER_GAMECONF_CCSPLAYER__CONSTRUCTRADIOFILTER);
        return;
    }

    // void CRecipientFilter::AddRecipient( const CBasePlayer *player )
    StartPrepSDKCall(SDKCall_Raw);
    PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, _RADIO_FILTER_GAMECONF_CRECIPIENTFILTER__ADDRECIPIENT);
    PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer); // const CBasePlayer *player
    g_hCRecipientFilter__AddRecipient = EndPrepSDKCall();
    if (g_hCRecipientFilter__AddRecipient == INVALID_HANDLE)
    {
        delete hGameData;
        SetFailState("Failed to initialize \"%s\" call", _RADIO_FILTER_GAMECONF_CRECIPIENTFILTER__ADDRECIPIENT);
        return;
    }

    // void RemoveRecipientByPlayerIndex( int playerindex );
    StartPrepSDKCall(SDKCall_Raw);
    PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CRecipientFilter::RemoveRecipientByPlayerIndex");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    g_hCRecipientFilter__RemoveRecipientByPlayerIndex = EndPrepSDKCall();
    if (g_hCRecipientFilter__RemoveRecipientByPlayerIndex == INVALID_HANDLE)
    {
        delete hGameData;
        SetFailState("Failed to initialize \"%s\" call", _RADIO_FILTER_GAMECONF_CRECIPIENTFILTER__REMOVERECIPIENTBYPLAYERINDEX);
        return;
    }

    // virtual int GetRecipientCount( void ) const;
    StartPrepSDKCall(SDKCall_Raw);
    PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CRecipientFilter::GetRecipientCount");
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
    g_hCRecipientFilter__GetRecipientCount = EndPrepSDKCall();
    if (g_hCRecipientFilter__GetRecipientCount == INVALID_HANDLE)
    {
        delete hGameData;
        SetFailState("Failed to initialize \"%s\" call", _RADIO_FILTER_GAMECONF_CRECIPIENTFILTER__GETRECIPIENTCOUNT);
        return;
    }

    // virtual int GetRecipientIndex( int slot ) const;
    StartPrepSDKCall(SDKCall_Raw);
    PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CRecipientFilter::GetRecipientIndex");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
    g_hCRecipientFilter__GetRecipientIndex = EndPrepSDKCall();
    if (g_hCRecipientFilter__GetRecipientIndex == INVALID_HANDLE)
    {
        delete hGameData;
        SetFailState("Failed to initialize \"%s\" call", _RADIO_FILTER_GAMECONF_CRECIPIENTFILTER__GETRECIPIENTINDEX);
        return;
    }

    delete hGameData;
}

static void RadioFilter_InitLocals(int client)
{
    g_iRadioFilter[client] = g_ckRadioFilter.GetInt(client, _RADIO_FILTER_COOKIE_DEFAULT);
    g_iSpecMode[client] = g_ckSpecMode.GetInt(client, _RADIO_FILTER_COOKIE_SPEC_DEFAULT);
    g_iInfoMode[client] = g_ckInfoMode.GetInt(client, _RADIO_FILTER_COOKIE_INFO_DEFAULT);
}

static void RadioFilter_CreateGlobals()
{
    g_szModes[_RADIO_FILTER_COOKIE_ALLOW_ALL] = _RADIO_FILTER_MENU_ALLOW_ALL;
    g_szModes[_RADIO_FILTER_COOKIE_SELF_ONLY] = _RADIO_FILTER_MENU_SELF_ONLY;
    g_szModes[_RADIO_FILTER_COOKIE_PARTNER_ONLY] = _RADIO_FILTER_MENU_PARTNER_ONLY;

    g_szSpecModes[_RADIO_FILTER_COOKIE_SPEC_ALLOW_ALL] = _RADIO_FILTER_MENU_ALLOW_ALL;
    g_szSpecModes[_RADIO_FILTER_COOKIE_SPEC_SELF_ONLY] = _RADIO_FILTER_MENU_SELF_ONLY;
    g_szSpecModes[_RADIO_FILTER_COOKIE_SPEC_PARTNER_ONLY] = _RADIO_FILTER_MENU_PARTNER_ONLY;
    g_szSpecModes[_RADIO_FILTER_COOKIE_SPEC_MATCH] = _RADIO_FILTER_MENU_TMATCH;

    g_szInfoModes[_RADIO_FILTER_COOKIE_INFO_NONE] = _RADIO_FILTER_MENU_TNONE;
    g_szInfoModes[_RADIO_FILTER_COOKIE_INFO_STATIC] = _RADIO_FILTER_MENU_TSTATIC;
    g_szInfoModes[_RADIO_FILTER_COOKIE_INFO_DYNAMIC] = _RADIO_FILTER_MENU_TDYNAMIC;

    g_szDescriptions[_RADIO_FILTER_COOKIE_ALLOW_ALL] = _RADIO_FILTER_MENU_ALLOW_ALL_DESCRIPTION;
    g_szDescriptions[_RADIO_FILTER_COOKIE_SELF_ONLY] = _RADIO_FILTER_MENU_SELF_ONLY_DESCRIPTION;
    g_szDescriptions[_RADIO_FILTER_COOKIE_PARTNER_ONLY] = _RADIO_FILTER_MENU_PARTNER_ONLY_DESCRIPTION;
}

static void RadioFilter_CreateCookies()
{
    g_ckRadioFilter = RegClientCookie(_RADIO_FILTER_COOKIE_NAME, _RADIO_FILTER_COOKIE_DESCRIPTION, CookieAccess_Protected);
    g_ckSpecMode = RegClientCookie(_RADIO_FILTER_COOKIE_SPEC_NAME, _RADIO_FILTER_COOKIE_SPEC_DESCRIPTION, CookieAccess_Protected);
    g_ckInfoMode = RegClientCookie(_RADIO_FILTER_COOKIE_INFO_NAME, _RADIO_FILTER_COOKIE_INFO_DESCRIPTION, CookieAccess_Protected);
}

static void RadioFilter_CreateCommands()
{
    RegConsoleCmd("sm_radio", Command_Radio);
    RegConsoleCmd("sm_rf", Command_Radio);
}

static stock int RadioFilter_GetPartner(int client)
{
    if (GetFeatureStatus(FeatureType_Native, "Timer_GetPartner") != FeatureStatus_Available)
    {
        return _RADIO_FILTER_PARTNER_UNKNOWN;
    }

    int partner = Timer_GetPartner(client);
    if (!RadioFilter_IsPlayerInGame(partner) || !IsPlayerAlive(partner))
    {
        return _RADIO_FILTER_PARTNER_UNKNOWN;
    }

    return partner;
}

static stock void RadioFilter_SayText2(int client, char[] szMessage)
{
    if (!RadioFilter_IsPlayerInGame(client))
    {
        return;
    }

    Handle hSayText2 = StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
    if (hSayText2 == INVALID_HANDLE)
    {
        return;
    }

    BfWrite bfMsg = UserMessageToBfWrite(hSayText2);
    bfMsg.WriteByte(client);
    bfMsg.WriteByte(_RADIO_FILTER_CHAT_SOUND);
    bfMsg.WriteString(szMessage);
    EndMessage();
}

static stock bool RadioFilter_IsPlayerInGame(int client)
{
    return RadioFilter_IsPlayer(client) && IsClientInGame(client);
}

static stock bool RadioFilter_IsClientInGame(int client)
{
    return RadioFilter_IsClient(client) && IsClientInGame(client);
}

static stock bool RadioFilter_IsPlayer(int client)
{
    return RadioFilter_IsClient(client) && !IsFakeClient(client);
}

static stock bool RadioFilter_IsClient(int client)
{
    return client >= 1 && client <= MaxClients;
}

methodmap M_CRecipientFilter
{
    public M_CRecipientFilter(Address addr)
    {
        return view_as<M_CRecipientFilter>(addr);
    }

    public void AddRecipient(int playerindex)
    {
        SDKCall(g_hCRecipientFilter__AddRecipient, view_as<Address>(this), playerindex);
    }

    public void RemoveRecipient(int playerindex)
    {
        SDKCall(g_hCRecipientFilter__RemoveRecipientByPlayerIndex, view_as<Address>(this), playerindex);
    }

    public int GetRecipientCount()
    {
        return SDKCall(g_hCRecipientFilter__GetRecipientCount, view_as<Address>(this));
    }

    public int GetRecipientIndex(int slot)
    {
        return SDKCall(g_hCRecipientFilter__GetRecipientIndex, view_as<Address>(this), slot);
    }
}
