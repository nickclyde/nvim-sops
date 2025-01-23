local debug = require("nvim_sops.utils").debug
local M = {}

M.get_sops_general_options = function()
	local awsProfile = vim.g.nvim_sops_defaults_aws_profile
	local gcpCredentialsPath = vim.g.nvim_sops_defaults_gcp_credentials_path
	local ageKeyFile = vim.g.nvim_sops_defaults_age_key_file

	-- If age key file isn't set, look for age.key in the current working directory
	if not ageKeyFile then
		local cwd = vim.fn.getcwd()
		local default_age_key = cwd .. "/age.key"
		if vim.fn.filereadable(default_age_key) == 1 then
			debug("Found default age key file at:", default_age_key)
			ageKeyFile = default_age_key
		else
			debug("No age key file found in current directory:", default_age_key)
		end
	end

	local sopsGeneralEnvVars = {}

	if awsProfile then
		sopsGeneralEnvVars.AWS_PROFILE = awsProfile
	end

	if gcpCredentialsPath then
		sopsGeneralEnvVars.GOOGLE_APPLICATION_CREDENTIALS = gcpCredentialsPath
	end

	if ageKeyFile then
		sopsGeneralEnvVars.SOPS_AGE_KEY_FILE = ageKeyFile
		debug("Using age key file:", ageKeyFile)
	else
		debug("No age key file found or specified")
	end

	-- Log all environment variables in debug mode
	for key, value in pairs(sopsGeneralEnvVars) do
		debug("sops option: " .. key .. " = " .. value)
	end

	return {
		sopsGeneralEnvVars = sopsGeneralEnvVars,
	}
end

return M
