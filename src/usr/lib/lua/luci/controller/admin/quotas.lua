module("luci.controller.admin.quotas", package.seeall)

local fs = require "nixio.fs"
local http = require "luci.http"
local disp = require "luci.dispatcher"

function index()
    entry({"admin", "quotas"}, alias("admin", "quotas", "template"), "Quotas", 60).index = true

    entry({"admin", "quotas", "status"}, template("admin_quotas/status"), "Status", 1)
    entry({"admin", "quotas", "update"}, template("admin_quotas/update"), "Update", 2)

    -- for update page
    entry({"admin", "quotas", "install"}, call("action_install"), nil).leaf = true
    entry({"admin", "quotas", "spinner"}, template("admin_quotas/spinner"), nil).leaf = true
    entry({"admin", "quotas", "check_cmd"}, template("admin_quotas/check_cmd"), nil).leaf = true
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
