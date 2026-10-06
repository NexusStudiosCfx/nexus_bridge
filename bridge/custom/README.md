# Your own adapters

This folder is yours. Nothing in it is replaced by an update of the bridge.

`example/` is a template: three small files that show what an adapter looks like. It is never loaded, because "example" is no category.

To make the bridge talk to a resource it does not know:

1. Make a folder named after the module: `bridge/custom/inventory/`, `bridge/custom/notify/` and so on.
2. Put a `server.lua` and, where the module has a client half, a `client.lua` into it. Each returns a table of functions, the same ones the adapters next door return (`bridge/inventory/ox_inventory/server.lua` is a good one to read first).
3. In `config.lua`, set that module to `'custom'`:

   ```lua
   Config.adapters = {
       inventory = 'custom',
   }
   ```
4. Restart the bridge and run `bridge doctor` in the server console. The module shows `custom`, and what it supports.

A function you leave out answers with the module's harmless default, and the console says once which one a resource asked for.

The full walk-through, with a worked example and the other way (registering an adapter from a resource of your own, without touching this folder), is in [docs/adding-an-adapter.md](../../docs/adding-an-adapter.md).
