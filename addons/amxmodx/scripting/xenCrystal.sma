/*
*
*	Xen Crystal by RedSMURF
*
*
*	Description:
*
*	Cvars:
*		None
*
*	Commands:
*       say /xc                             "Opens the Xen Crystal menu."
*       say_team /xc                        "Opens the Xen Crystal menu."
*       say /xen_crystal                    "Opens the Xen Crystal menu."
*       say_team /xen_crystal               "Opens the Xen Crystal menu."
*       xc_reload                           "Reloads the configuration file."
*       xencrystal_reload                   "Reloads the configuration file."
*
*	Changelog:
*       v1.0: Initial release.
*
*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>

#if !defined MAX_PLAYERS
    #define MAX_PLAYERS 32
#endif

#if !defined MAX_VALUE_LENGTH
    #define MAX_VALUE_LENGTH 64
#endif

#if !defined MAX_RESOURCE_PATH_LENGTH
    #define MAX_RESOURCE_PATH_LENGTH 128
#endif

#if !defined MAX_FILE_CELL_SIZE
    #define MAX_FILE_CELL_SIZE 192
#endif

#if !defined MAX_PLATFORM_PATH_LENGTH
    #define MAX_PLATFORM_PATH_LENGTH 256
#endif

#define MAX_ENT                     32
#define ADMIN_ACCESS                ADMIN_RCON
#define CRYSTAL_KEY                 908070
#define CRYSTAL_ARRAY_ITEM          pev_iuser1
#define CRYSTAL_DLIGHT_SCALE_MAX    100
#define CRYSTAL_DLIGHT_SCALE_MIN    1
#define PDATA_NEXT_ATTACK           83
#define XO_CBASEPLAYER              5
#define XO_CBASEPLAYERWEAPON        4
#define SOUND_NAV                   "buttons/blip1.wav"
#define SOUND_REMOVE                "buttons/button10.wav"
#define SOUND_ALERT                 "buttons/bell1.wav"

new const PLUGIN_VERSION[]          = "1.0"
new const Float:DELAY_ON_CONNECT    = 1.0
new const Float:DELAY_ON_LOAD       = 2.0
new const ERROR_FILE[]              = "XenCrystal_ERRORS.log"

enum
{
    SECTION_NONE,
    SECTION_MAIN_SETTINGS,
    SECTION_CRYSTAL
}

enum
{
    DTYPE_INT,
    DTYPE_FLOAT,
    DTYPE_FLAGS,
    DTYPE_ARRAY_STRING,
    DTYPE_ARRAY_SOUND,
    DTYPE_STRING_MODEL,
    DTYPE_STRING_SOUND,
    DTYPE_STRING_MODEL_ID
}

enum
{
    FLAG_SOLID              = (1 << 0),
    FLAG_REVERSE            = (1 << 1),
    FLAG_COLOR_RANDOM       = (1 << 2),

    FLAG_SHOW               = (1 << 3),
    FLAG_GHOST              = (1 << 4),
    FLAG_GROUND             = (1 << 5),
    FLAG_ACTIVE             = (1 << 6),
    FLAG_LOCK               = (1 << 7),
    FLAG_PENDING            = (1 << 8)
}

enum
{
    ROTATE_MODE_PITCH,
    ROTATE_MODE_YAW,
    ROTATE_MODE_ROLL
}

enum
{
    TEAM_NONE,
    TEAM_T,
    TEAM_CT,
    TEAM_BOTH
}

enum
{
    SIZE_NORMAL,
    SIZE_LARGE
}

enum
{
    SHAPE_1,
    SHAPE_2,
    SHAPE_3
}

enum
{
    TARGET_GHOST,
    TARGET_SELECT,
    TARGET_HIDE,
    TARGET_CLEAR
}

enum _:MAIN_SETTINGS
{
    SETTING_DEFAULT_FLAGS,
    SETTING_DEFAULT_TEAM,
    Float:SETTING_DEFAULT_FRAMERATE,

    Float:SETTING_DEFAULT_TRIGGER_DISTANCE,
    Float:SETTING_DEFAULT_TRIGGER_DURATION[2],
    Float:SETTING_DEFAULT_COLOR_FREQUENCY[2],

    SETTING_MODEL_CRYSTAL_NORMAL[MAX_RESOURCE_PATH_LENGTH],
    SETTING_MODEL_CRYSTAL_LARGE[MAX_RESOURCE_PATH_LENGTH],
    Float:SETTING_MINS_NORMAL[3],
    Float:SETTING_MAXS_NORMAL[3],
    Float:SETTING_MINS_LARGE[3],
    Float:SETTING_MAXS_LARGE[3],

    bool:SETTING_CRYSTAL_LOAD,
    Float:SETTING_CRYSTAL_CHECK,
    Float:SETTING_CRYSTAL_TASK,
    Float:SETTING_OFFSET_BASE,
    Float:SETTING_OFFSET[2],
    Float:SETTING_OFFSET_STEP,
    SETTING_GHOST_ALPHA,
    Float:SETTING_ROTATION_STEP,
    SETTING_CRYSTAL_LIFE
}

enum _:CRYSTAL
{
    CRYSTAL_ID,
    CRYSTAL_ITEM,
    CRYSTAL_FLAGS,
    CRYSTAL_TEAM,
    CRYSTAL_SIZE,
    CRYSTAL_SHAPE,
    CRYSTAL_NAME[MAX_VALUE_LENGTH],

    Float:CRYSTAL_ORIGIN[3],
    Float:CRYSTAL_ANGLES[3],
    Float:CRYSTAL_MINS[3],
    Float:CRYSTAL_MAXS[3],

    Float:CRYSTAL_FRAMERATE,
    Float:CRYSTAL_TRIGGER_DISTANCE,
    Float:CRYSTAL_TRIGGER_DURATION[2],
    Float:CRYSTAL_COLOR_FREQUENCY[2],
    CRYSTAL_DLIGHT_COLOR[3],
    CRYSTAL_DLIGHT_SCALE,

    Float:CRYSTAL_NEXT_SHOW,
    Float:CRYSTAL_NEXT_HIDE,
    Float:CRYSTAL_NEXT_RANDOM
}

enum _:PLAYER_DATA
{
    PDATA_CRYSTAL_GHOST,
    PDATA_CRYSTAL_MENU,
    bool:PDATA_CRYSTAL_ACTION,
    PDATA_ROTATE_MODE,
    PDATA_ROTATE_SIZE,
    PDATA_ROTATE_SHAPE,
    PDATA_LIGHT_FACTOR,
    PDATA_LIGHT_COLOR,
    Float:PDATA_OFFSET,
    Float:PDATA_NEXT_OFFSET,

    PDATA_MENU_TYPE,
    bool:PDATA_MENU_TRACE
}

enum
{
    SOUND_MENU_NAV,
    SOUND_MENU_REMOVE,
    SOUND_MENU_ALERT
}

enum
{
    MENU_ROOT,
    MENU_CREATE,
    MENU_EDIT,
    MENU_REMOVE,
    MENU_SHOW,
    MENU_STATUS,
    MENU_ROTATE,
    MENU_LIGHT
}

enum
{
    ROOT_CREATE,
    ROOT_EDIT,
    ROOT_REMOVE,
    ROOT_SAVE,

    ROOT_NOCLIP = 5,
    ROOT_GODMODE
}

enum
{
    EDIT_SHOW,
    EDIT_STATUS
}

enum
{
    REMOVE_NEXT,
    REMOVE_BACK,

    REMOVE_CURRENT = 3,
    REMOVE_ALL
}

enum
{
    SHOW_NEXT,
    SHOW_BACK,

    SHOW_CURRENT = 3,
    SHOW_ALL_SHOW,
    SHOW_ALL_HIDE
}

enum
{
    STATUS_NEXT,
    STATUS_BACK,

    STATUS_CURRENT = 3,
    STATUS_ALL_ENABLE,
    STATUS_ALL_DISABLE
}

enum
{
    ROTATE_UP,
    ROTATE_DOWN,
    ROTATE_GROUND,
    ROTATE_MODE,
    ROTATE_SIZE,
    ROTATE_SHAPE,
    ROTATE_PLACE
}

enum
{
    LIGHT_SCALE_UP,
    LIGHT_SCALE_DOWN,

    LIGHT_FACTOR = 3,
    LIGHT_COLOR,
    LIGHT_PLACE
}

new Float:g_fDirections[][] =
{
    {-1.0, 0.0, 0.0},
    {1.0, 0.0, 0.0},
    {0.0, -1.0, 0.0},
    {0.0, 1.0, 0.0},
    {0.0, 0.0, -1.0},
    {0.0, 0.0, 1.0}
}

new g_szMenuHandler[][MAX_VALUE_LENGTH] =
{
    "menuHandlerRoot",
    "menuHandlerCreate",
    "menuHandlerEdit",
    "menuHandlerRemove",
    "menuHandlerShow",
    "menuHandlerStatus",
    "menuHandlerRotate",
    "menuHandlerLight"
}

new g_szCN[] = "xen_crystal"

new Array:g_aCrystal,
    Array:g_aCrystalConfig,
    g_eSettings[MAIN_SETTINGS],
    g_ePlayerData[MAX_PLAYERS + 1][PLAYER_DATA],
    bool:g_bFileWasRead, g_iActivePlayers,
    HamHook:g_iFwdPreThink, HamHook:g_iFwdKilled,
    g_iCrystal, g_iCrystalConfig,
    g_iMaxPlayers

new const g_iColorActive[] = { 0, 255, 0 }
new const g_iColorInactive[] = { 255, 0, 0 }
new g_szRotateMode[][] = {"CRYSTAL_ROTATE_PITCH", "CRYSTAL_ROTATE_YAW", "CRYSTAL_ROTATE_ROLL"}
new g_szRotateSize[][] = {"CRYSTAL_ROTATE_NORMAL", "CRYSTAL_ROTATE_LARGE"}
new g_szRotateShape[][] = {"CRYSTAL_ROTATE_SHAPE_1", "CRYSTAL_ROTATE_SHAPE_2", "CRYSTAL_ROTATE_SHAPE_3"}
new g_szCrystalColors[][] = {"CRYSTAL_COLOR_WHITE", "CRYSTAL_COLOR_RED", "CRYSTAL_COLOR_GREEN", "CRYSTAL_COLOR_BLUE", "CRYSTAL_COLOR_CYAN", "CRYSTAL_COLOR_YELLOW", "CRYSTAL_COLOR_MAGENTA", "CRYSTAL_COLOR_ORANGE", "CRYSTAL_COLOR_PURPLE", "CRYSTAL_COLOR_PINK", "CRYSTAL_COLOR_AQUA", "CRYSTAL_COLOR_WARM"}
new const g_iCrystalFactor[] = {1, 2, 3, 5, 10}
new const g_iCrystalColors[][3] =
{
    { 255, 255, 255 }, // White
    { 255,   0,   0 }, // Red
    {   0, 255,   0 }, // Green
    {   0,   0, 255 }, // Blue
    {   0, 255, 255 }, // Cyan
    { 255, 255,   0 }, // Yellow
    { 255,   0, 255 }, // Magenta
    { 255, 128,   0 }, // Orange
    { 128,   0, 255 }, // Purple
    { 255, 128, 192 }, // Pink
    { 128, 255, 255 }, // Aqua
    { 255, 192, 128 }  // Warm
}

public plugin_init()
{
    register_plugin("Xen Crystal", PLUGIN_VERSION, "RedSMURF")
    register_cvar("RedSMURF_XenCrystal", PLUGIN_VERSION, ADMIN_ACCESS)

    register_clcmd("say /xc",               "cmdMenu", ADMIN_ACCESS, "-- Opens the Xen Crystal menu.")
    register_clcmd("say_team /xc",          "cmdMenu", ADMIN_ACCESS, "-- Opens the Xen Crystal menu.")
    register_clcmd("say /xencrystal",       "cmdMenu", ADMIN_ACCESS, "-- Opens the Xen Crystal menu.")
    register_clcmd("say_team /xencrystal",  "cmdMenu", ADMIN_ACCESS, "-- Opens the Xen Crystal menu.")
    register_concmd("xc_reload",          "cmdReload", ADMIN_ACCESS, "-- Reloads the configuration file")
    register_concmd("xencrystal_reload",  "cmdReload", ADMIN_ACCESS, "-- Reloads the configuration file")
    register_dictionary("XenCrystal.txt")

    g_iFwdPreThink = RegisterHam(Ham_Player_PreThink, "player", "fwdPreThink")
    g_iFwdKilled = RegisterHam(Ham_Killed, "player", "fwdKilled", 1)
    register_logevent("eventRoundStart", 2, "1=Round_Start")
    DisableForward()

    crystalInit()
    g_iMaxPlayers = get_maxplayers()
}

public plugin_precache()
{
    g_aCrystal = ArrayCreate(CRYSTAL)
    g_aCrystalConfig = ArrayCreate(CRYSTAL)

    ReadFile()
}

public plugin_end()
{
    ArrayDestroy(g_aCrystal)
    ArrayDestroy(g_aCrystalConfig)
}

public cmdMenu(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    crystalSound(id, SOUND_MENU_NAV)
    crystalMenu(id, MENU_ROOT)

    return PLUGIN_HANDLED
}

public cmdReload(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    ReadFile()
    console_print(id, "The configuration file has been reloaded successfully !")

    return PLUGIN_HANDLED
}

public eventRoundStart()
{
    crystalReset()
}

ReadFile()
{
    if ( g_bFileWasRead )
    {
        for ( new id = 1; id <= g_iMaxPlayers; id ++ )
            if ( is_user_connected(id))
                UpdateData(id)

        ArrayClear(g_aCrystalConfig)
        g_iCrystalConfig = 0
    }

    new szFile[MAX_RESOURCE_PATH_LENGTH], iFile
    get_configsdir(szFile, charsmax(szFile))
    add(szFile, charsmax(szFile), "/XenCrystal.ini")
    iFile = fopen(szFile, "rt")

    if ( !iFile )
    {
        set_fail_state("An error occured during the opening of the configuration file !")
    }

    new szData[MAX_FILE_CELL_SIZE],
        szKey[MAX_VALUE_LENGTH], szValue[MAX_VALUE_LENGTH],
        eCrystal[CRYSTAL], iSection = SECTION_NONE, iLine, iPos

    while( !feof(iFile) )
    {
        iLine ++
        fgets(iFile, szData, charsmax(szData))
        trim(szData)

        switch( szData[0] )
        {
            case EOS, ';', '#':
            {
                continue
            }
            case '[':
            {
                if ( szData[strlen(szData) - 1] == ']' )
                {
                    replace(szData, charsmax(szData), "[", "")
                    replace(szData, charsmax(szData), "]", "")
                    trim(szData)

                    if ( equali(szData, "Main Settings") )
                    {
                        iSection = SECTION_MAIN_SETTINGS
                    }
                    else
                    {
                        if ( g_iCrystalConfig )
                            ArrayPushArray(g_aCrystalConfig, eCrystal)

                        copy(eCrystal[CRYSTAL_NAME], charsmax(eCrystal[CRYSTAL_NAME]), szData)
                        eCrystal[CRYSTAL_FLAGS]                 = g_eSettings[SETTING_DEFAULT_FLAGS]
                        eCrystal[CRYSTAL_TEAM]                  = g_eSettings[SETTING_DEFAULT_TEAM]
                        eCrystal[CRYSTAL_FRAMERATE]             = g_eSettings[SETTING_DEFAULT_FRAMERATE]
                        eCrystal[CRYSTAL_TRIGGER_DISTANCE]      = g_eSettings[SETTING_DEFAULT_TRIGGER_DISTANCE]
                        eCrystal[CRYSTAL_TRIGGER_DURATION][0]   = g_eSettings[SETTING_DEFAULT_TRIGGER_DURATION][0]
                        eCrystal[CRYSTAL_TRIGGER_DURATION][1]   = g_eSettings[SETTING_DEFAULT_TRIGGER_DURATION][1]
                        eCrystal[CRYSTAL_COLOR_FREQUENCY][0]    = g_eSettings[SETTING_DEFAULT_COLOR_FREQUENCY][0]
                        eCrystal[CRYSTAL_COLOR_FREQUENCY][1]    = g_eSettings[SETTING_DEFAULT_COLOR_FREQUENCY][1]

                        iSection = SECTION_CRYSTAL
                        g_iCrystalConfig ++
                    }
                }
                else
                {
                    LogConfigError(iLine, "Unclosed section name: %s", szData)
                    iSection = SECTION_NONE
                }
            }
            default:
            {
                strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
                iPos = contain(szValue, "#")
                if ( iPos != -1 )
                    szValue[iPos] = EOS

                trim(szKey)
                trim(szValue)

                switch( iSection )
                {
                    case SECTION_NONE:
                    {
                        LogConfigError(iLine, "Data is not in any defined section: %s", szData)
                    }
                    case SECTION_MAIN_SETTINGS:
                    {
                        if ( equali(szKey, "SETTING_DEFAULT_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FLAGS], charsmax(g_eSettings[SETTING_DEFAULT_FLAGS]))
                        else if ( equali(szKey, "SETTING_DEFAULT_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_TEAM], charsmax(g_eSettings[SETTING_DEFAULT_TEAM]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FRAMERATE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FRAMERATE], charsmax(g_eSettings[SETTING_DEFAULT_FRAMERATE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_TRIGGER_DISTANCE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_TRIGGER_DISTANCE], charsmax(g_eSettings[SETTING_DEFAULT_TRIGGER_DISTANCE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_TRIGGER_DURATION") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_TRIGGER_DURATION], charsmax(g_eSettings[SETTING_DEFAULT_TRIGGER_DURATION]))
                        else if ( equali(szKey, "SETTING_DEFAULT_COLOR_FREQUENCY") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_COLOR_FREQUENCY], charsmax(g_eSettings[SETTING_DEFAULT_COLOR_FREQUENCY]))
                        else if ( equali(szKey, "SETTING_MODEL_CRYSTAL_NORMAL") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_CRYSTAL_NORMAL], charsmax(g_eSettings[SETTING_MODEL_CRYSTAL_NORMAL]))
                        else if ( equali(szKey, "SETTING_MODEL_CRYSTAL_LARGE") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_CRYSTAL_LARGE], charsmax(g_eSettings[SETTING_MODEL_CRYSTAL_LARGE]))
                        else if ( equali(szKey, "SETTING_MINS_NORMAL") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS_NORMAL], charsmax(g_eSettings[SETTING_MINS_NORMAL]))
                        else if ( equali(szKey, "SETTING_MAXS_NORMAL") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS_NORMAL], charsmax(g_eSettings[SETTING_MAXS_NORMAL]))
                        else if ( equali(szKey, "SETTING_MINS_LARGE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS_LARGE], charsmax(g_eSettings[SETTING_MINS_LARGE]))
                        else if ( equali(szKey, "SETTING_MAXS_LARGE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS_LARGE], charsmax(g_eSettings[SETTING_MAXS_LARGE]))
                        else if ( equali(szKey, "SETTING_CRYSTAL_LOAD") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_CRYSTAL_LOAD], charsmax(g_eSettings[SETTING_CRYSTAL_LOAD]))
                        else if ( equali(szKey, "SETTING_CRYSTAL_CHECK") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_CRYSTAL_CHECK], charsmax(g_eSettings[SETTING_CRYSTAL_CHECK]))
                        else if ( equali(szKey, "SETTING_CRYSTAL_TASK") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_CRYSTAL_TASK], charsmax(g_eSettings[SETTING_CRYSTAL_TASK]))
                        else if ( equali(szKey, "SETTING_OFFSET_BASE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET_BASE], charsmax(g_eSettings[SETTING_OFFSET_BASE]))
                        else if ( equali(szKey, "SETTING_OFFSET") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET], charsmax(g_eSettings[SETTING_OFFSET]))
                        else if ( equali(szKey, "SETTING_OFFSET_STEP") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET_STEP], charsmax(g_eSettings[SETTING_OFFSET_STEP]))
                        else if ( equali(szKey, "SETTING_GHOST_ALPHA") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_GHOST_ALPHA], charsmax(g_eSettings[SETTING_GHOST_ALPHA]))
                        else if ( equali(szKey, "SETTING_ROTATION_STEP") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_ROTATION_STEP], charsmax(g_eSettings[SETTING_ROTATION_STEP]))
                        else if ( equali(szKey, "SETTING_CRYSTAL_LIFE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_CRYSTAL_LIFE], charsmax(g_eSettings[SETTING_CRYSTAL_LIFE]))
                    }
                    case SECTION_CRYSTAL:
                    {
                        if ( equali(szKey, "CRYSTAL_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), eCrystal[CRYSTAL_FLAGS], charsmax(eCrystal[CRYSTAL_FLAGS]))
                        else if ( equali(szKey, "CRYSTAL_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eCrystal[CRYSTAL_TEAM], charsmax(eCrystal[CRYSTAL_TEAM]))
                        else if ( equali(szKey, "CRYSTAL_FRAMERATE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eCrystal[CRYSTAL_FRAMERATE], charsmax(eCrystal[CRYSTAL_FRAMERATE]))
                        else if ( equali(szKey, "CRYSTAL_TRIGGER_DISTANCE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eCrystal[CRYSTAL_TRIGGER_DISTANCE], charsmax(eCrystal[CRYSTAL_TRIGGER_DISTANCE]))
                        else if ( equali(szKey, "CRYSTAL_TRIGGER_DURATION") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eCrystal[CRYSTAL_TRIGGER_DURATION], charsmax(eCrystal[CRYSTAL_TRIGGER_DURATION]))
                        else if ( equali(szKey, "CRYSTAL_COLOR_FREQUENCY") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eCrystal[CRYSTAL_COLOR_FREQUENCY], charsmax(eCrystal[CRYSTAL_COLOR_FREQUENCY]))
                    }
                }
            }
        }
    }

    if ( g_iCrystalConfig )
        ArrayPushArray(g_aCrystalConfig, eCrystal)
    else
        set_fail_state("No Crystals were found in the configuration file.")

    g_bFileWasRead = true
    fclose(iFile)
}

public client_authorized(id)
{
    set_task(DELAY_ON_CONNECT, "UpdateData", id)
}

public client_disconnected(id)
{
    new eCrystal[CRYSTAL], iItem
    if ( g_ePlayerData[id][PDATA_CRYSTAL_GHOST]
    && (iItem = crystalGet(eCrystal, g_ePlayerData[id][PDATA_CRYSTAL_GHOST])) != -1 )
    {
        crystalKill(eCrystal[CRYSTAL_ID])
        crystalRemove(iItem)
    }

    DisableAction(id)
    g_ePlayerData[id][PDATA_CRYSTAL_GHOST]  = 0
    g_ePlayerData[id][PDATA_CRYSTAL_MENU]   = 0
}

public UpdateData(id)
{
    g_ePlayerData[id][PDATA_OFFSET] = g_eSettings[SETTING_OFFSET_BASE]
}

stock crystalInit()
{
    if ( g_eSettings[SETTING_CRYSTAL_LOAD] )
        set_task(DELAY_ON_LOAD, "loadData")
}

stock crystalTerminate()
{
    new eCrystal[CRYSTAL]
    for ( new i = 0; i < g_iCrystal; i ++ )
    {
        ArrayGetArray(g_aCrystal, i, eCrystal)
        if ( !(eCrystal[CRYSTAL_FLAGS] & FLAG_PENDING)
        || eCrystal[CRYSTAL_FLAGS] & FLAG_REVERSE )
            continue

        eCrystal[CRYSTAL_FLAGS] |= FLAG_ACTIVE
        eCrystal[CRYSTAL_FLAGS] &= ~FLAG_PENDING
        ArraySetArray(g_aCrystal, i, eCrystal)
    }
}

stock crystalMenu(id, iType)
{
    if ( !is_user_connected(id) )
        return PLUGIN_HANDLED

    new szData[256], iMenu
    formatex(szData, charsmax(szData), "%L", id, "CRYSTAL_MENU_TITLE", PLUGIN_VERSION)
    iMenu = menu_create(szData, g_szMenuHandler[iType])

    switch( iType )
    {
        case MENU_ROOT:   { menuRoot(id, iMenu); }
        case MENU_CREATE: { menuCreate(iMenu);      format(szData, charsmax(szData), "%s^n%L", szData, id, "CRYSTAL_ROOT_CREATE"); }
        case MENU_EDIT:   { menuEdit(id, iMenu);    format(szData, charsmax(szData), "%s^n%L", szData, id, "CRYSTAL_ROOT_EDIT"); }
        case MENU_REMOVE: { menuRemove(id, iMenu);  format(szData, charsmax(szData), "%s^n%L", szData, id, "CRYSTAL_ROOT_REMOVE"); }
        case MENU_SHOW:   { menuShow(id, iMenu);    format(szData, charsmax(szData), "%s^n%L", szData, id, "CRYSTAL_ROOT_SHOW"); }
        case MENU_STATUS: { menuStatus(id, iMenu);  format(szData, charsmax(szData), "%s^n%L", szData, id, "CRYSTAL_ROOT_STATUS"); }
        case MENU_ROTATE: { menuRotate(id, iMenu);  format(szData, charsmax(szData), "%s^n%L", szData, id, "CRYSTAL_ROOT_ROTATE"); }
        case MENU_LIGHT:  { menuLight(id, iMenu);   format(szData, charsmax(szData), "%s^n%L", szData, id, "CRYSTAL_ROOT_LIGHT"); }
    }

    if ( menu_pages(iMenu) > 1 )
        format(szData, charsmax(szData), "%s^n%L", szData, id, "CRYSTAL_MENU_TITLE_PAGE")

    menu_setprop(iMenu, MPROP_TITLE, szData)
    menu_setprop(iMenu, MPROP_EXIT, MEXIT_ALL)
    menu_setprop(iMenu, MPROP_NUMBER_COLOR, "\r")

    menu_display(id, iMenu)
    return PLUGIN_HANDLED
}

stock menuNav(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_NAV_NEXT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_NAV_BACK")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)
}

public menuRoot(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_ROOT_CREATE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_ROOT_EDIT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_ROOT_REMOVE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_ROOT_SAVE")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_ROOT_NOCLIP", id, get_user_noclip(id) ? "CRYSTAL_ON" : "CRYSTAL_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_ROOT_GODMODE", id, get_user_godmode(id) ? "CRYSTAL_ON" : "CRYSTAL_OFF")
    menu_additem(iMenu, szItem)
}

public menuHandlerRoot(id, menu, item)
{
    if ( item == MENU_EXIT )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROOT_CREATE:
        {
            if ( g_iCrystal >= MAX_ENT )
            {
                client_print_color(id, id, "%L %L", id, "CRYSTAL_CHAT_TAG", id, "CRYSTAL_CHAT_LIMIT", MAX_ENT)

                crystalSound(id, SOUND_MENU_REMOVE)
                crystalMenu(id, MENU_ROOT)
            }
            else
            {
                crystalSound(id, SOUND_MENU_NAV)
                crystalMenu(id, MENU_CREATE)
            }
        }
        case ROOT_EDIT:
        {
            if ( !g_iCrystal )
            {
                client_print_color(id, id, "%L %L", id, "CRYSTAL_CHAT_TAG", id, "CRYSTAL_CHAT_NO_CRYSTAL")

                crystalSound(id, SOUND_MENU_REMOVE)
                crystalMenu(id, MENU_ROOT)
            }
            else
            {
                crystalSound(id, SOUND_MENU_NAV)
                crystalMenu(id, MENU_EDIT)
            }
        }
        case ROOT_REMOVE:
        {
            if ( !g_iCrystal )
            {
                client_print_color(id, id, "%L %L", id, "CRYSTAL_CHAT_TAG", id, "CRYSTAL_CHAT_NO_CRYSTAL")

                crystalSound(id, SOUND_MENU_REMOVE)
                crystalMenu(id, MENU_ROOT)
            }
            else
            {
                crystalSound(id, SOUND_MENU_REMOVE)
                crystalMenu(id, MENU_REMOVE)
            }
        }
        case ROOT_SAVE:
        {
            saveData(id)
        }
        case ROOT_NOCLIP:
        {
            crystalNoClip(id)
        }
        case ROOT_GODMODE:
        {
            crystalGodMode(id)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuCreate(iMenu)
{
    new eCrystal[CRYSTAL], szItem[64]
    for ( new i = 0; i < g_iCrystalConfig; i ++ )
    {
        ArrayGetArray(g_aCrystalConfig, i, eCrystal)

        copy(szItem, charsmax(szItem), eCrystal[CRYSTAL_NAME])
        menu_additem(iMenu, szItem)
    }
}

public menuHandlerCreate(id, menu, item)
{
    if ( !is_user_alive(id) )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    else if ( item == MENU_EXIT )
    {
        crystalSound(id, SOUND_MENU_NAV)
        crystalMenu(id, MENU_ROOT)

        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    crystalCreate(id, item)
    crystalSound(id, SOUND_MENU_NAV)
    crystalMenu(id, MENU_ROTATE)

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuEdit(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_EDIT_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_EDIT_STATUS")
    menu_additem(iMenu, szItem)
}

public menuHandlerEdit(id, menu, item)
{
    switch( item )
    {
        case EDIT_SHOW:
        {
            crystalSound(id, SOUND_MENU_NAV)
            crystalMenu(id, MENU_SHOW)
        }
        case EDIT_STATUS:
        {
            crystalSound(id, SOUND_MENU_NAV)
            crystalMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            crystalSound(id, SOUND_MENU_NAV)
            crystalMenu(id, MENU_ROOT)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRemove(id, iMenu)
{
    new szItem[64], eCrystal[CRYSTAL]
    menuNav(id, iMenu)
    ArrayGetArray(g_aCrystal, g_ePlayerData[id][PDATA_CRYSTAL_MENU], eCrystal)

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_REMOVE_CURRENT", eCrystal[CRYSTAL_NAME])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_REMOVE_ALL")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    crystalSelect(eCrystal, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_REMOVE
    ArraySetArray(g_aCrystal, g_ePlayerData[id][PDATA_CRYSTAL_MENU], eCrystal)
}

public menuHandlerRemove(id, menu, item)
{
    new eCrystal[CRYSTAL]
    ArrayGetArray(g_aCrystal, g_ePlayerData[id][PDATA_CRYSTAL_MENU], eCrystal)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        crystalSelect(eCrystal, eCrystal[CRYSTAL_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case REMOVE_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_CRYSTAL_MENU] >= g_iCrystal - 1 )
                g_ePlayerData[id][PDATA_CRYSTAL_MENU] = 0
            else
                g_ePlayerData[id][PDATA_CRYSTAL_MENU] ++

            crystalSound(id, SOUND_MENU_NAV)
            crystalMenu(id, MENU_REMOVE)
        }
        case REMOVE_BACK:
        {
            if ( g_ePlayerData[id][PDATA_CRYSTAL_MENU] <= 0 )
                g_ePlayerData[id][PDATA_CRYSTAL_MENU] = g_iCrystal - 1
            else
                g_ePlayerData[id][PDATA_CRYSTAL_MENU] --

            crystalSound(id, SOUND_MENU_NAV)
            crystalMenu(id, MENU_REMOVE)
        }
        case REMOVE_CURRENT:
        {
            crystalSetState(eCrystal)
            crystalKill(eCrystal[CRYSTAL_ID])
            crystalRemove(g_ePlayerData[id][PDATA_CRYSTAL_MENU])

            client_print_color(id, id, "%L %L", id, "CRYSTAL_CHAT_TAG", id, "CRYSTAL_CHAT_REMOVE_CURRENT", eCrystal[CRYSTAL_NAME])
            g_ePlayerData[id][PDATA_CRYSTAL_MENU] = 0

            crystalSound(id, g_iCrystal > 0 ? SOUND_MENU_REMOVE : SOUND_MENU_NAV)
            crystalMenu(id, g_iCrystal > 0 ? MENU_REMOVE : MENU_ROOT)
        }
        case REMOVE_ALL:
        {
            while( g_iCrystal )
            {
                ArrayGetArray(g_aCrystal, 0, eCrystal)

                crystalSetState(eCrystal)
                crystalKill(eCrystal[CRYSTAL_ID])
                crystalRemove(0)
            }

            client_print_color(id, id, "%L %L", id, "CRYSTAL_CHAT_TAG", id, "CRYSTAL_CHAT_REMOVE_ALL")
            g_ePlayerData[id][PDATA_CRYSTAL_MENU] = 0

            crystalSound(id, SOUND_MENU_ALERT)
            crystalMenu(id, MENU_ROOT)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                crystalSound(id, SOUND_MENU_NAV)
                crystalMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_CRYSTAL_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_CRYSTAL_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuShow(id, iMenu)
{
    new szItem[64], eCrystal[CRYSTAL]
    menuNav(id, iMenu)
    ArrayGetArray(g_aCrystal, g_ePlayerData[id][PDATA_CRYSTAL_MENU], eCrystal)

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_SHOW_CURRENT",
    eCrystal[CRYSTAL_FLAGS] & FLAG_SHOW ? "\y" : "\r", eCrystal[CRYSTAL_NAME], id, eCrystal[CRYSTAL_FLAGS] & FLAG_SHOW ? "CRYSTAL_SHOWN" : "CRYSTAL_HIDDEN")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_SHOW_ALL_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_SHOW_ALL_HIDE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    crystalSelect(eCrystal, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_SHOW
    ArraySetArray(g_aCrystal, g_ePlayerData[id][PDATA_CRYSTAL_MENU], eCrystal)
}

public menuHandlerShow(id, menu, item)
{
    new eCrystal[CRYSTAL]
    ArrayGetArray(g_aCrystal, g_ePlayerData[id][PDATA_CRYSTAL_MENU], eCrystal)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        crystalSelect(eCrystal, eCrystal[CRYSTAL_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case SHOW_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_CRYSTAL_MENU] >= g_iCrystal - 1 )
                g_ePlayerData[id][PDATA_CRYSTAL_MENU] = 0
            else
                g_ePlayerData[id][PDATA_CRYSTAL_MENU] ++

            crystalSound(id, SOUND_MENU_NAV)
            crystalMenu(id, MENU_SHOW)
        }
        case SHOW_BACK:
        {
            if ( g_ePlayerData[id][PDATA_CRYSTAL_MENU] <= 0 )
                g_ePlayerData[id][PDATA_CRYSTAL_MENU] = g_iCrystal - 1
            else
                g_ePlayerData[id][PDATA_CRYSTAL_MENU] --

            crystalSound(id, SOUND_MENU_NAV)
            crystalMenu(id, MENU_SHOW)
        }
        case SHOW_CURRENT:
        {
            eCrystal[CRYSTAL_FLAGS] ^= FLAG_SHOW
            crystalSetState(eCrystal)

            client_print_color(id, id, "%L %L", id, "CRYSTAL_CHAT_TAG", id, "CRYSTAL_CHAT_SHOW_CURRENT",
            eCrystal[CRYSTAL_NAME], id, eCrystal[CRYSTAL_FLAGS] & FLAG_SHOW ? "CRYSTAL_CHAT_SHOWN" : "CRYSTAL_CHAT_HIDDEN")
            ArraySetArray(g_aCrystal, g_ePlayerData[id][PDATA_CRYSTAL_MENU], eCrystal)

            crystalSound(id, SOUND_MENU_NAV)
            crystalMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_SHOW:
        {
            for ( new i = 0; i < g_iCrystal; i ++ )
            {
                ArrayGetArray(g_aCrystal, i, eCrystal)
                eCrystal[CRYSTAL_FLAGS] |= FLAG_SHOW
                crystalSetState(eCrystal)

                ArraySetArray(g_aCrystal, i, eCrystal)
            }

            client_print_color(id, id, "%L %L", id, "CRYSTAL_CHAT_TAG", id, "CRYSTAL_CHAT_SHOW_ALL_SHOWN")
            crystalSound(id, SOUND_MENU_ALERT)
            crystalMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_HIDE:
        {
            for ( new i = 0; i < g_iCrystal; i ++ )
            {
                ArrayGetArray(g_aCrystal, i, eCrystal)
                eCrystal[CRYSTAL_FLAGS] &= ~FLAG_SHOW
                crystalSetState(eCrystal)

                ArraySetArray(g_aCrystal, i, eCrystal)
            }

            client_print_color(id, id, "%L %L", id, "CRYSTAL_CHAT_TAG", id, "CRYSTAL_CHAT_SHOW_ALL_HIDDEN")
            crystalSound(id, SOUND_MENU_ALERT)
            crystalMenu(id, MENU_SHOW)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                crystalSound(id, SOUND_MENU_NAV)
                crystalMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_CRYSTAL_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_CRYSTAL_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuStatus(id, iMenu)
{
    new szItem[64], eCrystal[CRYSTAL]
    menuNav(id, iMenu)
    ArrayGetArray(g_aCrystal, g_ePlayerData[id][PDATA_CRYSTAL_MENU], eCrystal)

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_STATUS_CURRENT",
    eCrystal[CRYSTAL_FLAGS] & FLAG_ACTIVE ? "\y" : "\r", eCrystal[CRYSTAL_NAME], id, eCrystal[CRYSTAL_FLAGS] & FLAG_ACTIVE ? "CRYSTAL_ENABLED" : "CRYSTAL_DISABLED")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_STATUS_ALL_ENABLE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_STATUS_ALL_DISABLE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    crystalSelect(eCrystal, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_STATUS
    ArraySetArray(g_aCrystal, g_ePlayerData[id][PDATA_CRYSTAL_MENU], eCrystal)
}

public menuHandlerStatus(id, menu, item)
{
    new eCrystal[CRYSTAL]
    ArrayGetArray(g_aCrystal, g_ePlayerData[id][PDATA_CRYSTAL_MENU], eCrystal)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        crystalSelect(eCrystal, eCrystal[CRYSTAL_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case STATUS_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_CRYSTAL_MENU] >= g_iCrystal - 1 )
                g_ePlayerData[id][PDATA_CRYSTAL_MENU] = 0
            else
                g_ePlayerData[id][PDATA_CRYSTAL_MENU] ++

            crystalSound(id, SOUND_MENU_NAV)
            crystalMenu(id, MENU_STATUS)
        }
        case STATUS_BACK:
        {
            if ( g_ePlayerData[id][PDATA_CRYSTAL_MENU] <= 0 )
                g_ePlayerData[id][PDATA_CRYSTAL_MENU] = g_iCrystal - 1
            else
                g_ePlayerData[id][PDATA_CRYSTAL_MENU] --

            crystalSound(id, SOUND_MENU_NAV)
            crystalMenu(id, MENU_STATUS)
        }
        case STATUS_CURRENT:
        {
            eCrystal[CRYSTAL_FLAGS] ^= FLAG_ACTIVE
            crystalSetState(eCrystal)

            client_print_color(id, id, "%L %L", id, "CRYSTAL_CHAT_TAG", id, "CRYSTAL_CHAT_STATUS_CURRENT",
            eCrystal[CRYSTAL_NAME], id, eCrystal[CRYSTAL_FLAGS] & FLAG_ACTIVE ? "CRYSTAL_CHAT_ENABLED" : "CRYSTAL_CHAT_DISABLED")
            ArraySetArray(g_aCrystal, g_ePlayerData[id][PDATA_CRYSTAL_MENU], eCrystal)

            crystalSound(id, SOUND_MENU_NAV)
            crystalMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_ENABLE:
        {
            for ( new i = 0; i < g_iCrystal; i ++ )
            {
                ArrayGetArray(g_aCrystal, i, eCrystal)
                eCrystal[CRYSTAL_FLAGS] |= FLAG_ACTIVE
                crystalSetState(eCrystal)

                ArraySetArray(g_aCrystal, i, eCrystal)
            }

            client_print_color(id, id, "%L %L", id, "CRYSTAL_CHAT_TAG", id, "CRYSTAL_CHAT_STATUS_ALL_ENABLED")
            crystalSound(id, SOUND_MENU_ALERT)
            crystalMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_DISABLE:
        {
            for ( new i = 0; i < g_iCrystal; i ++ )
            {
                ArrayGetArray(g_aCrystal, i, eCrystal)
                eCrystal[CRYSTAL_FLAGS] &= ~FLAG_ACTIVE
                crystalSetState(eCrystal)

                ArraySetArray(g_aCrystal, i, eCrystal)
            }

            client_print_color(id, id, "%L %L", id, "CRYSTAL_CHAT_TAG", id, "CRYSTAL_CHAT_STATUS_ALL_DISABLED")
            crystalSound(id, SOUND_MENU_ALERT)
            crystalMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                crystalSound(id, SOUND_MENU_NAV)
                crystalMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_CRYSTAL_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_CRYSTAL_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRotate(id, iMenu)
{
    new szItem[64], eCrystal[CRYSTAL]
    if ( crystalGet(eCrystal, g_ePlayerData[id][PDATA_CRYSTAL_GHOST]) == -1 )
    {
        menu_destroy(iMenu)
        return
    }

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_ROTATE_UP")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_ROTATE_DOWN")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_ROTATE_GROUND",
    id, eCrystal[CRYSTAL_FLAGS] & FLAG_GROUND ? "CRYSTAL_ON" : "CRYSTAL_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_ROTATE_MODE", id, g_szRotateMode[g_ePlayerData[id][PDATA_ROTATE_MODE]])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_ROTATE_SIZE", id, g_szRotateSize[g_ePlayerData[id][PDATA_ROTATE_SIZE]])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_ROTATE_SHAPE", id, g_szRotateShape[g_ePlayerData[id][PDATA_ROTATE_SHAPE]])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_ROTATE_PLACE")
    menu_additem(iMenu, szItem)
}

public menuHandlerRotate(id, menu, item)
{
    new eCrystal[CRYSTAL], iItem
    if ( (iItem = crystalGet(eCrystal, g_ePlayerData[id][PDATA_CRYSTAL_GHOST])) == -1 )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROTATE_UP:
        {
            pev(eCrystal[CRYSTAL_ID], pev_angles, eCrystal[CRYSTAL_ANGLES])
            eCrystal[CRYSTAL_ANGLES][g_ePlayerData[id][PDATA_ROTATE_MODE]] -= g_eSettings[SETTING_ROTATION_STEP]
            if ( eCrystal[CRYSTAL_ANGLES][g_ePlayerData[id][PDATA_ROTATE_MODE]] < -180.0 ) eCrystal[CRYSTAL_ANGLES][g_ePlayerData[id][PDATA_ROTATE_MODE]] += 360.0

            set_pev(eCrystal[CRYSTAL_ID], pev_angles, eCrystal[CRYSTAL_ANGLES])
            ArraySetArray(g_aCrystal, iItem, eCrystal)

            crystalSound(id, SOUND_MENU_NAV)
            crystalMenu(id, MENU_ROTATE)
        }
        case ROTATE_DOWN:
        {
            pev(eCrystal[CRYSTAL_ID], pev_angles, eCrystal[CRYSTAL_ANGLES])
            eCrystal[CRYSTAL_ANGLES][g_ePlayerData[id][PDATA_ROTATE_MODE]] += g_eSettings[SETTING_ROTATION_STEP]
            if ( eCrystal[CRYSTAL_ANGLES][g_ePlayerData[id][PDATA_ROTATE_MODE]] > 180.0 ) eCrystal[CRYSTAL_ANGLES][g_ePlayerData[id][PDATA_ROTATE_MODE]] -= 360.0

            set_pev(eCrystal[CRYSTAL_ID], pev_angles, eCrystal[CRYSTAL_ANGLES])
            ArraySetArray(g_aCrystal, iItem, eCrystal)

            crystalSound(id, SOUND_MENU_NAV)
            crystalMenu(id, MENU_ROTATE)
        }
        case ROTATE_GROUND:
        {
            eCrystal[CRYSTAL_FLAGS] ^= FLAG_GROUND
            ArraySetArray(g_aCrystal, iItem, eCrystal)

            crystalSound(id, SOUND_MENU_NAV)
            crystalMenu(id, MENU_ROTATE)
        }
        case ROTATE_MODE:
        {
            if ( ++ g_ePlayerData[id][PDATA_ROTATE_MODE] > ROTATE_MODE_ROLL )
                g_ePlayerData[id][PDATA_ROTATE_MODE] = ROTATE_MODE_PITCH

            crystalSound(id, SOUND_MENU_NAV)
            crystalMenu(id, MENU_ROTATE)
        }
        case ROTATE_SIZE:
        {
            if ( ++ g_ePlayerData[id][PDATA_ROTATE_SIZE] > SIZE_LARGE )
                g_ePlayerData[id][PDATA_ROTATE_SIZE] = SIZE_NORMAL

            eCrystal[CRYSTAL_SIZE] = g_ePlayerData[id][PDATA_ROTATE_SIZE]
            switch( eCrystal[CRYSTAL_SIZE] )
            {
                case SIZE_NORMAL: engfunc(EngFunc_SetModel, eCrystal[CRYSTAL_ID], g_eSettings[SETTING_MODEL_CRYSTAL_NORMAL])
                case SIZE_LARGE:  engfunc(EngFunc_SetModel, eCrystal[CRYSTAL_ID], g_eSettings[SETTING_MODEL_CRYSTAL_LARGE])
            }

            ArraySetArray(g_aCrystal, iItem, eCrystal)
            crystalSound(id, SOUND_MENU_NAV)
            crystalMenu(id, MENU_ROTATE)
        }
        case ROTATE_SHAPE:
        {
            if ( ++ g_ePlayerData[id][PDATA_ROTATE_SHAPE] > SHAPE_3 )
                g_ePlayerData[id][PDATA_ROTATE_SHAPE] = SHAPE_1

            eCrystal[CRYSTAL_SHAPE] = g_ePlayerData[id][PDATA_ROTATE_SHAPE]
            set_pev(eCrystal[CRYSTAL_ID], pev_body, eCrystal[CRYSTAL_SHAPE])
            ArraySetArray(g_aCrystal, iItem, eCrystal)

            crystalSound(id, SOUND_MENU_NAV)
            crystalMenu(id, MENU_ROTATE)
        }
        case ROTATE_PLACE:
        {
            crystalTrace(eCrystal, id)

            eCrystal[CRYSTAL_FLAGS] |= (FLAG_SHOW | FLAG_LOCK)
            eCrystal[CRYSTAL_FLAGS] &= ~FLAG_GHOST
            eCrystal[CRYSTAL_ANGLES][0] = -eCrystal[CRYSTAL_ANGLES][0]
            if ( !(eCrystal[CRYSTAL_FLAGS] & FLAG_REVERSE) )
                eCrystal[CRYSTAL_FLAGS] |= FLAG_ACTIVE
            else
                eCrystal[CRYSTAL_FLAGS] |= FLAG_PENDING
            crystalSetSize(eCrystal)
            ArraySetArray(g_aCrystal, iItem, eCrystal)

            crystalSound(id, SOUND_MENU_NAV)
            crystalMenu(id, MENU_LIGHT)
        }
        case MENU_EXIT:
        {
            crystalKill(eCrystal[CRYSTAL_ID])
            crystalRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_CRYSTAL_GHOST] = 0

            crystalSound(id, SOUND_MENU_NAV)
            crystalMenu(id, MENU_CREATE)
        }
        default:
        {
            crystalKill(eCrystal[CRYSTAL_ID])
            crystalRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_CRYSTAL_GHOST] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuLight(id, iMenu)
{
    new szItem[64], eCrystal[CRYSTAL]
    if ( crystalGet(eCrystal, g_ePlayerData[id][PDATA_CRYSTAL_GHOST]) == -1 )
    {
        menu_destroy(iMenu)
        return
    }

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_LIGHT_SCALE_UP")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_LIGHT_SCALE_DOWN")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_LIGHT_FACTOR", g_iCrystalFactor[g_ePlayerData[id][PDATA_LIGHT_FACTOR]])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_LIGHT_COLOR", id, g_szCrystalColors[g_ePlayerData[id][PDATA_LIGHT_COLOR]])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CRYSTAL_LIGHT_PLACE")
    menu_additem(iMenu, szItem)
}

public menuHandlerLight(id, menu, item)
{
    new eCrystal[CRYSTAL], iItem

    if ( (iItem = crystalGet(eCrystal, g_ePlayerData[id][PDATA_CRYSTAL_GHOST])) == -1 )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch ( item )
    {
        case LIGHT_SCALE_UP:
        {
            eCrystal[CRYSTAL_DLIGHT_SCALE] = clamp(eCrystal[CRYSTAL_DLIGHT_SCALE] + g_iCrystalFactor[g_ePlayerData[id][PDATA_LIGHT_FACTOR]], CRYSTAL_DLIGHT_SCALE_MIN, CRYSTAL_DLIGHT_SCALE_MAX)
            ArraySetArray(g_aCrystal, iItem, eCrystal)

            crystalSound(id, SOUND_MENU_NAV)
            crystalMenu(id, MENU_LIGHT)
        }
        case LIGHT_SCALE_DOWN:
        {
            eCrystal[CRYSTAL_DLIGHT_SCALE] = clamp(eCrystal[CRYSTAL_DLIGHT_SCALE] - g_iCrystalFactor[g_ePlayerData[id][PDATA_LIGHT_FACTOR]], CRYSTAL_DLIGHT_SCALE_MIN, CRYSTAL_DLIGHT_SCALE_MAX)
            ArraySetArray(g_aCrystal, iItem, eCrystal)

            crystalSound(id, SOUND_MENU_NAV)
            crystalMenu(id, MENU_LIGHT)
        }
        case LIGHT_FACTOR:
        {
            if ( ++ g_ePlayerData[id][PDATA_LIGHT_FACTOR] >= sizeof(g_iCrystalFactor) )
                g_ePlayerData[id][PDATA_LIGHT_FACTOR] = 0

            crystalSound(id, SOUND_MENU_NAV)
            crystalMenu(id, MENU_LIGHT)
        }
        case LIGHT_COLOR:
        {
            if ( ++ g_ePlayerData[id][PDATA_LIGHT_COLOR] >= sizeof(g_iCrystalColors) )
                g_ePlayerData[id][PDATA_LIGHT_COLOR] = 0

            eCrystal[CRYSTAL_DLIGHT_COLOR][0] = g_iCrystalColors[g_ePlayerData[id][PDATA_LIGHT_COLOR]][0]
            eCrystal[CRYSTAL_DLIGHT_COLOR][1] = g_iCrystalColors[g_ePlayerData[id][PDATA_LIGHT_COLOR]][1]
            eCrystal[CRYSTAL_DLIGHT_COLOR][2] = g_iCrystalColors[g_ePlayerData[id][PDATA_LIGHT_COLOR]][2]
            ArraySetArray(g_aCrystal, iItem, eCrystal)

            crystalSound(id, SOUND_MENU_NAV)
            crystalMenu(id, MENU_LIGHT)
        }
        case LIGHT_PLACE:
        {
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_CRYSTAL_GHOST] = 0
            eCrystal[CRYSTAL_FLAGS] &= ~FLAG_LOCK
            crystalSetState(eCrystal)
            ArraySetArray(g_aCrystal, iItem, eCrystal)

            client_print_color(id, id, "%L %L", id, "CRYSTAL_CHAT_TAG", id, "CRYSTAL_CHAT_CREATE_NEW", eCrystal[CRYSTAL_NAME])
            crystalSound(id, SOUND_MENU_NAV)
            crystalMenu(id, MENU_ROOT)
        }
        case MENU_EXIT:
        {
            crystalKill(eCrystal[CRYSTAL_ID])
            crystalRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_CRYSTAL_GHOST] = 0

            crystalSound(id, SOUND_MENU_NAV)
            crystalMenu(id, MENU_CREATE)
        }
        default:
        {
            crystalKill(eCrystal[CRYSTAL_ID])
            crystalRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_CRYSTAL_GHOST] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public crystalTask()
{
    new eCrystal[CRYSTAL], bool:bModified, Float:fCurrentTime
    fCurrentTime = get_gametime()

    for ( new i = 0; i < g_iCrystal; i ++ )
    {
        ArrayGetArray(g_aCrystal, i, eCrystal)
        bModified = false

        if ( eCrystal[CRYSTAL_FLAGS] & FLAG_SHOW )
        {
            if ( eCrystal[CRYSTAL_FLAGS] & FLAG_ACTIVE )
            {
                crystalDraw(eCrystal)
                if ( !(eCrystal[CRYSTAL_FLAGS] & FLAG_LOCK) )
                {
                    crystalDistance(eCrystal, fCurrentTime)
                    bModified = true
                }

                if ( eCrystal[CRYSTAL_NEXT_RANDOM] > 0.0
                && fCurrentTime >= eCrystal[CRYSTAL_NEXT_RANDOM] )
                {
                    new iColor = random(sizeof(g_iCrystalColors))
                    eCrystal[CRYSTAL_DLIGHT_COLOR][0] = g_iCrystalColors[iColor][0]
                    eCrystal[CRYSTAL_DLIGHT_COLOR][1] = g_iCrystalColors[iColor][1]
                    eCrystal[CRYSTAL_DLIGHT_COLOR][2] = g_iCrystalColors[iColor][2]
                    eCrystal[CRYSTAL_NEXT_RANDOM] = fCurrentTime + random_float(eCrystal[CRYSTAL_COLOR_FREQUENCY][0], eCrystal[CRYSTAL_COLOR_FREQUENCY][1])

                    bModified = true
                }

                if ( eCrystal[CRYSTAL_NEXT_HIDE] > 0.0
                && fCurrentTime >= eCrystal[CRYSTAL_NEXT_HIDE] )
                {
                    eCrystal[CRYSTAL_FLAGS] &= ~FLAG_ACTIVE
                    eCrystal[CRYSTAL_FLAGS] |= FLAG_PENDING
                    eCrystal[CRYSTAL_NEXT_HIDE] = 0.0

                    bModified = true
                }
            }
            else
            {
                if ( eCrystal[CRYSTAL_FLAGS] & FLAG_REVERSE
                && eCrystal[CRYSTAL_FLAGS] & FLAG_LOCK )
                    crystalDraw(eCrystal)

                if ( eCrystal[CRYSTAL_FLAGS] & FLAG_PENDING
                && !(eCrystal[CRYSTAL_FLAGS] & FLAG_LOCK) )
                {
                    crystalDistance(eCrystal, fCurrentTime)
                    bModified = true
                }

                if ( eCrystal[CRYSTAL_NEXT_SHOW] > 0.0
                && fCurrentTime >= eCrystal[CRYSTAL_NEXT_SHOW] )
                {
                    eCrystal[CRYSTAL_FLAGS] |= FLAG_ACTIVE
                    eCrystal[CRYSTAL_FLAGS] &= ~FLAG_PENDING
                    eCrystal[CRYSTAL_NEXT_SHOW] = 0.0

                    bModified = true
                }
            }
        }

        if ( bModified )
            ArraySetArray(g_aCrystal, i, eCrystal)
    }
}

stock crystalCreate(id, iItem)
{
    new iEnt = cs_create_entity("info_target")
    if ( !pev_valid(iEnt) )
        return

    new eCrystal[CRYSTAL]
    ArrayGetArray(g_aCrystalConfig, iItem, eCrystal)
    eCrystal[CRYSTAL_ID] = iEnt
    eCrystal[CRYSTAL_ITEM] = iItem
    if ( id )
    {
        EnableAction(id)
        g_ePlayerData[id][PDATA_CRYSTAL_GHOST] = eCrystal[CRYSTAL_ID]
        g_ePlayerData[id][PDATA_ROTATE_MODE] = ROTATE_MODE_YAW
        g_ePlayerData[id][PDATA_OFFSET] = g_eSettings[SETTING_OFFSET_BASE]

        eCrystal[CRYSTAL_SIZE] = g_ePlayerData[id][PDATA_ROTATE_SIZE]
        eCrystal[CRYSTAL_SHAPE] = g_ePlayerData[id][PDATA_ROTATE_SHAPE]
        eCrystal[CRYSTAL_FLAGS] |= FLAG_GHOST
    }

    crystalSelect(eCrystal, TARGET_GHOST)
    set_pev(iEnt, pev_classname, g_szCN)
    set_pev(iEnt, pev_impulse, CRYSTAL_KEY)
    set_pev(iEnt, CRYSTAL_ARRAY_ITEM, g_iCrystal)
    dllfunc(DLLFunc_Spawn, iEnt)
    set_pev(iEnt, pev_solid, SOLID_NOT)
    set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
    set_pev(iEnt, pev_framerate, eCrystal[CRYSTAL_FRAMERATE])

    if ( id )
    {
        eCrystal[CRYSTAL_DLIGHT_SCALE] = g_iCrystalFactor[g_ePlayerData[id][PDATA_LIGHT_FACTOR]]
        eCrystal[CRYSTAL_DLIGHT_COLOR][0] = g_iCrystalColors[g_ePlayerData[id][PDATA_LIGHT_COLOR]][0]
        eCrystal[CRYSTAL_DLIGHT_COLOR][1] = g_iCrystalColors[g_ePlayerData[id][PDATA_LIGHT_COLOR]][1]
        eCrystal[CRYSTAL_DLIGHT_COLOR][2] = g_iCrystalColors[g_ePlayerData[id][PDATA_LIGHT_COLOR]][2]

        switch( eCrystal[CRYSTAL_SIZE] )
        {
            case SIZE_NORMAL:   engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_CRYSTAL_NORMAL])
            case SIZE_LARGE:    engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_CRYSTAL_LARGE])
        }
        set_pev(iEnt, pev_body, eCrystal[CRYSTAL_SHAPE])
    }

    ArrayPushArray(g_aCrystal, eCrystal)
    if ( ++ g_iCrystal == 1 )
        set_task(g_eSettings[SETTING_CRYSTAL_TASK], "crystalTask", CRYSTAL_KEY, .flags = "b")
}

public crystalRemove(iItem)
{
    new eCrystal[CRYSTAL]
    ArrayDeleteItem(g_aCrystal, iItem)

    if ( -- g_iCrystal == 0 )
        remove_task(CRYSTAL_KEY)

    for ( new i = iItem; i < g_iCrystal; i ++ )
    {
        ArrayGetArray(g_aCrystal, i, eCrystal)
        set_pev(eCrystal[CRYSTAL_ID], CRYSTAL_ARRAY_ITEM, i)
    }
}

public saveData(id)
{
    new eCrystal[CRYSTAL],
        szFile[128], iFile,
        szData[64]

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_XenCrystal.ini", szFile)

    iFile = fopen(szFile, "wt")
    if ( !iFile )
        return PLUGIN_HANDLED

    crystalTerminate()
    for ( new i = 0; i < g_iCrystal; i ++ )
    {
        ArrayGetArray(g_aCrystal, i, eCrystal)

        formatex(szData, charsmax(szData), "[%d]^n", i)
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "item = %d^n", eCrystal[CRYSTAL_ITEM])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "flags = %d^n", eCrystal[CRYSTAL_FLAGS])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "size = %d^n", eCrystal[CRYSTAL_SIZE])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "shape = %d^n", eCrystal[CRYSTAL_SHAPE])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "scale = %d^n", eCrystal[CRYSTAL_DLIGHT_SCALE])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "color = %d %d %d^n",
        eCrystal[CRYSTAL_DLIGHT_COLOR][0], eCrystal[CRYSTAL_DLIGHT_COLOR][1], eCrystal[CRYSTAL_DLIGHT_COLOR][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "origin = %.2f %.2f %.2f^n",
        eCrystal[CRYSTAL_ORIGIN][0], eCrystal[CRYSTAL_ORIGIN][1], eCrystal[CRYSTAL_ORIGIN][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "angles = %.2f %.2f %.2f^n",
        eCrystal[CRYSTAL_ANGLES][0], eCrystal[CRYSTAL_ANGLES][1], eCrystal[CRYSTAL_ANGLES][2])
        fputs(iFile, szData)
    }

    client_print_color(id, id, "%L %L", id, "CRYSTAL_CHAT_TAG", id, "CRYSTAL_CHAT_SAVE", szFile)
    fclose(iFile)

    crystalSound(id, SOUND_MENU_NAV)
    crystalMenu(id, MENU_ROOT)
    return PLUGIN_HANDLED
}

public loadData()
{
    new szFile[128], iFile,
        szData[64], szKey[32], szValue[32],
        Float:fOrigin[3], Float:fAngles[3], iItem, iFlags, iSize, iShape, iScale, iColor[3], iCount = -1

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_XenCrystal.ini", szFile)

    iFile = fopen(szFile, "rt")
    if ( !iFile )
        return

    while( !feof(iFile) )
    {
        fgets(iFile, szData, charsmax(szData))

        if ( szData[0] == '[' )
        {
            if ( iCount != -1 )
                loadDataCrystal(iItem, iFlags, iSize, iShape, iScale, iColor, fOrigin, fAngles, iCount)

            iCount ++
        }
        else
        {
            strtok(szData, szKey, charsmax( szKey ), szValue, charsmax( szValue ), '=')
            trim(szKey)
            trim(szValue)

            if ( equal(szKey, "item") )
            {
                iItem = str_to_num(szValue)
            }
            else if ( equal(szKey, "flags") )
            {
                iFlags = str_to_num(szValue)
            }
            else if ( equal(szKey, "size") )
            {
                iSize = str_to_num(szValue)
            }
            else if ( equal(szKey, "shape") )
            {
                iShape = str_to_num(szValue)
            }
            else if ( equal(szKey, "scale") )
            {
                iScale = str_to_num(szValue)
            }
            else if ( equal(szKey, "color") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                iColor[0] = str_to_num(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                iColor[1] = str_to_num(szKey)
                iColor[2] = str_to_num(szValue)
            }
            else if ( equal(szKey, "origin") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[1] = str_to_float(szKey)
                fOrigin[2] = str_to_float(szValue)
            }
            else if ( equal(szKey, "angles") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[1] = str_to_float(szKey)
                fAngles[2] = str_to_float(szValue)
            }
        }
    }

    if ( iCount != -1 )
        loadDataCrystal(iItem, iFlags, iSize, iShape, iScale, iColor, fOrigin, fAngles, iCount)

    fclose(iFile)
}

stock loadDataCrystal(iItem, iFlags, iSize, iShape, iScale, iColor[3], Float:fOrigin[3], Float:fAngles[3], iCount)
{
    new eCrystal[CRYSTAL]
    crystalCreate(0, iItem)
    ArrayGetArray(g_aCrystal, iCount, eCrystal)

    fAngles[0] = -fAngles[0]
    xs_vec_copy(fOrigin, eCrystal[CRYSTAL_ORIGIN])
    xs_vec_copy(fAngles, eCrystal[CRYSTAL_ANGLES])

    eCrystal[CRYSTAL_FLAGS] = iFlags
    eCrystal[CRYSTAL_SIZE] = iSize
    eCrystal[CRYSTAL_SHAPE] = iShape
    eCrystal[CRYSTAL_DLIGHT_SCALE] = iScale
    eCrystal[CRYSTAL_DLIGHT_COLOR][0] = iColor[0]
    eCrystal[CRYSTAL_DLIGHT_COLOR][1] = iColor[1]
    eCrystal[CRYSTAL_DLIGHT_COLOR][2] = iColor[2]

    switch( eCrystal[CRYSTAL_SIZE] )
    {
        case SIZE_NORMAL:   engfunc(EngFunc_SetModel, eCrystal[CRYSTAL_ID], g_eSettings[SETTING_MODEL_CRYSTAL_NORMAL])
        case SIZE_LARGE:    engfunc(EngFunc_SetModel, eCrystal[CRYSTAL_ID], g_eSettings[SETTING_MODEL_CRYSTAL_LARGE])
    }
    set_pev(eCrystal[CRYSTAL_ID], pev_body, eCrystal[CRYSTAL_SHAPE])

    crystalSetBox(eCrystal)
    crystalSetSize(eCrystal)
    crystalSetState(eCrystal)
    ArraySetArray(g_aCrystal, iCount, eCrystal)
}

public crystalNoClip(id)
{
    set_user_noclip(id, !get_user_noclip(id))

    crystalSound(id, SOUND_MENU_NAV)
    crystalMenu(id, MENU_ROOT)
}

public crystalGodMode(id)
{
    set_user_godmode(id, !get_user_godmode(id))

    crystalSound(id, SOUND_MENU_NAV)
    crystalMenu(id, MENU_ROOT)
}

public fwdPreThink(id)
{
    if ( !is_user_alive(id) )
        return HAM_IGNORED

    static eCrystal[CRYSTAL], iButton, Float:fCurrentTime
    iButton = pev(id, pev_button)
    fCurrentTime = get_gametime()

    if ( crystalGet(eCrystal, g_ePlayerData[id][PDATA_CRYSTAL_GHOST]) != -1
    && !(eCrystal[CRYSTAL_FLAGS] & FLAG_LOCK) )
    {
        if ( g_ePlayerData[id][PDATA_CRYSTAL_GHOST] )
        {
            if ( fCurrentTime > g_ePlayerData[id][PDATA_NEXT_OFFSET] )
            {
                if ( iButton & IN_ATTACK )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      += g_eSettings[SETTING_OFFSET_STEP]
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], g_eSettings[SETTING_OFFSET][0], g_eSettings[SETTING_OFFSET][1])
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
                else if ( iButton & IN_ATTACK2 )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      -= g_eSettings[SETTING_OFFSET_STEP]
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], g_eSettings[SETTING_OFFSET][0], g_eSettings[SETTING_OFFSET][1])
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
            }

            set_pdata_float(id, PDATA_NEXT_ATTACK, fCurrentTime + 0.1, XO_CBASEPLAYER, XO_CBASEPLAYER)
            iButton &= ~(IN_ATTACK | IN_ATTACK2)
            set_pev(id, pev_button, iButton)

            crystalTrace(eCrystal, id)
        }
    }
    else if ( g_ePlayerData[id][PDATA_CRYSTAL_ACTION] )
    {
        crystalCheck(id)
    }

    return HAM_IGNORED
}

public fwdKilled(id, iAttacker, bGib)
{
    DisableAction(id)
    g_ePlayerData[id][PDATA_CRYSTAL_MENU]   = 0
    if ( g_ePlayerData[id][PDATA_CRYSTAL_GHOST] )
    {
        new eCrystal[CRYSTAL], iItem
        if ( (iItem = crystalGet(eCrystal, g_ePlayerData[id][PDATA_CRYSTAL_GHOST])) != -1 )
        {
            crystalKill(eCrystal[CRYSTAL_ID])
            crystalRemove(iItem)
        }

        g_ePlayerData[id][PDATA_CRYSTAL_GHOST] = 0
    }
}

stock crystalTrace(eCrystal[CRYSTAL], id)
{
    new Float:fVec1[3]
    pev(id, pev_origin, eCrystal[CRYSTAL_ORIGIN])
    pev(id, pev_v_angle, fVec1)
    engfunc(EngFunc_MakeVectors, fVec1)
    global_get(glb_v_forward, fVec1)

    xs_vec_mul_scalar(fVec1, g_ePlayerData[id][PDATA_OFFSET], fVec1)
    xs_vec_add(fVec1, eCrystal[CRYSTAL_ORIGIN], fVec1)

    engfunc(EngFunc_TraceLine, eCrystal[CRYSTAL_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, id, 0)
    get_tr2(0, TR_vecEndPos, eCrystal[CRYSTAL_ORIGIN])

    crystalSetBox(eCrystal)
    crystalSetOffset(eCrystal)
    set_pev(eCrystal[CRYSTAL_ID], pev_origin, eCrystal[CRYSTAL_ORIGIN])
}

stock crystalCheck(id)
{
    new eCrystal[CRYSTAL], Float:fVec1[3], Float:fVec2[3], Float:fVec3[3], Float:fMins[3], Float:fMaxs[3], Float:fNearest[3]
    new iBest, Float:fBestDist, Float:fDot, Float:fDist

    pev(id, pev_origin, fVec1)
    pev(id, pev_view_ofs, fVec2)
    xs_vec_add(fVec1, fVec2, fVec1)

    pev(id, pev_v_angle, fVec2)
    engfunc(EngFunc_MakeVectors, fVec2)
    global_get(glb_v_forward, fVec2)

    iBest = -1
    fBestDist = g_eSettings[SETTING_CRYSTAL_CHECK]
    for ( new i = 0; i < g_iCrystal; i ++ )
    {
        ArrayGetArray(g_aCrystal, i, eCrystal)
        xs_vec_sub(eCrystal[CRYSTAL_ORIGIN], fVec1, fVec3)
        fDot = xs_vec_dot(fVec2, fVec3)

        if ( fDot < 0.0 )
            continue

        pev(eCrystal[CRYSTAL_ID], pev_absmin, fMins)
        pev(eCrystal[CRYSTAL_ID], pev_absmax, fMaxs)
        xs_vec_mul_scalar(fVec2, fDot, fVec3)
        xs_vec_add(fVec3, fVec1, fVec3)

        fNearest[0] = floatclamp(fVec3[0], fMins[0], fMaxs[0])
        fNearest[1] = floatclamp(fVec3[1], fMins[1], fMaxs[1])
        fNearest[2] = floatclamp(fVec3[2], fMins[2], fMaxs[2])
        fDist = get_distance_f(fVec3, fNearest)
        if ( fDist < fBestDist )
        {
            fBestDist = fDist
            iBest = i
        }
    }

    if ( iBest != -1
    && g_ePlayerData[id][PDATA_CRYSTAL_MENU] != iBest )
    {
        ArrayGetArray(g_aCrystal, g_ePlayerData[id][PDATA_CRYSTAL_MENU], eCrystal)
        crystalSelect(eCrystal, eCrystal[CRYSTAL_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

        g_ePlayerData[id][PDATA_MENU_TRACE] = true
        g_ePlayerData[id][PDATA_CRYSTAL_MENU] = iBest
        crystalMenu(id, g_ePlayerData[id][PDATA_MENU_TYPE])
    }
}

stock crystalDraw(eCrystal[CRYSTAL])
{
    message_begin_f(MSG_PVS, SVC_TEMPENTITY, eCrystal[CRYSTAL_ORIGIN])
    write_byte(TE_DLIGHT)
    write_coord_f(eCrystal[CRYSTAL_ORIGIN][0])
    write_coord_f(eCrystal[CRYSTAL_ORIGIN][1])
    write_coord_f(eCrystal[CRYSTAL_ORIGIN][2])
    write_byte(eCrystal[CRYSTAL_DLIGHT_SCALE])
    write_byte(eCrystal[CRYSTAL_DLIGHT_COLOR][0])
    write_byte(eCrystal[CRYSTAL_DLIGHT_COLOR][1])
    write_byte(eCrystal[CRYSTAL_DLIGHT_COLOR][2])
    write_byte(g_eSettings[SETTING_CRYSTAL_LIFE])
    write_byte(0)
    message_end()
}

stock crystalDistance(eCrystal[CRYSTAL], Float:fCurrentTime)
{
    new Float:fOrigin[3], id
    for ( id = 1; id <= g_iMaxPlayers; id ++ )
    {
        if ( !is_user_alive(id)
        || ( !(eCrystal[CRYSTAL_FLAGS] & FLAG_REVERSE) && CsTeams:eCrystal[CRYSTAL_TEAM] & cs_get_user_team(id))
        || ( eCrystal[CRYSTAL_FLAGS] & FLAG_REVERSE && !(CsTeams:eCrystal[CRYSTAL_TEAM] & cs_get_user_team(id))) )
            continue

        pev(id, pev_origin, fOrigin)
        if ( xs_vec_distance(fOrigin, eCrystal[CRYSTAL_ORIGIN]) > eCrystal[CRYSTAL_TRIGGER_DISTANCE] )
            continue

        if ( eCrystal[CRYSTAL_FLAGS] & FLAG_REVERSE )
        {
            eCrystal[CRYSTAL_FLAGS] |= FLAG_ACTIVE
            eCrystal[CRYSTAL_FLAGS] &= ~FLAG_PENDING
            eCrystal[CRYSTAL_NEXT_HIDE] = fCurrentTime + random_float(eCrystal[CRYSTAL_TRIGGER_DURATION][0], eCrystal[CRYSTAL_TRIGGER_DURATION][1])
        }
        else
        {
            eCrystal[CRYSTAL_FLAGS] &= ~FLAG_ACTIVE
            eCrystal[CRYSTAL_FLAGS] |= FLAG_PENDING
            eCrystal[CRYSTAL_NEXT_SHOW] = fCurrentTime + random_float(eCrystal[CRYSTAL_TRIGGER_DURATION][0], eCrystal[CRYSTAL_TRIGGER_DURATION][1])
        }

        break
    }
}

stock crystalSetBox(eCrystal[CRYSTAL])
{
    new Float:fMins[3], Float:fMaxs[3],
        Float:fForward[3], Float:fRight[3], Float:fUp[3],
        Float:fCorners[8][3]

    eCrystal[CRYSTAL_ANGLES][0] = -eCrystal[CRYSTAL_ANGLES][0]
    engfunc(EngFunc_AngleVectors, eCrystal[CRYSTAL_ANGLES], fForward, fRight, fUp)
    switch( eCrystal[CRYSTAL_SIZE] )
    {
        case SIZE_NORMAL:   { xs_vec_copy(g_eSettings[SETTING_MINS_NORMAL], fMins); xs_vec_copy(g_eSettings[SETTING_MAXS_NORMAL], fMaxs); }
        case SIZE_LARGE:    { xs_vec_copy(g_eSettings[SETTING_MINS_LARGE], fMins);  xs_vec_copy(g_eSettings[SETTING_MAXS_LARGE], fMaxs); }
    }

    for ( new i = 0; i < 8; i ++ )
    {
        fCorners[i][0] = (i & 1) ? fMaxs[0] : fMins[0]
        fCorners[i][1] = (i & 2) ? fMaxs[1] : fMins[1]
        fCorners[i][2] = (i & 4) ? fMaxs[2] : fMins[2]

        boxRotate(fCorners[i], fForward, fRight, fUp)
    }

    xs_vec_copy(fCorners[0], fMins)
    xs_vec_copy(fCorners[0], fMaxs)
    for ( new i = 1; i < 8; i ++ )
    {
        fMins[0] = floatmin(fMins[0], fCorners[i][0])
        fMins[1] = floatmin(fMins[1], fCorners[i][1])
        fMins[2] = floatmin(fMins[2], fCorners[i][2])

        fMaxs[0] = floatmax(fMaxs[0], fCorners[i][0])
        fMaxs[1] = floatmax(fMaxs[1], fCorners[i][1])
        fMaxs[2] = floatmax(fMaxs[2], fCorners[i][2])
    }

    xs_vec_copy(fMins, eCrystal[CRYSTAL_MINS])
    xs_vec_copy(fMaxs, eCrystal[CRYSTAL_MAXS])
}

stock boxRotate(Float:fLocal[3], Float:fForward[3], Float:fRight[3], Float:fUp[3])
{
    new Float:fOut[3]
    fOut[0] = fLocal[0] * fForward[0] - fLocal[1] * fRight[0] + fLocal[2] * fUp[0]
    fOut[1] = fLocal[0] * fForward[1] - fLocal[1] * fRight[1] + fLocal[2] * fUp[1]
    fOut[2] = fLocal[0] * fForward[2] - fLocal[1] * fRight[2] + fLocal[2] * fUp[2]

    xs_vec_copy(fOut, fLocal)
}

stock crystalSetOffset(eCrystal[CRYSTAL])
{
    new Float:fGaps[6], Float:fVec1[3], Float:fCurrentGap
    fGaps[0] = -eCrystal[CRYSTAL_MINS][0]
    fGaps[1] = eCrystal[CRYSTAL_MAXS][0]
    fGaps[2] = -eCrystal[CRYSTAL_MINS][1]
    fGaps[3] = eCrystal[CRYSTAL_MAXS][1]
    fGaps[4] = -eCrystal[CRYSTAL_MINS][2]
    fGaps[5] = eCrystal[CRYSTAL_MAXS][2]

    if ( eCrystal[CRYSTAL_FLAGS] & FLAG_GROUND )
    {
        xs_vec_sub(eCrystal[CRYSTAL_ORIGIN], Float:{0.0, 0.0, 9999.9}, fVec1)
        engfunc(EngFunc_TraceLine, eCrystal[CRYSTAL_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, eCrystal[CRYSTAL_ID], 0)
        get_tr2(0, TR_vecEndPos, eCrystal[CRYSTAL_ORIGIN])
    }

    for ( new i = 5; i >= 0; i -- )
    {
        xs_vec_mul_scalar(g_fDirections[i], 9999.9, fVec1)
        xs_vec_add(fVec1, eCrystal[CRYSTAL_ORIGIN], fVec1)
        engfunc(EngFunc_TraceLine, eCrystal[CRYSTAL_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, eCrystal[CRYSTAL_ID], 0)
        get_tr2(0, TR_vecEndPos, fVec1)
        fCurrentGap = xs_vec_distance(eCrystal[CRYSTAL_ORIGIN], fVec1)

        if ( fCurrentGap < fGaps[i] )
        {
            get_tr2(0, TR_vecPlaneNormal, fVec1)
            xs_vec_mul_scalar(fVec1, fGaps[i] - fCurrentGap, fVec1)
            xs_vec_add(eCrystal[CRYSTAL_ORIGIN], fVec1, eCrystal[CRYSTAL_ORIGIN])
        }
    }
}

stock crystalSetSize(eCrystal[CRYSTAL])
{
    crystalSelect(eCrystal, TARGET_CLEAR)
    engfunc(EngFunc_SetOrigin, eCrystal[CRYSTAL_ID], eCrystal[CRYSTAL_ORIGIN])
    set_pev(eCrystal[CRYSTAL_ID], pev_angles, eCrystal[CRYSTAL_ANGLES])
    set_pev(eCrystal[CRYSTAL_ID], pev_solid, eCrystal[CRYSTAL_FLAGS] & (FLAG_SOLID | FLAG_SHOW) == (FLAG_SOLID | FLAG_SHOW) ? SOLID_BBOX : SOLID_NOT)
    set_pev(eCrystal[CRYSTAL_ID], pev_movetype, MOVETYPE_NONE)

    engfunc(EngFunc_SetSize, eCrystal[CRYSTAL_ID], eCrystal[CRYSTAL_MINS], eCrystal[CRYSTAL_MAXS])
}

stock crystalSetState(eCrystal[CRYSTAL])
{
    if ( eCrystal[CRYSTAL_FLAGS] & FLAG_COLOR_RANDOM )
        eCrystal[CRYSTAL_NEXT_RANDOM] = get_gametime() + random_float(eCrystal[CRYSTAL_COLOR_FREQUENCY][0], eCrystal[CRYSTAL_COLOR_FREQUENCY][1])

    if ( eCrystal[CRYSTAL_FLAGS] & FLAG_SHOW )
    {
        set_pev(eCrystal[CRYSTAL_ID], pev_solid, eCrystal[CRYSTAL_FLAGS] & FLAG_SOLID ? SOLID_BBOX : SOLID_NOT)
        crystalSelect(eCrystal, TARGET_CLEAR)
    }
    else
    {
        set_pev(eCrystal[CRYSTAL_ID], pev_solid, SOLID_NOT)
        crystalSelect(eCrystal, TARGET_HIDE)
    }
}

stock crystalSelect(eCrystal[CRYSTAL], iAction)
{
    new iRender, iRenderFx, iRenderColor[3], iRenderAmt

    iRenderFx = kRenderFxNone
    if ( iAction == TARGET_SELECT )
    {
        if ( eCrystal[CRYSTAL_FLAGS] & FLAG_ACTIVE )    { iRenderColor[0] = g_iColorActive[0];   iRenderColor[1] = g_iColorActive[1];     iRenderColor[2] = g_iColorActive[2]; }
        else                                            { iRenderColor[0] = g_iColorInactive[0]; iRenderColor[1] = g_iColorInactive[1];   iRenderColor[2] = g_iColorInactive[2]; }

        iRender = kRenderTransColor
        iRenderFx = kRenderFxGlowShell
        iRenderAmt = 16
    }
    else if ( iAction == TARGET_GHOST )
    {
        iRender = kRenderTransAlpha
        iRenderAmt = g_eSettings[SETTING_GHOST_ALPHA]
    }
    else if ( iAction == TARGET_HIDE )
    {
        iRender = kRenderTransAlpha
        iRenderAmt = 0
    }
    else if ( iAction == TARGET_CLEAR )
    {
        iRender = kRenderNormal
        iRenderAmt = 255
    }

    set_ent_rendering(eCrystal[CRYSTAL_ID], iRenderFx, iRenderColor[0], iRenderColor[1], iRenderColor[2], iRender, iRenderAmt)
}

stock crystalReset()
{
    new eCrystal[CRYSTAL]
    for ( new i = 0; i < g_iCrystal; i ++ )
    {
        ArrayGetArray(g_aCrystal, i, eCrystal)
        eCrystal[CRYSTAL_NEXT_HIDE] = 0.0
        eCrystal[CRYSTAL_NEXT_SHOW] = 0.0
        eCrystal[CRYSTAL_NEXT_RANDOM] = 0.0
        ArraySetArray(g_aCrystal, i, eCrystal)
    }
}

stock crystalSound(iEnt, iSound, bool:bPlayer = true)
{
    new szSample[64]
    switch( iSound )
    {
        case SOUND_MENU_NAV:    copy(szSample, charsmax(szSample), SOUND_NAV)
        case SOUND_MENU_REMOVE: copy(szSample, charsmax(szSample), SOUND_REMOVE)
        case SOUND_MENU_ALERT:  copy(szSample, charsmax(szSample), SOUND_ALERT)
    }

    if ( bPlayer )
        client_cmd(iEnt, "spk %s", szSample)
    else
        engfunc(EngFunc_EmitSound, iEnt, CHAN_ITEM, szSample, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

stock crystalGet(eCrystal[CRYSTAL], iEnt)
{
    if ( !isCrystal(iEnt) )
        return -1

    new iItem
    iItem = pev(iEnt, CRYSTAL_ARRAY_ITEM)
    if ( iItem < 0 || iItem >= g_iCrystal )
        return -1

    ArrayGetArray(g_aCrystal, iItem, eCrystal)
    return iItem
}

stock bool:isCrystal(iEnt)
{
    return pev_valid(iEnt) && pev(iEnt, pev_impulse) == CRYSTAL_KEY
}

stock crystalKill(iEnt)
{
    if (pev_valid(iEnt))
        set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
}

stock parseSetting(iType, szValue[], iValueLen, any:aOutput[], iOutputLength)
{
    switch ( iType )
    {
        case DTYPE_INT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_num(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLOAT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_float(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLAGS:
        {
            aOutput[0] = read_flags(szValue)
        }
        case DTYPE_ARRAY_STRING:
        {
            replace_all(szValue, iValueLen, "^"", " ")
            replace_all(szValue, iValueLen, "^^n", "^n")
            ArrayPushString(aOutput[0], szValue)
        }
        case DTYPE_ARRAY_SOUND:
        {
            ArrayPushString(aOutput[0], szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_STRING_MODEL:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_model(szValue)
        }
        case DTYPE_STRING_SOUND:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_STRING_MODEL_ID:
        {
            if ( !g_bFileWasRead )
                aOutput[0] = precache_model(szValue)
        }
    }
}

stock EnableAction(id)
{
    if ( !g_ePlayerData[id][PDATA_CRYSTAL_ACTION] )
    {
        new eCrystal[CRYSTAL]
        for ( new i = 0; i < g_iCrystal; i ++ )
        {
            ArrayGetArray(g_aCrystal, i, eCrystal)
            if ( eCrystal[CRYSTAL_FLAGS] & FLAG_SHOW )
                continue

            crystalSelect(eCrystal, TARGET_GHOST)
        }

        g_ePlayerData[id][PDATA_CRYSTAL_ACTION] = true
        if ( ++ g_iActivePlayers == 1 )
            EnableForward()
    }
}

stock DisableAction(id)
{
    if ( g_ePlayerData[id][PDATA_CRYSTAL_ACTION] )
    {
        new eCrystal[CRYSTAL]
        for ( new i = 0; i < g_iCrystal; i ++ )
        {
            ArrayGetArray(g_aCrystal, i, eCrystal)
            if ( eCrystal[CRYSTAL_FLAGS] & FLAG_SHOW )
                continue

            crystalSelect(eCrystal, TARGET_HIDE)
        }

        g_ePlayerData[id][PDATA_CRYSTAL_ACTION] = false
        if ( -- g_iActivePlayers == 0 )
            DisableForward()
    }
}

stock EnableForward()
{
    EnableHamForward(g_iFwdPreThink)
    EnableHamForward(g_iFwdKilled)
}

stock DisableForward()
{
    DisableHamForward(g_iFwdPreThink)
    DisableHamForward(g_iFwdKilled)
}

stock LogConfigError(const iLine, const szText[], any:...)
{
    new szError[MAX_PLATFORM_PATH_LENGTH]
    vformat(szError, charsmax(szError), szText, 3)

    log_to_file(ERROR_FILE, "^nLine %d: %s", iLine, szError)
}