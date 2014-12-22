echo cleaning project ...
mvn clean
echo building project skiping Tests ...
mvn package -DskipTests
echo stopping tomee ... 
service tomee stop
echo cleaning up tomee ...
cd /opt/tomee/logs
# rm -r -f *.log
# rm -r -f *.txt
# rm -r -f *.out
rm -r -f /opt/tomee/work/Catalina/localhost/orca-sbac/
rm -r -f /opt/tomee/webapps/orca-sbac/
rm -r -f /opt/tomee/webapps/orca-sbac.war

echo copying artifact to tomee 
cd /git/sbac-iaip/java/target
mv ORCA-SBAC.war orca-sbac.war
cp orca-sbac.war /opt/tomee/webapps
echo starting tomee ...
# service tomee start
cd /opt/tomee/bin
./catalina.sh jpda start

echo tomee log ...
cd /opt/tomee/logs
tail -f -n200 /opt/tomee/logs/catalina.out


