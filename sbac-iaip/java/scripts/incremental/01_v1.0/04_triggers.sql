CREATE TRIGGER `hd_insert` AFTER INSERT ON `hierarchy_definition` FOR EACH ROW BEGIN
    CALL table_modified('hierarchy_definition');
    END;
/
CREATE TRIGGER `hd_update` AFTER UPDATE ON `hierarchy_definition` FOR EACH ROW BEGIN
    CALL table_modified('hierarchy_definition');
    END;
/
CREATE TRIGGER `hd_delete` AFTER DELETE ON `hierarchy_definition` FOR EACH ROW BEGIN
    CALL table_modified('hierarchy_definition');
    END;
/