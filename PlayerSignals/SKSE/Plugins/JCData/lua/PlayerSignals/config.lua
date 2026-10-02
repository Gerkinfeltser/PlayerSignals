-- Raw JSON validation avoids JContainers' boolean/integer and reference-string normalization.
local M = {}
local null = {}

local function decode(text)
    local pos, length = 1, #text
    local function fail(message) error('JSON byte ' .. pos .. ': ' .. message, 0) end
    -- Validate UTF-8 before passing display strings to the native bridge.
    local byte = 1
    while byte <= length do
        local first = string.byte(text, byte)
        local count, low, high = 0, 128, 191
        if first >= 194 and first <= 223 then count = 1
        elseif first >= 224 and first <= 239 then
            count = 2
            if first == 224 then low = 160 elseif first == 237 then high = 159 end
        elseif first >= 240 and first <= 244 then
            count = 3
            if first == 240 then low = 144 elseif first == 244 then high = 143 end
        elseif first >= 128 then fail('invalid UTF-8 at byte ' .. byte) end
        if count > 0 then
            local second = string.byte(text, byte + 1)
            if not second or second < low or second > high then fail('invalid UTF-8 at byte ' .. byte) end
            for continuation = 2, count do
                local b = string.byte(text, byte + continuation)
                if not b or b < 128 or b > 191 then fail('invalid UTF-8 at byte ' .. byte) end
            end
        end
        byte = byte + count + 1
    end
    local function space()
        while pos <= length and string.find(' \t\r\n', string.sub(text, pos, pos), 1, true) do pos = pos + 1 end
    end
    local function utf8(n)
        if n < 128 then return string.char(n) end
        if n < 2048 then return string.char(192 + math.floor(n / 64), 128 + n % 64) end
        if n < 65536 then return string.char(224 + math.floor(n / 4096), 128 + math.floor(n / 64) % 64, 128 + n % 64) end
        return string.char(240 + math.floor(n / 262144), 128 + math.floor(n / 4096) % 64, 128 + math.floor(n / 64) % 64, 128 + n % 64)
    end
    local function hex()
        local s = string.sub(text, pos, pos + 3)
        if #s ~= 4 or not string.match(s, '^%x%x%x%x$') then fail('invalid Unicode escape') end
        pos = pos + 4
        return tonumber(s, 16)
    end
    local function str()
        pos = pos + 1
        local parts = {}
        while pos <= length do
            local c = string.sub(text, pos, pos)
            pos = pos + 1
            if c == '"' then return table.concat(parts) end
            if c == '\\' then
                c = string.sub(text, pos, pos); pos = pos + 1
                local escapes = {['"']='"', ['\\']='\\', ['/']='/', b='\b', f='\f', n='\n', r='\r', t='\t'}
                if c == 'u' then
                    local n = hex()
                    if n >= 55296 and n <= 56319 then
                        if string.sub(text, pos, pos + 1) ~= '\\u' then fail('missing low surrogate') end
                        pos = pos + 2
                        local low = hex()
                        if low < 56320 or low > 57343 then fail('invalid low surrogate') end
                        n = 65536 + (n - 55296) * 1024 + low - 56320
                    elseif n >= 56320 and n <= 57343 then fail('unpaired low surrogate') end
                    if n == 0 then fail('NUL cannot be represented by Papyrus') end
                    parts[#parts + 1] = utf8(n)
                elseif escapes[c] then parts[#parts + 1] = escapes[c]
                else fail('invalid escape') end
            elseif string.byte(c) < 32 then fail('unescaped control character')
            else parts[#parts + 1] = c end
        end
        fail('unterminated string')
    end
    local value
    value = function(depth)
        if depth > 128 then fail('JSON nesting too deep') end
        space()
        local c = string.sub(text, pos, pos)
        if c == '"' then return str() end
        if c == '{' or c == '[' then
            pos = pos + 1
            local node = {kind = c == '{' and 'object' or 'array', data = {}}
            local close = c == '{' and '}' or ']'
            space()
            if string.sub(text, pos, pos) == close then pos = pos + 1; return node end
            while true do
                local key
                if c == '{' then
                    space()
                    if string.sub(text, pos, pos) ~= '"' then fail('expected object key') end
                    key = str(); space()
                    if string.sub(text, pos, pos) ~= ':' then fail('expected colon') end
                    pos = pos + 1
                    if node.data[key] ~= nil then fail('duplicate object key ' .. key) end
                else key = #node.data + 1 end
                node.data[key] = value(depth + 1)
                space()
                local delimiter = string.sub(text, pos, pos); pos = pos + 1
                if delimiter == close then return node end
                if delimiter ~= ',' then fail('expected comma or ' .. close) end
            end
        end
        for _, literal in ipairs({'true', 'false', 'null'}) do
            if string.sub(text, pos, pos + #literal - 1) == literal then
                pos = pos + #literal
                if literal == 'null' then return null end
                return literal == 'true'
            end
        end
        local token = string.match(string.sub(text, pos), '^%-?%d+%.?%d*[eE]?[+%-]?%d*')
        if not token then fail('expected JSON value') end
        -- Only integer tokens are valid anywhere in this schema. Preserve lexical type.
        if not string.match(token, '^%-?%d+$') or string.match(token, '^%-?0%d') then fail('expected integer token') end
        pos = pos + #token
        return tonumber(token)
    end
    local result = value(0); space()
    if pos <= length then fail('trailing input') end
    return result
end

local function object(node, path, allowed)
    assert(type(node) == 'table' and node.kind == 'object', path .. ': expected object')
    if allowed then
        for key in pairs(node.data) do assert(allowed[key], path .. '.' .. key .. ': unknown property') end
    end
    return node.data
end
local function nonempty(v, path)
    assert(type(v) == 'string' and #v > 0, path .. ': expected nonempty string')
end
local function validateCatalog(root)
    local r = object(root, 'root', {schemaVersion=true, intents=true})
    assert(type(r.schemaVersion) == 'number' and r.schemaVersion == 1, 'schemaVersion: expected integer 1')
    local intents = object(r.intents, 'intents')
    assert(next(intents), 'intents: expected nonempty object')
    local marker = '{target}'
    for id, record in pairs(intents) do
        local path = 'intents.' .. id
        assert(string.match(id, '^[a-z][a-z0-9_]*$'), path .. ': expected lowercase ASCII ID')
        local entry = object(record, path, {narration=true, notification=true, targetedNotification=true})
        nonempty(entry.narration, path .. '.narration')
        nonempty(entry.notification, path .. '.notification')
        nonempty(entry.targetedNotification, path .. '.targetedNotification')
        for _, field in ipairs({'narration', 'notification', 'targetedNotification'}) do
            assert(not string.match(entry[field], '%.%s*$'), path .. '.' .. field .. ': omit the final period')
            if field ~= 'targetedNotification' then
                assert(not string.find(entry[field], marker, 1, true),
                    path .. '.' .. field .. ': {target} is only allowed in targetedNotification')
            end
        end
        local first = string.find(entry.targetedNotification, marker, 1, true)
        assert(first, path .. '.targetedNotification: expected exactly one {target}')
        assert(not string.find(entry.targetedNotification, marker, first + #marker, true),
            path .. '.targetedNotification: expected exactly one {target}')
    end
    return r
end
local function validate(root, intents)
    local r = object(root, 'root', {schemaVersion=true, root=true, input=true, wheels=true})
    assert(type(r.schemaVersion) == 'number' and r.schemaVersion == 1, 'schemaVersion: expected integer 1')
    nonempty(r.root, 'root')
    local input = object(r.input, 'input', {openKeyCode=true})
    assert(type(input.openKeyCode) == 'number' and input.openKeyCode >= 1 and input.openKeyCode <= 255, 'input.openKeyCode: expected integer 1..255')
    local wheels = object(r.wheels, 'wheels')
    assert(next(wheels), 'wheels: expected nonempty object')
    assert(wheels[r.root], 'root: unknown wheel ' .. r.root)
    for name, wheel in pairs(wheels) do
        nonempty(name, 'wheels name')
        assert(type(wheel) == 'table' and wheel.kind == 'array', 'wheels.' .. name .. ': expected array')
        assert(#wheel.data >= 1 and #wheel.data <= 8, 'wheels.' .. name .. ': expected 1..8 slots')
        for i, slot in ipairs(wheel.data) do
            if slot ~= null then
                local path = 'wheels.' .. name .. '[' .. i .. ']'
                local e = object(slot, path, {label=true, intent=true, submenu=true, control=true})
                nonempty(e.label, path .. '.label')
                local actions = 0
                for _, action in ipairs({'intent','submenu','control'}) do
                    if e[action] ~= nil then actions = actions + 1; nonempty(e[action], path .. '.' .. action) end
                end
                assert(actions == 1, path .. ': expected exactly one action')
                if e.intent then assert(intents[e.intent], path .. '.intent: unknown ID ' .. e.intent) end
                if e.submenu then assert(wheels[e.submenu], path .. '.submenu: unknown wheel ' .. e.submenu) end
                if e.control then assert(e.control == 'back' or e.control == 'close', path .. '.control: expected back or close') end
            end
        end
    end
    -- Iterative topological elimination checks every wheel, including unreachable ones.
    local done, remaining = {}, 0
    for _ in pairs(wheels) do remaining = remaining + 1 end
    while remaining > 0 do
        local progress = false
        for name, wheel in pairs(wheels) do
            if not done[name] then
                local ready = true
                for _, slot in ipairs(wheel.data) do
                    if slot ~= null and slot.data.submenu and not done[slot.data.submenu] then ready = false end
                end
                if ready then done[name] = true; remaining = remaining - 1; progress = true end
            end
        end
        assert(progress, 'wheels: submenu cycle')
    end
    return r
end
function M.validateCatalogText(text)
    return validateCatalog(decode(text))
end
function M.validateText(text, catalogText)
    local catalog = M.validateCatalogText(catalogText)
    return validate(decode(text), catalog.intents.data)
end

function M.load(args)
    local ok, result = pcall(function()
        local function readFile(path)
            local file, message = io.open(path, 'rb')
            assert(file, path .. ': cannot open file: ' .. tostring(message))
            local text, readMessage = file:read('*a')
            file:close()
            assert(text, path .. ': cannot read file: ' .. tostring(readMessage))
            return text
        end
        local layoutText = readFile(args.path)
        local lastSeparator = 0
        for i = #args.path, 1, -1 do
            local byte = string.byte(args.path, i)
            if byte == 47 or byte == 92 then lastSeparator = i; break end
        end
        local catalogPath = string.sub(args.path, 1, lastSeparator) .. 'intents.json'
        local catalogText = readFile(catalogPath)
        local catalogOk, catalog = pcall(M.validateCatalogText, catalogText)
        if not catalogOk then error(catalogPath .. ': ' .. tostring(catalog), 0) end
        local layoutOk, r = pcall(function()
            return validate(decode(layoutText), catalog.intents.data)
        end)
        if not layoutOk then error(args.path .. ': ' .. tostring(r), 0) end
        -- Build native containers directly: no metadata/reference-string reinterpretation.
        -- Numeric fields use the native JSON integer decoder only after raw validation.
        local root = JValue.objectFromPrototype('{"schemaVersion":1,"input":{"openKeyCode":' .. r.input.data.openKeyCode .. '}}')
        local notifications = JMap.object(); root.notifications = notifications
        local narrations = JMap.object(); root.narrations = narrations
        local targetNotificationPrefixes = JMap.object(); root.targetNotificationPrefixes = targetNotificationPrefixes
        local targetNotificationSuffixes = JMap.object(); root.targetNotificationSuffixes = targetNotificationSuffixes
        local marker = '{target}'
        for id, intent in pairs(catalog.intents.data) do
            notifications[id] = intent.data.notification
            narrations[id] = intent.data.narration
            local template = intent.data.targetedNotification
            local markerStart = string.find(template, marker, 1, true)
            targetNotificationPrefixes[id] = string.sub(template, 1, markerStart - 1)
            targetNotificationSuffixes[id] = string.sub(template, markerStart + #marker)
        end
        -- Canonical internal wheel keys preserve case-distinct and metadata-like JSON names.
        local names, ordinal = {}, 0
        for name in pairs(r.wheels.data) do ordinal = ordinal + 1; names[name] = tostring(ordinal) end
        root.root = names[r.root]
        local wheels = JMap.object(); root.wheels = wheels
        for name, wheel in pairs(r.wheels.data) do
            local slots = JArray.objectWithSize(#wheel.data); wheels[names[name]] = slots
            for i, slot in ipairs(wheel.data) do
                if slot ~= null then
                    local entry = JMap.object(); slots[i] = entry
                    for key, v in pairs(slot.data) do
                        if key == 'submenu' then v = names[v] end
                        entry[key] = v
                    end
                    -- Decorate display text once; authored labels and action identity stay separate.
                    if slot.data.submenu then entry.label = slot.data.label .. ' >'
                    elseif slot.data.control == 'back' then entry.label = slot.data.label .. ' <' end
                end
            end
        end
        args.config = root
        return ''
    end)
    if ok then return result end
    return tostring(result)
end
return M
