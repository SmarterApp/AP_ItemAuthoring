declare
	cursor session_info is 
		select s.sid, s.serial#, p.spid from v$session s, v$process p where s.username = '${dbUsername}' and p.addr (+) = s.paddr;
	sess_inf_rec session_info%ROWTYPE;

begin
	open session_info;
	loop
		fetch session_info into sess_inf_rec;
		exit when session_info%NOTFOUND;

		execute immediate 'alter system kill session '||chr(39)||sess_inf_rec.sid||','||sess_inf_rec.serial#||chr(39);

	end loop;
	close session_info;
end;
/
