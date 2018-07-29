local http = require "luci.http"
local sys = require "luci.sys"
local fs  = require "nixio.fs"

m = Map("download_quotas", "Quotas Settings") -- We want to edit the uci config file /etc/config/download_quotas

s = m:section(TypedSection, "guests", "Guests")
s.anonymous = true

s:option(Value, "download_quota",  "Download Quota", "How much data (Mb) each guest can download before being throttled.") -- This will give a simple textbox
s:option(Value, "speed_normal",    "Max Speed (Normal)", "Max download speed for each device (k/s)")
s:option(Value, "speed_overquota", "Max Speed (Overquota)", "Max download speed once overquota (k/s).")

function spinner_redirect(url)
	url = http.protocol.urlencode(url)
	local spinner = luci.dispatcher.build_url("admin/quotas/spinner") .. "?url=" .. url
	http.redirect(spinner)
end

-- Called on "Save & Apply"
function m.on_commit(map)
	spinner_redirect(luci.dispatcher.build_url("admin/quotas/status"))
	sys.call("/etc/init.d/download-quotas stop; /etc/init.d/download-quotas start")
end

return m -- Returns the map
