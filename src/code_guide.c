#include "raylib.h"
#include "raymath.h"
#include "resources.h"
#include "tilemap.h"
#include "util.h"

#include <stddef.h> // Required for: NULL
#include <math.h> // Required for: abs

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

// copied from lua sources; needed for running lua code in a safe way

static int msghandler (lua_State *L) {
  const char *msg = lua_tostring(L, 1);
  if (msg == NULL) {  /* is error object not a string? */
    if (luaL_callmeta(L, 1, "__tostring") &&  /* does it have a metamethod */
        lua_type(L, -1) == LUA_TSTRING)  /* that produces a string? */
      return 1;  /* that is the message */
    else
      msg = lua_pushfstring(L, "(error object is a %s value)",
                               luaL_typename(L, 1));
  }
  luaL_traceback(L, L, msg, 1);  /* append a standard traceback */
  return 1;  /* return the traceback */
}


/*
** Interface to 'lua_pcall', which sets appropriate message function
** and C-signal handler. Used to run all chunks.
*/
static int docall (lua_State *L, int narg, int nres) {
  int status;
  int base = lua_gettop(L) - narg;  /* function index */
  lua_pushcfunction(L, msghandler);  /* push message handler */
  lua_insert(L, base);  /* put it under function and args */
  status = lua_pcall(L, narg, nres, base);
  lua_remove(L, base);  /* remove message handler from the stack */
  return status;
}

// Lua binding functions - sloppy quick and dirtily added so I can get on with the guide
int lua_Tilemap_new(lua_State *L)
{
    int width = luaL_checkinteger(L, 1);
    int height = luaL_checkinteger(L, 2);
    int tileWidth = luaL_optinteger(L, 3, 16);
    int tileHeight = luaL_optinteger(L, 4, 16);
    Tilemap *tilemap = lua_newuserdata(L, sizeof(Tilemap));
    tilemap->tiles = NULL;
    tilemap->filepath = NULL;
    tilemap->width = width;
    tilemap->height = height;
    tilemap->tileWidth = tileWidth;
    tilemap->tileHeight = tileHeight;
    luaL_setmetatable(L, "Tilemap");
    return 1;
}

int lua_Tilemap_draw(lua_State *L)
{
    Tilemap *tilemap = luaL_checkudata(L, 1, "Tilemap");
    int x = luaL_checkinteger(L, 2);
    int y = luaL_checkinteger(L, 3);
    if (tilemap->tiles != NULL)
    {
        Tilemap_draw(tilemap, (Vector2){x, y}, (Vector2){2, 2}, WHITE);
    }
    else
    {
        TraceLog(LOG_ERROR, "tilemap not initialized\n");
    }
    lua_pushvalue(L, 1);
    return 1;
}

int lua_Tilemap_parse(lua_State *L)
{
    Tilemap *tilemap = luaL_checkudata(L, 1, "Tilemap");
    Tilemap_parse(tilemap, luaL_checkstring(L, 2));
    lua_pushvalue(L, 1);
    return 1;
}

int lua_Tilemap_getValue(lua_State *L)
{
    Tilemap *tilemap = luaL_checkudata(L, 1, "Tilemap");
    int x = luaL_checkinteger(L, 2);
    int y = luaL_checkinteger(L, 3);
    if (x < 0 || y < 0 || x >= tilemap->width || y >= tilemap->height)
    {
        lua_pushinteger(L, 0);
        return 1;
    }
    lua_pushinteger(L, tilemap->tiles[y * tilemap->width + x]);
    return 1;
}

int lua_Tilemap_getSize(lua_State *L)
{
    Tilemap *tilemap = luaL_checkudata(L, 1, "Tilemap");
    lua_pushinteger(L, tilemap->width);
    lua_pushinteger(L, tilemap->height);
    return 2;
}

int luaopen_Tilemap(lua_State *L)
{
    luaL_Reg functions[] = {
        {"new", lua_Tilemap_new},
        {"draw", lua_Tilemap_draw},
        {"parse", lua_Tilemap_parse},
        {"getValue", lua_Tilemap_getValue},
        {"getSize", lua_Tilemap_getSize},
        {NULL, NULL}
    };

    luaL_newlib(L, functions);
    luaL_newmetatable(L, "Tilemap");
    lua_pushvalue(L, -2);
    lua_setfield(L, -2, "__index");
    lua_pop(L, 1);

    return 1;
}

static Color luaDrawColor = {255, 255, 255, 255};
static int luaDrawColorAlpha = 255;
static Color luaClearColor = {0, 0, 0, 0};
static int luaCurrentStepIndex = 0;

