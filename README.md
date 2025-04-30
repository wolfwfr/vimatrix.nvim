![2025-04-28_16-04-1745850986](https://github.com/user-attachments/assets/dc1c7ff7-c63b-453c-9c3e-397e629103a7)

# 🍃 vimatrix.nvim 🍃

Configurable digital rain simulator for neovim, that can act as a screensaver or
run automatically on files of your choosing.

[vimatrix.webm](https://github.com/user-attachments/assets/8d3d64f6-ed09-47eb-8230-51109df3658b)

**WARNING: vimatrix.nvim may cause discomfort and seizures in people with
photosensitive epilepsy. User discretion is advised.**

## ❔ Why

This was a toy project that I started as a means for getting more familiar with
lua and the nvim api.

Thanks to the authors of [neo](https://github.com/st3w/neo) and
[drop](https://github.com/folke/drop.nvim) and obviously the matrix franchise
for inspiring this plugin!

## ⚡️ Requirements

- Neovim >= 0.8.0
- a font for the configured symbols (katakana by default)
- some CPU headroom
- red pill

## 📦 Installation

Install the plugin with your preferred package manager:

```lua
-- Lazy.nvim (recommended)
{
  "wolfwfr/vimatrix.nvim",
  opts = {
    -- configuration options go here
  }
}
```

## ⚙️ Configuration

**Vimatrix.nvim** comes with the following defaults:

```lua
{
  auto_activation = {
    screensaver = {
      setup_deferral = 10,
      timeout = 0,
      ignore_focus = false,
      block_on_term = true,
      block_on_cmd_line = true,
    },
    on_filetype = {},
  },
  window = {
    general = {
      background = "#000000", --black
			border = "none",
      blend = 0,
      zindex = 10,
      ignore_cells = nil,
    },
    by_filetype = {
      -- e.g:
      -- snacks_dashboard = {
      -- 	background = "",
      -- 	blend = 100,
      -- },
    },
  },
  droplet = {
    max_size_offset = 5,
    timings = {
      max_fps = 25,
      fps_variance = 3,
      glitch_fps_divider = 12,
      max_timeout = 200,
      local_glitch_frame_sharing = false,
      global_glitch_frame_sharing = true,
    },
    random = {
      body_to_tail = 50,
      head_to_glitch = 20,
      head_to_tail = 50,
      kill_head = 150,
      new_head = 30,
    },
  },
  colourscheme = "matrix",
  highlight_props = {
    bold = true,
    blend = 1, -- quickfix for loss of highlight contrast with window blend;
    -- might be removed if it causes unwanted effects
  },
  alphabet = {
    built_in = { "katakana", "decimal", "symbols" },
    custom = {},
    randomize_on_init = true,
    randomize_on_pick = false,
  },
  logging = {
    print_errors = false,
    log_level = vim.log.levels.DEBUG,
  },
}
```

<details><summary>Config Types and Descriptions</summary>

colourscheme:

```lua
---@class vimatrix.colour_scheme
---@field head string hex colourcode for head cell
---@field body string[] hex colourcodes for body cells, no particular order
---@field tail string hex colourcode for the tail cell
---@field glitch_bright? string|string[] hex colourcode for glitch cells upon character change, after which they change colour once more
---@field glitch? string[] hex colourcodes for glitch cells
```

alphabet:

```lua
---@class vx.alphabet_props
---@field built_in? string[] built-in symbol-sets to include
---@field custom? string[] custom symbols to include
---@field randomize_on_init boolean randomizes the given alphabet on initialization; possible performance hit on init
---@field randomize_on_pick boolean randomizes the chosen character on pick
```

other:

```lua

---@class vx.screensaver
---@field setup_deferral integer seconds to wait prior to activating screensaver timers (this helps if you automatically open multiple neovim sessions and screensavers are needlessly activated)
---@field timeout integer seconds after which to automatically display vimatrix
---@field ignore_focus boolean allows screensaver to activate on neovim instances that are out-of-focus (e.g. background)
---@field block_on_term boolean prevents screensaver from activating when terminal window is open
---@field block_on_cmd_line boolean prevents screensaver from activating when command-line window is open

---@class vx.auto_activation
---@field screensaver vx.screensaver screensaver specific settings
---@field on_filetype string[] filetypes for which to automatically display vimatrix

---@class vx.lane_timings
---@field max_fps integer frames per second for the fastest lane
---@field fps_variance integer the number of different speeds to assign to the various lanes; each speed is equal to 'fps/random(1,fps_variance)'
---@field glitch_fps_divider integer glitch symbols update at a slower pace than the droplet's progression; lane_glitch_fps_divider defines the ratio; glitch updates equal 'lane_fps/lane_glitch_fps_divider'
---@field max_timeout integer maximum number of seconds that any lane can idle prior to printing its first droplet; timeout is randomized to random(1, max_timeout)
---@field local_glitch_frame_sharing boolean determines whether glitch cells within one lane synchronise their timings
---@field global_glitch_frame_sharing boolean determines whether all glitch cells on screen synchronise their timings; overrules local_glitch_frame_sharing when true

---@class vx.window_props
---@field background string hex-code colour for window background; empty string will not set a custom background
---@field border string window option to override default window borders
---@field blend integer determines the blend (i.e.) transparency property of the window; see vim.api.keyset.win_config
---@field zindex integer zindex of the floating vimatrix window; see vim.api.keyset.win_config; 1000 seems to hide every other window underneath it but this includes messages and terminal applications from which vimatrix is not cancelled.
---@field ignore_cells? function(integer, integer, integer) callback function that accepts parameters (old_buffer_id, line, column) and returns a boolean that determines if printing to that cell is allowed.

---@class vx.window
---@field general vx.window_props window settings that apply when no filetype match is found
---@field by_filetype table<string, vx.window_props> window settings that appy to the configured filetype

---@class vx.random
---@field body_to_tail integer determines the chance of a body cell at the top row changing into a tail cell
---@field head_to_glitch integer determines the chance of a head cell to leave behind a glitch cell
---@field head_to_tail integer determines the chance of a head cell to immediately be followed by a tail cell (nano-droplet)
---@field kill_head integer determines the chance or a head cell being killed on-screen
---@field new_head integer determines the chance of a new head cell forming when the lane is empty

---@class vx.droplet
---@field max_size_offset integer a positive value will force tail creation on a droplet when it has reached length == window_height - max_size_offset
---@field timings vx.lane_timings the timings of changes on screen
---@field random vx.random the chances of random events; each is a chance of 1 in x

---@class vx.config
---@field auto_activation vx.auto_activation --settings that relate to automatic activation of vimatrix.nvim
---@field window vx.window settings that relate to the window that vimatrix.nvim opens
---@field droplet vx.droplet settings that relate to the droplet lanes
---@field colourscheme vimatrix.colour_scheme | string
---@field highlight_props? vim.api.keyset.highlight Highlight definition to apply to rendered cells, accepts the following keys:
--- - bg: color name or "#RRGGBB"
--- - blend: integer between 0 and 100
--- - bold: boolean
--- - standout: boolean
--- - underline: boolean
--- - undercurl: boolean
--- - underdouble: boolean
--- - underdotted: boolean
--- - underdashed: boolean
--- - strikethrough: boolean
--- - italic: boolean
--- - reverse: boolean
---@field alphabet vx.alphabet_props
---@field logging vx.log.props error logging settings; BEWARE: errors can ammass quickly if something goes wrong
```

</details>

### Options

![2025-04-28_18-04-1745857562](https://github.com/user-attachments/assets/49ab7676-003b-4fac-a31d-aa4ac7026c41)
![2025-04-28_16-04-1745850986](https://github.com/user-attachments/assets/6d020b2d-ec85-482f-a041-ebb74bf87c7d)
![2025-04-28_17-04-1745853567](https://github.com/user-attachments/assets/89240bca-4a9c-470b-87c6-9b217783c67d)
![2025-04-28_17-04-1745853786](https://github.com/user-attachments/assets/a98cd29d-d729-4bd7-b53b-f14f65b34a5b)
![2025-04-28_17-04-1745853834](https://github.com/user-attachments/assets/e3f62675-9410-4582-aa48-cd7501725769)
![2025-04-28_17-04-1745854069](https://github.com/user-attachments/assets/1bc1d659-037b-42ce-b5bf-40db51cea73a)
![2025-04-28_17-04-1745853911](https://github.com/user-attachments/assets/eaad5590-2dc6-45f5-9d0c-cb1199c526a7)
![2025-04-28_17-04-1745854366](https://github.com/user-attachments/assets/5c9351f1-d294-4314-be6a-54ae078ab682)
![2025-04-28_17-04-1745854340](https://github.com/user-attachments/assets/3a79e071-e0f1-4413-b791-64851f314adb)

#### 🎨 Colours

Vimatrix.nvim supports multiple built-in colourschemes, but can also be
configured with custom colours.

<details><summary>Built-In Colourschemes</summary>

- matrix
- rainbow
- green
- red
- orange
- blue
- cyan
- yellow
- pink
- purple

</details>

##### Apply a built-in colourscheme

```lua
-- e.g.
colourscheme = "pink" -- string
```

##### Apply a custom colourscheme

```lua
-- e.g.
colourscheme = {
  head = "#f2fff2", -- required string
  body = { "#27b427", "#1b671b", "#138c13" }, -- required string[]
  tail = "#425842", -- required string
  glitch_bright = "#addaae", -- optional string[]
  --glitch = { "#....." } -- optional string or string[]
}
```

<details><summary>Glitch Behaviour</summary>

When `glitch_bright` is empty or nil, it will fallback to `glitch`.

When `glitch` is empty or nil, it will fallback to `body`.

The `glitch_bright` colours are applied to glitching characters on the moment
the character changes. Right after, the colour will shift to one of `glitch`.
This colourshift only happens when `glitch_bright` is not empty.

</details>

#### 🔤 alphabet

Vimatrix.nvim supports multiple built-in symbols and alphabets, but can also be
configured with custom ones.

<details><summary>Built-In Alphabets</summary>

- arabic
- armenian
- armenian_lower
- armenian_upper
- greek
- greek_lower
- greek_upper
- katakana
- latin
- latin_lower
- latin_upper
- russian
- russian_lower
- russian_upper
- sanskrit

and the following symbols:

- binary
- decimals
- symbols

</details>

> [!IMPORTANT]  
> In order to display these symbols your system needs to be configured with a
> font installed that supports them.

> [!NOTE]  
> Some of the built-in alphabets don't exclusively contain half-width
> characters, which is not perfect for visual consistency, but it still looks
> pretty cool. Affected alphabets are arabic and sanskrit.

##### Apply built-in alphabets

```lua
-- e.g.
{
  alphabet = {
    built_in = {
      "latin",
      "binary",
    }
  }
}
```

##### apply custom alphabets

```lua
-- e.g.
{
  alphabet = {
    -- set built_in to empty to only use your custom set of symbols
    built_in = {},
    custom = {"A", "B", "C"}
  }
}
```

#### ⏩ Speed, Density, and More

Vimatrix.nvim generates, advances, kills, and mutates droplets based on random
chances and other settings that are configurable in the `droplets.random` and
`droplets.timings` sections of the config.

The config determines the speeds, the speed variance, the chance of droplets
forming or dying, the chance of glitching characters appearing, how frequently
they change and whether or not they change in sync.

So good news, you finally found one more plugin that you can configure for days.

##### 🍃 Recommended settings for matrix reproduction

```lua
-- Based on the first scene with Neo and Cypher.
{
  droplet = {
    max_size_offset = 5,
    timings = {
      max_fps = 15,
      fps_variance = 1,
      glitch_fps_divider = 8,
      max_timeout = 200,
      local_glitch_frame_sharing = false,
      global_glitch_frame_sharing = true,
    },
    random = {
      body_to_tail = 50,
      head_to_glitch = 5,
      head_to_tail = 50,
      kill_head = 150,
      new_head = 30,
    },
  },
  colourscheme = "matrix",
}
```

#### 🪟 window settings

Vimatrix.nvim allows you to configure some aspects of the window being drawn and
what happens within it.

For example, you can make a window transparent and determine what cells to
ignore on your dashboard page.

```lua
-- e.g.
{
  window = {
    general = {
      background = "#000000",
      blend = 0,
    },
    by_filetype = {
      snacks_dashboard = {
        background = "",
        blend = 100,
        -- a crude example but it works
        ignore_cells = function(_, ln, cl)
          return (ln > 23 and ln < 32) and (cl > 67 and cl < 215)
          or (ln > 30 and ln < 55) and (cl > 109 and cl < 175)
          or (ln == vim.go.lines)
        end,
      },
    },
  },
}
```

which allows for the following effect:

![2025-04-28_22-04-1745871395](https://github.com/user-attachments/assets/d6625879-4209-4630-aac5-3aa8e823952a)

## 🚀 Usage

### ❌ Cancelling the effect

Vimatrix.nvim generally functions like a screensaver.

You can cancel the effect by `moving the cursor`, `inserting text`, or
`changing modes`.

There is an exception when terminal or command-line windows are open and some of
the default screensaver settings are altered (see `Known Limitations`)

Vimatrix.nvim also exposes the `VimatrixClose` and `VimatrixStop` user-commands,
that can be called (if the regular means do not work) to stop the ticker and
close the window or only stop the ticker, respectively.

### 🖱 Manual Invocation

Vimatrix.nvim makes the `VimatrixOpen` user-command available, which opens the
floating Vimatrix window according to the `window` settings in the config.

You can keymap it if you want, e.g:

```nvim/keymaps.lua
vim.keymap.set("n", "<leader>M", "<CMD>VimatrixOpen<CR>", {})
```

### ✨ Screensaver

Configure the `auto_activation.screensaver` table in the config to your liking.

> [!NOTE]  
> **A note on screensaver.setup-deferral**  
> If, like me, you automatically create/restore multiple neovim instances
> through terminal tabs or a terminal emulator like zellij or tmux, you'll
> probably want to defer the screensaver-setup for a duration longer than it
> takes your system to set-up the instances. Otherwise, screensavers may
> activate on unfocused instances. By default there is a deferral of 10 seconds.

The screensaver is configured to activate only on neovim instances that are in
focus, to prevent system resources from being spent on background instances.

The screensaver does have known limitations and workarounds, see
`Known Limitations`.

### 📄 Activation on File

Configure the `auto_activation` table in the config to your liking.

```lua
-- e.g.
{
  auto_activation = {
    on_filetype = { "snacks_dashboard" },
  },
  window = {
    by_filetype = {
      snacks_dashboard = {
        background = "",
        blend = 100, -- transparent Vimatrix window background
      },
    },
  },
}
```

> [!NOTE]  
> Using blend can apply an unwanted dark tone to the background. See
> `Known Limitations`.

> [!TIP]  
> When automatically activating Vimatrix on a given filetype, you might also
> want to configure Vimatrix window settings by file-type in the
> `window.by_filetype` section of the config. Here you can set `blend`
> (transparency), `background`, `zindex` (handle with care), and configure a
> callback that tells vimatrix to ignore particular areas of the window.

> [!TIP]  
> Find the `filetype` of the file you want to include, e.g. your neovim
> dashboard by loading up the current buffer with your file and executing:
> `:lua print(vim.bo[vim.api.nvim_get_current_buf()].filetype)`

## 📈 Performance

I have tested and attempted to optimize Vimatrix.nvim for CPU and memory usage.

I have found no memory-leaks and, unless you start stacking Vimatrix windows in
multiple neovim instances, I found the CPU usage to be unobtrusive.

On my system (ryzen 7 7840U) I see a ~5-7% overall CPU usage increase when
running the recommended settings for matrix reproduction on a 1440p monitor with
281 window columns and 76 window lines.

Vimatrix.nvim uses the virtual text property of extended marks to print its
effect, which is a lot more performant than printing actual text to a buffer.

But if you are operating a machine with limited resources, use with caution
(e.g. lower the default fps and disable glitches).

### Recommendation for low-power systems

My testing suggests that it is not the calculating of droplet mutations but the
screen rendering that is most resource intensive. Therefore, if you must reduce
CPU usage, I recommend you focus on reducing the density of the droplets and
turning off glitches. The following settings have allowed me to reduce CPU
consumption on my system by over 50% compared to the above example.

```lua
-- e.g.
droplet = {
  max_size_offset = 5,
  timings = {
    max_fps = 15,
    fps_variance = 2,
    max_timeout = 200,
  },
  random = {
    body_to_tail = 10,
    head_to_glitch = -1,
    head_to_tail = 20,
    kill_head = 50,
    new_head = 80,
  },
},
```

> [!TIP]  
> You can use the `ignore_cells` callback option in the `window` settings to
> manage the amount of rendering. This is also quite effective at reducing CPU
> usage.

## 🛣 roadmap

As this was a toy project, I'm not making any promises, but I have been thinking
about the following features. If you would like to express your interest in one
of these, then let me know in the discussions, or if you see potential for more
cool stuff, feel free to open a feature request in the issues section.

- [ ] add support for manually opening vimatrix in split window
- [ ] add support for manually opening vimatrix in more than one window
- [ ] add support for gradient colourschemes
- [ ] add support for printing one or more lines of persistent text to the
      screen, like in [neo](https://github.com/st3w/neo/tree/main)
- [ ] add a some kind of performance mode that reduces CPU usage

## ⚠️ Known Limitations

### Terminal and Command-Line windows

By default, the screensaver functionality is blocked when switching to
`TERMINAL` or `COMMAND` mode.

This can be undone by setting the `auto_activation.screensaver.block_on_term`
and/or `.block_on_cmd_line` to false. However, do be aware of the following,
when you do.

When screensaver functionality is enabled within terminal and command-line
modes, some unintented, though relatively harmless, behaviour may occur when
leaving these windows open for a duration that exceeds the screensaver timeout.

The Vimatrix screensaver resets the timeout on cursor-movement or text
insertion, but (as far as I know) these or similar operations cannot be detected
within terminal applications or the command-line. This has two consequences:

1. The screensaver can be activated while these windows are open and actively
   used, since use of these windows does not reset the timer.
2. Cancelling the screensaver requires the window to be closed first, after
   which the usual cursor-movement or text insertion can be picked up by the
   autocommand that stops the screensaver.

By default, the Vimatrix floating window is configured with a z-index of 10,
which means that terminal windows, messages, and the command-line window run on
top of it.

This is intentional. If the screensaver is activated with these windows open, it
will be clearly visible and the user will know what to do.

Finally, the Vimatrix effect makes the cursor invisible, to have it not get in
the way of the visual effect. But this also affects the windows mentioned above.
If the screensaver initiates with these windows open, then the cursor in these
windows will no longer be visible.

In practice I have not found this scenario to to occur to me as I generally
don't leave neovim terminal applications unattended for extended periods of
time.

### blend

It appears that there is an
[open bug](https://github.com/neovim/neovim/issues/18576) in neovim that applies
a dark background colour to floating windows with a positive blend option. Some
users report that they are not experiencing the issue in their setups, so your
mileage may vary.
