#ifndef __UTIL_H__
#define __UTIL_H__

#include "raylib.h"
#include "stddef.h"
#include <math.h> // Required for: floor, abs

typedef struct StyledTextBox
{
    const char *text;
    int displayedLineCount;
    int fontSize;
    Rectangle box;
    Vector2 align;
    Color color;
    int underScoreOffset;
    int underScoreSize;
} StyledTextBox;

void SetDefaultFonts(Font *fonts);
void SetDefaultMonoFonts(Font *fonts);
void SetTextLineSpacingEx(int spacing);
Rectangle DrawTextBoxAligned(const char *text, int fontSize, int x, int y, int w, int h, float alignX, float alignY, Color color);
Rectangle DrawStyledTextBox(StyledTextBox styledTextBox);

#define ARROW_NONE 0
#define ARROW_UP 1
#define ARROW_DOWN 2
#define ARROW_LEFT 3
#define ARROW_RIGHT 4

void DrawBubble(int x, int y, int w, int h, float arrowAngle, int arrowX, int arrowY, Color color);
void DrawGuy(int x, int y);
void DrawHouse(int x, int y);

#endif