#include "tilemap.h"
#include "resources.h"

typedef struct TileTypeSpriteLocation
{
    unsigned char x;
    unsigned char y;
    unsigned char width, height;
} TileTypeSpriteLocation;

// a mapping of a pattern of 2x2 vertices to a sprite in the tileset
TileTypeSpriteLocation tileTypeSpriteLocations[] = {
    // 0 0 
    // 0 0 (does not exist)
    {0xff, 0xff},
    // 0 0
    // 0 1
    {0, 0},
    // 0 0
    // 1 0
    {3, 0},
    // 0 0
    // 1 1
    {1, 0, 1, 0},
    // 0 1
    // 0 0
    {0, 4},
    // 0 1
    // 0 1
    {0, 1, 0, 2},
    // 0 1
    // 1 0 (does not exist)
    {0xff, 0xff},
    // 0 1
    // 1 1
    {2, 3},
    // 1 0
    // 0 0
    {3, 4},
    // 1 0
    // 0 1 (does not exist)
    {0xff, 0xff},
    // 1 0
    // 1 0
    {3, 1, 0, 2},
    // 1 0
    // 1 1
    {1, 3},
    // 1 1
    // 0 0
    {1, 4, 1, 0},
    // 1 1
    // 0 1
    {2, 2},
    // 1 1
    // 1 0
    {1, 2},
    // 1 1
    // 1 1
    {1, 1, 1, 0}
};

static int GetLocationRandom(int x, int y, int z, int max)
{
    unsigned int seed = x * 17 ^ y * 11 ^ z * 7 + 291123835;
    seed = (seed % 1221) ^ seed ^ x * 19 + y * 31 + z * 29;
    return seed % (max + 1);
}

void Tilemap_parse(Tilemap *tilemap, const char *content)
{
    int lineCount = 0;
    int height = 0;
    int width = 0;
    int numbersInLineCount = 0;
    for (int i=0;content[i];i++)
    {
        if (content[i] == '\n')
        {
            lineCount++;
            if (numbersInLineCount > 0)
            {
                if (width == 0) width = numbersInLineCount;
                else if (width != numbersInLineCount)
                {
                    TraceLog(LOG_WARNING, "Tilemap width mismatch in line %d", lineCount);
                }
                height++;
            }
            numbersInLineCount = 0;
        }
        else if (content[i] >= '0' && content[i] <= '9')
        {
            numbersInLineCount++;
        }
    }

    if (tilemap->tiles) MemFree(tilemap->tiles);
    tilemap->width = width;
    tilemap->height = height;
    tilemap->tiles = MemAlloc(sizeof(unsigned char) * width * height);
    TraceLog(LOG_INFO, "Tilemap %s loaded with dimensions %dx%d", tilemap->filepath ? tilemap->filepath : "<no file>", width, lineCount);
    lineCount = 0;
    numbersInLineCount = 0;
    int y = 0;
    for (int i=0;content[i];i++)
    {
        if (content[i] == '\n')
        {
            lineCount++;
            if (numbersInLineCount > 0)
            {
                y++;
            }

            numbersInLineCount = 0;
        }
        else if (content[i] >= '0' && content[i] <= '9')
        {
            tilemap->tiles[y * width + numbersInLineCount] = content[i] - '0';
            numbersInLineCount++;
        }
    }
}

