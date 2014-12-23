--# Comments from the original SQL Server Quartz file: 
--#
--# thanks to George Papastamatopoulos for submitting this ... and Marko Lahma for
--# updating it.
--#
--# In your Quartz properties file, you'll need to set 
--# org.quartz.jobStore.driverDelegateClass = org.quartz.impl.jdbcjobstore.MSSQLDelegate
--#
--# you shouse enter your DB instance's name on the next line in place of "enter_db_name_here"
--#
--#
--# From a helpful (but anonymous) Quartz user:
--#
--# Regarding this error message:  
--#
--#     [Microsoft][SQLServer 2000 Driver for JDBC]Can't start a cloned connection while in manual transaction mode.
--#
--#
--#     I added "SelectMethod=cursor;" to my Connection URL in the config file. 
--#     It Seems to work, hopefully no side effects.
--#
--#		example:
--#		"jdbc:microsoft:sqlserver://dbmachine:1433;SelectMethod=cursor"; 
--#
--# Another user has pointed out that you will probably need to use the 
--# JTDS driver
--#

--
-- Comments from Jaspersoft: 
--
--
-- 2012-05-23: tkavanagh
--             In the switch from quartz 1.5 to 2.1.2, we have to handle the
--             table and column size changes carefully because of existing
--             JRS customers who will be upgrading from older JRS (and thus
--             older quartz). If column sizes were made larger in quartz
--             2.1.2, we are ignoring this and leaving the col size the same.
--             So, for instance, if qrtz_job_details.JOB_NAME was increased
--             to (200) in 2.1.2, I explicitly set it to (80) which is what it
--             was in quartz 1.5.
--             Additional changes from original 2.1.2 (and 1.5) schema
--             - The original quartz schema for sql server used VARCHAR for
--               all the string columns. JRS fully support internationalization
--               so all string columns are changed to NVARCHAR. 
--             - This change dates back to the original JRS port to sql server.  
--
--
-- 2012-03-22: thorick:
--             create separate drop ddl to keep drop out of the create script
--             run only 'create' by mistake and nothing bad will happen
--             not so with DROP !
--


CREATE TABLE [dbo].[QRTZ_CALENDARS] (
  [SCHED_NAME] [NVARCHAR] (100)  NOT NULL ,
  [CALENDAR_NAME] [NVARCHAR] (80)  NOT NULL ,
  [CALENDAR] [IMAGE] NOT NULL
) ON [PRIMARY]

CREATE TABLE [dbo].[QRTZ_CRON_TRIGGERS] (
  [SCHED_NAME] [NVARCHAR] (100)  NOT NULL ,
  [TRIGGER_NAME] [NVARCHAR] (80)  NOT NULL ,
  [TRIGGER_GROUP] [NVARCHAR] (80)  NOT NULL ,
  [CRON_EXPRESSION] [NVARCHAR] (80)  NOT NULL ,
  [TIME_ZONE_ID] [NVARCHAR] (80) 
) ON [PRIMARY]

CREATE TABLE [dbo].[QRTZ_FIRED_TRIGGERS] (
  [SCHED_NAME] [NVARCHAR] (100)  NOT NULL ,
  [ENTRY_ID] [NVARCHAR] (95)  NOT NULL ,
  [TRIGGER_NAME] [NVARCHAR] (80)  NOT NULL ,
  [TRIGGER_GROUP] [NVARCHAR] (80)  NOT NULL ,
  [INSTANCE_NAME] [NVARCHAR] (80)  NOT NULL ,
  [FIRED_TIME] [BIGINT] NOT NULL ,
  [PRIORITY] [INTEGER] NOT NULL ,
  [STATE] [NVARCHAR] (16)  NOT NULL,
  [JOB_NAME] [NVARCHAR] (80)  NULL ,
  [JOB_GROUP] [NVARCHAR] (80)  NULL ,
  [IS_NONCONCURRENT] [NVARCHAR] (1)  NULL ,
  [REQUESTS_RECOVERY] [NVARCHAR] (1)  NULL 
) ON [PRIMARY]

CREATE TABLE [dbo].[QRTZ_PAUSED_TRIGGER_GRPS] (
  [SCHED_NAME] [NVARCHAR] (100)  NOT NULL ,
  [TRIGGER_GROUP] [NVARCHAR] (80)  NOT NULL
) ON [PRIMARY]

CREATE TABLE [dbo].[QRTZ_SCHEDULER_STATE] (
  [SCHED_NAME] [NVARCHAR] (100)  NOT NULL ,
  [INSTANCE_NAME] [NVARCHAR] (80)  NOT NULL ,
  [LAST_CHECKIN_TIME] [BIGINT] NOT NULL ,
  [CHECKIN_INTERVAL] [BIGINT] NOT NULL
) ON [PRIMARY]

CREATE TABLE [dbo].[QRTZ_LOCKS] (
  [SCHED_NAME] [NVARCHAR] (100)  NOT NULL ,
  [LOCK_NAME] [NVARCHAR] (40)  NOT NULL 
) ON [PRIMARY]

