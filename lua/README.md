# txt2mp3.nvim

A high-quality, offline **Text-to-Speech (TTS)** plugin for Neovim. 

It converts your current visual selection into an MP3 file using **Piper**
(Neural Network Voices) and **Lame** (Encoding). The process runs
asynchronously, so it never freezes your editor.

## ✨ Features

* **High Quality:** Uses [Piper](https://github.com/rhasspy/piper) for human-sounding, neural network speech.
* **Offline:** No internet connection required after initial installation.
* **Asynchronous:** Conversions happen in the background using `vim.system`
(Neovim 0.10+).
* **Clean Output:** Pipes audio directly from generator to encoder, avoiding
temporary `.wav` files.
* **Zero Python Dependency:** Uses the standalone Piper binary.

## ⚡ Requirements

1.  **Neovim 0.10+** (Required for async `vim.system`).
2.  **Lame:** The MP3 encoder must be installed on your system.
    * Arch Linux: `sudo pacman -S lame`
    * Ubuntu/Debian: `sudo apt install lame`
    * MacOS: `brew install lame`
3.  **Piper:** The plugin can install this for you automatically (see below).

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
    local script = [[
      mkdir -p ~/piper
      cd ~/piper
      if [ ! -f piper ]; then
        echo "Downloading Piper..."
        wget -O piper.tar.gz [https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper_linux_x86_64.tar.gz](https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper_linux_x86_64.tar.gz)
        tar -xvf piper.tar.gz
        mv piper/* .
        rm -rf piper piper.tar.gz
      fi
      if [ ! -f voice.onnx ]; then
        echo "Downloading Voice Model..."
        wget -O voice.onnx [https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/lessac/medium/en_US-lessac-medium.onnx](https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/lessac/medium/en_US-lessac-medium.onnx)
        wget -O voice.onnx.json [https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json](https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json)
      fi
    ]]
    os.execute("bash -c '" .. script .. "'")
  end,

  config = function()
    require("txt2mp3").setup({
      output_dir = "~/Music",         -- Where to save the MP3s
      filename = "read_later.mp3",    -- Default filename
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

```lua
require("txt2mp3").setup({
  piper_dir   = vim.fn.expand("~/path/to/piper_folder"),
  -- Point specifically to the executable binary inside the folder
  piper_bin   = vim.fn.expand("~/path/to/piper_folder/piper"),
  voice_model = vim.fn.expand("~/path/to/voice.onnx"),
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
  piper_dir  = vim.fn.expand("~/piper"),
  piper_bin  = vim.fn.expand("~/piper/piper"),
  voice_model = vim.fn.expand("~/piper/voice.onnx"),
}
```

## 🔧 Troubleshooting

**Error: `is a directory`**

  * Ensure your `piper_bin` path points to the actual executable file, not the
  folder containing it.

**Error: `missing dependency: lame`**

  * Install Lame via your OS package manager (e.g., `sudo pacman -S lame`).

**Audio is too fast/slow**

  * You can edit the command in `lua/txt2mp3.lua` to include `--length_scale 1.1` (slower) or `0.9` (faster).

## 📄 License

MIT

```
```
