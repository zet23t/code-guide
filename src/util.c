#include "util.h"
#include "resources.h"
#include "rlgl.h"
#include <string.h> // used for strncmp

static Font* defaultFonts;
static Font* monoFonts;

static Font* CopyFonts(Font *fonts)
{
    int fontCount = 0;
    while (fonts[fontCount++].recs != NULL);
    Font* copy = (Font*)MemAlloc(sizeof(Font) * (fontCount + 1));
    for (int i=0;i<=fontCount;i++)
    {
        copy[i] = fonts[i];
    }
    return copy;
}

static Font GetFontBySize(Font *fonts, int size)
{
    for (int i=1; fonts[i].recs; i++)
    {
        int baseSize = fonts[i].baseSize;
        if (size <= baseSize)
        {
            Font previousFont = fonts[i - 1];
            int diff1 = size - previousFont.baseSize;
            int diff2 = baseSize - size;
            return (diff1 < diff2) ? previousFont : fonts[i];
        }
    }
    return fonts[0];
}

void SetDefaultFonts(Font *fonts)
{
    defaultFonts = CopyFonts(fonts);
}

void SetDefaultMonoFonts(Font *fonts)
{
    monoFonts = CopyFonts(fonts);
}

Font GetFont(int size)
{
    return GetFontBySize(defaultFonts, size);
}

Font GetMonoFont(int size)
{
    return GetFontBySize(monoFonts, size);
}

void DrawHouse(int x, int y)
{
    DrawTexturePro(resources.tileset, (Rectangle){80, 464, 48, 48}, (Rectangle){x * 2, y * 2, 96, 96}, (Vector2){0, 0}, 0, WHITE);
}

void DrawGuy(int x, int y)
{
    int animationTime = (int)(GetTime() * 2.0f) % 4;
    DrawTexturePro(resources.tileset, 
        (Rectangle){0, 464, 16, 16}, (Rectangle){x - 16, y - 28, 32, 32}, (Vector2){0, 0}, 0, WHITE);
    // face
    DrawTexturePro(resources.tileset, 
        (Rectangle){16 * animationTime, 448, 16, 16}, (Rectangle){x - 14, y - 48, 32, 32}, (Vector2){0, 0}, 0, WHITE);

}

void DrawBubble(int x, int y, int w, int h, float arrowAngle, int arrowX, int arrowY, Color color)
{
    const NPatchInfo ninePatch = {
        .source = {0, 480, 32, 32},
        .left = 12,
        .top = 12,
        .right = 12,
        .bottom = 12,
        .layout = NPATCH_NINE_PATCH
    };


    rlPushMatrix();
    rlScalef(2.0f, 2.0f, 1.0f);
    
    x /= 2;
    y /= 2;
    w /= 2;
    h /= 2;
    arrowX /= 2;
    arrowY /= 2;
   
    if (arrowAngle >= 0.0f)
        DrawTexturePro(resources.tileset, 
            (Rectangle){32, 496, 32, 16}, 
            (Rectangle){x + arrowX + 2, y + arrowY + 2, 32, 16}, (Vector2){2, 8}, arrowAngle, (Color){0, 0, 0, 128});
    DrawTextureNPatch(resources.tileset, ninePatch, (Rectangle){x + 2, y + 2, w, h}, (Vector2){0, 0}, 0, (Color){0, 0, 0, 128});
    
    if (arrowAngle >= 0.0f)
        DrawTexturePro(resources.tileset, 
            (Rectangle){32, 496, 32, 16}, 
            (Rectangle){x + arrowX, y + arrowY, 32, 16}, (Vector2){2, 8}, arrowAngle, color);
    DrawTextureNPatch(resources.tileset, ninePatch, (Rectangle){x, y, w, h}, (Vector2){0, 0}, 0, color);

    rlPopMatrix();
}

static int textLineSpacing = 0;
void SetTextLineSpacingEx(int spacing)
{
    SetTextLineSpacing(spacing);
    textLineSpacing = spacing;
}

static int hexToInt(char chr)
{
    if (chr >= '0' && chr <= '9') return chr - '0';
    if (chr >= 'a' && chr <= 'f') return chr - 'a' + 10;
    if (chr >= 'A' && chr <= 'F') return chr - 'A' + 10;
    return -1;
}

// Measure string size for Font
static Vector2 MeasureTextRich(Font font, const char *text, float fontSize, float spacing)
{
    Vector2 textSize = { 0 };

    if ((font.texture.id == 0) || (text == NULL)) return textSize; // Security check

    int size = TextLength(text);    // Get size in bytes of text
    int tempByteCounter = 0;        // Used to count longer text line num chars
    int byteCounter = 0;

    float textWidth = 0.0f;
    float tempTextWidth = 0.0f;     // Used to count longer text line width

    float textHeight = fontSize;
    float scaleFactor = fontSize/(float)font.baseSize;

    int letter = 0;                 // Current character
    int index = 0;                  // Index position in sprite font

    for (int i = 0; i < size;)
    {
        byteCounter++;

        int next = 0;
        letter = GetCodepointNext(&text[i], &next);
        index = GetGlyphIndex(font, letter);

        if (letter == '[')
        {
            // check for color tag
            if (strncmp(&text[i], "[color=", 7) == 0 && size - i >= 11 && text[i+11] == ']')
            {
                int r = hexToInt(text[i + 7]);
                int g = hexToInt(text[i + 8]);
                int b = hexToInt(text[i + 9]);
                int a = hexToInt(text[i + 10]);
                if (r >= 0 && g >= 0 && b >= 0 && a >= 0)
                {
                    i+= 12;
                    continue;
                }
            }
            if (strncmp(&text[i], "[/color]", 8) == 0)
            {
                i += 8;
                continue;
            }
        }

        i += next;

        if (letter != '\n')
        {
            if (font.glyphs[index].advanceX != 0) textWidth += font.glyphs[index].advanceX;
            else textWidth += (font.recs[index].width + font.glyphs[index].offsetX);
        }
        else
        {
            if (tempTextWidth < textWidth) tempTextWidth = textWidth;
            byteCounter = 0;
            textWidth = 0;

            // NOTE: Line spacing is a global variable, use SetTextLineSpacing() to setup
            textHeight += (fontSize + textLineSpacing);
        }

        if (tempByteCounter < byteCounter) tempByteCounter = byteCounter;
    }

    if (tempTextWidth < textWidth) tempTextWidth = textWidth;

    textSize.x = tempTextWidth*scaleFactor + (float)((tempByteCounter - 1)*spacing);
    textSize.y = textHeight;

    return textSize;
}

