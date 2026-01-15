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

return bench