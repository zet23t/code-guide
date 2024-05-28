#include "resources.h"

Resources resources;

void Resources_load()
{
    resources.tileset = LoadTexture("resources/tileset.png");
    resources.tilesetModifiedTime = GetFileModTime("resources/tileset.png");
}

static int frameCounter = 0;
static bool reloadTileset = false;
void Resources_update()
{
    // don't check time stamps too often
    if (frameCounter++ % 60 != 0) return;

    long modifiedTime = GetFileModTime("resources/tileset.png");
    if (modifiedTime > resources.tilesetModifiedTime)
    {
        reloadTileset = true;
        resources.tilesetModifiedTime = modifiedTime;
        return;
    }
    if (reloadTileset)
    {
        reloadTileset = false;
        UnloadTexture(resources.tileset);
        resources.tileset = LoadTexture("resources/tileset.png");
    }
}