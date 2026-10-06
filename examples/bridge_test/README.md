# bridge_test

A resource that runs Nexus Bridge on the server it is started on and prints one line for each check:

```
[bridge_test] OK    framework.listJobs: 23 jobs
[bridge_test] OK    vehicles.give: BRT0TEST
[bridge_test] ready: every check passed
```

It has been started on Qbox, QBCore, ESX and ESX with ox_inventory. It is the quickest way to see whether the bridge and your server agree.

```cfg
ensure nexus_bridge
ensure bridge_test
```

It runs when it starts, and again with `bridgetest` in the server console.

By itself it only reads. The checks that change something are behind convars, and each one removes what it made:

| convar | what it does |
|---|---|
| `set bridge_test_character 1` | makes a throwaway character that is not online and moves its money (Qbox and QBCore) |
| `set bridge_test_vehicles 1` | gives a throwaway character a vehicle, hands it to a second one and removes it |
| `set bridge_test_jobs 1` | hires and fires a throwaway character, and makes, changes and removes a grade nobody holds |
| `set bridge_test_banking 1` | adds 25 to a job's account and takes it out again |
| `set bridge_test_dispatch 1` | sends one real alert to whoever is on duty |

Use them on a test server. They are safe on a live one in the sense that they clean up after themselves, but an alert is an alert.