CREATE TABLE [dbo].[QRTZ_JOB_DETAILS] (
  [SCHED_NAME] [NVARCHAR] (100)  NOT NULL ,
  [JOB_NAME] [NVARCHAR] (80)  NOT NULL ,
  [JOB_GROUP] [NVARCHAR] (80)  NOT NULL ,
  [DESCRIPTION] [NVARCHAR] (120) NULL ,
  [JOB_CLASS_NAME] [NVARCHAR] (128)  NOT NULL ,
  [IS_DURABLE] [NVARCHAR] (1)  NOT NULL ,
  [IS_NONCONCURRENT] [NVARCHAR] (1)  NOT NULL ,
  [IS_UPDATE_DATA] [NVARCHAR] (1)  NOT NULL ,
  [REQUESTS_RECOVERY] [NVARCHAR] (1)  NOT NULL ,
  [JOB_DATA] [IMAGE] NULL
) ON [PRIMARY]

CREATE TABLE [dbo].[QRTZ_SIMPLE_TRIGGERS] (
  [SCHED_NAME] [NVARCHAR] (100)  NOT NULL ,
  [TRIGGER_NAME] [NVARCHAR] (80)  NOT NULL ,
  [TRIGGER_GROUP] [NVARCHAR] (80)  NOT NULL ,
  [REPEAT_COUNT] [BIGINT] NOT NULL ,
  [REPEAT_INTERVAL] [BIGINT] NOT NULL ,
  [TIMES_TRIGGERED] [BIGINT] NOT NULL
) ON [PRIMARY]

CREATE TABLE [dbo].[QRTZ_SIMPROP_TRIGGERS] (
  [SCHED_NAME] [NVARCHAR] (100)  NOT NULL ,
  [TRIGGER_NAME] [NVARCHAR] (80)  NOT NULL ,
  [TRIGGER_GROUP] [NVARCHAR] (80)  NOT NULL ,
  [STR_PROP_1] [NVARCHAR] (512) NULL,
  [STR_PROP_2] [NVARCHAR] (512) NULL,
  [STR_PROP_3] [NVARCHAR] (512) NULL,
  [INT_PROP_1] [INT] NULL,
  [INT_PROP_2] [INT] NULL,
  [LONG_PROP_1] [BIGINT] NULL,
  [LONG_PROP_2] [BIGINT] NULL,
  [DEC_PROP_1] [NUMERIC] (13,4) NULL,
  [DEC_PROP_2] [NUMERIC] (13,4) NULL,
  [BOOL_PROP_1] [NVARCHAR] (1) NULL,
  [BOOL_PROP_2] [NVARCHAR] (1) NULL,
) ON [PRIMARY]

CREATE TABLE [dbo].[QRTZ_BLOB_TRIGGERS] (
  [SCHED_NAME] [NVARCHAR] (100)  NOT NULL ,
  [TRIGGER_NAME] [NVARCHAR] (80)  NOT NULL ,
  [TRIGGER_GROUP] [NVARCHAR] (80)  NOT NULL ,
  [BLOB_DATA] [IMAGE] NULL
) ON [PRIMARY]

