comms = {}

peer = { 
    peers = {},
    getPeers = function()
        local data = {}
        for k in pairs(peer.peers) do 
            if peer.peers[k] then 
                data[k] = peer.peers[k] 
            end
        end
        return data
    end
}

function listen(n, cb)
    comms[n] = cb
end

function tell(s, n, ...)
    TriggerClientEvent('peer:client:listen', s, n, ...)
end

listen('peer:server:new', function()
    peer.peers[tostring(source)] = {
        entity = GetPlayerPed(source),
        channels = {
            ['all'] = true
        }
    }
    for k in pairs (peer.peers) do 
        if peer.peers[k] then 
            tell(tonumber(k), 'peer:client:new', source, NetworkGetNetworkIdFromEntity(GetPlayerPed(source)), GetPlayerName(source), GetPlayerIdentifierByType(source, 'license'))
        end
    end
    return { source, GetPlayerName(source), GetPlayerIdentifierByType(source, 'license') }
end)

listen('peer:server:channel', function(t, c)
    if not peer.peers[tostring(source)] then print('[browns_peerSync]: attempt to perform a peer action on a non peer, do "peer.new()" to initiate peer first, [ERROR]') return end 
    if t == 'add' then 
        peer.peers[tostring(source)].channels[c] = true
    end
    if t == 'remove' then 
        if peer.peers[tostring(source)].channels[c] then  
            peer.peers[tostring(source)].channels[c] = nil
        end
    end
    return { true }
end)

listen('peer:server:trigger', function(s, c, e, ...)
    if not peer.peers[tostring(source)] then print('[browns_peerSync]: attempt to perform a peer action on a non peer, do "peer.new()" to initiate peer first, [ERROR]') return end
    local channels, channel, continue = {}, false, false
    if c and type(c) == 'table' then 
        for i = 1, #c do 
            channels[c[i]] = true 
            channel = true
        end 
    end
    if channel then 
        for check in pairs(peer.peers[tostring(source)].channels) do 
            print(check)
            if channels[check] then 
                continue = true
                break
            end
        end
    else
        print('[browns_peerSync]: channel table invalid or not found, [ERROR]') return 
    end
    if not continue then print('[browns_peerSync]: peer attempted to sync to a channel that they are not connected to, [ERROR]') return end 
    if not s then 
        for k in pairs (peer.peers) do 
            if tonumber(k) ~= source then 
                if peer.peers[k] then 
                    if channel then 
                        for a in pairs(peer.peers[k].channels) do 
                            if peer.peers[k].channels[a] and channels[a] then 
                                tell(tonumber(k), e, table.unpack({...}))
                                break
                            end
                        end
                    else
                        tell(tonumber(k), e, table.unpack({...}))
                    end
                end
            end
        end
        tell(source, 'peer:client:resp')
        return 
    end
    for k in pairs (peer.peers) do 
        if peer.peers[k] then 
            if channel then 
                for a in pairs(peer.peers[k].channels) do 
                    if channels[a] then 
                        tell(tonumber(k), e, table.unpack({...}))
                    end
                end
            else
                tell(tonumber(k), e, table.unpack({...}))
            end
        end
    end
    return { true }
end)

listen('peer:server:drop', function()
    if not peer.peers[tostring(source)] then print('[browns_peerSync]: attempt to perform a peer action on a non peer, do "peer.new()" to initiate peer first, [ERROR]') return end 
    for k in pairs (peer.peers) do 
        if peer.peers[k] then 
            tell(tonumber(k), 'peer:client:drop', source)
        end
    end
    peer.peers[tostring(source)] = nil 
    return { true }
end)

listen('peer:server:setmetadata', function(k, v)
    if not peer.peers[tostring(source)] then print('[browns_peerSync]: attempt to perform a peer action on a non peer, do "peer.new()" to initiate peer first, [ERROR]') return end 
    for i in pairs (peer.peers) do 
        if peer.peers[i] then 
            tell(tonumber(i), 'peer:client:setmetadata', source, k, v)
        end
    end
    return { true }
end)

listen('peer:server:setdata', function(k, v)
    if not peer.peers[tostring(source)] then print('[browns_peerSync]: attempt to perform a peer action on a non peer, do "peer.new()" to initiate peer first, [ERROR]') return end 
    for i in pairs (peer.peers) do 
        if peer.peers[i] then 
            tell(tonumber(i), 'peer:client:setdata', k, v)
        end
    end
    return { true }
end)

listen('peer:server:net', function(s, n, c, ...)
    if not peer.peers[tostring(source)] then print('[browns_peerSync]: attempt to perform a peer action on a non peer, do "peer.new()" to initiate peer first, [ERROR]') return end 
    if type(c) ~= 'table' then print('[browns_peerSync]: channels data is not a table [ERROR]') return end  
    local channels = {}
    for i = 1, #c do 
        channels[c[i]] = true 
    end 
    
    if s then 
        for k in pairs (peer.peers) do 
            if peer.peers[k] then 
                for a in pairs(peer.peers[k].channels) do 
                    if channels[a] then 
                        tell(tonumber(k), 'peer:client:on', n, ...)
                    end
                end
            end
        end
    end

    if not s then 
        for k in pairs (peer.peers) do 
            if k ~= tostring(source) then 
                if peer.peers[k] then 
                    for a in pairs(peer.peers[k].channels) do 
                        if channels[a] then 
                            tell(tonumber(k), 'peer:client:on', n, ...)
                        end
                    end
                end
            end
        end
    end

    return { true }
end)

listen('peer:server:direct', function(n, i, ...)
    if not peer.peers[tostring(source)] then print('[browns_peerSync]: attempt to perform a peer action on a non peer, do "peer.new()" to initiate peer first, [ERROR]') return end 
    if not peer.peers[tostring(i)] then print('[browns_peerSync]: attempt to send a direct to a non synced peer [ERROR]') return end 
    tell(i, 'peer:client:on', n, ...)
    return { true }
end)

RegisterNetEvent('peer:server:listen', function(n, ...)
    if comms[n] then 
        local data = comms[n](table.unpack({...}))
        TriggerClientEvent('peer:client:tell', source, n, data)
    end
end)

return peer
