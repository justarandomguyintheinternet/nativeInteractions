local miscUtils = {
    data = {},
    saveLock = 0
}

---@param origin table
---@return table
function miscUtils.deepcopy(origin)
	local orig_type = type(origin)
    local copy
    if orig_type == 'table' then
        copy = {}
        for origin_key, origin_value in next, origin, nil do
            copy[miscUtils.deepcopy(origin_key)] = miscUtils.deepcopy(origin_value)
        end
        setmetatable(copy, miscUtils.deepcopy(getmetatable(origin)))
    else
        copy = origin
    end
    return copy
end

---Returns the index of a value in a table, if not found -1
---@param table table
---@param value any
---@return integer
function miscUtils.indexValue(table, value)
    local index={}
    for k,v in pairs(table) do
        index[v]=k
    end
    return index[value] or -1
end

---@param tab table
---@param val any
---@return boolean
function miscUtils.has_value(tab, val)
    for _, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

---@param tab table
---@param index any
---@return boolean
function miscUtils.hasIndex(tab, index)
    for k, _ in pairs(tab) do
        if k == index then
            return true
        end
    end
    return false
end

function miscUtils.tableLength(table)
    local count = 0
    for _ in pairs(table) do count = count + 1 end
    return count
end

---@param tab table
---@param val any
function miscUtils.removeItem(tab, val)
    table.remove(tab, miscUtils.indexValue(tab, val))
end

function miscUtils.addVector(v1, v2)
    return Vector4.new(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z, v1.w + v2.w)
end

function miscUtils.subVector(v1, v2)
    return Vector4.new(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z, v1.w - v2.w)
end

function miscUtils.multVector(v1, factor)
    return Vector4.new(v1.x * factor, v1.y * factor, v1.z * factor, v1.w * factor)
end

function miscUtils.multVecXVec(v1, v2)
    return Vector4.new(v1.x * v2.x, v1.y * v2.y, v1.z * v2.z, v1.w * v2.w)
end

function miscUtils.addEuler(e1, e2)
    return EulerAngles.new(e1.roll + e2.roll, e1.pitch + e2.pitch, e1.yaw + e2.yaw)
end

function miscUtils.subEuler(e1, e2)
    return EulerAngles.new(e1.roll - e2.roll, e1.pitch - e2.pitch, e1.yaw - e2.yaw)
end

function miscUtils.multEuler(e1, factor)
    return EulerAngles.new(e1.roll * factor, e1.pitch * factor, e1.yaw * factor)
end

---Returns table with x y z w from given Vector4
---@param vector Vector4
---@return table {x, y, z, w}
function miscUtils.fromVector(vector)
    return {x = vector.x, y = vector.y, z = vector.z, w = vector.w}
end

---Returns table with i j k r from given Quaternion
---@param quat Quaternion
---@return table {i, j, k, r}
function miscUtils.fromQuaternion(quat)
    return {i = quat.i, j = quat.j, k = quat.k, r = quat.r}
end

---Returns Vector4 object from given table containing x y z w
---@param tab table {x, y, z, w}
---@return Vector4
function miscUtils.getVector(tab)
    return(Vector4.new(tab.x, tab.y, tab.z, tab.w))
end

---Returns Quaternion object from given table containing i j k r
---@param tab table {i, j, k, r}
---@return Quaternion
function miscUtils.getQuaternion(tab)
    return(Quaternion.new(tab.i, tab.j, tab.k, tab.r))
end

---Returns table with roll pitch yaw from given EulerAngles
---@param eul EulerAngles
---@return table {roll, pitch, yaw}
function miscUtils.fromEuler(eul)
    return {roll = eul.roll, pitch = eul.pitch, yaw = eul.yaw}
end

---Returns EulerAngles object from given table containing roll pitch yaw
---@param tab table {roll, pitch, yaw}
---@return EulerAngles
function miscUtils.getEuler(tab)
    return(EulerAngles.new(tab.roll, tab.pitch, tab.yaw))
end

---Sanitizes a string to be used as a file name
---@param name string
---@return string
function miscUtils.createFileName(name)
    name = name:gsub("<", "_")
    name = name:gsub(">", "_")
    name = name:gsub(":", "_")
    name = name:gsub("\"", "_")
    name = name:gsub("/", "_")
    name = name:gsub("\\", "_")
    name = name:gsub("|", "_")
    name = name:gsub("?", "_")
    name = name:gsub("*", "_")
    name = name:gsub("'", "_")
    name = name:gsub(" ", "_")

    return name
end

function miscUtils.addEulerRelative(current, delta)
    local result = Game['OperatorMultiply;QuaternionQuaternion;Quaternion'](current:ToQuat(), Quaternion.SetAxisAngle(Vector4.new(0, 1, 0, 0), Deg2Rad(delta.roll)))
    result = Game['OperatorMultiply;QuaternionQuaternion;Quaternion'](result, Quaternion.SetAxisAngle(Vector4.new(1, 0, 0, 0), Deg2Rad(delta.pitch)))
    result = Game['OperatorMultiply;QuaternionQuaternion;Quaternion'](result, Quaternion.SetAxisAngle(Vector4.new(0, 0, 1, 0), Deg2Rad(delta.yaw)))

    return result:ToEulerAngles()
end

---@param enumName string
---@return table
function miscUtils.enumTable(enumName)
    local enums = {}

    for i = -25, tonumber(EnumGetMax(enumName)) do
        local name = EnumValueToString(enumName, i)
        if name ~= "" then
            table.insert(enums, name)
        end
    end

    return enums
