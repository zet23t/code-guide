#ifndef __RESOURCES_H__
#define __RESOURCES_H__

#include "raylib.h"

typedef struct Resources
{
    Texture2D tileset;
    long tilesetModifiedTime;
} Resources;

extern Resources resources;

void Resources_load();
void Resources_update();

#endif