--[[
This script defines all the steps in the demo that explains the different
path finding algorithms. It is NOT straight forward to read and understand.
It is in fact quite messy since I focused on creating a smooth demonstration
rather than a clean script. 


]]

-- longer benchmarkTimes mean longer startup times but better accuracy
local benchmarkTime = 0.05
local tilemap = require "Tilemap"
local syntaxHighlightLua = require "resources.syntaxHighlightLua"

local map = tilemap.new(16, 16)
local overlay = tilemap.new(16, 16)
map:parse[[
    1 1 1 1  1 1 1 1  1 1 1 1  1 1 1 1  1 1 1 1  1 1 1 1  1 1 1 0
    1 1 3 3  3 3 3 3  3 1 1 1  1 1 1 1  1 1 1 1  1 1 1 1  1 1 1 1
    1 3 3 4  4 4 4 3  3 3 3 3  3 3 1 1  1 1 1 1  1 1 1 1  1 1 1 1
    1 3 4 4  4 4 4 4  4 4 4 4  4 3 3 3  3 3 3 3  3 1 1 1  1 1 1 1
    
    1 3 3 3  4 4 4 4  5 5 5 4  4 4 3 3  3 3 3 3  3 3 3 1  1 1 1 1
    1 1 1 3  3 3 5 4  4 4 5 5  4 4 4 3  3 4 5 4  4 3 3 3  1 1 1 1
    1 1 1 1  1 1 1 5  3 5 5 5  4 4 4 3  4 5 5 5  4 3 3 3  1 1 1 1
    1 1 1 1  1 3 5 5  3 4 4 4  4 4 3 3  4 4 5 5  5 5 5 3  3 1 1 1
    
    1 1 5 3  3 3 3 3  3 3 3 4  5 5 4 4  4 3 3 5  5 5 3 3  1 1 1 1
    1 3 5 4  4 4 4 4  4 5 5 5  5 5 5 4  4 4 2 4  3 3 3 1  1 3 1 1
    1 5 5 4  4 4 4 4  4 4 5 5  4 4 4 4  4 4 2 2  2 4 4 1  3 5 5 1
    1 3 3 3  4 4 4 4  4 4 5 5  4 4 4 4  4 4 4 4  4 4 4 1  3 5 5 1
    
    1 1 1 3  4 4 4 4  3 4 4 4  4 4 4 1  3 3 3 3  3 3 3 1  3 5 3 1
    1 1 1 3  3 3 4 4  3 3 3 3  3 3 3 1  5 3 1 1  1 3 1 1  1 3 3 1
    1 1 1 1  1 3 3 1  1 1 3 3  1 1 1 5  5 5 1 1  1 1 1 1  1 3 1 1
    0 1 1 1  1 1 1 1  1 1 1 1  1 1 1 5  5 1 1 1  1 1 1 1  1 1 1 0
]]
overlay:parse[[
    0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0
    0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0
    0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0
    0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0
    
    0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0
    0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 6 0  0 0 0 0  0 0 0 0
    0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 6 6 6  0 0 0 0  0 0 0 0
    0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0
    
    0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0
    0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0
    0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0
    0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0
    
    0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0
    0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0
    0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0
    0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0
]]

local mapWidth, mapHeight = map:getSize()

