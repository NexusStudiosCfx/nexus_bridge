---@meta

---Server only. Accounts of jobs and gangs ("society money"). Capabilities: create, statements.
---@class Bridge.Banking: Bridge.Module
---@field exists fun(account: string): boolean
---@field balance fun(account: string): integer? nil when the bank has no such account
---@field add fun(account: string, amount: number, reason?: string): boolean
---@field remove fun(account: string, amount: number, reason?: string): boolean never below zero
---@field ensure fun(account: string, label?: string): boolean makes the account when it is missing

---@class Bridge.OwnedVehicle
---@field plate string
---@field owner string? the character id
---@field model string? the model's name where the framework stores one
---@field hash integer?
---@field stored boolean true while it is in a garage
---@field garage string?
---@field props table the framework's own vehicle properties

---Server only. Capabilities: give, transfer, remove.
---@class Bridge.Vehicles: Bridge.Module
---@field get fun(plate: string): Bridge.OwnedVehicle?
---@field owner fun(plate: string): string?
---@field isOwned fun(plate: string): boolean
---@field owns fun(id: string, plate: string): boolean
---@field list fun(id: string): Bridge.OwnedVehicle[]
---@field give fun(id: string, vehicle: { model: string, plate?: string, props?: table, garage?: string }): string|false the plate it got
---@field setOwner fun(plate: string, id: string): boolean
---@field remove fun(plate: string): boolean
---@field plate fun(): string? a plate nobody owns yet

---Server only. Give the entity, the plate, or both. Capability: has.
---@class Bridge.Keys: Bridge.Module
---@field give fun(src: integer, vehicle?: integer, plate?: string): boolean
---@field remove fun(src: integer, vehicle?: integer, plate?: string): boolean
---@field has fun(src: integer, vehicle?: integer, plate?: string): boolean

---Levels are 0 to 100. On the server `get` needs the capability read.
---@class Bridge.Fuel: Bridge.Module
---@field get fun(vehicle: integer): number?
---@field set fun(vehicle: integer, level: number): boolean

---@class Bridge.Alert
---@field title string
---@field coords vector3|vector4|{ x: number, y: number, z: number }
---@field message string?
---@field code string? '10-90'
---@field location string? a name for the place
---@field jobs string|string[]? without it the jobs in config.lua
---@field priority 'low'|'medium'|'high'?
---@field blip { sprite?: integer, colour?: integer, scale?: number, seconds?: integer }?
---@field source integer? the player it is about

---Server only. Capabilities: blip, priority, code.
---@class Bridge.Dispatch: Bridge.Module
---@field send fun(alert: Bridge.Alert): boolean

---`who` is a player id, or a character id. Capabilities: mail, offline.
---@class Bridge.PhoneServer: Bridge.Module
---@field getNumber fun(who: integer|string): string?
---@field notify fun(src: integer, note: { title?: string, message?: string, app?: string }): boolean
---@field mail fun(who: integer|string, mail: { sender?: string, subject?: string, message: string }): boolean

---Capability: open.
---@class Bridge.PhoneClient: Bridge.Module
---@field isOpen fun(): boolean

---Capabilities: heal, events. Raises playerDied and playerRevived.
---@class Bridge.MedicalServer: Bridge.Module
---@field isDown fun(src: integer): boolean dead or in last stand
---@field revive fun(src: integer): boolean
---@field heal fun(src: integer): boolean

---@class Bridge.MedicalClient: Bridge.Module
---@field isDown fun(): boolean

---A channel is a whole number above zero; 0 or nothing means none. Capabilities: read, mute.
---@class Bridge.VoiceServer: Bridge.Module
---@field setRadio fun(src: integer, channel?: integer): boolean
---@field getRadio fun(src: integer): integer
---@field setCall fun(src: integer, channel?: integer): boolean
---@field getCall fun(src: integer): integer
---@field mute fun(src: integer, muted: boolean): boolean

---Capability: talking.
---@class Bridge.VoiceClient: Bridge.Module
---@field isTalking fun(): boolean

---Capabilities: read, time, set.
---@class Bridge.WeatherServer: Bridge.Module
---@field get fun(): string? the type in capitals: 'CLEAR', 'RAIN'
---@field isRaining fun(): boolean
---@field getTime fun(): integer?, integer? hour, minute
---@field set fun(weather: string): boolean
---@field setTime fun(hour: integer, minute?: integer): boolean

---Reads the game itself. Capability: pause.
---@class Bridge.WeatherClient: Bridge.Module
---@field get fun(): string?
---@field isRaining fun(): boolean
---@field getTime fun(): integer, integer
---@field pause fun(state: boolean): boolean holds the weather resource off for the local player

---@class Bridge.AppearanceServer: Bridge.Module
---@field reload fun(src: integer): boolean

---A look is the clothing resource's own table: keep it to put it back, do not read it.
---Capabilities: result, reload, snapshot.
---@class Bridge.AppearanceClient: Bridge.Module
---@field open fun(options?: { full?: boolean }, onDone?: fun(saved: boolean)): boolean
---@field reload fun(): boolean
---@field get fun(): table?
---@field set fun(look: table): boolean

---@class Bridge.LogEntry
---@field title string?
---@field message string?
---@field fields table<string, any>|{ name: string, value: any }[]?
---@field level 'info'|'warn'|'error'?
---@field player integer? a player id: their name and character id are added

---Server only.
---@class Bridge.Log: Bridge.Module
---@field send fun(channel: string, entry: string|Bridge.LogEntry): boolean