CREATE TABLE [dbo].[QRTZ_TRIGGERS] (
  [SCHED_NAME] [NVARCHAR] (100)  NOT NULL ,
  [TRIGGER_NAME] [NVARCHAR] (80)  NOT NULL ,
  [TRIGGER_GROUP] [NVARCHAR] (80)  NOT NULL ,
  [JOB_NAME] [NVARCHAR] (80)  NOT NULL ,
  [JOB_GROUP] [NVARCHAR] (80)  NOT NULL ,
  [DESCRIPTION] [NVARCHAR] (120) NULL ,
  [NEXT_FIRE_TIME] [BIGINT] NULL ,
  [PREV_FIRE_TIME] [BIGINT] NULL ,
  [PRIORITY] [INTEGER] NULL ,
  [TRIGGER_STATE] [NVARCHAR] (16)  NOT NULL ,
  [TRIGGER_TYPE] [NVARCHAR] (8)  NOT NULL ,
  [START_TIME] [BIGINT] NOT NULL ,
  [END_TIME] [BIGINT] NULL ,
  [CALENDAR_NAME] [NVARCHAR] (80)  NULL ,
  [MISFIRE_INSTR] [SMALLINT] NULL ,
  [JOB_DATA] [IMAGE] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[QRTZ_CALENDARS] WITH NOCHECK ADD
  CONSTRAINT [PK_QRTZ_CALENDARS] PRIMARY KEY  CLUSTERED
  (
    [SCHED_NAME],
    [CALENDAR_NAME]
  )  ON [PRIMARY]

ALTER TABLE [dbo].[QRTZ_CRON_TRIGGERS] WITH NOCHECK ADD
  CONSTRAINT [PK_QRTZ_CRON_TRIGGERS] PRIMARY KEY  CLUSTERED
  (
    [SCHED_NAME],
    [TRIGGER_NAME],
    [TRIGGER_GROUP]
  )  ON [PRIMARY]

ALTER TABLE [dbo].[QRTZ_FIRED_TRIGGERS] WITH NOCHECK ADD
  CONSTRAINT [PK_QRTZ_FIRED_TRIGGERS] PRIMARY KEY  CLUSTERED
  (
    [SCHED_NAME],
    [ENTRY_ID]
  )  ON [PRIMARY]

ALTER TABLE [dbo].[QRTZ_PAUSED_TRIGGER_GRPS] WITH NOCHECK ADD
  CONSTRAINT [PK_QRTZ_PAUSED_TRIGGER_GRPS] PRIMARY KEY  CLUSTERED
  (
    [SCHED_NAME],
    [TRIGGER_GROUP]
  )  ON [PRIMARY]

ALTER TABLE [dbo].[QRTZ_SCHEDULER_STATE] WITH NOCHECK ADD
  CONSTRAINT [PK_QRTZ_SCHEDULER_STATE] PRIMARY KEY  CLUSTERED
  (
    [SCHED_NAME],
    [INSTANCE_NAME]
  )  ON [PRIMARY]

ALTER TABLE [dbo].[QRTZ_LOCKS] WITH NOCHECK ADD
  CONSTRAINT [PK_QRTZ_LOCKS] PRIMARY KEY  CLUSTERED
  (
    [SCHED_NAME],
    [LOCK_NAME]
  )  ON [PRIMARY]

ALTER TABLE [dbo].[QRTZ_JOB_DETAILS] WITH NOCHECK ADD
  CONSTRAINT [PK_QRTZ_JOB_DETAILS] PRIMARY KEY  CLUSTERED
  (
    [SCHED_NAME],
    [JOB_NAME],
    [JOB_GROUP]
  )  ON [PRIMARY]

ALTER TABLE [dbo].[QRTZ_SIMPLE_TRIGGERS] WITH NOCHECK ADD
  CONSTRAINT [PK_QRTZ_SIMPLE_TRIGGERS] PRIMARY KEY  CLUSTERED
  (
    [SCHED_NAME],
    [TRIGGER_NAME],
    [TRIGGER_GROUP]
  )  ON [PRIMARY]

ALTER TABLE [dbo].[QRTZ_SIMPROP_TRIGGERS] WITH NOCHECK ADD
  CONSTRAINT [PK_QRTZ_SIMPROP_TRIGGERS] PRIMARY KEY  CLUSTERED
  (
    [SCHED_NAME],
    [TRIGGER_NAME],
    [TRIGGER_GROUP]
  )  ON [PRIMARY]

ALTER TABLE [dbo].[QRTZ_TRIGGERS] WITH NOCHECK ADD
  CONSTRAINT [PK_QRTZ_TRIGGERS] PRIMARY KEY  CLUSTERED
  (
    [SCHED_NAME],
    [TRIGGER_NAME],
    [TRIGGER_GROUP]
  )  ON [PRIMARY]

ALTER TABLE [dbo].[QRTZ_CRON_TRIGGERS] ADD
  CONSTRAINT [FK_QRTZ_CRON_TRIGGERS_QRTZ_TRIGGERS] FOREIGN KEY
  (
    [SCHED_NAME],
    [TRIGGER_NAME],
    [TRIGGER_GROUP]
  ) REFERENCES [dbo].[QRTZ_TRIGGERS] (
    [SCHED_NAME],
    [TRIGGER_NAME],
    [TRIGGER_GROUP]
  ) ON DELETE CASCADE

ALTER TABLE [dbo].[QRTZ_SIMPLE_TRIGGERS] ADD
  CONSTRAINT [FK_QRTZ_SIMPLE_TRIGGERS_QRTZ_TRIGGERS] FOREIGN KEY
  (
    [SCHED_NAME],
    [TRIGGER_NAME],
    [TRIGGER_GROUP]
  ) REFERENCES [dbo].[QRTZ_TRIGGERS] (
    [SCHED_NAME],
    [TRIGGER_NAME],
    [TRIGGER_GROUP]
  ) ON DELETE CASCADE

ALTER TABLE [dbo].[QRTZ_SIMPROP_TRIGGERS] ADD
  CONSTRAINT [FK_QRTZ_SIMPROP_TRIGGERS_QRTZ_TRIGGERS] FOREIGN KEY
  (
    [SCHED_NAME],
    [TRIGGER_NAME],
    [TRIGGER_GROUP]
  ) REFERENCES [dbo].[QRTZ_TRIGGERS] (
    [SCHED_NAME],
    [TRIGGER_NAME],
    [TRIGGER_GROUP]
  ) ON DELETE CASCADE

ALTER TABLE [dbo].[QRTZ_TRIGGERS] ADD
  CONSTRAINT [FK_QRTZ_TRIGGERS_QRTZ_JOB_DETAILS] FOREIGN KEY
  (
    [SCHED_NAME],
    [JOB_NAME],
    [JOB_GROUP]
  ) REFERENCES [dbo].[QRTZ_JOB_DETAILS] (
    [SCHED_NAME],
    [JOB_NAME],
    [JOB_GROUP]
  )

