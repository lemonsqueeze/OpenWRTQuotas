module("luci.controller.admin.quotas", package.seeall)

function index()
    entry({"admin", "quotas"}, alias("admin", "quotas", "template"), "Quotas", 60).index = true

    entry({"admin", "quotas", "status"}, template("admin_quotas/status"), "Status", 1)
end

