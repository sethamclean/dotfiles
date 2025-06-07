vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Execute visually selected text and write output to the current buffer
vim.keymap.set("v", "<leader>x", function()
	-- Save current mode and exit visual
	local mode = vim.fn.mode()
	vim.cmd('normal! gv"xy') -- yank selection to register x
	local command = vim.fn.getreg("x")
	-- Run command in zsh
	local output = vim.fn.systemlist("zsh -c " .. vim.fn.shellescape(command))
	-- Get selection range (after yanking, '< and '> are correct)
	local start_line = vim.fn.line("'<")
	local end_line = vim.fn.line("'>")
	-- Insert output below selection
	vim.api.nvim_buf_set_lines(0, end_line, end_line, false, output)
end, { desc = "Execute selection in shell and insert output below", noremap = true })

-- Execute visually selected text and show output in horizontal split
vim.keymap.set("v", "<leader>X", function()
	-- Get the selected text
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local lines = vim.fn.getline(start_pos[2], end_pos[2])
	local text = table.concat(lines, "\n"):gsub("^%s*(.-)%s*$", "%1") -- trim whitespace

	-- Create a new horizontal split below and set height
	vim.cmd("below new")
	vim.cmd("resize 10") -- Set height to 10 lines

	-- Debug info
	local debug_info = {
		"Command to execute: " .. text,
		"Working directory: " .. vim.fn.getcwd(),
		"---Output---",
	}

	-- Set buffer options
	vim.bo.buftype = "nofile"
	vim.bo.bufhidden = "wipe"
	vim.bo.swapfile = false

	-- Execute the command and get output
	local success, output = pcall(function()
		-- Always run with shell=true to ensure consistent shell interpretation
		return vim.fn.systemlist(text, nil, true)
	end)

	if not success then
		output = { "Error executing command:", tostring(output) }
	end

	-- Combine debug info with output
	local final_output = vim.list_extend(debug_info, output)

	-- Put the output in the new buffer
	vim.api.nvim_buf_set_lines(0, 0, -1, false, final_output)
end, { noremap = true, silent = true, desc = "Execute selected text in split" })