static Color getCurrentColor()
{
    int a = luaDrawColorAlpha * luaDrawColor.a / 255;
    return (Color){luaDrawColor.r, luaDrawColor.g, luaDrawColor.b, a};
}

int lua_SetCurrentStepIndex(lua_State *L)
{
    luaCurrentStepIndex = luaL_checkinteger(L, 1);
    return 0;
}

int lua_GetCurrentStepIndex(lua_State *L)
{
    lua_pushinteger(L, luaCurrentStepIndex);
    return 1;
}

int lua_SetClearColor(lua_State *L)
{
    int r = luaL_checkinteger(L, 1);
    int g = luaL_checkinteger(L, 2);
    int b = luaL_checkinteger(L, 3);
    int a = luaL_optinteger(L, 4, 255);
    luaClearColor = (Color){r, g, b, a};
    return 0;
}

int lua_SetColor(lua_State *L)
{
    int r = luaL_checkinteger(L, 1);
    int g = luaL_checkinteger(L, 2);
    int b = luaL_checkinteger(L, 3);
    int a = luaL_optinteger(L, 4, 255);
    luaDrawColor = (Color){r, g, b, a};
    return 0;
}

int lua_SetColorAlpha(lua_State *L)
{
    int a = luaL_checkinteger(L, 1);
    luaDrawColorAlpha = a;
    return 0;
}

int lua_SetLineSpacing(lua_State *L)
{
    SetTextLineSpacingEx(luaL_checkinteger(L, 1));
    return 0;
}

int lua_BeginScissorMode(lua_State *L)
{
    BeginScissorMode(luaL_checkinteger(L, 1), luaL_checkinteger(L, 2),
        luaL_checkinteger(L,3), luaL_checkinteger(L, 4));
    return 0;
}

int lua_EndScissorMode(lua_State *L)
{
    EndScissorMode();
    return 0;
}

int lua_DrawRectangle(lua_State *L)
{
    int x = (int)luaL_checknumber(L, 1);
    int y = (int)luaL_checknumber(L, 2);
    int w = (int)luaL_checknumber(L, 3);
    int h = (int)luaL_checknumber(L, 4);
    DrawRectangle(x, y, w, h, getCurrentColor());
    return 0;
}

int lua_GetScreenSize(lua_State *L)
{
    lua_pushinteger(L, GetScreenWidth());
    lua_pushinteger(L, GetScreenHeight());
    return 2;
}

int lua_DrawBubble(lua_State *L)
{
    int x = luaL_checkinteger(L, 1);
    int y = luaL_checkinteger(L, 2);
    int w = luaL_checkinteger(L, 3);
    int h = luaL_checkinteger(L, 4);
    float angle = luaL_checknumber(L, 5);
    int arrowX = luaL_checkinteger(L, 6);
    int arrowY = luaL_checkinteger(L, 7);
    DrawBubble(x, y, w, h, angle, arrowX, arrowY, getCurrentColor());
    return 0;
}

int lua_DrawTextBoxAligned(lua_State *L)
{
    const char *text = luaL_checkstring(L, 1);
    int fontSize = luaL_checkinteger(L, 2);
    int x = luaL_checkinteger(L, 3);
    int y = luaL_checkinteger(L, 4);
    int w = luaL_checkinteger(L, 5);
    int h = luaL_checkinteger(L, 6);
    float alignX = luaL_checknumber(L, 7);
    float alignY = luaL_checknumber(L, 8);
    Rectangle rect = DrawTextBoxAligned(text, fontSize, x, y, w, h, alignX, alignY, getCurrentColor());
    lua_pushnumber(L, rect.x);
    lua_pushnumber(L, rect.y);
    lua_pushnumber(L, rect.width);
    lua_pushnumber(L, rect.height);
    return 4;
}

int lua_DrawTriangle(lua_State *L)
{
    float x1 = (float)luaL_checknumber(L, 1);
    float y1 = (float)luaL_checknumber(L, 2);
    float x2 = (float)luaL_checknumber(L, 3);
    float y2 = (float)luaL_checknumber(L, 4);
    float x3 = (float)luaL_checknumber(L, 5);
    float y3 = (float)luaL_checknumber(L, 6);
    DrawTriangle((Vector2){x1, y1}, (Vector2){x2, y2}, (Vector2){x3, y3}, getCurrentColor());
    return 0;
}

