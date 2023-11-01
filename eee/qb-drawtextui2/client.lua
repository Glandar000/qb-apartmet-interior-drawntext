local QBCore = exports["qb-core"]:GetCoreObject()

RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    playerData = QBCore.Functions.GetPlayerData()

end)

RegisterNetEvent('QBCore:Client:OnJobUpdate')
AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo)
    playerData = JobInfo

end)

CreateThread(function()
    if QBCore.Functions.GetPlayerData() then
        playerData = QBCore.Functions.GetPlayerData()
    end
end)