// Draw text using Font
// NOTE: chars spacing is NOT proportional to fontSize
static void DrawTextRich(Font font, const char *text, Vector2 position, float fontSize, float spacing, Color tint)
{
    if (font.texture.id == 0) font = GetFontDefault();  // Security check in case of not valid font

    int size = TextLength(text);    // Total size in bytes of the text, scanned by codepoints in loop

    float textOffsetY = 0;          // Offset between lines (on linebreak '\n')
    float textOffsetX = 0.0f;       // Offset X to next character to draw

    float scaleFactor = fontSize/font.baseSize;         // Character quad scaling factor
    int alpha = tint.a;
    Color colorStack[16];
    int colorStackIndex = 0;

    for (int i = 0; i < size;)
    {
        // Get next codepoint from byte string and glyph index in font
        int codepointByteCount = 0;
        int codepoint = GetCodepointNext(&text[i], &codepointByteCount);
        int index = GetGlyphIndex(font, codepoint);

        if (codepoint == '[')
        {
            // check for color tag
            if (strncmp(&text[i], "[color=", 7) == 0 && size - i >= 11 && text[i+11] == ']')
            {
                int r = hexToInt(text[i + 7]);
                int g = hexToInt(text[i + 8]);
                int b = hexToInt(text[i + 9]);
                int a = hexToInt(text[i + 10]);
                if (r >= 0 && g >= 0 && b >= 0 && a >= 0)
                {
                    // valid color tag
                    Color rgba = {r | r << 4, g | g << 4, b | b << 4, 
                        (a | a << 4) * alpha / 255 };
                    i+= 12;
                    if (colorStackIndex < 16)
                        colorStack[colorStackIndex++] = tint;
                    else TraceLog(LOG_WARNING, "Color stack overflow");
                    tint = rgba;
                    continue;
                }
            }
            if (strncmp(&text[i], "[/color]", 8) == 0)
            {
                if (colorStackIndex > 0)
                {
                    tint = colorStack[--colorStackIndex];
                }
                i += 8;
                continue;
            }
        }

        if (codepoint == '\n')
        {
            // NOTE: Line spacing is a global variable, use SetTextLineSpacing() to setup
            textOffsetY += (fontSize + textLineSpacing);
            textOffsetX = 0.0f;
        }
        else
        {
            if ((codepoint != ' ') && (codepoint != '\t'))
            {
                DrawTextCodepoint(font, codepoint, (Vector2){ position.x + textOffsetX, position.y + textOffsetY }, fontSize, tint);
            }

            if (font.glyphs[index].advanceX == 0) textOffsetX += ((float)font.recs[index].width*scaleFactor + spacing);
            else textOffsetX += ((float)font.glyphs[index].advanceX*scaleFactor + spacing);
        }

        i += codepointByteCount;   // Move text bytes counter to next codepoint
    }
}

Rectangle DrawTextBoxAligned(const char *text, int fontSize, int x, int y, int w, int h, float alignX, float alignY, Color color)
{
    Font *fonts = fontSize < 0 ? monoFonts : defaultFonts;
    fontSize = fontSize < 0 ? -fontSize : fontSize;
    float fontSpacing = floor(fontSize * 0.025f);
    Font font = GetFontBySize(fonts, fontSize);
    Vector2 textSize = MeasureTextRich(font, text, fontSize, fontSpacing);
    int posX = x + (int)((w - textSize.x) * alignX);
    int posY = y + (int)((h - textSize.y) * alignY);
    DrawTextRich(font, text, (Vector2){posX, posY}, fontSize, fontSpacing, color);

    return (Rectangle) {
        .x = posX, .y = posY, .width = textSize.x, .height = textSize.y
    };
}

Rectangle DrawStyledTextBox(StyledTextBox styledTextBox)
{
    char text[1024] = {0};
    int linesToDisplay = styledTextBox.displayedLineCount;
    for (int i=0;styledTextBox.text[i];i++)
    {
        text[i] = styledTextBox.text[i];
        if (text[i] == '\n')
        {
            linesToDisplay--;
            if (linesToDisplay == 0)
            {
                text[i] = '\0';
                break;
            }
        }
    }

    Rectangle rect = DrawTextBoxAligned(text, styledTextBox.fontSize,
        styledTextBox.box.x, styledTextBox.box.y,
        styledTextBox.box.width, styledTextBox.box.height, 
        styledTextBox.align.x, styledTextBox.align.y,
        styledTextBox.color);
    if (styledTextBox.underScoreSize > 0)
    {
        DrawRectangle(rect.x, rect.y + rect.height + styledTextBox.underScoreOffset, 
            rect.width, styledTextBox.underScoreSize, styledTextBox.color);
    }
    return rect;
}