module("luci.controller.admin.quotas", package.seeall)

local fs = require "nixio.fs"
local http = require "luci.http"
local disp = require "luci.dispatcher"

function index()
    entry({"admin", "quotas"}, alias("admin", "quotas", "template"), "Quotas", 60).index = true

    entry({"admin", "quotas", "status"}, template("admin_quotas/status"), "Status", 1)
    entry({"admin", "quotas", "settings"}, cbi("admin_quotas/settings"), "Settings", 2)
    entry({"admin", "quotas", "admin"}, template("admin_quotas/admin"), "Admin", 3)
    entry({"admin", "quotas", "update"}, template("admin_quotas/update"), "Update", 4)

    -- for admin page
    entry({"admin", "quotas", "stop"},  call("action_stop"), nil).leaf = true
    entry({"admin", "quotas", "start"}, call("action_start"), nil).leaf = true
    entry({"admin", "quotas", "reset"}, call("action_reset"), nil).leaf = true

    -- for update page
    entry({"admin", "quotas", "install"}, call("action_install"), nil).leaf = true
    entry({"admin", "quotas", "spinner"}, template("admin_quotas/spinner"), nil).leaf = true
    entry({"admin", "quotas", "check_cmd"}, template("admin_quotas/check_cmd"), nil).leaf = true
end

function action_stop()
	luci.sys.call("/etc/init.d/download-quotas stop;  sleep 5")
	luci.http.redirect(luci.dispatcher.build_url("admin/quotas/status"))
end

function action_start()
	luci.sys.call("/etc/init.d/download-quotas start;  sleep 5")
	luci.http.redirect(luci.dispatcher.build_url("admin/quotas/status"))
end

function action_reset()
	luci.sys.call("/etc/init.d/download-quotas reset;  sleep 5")
	luci.http.redirect(luci.dispatcher.build_url("admin/quotas/status"))
end

function log_cmd(cmd)
	luci.sys.call("rm /tmp/download_quotas/cmd.*")
	return luci.sys.call(cmd .. " > /tmp/download_quotas/cmd.log 2>&1 ; echo $? > /tmp/download_quotas/cmd.res")
end

function action_install()
	local done_url    = disp.build_url("admin/quotas/check_cmd")
	done_url = http.protocol.urlencode(done_url)
	local spinner_url = disp.build_url("admin/quotas/spinner") .. "?url=" .. done_url
	http.redirect(spinner_url)

        local file = http.formvalue("file")
        local md5 = luci.http.formvalue("md5")
	log_cmd("/usr/share/download_quotas/luci/install " .. file .. " " .. md5)
end
