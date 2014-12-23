connect("${wlAdminLogin}","${wlAdminPassword}", "${wlAdminUrl}")

try:
    cd('JDBCSystemResources/${dsJndiName}')
except Exception, e:
    edit()
    
    dsname="${dsJndiName}"
    server="${wlServerName}"
    cd("Servers/"+server)
    target=cmo
    cd("../..")

    startEdit()
    jdbcSR = create(dsname,"JDBCSystemResource")
    theJDBCResource = jdbcSR.getJDBCResource()
    theJDBCResource.setName("${dsJndiName}")

    connectionPoolParams = theJDBCResource.getJDBCConnectionPoolParams()
    connectionPoolParams.setTestTableName("SQL ${jdbcTestTableQuery}")

    dsParams = theJDBCResource.getJDBCDataSourceParams()
    dsParams.addJNDIName("${dsJndiName}")

    driverParams = theJDBCResource.getJDBCDriverParams()
    driverParams.setUrl("${dsUrl}")
    driverParams.setDriverName("${jdbcDriverClass}")

    driverParams.setPassword("${dsPassword}")
    driverProperties = driverParams.getProperties()

    proper = driverProperties.createProperty("user")
    proper.setValue("${dsUser}")

    jdbcSR.addTarget(target)

    save()
    activate(block="true")
else:
    print "Datasource ${dsJndiName} already exists"