local function getBlockedMap(map, useCosts)
    local blockedMap = {}
    local w,h = map:getSize()
    -- local m = {}
    for y=0,h - 1 do
        local index = y * w
        for x=0,w - 1 do
            local tileId = map:getValue(x, y)
            if useCosts then
                local costs = 0
                if tileId == 3 then
                    costs = 3
                elseif tileId == 4 then
                    costs = 1
                end
                blockedMap[index + x] = costs
            else
                blockedMap[index + x] = tileId < 3 or tileId == 5
            end
            -- m[#m + 1] = blockedMap[index + x] and "_" or "1"
        end
        -- m[#m+1] = "\n"
    end
    -- print(table.concat(m, ""))
    return blockedMap
end

local trimCache = {}
local function trim(s)
    if trimCache[s] then
        return table.unpack(trimCache[s])
    end
    local result = {}
    for line in s:gmatch("[^\r\n]*") do
        local trimmed = line:match("^%s*|?(.-)%s*$")
        table.insert(result, trimmed)
    end
    if result[#result] == "" then
        table.remove(result)
    end
    local trimmed = table.concat(result, "\n")
    trimCache[s] = {trimmed, #result}
    return trimmed, #result
end

local guyPos = {x = 400.5, y = 100}
local guyTarget = {x = 400.5, y = 100}
local guySpeed = 1
local guyIsMoving = false
local function guyUpdate(dt)
    local dx = guyTarget.x - guyPos.x
    local dy = guyTarget.y - guyPos.y
    local len = math.sqrt(dx * dx + dy * dy)
    if len > 10 then
        guyIsMoving = true
        guyPos.x = guyPos.x + dx / len * guySpeed
        guyPos.y = guyPos.y + dy / len * guySpeed
    else
        guyIsMoving = false
    end
end

local function guyDraw()
    local x, y = guyPos.x, guyPos.y
    local t = GetTime()
    if guyIsMoving then
        y = y - math.abs(math.sin(t * 15) * 8)
    end
    local animationTime = math.floor(t * 2) % 4;
    Sprite(0, 464, 16, 16, x - 16, y - 28)
    Sprite(16 * animationTime, 448, 16, 16, x - 14, y - 48);
end

local function moveValueTo(value, target, speed, dt)
    local diff = target - value
    local change = diff * speed * dt
    if math.abs(diff) < math.abs(change) then
        return target
    end
    return value + change
end

local function eval(value, arg)
    if type(value) == "function" then
        return value(arg)
    end
    return value
end

local codeExecutorRunToStepWarpRangeDefault = 16
local codeExecutorStepsPerSecondDefault = 3
local codeExecutorRunning = false
local codeExecutorAlpha = 255
local codeExecutorShowLine = nil
local codeExecutorRunToLine = nil
local codeExecutorSetStep = nil
local codeExecutorRunToStep = nil
local codeExecutorRunToStepWarpRange = codeExecutorRunToStepWarpRangeDefault
local codeExecutorStepsPerSecond = codeExecutorStepsPerSecondDefault
local codeExecutorDisplayValueOverlay = false
local codeExecutorStats = {}
local function codeExecutor(name, code, x, y, w, h, fontsize, contextEnv, stackInfoHandler)
    local func, err = load(code, nil, "t", contextEnv)
    if not func then
        print(err)
        return
    end
    local maxStepCount = 30000
    local highlightedText, codelines = syntaxHighlightLua(code)
    local highlightedText,lineCount = trim(err or highlightedText)
    local codeHeight = math.abs(fontsize) * lineCount
    w = w or 400
    fontsize = fontsize or 20
    x = x or math.floor((GetScreenSize() - w) / 2)
    y = y or 15
    h = h or 200
    local coro
    local currentStep = 1
    local totalLineExec = 0
    local getInfosAt
    function getInfosAt(step)
        coro = coroutine.create(func)
        local stepCount = 0
        local stackInfo = { line = 0}
        local stackStart = 2
        local cloneCache = {}
        local function clone(value)
            if type(value) ~= "table" then
                return value
            end
            if cloneCache[value] then
                return cloneCache[value]
            end
            local result = {}
            cloneCache[value] = result
            for k,v in pairs(value) do
                result[k] = clone(v)
            end
            return result
        end
        debug.sethook(coro, function(event, line)
            stepCount = stepCount + 1
            if stepCount > maxStepCount then
                error("Code execution limit reached")
            end
            if stepCount == step then
                stackInfo.line = line
                for stackIndex = stackStart, 200 do
                    local info = {}
                    local func = debug.getinfo(stackIndex, "fnl")
                    if not func then
                        break
                    end
                    info.func = func
                    info.locals = {}
                    for valueIndex = 1, 200 do
                        local name, value = debug.getlocal(stackIndex, valueIndex)
                        if not name then
                            break
                        end
                        if name ~= "(temporary)" then
                            info.locals[#info.locals+1] = {name = name, value = clone(value) }
                        end
                    end
                    stackInfo[#stackInfo+1] = info
                end

            end
        end, "l")
        local suc, err = coroutine.resume(coro)
        if not suc then
            print(err)
        end
        return stackInfo
    end
    local t1, t2 = GetTime()
    local n = 0
    repeat
        coro = coroutine.create(func)
        n = n + 1
        t2 = GetTime()
        local suc, err = coroutine.resume(coro)
        if not suc then
            print(err)
            return
        end
    until t2 - t1 > benchmarkTime

    coro = coroutine.create(func)

    debug.sethook(coro, function(event, line)
        totalLineExec = totalLineExec + 1
        if totalLineExec > maxStepCount then
            error("Code execution limit reached")
        end
    end, "l")
    local suc, err = coroutine.resume(coro)
    if not suc then
        print(err)
    end
    local dt = (t2 - t1) / n
    print(("dt=%.3fms (%d) locExec=%d"):format(dt*1000, n,totalLineExec))
    codeExecutorStats[#codeExecutorStats+1] = {
        name = name,
        time = dt,
        n = n,
        totalLineExec = totalLineExec
    }

    local nextStep = GetTime() + 1 / codeExecutorStepsPerSecond
    local currentLine = 1
    local currentStackInfo = {}
    local currentLineShown = 1
    local maxScrollSpeed = 2
    local wordsByLine = {}
    for i, line in ipairs(codelines) do
        local words = {}
        for pos,word in line:gmatch("()([a-zA-Z_][a-zA-Z_0-9]*)") do
            words[#words + 1] = {word = word, pos = pos}
        end
        wordsByLine[#wordsByLine + 1] = words
    end

    return function(step)
        if step.activeTime == 0 then
            currentStep = 0
            nextStep = 0
        end
        local time = GetTime()
        local remainingSteps = 2

        currentStep = math.min(currentStep, totalLineExec - 1)
        while time > nextStep and getInfosAt and 
            (codeExecutorRunning or codeExecutorSetStep or 
            (codeExecutorRunToLine and codeExecutorRunToLine ~= currentLine) or
            (codeExecutorRunToStep)
            ) and remainingSteps > 0
        do
            remainingSteps = remainingSteps - 1
            nextStep = nextStep + 1 / codeExecutorStepsPerSecond
            if codeExecutorRunToStep and not codeExecutorSetStep then
                if codeExecutorRunToStep > currentStep + 1 then
                    currentStep = math.max(currentStep + 1, codeExecutorRunToStep - codeExecutorRunToStepWarpRange)
                    
                elseif codeExecutorRunToStep < currentStep - 1 then
                    currentStep = math.min(currentStep - 1, codeExecutorRunToStep + codeExecutorRunToStepWarpRange)
                else
                    currentStep = codeExecutorRunToStep
                    codeExecutorRunToStep = nil
                end
            else
                currentStep = currentStep + 1
            end
            if codeExecutorSetStep then
                currentStep = math.min(codeExecutorSetStep, totalLineExec)
                codeExecutorSetStep = nil
            end
            currentStackInfo = getInfosAt(currentStep)
            currentLine = currentStackInfo.line
            if codeExecutorRunToLine and currentLine == codeExecutorRunToLine then
                codeExecutorRunToLine = nil
            end
        end
        if remainingSteps == 0 then
            nextStep = time + 1 / codeExecutorStepsPerSecond
        end
        if stackInfoHandler then
            stackInfoHandler(step, currentStackInfo)
        end
        local dt = GetFrameTime()
        currentLineShown = moveValueTo(currentLineShown, codeExecutorShowLine or currentLine, maxScrollSpeed, dt)
        local shownLineY = math.abs(fontsize) * (currentLineShown - 1)
        local offsetY = math.max(0, math.min(shownLineY - 4 * math.abs(fontsize), codeHeight - h + 8))
        if codeExecutorAlpha == 0 then
            return
        end
        SetColorAlpha(codeExecutorAlpha)
        SetColor(240,230,200,255)
        DrawRectangle(x, y, w, h)
        local currentLineY = 8 + math.abs(fontsize) * (currentLine - 1) - offsetY
        BeginScissorMode(x, y, w, h)
        SetColor(255,190,90,255)
        DrawRectangle(x, currentLineY, w, math.abs(fontsize))
        --print(currentLineY)
        
        SetColor(0,0,0,255)
        DrawTextBoxAligned(highlightedText, fontsize, x+8, math.floor(y+8 - offsetY), w-16, h-16, 0, 0)
        SetColor(220,200,130,255)
        local stackWindowWidth = 250
        local stackWindowX = x + w - stackWindowWidth
        DrawRectangle(stackWindowX, y, stackWindowWidth, h)
        SetColor(0,0,0,255)
        DrawTextBoxAligned("Stack", 20, stackWindowX + 10, y + 5, stackWindowWidth - 20, 30, 0, 0)
        local stackY = y + 30
        local function stringify(value)
            local asString
            if type(value) == "table" then
                asString = "{ "
                local count = 0
                local isInteger = true
                for k,v in pairs(value) do
                    count = count + 1
                end
                if count == 0 then return "{}" end
                isInteger = count == #value
                if isInteger then
                    for i=1,math.min(count, 3) do
                        asString = asString .. stringify(value[i]) .. ", "
                    end
                    if count > 3 then
                        asString = asString .. "...}"
                    else
                        asString = asString:sub(1, -3) .. " }"
                    end
                else
                    local n = 2
                    for k,v in pairs(value) do
                        asString = asString .. stringify(k) .. " = " .. stringify(v) .. ", "
                        n = n - 1
                        count = count - 1
                        if n <= 0 then
                            break
                        end
                    end
                    if count > 0 then
                        asString = asString .. "...}"
                    else
                        asString = asString:sub(1, -3) .. " }"
                    end
                end
            else
                asString = tostring(value)
            end
            return asString
        end
        local variables = {}
        for i=1,#currentStackInfo do
            SetColor(64,64,64,255)
            DrawRectangle(stackWindowX, stackY - 5, stackWindowWidth, 22)
            local info = currentStackInfo[i]
            local func = info.func
            local locals = info.locals
            SetColor(255,255,255,255)
            DrawTextBoxAligned(("%d: %s"):format(#currentStackInfo - i, func.name or "Main"), 15, stackWindowX + 10, stackY, stackWindowWidth - 20, 20, 0, 0)
            stackY = stackY + 20
            for j=1,#locals do
                local localInfo = locals[j]
                SetColor(0,0,0,255)
                DrawTextBoxAligned(localInfo.name, 15, stackWindowX + 10, stackY, stackWindowWidth - 20, 20, 0, 0)
                SetColor(0,0,0,255)
                local asString = stringify(localInfo.value)
                if #asString > 30 then
                    asString = asString:sub(1, 30) .. "..."
                end
                if not variables[localInfo.name] then
                    variables[localInfo.name] = asString
                end
                DrawTextBoxAligned(asString, 15, stackWindowX + 10, stackY, stackWindowWidth - 20, 20, 1, 0)
                stackY = stackY + 20
            end
        end

        if codeExecutorDisplayValueOverlay then
            for i, word in ipairs(wordsByLine[currentLine]) do
                local value = variables[word.word]
                if value then
                    local wordX = x + 24 + word.pos * 9
                    local wordY = math.floor(y + 8 + math.abs(fontsize) * (currentLine - 1) - offsetY - 22)
                    local wordWidth = #word.word * 9
                    local wordHeight = math.abs(fontsize)
                    SetColor(0,0,0,255)
                    DrawRectangle(wordX-1, wordY-1, wordWidth+2, wordHeight+2)
                    DrawTriangle(
                        wordX + wordWidth / 2 + 8, wordY + wordHeight, 
                        wordX + wordWidth / 2 - 8, wordY + wordHeight, 
                        wordX + wordWidth / 2, wordY + wordHeight + 8)
                    SetColor(255,255,255,255)
                    DrawRectangle(wordX, wordY, wordWidth, wordHeight)
                    SetColor(0,0,0,255)
                    DrawTextBoxAligned(value, 15, wordX, math.floor(wordY+1), wordWidth, wordHeight, 0.5, 0.5)
                end
            end
            -- print(table.unpack(wordsByLine[currentLine]))
        end
        
        EndScissorMode()
        -- draw progress bar
        SetColor(128,128,200,255)
        local progressBarWidth = w - stackWindowWidth
        local progressBarHeight = 8
        DrawRectangle(x, y + h, progressBarWidth, progressBarHeight)
        SetColor(255,190,90,255)
        local progress = currentStep / totalLineExec
        -- print(progress, currentStep, #)
        DrawRectangle(x+2, y + h + 2, (progressBarWidth - 4) * progress, progressBarHeight - 4)
        SetColorAlpha(255)
    end
end

local function detachedBubble(text, x, y, w, h, fontsize, linespacing)
    w = w or 400
    fontsize = fontsize or 20
    linespacing = linespacing or 1
    local lineHeight = math.floor(math.abs(fontsize) * linespacing + .5)
    if not h then
        h = 40
        for line in text:gmatch("[^\r\n]*") do
            h = h + lineHeight
        end
    end
    text = trim(text)
    x = x or math.floor((GetScreenSize() - w) / 2)
    y = y or 15
    return function()
        local posX = math.floor(guyPos.x - x)
        posX = math.max(16, math.min(w - 16, posX))

        SetColor(255,255,255,255)
        DrawBubble(x,y, w, h, 270, posX, h + 16)
        SetColor(0,0,32,255)
        SetLineSpacing(lineHeight - math.abs(fontsize))
        DrawTextBoxAligned(text, fontsize, x, y, w, h, 0.5, 0.5, lineHeight)
        SetLineSpacing(0)
    end
end

local function speechBubblePointAt(text, x, y, w, h, arrowAngle, arrowX, arrowY, fontsize)
    w = w or 300
    fontsize = fontsize or 20
    if not h then
        h = 40
        for line in text:gmatch("[^\r\n]*") do
            h = h + fontsize
        end
    end
    text = trim(text)
    return function() 
        x,y = math.floor(x), math.floor(y)
        arrowX = math.floor(arrowX)
        SetColor(255,255,255,255)
        DrawBubble(x,y, w, h, arrowAngle, arrowX, arrowY)
        SetColor(0,0,32,255)
        DrawTextBoxAligned(text, fontsize, x, y, w, h, 0.5, 0.5)
    end
end

local function speechBubble(text, w, h, fontsize)
    w = w or 300
    fontsize = fontsize or 20
    if not h then
        h = 40
        for line in text:gmatch("[^\r\n]*") do
            h = h + fontsize
        end
    end
    text = trim(text)
    return function() 
        local x, y = guyPos.x - w - 40, math.max(5, guyPos.y - h - 20)
        local arrowX = w + 16
        local arrowAngle = 180
        if x < 0 then
            x = guyPos.x + 40
            arrowX = -32
            arrowAngle = 0
        end
        x,y = math.floor(x), math.floor(y)
        arrowX = math.floor(arrowX)
        local arrowY = math.floor(guyPos.y - y - 40)
        SetColor(255,255,255,255)
        DrawBubble(x,y, w, h, arrowAngle, arrowX, arrowY)
        SetColor(0,0,32,255)
        DrawTextBoxAligned(text, fontsize, x, y, w, h, 0.5, 0.5)
    end
end

local function drawAnimatedSprite(srcX, srcY, srcW, srcH, 
    dstX, dstY, scaleX, scaleY, pivotX, pivotY, frames, fps)
    return function(self)
        local time = self.activeTime
        local frame = math.floor(time * fps) % frames
        SetColor(255,255,255,255)
        local srcX = eval(srcX, time)
        local srcY = eval(srcY, time)
        local srcW = eval(srcW, time)
        local srcH = eval(srcH, time)
        local dstX = eval(dstX, time)
        local dstY = eval(dstY, time)
        local scaleX = eval(scaleX, time)
        local scaleY = eval(scaleY, time)
        local dstW = eval(scaleX, time) * srcW * 2
        local dstH = eval(scaleY, time) * srcH * 2
        -- compensate for the pivot
        dstX = dstX - pivotX * scaleX * 2
        dstY = dstY - pivotY * scaleY * 2
        Sprite(srcX + frame * srcW, srcY, srcW, srcH, dstX, dstY, dstW, dstH)
    end
end

local function lerp(start, finish, t)
    return start + (finish - start) * t
end

local function elasticOut(t)
    return 2 ^ (-10 * t) * math.sin((t * 10 - 0.75) * (2 * math.pi) / 3) + 1
end

local function easeOutElasticTween(start, finish, duration)
    return function(t)
        t = math.min(1, t / duration)
        local p = 2 ^ (-10 * t) * math.sin((t * 10 - 0.75) * (2 * math.pi) / 3) + 1
        return start + (finish - start) * p
    end
end

local function easeOutSineTween(start, finish, duration)
    return function(t)
        t = math.min(1, t / duration)
        return lerp(start, finish, math.sin(t * math.pi / 2))
    end
end

local function bounceTween(start, bounceMax, duration)
    return function(t)
        t = math.min(1, t / duration)
        local p = math.sin(t * math.pi)
        return lerp(start, bounceMax,  p)
    end
end

local function delayTween(duration, f)
    return function(t)
        return f(t - duration)
    end
end
local function drawArrowLine(startX, startY, endX, endY, tween, r,g,b,a)
    return function(self)
        local time = self.activeTime
        local tween = eval(tween, time)
        if tween < 0 then
            return
        end
        local startX = eval(startX, time)
        local startY = eval(startY, time)
        local endX = eval(endX, time)
        local endY = eval(endY, time)
        local x = lerp(startX, endX, tween)
        local y = lerp(startY, endY, tween)
        local dx, dy = endX - startX, endY - startY
        local len = math.sqrt(dx * dx + dy * dy)
        local nx, ny = dx / len, dy / len
        local rx, ry = -ny, nx
        local aw = 8
        local ah = 16
        SetColor(0,0,0,a)
        DrawLine(startX, startY, x, y, 9)
        DrawTriangle(
            x + rx * (aw + 4) - nx * 2, 
            y + ry * (aw + 4) - ny * 2, 
            x + nx * (ah + 4),
            y + ny * (ah + 4), 
            x - rx * (aw + 4) - nx * 2, 
            y - ry * (aw + 4) - ny * 2)

        SetColor(r,g,b,a)
        DrawLine(startX, startY, x, y, 5)
        DrawTriangle(x + rx * aw, y + ry * aw, x + nx * ah, y + ny * ah, x - rx * aw, y - ry * aw)
    end
end

local function moveGuyTo(x, y)
    return function(self)
        -- warp the guy to the target to avoid clipping
        -- would be cool to have a warp effect if it's needed
        local dx, dy = guyPos.x - x, guyPos.y - y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist > 20 then
            guyPos.x = guyTarget.x
            guyPos.y = guyTarget.y
        end
        guyTarget.x = x
        guyTarget.y = y
    end
end

local function drawMapInfoSquares(minX, minY, maxX, maxY)
    return function (step)
        for x = minX, maxX - 1 do 
            for y = minY, maxY - 1 do 
                local tileId = map:getValue(x + 1, y + 1)
                if tileId < 3 or tileId == 5 then
                    SetColor(128,0,0,128)
                    local px = x * 32 + 16
                    local py = y * 32 + 16
                    local tOffset = x + y
                    local t = math.min(step.activeTime * 2 - tOffset * .1, 1)
                    if t > 0 then
                        t = elasticOut(t)
                        local s = 32 * t
                        DrawRectangle(px + 16 - s * .5, py + 16 - s * .5, s, s)
                    end
                end
            end
        end
    end
end

local function drawGrid(minX, minY, maxX, maxY)
    return function(step)
        
        SetColor(0,0,0,128)
        local centerX = 32 * (maxX - minX) * .5 + 16
        local centerY = 32 * (maxY - minY) * .5 + 16
        for x=minX, maxX do
            local px = x * 32 + 16
            local offset = math.abs((px - centerX) * .0025)
            local t = math.min(1, (step.activeTime - offset) * .25)
            if t > 0 then
                t = elasticOut(t);
                local lineLenH = 32 * (maxY - minX) * t
                DrawRectangle(px, centerY - lineLenH * .5, 1, lineLenH)
            end
        end
        for y=minY, maxY do
            local py = y * 32 + 16
            local offset = math.abs((py - centerY)) * .0025
            local t = math.min(1,(step.activeTime - offset) * .25)
            if t > 0 then
                t = elasticOut(t)
                local lineLenW = 32 * (maxX - minX) * t
                DrawRectangle(centerX - lineLenW * .5, py, lineLenW, 1)
            end
        end
    end
end

local steps = {
    {
        chapter = "Introduction",
        step = 0,
        draw = speechBubble([[
            Hello World!
            This is a walk through different path finding 
            topics from beginner level to fairly advanced
            topics.
            Press <ENTER> to get to the next step and
            <BACKSPACE> to go back a step.

            You can also open a menu by pressing
            <SPACE> to see a list of all chapters.

            Alternatively you can use the mouse or touch
            input on the bottom elements.
            ]], 355)
    },
    {
        step = {0, 2},
        draw = moveGuyTo(400, 100)
    },
    {
        step = 1,
        draw = speechBubble([[
            By the way, the code for this 
            application is open source and 
            contains not only path finding 
            algorithms but also covers tile 
            rendering using auto-tiling and 
            Lua scripting bindings.]])
    },
    {
        step = 2,
        draw = speechBubble [[
                You can go back to a previous step
                any time by pressing BACKSPACE.]]
    },
    {
        chapter = "Path Finding Basics",
        step = 0,
        draw = speechBubble([[
                Chapter 1:
                Path finding basics]], 250, 100, 30)
    },
    {
        step = 1,
        draw = speechBubble([[
            Let's say I want to move to the flag
            down there ...]])
    },
    {
        step = 2,
        draw = speechBubble([[
            ... then this isn't a problem.]])
    },
    {
        step = 3,
        draw = detachedBubble([[
            In this situation however it isn't as simple:
            The plateau is blocking my path.
            
            This is where path finding comes in: I need 
            an algorithm to find a way around the plateau,
            telling me, which directions I need to take.
            
            We will start with simple approaches and work
            through to more advanced algorithms.]])
    },
    {
        step = {4,5},
        draw = drawGrid(0,0,24,13)
    },
    {
        step = 5,
        draw = drawMapInfoSquares(0,0,24,13)
    },
    {
        step = 4,
        draw = detachedBubble [[
            Before we start, we have to describe what we see
            in a way that the computer can understand.

            For that purpose, we'll use a simple grid of squares.
        ]]
    },
    {
        step = 5,
        draw = detachedBubble[[
            Now we mark the squares that I can't walk on.
            This way, we have something the computer 
            can work with.
        ]]
    },
    {
        step = {0, 1},
        activate = moveGuyTo(400, 100)
    },
    {
        step = {2, 5},
        activate = moveGuyTo(512, 298)
    },
    {
        step = {1, 2},
        draw = drawArrowLine(
            function() return guyPos.x end,
            function() return guyPos.y end,
            500, 300, delayTween(.5, easeOutSineTween(0, .8, .5)), 255,128,0,255
        )
    },
    {
        step = 3,
        draw = drawArrowLine(
            function() return guyPos.x end,
            function() return guyPos.y end,
            200, 290, delayTween(.5, easeOutSineTween(0, .8, .5)), 255,128,0,255
        )
    },
    {
        step = {1,2},
        draw = drawAnimatedSprite(0, 432, 16, 16, 
            500, bounceTween(300,280,.25), 1, easeOutElasticTween(0, 1, 1.5), 8, 16, 4, 10)
    },
    {
        step = {3,5},
        draw = drawAnimatedSprite(0, 432, 16, 16, 
            192, bounceTween(300,280,.25), 1, easeOutElasticTween(0, 1, 1.5), 8, 16, 4, 10)
    },

    -----------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------

    {
        chapter = "Depth First Search",
        step = {0,26},
        draw = drawGrid(0,0,24,13)
    },
    {
        step = {0,26},
        draw = drawMapInfoSquares(0,0,24,13)
    },
    {
        step = 0,
        draw = detachedBubble([[
                Chapter 2:
                Depth First Search]], nil, nil, nil, nil, 30)
    },
    {
        step = 1,
        draw = detachedBubble[[
            Depth First Search can be implemented
            with a fairly simple recursive algorithm.

            This chapter will explain with lots of detail
            how program execution works. If you
            are familar with programming, you can 
            skip this chapter.
        ]]
    },
    {
        step = {0, 26},
        activate = moveGuyTo(512, 298)
    },
    {
        step = {0,26},
        draw = drawAnimatedSprite(0, 432, 16, 16, 
            192, bounceTween(300,280,.25), 1, easeOutElasticTween(0, 1, 1.5), 8, 16, 4, 10)
    },
    {
        step = {2,26},
        draw = codeExecutor("Depth First", [[
            function visit(x, y, visited)
              if x < 0 or x >= width or y < 0 or y >= height then
                return
              end
              local index = x + y * width
              if visited[index] or blocked[index] then
                return
              end
              visited[index] = true
              visit(x - 1, y, visited)
              visit(x + 1, y, visited)
              visit(x, y + 1, visited)
              visit(x, y - 1, visited)
            end
            visit(16, 9, {})]], 0, 0, GetScreenSize(), nil, -20,
            {
                blocked = getBlockedMap(map),
                width = mapWidth,
                height = mapHeight
            },
            function(step, stackinfo)
                local prevX, prevY
                local visited
                for i=1,#stackinfo do
                    local info = stackinfo[i]
                    local currentX, currentY
                    for j=1, #info.locals do
                        local localInfo = info.locals[j]
                        if localInfo.name == "x" then
                            currentX = localInfo.value
                        elseif localInfo.name == "y" then
                            currentY = localInfo.value
                        elseif localInfo.name == "visited" then
                            visited = localInfo.value
                        end
                    end
                    if currentX and currentY then
                        local cx, cy = currentX * 32, currentY * 32
                        
                        if prevX and prevY then
                            local px, py = prevX * 32, prevY * 32
                            SetColor(0,0,0,255)
                            DrawLine(px, py, cx, cy, 5)
                        end
                        SetColor(255,0,0,255)
                        DrawRectangle(cx - 4, cy - 4, 8, 8)
                        prevX, prevY = currentX, currentY
                    end
                end
                if visited then
                    for y=0,mapHeight - 1 do
                        for x=0,mapWidth - 1 do
                            local index = x + y * mapWidth
                            if visited[index] then
                                SetColor(100,0,200,128)
                                DrawRectangle(x * 32 - 16, y * 32 - 16, 32, 32)
                            end
                        end
                    end
                end
            end)
    },
    {
        step = {0, 1},
        activate = function() 
            codeExecutorSetStep = 0
            codeExecutorRunToStep = nil
            codeExecutorShowLine = 1
        end,
    },
    {
        step = 2,
        activate = function() 
            codeExecutorSetStep = 0
            codeExecutorShowLine = 1
            codeExecutorRunToStep = nil
        end,
        draw = speechBubblePointAt([[
            For the purpose of this demonstration, we
            use [color=008f]Lua[/color] as a scripting language. This way
            we can show the algorithm in action.

            We start out with a function called [color=808f]visit[/color].
            But this is only the function declaration.]], 400, 0, 330, nil, 0, -16, 20)
    },
    {
        step = 3,
        activate = function() 
            codeExecutorSetStep = 0
            codeExecutorShowLine = 15
            codeExecutorRunToStep = nil
        end,
        draw = speechBubblePointAt([[
            The actual execution begins down here.]], 200, 170, 330, nil, 0, -16, 20)
    },
    {
        step = 4,
        activate = function() 
            codeExecutorShowLine = 15 
            codeExecutorSetStep = 3
            codeExecutorRunToStep = nil
        end,
        draw = speechBubblePointAt([[
            Let's start the program execution!]], 200, 170, 330, nil, 0, -16, 20)
    },
    {
        step = 5,
        activate = function() 
            codeExecutorShowLine = nil 
            codeExecutorSetStep = 3
            codeExecutorRunToStep = nil
        end,
        draw = speechBubblePointAt([[
            On the right we see the current stack - 
            as our program has only just begun, 
            there's not much to see.]], 200, 70, 330, nil, 180, 350, 20)
    },
    {
        step = 6,
        activate = function() 
            codeExecutorShowLine = 1 
            codeExecutorSetStep = 4
            codeExecutorRunToStep = nil
        end,
        draw = speechBubblePointAt([[
            Let's move one step in our program.
            Now we can see some local variables. 
            Currently it's just the first call, 
            so we see only the function's arguments: 
            [color=800f]x[/color], [color=800f]y[/color] and the array called [color=800f]visited[/color] that 
            stores the visited cells - right now, it's 
            empty. ]], 200, 70, 330, nil, 180, 350, 20)
    },
    {
        step = 7,
        activate = function() 
            codeExecutorShowLine = 1 
            codeExecutorSetStep = 4
            codeExecutorRunToStep = nil
        end,
        draw = speechBubblePointAt([[
            In the currently executed line, the program
            checks if x or y is outside our map's area
            and if it is not, we return.]], 100, 70, 330, nil, 90, 150, -20)
    },
    {
        step = 7,
        draw = speechBubblePointAt([[
            For convenience, we draw the current x 
            and y position on the map - it starts at
            my position - of course!]], 130, 270, 330, nil, 180, 360, 20)
    },
    {
        step = 8,
        activate = function() 
            codeExecutorShowLine = 1 
            codeExecutorRunToStep = 6
        end,
        draw = speechBubblePointAt([[
            We skipped to this line - we used [color=800f]x[/color] and [color=800f]y[/color]
            to calculate the [color=800f]index[/color]. This is a number
            we use as an adress. The [color=800f]visited[/color] and 
            [color=800f]blocked[/color] variables ([color=800f]blocked[/color] is a 
            global value, same as [color=800f]width[/color] and [color=800f]height[/color]).
            Currently, the [color=800f]visited[/color] table is empty and 
            the field isn't blocked either, so this 
            evaluates to [color=888f]false[/color].]], 100, 170, 330, nil, 90, 150, -20)
    },
    {
        step = 9,
        activate = function() 
            codeExecutorShowLine = 4 
            codeExecutorRunToStep = 7
        end,
        draw = speechBubblePointAt([[
            We haven't exited the function's call, so we 
            found a cell we can visit! Let's mark the 
            cell as visited, so we know we don't have 
            to look at it again.]], 100, 150, 330, nil, 90, 120, -24)
    },
    {
        step = 10,
        activate = function() 
            codeExecutorShowLine = 4 
            codeExecutorRunToStep = 8
        end,
        draw = speechBubblePointAt([[
            Note how the [color=800f]visited[/color] table has now 
            an entry.]], 450, 130, 330, nil, 90, 300, -24)
    },
    {
        step = 10,
        draw = speechBubblePointAt([[
            To help understand the content of the [color=800f]visited[/color] table, 
            we draw it's content as purple colored rectangles 
            in the map.]], 
            400, 320, 400, nil, 90, 110, -24)
    },
    {
        step = 11,
        activate = function() 
            codeExecutorShowLine = 4 
            codeExecutorSetStep = 8
        end,
        draw = speechBubblePointAt([[
            The code is now about to call the [color=a00f]visit[/color] 
            function from within the [color=a00f]visit[/color] funtion.
            This is called "recursion". However, we will 
            change the position to look at to the left, by 
            subtracting 1 from [color=800f]x[/color].]], 100, 170, 350, nil, 90, 30, -24)
    },
    {
        step = {12,14},
        activate = function() 
            codeExecutorShowLine = 1 
            codeExecutorSetStep = 9
        end,
        draw = speechBubblePointAt([[
            Look, many things have changed 
            now: the program jumped up ...]], 30, 70, 280, nil, 90, 30, -24)
    },
    {
        step = {13,14},
        draw = speechBubblePointAt([[
            ... and a new stack 
            entry appeared. The
            [color=800f]x[/color] value changed
            from 16 to 15.]], 330, 12, 180, nil, 180, 210, 24)
    },
    {
        step = 14,
        draw = speechBubblePointAt([[
            Our new coordinate in the program
            is now here. We draw the a black 
            line from the place we came from
            to the new position.]], 180, 265, 270, nil, 180, 290, 24)
    },
    {
        step = 15,
        activate = function() 
            codeExecutorShowLine = 5 
            codeExecutorRunToStep = 13
        end,
        draw = speechBubblePointAt([[
            After proceeding a little, the
            [color=800f]visited[/color] array is flagged and we
            will recurse again with another
            step to the left ...]], 140, 265, 270, nil, 180, 290, 24)
    },
    {
        step = 16,
        activate = function() 
            codeExecutorShowLine = 1
            codeExecutorSetStep = 14
        end,
        draw = speechBubblePointAt([[
            After proceeding a little, the
            [color=800f]visited[/color] array is flagged and we
            will recurse again with another
            step to the left ...]], 140, 265, 270, nil, 180, 290, 24)
    },
    {
        step = 17,
        activate = function() 
            codeExecutorShowLine = 1
            codeExecutorRunToStep = 17
        end,
        draw = speechBubblePointAt([[
            Since the field is blocked,the 
            recursive call will end here and we 
            will return to the source of the call.]], 140, 265, 270, nil, 180, 290, 24)
    },
    {
        step = 18,
        activate = function() 
            codeExecutorShowLine = 4
            codeExecutorRunToStep = 18
        end,
        draw = speechBubblePointAt([[
            After returning, the code proceeds
            to the next cell to check, which is
            to the right - which we have
            flagged already as visited...]], 180, 265, 270, nil, 180, 290, 24)
    },
    {
        step = 19,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorRunToStep = 23
            codeExecutorRunToStepWarpRange = codeExecutorRunToStepWarpRangeDefault
            codeExecutorStepsPerSecond = codeExecutorStepsPerSecondDefault
        end,
        draw = speechBubblePointAt([[
            This recursion did therefore return
            quickly and we will now go down]], 180, 265, 270, nil, 180, 290, 24)
    },
    {
        step = 20,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorRunToStep = 205
            codeExecutorRunToStepWarpRange = 500
            codeExecutorStepsPerSecond = 50
        end,
        draw = speechBubblePointAt([[
            We will now speed up the execution
            for a while.]], 20, 265, 270, nil, -1, 290, 24)
    },
    {
        step = 21,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorSetStep = 205
            codeExecutorRunToStepWarpRange = codeExecutorRunToStepWarpRangeDefault
            codeExecutorStepsPerSecond = codeExecutorStepsPerSecondDefault
        end,
        draw = speechBubblePointAt([[
            We have hit now the first real
            dead end! Watch how it will 
            now backtrack! ]], 20, 265, 270, nil, -1, 290, 24)
    },
    {
        step = 22,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorRunToStepWarpRange = 500
            codeExecutorSetStep = 205
            codeExecutorRunToStep = 365
            codeExecutorStepsPerSecond = 10
        end,
        draw = speechBubblePointAt([[
            As you can see, it will faithfully,
            track back and until it finds an
            unexplored region.]], 20, 265, 270, nil, -1, 290, 24)
    },
    {
        step = {23,24},
        activate = function()
            codeExecutorShowLine = nil
            codeExecutorSetStep = 1510
            codeExecutorStepsPerSecond = 10
            codeExecutorRunToStep = nil
            codeExecutorAlpha = 255
            codeExecutorRunning = false
        end,
        draw = speechBubblePointAt([[
            Let's jump forward to our flag!]], 20, 330, 270, nil, 90, 170, -24)
    },
    {
        step = 24,
        draw = speechBubblePointAt([[
            The code doesn't handle this case, 
            so it would just go on. 
            However, we the code doesn't handle
            the case of finding the flag.]], 320, 250, 330, nil, -1, 170, -24)
    },
    {
        step = 25,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorSetStep = 1510
            codeExecutorStepsPerSecond = 150
            codeExecutorRunToStep = nil
            codeExecutorRunning = true
            codeExecutorAlpha = 128
        end,
        draw = speechBubblePointAt([[
            So the program will run until every
            part of the map has been explored.]], 320, 250, 330, nil, -1, 170, -24)
    },
    {
        step = 26,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorSetStep = 5000
            codeExecutorRunToStep = nil
            codeExecutorRunning = false
            codeExecutorAlpha = 255
        end,
        draw = speechBubblePointAt([[
            But the path obtained through this
            algorithm would not have been useful 
            anyway.
            It is however a simple algorithm that
            can be used to find out if a connection
            between two points exists.
            ]], 120, 250, 330, nil, 180, 360, 28)
    },
    -----------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------

    {
        chapter = "Breadth search",
        step = {0,21},
        draw = drawGrid(0,0,24,13)
    },
    
    {
        step = {0, 21},
        activate = moveGuyTo(512, 298)
    },
    {
        step = {0,21},
        draw = drawAnimatedSprite(0, 432, 16, 16, 
            192, bounceTween(300,280,.25), 1, easeOutElasticTween(0, 1, 1.5), 8, 16, 4, 10)
    },
    {
        step = 0,
        draw = detachedBubble([[
                Chapter 3:
                Breadth First Search]], nil, nil, nil, nil, 30)
    },
    {
        step = 1,
        draw = detachedBubble[[
            Breadth First Search works differently than 
            Depth First Search. It maintains a queue of
            cells to visit and processes them in order
            of encountering them.
        ]]
    },
    {
        step = {2,20},
        draw = codeExecutor("Breadth First", [[
            local queue = {}
            local visited = {}
            local adjacents = {{1,0},{-1,0},{0,1},{0,-1}}
            local startX, startY = 16, 9
            local endX, endY = 6, 9
            queue[#queue + 1] = {startX, startY}
            visited[startX + startY * width] = {startX, startY}
            while #queue > 0 do
              local current = table.remove(queue, 1)
              local x, y = current[1], current[2]
              if x == endX and y == endY then
                break
              end
              for _, dir in ipairs(adjacents) do
                local nextX, nextY = x + dir[1], y + dir[2]
                if nextX >= 0 and nextX < width and 
                    nextY >= 0 and nextY < height 
                then
                  local index = nextX + nextY * width
                  if not visited[index] and not blocked[index] then
                    queue[#queue + 1] = {nextX, nextY}
                    -- store the source we came from in the visited table
                    visited[index] = current
                  end
                end
              end
            end
            local path
            if visited[endX + endY * width] then
              path = {}
              local current = endX + endY * width
              while current do
                path[#path + 1] = current
                if current == startX + width * startY then
                  break
                end
                local from = visited[current]
                current = from[1] + from[2] * width
              end
            end
            ]], 0, 0, GetScreenSize(), nil, -20,
            {
                blocked = getBlockedMap(map),
                width = mapWidth,
                height = mapHeight,
                table = table,
                ipairs = ipairs
            },
            function(step, stackinfo)
                local stackScope = {}
                for i=#stackinfo,1,-1 do
                    local info = stackinfo[i]
                    for j=1,#info.locals do
                        local localInfo = info.locals[j]
                        stackScope[localInfo.name] = localInfo.value
                    end
                end
                local visited = stackScope.visited or {}
                local queue = stackScope.queue or {}
                local x,y = stackScope.x, stackScope.y
                local nextX, nextY = stackScope.nextX, stackScope.nextY
                local endX, endY = stackScope.endX, stackScope.endY
                -- if endX and endY then
                --     local cx, cy = endX * 32, endY * 32
                --     SetColor(255,0,0,255)
                --     DrawRectangle(cx - 10, cy - 10, 20, 20)
                -- end
                SetColor(255,255,255,255)
                local path = stackScope.path or {}
                local pathmap = {}
                for i=1,#path do
                    pathmap[path[i]] = true
                end
                for i,v in pairs(visited) do
                    local from = visited[i]
                    local fromX, fromY = from[1], from[2]
                    local cellX = i % mapWidth
                    local cellY = math.floor(i / mapWidth)
                    if fromX ~= cellX or fromY ~= cellY then
                        local cx, cy = (cellX + fromX) * 16, (cellY + fromY) * 16
                        local dx, dy = cellX - fromX, cellY - fromY
                        local spriteId = 2
                        if dx == 1 then
                            spriteId = 1
                        elseif dy == -1 then
                            spriteId = 0
                        elseif dx == -1 then
                            spriteId = 3
                        end
                        if pathmap[i] then
                            SetColor(255,100,0,255)
                        else
                            SetColor(255,255,255,255)
                        end
                        Sprite(spriteId * 16, 400, 16, 16, cx-8, cy-8, 16, 16)
                    end
                end
                for i=1,#queue do
                    local current = queue[i]
                    local cx, cy = current[1] * 32, current[2] * 32
                    SetColor(255,255,255,140)
                    DrawRectangle(cx - 10, cy - 10, 20, 20)
                    SetColor(128,0,255,140)
                    DrawRectangle(cx - 8, cy - 8, 16, 16)
                    SetColor(255,255,255,180)
                    DrawTextBoxAligned(tostring(i),15, cx - 16, cy - 14, 32, 32, 0.5, 0.5)
                end
                if x and y then
                    local cx, cy = x * 32, y * 32
                    SetColor(255,0,0,255)
                    DrawRectangle(cx - 4, cy - 4, 8, 8)
                end
                if nextX and nextY then
                    local cx, cy = nextX * 32, nextY * 32
                    SetColor(0,0,0,255)
                    DrawLine(cx, cy, x * 32, y * 32, 5)
                    SetColor(255,128,0,255)
                    DrawRectangle(cx - 4, cy - 4, 8, 8)
                end
            end)
    },
    {
        step = 2,
        activate = function() 
            codeExecutorSetStep = 0
            codeExecutorShowLine = 1
            codeExecutorRunToStepWarpRange = 500
            codeExecutorRunToStep = 1
            codeExecutorStepsPerSecond = 2
        end,
        draw = speechBubblePointAt([[
            This time we use a queue to store the cells
            we want to look at in the future.]], 400, 0, 330, nil, 0, -16, 20)
    },
    {
        step = 3,
        activate = function() 
            codeExecutorShowLine = 1
            codeExecutorSetStep = 2
        end,
        draw = speechBubblePointAt([[
            The visited table will now store the 
            coordinate of the cell we came from.]], 400, 18, 330, nil, 0, -16, 20)
    },
    {
        step = 4,
        activate = function() 
            codeExecutorShowLine = 1
            codeExecutorSetStep = 3
        end,
        draw = speechBubblePointAt([[
            The adjacents is a helper table that
            provides a list coordinates for 
            neighboring cells that we want
            to enqueue.]], 480, 36, 300, nil, 0, -16, 20)
    },
    {
        step = {5,6},
        activate = function() 
            codeExecutorShowLine = 1
            codeExecutorSetStep = 7
        end,
        draw = speechBubblePointAt([[
            We initialize the queue and visit
            table with starting point.]], 480, 110, 300, nil, 0, -16, 20)
    },
    {
        step = 6,
        activate = function() 
            codeExecutorShowLine = 1
            codeExecutorSetStep = 7
        end,
        draw = speechBubblePointAt([[
            The content of the queue is visualized
            with these purple rectangles. The
            number is the position in the queue.]], 480, 316, 300, nil, 90, 32, -20)
    },
    {
        step = 7,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorSetStep = 7
            codeExecutorRunToStep = 11
        end,
        draw = speechBubblePointAt([[
            Our loop is now going to run as long
            as there are elements in the queue.
            The coordinate of the dequeued point
            that we dequeued is this red rectangle.]], 480, 316, 300, nil, 90, 32, -20)
    },
    {
        step = 8,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorSetStep = 11
            codeExecutorRunToStep = 14
        end,
        draw = speechBubblePointAt([[
            Iterating over the list of coordinates
            in our adjacents table, we first look 
            at the position to the right ...]], 480, 316, 300, nil, 90, 64, -20)
    },
    {
        step = 9,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorSetStep = 14
            codeExecutorRunToStep = 19
        end,
        draw = speechBubblePointAt([[
            Since the position is neither blocked
            or visited, it is queued.]], 480, 316, 300, nil, 90, 64, -20)
    },
    {
        step = 10,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorSetStep = 19
            codeExecutorRunToStep = 20
        end,
        draw = speechBubblePointAt([[
            This finished the first loop over the
            adjacents table and the visited table
            contains now the first entry that
            points to the starting position.]], 480, 316, 300, nil, 90, 48, -20)
    },
    {
        step = 11,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorRunToStepWarpRange = 50
            codeExecutorSetStep = 20
            codeExecutorRunToStep = 46
            codeExecutorStepsPerSecond = 5
        end,
        draw = speechBubblePointAt([[
            After we finished the first loop, each
            valid neighbor of the starting position
            is queued.
            ]], 80, 280, 300, nil, -1, 48, -20)
    },
    {
        step = 12,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorRunToStepWarpRange = 50
            codeExecutorSetStep = 46
            codeExecutorRunToStep = 46
            codeExecutorStepsPerSecond = 5
        end,
        draw = speechBubblePointAt([[
            We will dequeue now the first element
            from the queue and repeat the same 
            process.]], 80, 280, 300, nil, -1, 48, -20)
    },
    {
        step = 13,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorRunToStepWarpRange = 50
            codeExecutorSetStep = 46
            codeExecutorRunToStep = 79
            codeExecutorStepsPerSecond = 5
        end,
        draw = speechBubblePointAt([[
            After having finished the second loop
            iteration, we have now two more 
            elements in the queue at the end of it. 
            There are still 3 more entries from 
            the starting position that are looked
            at first.]], 80, 230, 300, nil, -1, 48, -20)
    },
    {
        step = 14,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorRunToStepWarpRange = 50
            codeExecutorSetStep = 79
            codeExecutorRunToStep = 113
            codeExecutorStepsPerSecond = 5
        end,
        draw = speechBubblePointAt([[
            Just one more time, let's look how 
            this iteration looks like. ]], 80, 230, 300, nil, -1, 48, -20)
    },
    {
        step = {15, 16},
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorRunToStepWarpRange = 50
            codeExecutorSetStep = 344
            codeExecutorRunToStep = nil
            codeExecutorStepsPerSecond = 5
        end,
        draw = speechBubblePointAt([[
            Skipping now the next few steps, we
            can see where this is going: Like the
            depth first search, it explores the
            entire map - but it goes into breadth
            and not deep first. ]], 80, 230, 300, nil, -1, 48, -20)
    },
    {
        step = 16,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorRunToStepWarpRange = 50
            codeExecutorSetStep = 344
            codeExecutorRunToStep = nil
            codeExecutorStepsPerSecond = 5
            codeExecutorAlpha = 255
        end,
        draw = speechBubblePointAt([[
            The arrows tell us which
            way we came to each tile.
            Once we find the flag, we
            can find the way back to
            the starting point.]], 590, 230, 210, nil, -1, 48, -20)
    },
    {
        step = 17,
        activate = function() 
            codeExecutorAlpha = 100
            codeExecutorShowLine = nil
            codeExecutorRunToStepWarpRange = 5000
            codeExecutorSetStep = 344
            codeExecutorRunToStep = 4610
            codeExecutorStepsPerSecond = 250
        end,
        draw = speechBubblePointAt([[
            Since it's so fun to 
            watch, let's see where 
            this is going!]], 590, 230, 210, nil, -1, 48, -20)
    },
    {
        step = 18,
        activate = function() 
            codeExecutorAlpha = 255
            codeExecutorShowLine = nil
            codeExecutorRunToStepWarpRange = 5000
            codeExecutorSetStep = 4610
            codeExecutorRunToStep = 4610
            codeExecutorStepsPerSecond = 250
        end,
        draw = speechBubblePointAt([[
            Our loop has terminated.
            There are still elements in
            the queue, but we won't
            follow anymore where they 
            lead to.]], 560, 230, 240, nil, -1, 48, -20)
    },
    {
        step = 19,
        activate = function() 
            codeExecutorAlpha = 255
            codeExecutorShowLine = 35
            codeExecutorRunToStepWarpRange = 5000
            codeExecutorSetStep = 4610
            codeExecutorRunToStep = 4687
            codeExecutorStepsPerSecond = 4
        end,
        draw = speechBubblePointAt([[
            We construct now the path
            by going backwards, using
            the collected information.]], 560, 230, 240, nil, -1, 48, -20)
    },
    {
        step = 20,
        activate = function() 
            codeExecutorAlpha = 255
            codeExecutorShowLine = 35
            codeExecutorRunToStepWarpRange = 5000
            codeExecutorSetStep = 4687
            codeExecutorRunToStep = nil
            codeExecutorStepsPerSecond = 4
        end,
        draw = speechBubblePointAt([[
            This is now a path I could 
            take to get to the flag!
            
            The list of points in the 
            path is however in reversed
            order. We can fix that by 
            starting the search at the
            end point.]], 560, 230, 240, nil, -1, 48, -20)
    },
    {
        step = 21,
        activate = function() 
            codeExecutorAlpha = 0
            codeExecutorShowLine = 35
            codeExecutorRunToStepWarpRange = 5000
            codeExecutorSetStep = 4687
            codeExecutorRunToStep = nil
            codeExecutorStepsPerSecond = 4
        end,
        draw = speechBubblePointAt([[
            That concludes our breadth first search chapter.
            
            The next chapter covers the Dijkstra algorithm - because
            I really don't want to walk over sand if it can be avoided!]], 120, 30, 540, nil, -1, 48, -20)
    },

    -----------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------
    {
        chapter = "Dijkstra search",
        step = {0,20},
        activate = function()
            codeExecutorAlpha = 255
            codeExecutorShowLine = nil
            codeExecutorRunToStepWarpRange = codeExecutorRunToStepWarpRangeDefault
            codeExecutorSetStep = nil
            codeExecutorRunToStep = nil
            codeExecutorStepsPerSecond = codeExecutorStepsPerSecondDefault
        end,
        draw = drawGrid(0,0,24,13)
    },
    {
        step = {0, 20},
        activate = moveGuyTo(512, 298)
    },
    {
        step = {0,20},
        draw = drawAnimatedSprite(0, 432, 16, 16, 
            192, bounceTween(300,280,.25), 1, easeOutElasticTween(0, 1, 1.5), 8, 16, 4, 10)
    },
    {
        step = 0,
        draw = detachedBubble([[
                Chapter 4:
                Dijkstra's Algorithm]], nil, nil, nil, nil, 30)
    },
    {
        step = 1,
        draw = detachedBubble[[
            The Breadth First Search algorithm treats every
            cell the same. Dijkstra's Algorithm considers 
            the cost of moving from one cell to another.

            Since I would like to avoid walking over sand,
            if possible, it's a good choice to look into next.]]
    },
    {
        step = {2,16},
        draw = codeExecutor("Dijkstra-4",[[
            local queue = {}
            local visited = {}
            local adjacents = {{1,0},{-1,0},{0,1},{0,-1}}
            local startX, startY = 16, 9
            local endX, endY = 6, 9
            queue[#queue + 1] = {startX, startY, 0}
            visited[startX + startY * width] = {startX, startY, 0}
            while #queue > 0 do
              local lowestCost = queue[1][3]
              local lowestCostIndex = 1
              for i=2,#queue do
                if queue[i][3] < lowestCost then
                  lowestCost = queue[i][3]
                  lowestCostIndex = i
                end
              end
              local current = table.remove(queue, lowestCostIndex)
              local x, y, cost = current[1], current[2], current[3]
              if x == endX and y == endY then
                break
              end
              for _, dir in ipairs(adjacents) do
                local nextX, nextY = x + dir[1], y + dir[2]
                if nextX >= 0 and nextX < width and 
                    nextY >= 0 and nextY < height 
                then
                  local index = nextX + nextY * width
                  if not visited[index] and costMap[index] > 0 then
                    local newCost = cost + costMap[index]
                    queue[#queue + 1] = {nextX, nextY, newCost}
                    visited[index] = {x, y, newCost}
                  end
                end
              end
            end
            local path
            if visited[endX + endY * width] then
              path = {}
              local current = endX + endY * width
              while current do
                path[#path + 1] = current
                if current == startX + width * startY then
                  break
                end
                local from = visited[current]
                current = from[1] + from[2] * width
              end
            end
            ]], 0, 0, GetScreenSize(), nil, -20,
            {
                costMap = getBlockedMap(map, true),
                width = mapWidth,
                height = mapHeight,
                table = table,
                ipairs = ipairs
            },
            function(step, stackinfo)
                local stackScope = {}
                for i=#stackinfo,1,-1 do
                    local info = stackinfo[i]
                    for j=1,#info.locals do
                        local localInfo = info.locals[j]
                        stackScope[localInfo.name] = localInfo.value
                    end
                end
                local visited = stackScope.visited or {}
                local queue = stackScope.queue or {}
                local x,y = stackScope.x, stackScope.y
                local nextX, nextY = stackScope.nextX, stackScope.nextY
                local endX, endY = stackScope.endX, stackScope.endY
                -- if endX and endY then
                --     local cx, cy = endX * 32, endY * 32
                --     SetColor(255,0,0,255)
                --     DrawRectangle(cx - 10, cy - 10, 20, 20)
                -- end
                SetColor(255,255,255,255)
                local path = stackScope.path or {}
                local pathmap = {}
                for i=1,#path do
                    pathmap[path[i]] = true
                end
                for i,v in pairs(visited) do
                    local from = visited[i]
                    local fromX, fromY, cost = from[1], from[2], from[3]
                    local cellX = i % mapWidth
                    local cellY = math.floor(i / mapWidth)
                    if fromX ~= cellX or fromY ~= cellY then
                        local cx, cy = (cellX + fromX) * 16, (cellY + fromY) * 16
                        local dx, dy = cellX - fromX, cellY - fromY
                        local spriteId = 2
                        if dx == 1 then
                            spriteId = 1
                        elseif dy == -1 then
                            spriteId = 0
                        elseif dx == -1 then
                            spriteId = 3
                        end
                        if pathmap[i] then
                            SetColor(255,100,0,255)
                        else
                            SetColor(255,255,255,255)
                        end
                        Sprite(spriteId * 16, 400, 16, 16, cx-8, cy-8, 16, 16)
                        DrawTextBoxAligned(tostring(cost), 15, cellX * 32 - 16, cellY * 32 - 16, 32, 32, 0.5, 0.5)
                    end
                end
                for i=1,#queue do
                    local current = queue[i]
                    local cx, cy = current[1] * 32, current[2] * 32
                    SetColor(255,255,255,140)
                    DrawRectangle(cx - 10, cy - 10, 20, 20)
                    SetColor(128,0,255,140)
                    DrawRectangle(cx - 8, cy - 8, 16, 16)
                    SetColor(255,255,255,180)
                    DrawTextBoxAligned(tostring(current[3]),15, cx - 16, cy - 14, 32, 32, 0.5, 0.5)
                end
                if x and y then
                    local cx, cy = x * 32, y * 32
                    SetColor(255,0,0,255)
                    DrawRectangle(cx - 4, cy - 4, 8, 8)
                end
                if nextX and nextY then
                    local cx, cy = nextX * 32, nextY * 32
                    SetColor(0,0,0,255)
                    DrawLine(cx, cy, x * 32, y * 32, 5)
                    SetColor(255,128,0,255)
                    DrawRectangle(cx - 4, cy - 4, 8, 8)
                end
            end)
    },
    {
        step = {17,20},
        draw = codeExecutor("Dijkstra-8",[[
            local queue = {}
            local visited = {}
            local adjacents = {
                {1,  0, 1    }, {-1,  0, 1 },
                {0,  1, 1    }, { 0, -1, 1 },
                {1,  1, 1.41 }, {-1, -1, 1.41 },
                {1, -1, 1.41 }, {-1,  1, 1.41 }
            }
            local startX, startY = 16, 9
            local endX, endY = 6, 9
            queue[#queue + 1] = {startX, startY, 0}
            visited[startX + startY * width] = {startX, startY, 0}
            while #queue > 0 do
              local lowestCost = queue[1][3]
              local lowestCostIndex = 1
              for i=2,#queue do
                if queue[i][3] < lowestCost then
                  lowestCost = queue[i][3]
                  lowestCostIndex = i
                end
              end
              local current = table.remove(queue, lowestCostIndex)
              local x, y, cost = current[1], current[2], current[3]
              if x == endX and y == endY then
                break
              end
              for _, dir in ipairs(adjacents) do
                local nextX, nextY = x + dir[1], y + dir[2]
                local length = dir[3]
                if nextX >= 0 and nextX < width and 
                    nextY >= 0 and nextY < height 
                then
                  local index = nextX + nextY * width
                  if not visited[index] and costMap[index] > 0 then
                    local newCost = cost + costMap[index] * length
                    queue[#queue + 1] = {nextX, nextY, newCost}
                    visited[index] = {x, y, newCost}
                  end
                end
              end
            end
            local path
            if visited[endX + endY * width] then
              path = {}
              local current = endX + endY * width
              while current do
                path[#path + 1] = current
                if current == startX + width * startY then
                  break
                end
                local from = visited[current]
                current = from[1] + from[2] * width
              end
            end
            ]], 0, 0, GetScreenSize(), nil, -20,
            {
                costMap = getBlockedMap(map, true),
                width = mapWidth,
                height = mapHeight,
                table = table,
                ipairs = ipairs
            },
            function(step, stackinfo)
                local stackScope = {}
                for i=#stackinfo,1,-1 do
                    local info = stackinfo[i]
                    for j=1,#info.locals do
                        local localInfo = info.locals[j]
                        stackScope[localInfo.name] = localInfo.value
                    end
                end
                local visited = stackScope.visited or {}
                local queue = stackScope.queue or {}
                local x,y = stackScope.x, stackScope.y
                local nextX, nextY = stackScope.nextX, stackScope.nextY
                local endX, endY = stackScope.endX, stackScope.endY
                -- if endX and endY then
                --     local cx, cy = endX * 32, endY * 32
                --     SetColor(255,0,0,255)
                --     DrawRectangle(cx - 10, cy - 10, 20, 20)
                -- end
                SetColor(255,255,255,255)
                local path = stackScope.path or {}
                local pathmap = {}
                for i=1,#path do
                    pathmap[path[i]] = true
                end
                for i,v in pairs(visited) do
                    local from = visited[i]
                    local fromX, fromY, cost = from[1], from[2], from[3]
                    local cellX = i % mapWidth
                    local cellY = math.floor(i / mapWidth)
                    if fromX ~= cellX or fromY ~= cellY then
                        local cx, cy = (cellX + fromX) * 16, (cellY + fromY) * 16
                        local dx, dy = cellX - fromX, cellY - fromY
                        local spriteId = 2
                        if dx == 1 and dy == 1 then
                            spriteId = 5
                        elseif dx == -1 and dy == -1 then
                            spriteId = 7
                        elseif dx == 1 and dy == -1 then
                            spriteId = 4
                        elseif dx == -1 and dy == 1 then
                            spriteId = 6
                        elseif dx == 1 then
                            spriteId = 1
                        elseif dy == -1 then
                            spriteId = 0
                        elseif dx == -1 then
                            spriteId = 3
                        end
                        if pathmap[i] then
                            SetColor(255,100,0,255)
                        else
                            SetColor(255,255,255,255)
                        end
                        Sprite(spriteId * 16, 400, 16, 16, cx-8, cy-8, 16, 16)
                        DrawTextBoxAligned(("%.1f"):format(cost), 10, cellX * 32 - 16, cellY * 32 - 16, 32, 32, 0.5, 0.5)
                    end
                end
                for i=1,#queue do
                    local current = queue[i]
                    local cx, cy = current[1] * 32, current[2] * 32
                    SetColor(255,255,255,140)
                    DrawRectangle(cx - 10, cy - 10, 20, 20)
                    SetColor(128,0,255,140)
                    DrawRectangle(cx - 8, cy - 8, 16, 16)
                    SetColor(255,255,255,180)
                    DrawTextBoxAligned(("%.1f"):format(current[3]),10, cx - 16, cy - 14, 32, 32, 0.5, 0.5)
                end
                if x and y then
                    local cx, cy = x * 32, y * 32
                    SetColor(255,0,0,255)
                    DrawRectangle(cx - 4, cy - 4, 8, 8)
                end
                if nextX and nextY then
                    local cx, cy = nextX * 32, nextY * 32
                    SetColor(0,0,0,255)
                    DrawLine(cx, cy, x * 32, y * 32, 5)
                    SetColor(255,128,0,255)
                    DrawRectangle(cx - 4, cy - 4, 8, 8)
                end
            end)
    },
    {
        step = {2,3},
        activate = function() 
            codeExecutorShowLine = 1
            codeExecutorSetStep = 6
        end,
        draw = speechBubblePointAt([[
            Since the start of the code is similar to the Breadth First Search, we will skip the 
            first lines. The first difference is this [color=f00f]0[/color]! ]], 50, 10, 600,nil,270,320,100)
    },
    {
        step = 3,
        draw = speechBubblePointAt([[
            Another [color=f00f]0[/color] is inserted here. This is the cost we have spent
            to get to this cell - since we are at the start, it is [color=f00f]0[/color].]],
            50, 165, 600,nil,90,460,-20)
    },
    {
        step = 4,
        activate = function() 
            codeExecutorShowLine = 9
            codeExecutorSetStep = 9
        end,
        draw = speechBubblePointAt([[
            The accumulated travel costs are drawn on the purple squares that represent
            queue entries.]], 50, 314, 600,nil,90,463,-20)
    },
    {
        step = 5,
        activate = function() 
            codeExecutorShowLine = 9
            codeExecutorSetStep = 9
        end,
        draw = speechBubblePointAt([[
            Another difference is, that we are now looking for the index 
            with the lowest total costs. It would be more efficient if 
            a priority queue was used, so a dedicated data structure 
            that supports getting the entry with highest priority 
            efficiently, but for simplicity, we do a linear search here.]], 350, 10, 450,nil,0,-20,90)
    },
    {
        step = 6,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorSetStep = 9
            codeExecutorRunToStep = 11
        end,
        draw = speechBubblePointAt([[
            Since the queue has only one entry, the loop
            with the linear search is skipped. ]], 400, 60, 350,nil,0,-20,40)
    },
    {
        step = 7,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorSetStep = 11
            codeExecutorRunToStep = 20
        end,
        draw = speechBubblePointAt([[
            Another difference is the 
            [color=f00f]costMap[/color]: It is a table that
            contains the cost of crossing 
            that cell. When the entry is 0,
            it means the cell is blocked.
             ]], 520, 60, 250,nil,0,-20,40)
    },
    {
        step = 8,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorSetStep = 20
            codeExecutorRunToStep = 23
        end,
        draw = speechBubblePointAt([[
            The queue has now a new 
            entry that contains the 
            new cost of the cell plus 
            the cost of crossing the
            current cell.
            The visited table gets this
            information too, but we use
            this only for visualization
            purposes.
             ]], 520, 60, 250,nil,0,-20,40)
    },
    {
        step = 9,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorSetStep = 23
            codeExecutorRunToStep = 55
        end,
        draw = speechBubblePointAt([[
            Contrary to the breadth
            search, the queue entries
            have now the same counter -
            it's the costs of traveling
            to these points.]], 180, 250, 250,nil,180,280,40)
    },
    {
        step = 10,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorSetStep = 65
            codeExecutorRunToStep = 65
        end,
        draw = speechBubblePointAt([[
            We skip the search for the 
            queue entry that has the
            lowest cost for now since
            all entries have the same
            costs.]], 570, 250, 230,nil,-1,280,40)
    },
    {
        step = 11,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorSetStep = 75
            codeExecutorRunToStep = 96
        end,
        draw = speechBubblePointAt([[
            We encountered now the 
            first cell with sand - and
            you can see that the cost 
            is higher than for grass:
            the cost for sand is 3,
            for grass it is 1.]], 570, 250, 230,nil,-1,280,40)
    },
    {
        step = 12,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorSetStep = 96
            codeExecutorRunToStep = 96
        end,
        draw = speechBubblePointAt([[
            Naturally that means that 
            this queue entry is going
            to stay longer in the 
            queue than the other 
            entries.]], 570, 250, 230,nil,-1,280,40)
    },
    {
        step = 13,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorSetStep = 96
            codeExecutorRunToStepWarpRange = 500
            codeExecutorRunToStep = 500
            codeExecutorStepsPerSecond = 10
        end,
        draw = speechBubblePointAt([[
            Letting it run for a while,
            you can see that the search
            is now favoring tiles that
            have lower costs.]], 170, 250, 230,nil,-1,280,40)
    },
    {
        step = 14,
        activate = function() 
            codeExecutorAlpha = 255
            codeExecutorShowLine = nil
            codeExecutorSetStep = 1505
            codeExecutorRunToStepWarpRange = 500
            codeExecutorRunToStep = 1505
            codeExecutorStepsPerSecond = 10
        end,
        draw = speechBubblePointAt([[
            Skipping a large number
            of iterations, we can see
            this even more clearly:
            The search continues faster
            over grass tiles.]], 10, 250, 230,nil,-1,280,40)
    },
    {
        step = 15,
        activate = function() 
            codeExecutorAlpha = 0
            codeExecutorShowLine = nil
            codeExecutorSetStep = 8105
            codeExecutorRunToStepWarpRange = 500
            codeExecutorRunToStep = 8105
            codeExecutorStepsPerSecond = 10
        end,
        draw = speechBubblePointAt([[
            Looking at the result, we
            see that I no longer have
            to travel over sand tiles!]], 550, 240, 230,nil,0,-25,30)
    },
    {
        step = 16,
        activate = function() 
            codeExecutorAlpha = 0
            codeExecutorShowLine = nil
            codeExecutorSetStep = 8105
            codeExecutorRunToStepWarpRange = 500
            codeExecutorRunToStep = 8105
            codeExecutorStepsPerSecond = 10
        end,
        draw = speechBubblePointAt([[
            But the path has lots of 
            rectangular movements -
            it would be nice if I could
            Go diagonal. Diagonal 
            moves take longer - but 
            this is exactly what 
            Dijkstra's algorithm can 
            take into account!]], 550, 200, 230,nil,0,-25,70)
    },
    {
        step = 17,
        activate = function() 
            codeExecutorAlpha = 255
            codeExecutorShowLine = 1
            codeExecutorSetStep = 15105
            codeExecutorRunToStepWarpRange = 500
            codeExecutorRunToStep = 15105
            codeExecutorStepsPerSecond = 10
        end,
        draw = speechBubblePointAt([[
            In order to have diagonal
            movements, we only need to
            add it to the adjacents 
            table, together with the 
            cost multiplier, because 
            diagonal movement implies 
            longer travel distances.]], 400, 70, 250,nil,0,-25,70)
    },
    {
        step = 18,
        draw = speechBubblePointAt([[
            We read out the length factor ...]], 50, 60, 250,nil,90,100,-20)
    },
    {
        step = 18,
        activate = function() 
            codeExecutorAlpha = 255
            codeExecutorShowLine = 32
            codeExecutorSetStep = 15105
            codeExecutorRunToStepWarpRange = 500
            codeExecutorRunToStep = 15105
            codeExecutorStepsPerSecond = 10
        end,
        draw = speechBubblePointAt([[
            ... and we multiply the length
            with the cost of the tile.
            This way, sand is crossed
            using the shortest distance
            if possible: in a straight line.]], 550, 90, 250,nil,0,-25,70)
    },
    {
        step = {19,20},
        activate = function() 
            codeExecutorAlpha = 0
            codeExecutorShowLine = 32
            codeExecutorSetStep = 15105
            codeExecutorRunToStepWarpRange = 500
            codeExecutorRunToStep = 15105
            codeExecutorStepsPerSecond = 10
        end,
        draw = speechBubblePointAt([[
            While the solution we have
            is good, one problem now is,
            that the search is not 
            directed: It searches in all,
            regardless of where the flag
            is.
            The next chapter will improve
            this through using a well
            known algorithm called A*.]], 10, 10, 250,nil,-1,-25,70)
    },
    {
        step = 20,
        activate = function() 
            codeExecutorAlpha = 0
            codeExecutorShowLine = 32
            codeExecutorSetStep = 15105
            codeExecutorRunToStepWarpRange = 500
            codeExecutorRunToStep = 15105
            codeExecutorStepsPerSecond = 10
        end,
        draw = speechBubblePointAt([[
            Another issue is, that the diagonal movements 
            are too close to the walls. We should look into
            this, too.]], 400, 330, 380,nil,90,62,-20)
    },

    -----------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------
    {
        chapter = "A*",
        step = {0,21},
        activate = function()
            codeExecutorAlpha = 255
            codeExecutorShowLine = nil
            codeExecutorRunToStepWarpRange = codeExecutorRunToStepWarpRangeDefault
            codeExecutorSetStep = nil
            codeExecutorRunToStep = nil
            codeExecutorStepsPerSecond = codeExecutorStepsPerSecondDefault
        end,
        draw = drawGrid(0,0,24,13)
    },
    {
        step = 0,
        draw = detachedBubble([[
                Chapter 5:
                A*]], nil, nil, nil, nil, 30)
    },
    {
        step = {2,16},
        draw = codeExecutor("A*",[[
            local queue = {}
            local visited = {}
            local adjacents = {{1,0},{-1,0},{0,1},{0,-1}}
            local startX, startY = 16, 9
            local endX, endY = 6, 9
            local foundTotalCosts
            local function estimate(x, y)
                return math.abs(x - endX) + math.abs(y - endY)
            end
            
            -- the 4th value is the estimated cost plus 
            -- the cost to get here
            queue[#queue + 1] = {startX, startY, 0, 
                estimate(startX, startY)}
            visited[startX + startY * width] = {startX, startY, 0,
                estimate(startX, startY)}
            while #queue > 0 do
              local lowestCostIndex = #queue
              local lowestCost = queue[lowestCostIndex][4]
              for i=#queue,2,-1 do
                if queue[i][4] < lowestCost then
                  lowestCost = queue[i][4]
                  lowestCostIndex = i
                end
              end
              if foundTotalCosts and lowestCost >= foundTotalCosts then
                break
              end
              local current = table.remove(queue, lowestCostIndex)
              local x, y, cost = current[1], current[2], current[3]
              if x == endX and y == endY then
                foundTotalCosts = cost
              else
                for _, dir in ipairs(adjacents) do
                  local nextX, nextY = x + dir[1], y + dir[2]
                  if nextX >= 0 and nextX < width and 
                    nextY >= 0 and nextY < height 
                  then
                    local index = nextX + nextY * width
                    local newCost = cost + costMap[index]
                    local estimatedCost = newCost + estimate(nextX, nextY)
                      
                    if (not visited[index] or visited[index][4] > estimatedCost)
                      and costMap[index] > 0 
                    then
                      queue[#queue + 1] = {nextX, nextY, newCost, estimatedCost}
                      visited[index] = {x, y, newCost, estimatedCost}
                    end
                  end
                end
              end
            end
            local path
            if visited[endX + endY * width] then
              path = {}
              local current = endX + endY * width
              while current do
                path[#path + 1] = current
                if current == startX + width * startY then
                  break
                end
                local from = visited[current]
                current = from[1] + from[2] * width
              end
            end
            ]], 0, 0, GetScreenSize(), nil, -20,
            {
                costMap = getBlockedMap(map, true),
                width = mapWidth,
                height = mapHeight,
                table = table,
                ipairs = ipairs,
                math = math,
                print=print
            },
            function(step, stackinfo)
                local stackScope = {}
                for i=#stackinfo,1,-1 do
                    local info = stackinfo[i]
                    for j=1,#info.locals do
                        local localInfo = info.locals[j]
                        stackScope[localInfo.name] = localInfo.value
                    end
                end
                local visited = stackScope.visited or {}
                local queue = stackScope.queue or {}
                local x,y = stackScope.x, stackScope.y
                local nextX, nextY = stackScope.nextX, stackScope.nextY
                local endX, endY = stackScope.endX, stackScope.endY
                -- if endX and endY then
                --     local cx, cy = endX * 32, endY * 32
                --     SetColor(255,0,0,255)
                --     DrawRectangle(cx - 10, cy - 10, 20, 20)
                -- end
                SetColor(255,255,255,255)
                local path = stackScope.path or {}
                local pathmap = {}
                for i=1,#path do
                    pathmap[path[i]] = true
                end
                for i,v in pairs(visited) do
                    local from = visited[i]
                    local fromX, fromY, cost = from[1], from[2], from[4]
                    local cellX = i % mapWidth
                    local cellY = math.floor(i / mapWidth)
                    if fromX ~= cellX or fromY ~= cellY then
                        local cx, cy = (cellX + fromX) * 16, (cellY + fromY) * 16
                        local dx, dy = cellX - fromX, cellY - fromY
                        local spriteId = 2
                        if dx == 1 then
                            spriteId = 1
                        elseif dy == -1 then
                            spriteId = 0
                        elseif dx == -1 then
                            spriteId = 3
                        end
                        if pathmap[i] then
                            SetColor(255,100,0,255)
                        else
                            SetColor(255,255,255,255)
                        end
                        Sprite(spriteId * 16, 400, 16, 16, cx-8, cy-8, 16, 16)
                        DrawTextBoxAligned(tostring(cost), 15, cellX * 32 - 16, cellY * 32 - 16, 32, 32, 0.5, 0.5)
                    end
                end
                for i=1,#queue do
                    local current = queue[i]
                    local cx, cy = current[1] * 32, current[2] * 32
                    SetColor(255,255,255,140)
                    DrawRectangle(cx - 10, cy - 10, 20, 20)
                    SetColor(128,0,255,140)
                    DrawRectangle(cx - 8, cy - 8, 16, 16)
                    SetColor(255,255,255,180)
                    DrawTextBoxAligned(tostring(current[4]),15, cx - 16, cy - 14, 32, 32, 0.5, 0.5)
                end
                if x and y then
                    local cx, cy = x * 32, y * 32
                    SetColor(255,0,0,255)
                    DrawRectangle(cx - 4, cy - 4, 8, 8)
                end
                if nextX and nextY then
                    local cx, cy = nextX * 32, nextY * 32
                    SetColor(0,0,0,255)
                    DrawLine(cx, cy, x * 32, y * 32, 5)
                    SetColor(255,128,0,255)
                    DrawRectangle(cx - 4, cy - 4, 8, 8)
                end
            end)
    },
    {
        step = {0, 24},
        activate = moveGuyTo(512, 298)
    },
    {
        step = {0,20},
        draw = drawAnimatedSprite(0, 432, 16, 16, 
            192, bounceTween(300,280,.25), 1, easeOutElasticTween(0, 1, 1.5), 8, 16, 4, 10)
    },
    
    {
        step = 1,
        draw = detachedBubble[[
            A* can be seen as an extension of Dijkstra's 
            algorithm: Additionally to the cost of traveling 
            to a cell, it also estimates the cost of traveling 
            from that cell to the goal. The rest works the 
            same. We will see now how this changes the
            undirected search to a directed one.
            
            We will ignore the diagonal movements for now
            as we will later look at a better solution.]]
    },
    {
        step = 2,
        activate = function() 
            codeExecutorShowLine = 6
            codeExecutorSetStep = 6
        end,
        draw = speechBubblePointAt([[
            We have now an [color=f00f]estimate[/color] function that returns the estimated 
            travel costs to the target. We use the manhatten distance here.]], 50, 00, 500,nil,270,320,100)
    },
    {
        step = 3,
        activate = function() 
            codeExecutorShowLine = 11
            codeExecutorSetStep = 8
        end,
        draw = speechBubblePointAt([[
            The [color=f00f]queue[/color] and [color=f00f]visited[/color] table has now a 4th value that is the sum 
            of the estimate and the costs of this cell.]], 50, 00, 500,nil,270,320,100)
    },
    {
        step = {4,5},
        activate = function() 
            codeExecutorShowLine = 20
            codeExecutorSetStep = 16
        end,
        draw = speechBubblePointAt([[
            When looking for the next element to dequeue,
            we pick the one with that has the best prospect
            to reach the target soon.]], 400, 70, 400,nil,0,-20,40)
    },
    {
        step = 5,
        draw = speechBubblePointAt([[
            The number here represents the sum of the estimate
            and the costs so far - the distance to the flag is 10.
            Thus, the first entry has total value of 10.]], 390, 320, 410,nil,90,120,-20)
    },
    {
        step = 6,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorSetStep = 70
        end,
        draw = speechBubblePointAt([[
            After the first iteration, the value to the left has the
            best score: 10. If our estimation function does not 
            underestimate the distance, we will never be lower 
            than 10.]], 50, 250, 400,nil,180,420,40)
    },
    {
        step = {7,8},
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorSetStep = 133
        end,
        draw = speechBubblePointAt([[
            We now have 5 entries with the same score.]], 50, 250, 400,nil,180,420,40)
    },
    {
        step = 8,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorSetStep = 138
        end,
        draw = speechBubblePointAt([[
            But I changed the iteration over the queue:
            Searching from end to start for the best 
            candidate to continue gives entries that
            were added last a bonus.
            This makes sense: If we are on a good route,
            why should we continue with entries that are
            rather old?]], 350, 50, 400,nil,0,-20,40)
    },
    {
        step = 9,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorRunToStepWarpRange = 500
            codeExecutorSetStep = 133
            codeExecutorRunToStep = 450
            codeExecutorStepsPerSecond = 20
        end,
        draw = speechBubblePointAt([[
            We can see now that our search continues
            at those points that are closest to the target]], 10, 250, 350,nil,180,370,40)
    },
    {
        step = 10,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorRunToStepWarpRange = 2500
            codeExecutorSetStep = 450
            codeExecutorRunToStep = 2136
            codeExecutorStepsPerSecond = 200
        end,
        draw = speechBubblePointAt([[
            It is quite clear, 
            that the search is 
            converging very 
            fast towards the 
            target.]], 10, 250, 150,nil,-1,370,40)
    },
    {
        step = {11,12},
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorRunToStepWarpRange = 2500
            codeExecutorSetStep = 2136
            codeExecutorRunToStep = 2136
            codeExecutorStepsPerSecond = 200
        end,
        draw = speechBubblePointAt([[
            But is this really 
            the shortest path?]], 10, 250, 150,nil,-1,370,40)
    },
    {
        step = 12,
        draw = speechBubblePointAt([[
            There could still be paths that are shorter -
            as long as there are entries in the queue with
            costs lower than what we have found, there could
            exist a path that's better.
            From this point on, we will no longer consider
            queued elements where the costs are equal or
            greater than the costs of the path we have 
            found. As long as our estimatation does not 
            overestimate the costs and there are no tiles
            with zero or less costs, this is a safe 
            assumption.]], 390, 80, 410,nil,0,-20,20)
    },
    {
        step = 13,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorRunToStepWarpRange = 2500
            codeExecutorSetStep = 2136
            codeExecutorRunToStep = 2179
            codeExecutorStepsPerSecond = 2
            codeExecutorDisplayValueOverlay = false
        end,
        draw = speechBubblePointAt([[
            Checking the 
            content of the 
            queue ...]], 10, 250, 150,nil,-1,370,40)
    },
    {
        step = 14,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorRunToStepWarpRange = 2500
            codeExecutorSetStep = 2179
            codeExecutorRunToStep = 2179
            codeExecutorStepsPerSecond = 2
            codeExecutorDisplayValueOverlay = true
        end,
        draw = speechBubblePointAt([[
            This condition makes sure we finish the loop as soon
            as we can. Since the total cost we've found is as low
            as every other cell's value, we are finished]], 100, 130, 400,nil,90,200,-20)
    },
    {
        step = 15,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorRunToStepWarpRange = 2500
            codeExecutorSetStep = 2179
            codeExecutorRunToStep = 2266
            codeExecutorStepsPerSecond = 10
            codeExecutorDisplayValueOverlay = false
        end,
        draw = speechBubblePointAt([[
            Computing the path works the same as always.]], 100, 200, 400,nil,-1,200,-20)
    },
    {
        step = 16,
        activate = function() 
            codeExecutorShowLine = nil
            codeExecutorRunToStepWarpRange = codeExecutorRunToStepWarpRangeDefault
            codeExecutorSetStep = 2266
            codeExecutorRunToStep = nil
            codeExecutorStepsPerSecond = 10
            codeExecutorDisplayValueOverlay = false
            codeExecutorAlpha = 0
        end,
        draw = speechBubblePointAt([[
            As can be seen, A* visited quite fewer tiles than
            any other algorithm before. But it also added some
            complexity. How does this translate to efficiency?]], 200, 40, 400,nil,-1,200,-20)
    },
    {
        step = {17,23},
        draw = function(step, stepIndex)
            local width, height = GetScreenSize()
            SetColor(220, 230, 250, 255)
            DrawBubble(20, 20, width - 40, height - 40, -1, 0, 0)
            -- draw charts
            SetColor(0,0,0,255)
            local chartX = 80
            local chartY = 60
            local chartW = width - chartX - 80
            local chartH = height - chartY - 80
            DrawRectangle(chartX, chartY, 2, chartH)
            DrawRectangle(chartX + chartW - 2, chartY, 2, chartH)
            DrawRectangle(chartX, chartY + chartH, chartW, 2)
            local maxLines = 0
            local maxTime = 0
            for i,stat in ipairs(codeExecutorStats) do
                if stat.totalLineExec > maxLines then
                    maxLines = stat.totalLineExec
                    maxTime = stat.time
                end
            end

            maxLines = math.ceil(maxLines / 1000) * 1000
            maxTime = math.ceil(maxTime * 100000) / 100
            
            for y=1,5 do
                local cy = chartY + (5-y) * chartH / 5
                SetColor(0,0,0,255)
                DrawRectangle(chartX-4 + chartW, cy, 6, 3)
                DrawRectangle(chartX-2, cy, 6, 3)
                DrawRectangle(chartX-2, cy + 1, chartW, 1)
                local k = math.floor(maxLines / 5 * y)
                SetColor(255,0,0,255)
                DrawTextBoxAligned(tostring(k), 15, chartX - 45, cy - 6, 40, 16, 1, 0)
                local kt = (maxTime / 5 * y)
                SetColor(0,0,255,255)
                DrawTextBoxAligned(("%.3fms"):format(kt), 15, chartX + chartW + 5, cy - 6, 40, 16, 0, 0)
            end

            local displayBarUntil = stepIndex - 16

            SetColor(0,0,0,255)
            DrawTextBoxAligned("[color=f00f]Number of executed code lines[/color] / [color=00ff]execution time[/color]", 20, chartX, chartY - 20, chartW, 20, 0.5, 0)
            for i, stat in ipairs(codeExecutorStats) do
                if i >= displayBarUntil then
                    break
                end
                local x = chartX + i * 100
                local y = math.floor(chartY + chartH - stat.totalLineExec / maxLines * chartH)
                SetColor(255,0,0,255)
                DrawRectangle(x - 20, y, 30, chartH - y + chartY)
                SetColor(0,0,0,255)
                DrawTextBoxAligned(tostring(stat.name), 15, x, chartY + chartH + 5, 30, 20, 0.5, 0)
                local y = math.floor(chartY + chartH - stat.time * 1000 / maxTime * chartH)
                SetColor(0,0,255,255)
                DrawRectangle(x + 20, y, 30, chartH - y + chartY)
            end
        end
    },
    {
        step = 17,
        draw = speechBubblePointAt([[
            Taking the code samples and counting the
            total number of lines that were executed,
            we can make compare the different 
            algorithms next to each other.]], 100, 70, 340,nil,-1,200,-20)
    },
    {
        step = 18,
        draw = speechBubblePointAt([[
            The depth first algorithm was our most 
            simple example - it didn't even terminate
            when hitting the end point.]], 100, 70, 340,nil,-1,200,-20)
    },
    {
        step = 19,
        draw = speechBubblePointAt([[
            But compared to the breadth search, it
            is quite more simple, so that search
            was already taking more lines to execute.]], 100, 70, 340,nil,-1,200,-20)
    },
    {
        step = 20,
        draw = speechBubblePointAt([[
            The search using the Dijkstra algorithm
            involved even more code lines - searching
            for the lowest entry in the queue has
            quite an impact.]], 100, 70, 340,nil,-1,200,-20)
    },
    {
        step = 21,
        draw = speechBubblePointAt([[
            When running the same algorithm but with
            additional diagonal checks, the number 
            of lines executed took another hit.]], 100, 70, 340,nil,-1,200,-20)
    },
    {
        step = 22,
        draw = speechBubblePointAt([[
            But A* could really shine - despite having
            most lines of code, the directed search
            produced quite a bit quicker a result than
            the other algorithms.]], 100, 70, 340,nil,-1,200,-20)
    },
    {
        step = 23,
        draw = speechBubblePointAt([[
            However, the numbers would be 
            different if the target could 
            not be reached!]], 100, 70, 280,nil,-1,200,-20)
    },

    -----------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------
    {
        chapter = "Conclusion",
        step = {0,2},
        activate = moveGuyTo(512, 298)
    },
    {
        step = 0,
        draw = speechBubble([[
            This concludes part 1 of our journey 
            through the world of pathfinding
            algorithms. I hope you enjoyed it!]])
    },
    {
        step = 1,
        draw = speechBubble([[
            If you found this interesting,
            errors or have suggestions for
            improvements, please let me know!]])
    },
    {
        step = 2,
        draw = speechBubble([[
            If you found this interesting,
            errors or have suggestions for
            improvements, please let me know!]])
    },
}

-- the steps are relative to each chapter. Let's calculate the absolute
-- step positions here
local chapterOffset = 0
local maxStepInChaper = 0
local chapters = {}
local prevChapter
for i, step in ipairs(steps) do
    if step.chapter then
        if prevChapter then
            prevChapter.stepsInChapter = maxStepInChaper - prevChapter.chapterOffset
        end
        print("Chapter", step.chapter, chapterOffset, maxStepInChaper)
        chapterOffset = maxStepInChaper
        chapters[#chapters+1] = step
        step.chapterOffset = chapterOffset
        step.chapterIndex = #chapters
        prevChapter = step
        maxStepInChaper = 0
    end
    if type(step.step) == "table" then
        step.step = {step.step[1] + chapterOffset, step.step[2] + chapterOffset}
        maxStepInChaper = math.max(maxStepInChaper, step.step[2] + 1)
    elseif type(step.step) == "number" then
        step.step = step.step + chapterOffset
        maxStepInChaper = math.max(maxStepInChaper, step.step + 1)
    end
    step.currentChapter = chapters[#chapters]
end
if prevChapter then
    prevChapter.stepsInChapter = maxStepInChaper - prevChapter.chapterOffset
end

local frame = 0
local showMenu = false
function draw(dt)
    frame = frame + 1
    SetColor(255,255,255,255)

    map:draw(0,0)
    overlay:draw(0,0)
    guyDraw()
    local currentStep = math.min(math.max(0,GetCurrentStepIndex()), chapters[#chapters].chapterOffset + chapters[#chapters].stepsInChapter - 1)
    SetCurrentStepIndex(currentStep)
    local currentChapter = chapters[1]
    for i, step in ipairs(steps) do
        local index = step.step
        if type(index) == "table" then
            if currentStep >= index[1] and currentStep <= index[2] then
                index = currentStep
            end
        end
        if index == currentStep then
            if step.lastActiveFrame ~= frame then
                if step.activate then
                    step:activate()
                end
                step.activeTime = 0
            end
            step.lastActiveFrame = frame + 1
            if step.draw then
                step:draw(currentStep - step.currentChapter.chapterOffset)
            end
            step.activeTime = step.activeTime + dt
            currentChapter = step.currentChapter
        elseif step.lastActiveFrame == frame and step.deactivate then
            step:deactivate()
        end
    end

    if IsMenuKeyPressed() then
        showMenu = not showMenu
    end

    guyUpdate(dt)

    local closeMenu = showMenu and GetInputAreaStatus(0,0,GetScreenSize()) == "activated"
    
    local w,h = GetScreenSize()
    local info_w = 400
    local info_h = #chapters * 20 + 80
    local info_y = showMenu and (h - info_h + 10) or (h - 30)
    local menuStatus = GetInputAreaStatus((w-info_w) / 2-1, info_y-1, info_w+2, info_h+2)
    local overMenu = menuStatus == "activated"
    if closeMenu and not overMenu then
        showMenu = false
        info_y = (h - 30)
    end
    if not showMenu and overMenu then
        showMenu = true
        info_y = (h - info_h + 10)
    end
    
    SetColor(0,0,0,255)
    DrawBubble((w-info_w) / 2-1, info_y-1, info_w+2, info_h+2, -1, 0,0)
    if menuStatus == "hover" and not showMenu then
        SetColor(250,230,100,255)
    else
        SetColor(250,200,100,255)
    end
    DrawBubble((w-info_w) / 2, info_y, info_w, info_h, -1, 0,0)
    SetColor(0,0,0,255)
    local currentChapterText = ("Chapter %d: %s (%d / %d)"):
        format(currentChapter.chapterIndex - 1, currentChapter.chapter, 
        currentStep - currentChapter.chapterOffset + 1, currentChapter.stepsInChapter or 0)
    DrawTextBoxAligned(currentChapterText, 20, (w-info_w) / 2 + 10, info_y + 2, info_w, 30, 0, 0.5)

    if showMenu then
        SetColor(0,0,0,255)
        DrawRectangle((w-info_w) / 2, info_y + 30, info_w, 2)
        for i=1,#chapters do
            local chapter = chapters[i]
            local y = info_y + 20 * i + 15
            local chapterText = ("%d: %s"):format(i-1, chapter.chapter)
            local rx,ry,rw,rh = (w-info_w) / 2 + 10, y, info_w, 20
            local status = GetInputAreaStatus(rx,ry,rw,rh)
            if status == "hover" then
                SetColor(20,50,200,255) 
            else
                SetColor(0,0,0,255)
            end
            DrawTextBoxAligned(chapterText, 20, rx,ry,rw,rh, 0, 0.5)
            if IsNumberKeyPressed(i-1) or status == "activated" then
                SetCurrentStepIndex(chapter.chapterOffset)
            end
        end
        DrawTextBoxAligned("Press a number to jump to a chapter", 20, (w-info_w)/2, info_y + info_h - 40, info_w, 30, 0.5, 0.5)
    end

    if frame < 2 then
        guyPos.x = guyTarget.x
        guyPos.y = guyTarget.y
    end


    local function button(x,y,w,h, text)
        local activated = false
        local status = GetInputAreaStatus(x,y,w,h)
        if status == "hover" then
            SetColor(200,200,255,255)
        elseif status == "pressed" then
            SetColor(250, 200, 180, 255)
        elseif status == "activated" then
            SetColor(255,255,200,255)
            activated = true
        else
            SetColor(180,180,220,255)
        end
        DrawBubble(x, y, w, h, -1, 0, 0)
        SetColor(0,0,0,255)
        DrawTextBoxAligned(text, 20, x, y, w, h, 0.5, 0.5)
        return activated
    end
    if button(-10, h-40, 100, 45, "<") then
        SetCurrentStepIndex(math.max(0, currentStep - 1))
    end
    if button(w-90, h-40, 100, 45, ">") then
        SetCurrentStepIndex(math.min(chapters[#chapters].chapterOffset + chapters[#chapters].stepsInChapter - 1, currentStep + 1))
    end
end