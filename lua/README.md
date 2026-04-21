# txt2mp3.nvim

A high-quality, offline **Text-to-Speech (TTS)** plugin for Neovim.

It converts your current visual selection into an MP3 file using **Piper**
(Neural Network Voices) and **Lame** (Encoding). The process runs
asynchronously, so it never freezes your editor.

## ✨ Features

* **High Quality:** Uses [Piper](https://github.com/rhasspy/piper) for human-sounding, neural network speech.
* **Offline:** No internet connection required after initial installation.
* **Asynchronous:** Conversions happen in the background using `vim.system` (Neovim 0.10+).
* **Clean Output:** Pipes audio directly from generator to encoder, avoiding
temporary `.wav` files.
* **Zero Python Dependency:** Uses the standalone Piper binary.

## ⚡ Requirements

1. **Neovim 0.10+** (Required for async `vim.system`).
2. **Lame:** The MP3 encoder must be installed on your system.
    * Arch Linux: `sudo pacman -S lame`
    * Ubuntu/Debian: `sudo apt install lame`
    * MacOS: `brew install lame`
3. **Curl or Wget:** Required for the plugin to automatically download Piper
   during installation.
4. **Piper:** The plugin can install this for you automatically (see below).

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim) (Recommended)

This method will automatically download the Piper binary and a high-quality
voice model (US English Lessac) into `~/piper` the first time you install the
plugin.

```lua
{
  "nisidabay/txt2mp3.nvim",
  cmd = { "TextToMp3" },
  
  -- The build script handles the dependency download automatically
  build = function()
    -- 1. Get the ABSOLUTE path to avoid "~" expansion issues
    local home = vim.fn.expand("~")
    local piper_dir = home .. "/piper"

    -- 2. Create a script to download dependencies (supports wget and curl)
    local script = string.format([[
      set -e
      mkdir -p "%s"
      cd "%s"

      # Detect downloader
      if command -v wget >/dev/null 2>&1; then
          DL_CMD="wget -O"
      elif command -v curl >/dev/null 2>&1; then
          DL_CMD="curl -L -o"
      else
          echo "❌ Error: Neither wget nor curl found."
          exit 1
      fi

      # Download Piper if missing
      if [ ! -f piper/piper ]; then
        echo "⬇️ Downloading Piper..."
        $DL_CMD piper.tar.gz [https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper_linux_x86_64.tar.gz](https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper_linux_x86_64.tar.gz)
        tar -xf piper.tar.gz
        rm piper.tar.gz
      fi

      # Download Voice if missing
      if [ ! -f voice.onnx ]; then
        echo "⬇️ Downloading Voice Model..."
        $DL_CMD voice.onnx [https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/lessac/medium/en_US-lessac-medium.onnx](https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/lessac/medium/en_US-lessac-medium.onnx)
        $DL_CMD voice.onnx.json [https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json](https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json)
      fi
    ]], piper_dir, piper_dir)

    -- 3. Run and capture output for debugging
    local out = vim.fn.system(script)
    if vim.v.shell_error ~= 0 then
      vim.notify("❌ txt2mp3 Build Failed:\n" .. out, vim.log.levels.ERROR)
    end
  end,

  config = function()
    require("txt2mp3").setup({
      output_dir = "~/Music",         -- Where to save the MP3s
      filename = "read_later.mp3",    -- Default filename
      
      -- Point to the extracted binary (Note: extraction creates 'piper/piper/' structure)
      piper_bin = vim.fn.expand("~/piper/piper/piper"),
      piper_dir = vim.fn.expand("~/piper/piper"), -- Directory with .so libraries
      voice_model = vim.fn.expand("~/piper/voice.onnx"), -- Path to .onnx file
      -- voice = "en_US-lessac-medium", -- Alternative: use voice key from Piper catalog
    })

    -- Optional: Keybinding
    vim.keymap.set("v", "<leader>p", ":TextToMp3<CR>", { noremap = true, silent = true, desc = "Convert to MP3" })
  end,
}
````

### Manual Installation

If you prefer to manage Piper yourself:

1.  Download **Piper** and a **Voice Model** (`.onnx` and `.onnx.json`).
2.  Place them in a folder (e.g., `~/piper`).
3.  Install the plugin via your package manager.
4.  Point the configuration to your files:

<!-- end list -->

```lua
require("txt2mp3").setup({
  piper_dir = vim.fn.expand("~/path/to/piper/piper"), -- Directory with .so libraries
  piper_bin = vim.fn.expand("~/path/to/piper/piper/piper"), -- Executable binary
  voice_model = vim.fn.expand("~/path/to/voice.onnx"),
  -- voice = "en_US-lessac-medium", -- Alternative: voice key from catalog
})
```

## 🚀 Usage

1.  Open any text file in Neovim.
2.  Enter **Visual Mode** (`v` or `V`) and select the text you want to listen to.
3.  Run the command:
    ```vim
    :TextToMp3
    ```
4.  You will see a notification: `🎙️ Converting...`
5.  When finished, a notification will confirm: `✅ Saved: ~/Music/read_later.mp3`

## ⚙️ Configuration

The default configuration (if you pass nothing to setup) assumes the automatic
installation path:

```lua
{
  output_dir = "~/Music",
  filename = "nvim_audio.mp3",
  piper_dir = vim.fn.expand("~/piper/piper"), -- Directory with .so libraries
  piper_bin = vim.fn.expand("~/piper/piper/piper"), -- Executable binary
  voice = nil, -- Voice key from Piper catalog (e.g., "en_US-lessac-medium")
  voice_model = vim.fn.expand("~/piper/voice.onnx"), -- Path to .onnx (overrides voice)
}
```

### Voice Configuration

You can configure the voice in two ways:

1. **Voice Key** (recommended for Piper catalog voices):
   ```lua
   voice = "en_US-lessac-medium"  -- Uses Piper's built-in voice catalog
   ```

2. **Voice Model Path** (backwards compatible, custom voice files):
   ```lua
   voice_model = vim.fn.expand("~/piper/voice.onnx")  -- Direct path to .onnx file
   ```

If both are set, `voice_model` takes precedence.

## 🔧 Troubleshooting

**Piper folder is empty / Plugin not working**

  * If the `~/piper` folder is empty or the installation didn't run
  automatically, you can force Lazy to rebuild the plugin dependencies by
  running:

    ```vim
    :Lazy build txt2mp3.nvim
    ```

**Error: `is a directory`**

  * Ensure your `piper_bin` path points to the actual executable file, not the
  folder containing it.

**Error: `missing dependency: lame`**

  * Install Lame via your OS package manager (e.g., `sudo pacman -S lame`).

**Audio is too fast/slow**

  * You can edit the command in `lua/txt2mp3.lua` to include `--length_scale
  1.1` (slower) or `0.9` (faster).

## 📄 License

MIT

### Third-Party Licenses

This plugin orchestrates the use of external binaries. Please respect their
respective licenses:

  * **Piper:** [MIT License](https://github.com/rhasspy/piper/blob/master/LICENSE.md).
  * **Lame:** [LGPL License](https://lame.sourceforge.io/about.php).

<!-- end list -->

```
```
