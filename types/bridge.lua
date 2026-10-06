---@meta
-- Types for the Lua language server. Point your workspace at this folder
-- ("Lua.workspace.library": ["path/to/nexus_bridge/types"]) and `Bridge.` completes with
-- every module, its functions and what they answer. Nothing in here runs.

---@alias Bridge.Event
---| 'playerLoaded'    # server (src, characterId), client ()
---| 'playerUnloaded'  # server (src, characterId), client ()
---| 'jobChanged'      # server (src, job), client (job)
---| 'moneyChanged'    # server (src, account, amount, action, reason)
---| 'itemUsed'        # server (src, itemName, slot, metadata)
---| 'playerDied'      # server (src), client ()
---| 'playerRevived'   # server (src), client ()

---What every module carries next to its own functions.
---@class Bridge.Module
---@field name string? the adapter that serves the module, or nil when nothing does
---@field resource string? the resource behind that adapter
---@field available boolean false when the module answers with its harmless defaults
---@field supports fun(feature: string): boolean
---@field capabilities fun(): table<string, boolean>

---@class NexusBridge
---@field version string the version of the bridge that is running, as '1.0.0'
---@field side 'server'|'client'
---@field resource string the resource this copy of the loader runs in
---@field framework Bridge.FrameworkServer|Bridge.FrameworkClient
---@field inventory Bridge.InventoryServer|Bridge.InventoryClient
---@field target Bridge.Target client only
---@field notify Bridge.NotifyServer|Bridge.NotifyClient
---@field banking Bridge.Banking server only
---@field vehicles Bridge.Vehicles server only
---@field keys Bridge.Keys server only
---@field fuel Bridge.Fuel
---@field dispatch Bridge.Dispatch server only
---@field phone Bridge.PhoneServer|Bridge.PhoneClient
---@field medical Bridge.MedicalServer|Bridge.MedicalClient
---@field voice Bridge.VoiceServer|Bridge.VoiceClient
---@field weather Bridge.WeatherServer|Bridge.WeatherClient
---@field appearance Bridge.AppearanceServer|Bridge.AppearanceClient
---@field log Bridge.Log server only
---@field format Bridge.Format
---@field db Bridge.Db server only
---@field cooldown Bridge.Cooldown server only
---@field ratelimit Bridge.RateLimit server only
---@field permission Bridge.Permission server only
---@field locale Bridge.Locale
---@field point Bridge.Point client only
---@field ped Bridge.Ped client only
---@field placer Bridge.Placer client only
local B = {}

---Stops the resource with a clear message when the running bridge is older than it needs.
---@param range string '>=1.1', '^1.2.0', '~1.2', or '1.2' for "1.2 or newer, below 2.0"
function B.require(range) end

---The name of the adapter serving a module, or nil when nothing does.
---@param module string
---@return string? adapter
function B.adapter(module) end

---True when the module exists on this side and something serves it.
---@param module string
---@return boolean
function B.has(module) end

---@param module string 'inventory', or 'inventory.metadata' with the feature in it
---@param feature? string
---@return boolean
function B.supports(module, feature) end

---Listens to one of the bridge's events. They are the same on every framework.
---@param event Bridge.Event
---@param handler function
---@param options? { replay: boolean } replay: playerLoaded also runs for who is already there
---@return any ref hand it to Bridge.off
function B.on(event, handler, options) end

---@param ref any
function B.off(ref) end

---The one global a resource gets from `shared_script '@nexus_bridge/init.lua'`.
---@type NexusBridge
Bridge = nil

---The same table under a name no other resource uses, for a script that has a `Bridge` of its own.
---@type NexusBridge
NexusBridge = nil
