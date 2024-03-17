comms = { 
    told = {},
    hear = {} 
}

function tell(n, ...) 
    comms.told[n] = false  
    TriggerServerEvent('peer:server:listen', n, table.unpack({...})) 
    while not comms.told[n] do Citizen.Wait(0) end  
    return table.unpack(comms.told[n]) 
end

RegisterNetEvent('peer:client:tell', function(n, d) 
    comms.told[n] = d 
end)

function listen(n, cb) 
    comms.hear[n] = cb 
end

RegisterNetEvent('peer:client:listen', function(n, ...) 
    if comms.hear[n] then 
        comms.hear[n](table.unpack({...}))
    end
end)

peer = { 

    client = {
        id = nil, 
        name = nil, 
        license = nil 
    },

    peers = {}, 

    nets = {}, 

    data = {},

    new = function () 
        local id, name, license = tell('peer:server:new')
        peer.client.id = id
        peer.client.name = name 
        peer.client.license = license
    end,


    trigger = function (s, c, e, ...) 
        local result = tell('peer:server:trigger', s, c, e, ...)
        if result then return end
    end,

    drop = function () 
        local result = tell('peer:server:drop')
        if result then return end
    end,

    get = function ()
        local data = {}
        for k in pairs(peer.peers) do 
            if k then 
                data[k] = peer.peers[k]
            end
        end
        return data 
    end,

    setmetadata = function(k, v)
        local result = tell('peer:server:setmetadata', k, v)
        if result then return end
    end,

    getmetadata = function(k, s)
        if not peer.peers[tostring(GetPlayerServerId(PlayerId()))] then return end 
        if not k then return end 
        if s then 
            if peer.peers[tostring(s)] and peer.peers[tostring(s)].metadata[k] then  
                return peer.peers[tostring(s)].metadata[k]
            end
        end
        if not s then 
            if peer.peers[tostring(GetPlayerServerId(PlayerId()))].metadata[k] then  
                return peer.peers[tostring(GetPlayerServerId(PlayerId()))].metadata[k]
            end
        end
    end,

    channel = {
        add = function(c)
            local result = tell('peer:server:channel', 'add', c)
            if result then return end
        end,
        remove = function(c)
            if c == 'all' then return end 
            local result = tell('peer:server:channel', 'remove', c)
            if result then return end
        end
    },

    net = function(s, n, c, ...)
        local result = tell('peer:server:net', s, n, c, ...)
        if result then return end
    end,

    direct = function(n, i, ...)
        local result = tell('peer:server:direct', n, i, ...)
        if result then return end
    end,

    on = function(n, cb)
        peer.nets[n] = cb
    end,

    setdata = function(k, v)
        local result = tell('peer:server:setdata', k, v)
        if result then return end 
    end,

    getdata = function(k)
        if not peer.peers[tostring(GetPlayerServerId(PlayerId()))] then return end 
        if peer.data[k] then 
            return peer.data[k]
        end
    end

}

listen('peer:client:new', function(s, p, n, l)
    peer.peers[tostring(s)] = {
        entity = NetToPed(p),
        metadata = {},
        id = s, 
        name = n,
        license = l
    }
end)

listen('peer:client:setmetadata', function(s, k, v)
    peer.peers[tostring(s)].metadata[k] = v
end)

listen('peer:client:drop', function(s)
    peer.peers[tostring(s)] = nil
end)

listen('peer:client:on', function(n, ...)
    if peer.nets[n] then 
        peer.nets[n](table.unpack({...}))
    end
end)

listen('peer:client:setdata', function(k, v)
    peer.data[k] = v
end)

return peer
