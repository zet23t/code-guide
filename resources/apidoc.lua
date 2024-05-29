---Sets the current clear color
---@param r integer 0-255
---@param g integer 0-255
---@param b integer 0-255
---@param a integer 0-255
function SetClearColor(r,g,b,a) end

---Sets the current color
---@param r integer 0-255
---@param g integer 0-255
---@param b integer 0-255
---@param a integer 0-255
function SetColor(r,g,b,a) end

---Sets a blend that modifies the final alpha value for every draw, regardless of the color set
---@param a integer 0-255
function SetColorAlpha(a) end

---Draws a rectangle using the current color
---@param x integer
---@param y integer
---@param w integer
---@param h integer
function DrawRectangle(x,y,w,h) end

---Draws a speech bubble
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param arrow_angle number in degrees
---@param arrow_x integer arrow tip relative to x
---@param arrow_y integer arrow tip relative to y
function DrawBubble(x,y,w,h, arrow_angle, arrow_x, arrow_y) end

---Draws a text within the specified rectangle
---@param text string
---@param fontsize integer
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param align_x number
---@param align_y number
---@return number x, number y, number width, number height the actual text boundaries drawn
function DrawTextBoxAligned(text, fontsize, x, y, w, h, align_x, align_y) return 0,0,0,0 end

function IsNextPagePressed() return false end
function IsPreviousPagePressed() return false end
function GetCurrentStepIndex() return 0 end
function SetCurrentStepIndex(i) return 0 end

function DrawLine(x1, y1, x2, y2, thickness) end
function DrawTriangle(x1, y1, x2, y2, x3, y3) end
---Draws a sprite using the tilemap texture
---@param srcX integer
---@param srcY integer
---@param srcWidth integer
---@param srcHeight integer
---@param dstX integer
---@param dstY integer
---@param dstWidth integer|nil uses srcWidth if nil
---@param dstHeight integer|nil uses srcHeight if nil
function Sprite(srcX,
    srcY,
    srcWidth,
    srcHeight,
    dstX,
    dstY,
    dstWidth,
    dstHeight) end

function GetTime() return 0.0 end
function GetFrameTime() return 0.0 end
function GetScreenSize() return 0,0 end

function IsMenuKeyPressed() return false end
function IsNumberKeyPressed(number) return false end

function BeginScissorMode(x, y, w, h) end
function EndScissorMode() end


---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@return "activated"|"pressed"|"hover"|"unknown"|nil
function GetInputAreaStatus(x,y,w,h) return "activated" end