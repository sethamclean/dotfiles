-- Drives nvim-dap in a running Neovim for the nvim-debug skill.
-- Call it as: luaeval("dofile(_A[1])(unpack(_A, 2))", [path, op, arg1, arg2]).
-- Every op returns one JSON string.
local dap = require("dap")
local bps = require("dap.breakpoints")

local KEY = "nvim-debug"
local WAIT_MS = 15000

local function session()
	return dap.session()
end

local function frame_info(s)
	local f = s and s.current_frame
	if not f then
		return nil
	end
	local path = f.source and f.source.path
	local text
	if path and vim.fn.filereadable(path) == 1 and f.line then
		text = vim.fn.readfile(path, "", f.line)[f.line]
	end
	return { name = f.name, line = f.line, path = path, text = text, id = f.id }
end

local function state(event, output)
	local s = session()
	return {
		event = event,
		output = output and #output > 0 and table.concat(output) or nil,
		session = s ~= nil,
		stopped = s ~= nil and s.stopped_thread_id ~= nil,
		thread = s and s.stopped_thread_id,
		frame = frame_info(s),
	}
end

-- Run action(), then block until the adapter reports a stop or the end of the
-- session, or until the timeout. Returns the resulting state.
local function act(action, timeout_ms)
	local event
	local output = {}
	local before = session() and session().current_frame
	local function set(name)
		return function()
			event = event or name
		end
	end
	dap.listeners.after.event_output[KEY] = function(_, body)
		if body.category ~= "telemetry" then
			output[#output + 1] = body.output
		end
	end
	dap.listeners.after.event_stopped[KEY] = set("stopped")
	dap.listeners.after.event_terminated[KEY] = set("terminated")
	dap.listeners.after.event_exited[KEY] = set("exited")
	local ok, err = pcall(action)
	if ok then
		vim.wait(timeout_ms or WAIT_MS, function()
			return event ~= nil
		end, 25)
	end
	if ok and event == "stopped" then
		-- The adapter sends the stack after the stop event; wait for a new frame.
		vim.wait(3000, function()
			local s = session()
			return s == nil or (s.current_frame ~= nil and s.current_frame ~= before)
		end, 25)
	end
	if ok and (event == "exited" or event == "terminated") then
		-- Program output can arrive just after the end of the session.
		vim.wait(500, function()
			return false
		end, 50)
	end
	dap.listeners.after.event_output[KEY] = nil
	dap.listeners.after.event_stopped[KEY] = nil
	dap.listeners.after.event_terminated[KEY] = nil
	dap.listeners.after.event_exited[KEY] = nil
	if not ok then
		return { error = tostring(err) }
	end
	return state(event or "timeout", output)
end

local function request(s, command, args)
	local done, err, resp
	s:request(command, args, function(e, r)
		err, resp, done = e, r, true
	end)
	vim.wait(5000, function()
		return done
	end, 20)
	if not done then
		return nil, "no reply to " .. command
	end
	if err then
		return nil, err.message or vim.inspect(err)
	end
	return resp
end

local function need_stopped()
	local s = session()
	if not s then
		return nil, { error = "no debug session" }
	end
	if not s.stopped_thread_id or not s.current_frame then
		return nil, { error = "program is running, not stopped" }
	end
	return s
end

local function variables(s, ref)
	local resp, err = request(s, "variables", { variablesReference = ref })
	if not resp then
		return nil, err
	end
	local out = {}
	for _, v in ipairs(resp.variables or {}) do
		out[#out + 1] = {
			name = v.name,
			value = v.value,
			type = v.type,
			ref = (v.variablesReference or 0) > 0 and v.variablesReference or nil,
		}
	end
	return out
end

local function parse_location(spec)
	local path, line = spec:match("^(.*):(%d+)$")
	if not path then
		return nil, nil, "expected path:line, got " .. spec
	end
	local bufnr = vim.fn.bufadd(vim.fn.fnamemodify(path, ":p"))
	vim.fn.bufload(bufnr)
	return bufnr, tonumber(line)
end

local function sync_breakpoints(bufnr)
	local s = session()
	if s then
		s:set_breakpoints(bps.get(bufnr))
	end
end

local ops = {}

function ops.state()
	return state("state")
end

function ops.configs(filetype)
	local list = dap.configurations[filetype or vim.bo.filetype] or {}
	local out = {}
	for _, c in ipairs(list) do
		out[#out + 1] = { name = c.name, request = c.request, type = c.type }
	end
	return { filetype = filetype or vim.bo.filetype, configs = out }
end

function ops.run(name, filetype)
	local list = dap.configurations[filetype or vim.bo.filetype] or {}
	for _, c in ipairs(list) do
		if c.name == name then
			return act(function()
				dap.run(c)
			end)
		end
	end
	return { error = "no configuration named " .. tostring(name), available = ops.configs(filetype).configs }
end

function ops.continue()
	return act(dap.continue)
end
function ops.over()
	return act(dap.step_over)
end
function ops.into()
	return act(dap.step_into)
end
function ops.out()
	return act(dap.step_out)
end
function ops.pause()
	return act(dap.pause)
end

function ops.terminate()
	return act(dap.terminate)
end

function ops.up()
	dap.up()
	return state("frame")
end
function ops.down()
	dap.down()
	return state("frame")
end

function ops.stack()
	local s, e = need_stopped()
	if not s then
		return e
	end
	local resp, err = request(s, "stackTrace", { threadId = s.stopped_thread_id, levels = 20 })
	if not resp then
		return { error = err }
	end
	local out = {}
	for i, f in ipairs(resp.stackFrames or {}) do
		out[i] = { name = f.name, line = f.line, path = f.source and f.source.path, current = f.name == s.current_frame.name and f.line == s.current_frame.line }
	end
	return { frames = out }
end

function ops.locals()
	local s, e = need_stopped()
	if not s then
		return e
	end
	local resp, err = request(s, "scopes", { frameId = s.current_frame.id })
	if not resp then
		return { error = err }
	end
	local out = {}
	for _, sc in ipairs(resp.scopes or {}) do
		if not sc.expensive then
			local vars, verr = variables(s, sc.variablesReference)
			out[#out + 1] = { scope = sc.name, variables = vars, error = verr }
		end
	end
	return { scopes = out }
end

function ops.expand(ref)
	local s, e = need_stopped()
	if not s then
		return e
	end
	local vars, err = variables(s, tonumber(ref))
	return vars and { variables = vars } or { error = err }
end

function ops.eval(expression)
	local s, e = need_stopped()
	if not s then
		return e
	end
	local resp, err = request(s, "evaluate", {
		expression = expression,
		frameId = s.current_frame.id,
		context = "repl",
	})
	if not resp then
		return { error = err }
	end
	return {
		result = resp.result,
		type = resp.type,
		ref = (resp.variablesReference or 0) > 0 and resp.variablesReference or nil,
	}
end

-- path:line [condition]
ops["break"] = function(spec, condition)
	local bufnr, line, err = parse_location(spec)
	if not bufnr then
		return { error = err }
	end
	bps.set({ condition = condition ~= "" and condition or nil }, bufnr, line)
	sync_breakpoints(bufnr)
	return ops.breakpoints()
end

function ops.logpoint(spec, message)
	local bufnr, line, err = parse_location(spec)
	if not bufnr then
		return { error = err }
	end
	bps.set({ log_message = message }, bufnr, line)
	sync_breakpoints(bufnr)
	return ops.breakpoints()
end

function ops.unbreak(spec)
	local bufnr, line, err = parse_location(spec)
	if not bufnr then
		return { error = err }
	end
	bps.remove(bufnr, line)
	sync_breakpoints(bufnr)
	return ops.breakpoints()
end

function ops.clear()
	dap.clear_breakpoints()
	return ops.breakpoints()
end

function ops.breakpoints()
	local out = {}
	for bufnr, list in pairs(bps.get()) do
		for _, b in ipairs(list) do
			out[#out + 1] = {
				path = vim.api.nvim_buf_get_name(bufnr),
				line = b.line,
				condition = b.condition,
				log = b.logMessage,
			}
		end
	end
	table.sort(out, function(a, b)
		return a.path == b.path and a.line < b.line or a.path < b.path
	end)
	return { breakpoints = out }
end

-- comma-separated adapter filters, e.g. "raised,uncaught" for debugpy
function ops.exceptions(filters)
	dap.set_exception_breakpoints(filters ~= "" and vim.split(filters, ",") or {})
	return { exception_filters = filters }
end

return function(op, ...)
	local fn = ops[op]
	if not fn then
		return vim.json.encode({ error = "unknown op " .. tostring(op) })
	end
	local ok, result = pcall(fn, ...)
	return vim.json.encode(ok and result or { error = tostring(result) })
end
