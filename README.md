# malice_nitro

Lightweight NOS system built around statebags for tracking levels. Simple, clean, and designed to be easy to integrate into existing ox-based setups.

## **Current Features:**

➢ Smooth nitrous system <br>
➢ Synced particle effects <br>
➢ Configurable refill stations <br>
➢ Restart-safe (keeps statebag data intact) <br>
➢ Easy configuration and integration <br>

## **Planned Features:**

- [ ] Purge mode <br>
- [ ] Persistence abstraction <br>
- [ ] Bottle removal (recover partially full bottles) <br>
- [ ] Configurable boost curves <br>
- [ ] Bottle pressure simulation <br>

## **Dependencies:**

- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)
- [ox_inventory](https://github.com/overextended/ox_inventory)

### Access Nitrous Level (for HUDs)

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
        description = "Full bottle of nitrous oxide",
        client = {
            image = "nitrous.png",
        },
        server = {
            export = 'malice_nitro.nitrous'
        }
    },

	["emptynitrous"] = {
		label = "Empty Nitrous",
		weight = 100,
		stack = true,
		close = true,
		description = "Depleted bottle of nitrous oxide",
		client = {
			image = "nitrous.png",
		}
	},
```
