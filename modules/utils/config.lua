local config = {}

function config.fileExists(filename)
    local f=io.open(filename,"r")
    if (f~=nil) then io.close(f) return true else return false end
end

function config.tryCreateConfig(path, data)
	if not config.fileExists(path) then
        local file = io.open(path, "w")
        local jconfig = json.encode(data)
        file:write(jconfig)
        file:close()
    end
end

function config.loadFile(path)
    local file = io.open(path, "r")
    local config = {}
    local success = pcall(function ()
        config = json.decode(file:read("*a"))
    end)
    if not success then
        print("Failed to load file: " .. path .. ", restoring empty state")
    end
    file:close()
    return config
end

function config.saveFile(path, data)
    local file = io.open(path, "w")
    local jconfig = json.encode(data)
    file:write(jconfig)
    file:close()
end

local function recursiveAddMissingKeys(source, target)
    for k, v in pairs(source) do
        if type(v) == "table" and type(target[k]) == "table" then
            recursiveAddMissingKeys(v, target[k])
        elseif target[k] == nil then
            target[k] = v
        end
    end
end

function config.backwardComp(path, data)
    local f = config.loadFile(path)

    recursiveAddMissingKeys(data, f)

    config.saveFile(path, f)
end

function config.loadText(path)
    local lines = {}
    for line in io.lines(path) do
        table.insert(lines, line)
    end
    return lines
end

function config.loadRaw(path)
    local file = io.open(path, "r")
    local content = file:read("*a")
    file:close()
    return content
end

function config.saveRaw(path, data)
    local file = io.open(path, "w")
    file:write(data)
    file:close()
end

function config.saveRawTable(path, data)
    local file = io.open(path, "w")
    for _, line in pairs(data) do
        file:write(line .. "\n")
    end
    file:close()
end

return config