int lua_DrawLine(lua_State *L)
{
    float x1 = (float)luaL_checknumber(L, 1);
    float y1 = (float)luaL_checknumber(L, 2);
    float x2 = (float)luaL_checknumber(L, 3);
    float y2 = (float)luaL_checknumber(L, 4);
    float thickness = (float)luaL_optnumber(L, 5, 1.0f);

    DrawLineEx((Vector2){x1, y1}, (Vector2){x2, y2}, thickness, getCurrentColor());
    return 0;
}

int lua_Sprite(lua_State *L)
{
    float srcX = (float)luaL_checknumber(L, 1);
    float srcY = (float)luaL_checknumber(L, 2);
    float srcWidth = (float)luaL_checknumber(L, 3);
    float srcHeight = (float)luaL_checknumber(L, 4);
    float dstX = (float)luaL_checknumber(L, 5);
    float dstY = (float)luaL_checknumber(L, 6);
    float dstWidth = (float)luaL_optnumber(L, 7, srcWidth * 2);
    float dstHeight = (float)luaL_optnumber(L, 8, srcHeight * 2);
    Texture2D texture = resources.tileset;
    Rectangle srcRec = (Rectangle){ srcX, srcY, srcWidth, srcHeight };
    Rectangle dstRec = (Rectangle){ dstX, dstY, dstWidth, dstHeight };
    DrawTexturePro(texture, srcRec, dstRec, (Vector2){0, 0}, 0.0f, getCurrentColor());
    return 0;
}

int lua_GetFrameTime(lua_State *L)
{
    lua_pushnumber(L, GetFrameTime());
    return 1;
}

int lua_GetTime(lua_State *L)
{
    lua_pushnumber(L, GetTime());
    return 1;
}

int lua_IsNumberKeyPressed(lua_State *L)
{
    int key = luaL_checkinteger(L, 1);
    lua_pushboolean(L, IsKeyPressed(key + KEY_ZERO));
    return 1;
}

int lua_IsNextPagePressed(lua_State *L)
{
    lua_pushboolean(L, IsKeyPressed(KEY_ENTER) || IsKeyPressed(KEY_RIGHT));
    return 1;
}

int lua_IsPreviousPagePressed(lua_State *L)
{
    lua_pushboolean(L, IsKeyPressed(KEY_BACKSPACE) || IsKeyPressed(KEY_LEFT));
    return 1;
}

int lua_IsMenuKeyPressed(lua_State*L)
{
    lua_pushboolean(L, IsKeyPressed(KEY_SPACE));
    return 1;
}

#define TOUCHPOINT_PHASE_BEGIN 1
#define TOUCHPOINT_PHASE_CONTACT 2
#define TOUCHPOINT_PHASE_RELEASED 3
#define TOUCHPOINT_PHASE_HOVER 4
typedef struct TouchPoint
{
    Vector2 position;
    Vector2 previousPosition;
    Vector2 startPosition;
    int phase;
    int previousPhase;
    int id;
} TouchPoint;

static TouchPoint _touchPoints[16];
static int _touchPointCount;

static TouchPoint *TouchPoint_getById(int id)
{
    for (int i=0;i<_touchPointCount;i++)
    {
        if (_touchPoints[i].id == id)
        {
            return &_touchPoints[i];
        }
    }

    return NULL;
}

