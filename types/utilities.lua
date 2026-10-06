---@meta

---Shared. The sign and the separators are the server's choice (Config.settings.format).
---@class Bridge.Format
---@field number fun(value: number, decimals?: integer): string '1,234,568'
---@field money fun(amount: number, options?: { decimals?: integer, symbol?: string, after?: boolean }): string '$1,500'
---@field compact fun(value: number): string '1.3M'

---Server only. oxmysql without including its library. Every function waits for the database.
---@class Bridge.Db
---@field ready fun(): boolean true when oxmysql runs
---@field query fun(sql: string, params?: any[]): table[]
---@field single fun(sql: string, params?: any[]): table?
---@field scalar fun(sql: string, params?: any[]): any
---@field insert fun(sql: string, params?: any[]): integer the new row's id
---@field update fun(sql: string, params?: any[]): integer how many rows changed
---@field transaction fun(queries: (string|table)[]): boolean
---@field columns fun(table: string): table<string, boolean>? nil when there is no such table
---@field migrate fun(name: string, steps: table<integer, string|string[]|fun(db: Bridge.Db)>): boolean, integer, string?

---Server only. Kept in the calling resource's key-value store, so they survive a restart.
---Leave `id` out for a cooldown everybody shares.
---@class Bridge.Cooldown
---@field start fun(key: string, seconds: number, id?: string)
---@field remaining fun(key: string, id?: string): integer whole seconds left, 0 when over
---@field active fun(key: string, id?: string): boolean
---@field try fun(key: string, seconds: number, id?: string): boolean, integer? true and it starts, or false and the seconds left
---@field clear fun(key: string, id?: string)
---@field sweep fun(): integer forgets the ones that are over

---Server only. Limits by player id, which a client cannot choose.
---@class Bridge.RateLimit
---@field check fun(src: integer, name: string, limit?: integer, window?: integer): boolean 6 calls per 1000 ms when left out
---@field guard fun(event: string, handler: fun(src: integer, ...), limit?: integer, window?: integer)
---@field lock fun(id: integer|string, name: string): boolean
---@field unlock fun(id: integer|string, name: string)
---@field locked fun(id: integer|string, name: string): boolean
---@field reset fun(src: integer)

---A rule: nil or true (everybody), false (nobody), 'ace:x', 'job:police:2', 'gang:x:1',
---'group:x', 'boss:police', 'duty:police', a list of rules (any), or a table of
---conditions (all): { ace, job, grade, gang, boss, onDuty }.
---@alias Bridge.PermissionRule nil|boolean|string|table

---Server only.
---@class Bridge.Permission
---@field check fun(src: integer, rule: Bridge.PermissionRule): boolean
---@field describe fun(rule: Bridge.PermissionRule): string

---Shared. Reads locales/<language>.json of the calling resource.
---@class Bridge.Locale
---@field language fun(): string
---@field load fun(options?: { language?: string, folder?: string, fallback?: string }): (fun(key: string, values?: table<string, any>): string), table<string, string>
