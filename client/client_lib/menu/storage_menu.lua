local QBCore = exports['qb-core']:GetCoreObject()

function showStorage(storage_data)
     local header = storage_data.name
     -- header
     local openMenu = {
          {
               header = header,
               isMenuHeader = true,
               icon = 'fa-solid fa-pump'
          }, {
               header = 'Crude oil',
               icon = 'fa-solid fa-oil-can',
               txt = "" .. storage_data.metadata.crudeOil .. " /gal",
               params = {
                    event = 'keep-oilrig:client_lib:StorageActions',
                    args = {
                         type = 'crudeOil',
                         storage_data = storage_data
                    }
               }
          },
          {
               header = 'Gasoline',
               icon = 'fa-solid fa-oil-can',
               txt = "" .. storage_data.metadata.gasoline .. " /gal",
               params = {
                    event = 'keep-oilrig:client_lib:StorageActions',
                    args = {
                         type = 'gasoline',
                         storage_data = storage_data
                    }
               }
          },
          {
               header = 'leave',
               params = {
                    event = "qb-menu:closeMenu"
               }
          }
     }

     exports['qb-menu']:openMenu(openMenu)
end

function showStorageActions(data)
     local header = "Actions " .. data.type
     local storage_data = data.storage_data
     -- header
     local openMenu = {
          {
               header = header,
               isMenuHeader = true,
               icon = 'fa-solid fa-pump'
          }, {
               header = 'Withraw from storage',
               icon = 'fa-solid fa-truck-ramp-box',
               txt = "",
               params = {
                    event = 'keep-oilrig:client_lib:StorageWithdraw',
                    args = data
               }
          },
          {
               header = 'Storage action',
               icon = 'fa-solid fa-arrow-right-arrow-left',
               params = {
                    event = '',
               }
          },
          {
               header = 'Back',
               icon = 'fa-solid fa-angle-left',
               params = {
                    event = "keep-oilrig:client_lib:ShowStorage"
               }
          }
     }
     exports['qb-menu']:openMenu(openMenu)
end

function showStorageWithdraw(data)
     local header = "Storage withdraw (" .. data.type .. ")"
     local currentWithdrawTarget = data.storage_data.metadata[data.type] -- oil or gas
     -- header
     local openMenu = {
          {
               header = header,
               isMenuHeader = true,
               icon = 'fa-solid fa-boxes-packing'
          },
          {
               header = 'you have ' .. currentWithdrawTarget .. ' gal of ' .. data.type,
               isMenuHeader = true,
               icon = 'fa-solid fa-boxes-packing'
          }, {
               header = 'Store in Barrel',
               icon = 'fa-solid fa-bottle-droplet',
               txt = "deposit: $500   Capacity: 5000 /gal",
               params = {
                    event = 'keep-oilrig:client_lib:Callback',
                    args = {
                         eventName = 'keep-oilrig:server:WithdrawWithBarrel',
                         citizenid = data.storage_data.citizenid,
                         type = data.type
                    }
               }
          },
          {
               header = 'Load in Truck',
               icon = 'fa-solid fa-truck-droplet',
               txt = "deposit: $25,000k   Capacity: 100,000 /gal",
               params = {
                    event = 'keep-oilrig:client_lib:Callback',
                    args = {
                         eventName = 'keep-oilrig:server:WithdrawLoadInTruck',
                         citizenid = data.storage_data.citizenid,
                         type = data.type
                    }
               }
          },
          {
               header = 'Back',
               icon = 'fa-solid fa-angle-left',
               params = {
                    event = "keep-oilrig:client_lib:StorageActions",
                    args = data
               }
          }
     }
     exports['qb-menu']:openMenu(openMenu)
end

MakeVehicle = function(model, Coord, TriggerLocation, DinstanceToTrigger, items)
     local plyped = PlayerPedId()
     local pedCoord = GetEntityCoords(plyped)
     local finished = false
     local distance = GetDistanceBetweenCoords(pedCoord.x, pedCoord.y, pedCoord.z, TriggerLocation.x, TriggerLocation.y, TriggerLocation.z, true)
     CreateThread(function()
          while distance > DinstanceToTrigger do
               local pedCoord = GetEntityCoords(plyped)
               distance = GetDistanceBetweenCoords(pedCoord.x, pedCoord.y, pedCoord.z, TriggerLocation.x, TriggerLocation.y, TriggerLocation.z, true)
               Wait(1000)
          end
          finished = true
     end)

     -- wait for player at delivery coord
     while finished == false do
          DrawMarker(2, TriggerLocation.x, TriggerLocation.y, TriggerLocation.z + 2, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 1.0, 1.0,
               1.0, 255, 128, 0, 50, false, true, 2, nil, nil, false)
          Wait(0)
     end

     local vehiclePlate = "SWK" .. math.random(1, 9) .. math.random(1, 9) .. math.random(1, 9)
     model = GetHashKey(model)
     RequestModel(model)
     while not HasModelLoaded(model) do
          Wait(10)
     end

     local veh = CreateVehicle(model, Coord.x, Coord.y, Coord.z, Coord.w, true, false)
     local netid = NetworkGetNetworkIdFromEntity(veh)
     SetVehicleHasBeenOwnedByPlayer(veh, true)

     SetNetworkIdCanMigrate(netid, true)
     SetVehicleNeedsToBeHotwired(veh, false)
     SetVehRadioStation(veh, "OFF")

     SetVehicleNumberPlateText(veh, vehiclePlate)
     -- TaskWarpPedIntoVehicle(plyped, veh, -1)
     -- exports['LegacyFuel']:SetFuel(veh, math.random(80, 90))
     SetVehicleEngineOn(veh, true, true)
     TriggerEvent('keep-oilrig:menu:AddToTrunk', vehiclePlate, items)
     SetModelAsNoLongerNeeded(model)
end

AddEventHandler('keep-oilrig:menu:AddToTrunk', function(vehiclePlate, items)
     TriggerServerEvent('inventory:server:addTrunkItems', vehiclePlate, items)
end)

-- Events
AddEventHandler('keep-oilrig:client_lib:PumpOilToStorage', function(data)
     QBCore.Functions.TriggerCallback('keep-oilrig:client_lib:PumpOilToStorageCallback', function(result)

     end, data.oilrig_hash)
end)

AddEventHandler('keep-oilrig:client_lib:ShowStorage', function(data)
     QBCore.Functions.TriggerCallback('keep-oilrig:server:getStorageData', function(result)
          showStorage(result)
     end)
end)


AddEventHandler('keep-oilrig:client_lib:StorageActions', function(storage_data)
     showStorageActions(storage_data)
end)


AddEventHandler('keep-oilrig:client_lib:StorageWithdraw', function(data)
     showStorageWithdraw(data)
end)


AddEventHandler('keep-oilrig:client_lib:Callback', function(data)
     QBCore.Functions.TriggerCallback(data.eventName, function(items)
          if items == false then
               return
          end
          local SpawnLocation = Config.Delivery.SpawnLocation
          local TriggerLocation = Config.Delivery.TriggerLocation
          local DinstanceToTrigger = Config.Delivery.DinstanceToTrigger
          local model = Config.Delivery.vehicleModel
          MakeVehicle(model, SpawnLocation, TriggerLocation, DinstanceToTrigger, items)
     end, data)
end)