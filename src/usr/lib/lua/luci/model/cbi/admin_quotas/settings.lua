local http = require "luci.http"
local sys = require "luci.sys"
local fs  = require "nixio.fs"

m = Map("download_quotas", "Quotas Settings") -- We want to edit the uci config file /etc/config/download_quotas

s = m:section(TypedSection, "guests", "Guests")
s.anonymous = true

s:option(Value, "download_quota",  "Download Quota", "How much data (Mb) each guest can download before being throttled.") -- This will give a simple textbox
s:option(Value, "speed_normal",    "Max Speed (Normal)", "Max download speed for each device (k/s)")
s:option(Value, "speed_overquota", "Max Speed (Overquota)", "Max download speed once overquota (k/s).")


s = m:section(TypedSection, "global", "Global")
s.anonymous = true

s:option(Flag, "metered_wifi",   "Metered Wifi", "Ask devices to reduce data usage (android devices only).")
s:option(Flag, "block_android_updates",   "Block Android Updates", "WARNING: breaks google apps also: youtube, maps ...")
s:option(Flag, "night_disable",  "Disable at night ?", "Turn off quotas between midnight - 6:00 ?")
s:option(Value, "lan_interface",    "LAN Interface", "'br-lan' usually for openwrt.")


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