end

function miscUtils.log(...)
    if true then return end

    local args = {...}
    local str = ""

    for i, arg in ipairs(args) do
        str = str .. tostring(arg)
        if i < #args then
            str = str .. "\t"
        end
    end

    print(str)
end

function miscUtils.getFileName(path)
    if string.match(path, "\\") then -- Workaround to avoid stripping records
        return path:match("([^/\\]+)%..*$") or path
    end

    return path
end

function miscUtils.combine(target, data)
    for _, v in pairs(data) do
        table.insert(target, v)
    end

    return target
end

function miscUtils.combineHashTable(target, data)
    for k, v in pairs(data) do
        target[k] = v
    end

    return target
end

function miscUtils.isA(object, class)
    return miscUtils.has_value(object.class, class)
end

function miscUtils.setNestedValue(tbl, keys, data)
    local value = tbl
    for i, key in ipairs(keys) do
        if i == #keys then
            value[key] = data
            return
        else
            value = value[key]
        end
    end
end

function miscUtils.getNestedValue(tbl, keys)
    local value = tbl
    for _, key in ipairs(keys) do
        if value[key] == nil then
            return nil
        end
        value = value[key]
    end
    return value
end

--https://web.archive.org/web/20131225070434/http://snippets.luacode.org/snippets/Deep_Comparison_of_Two_Values_3
function miscUtils.deepcompare(t1,t2,ignore_mt)
    local ty1 = type(t1)
    local ty2 = type(t2)
    if ty1 ~= ty2 then return false end
    -- non-table types can be directly compared
    if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
    -- as well as tables which have the metamethod __eq
    local mt = getmetatable(t1)
    if not ignore_mt and mt and mt.__eq then return t1 == t2 end
    for k1,v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not miscUtils.deepcompare(v1,v2) then return false end
    end
    for k2,v2 in pairs(t2) do
        local v1 = t1[k2]
        if v1 == nil or not miscUtils.deepcompare(v1,v2) then return false end
    end
    return true
end

--https://web.archive.org/web/20131225070434/http://snippets.luacode.org/snippets/Deep_Comparison_of_Two_Values_3
function miscUtils.deepcompareExclusions(t1,t2,ignore_mt,exclusions)
    local ty1 = type(t1)
    local ty2 = type(t2)
    if ty1 ~= ty2 then return false end
    -- non-table types can be directly compared
    if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
    -- as well as tables which have the metamethod __eq
    local mt = getmetatable(t1)
    if not ignore_mt and mt and mt.__eq then return t1 == t2 end
    for k1,v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or (not miscUtils.deepcompare(v1,v2) and not miscUtils.has_value(exclusions, k1)) then
            return false
        end
    end
    for k2,v2 in pairs(t2) do
        local v1 = t1[k2]
        if v1 == nil or (not miscUtils.deepcompare(v1,v2) and not miscUtils.has_value(exclusions, k2)) then
            return false
        end
    end
    return true
end

function miscUtils.getTextMaxWidth(texts)
    local max = 0

    for _, text in ipairs(texts) do
        local x, _ = ImGui.CalcTextSize(text)
        max = math.max(max, x)
    end

    return max
end

function miscUtils.getDerivedClasses(base)
    local classes = { base }

    for _, derived in pairs(Reflection.GetDerivedClasses(base)) do
        if derived:GetName().value ~= base then
            for _, class in pairs(miscUtils.getDerivedClasses(derived:GetName().value)) do
                table.insert(classes, class)
            end
        end
    end

    return classes
end

function miscUtils.nodeRefStringToHashString(data)
    return tostring(ResolveNodeRef(CreateNodeRef(data), GlobalNodeID.GetRoot()).hash):gsub("ULL", "")
end

function miscUtils.nodeRefToHashString(ref)
    local hash = NodeRefToHash(ref)
    hash, _ = tostring(hash):gsub("ULL", "")

    return hash
end

function miscUtils.getEntityByRef(ref)
    return Game.FindEntityByID(entEntityID.new({ hash = ResolveNodeRef(CreateNodeRef(ref), GlobalNodeID.GetRoot()).hash }))
end

function miscUtils.insertClipboardValue(key, data)
    miscUtils.data[key] = data
end

function miscUtils.getClipboardValue(key)
    return miscUtils.data[key]
end

function miscUtils.getKeys(tab)
    local keys = {}

    for k, _ in pairs(tab) do
        table.insert(keys, k)
    end

    return keys
end

function miscUtils.shortenPath(path, width, backwardsSlash)
    if ImGui.CalcTextSize(path) <= width then return path end

    local pattern = backwardsSlash and "^\\?[^\\]*" or "^%/?[^%/]*"
    local dotsWidth = ImGui.CalcTextSize("...")
    while ImGui.CalcTextSize(path) + dotsWidth > width do
        local stripped = path:gsub(pattern, "")
        if #stripped == 0 then
            break
        end
        path = stripped
    end

    while ImGui.CalcTextSize(path) + dotsWidth > width and #path > 0 do
        path = path:sub(2, #path)
    end

    return "..." .. path
end

function miscUtils.addSaveLock()
    miscUtils.saveLock = miscUtils.saveLock + 1
    SaveLocksManager.RequestSaveLockAdd("nif")
end

function miscUtils.removeSaveLock()
    miscUtils.saveLock = math.max(0, miscUtils.saveLock - 1)

    if miscUtils.saveLock == 0 then
        SaveLocksManager.RequestSaveLockRemove("nif")
    end
end

return miscUtils