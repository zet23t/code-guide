#ifndef __TILEMAP_H__
#define __TILEMAP_H__

#include "raylib.h"

typedef struct Tilemap
{
    unsigned char *tiles;
    const char *filepath;
    long fileModTime;
    int width;
    int height;
    int tileWidth;
    int tileHeight;
} Tilemap;

void Tilemap_parse(Tilemap *tilemap, const char *content);
void Tilemap_draw(Tilemap *tilemap, Vector2 position, Vector2 scale, Color color);

#endif