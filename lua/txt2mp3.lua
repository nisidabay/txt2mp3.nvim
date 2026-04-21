local M = {}

local config = {
	output_dir = "~/Music",
	filename = "nvim_audio.mp3",

	-- PATHS FOR CLEAN INSTALL
	piper_dir = vim.fn.expand("~/piper/piper"), -- The folder containing .so libraries
	piper_bin = vim.fn.expand("~/piper/piper/piper"), -- The executable binary
	voice = nil, -- Voice key from Piper catalog (e.g., "en_US-lessac-medium")
	voice_model = vim.fn.expand("~/piper/voice.onnx"), -- Path to .onnx file (overrides voice if set)
}

function M.setup(user_opts)
	config = vim.tbl_deep_extend("force", config, user_opts or {})
end

function M.convert_selection()
	-- Check for lame
	if vim.fn.executable("lame") == 0 then
		vim.notify("❌ Missing dependency: lame", vim.log.levels.ERROR)
		return
	end

	-- Get Visual Selection
	local _, csrow, cscol, _ = unpack(vim.fn.getpos("'<"))
	local _, cerow, cecol, _ = unpack(vim.fn.getpos("'>"))

	if csrow == 0 then
		vim.notify("⚠️ Select text first!", vim.log.levels.WARN)
		return
	end

	local lines = vim.fn.getline(csrow, cerow)
	if #lines == 0 then
		return
	end

	if #lines == 1 then
		lines[1] = string.sub(lines[1], cscol, cecol)
	else
		lines[1] = string.sub(lines[1], cscol)
		lines[#lines] = string.sub(lines[#lines], 1, cecol)
	end

	local text = table.concat(lines, " "):gsub("[\r\n]", " "):gsub("%s+", " ")
	if text == "" then
		return
	end

	local safe_text = text:gsub("'", "'\\''")
	local output_path = vim.fn.expand(config.output_dir):gsub("/$", "") .. "/" .. config.filename

	vim.notify("🎙️ Converting...", vim.log.levels.INFO)

	-- COMMAND
	-- We set LD_LIBRARY_PATH so it finds the .so files
	-- Use voice_model if set (backwards compat), otherwise use voice key
	local model_arg = config.voice_model and ("--model " .. config.voice_model) or ("--voice " .. config.voice)
	local cmd = string.format(
		"export LD_LIBRARY_PATH=%s:$LD_LIBRARY_PATH; echo '%s' | %s %s --output_file - | lame -b 192 --quiet - '%s'",
		config.piper_dir,
		safe_text,
		config.piper_bin,
		model_arg,
		output_path
	)

	vim.system({ "bash", "-c", cmd }, { text = true }, function(obj)
		if obj.code == 0 then
			vim.schedule(function()
				vim.notify("✅ Saved: " .. output_path, vim.log.levels.INFO)
			end)
		else
			vim.schedule(function()
				vim.notify("❌ Error: " .. obj.stderr, vim.log.levels.ERROR)
			end)
		end
	end)
end

vim.api.nvim_create_user_command("TextToMp3", function()
	M.convert_selection()
end, { range = true })

return M