// this is a naive and simple tile drawing implementation
void Tilemap_draw(Tilemap *tilemap, Vector2 position, Vector2 scale, Color color)
{
    if (tilemap->filepath && GetFileModTime(tilemap->filepath) - 1 > tilemap->fileModTime)
    {
        tilemap->fileModTime = GetFileModTime(tilemap->filepath);
        char* content = LoadFileText(tilemap->filepath);
        if (content)
        {
            Tilemap_parse(tilemap, content);
        }
        else
        {
            TraceLog(LOG_WARNING, "Failed to load tilemap file %s", tilemap->filepath);
        }
    }

    // the tilemap sprites are stored in a single texture
    // Each tile type is expressed by a group of sprites in the tileset.
    // The pattern describes the tile itself and its transitions to transparent
    // borders. The following visual pattern describes the _vertices_ of each tile where 
    // 0 is transparent and 1 is solid 
    // 0 0 0 0 0
    // 0 1 1 1 0
    // 0 1 1 1 0
    // 0 1 0 1 0
    // 0 1 1 1 0
    // 0 0 0 0 0
    // Each 2x2 square is one tile with each corner representing a vertex. The pattern
    // 0 1
    // 0 1
    // represents a tile where the right side is solid and the left side is transparent.
    // The pattern
    // 0 1
    // 1 0
    // is not present and must be handled by the drawing logic by combining these two tiles
    // 0 1 | 0 0
    // 0 0 | 1 0
    // The tilemap is stored as a 1D array of unsigned chars where each byte represents a tile
    // type of a _vertice_ of a tile. 
    // The order of drawing tile types is determined by the ordinal value of the tile type.

    int maxY = tilemap->height - 1;
    int maxX = tilemap->width - 1;

    for (int y = 0; y < maxY; y++)
    {
        int tileIndex = y * tilemap->width;
        Vector2 tilePosition = (Vector2){
                0, 
                position.y + y * tilemap->tileHeight * scale.y};
        for (int x = 0; x < maxX; x++, tileIndex++)
        {
            int typeA = tilemap->tiles[tileIndex] - 1;
            int typeB = tilemap->tiles[tileIndex + 1] - 1;
            int typeC = tilemap->tiles[tileIndex + tilemap->width] - 1;
            int typeD = tilemap->tiles[tileIndex + tilemap->width + 1] - 1;
            int minType = (typeA < typeB) ? typeA : typeB;
            minType = (minType < typeC) ? minType : typeC;
            minType = (minType < typeD) ? minType : typeD;
            int maxType = (typeA > typeB) ? typeA : typeB;
            maxType = (maxType > typeC) ? maxType : typeC;
            maxType = (maxType > typeD) ? maxType : typeD;
            if (minType < 0) {
                if (maxType == -1) continue;
                minType = 0;
            }

            tilePosition.x = position.x + x * tilemap->tileWidth * scale.x;

            // iterate over all possible types to determine which ones to draw 
            for (int tileTypeId = minType; tileTypeId <= maxType; tileTypeId++)
            {
                unsigned char typeAId = (typeA == tileTypeId) ? 1 : 0;
                unsigned char typeBId = (typeB == tileTypeId) ? 1 : 0;
                unsigned char typeCId = (typeC == tileTypeId) ? 1 : 0;
                unsigned char typeDId = (typeD == tileTypeId) ? 1 : 0;

                int tileTypePattern = typeAId << 3 | typeBId << 2 | typeCId << 1 | typeDId << 0;
                if (tileTypePattern == 0) continue;
                int hasDiagonalPattern = 0;
                // diagonal pattern handling
                if (tileTypePattern == 0b1001) 
                {
                    hasDiagonalPattern = 0b0001;
                    tileTypePattern = 0b1000;
                }
                if (tileTypePattern == 0b0110)
                {
                    hasDiagonalPattern = 0b0010;
                    tileTypePattern = 0b0100;
                }

                paintTile: ;
                TileTypeSpriteLocation spriteLocation = tileTypeSpriteLocations[tileTypePattern];
                int srcX = spriteLocation.x + (spriteLocation.width > 0 ? GetLocationRandom(x, y, tileTypeId, spriteLocation.width) : 0);
                int srcY = spriteLocation.y + (spriteLocation.height > 0 ? GetLocationRandom(x, y, tileTypeId, spriteLocation.height) : 0);
                Rectangle source = (Rectangle){
                    (tileTypeId * 4 + srcX) * tilemap->tileWidth, 
                    srcY * tilemap->tileHeight, 
                    tilemap->tileWidth, tilemap->tileHeight
                };
                DrawTexturePro(resources.tileset, source, (Rectangle){tilePosition.x, tilePosition.y, tilemap->tileWidth * scale.x, tilemap->tileHeight * scale.y}, 
                    (Vector2){0, 0}, 0, color);
                
                if (hasDiagonalPattern)
                {
                    tileTypePattern = hasDiagonalPattern;
                    hasDiagonalPattern = 0;
                    goto paintTile;
                }
                
            }
        }
    }
}