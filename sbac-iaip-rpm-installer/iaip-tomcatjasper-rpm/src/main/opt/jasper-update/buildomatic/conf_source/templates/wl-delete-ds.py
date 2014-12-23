connect("${wlAdminLogin}","${wlAdminPassword}", "${wlAdminUrl}")

try:
    cd("JDBCSystemResources/${dsJndiName}")
    cd("/")
except Exception, e:
    print "Datasource ${dsJndiName} doesn't exist"
else:
    edit()
    startEdit()
    delete("${dsJndiName}","JDBCSystemResource")
    save()
    activate(block="true")
