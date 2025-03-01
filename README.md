# Stack Combinator (Redux)

A Factorio 2.0 combinator for the circuit network that manages item stack sizes and related computation.

![A stack combinator in the wild](https://github.com/hgschmie/factorio-stack-combinator-redux/raw/main/portal/staco-main.png)

This mod is a re-implementation of the [Stack Combinator](https://mods.factorio.com/mod/stack-combinator) mod from @modo_lv. It retains its functionality but is a new implementation for Factorio 2.0.

Migration of 1.1 stack combinators in existing saves is supported.

## Features

* Multiply signal count by stack size.
* Divide signal count by stack size and round either up or down.
* Round signal count to the next full stack (up or down or nearest).

* Calculate Stack sizes for each signal separately (by wire color) or merge signals first
* Invert input signals before calculating stack sizes

* 'Wagon stack' mode to calculate train capacity.

* Pass, invert or drop non-processed signals such as virtual signals or fluids.

* Compatible with [Even Pickier Dollies](https://mods.factorio.com/mod/even-pickier-dollies) to move around and [Compact Circuits](https://mods.factorio.com/mod/compaktcircuit).

## Stack Combinator UI settings

![Stack combinator UI](https://github.com/hgschmie/factorio-stack-combinator-redux/raw/main/portal/staco-ui.png)

The stack combinator supports settings copy/paste and blueprinting.

### Mode

The 'Mode' setting supports the following options:

* Multiply ('*') - Multiply each item signal by its stack size.
* Divide and round up ('/ ↑') - Divide each item signal by its stack size, rounding the result away from zero.
* Divide and round down('/ ↓') - Divide each item signal by its stack size, rounding the result towards zero.
* Round ('↕') - Rounds each item signal towards its nearest full stack count.
* Round up ('↑') - Rounds each item signal to its nearest full stack count, away from zero.
* Round down ('↓') - Rounds each item signal to its nearest full stack count, towards zero.

### Signals

The _Merge red and green input signals_ checkbox controls whether input signals are added first or whether they are processed separately and the results are added.

The red and green wires each have a "coal 25" signal. When using the _Divide and round up_ operation, the combinator will output "coal 2" as each signal is calculated separately and rounded up to a full stack:

![Stack combinator UI](https://github.com/hgschmie/factorio-stack-combinator-redux/raw/main/portal/staco-merge-off.png)

The red and green wires each have a "coal 25" signal but the _Merge red and green input signals_ checkbox is activated. When using the _Divide and round up_ operation, the combinator will output "coal 1" as the red and green signals are first added to 50 which is a single stack:

![Stack combinator UI](https://github.com/hgschmie/factorio-stack-combinator-redux/raw/main/portal/staco-merge-on.png)

The _R_ and _G_ checkboxes control whether the combinator processes the red/green signals. This is similar to the standard combinators. If a box is unchecked, signals are not processed even if they are present. If no wire is connected or the merge box is checked, the checkboxes are grayed out.

The _Invert signals_ checkboxes control the inversion of the red and green signals. These boxes are even available when merge is selected. They will be grayed out if no wire is connected. Signal inversion affects all signals, not just item signals.

The _Output signals require power_ checkbox controls how the combinator behaves when it loses power. Standard combinators return the last processed value. This is the default behavior (checkbox is unchecked). If the box is checked, the combinator will output nothing when it loses power.

### Wagon stacks

When activating the _Wagon Stacks_ switch, the stack size of each item is multiplied by the number of cargo wagons as detected by signals that represent cargo wagons. This can be used to determine how many items will fit into a train.

When checking the _Process fluid signals_ checkbox, the combinator will also compute fluid capacity for fluid wagons.

![Stack combinator UI](https://github.com/hgschmie/factorio-stack-combinator-redux/raw/main/portal/staco-wagon-stacks.png)

In this example, the combinator calculates the number of Advanced circuits that can be loaded onto a two wagon train. For this, the red wire carries the number of cargo wagons (two) and the "Advanced Circuit" signal. The mode is set to _multiply_ which will multiply the number of wagons with the stack size of an item and the capacity of a cargo wagon.

On the green wire, the "Petroleum gas" signal is used to calculate the amount that is needed to fill a five wagon fluid train. It uses the per-wagon fluid capacity and multiplies it with the number of wagons.

Note that the wagon signal (cargo wagon or fluid wagon) and the item or fluid signal must be on the same wire. To use different wires, the signals must be merged first!

If no wagon signal is present, the combinator outputs no signal. This is different from the 1.1 combinator which would have output a single stack.

### Handle non-processed signals

In normal operation, the combinator only processes signals that represents items. It may also process fluid signals if Wagon Stack mode is activated and the Process fluid signals checkbox is checked. All other signals are controlled by this setting

* *Passthrough* - Non-processed signals are passed through. They might have been inverted if any of the "Invert signals" box for an input wire was checked.
* *Invert* - Non-processed signals are inverted. If any of the "Invert signals" box for an input wire was checked, a signal might be inverted twice (back to its original value).
* *Drop* - Non-processed signals are dropped from the output.

## Settings

### Startup settings

* *Migrate 1.1 Stack combinators* - When set before loading a game, all existing 1.1 Stack combinators will be migrated to Stack Combinator Redux.

### Per map settings (can be changed at runtime)

* *Update interval (in ticks)* - Controls how often a combinator gets updated. The default is 6 which is 10 times per second. Warning. Setting this to very low values with many stack combinators will impact FPS/UPS.

### Per player settings (can be changed at runtime)

* *Output signals require power* - This is the default setting for the UI checkbox. Any newly created combinator will use this as the default value.
* *Handle non-processed signals* - This is the default setting for the UI selector. Any newly created combinator will use this as the default value.

## Migrating from the 1.1 Stack combinator module

When activating the "Migrate 1.1 Stack combinators" setting, all existing, old stack combinators are migrated to this mod. The 1.1 Stack Combinator module does not need to be activated.

* all entities on all surfaces are migrated, their configuration is applied to the new stack combinator, which retains all wire connections
* all references in blueprints and blueprint books that are either in the Game Blueprint Library or in a Player's main inventory are replaced with the new stack combinator

----

## Legal and other stuff

(C) 2025 Henning Schmiedehausen (hgschmie)

Report Bugs either directly [on github](https://github.com/hgschmie/factorio-stack-combinator-redux/issues) (preferred!) or on the [Mod discussion forum](https://mods.factorio.com/mod/stack-combinator-redux/discussion).

I occasionally hang out [on the official Factorio discord](https://discord.gg/factorio). Find me on `#mod-dev-help` or `#mod-dev-discussion`.

Licensed under the MIT License. See the [license file](LICENSE.md) for details.

* Inspired by the [Stack Combinator](https://mods.factorio.com/mod/stack-combinator) mod by [@modo_lv](https://mods.factorio.com/user/modo_lv).
