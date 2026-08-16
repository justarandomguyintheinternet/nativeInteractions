local bench = {
    times = {},
    avg = {}
}

function bench.startTimer(id)
    bench.times[id] = os.clock()
end

function bench.stopTimer(id)
    local ms = (os.clock() - bench.times[id]) * 1000
    print(string.format("%s: %.4f ms | AVG: %.4f", id, ms, bench.avg[id] or ms))

    if not bench.avg[id] then
        bench.avg[id] = ms
    else
        bench.avg[id] = bench.avg[id] * 0.99 + ms * 0.01
    end
end

-- q = Game.GetQuestsSystem()
-- total = 0
-- for i = 1, 25 do
--     time = os.clock()
--     for i = 1, 10000 do
--         local x = q:GetFactStr("nif_eat_level")
--     end
--     total = total + (os.clock() - time)
-- end
-- print("GetFactStr took " .. (total / 25) .. " seconds")

return bench