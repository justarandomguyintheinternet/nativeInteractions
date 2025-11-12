-- _                       __          ___
-- | |                      \ \        / / |
-- | | _____  __ _ _ __  _   \ \  /\  / /| |__   ___  ___ _______
-- | |/ / _ \/ _` | '_ \| | | \ \/  \/ / | '_ \ / _ \/ _ \_  / _ \
-- |   <  __/ (_| | | | | |_| |\  /\  /  | | | |  __/  __// /  __/
-- |_|\_\___|\__,_|_| |_|\__,_| \/  \/   |_| |_|\___|\___/___\___|
-------------------------------------------------------------------------------------------------------------------------------
-- This mod was created by keanuWheeze from CP2077 Modding Tools Discord.
--
-- You are free to use this mod as long as you follow the following license guidelines:
--    * It may not be uploaded to any other site without my express permission.
--    * Using any code contained herein in another mod requires full credits / asking me.
--    * You may not fork this code and make your own competing version of this mod available for download without my permission.
--
-------------------------------------------------------------------------------------------------------------------------------

local Cron = require("modules/utils/Cron")
local style = require("modules/ui/style")
local resourceHelper = require("modules/utils/resourceHelper")
local manager = require("modules/projectsManager")
local world = require("modules/utils/worldInteraction")
local removals = require("modules/removalManager")
local apartmentManager = require("modules/apartmentManager")

---@class mod
---@field runtimeData {cetOpen: boolean, inGame: boolean, inMenu: boolean}
---@field baseUI baseUI
local mod = {
    player = nil,
    runtimeData = {
        cetOpen = false,
        inGame = false,
        inMenu = false
    },

    baseUI = require("modules/ui/baseUI"),
    GameUI = require("modules/utils/GameUI"),
    api = require("modules/api")
}

function mod:new()
    registerForEvent("onInit", function()
        self.baseUI.init()
        resourceHelper.init()
        manager.init(self)
        world.init()
        removals.init(self)
        apartmentManager.init()
        CName.add("nif_start_signal")
        CName.add("nif_interaction_id")
        CName.add("nif_scene_active")
        CName.add("nif_iguana_idle")
        CName.add("nif")
        Game.GetQuestsSystem():SetFactStr("nif_iguana_idle", 0)
        self.api.init()

        Observe('RadialWheelController', 'OnIsInMenuChanged', function(_, isInMenu)
            self.runtimeData.inMenu = isInMenu
        end)

        self.GameUI.OnSessionStart(function()
            self.runtimeData.inGame = true
            Game.GetQuestsSystem():SetFactStr("nif_iguana_idle", 0)
            Game.GetQuestsSystem():SetFactStr("nif_scene_active", 0)
            manager.sessionStart()
            world.onSessionStart()
            resourceHelper.endEvents = {}
            resourceHelper.patches = {}
            self.baseUI.interactionUI.paused = false
            self.baseUI.interactionUI.fastForward = false
            self.baseUI.interactionUI.cameraExternal = false

            if self.baseUI.interactionUI.interaction then
                self.baseUI.interactionUI.interaction:editEnd()
                self.baseUI.interactionUI.interaction = nil
            end
        end)

        self.GameUI.OnSessionEnd(function()
            manager.sessionEnd()
            self.runtimeData.inGame = false
            Cron.HaltAll()
        end)

        self.runtimeData.inGame = not self.GameUI.IsDetached()

        if self.runtimeData.inGame then
        end

        -- Allow us to patch the journal
        Game.GetResourceDepot():RemoveResourceFromCache("nif\\dummy.journal")
        ArchiveXL.Reload()
    end)

    registerForEvent("onUpdate", function (dt)
        if self.runtimeData.inGame and not self.runtimeData.inMenu then
            Cron.Update(dt)
            manager.update()
            world.update()
        end
    end)

    registerForEvent("onDraw", function()
        style.initialize(true)

        if self.runtimeData.cetOpen then
            self.baseUI.draw(self)
        end
    end)

    registerForEvent("onShutdown", function ()
        world.shutdown()
        manager.shutdown()
        SaveLocksManager.RequestSaveLockRemove("nif")
    end)

    registerForEvent("onOverlayOpen", function()
        self.runtimeData.cetOpen = true
    end)

    registerForEvent("onOverlayClose", function()
        self.runtimeData.cetOpen = false
    end)

    return self
end

return mod:new()

--Facts:
--nif_start_signal: Starts the flow in the questphase, goes into switch
--nif_interaction_id: The ID of the interaction that is to be run, used by switch
--Each scene has:
-- Skip fact: Can be used to terminate scene, e.g. hiding interaction
-- End event: Signals that the scene is being terminated
-- nif_scene_active: Gets set to 1 when the scenes main body runs, i.e. not while only the choice is shown, gets set to 0 when the end event is fired and catched from scripts