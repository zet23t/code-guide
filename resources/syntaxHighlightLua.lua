
local controlKeywords = {
    "function", "if", "then", "else", "elseif", "end", 
    "for", "while", "do", "repeat", "until", "return", 
    "break", "goto", "in"
}
local literalKeywords = { "nil", "true", "false" }
local expressionKeywords = { "and", "or", "not" }
local scopingKeywords = { "local" }
local keywords = {}
local function feedKeywords(list, color) 
    color = "[color=" .. color .. "]"
    for i, word in ipairs(list) do 
        keywords[word] = color 
    end 
end
feedKeywords(controlKeywords, "408f")
feedKeywords(literalKeywords, "00af")
feedKeywords(expressionKeywords, "444f")
feedKeywords(scopingKeywords, "00ff")

local function syntaxHighlightLua(text)
    local minIndention = 255
    local lines = {}
    local nonHighlighted = {}
    for line in text:gmatch "[^\r\n]*" do
        local indention = line:match "^%s*"
        if indention then
            minIndention = math.min(minIndention, #indention)
        end
        lines[#lines+1] = line
    end
    for i=1,#lines do
        local line = lines[i]
        local code, comment = line:match "^(.-%s*)(%-%-.*)$"
        if code then
            line = code
        end
        line = line:sub(minIndention + 1)
        nonHighlighted[i] = line
        line = line:gsub("%w+", function(word)
            local color = keywords[word]
            if color then
                return color .. word .. "[/color]"
            end
        end)
        if comment then
            line = line .. " [color=484f]" .. comment .. "[/color]"
        end
        lines[i] = ("[color=4448]%02d[/color] %s"):format(i, line)
    end
    return table.concat(lines, "\n"), nonHighlighted
end

return syntaxHighlightLua