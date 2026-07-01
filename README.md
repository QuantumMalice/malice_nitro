![Main Banner](https://i.imgur.com/qyeKUDy.png)

Lightweight NOS system built around statebags for tracking levels. Simple, clean, and designed to be easy to integrate into existing ox-based setups.

## **Features:**

- [x] Restart-safe <br>
- [x] Smooth nitrous system <br>
- [x] Bottle removal (radial menu) <br>
- [x] Configurable refill stations <br>
- [x] Easy configuration and integration <br>
- [ ] Synced particle effects <br>
- [ ] Purge mode <br>
- [ ] Persistence abstraction <br>
- [ ] Configurable boost curves <br>
- [ ] Bottle pressure simulation <br>

## **Dependencies:**

- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)
- [ox_inventory](https://github.com/overextended/ox_inventory)

```lua
-- Access nitrous level (for HUDs)
Entity(cache.vehicle).state.nitrous
```

### **_ox_inventory_**:

```lua
    ["nitrous"] = {
        label = "Nitrous",
        weight = 1000,
        stack = true,
        close = true,
        description = "Bottle of nitrous oxide",
        client = {
            image = "nitrous.png",
        },
        server = {
            export = 'malice_nitro.nitrous'
        }
    },
```