static void TouchPoint_update()
{
    for (int i=0;i<_touchPointCount;i++)
    {
        _touchPoints[i].previousPosition = _touchPoints[i].position;
        _touchPoints[i].previousPhase = _touchPoints[i].phase;
        _touchPoints[i].phase = 0;
    }
    
    // for (int i=0;i<_touchPointCount;i++)
    // {
    //     TraceLog(LOG_INFO, "? touch[%d] %d: %d %d %d %d", i , _touchPoints[i].id, _touchPoints[i].phase, _touchPoints[i].previousPhase, (int)_touchPoints[i].position.x, (int)_touchPoints[i].position.y);
    // }
    int touchCount = GetTouchPointCount();
    for (int i=0;i<touchCount;i++)
    {
        Vector2 pos = GetTouchPosition(i);
        int touchId = GetTouchPointId(i);
        TouchPoint *touch = TouchPoint_getById(touchId);
        if (touch == NULL)
        {
            _touchPoints[_touchPointCount++] = (TouchPoint){
                .id = touchId,
                .phase = TOUCHPOINT_PHASE_BEGIN,
                .position = pos,
                .previousPhase = 0,
                .startPosition = pos
            };
        }
        else
        {
            touch->previousPhase = TOUCHPOINT_PHASE_CONTACT;
            touch->position = pos;
        }
    }

    TouchPoint *mouse = TouchPoint_getById(-123);
    if (mouse == NULL)
    {
        _touchPoints[_touchPointCount++] = (TouchPoint) {
            .id = -123,
            .phase = TOUCHPOINT_PHASE_HOVER,
            .position = GetMousePosition(),
            .previousPosition = GetMousePosition(),
            .startPosition = GetMousePosition()
        };
    }
    else
    {
        mouse->position = GetMousePosition();
        if (IsMouseButtonDown(MOUSE_BUTTON_LEFT))
        {
            mouse->phase = TOUCHPOINT_PHASE_CONTACT;
            if (mouse->previousPhase == TOUCHPOINT_PHASE_HOVER)
            {
                mouse->startPosition = mouse->position;
            }
        }
        else
        {
            mouse->phase = (mouse->previousPhase == TOUCHPOINT_PHASE_CONTACT) 
                ? TOUCHPOINT_PHASE_RELEASED
                : TOUCHPOINT_PHASE_HOVER;
        }
    }

    int record = 0;
    for (int i=0;i<_touchPointCount;i++)
    {
        TouchPoint *touch = &_touchPoints[i];
        if (touch->phase == 0 && touch->previousPhase == 0)
        {
            // remove
            continue;
        }
        if (touch->phase == 0 && touch->previousPhase == TOUCHPOINT_PHASE_CONTACT)
        {
            touch->phase = TOUCHPOINT_PHASE_RELEASED;
        }
        _touchPoints[record++] = *touch;
    }
    _touchPointCount = record;

    // for (int i=0;i<_touchPointCount;i++)
    // {
    //     TraceLog(LOG_INFO, "%d touch[%d] %d: %d %d %d %d", touchCount,i , _touchPoints[i].id, _touchPoints[i].phase, _touchPoints[i].previousPhase, (int)_touchPoints[i].position.x, (int)_touchPoints[i].position.y);
    // }
}

static int lua_GetInputAreaStatus(lua_State *L)
{
    float x = (float)luaL_checknumber(L, 1);
    float y = (float)luaL_checknumber(L, 2);
    float w = (float)luaL_checknumber(L, 3);
    float h = (float)luaL_checknumber(L, 4);
    Rectangle rect = {x,y,w,h};
    
    for (int i=0;i<_touchPointCount;i++)
    {
        TouchPoint *touch = &_touchPoints[i];
        if (CheckCollisionPointRec(touch->startPosition, rect))
        {
            if (CheckCollisionPointRec(touch->position, rect))
            {
                if (touch->phase == TOUCHPOINT_PHASE_RELEASED)
                {
                    lua_pushstring(L, "activated");
                }
                else if (touch->phase == TOUCHPOINT_PHASE_CONTACT ||touch->phase == TOUCHPOINT_PHASE_BEGIN)
                {
                    lua_pushstring(L, "pressed");
                }
                else if (touch->phase == TOUCHPOINT_PHASE_HOVER)
                {
                    lua_pushstring(L, "hover");
                }
                else
                {
                    lua_pushstring(L, "unknown");
                }
                return 1;
            }
        }
        if (touch->phase == TOUCHPOINT_PHASE_HOVER && CheckCollisionPointRec(touch->position, rect))
        {
            lua_pushstring(L, "hover");
            return 1;
        }
    }
    return 0;
}

