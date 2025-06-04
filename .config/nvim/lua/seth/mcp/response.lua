-- response.lua
-- Shared response object for MCP servers

local Response = {}
Response.__index = Response

function Response:new()
  local o = {}
  setmetatable(o, self)
  o.body = nil
  o.mime_type = nil
  o.is_error = nil
  return o
end

function Response:text(content, mime_type)
  self.body = content
  self.mime_type = mime_type or "text/plain"
  return self
end

function Response:json(content)
  self.body = vim.fn.json_encode(content)
  self.mime_type = "application/json"
  return self
end

function Response:error(msg)
  self.body = msg
  self.mime_type = "text/plain"
  self.is_error = true
  return self:send()
end

function Response:send()
  return {
    body = self.body,
    mime_type = self.mime_type,
    is_error = self.is_error,
  }
end

-- Decorator to guard request and response objects
function Response.with_request_response_guard(handler, logger)
  return function(req, res)
    -- Validate request
    if type(req) ~= "table" or type(req.params) ~= "table" then
      if logger then logger("Invalid request object", vim.log.levels.ERROR) end
      if res and type(res.error) == "function" then
        return res:error("Invalid request object: missing or malformed 'params' field")
      else
        return { body = "Invalid request object: missing or malformed 'params' field", mime_type = "text/plain", is_error = true }
      end
    end

    -- Validate response
    if type(res) ~= "table" or type(res.json) ~= "function" or type(res.text) ~= "function" then
      if logger then logger("Invalid response object, aborting handler", vim.log.levels.ERROR) end
      -- Do not create a new response object, just log and return early
      return { body = "Internal error: response object is missing or invalid", mime_type = "text/plain", is_error = true }
    end

    local ok, result = pcall(handler, req, res)
    if not ok then
      if logger then logger("Handler error: " .. tostring(result), vim.log.levels.ERROR) end
      if res and type(res.error) == "function" then
        return res:error("Internal error in handler: " .. tostring(result))
      else
        return { body = "Internal error in handler: " .. tostring(result), mime_type = "text/plain", is_error = true }
      end
    end
    return result
  end
end

return Response

