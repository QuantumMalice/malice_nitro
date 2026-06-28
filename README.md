# malice_nitro

## **Dependencies:**

- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)
- [ox_inventory](https://github.com/overextended/ox_inventory)

## **_ox_inventory_**:

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
