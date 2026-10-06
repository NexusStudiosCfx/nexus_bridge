---@meta

---@alias Bridge.NotifyKind 'info'|'success'|'error'|'warning'

---@class Bridge.NotifyOptions
---@field title string?
---@field duration integer? milliseconds

---@class Bridge.NotifyServer: Bridge.Module
---@field send fun(src: integer, message: string, kind?: Bridge.NotifyKind, options?: Bridge.NotifyOptions): boolean src -1 is everybody

---Capabilities: title, duration, warning.
---@class Bridge.NotifyClient: Bridge.Module
---@field show fun(message: string, kind?: Bridge.NotifyKind, options?: Bridge.NotifyOptions): boolean

---@class Bridge.TargetOption
---@field label string
---@field icon string? a Font Awesome name
---@field distance number?
---@field onSelect fun(entity: integer?) entity is nil for a point or a box
---@field canInteract (fun(entity: integer?, distance: number): boolean?)?
---@field groups Bridge.GroupRule?

---One option, or a list of them.
---@alias Bridge.TargetOptions Bridge.TargetOption|Bridge.TargetOption[]

---Client only. What was added is put back when the target resource restarts or changes.
---@class Bridge.Target: Bridge.Module
---@field addPoint fun(point: { coords: vector3, radius?: number, options: Bridge.TargetOptions }): integer?
---@field addBox fun(box: { coords: vector3, size: vector3, heading?: number, options: Bridge.TargetOptions }): integer?
---@field addEntity fun(entity: integer, options: Bridge.TargetOptions): integer?
---@field addModel fun(models: string|integer|(string|integer)[], options: Bridge.TargetOptions): integer?
---@field addGlobal fun(kind: 'player'|'vehicle'|'ped'|'object', options: Bridge.TargetOptions): integer?
---@field remove fun(id: integer): boolean
---@field clear fun() everything this resource added
---@field disable fun(state: boolean) no targeting while a menu or a scene has the player
---@field count fun(): integer

---@class Bridge.PointDef
---@field coords vector3
---@field distance number? 25 when left out
---@field onEnter fun(point: Bridge.PointDef)?
---@field onExit fun(point: Bridge.PointDef)?
---@field nearby fun(point: Bridge.PointDef, distance: number)? every frame while inside
---@field id integer? set by the bridge

---Client only. One loop for all points of a resource; none without points.
---@class Bridge.Point
---@field add fun(point: Bridge.PointDef): integer?
---@field remove fun(id: integer): boolean
---@field inside fun(id: integer): boolean
---@field count fun(): integer

---@class Bridge.PedDef
---@field model string|integer
---@field coords vector3|vector4 the fourth number is the heading
---@field heading number?
---@field distance number? how near the player has to be for the ped to exist; 50 when left out
---@field scenario string?
---@field options Bridge.TargetOptions?
---@field onSpawn fun(ped: integer)?

---Client only. A ped exists while the player is near it.
---@class Bridge.Ped
---@field add fun(ped: Bridge.PedDef): integer?
---@field remove fun(id: integer): boolean
---@field entity fun(id: integer): integer?

---@class Bridge.PlacerOptions
---@field model string|integer
---@field reach number? how far from the player it may stand; 6 when left out
---@field flatness number? how level the surface has to be; 0.85 when left out
---@field canPlace (fun(coords: vector3, heading: number): boolean?)?

---Client only.
---@class Bridge.Placer
---@field start fun(options: Bridge.PlacerOptions, onDone?: fun(result: { coords: vector3, heading: number }?)): boolean
---@field active fun(): boolean
---@field cancel fun(): boolean
---@field settle fun(entity: integer, onDone?: fun(ok: boolean)): boolean
