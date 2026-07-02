# malice_nitro

![Main Banner](https://i.imgur.com/qyeKUDy.png)

Lightweight NOS system built around statebags. Simple, clean, and designed to be easy to integrate into existing ox-based setups.

## **Features:**

- [x] Restart-safe <br>
- [x] Smooth nitrous system <br>
- [x] Bottle removal (radial menu) <br>
- [x] Configurable refill stations <br>
- [x] Synced particle effects <br>
- [ ] Configurable boost curves <br>
- [ ] Bottle pressure simulation <br>
- [ ] Persistence abstraction <br>
- [ ] Purge mode <br>

## **Dependencies:**

- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)
- [ox_inventory](https://github.com/overextended/ox_inventory)

### **_Access nitrous level (for HUDs)_**:

```lua
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
