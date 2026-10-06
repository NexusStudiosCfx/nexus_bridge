# nexus_shop, on the bridge

A small shop: a clerk behind a counter, an option to open it, a basket and a checkout in cash or by card. It is a copy of the Nexus UI example resource, moved from its own framework and inventory code onto Nexus Bridge.

It is the worked example of [docs/moving-a-resource.md](../../docs/moving-a-resource.md), which goes through what changed and why. It has been started on Qbox, QBCore, ESX and ESX with ox_inventory.

## What it uses

| | |
|---|---|
| `Bridge.framework.getMoney`, `removeMoney`, `addMoney` | the checkout, and the refund when an item did not arrive |
| `Bridge.inventory.exists`, `label`, `canCarry`, `add` | the price list and the delivery |
| `Bridge.inventory.image` (client) | the pictures in the basket |
| `Bridge.target.addEntity`, `remove` (client) | the option on the clerk: an eye option where the server has a target resource, a key prompt where it has none |

## Running it

```cfg
ensure nexus_bridge
ensure nexus_shop
```

The page (`web/dist`) is built already. The items it sells are in `config.lua`; an item your inventory does not know is left out of the shop with a line in the console.

The page is made with [Nexus UI](https://github.com/NexusStudiosCfx/nexus-ui), whose runtime is in `nexus/`. Nothing in the page knows about the bridge: it talks to the Lua in `server/main.lua` and `client/main.lua`, and those talk to the bridge.
