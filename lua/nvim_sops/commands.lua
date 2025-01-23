local debug = require("nvim_sops.utils").debug
local sops = require("nvim_sops.sops")

local M = {}

M.file_encrypt = function()
	-- load lyaml
	local input_file = vim.fn.expand("%:p")
	local dir = vim.fn.expand("%:p:h")
	local project_path = vim.fn.fnamemodify(vim.fn.expand("%"), ":.")
	debug("decrypting", input_file)

	-- local sops_file = sops.find_sops_config_file(dir)
	-- local sops_config = parse_yaml_with_yq(sops_file)
	--
	-- debug('sops_config', sops_config)
	--
	-- if not sops_config or not sops_config.creation_rules then
	--   print('Invalid .sops.yaml file format, no creation_rules found')
	--   return nil
	-- end
	-- -- find the first creation_rule that matches the current file path
	-- for _, rule in ipairs(sops_config.creation_rules) do
	--   local escaped_pattern = escape_lua_pattern(rule.path_regex)
	--   local match = string.match(project_path, escaped_pattern)
	--
	--   if match then
	--     -- return rule.age
	--     print('matched rule: ' .. rule.path_regex .. ' with age key: ' .. rule.age)
	--     print('using escaped pattern: ' .. escaped_pattern)
	--   else
	--     print("Error matching path: " .. project_path .. " with regex: " .. rule.path_regex)
	--     print('using escaped pattern: ' .. escaped_pattern)
	--   end
	-- end
	--
	local binary = vim.g.nvim_sops_bin_path .. " "
	local sops_options = sops.get_sops_general_options()

	local envs = ""
	for key, value in pairs(sops_options.sopsGeneralEnvVars) do
		envs = envs .. key .. "=" .. value .. " "
	end
	local args = {
		"--encrypt",
		"--in-place",
	}

	local command = envs .. binary .. table.concat(args, " ") .. " " .. input_file
	debug(command)

	vim.fn.system(command)
	if vim.v.shell_error ~= 0 then
		print("Error encrypting file: " .. input_file)
	end

	-- reload the buffer to show the encrypted content
	vim.api.nvim_command("edit")
end

M.file_decrypt = function()
	local input_file = vim.fn.expand("%:p")
	debug("decrypting", input_file)
	local binary = vim.g.nvim_sops_bin_path .. " "
	local sops_options = sops.get_sops_general_options()

	local envs = ""
	for key, value in pairs(sops_options.sopsGeneralEnvVars) do
		envs = envs .. key .. "=" .. value .. " "
	end
	local args = {
		"--decrypt",
		"--in-place",
	}

	local command = envs .. binary .. table.concat(args, " ") .. " " .. input_file
	debug("Running command:", command)

	-- Capture both stdout and stderr
	local output = vim.fn.system(command)
	local error_code = vim.v.shell_error

	if error_code ~= 0 then
		-- Build error message
		local error_msg = {
			"Error decrypting file: " .. input_file,
			"Error code: " .. error_code,
			"Command output: " .. output,
		}

		-- Add debug information if debug mode is on
		if vim.g.nvim_sops_debug then
			table.insert(error_msg, "\nDebug information:")
			table.insert(error_msg, "Environment variables:")
			for key, value in pairs(sops_options.sopsGeneralEnvVars) do
				table.insert(error_msg, string.format("%s=%s", key, value))
			end
			table.insert(error_msg, "File path: " .. input_file)
		end

		-- Send to Neovim's notification system
		vim.notify(table.concat(error_msg, "\n"), vim.log.levels.ERROR, {
			title = "nvim-sops Decryption Error",
			timeout = 10000, -- 10 seconds
		})
		return
	end

	-- Only reload the buffer if decryption was successful
	vim.api.nvim_command("edit")
	vim.notify("File decrypted successfully", vim.log.levels.INFO, {
		title = "nvim-sops",
	})
end

return M
