module("luci.controller.admin.quotas", package.seeall)

function index()
    entry({"admin", "quotas"}, alias("admin", "quotas", "template"), "Quotas", 60).index = true

    entry({"admin", "quotas", "status"}, template("admin_quotas/status"), "Status", 1)
    entry({"admin", "quotas", "update"}, template("admin_quotas/update"), "Update", 2)

    -- for update page
    entry({"admin", "quotas", "install"}, call("action_install"), nil).leaf = true
end

function action_install()
        local file = luci.http.formvalue("file")
	luci.http.prepare_content("text/plain")
	local r = luci.sys.call("/usr/share/download_quotas/luci/install " .. file)
	if r == 0 then
		luci.http.write("Success !")
        else
		luci.http.write("Failed ...")
	end
end