void init_lua(lua_State *L)
{
    luaL_openlibs(L);
    
    luaL_requiref(L, "Tilemap", luaopen_Tilemap, 0);

    luaL_Reg functions[] = {
        {"SetClearColor", lua_SetClearColor},
        {"SetColor", lua_SetColor},
        {"SetColorAlpha", lua_SetColorAlpha},
        {"SetLineSpacing", lua_SetLineSpacing},
        {"SetCurrentStepIndex", lua_SetCurrentStepIndex},
        {"GetCurrentStepIndex", lua_GetCurrentStepIndex},
        {"DrawTextBoxAligned", lua_DrawTextBoxAligned},
        {"BeginScissorMode", lua_BeginScissorMode},
        {"EndScissorMode", lua_EndScissorMode},
        {"DrawRectangle", lua_DrawRectangle},
        {"GetScreenSize", lua_GetScreenSize},
        {"DrawBubble", lua_DrawBubble},
        {"DrawTriangle", lua_DrawTriangle},
        {"DrawLine", lua_DrawLine},
        {"Sprite", lua_Sprite},
        {"GetTime", lua_GetTime},
        {"GetFrameTime", lua_GetFrameTime},
        {"IsNumberKeyPressed", lua_IsNumberKeyPressed},
        {"IsNextPagePressed", lua_IsNextPagePressed},
        {"IsPreviousPagePressed", lua_IsPreviousPagePressed},
        {"IsMenuKeyPressed", lua_IsMenuKeyPressed},
        {"GetInputAreaStatus", lua_GetInputAreaStatus},
        {NULL, NULL}
    };
    lua_pushglobaltable(L);
    luaL_setfuncs(L, functions, 0);
    lua_pop(L, 1);

    if (luaL_loadfile(L, "resources/script.lua") != 0) {
        luaL_traceback(L, L, lua_tostring(L, -1), 1);
        TraceLog(LOG_ERROR, "%s\n", lua_tostring(L, -1));
        lua_pop(L, 1);
        return;
    }
    
    if (docall(L, 0, 0) != 0) {
        luaL_traceback(L, L, lua_tostring(L, -1), 1);
        TraceLog(LOG_ERROR, "%s\n", lua_tostring(L, -1));
        lua_pop(L, 1);
        return;
    }
}

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
int main(void)
{
    lua_State *L = luaL_newstate();
    SetTraceLogLevel(LOG_ALL);
    // Initialization
    //--------------------------------------------------------------------------------------
    const int screenWidth = 800;
    const int screenHeight = 450;

    InitWindow(screenWidth, screenHeight, "Code Guide");

    SetTargetFPS(60);

    Resources_load();
    
    int codePoints[256];
    for (int i=0;i<256;i++)
    {
        codePoints[i] = i + 32;
    }
    codePoints[200] = 0x25CF;
    SetDefaultFonts((Font[]){
        LoadFontEx("resources/Roboto-Bold.ttf", 15, codePoints, 256),
        LoadFontEx("resources/Roboto-Bold.ttf", 20, codePoints, 256),
        LoadFontEx("resources/Roboto-Bold.ttf", 30, codePoints, 256),
        LoadFontEx("resources/Roboto-Bold.ttf", 40, codePoints, 256),
        {0}
    });
    SetDefaultMonoFonts((Font[]){
        LoadFontEx("resources/RobotoMono-Medium.ttf", 10, codePoints, 256),
        LoadFontEx("resources/RobotoMono-Medium.ttf", 15, codePoints, 256),
        LoadFontEx("resources/RobotoMono-Medium.ttf", 20, codePoints, 256),
        LoadFontEx("resources/RobotoMono-Medium.ttf", 30, codePoints, 256),
        LoadFontEx("resources/RobotoMono-Medium.ttf", 40, codePoints, 256),
        {0}
    });

    // Tutorial_init();
    init_lua(L);
    
    //--------------------------------------------------------------------------------------
    long scriptModTime = GetFileModTime("resources/script.lua");
    float reloadTimeOut = 0.0f;
    // Main game loop
    while (!WindowShouldClose())    // Detect window close button or ESC key
    {
        Resources_update();
        TouchPoint_update();
        if (IsKeyPressed(KEY_ENTER) || IsKeyPressed(KEY_RIGHT)) luaCurrentStepIndex++;
        if (IsKeyPressed(KEY_BACKSPACE) || IsKeyPressed(KEY_LEFT)) luaCurrentStepIndex--;
        if (IsKeyPressed(KEY_R)) luaCurrentStepIndex = 0;

        if (GetFileModTime("resources/script.lua") > scriptModTime)
        {
            scriptModTime = GetFileModTime("resources/script.lua");
            reloadTimeOut = 0.5f + GetTime();
        }
        if (IsKeyPressed(KEY_F5) || (GetTime() > reloadTimeOut && reloadTimeOut > 0.0f))
        {
            reloadTimeOut = 0.0f;
            TraceLog(LOG_INFO, "closing old lua state\n");
            // lua_close(L);
            TraceLog(LOG_INFO, "reloading script\n");
            L = luaL_newstate();
            init_lua(L);
        }
        //----------------------------------------------------------------------------------
        // Draw
        //----------------------------------------------------------------------------------
        BeginDrawing();

            ClearBackground(luaClearColor);

            lua_getglobal(L, "draw");
            if (lua_isfunction(L, -1))
            {
                lua_pushnumber(L, GetFrameTime());
                if (docall(L, 1, 0) != 0) {
                    luaL_traceback(L, L, lua_tostring(L, -1), 1);
                    TraceLog(LOG_ERROR, "%s\n", lua_tostring(L, -1));
                    lua_pop(L, 1);
                    lua_pushnil(L);
                    lua_setglobal(L, "draw");
                }
            }
        EndDrawing();
        //----------------------------------------------------------------------------------
    }

    // De-Initialization
    //--------------------------------------------------------------------------------------
    CloseWindow();
    //--------------------------------------------------------------------------------------

    return 0;
}

