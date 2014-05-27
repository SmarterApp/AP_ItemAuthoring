CREATE VIEW `characterization_for_item_view` AS select `i`.`i_id` AS `i_id`,`i1`.`ic_value` AS `item_standard`,`i2`.`ic_value` AS `content_area`,`i3`.`ic_value` AS `grade_level`,`i5`.`ic_value` AS `grade_span_start`,`i6`.`ic_value` AS `grade_span_end`,`i7`.`ic_value` AS `points` from ((((((`item` `i` left join `item_characterization` `i1` on(((`i`.`i_id` = `i1`.`i_id`) and (`i1`.`ic_type` = 1)))) left join `item_characterization` `i2` on(((`i`.`i_id` = `i2`.`i_id`) and (`i2`.`ic_type` = 2)))) left join `item_characterization` `i3` on(((`i`.`i_id` = `i3`.`i_id`) and (`i3`.`ic_type` = 3)))) left join `item_characterization` `i5` on(((`i`.`i_id` = `i5`.`i_id`) and (`i5`.`ic_type` = 5)))) left join `item_characterization` `i6` on(((`i`.`i_id` = `i6`.`i_id`) and (`i6`.`ic_type` = 6)))) left join `item_characterization` `i7` on(((`i`.`i_id` = `i7`.`i_id`) and (`i7`.`ic_type` = 7))));
CREATE VIEW `hierarchy_definition_1_view` AS select `hierarchy_definition`.`hd_id` AS `hd_id`,`hierarchy_definition`.`hd_type` AS `hd_type`,`hierarchy_definition`.`hd_value` AS `hd_value`,`hierarchy_definition`.`hd_parent_id` AS `hd_parent_id`,`hierarchy_definition`.`hd_posn_in_parent` AS `hd_posn_in_parent`,`hierarchy_definition`.`hd_std_desc` AS `hd_std_desc`,`hierarchy_definition`.`hd_extended_desc` AS `hd_extended_desc`,`hierarchy_definition`.`hd_parent_path` AS `hd_parent_path` from `hierarchy_definition` where `hierarchy_definition`.`hd_parent_id` in (select `hierarchy_definition`.`hd_id` AS `hd_id` from `hierarchy_definition` where (`hierarchy_definition`.`hd_parent_id` = 0));
CREATE VIEW `item_report_view` AS select `item`.`ib_id` AS `ItemBankId`,`item_bank`.`ib_external_id` AS `ItemBankExternalId`,`item`.`i_external_id` AS `ItemExternalId`,`ic_content_area`.`ic_value` AS `ContentAreaId`,ifnull(`content_area`.`ca_name`,_latin1'') AS `ContentAreaName`,ifnull(`grade_level_as_str`(`ic_grade_level`.`ic_value`),_latin1'') AS `GradeLevel`,ifnull(`grade_level_as_str`(`ic_grade_from`.`ic_value`),_latin1'') AS `GradeFrom`,ifnull(`grade_level_as_str`(`ic_grade_to`.`ic_value`),_latin1'') AS `GradeTo`,if(((`ic_grade_from`.`ic_value` >= 0) or (`ic_grade_to`.`ic_value` >= 0)),ifnull(concat(`grade_level_as_str`(`ic_grade_from`.`ic_value`),_latin1' - ',`grade_level_as_str`(`ic_grade_to`.`ic_value`)),_latin1''),_latin1'') AS `GradeSpan`,ifnull(`item_type`.`it_name`,_latin1'') AS `ItemTypeName`,ifnull(`dev_state`.`ds_name`,_latin1'') AS `DevStateName`,ifnull(`difficulty`.`d_name`,_latin1'') AS `DifficultyName`,ifnull(`publication_status`.`ps_name`,_latin1'') AS `PublicationStatusName`,ifnull(`user`.`u_username`,_latin1'') AS `ItemWriter`,ifnull(`item`.`i_readability_index`,_latin1'') AS `ReadabilityIndex`,ifnull(`blooms_taxonomy`.`bt_name`,_latin1'') AS `BloomTaxonomyName`,ifnull(`item`.`i_cognitive_process`,_latin1'') AS `CognitiveProcess`,ifnull(`item`.`i_description`,_latin1'') AS `ItemDescription` from ((((((((((((`item` join `item_bank` on((`item`.`ib_id` = `item_bank`.`ib_id`))) left join `item_characterization` `ic_content_area` on(((`item`.`i_id` = `ic_content_area`.`i_id`) and (`ic_content_area`.`ic_type` = 2)))) left join `content_area` on((`ic_content_area`.`ic_value` = `content_area`.`ca_id`))) left join `item_characterization` `ic_grade_level` on(((`item`.`i_id` = `ic_grade_level`.`i_id`) and (`ic_grade_level`.`ic_type` = 3)))) left join `item_characterization` `ic_grade_from` on(((`item`.`i_id` = `ic_grade_from`.`i_id`) and (`ic_grade_from`.`ic_type` = 5)))) left join `item_characterization` `ic_grade_to` on(((`item`.`i_id` = `ic_grade_to`.`i_id`) and (`ic_grade_to`.`ic_type` = 6)))) left join `item_type` on((`item`.`i_type` = `item_type`.`it_id`))) left join `dev_state` on((`item`.`i_dev_state` = `dev_state`.`ds_id`))) left join `difficulty` on((`item`.`i_difficulty` = `difficulty`.`d_id`))) left join `publication_status` on((`item`.`i_publication_status` = `publication_status`.`ps_id`))) left join `user` on((`user`.`u_id` = `item`.`i_author`))) left join `blooms_taxonomy` on((`item`.`i_blooms_taxonomy` = `blooms_taxonomy`.`bt_id`)));
CREATE VIEW `single_item_view` AS select `i`.`i_id` AS `i_id`,`i`.`i_external_id` AS `i_external_id`,`i`.`i_description` AS `i_description`,`ib`.`ib_external_id` AS `item_bank`,`cfi`.`points` AS `points`,`cfi`.`grade_level` AS `grade_level`,`cfi`.`grade_span_start` AS `grade_span_start`,`cfi`.`grade_span_end` AS `grade_span_end`,`ca`.`ca_name` AS `content_area`,`it`.`it_name` AS `item_type`,`ps`.`ps_name` AS `publication_status` from (((((`item` `i` join `characterization_for_item_view` `cfi` on((`i`.`i_id` = `cfi`.`i_id`))) join `item_bank` `ib` on((`i`.`ib_id` = `ib`.`ib_id`))) join `content_area` `ca` on((`cfi`.`content_area` = `ca`.`ca_id`))) join `item_type` `it` on((`i`.`i_type` = `it`.`it_id`))) join `publication_status` `ps` on((`i`.`i_publication_status` = `ps`.`ps_id`)));
CREATE VIEW `single_item_view_with_content` AS select `siv`.`i_id` AS `i_id`,`siv`.`i_external_id` AS `i_external_id`,`siv`.`i_description` AS `i_description`,`siv`.`item_bank` AS `item_bank`,`siv`.`points` AS `points`,`siv`.`grade_level` AS `grade_level`,`siv`.`content_area` AS `content_area`,`siv`.`item_type` AS `item_type`,`siv`.`publication_status` AS `publication_status`,group_concat(`ifr`.`if_text` separator '<br>') AS `i_html` from (`single_item_view` `siv` join `item_fragment` `ifr`) where ((`siv`.`i_id` = `ifr`.`i_id`) and (`ifr`.`if_type` in (1,2))) group by `siv`.`i_id` order by `ifr`.`if_type`;
CREATE VIEW `stat_administration_item_view` AS 
SELECT DISTINCT
  `siv`.`sa_id` AS `sa_id`,
  `siv`.`i_id`  AS `i_id`
FROM ((`item` `i`
    JOIN `stat_item_value` `siv`
      ON ((`i`.`i_id` = `siv`.`i_id`)))
   JOIN `stat_administration` `sa`
     ON ((`siv`.`sa_id` = `sa`.`sa_id`)));
CREATE VIEW `stat_admin_item_value_view` AS 
SELECT
  `sai`.`i_id`                AS `i_id`,
  `sai`.`sa_id`               AS `sa_id`,
  `siv1`.`siv_numeric_value`  AS `value1`,
  `siv2`.`siv_numeric_value`  AS `value2`,
  `siv3`.`siv_numeric_value`  AS `value3`,
  `siv4`.`siv_numeric_value`  AS `value4`,
  `siv5`.`siv_numeric_value`  AS `value5`,
  `siv6`.`siv_numeric_value`  AS `value6`,
  `siv7`.`siv_numeric_value`  AS `value7`,
  `siv8`.`siv_numeric_value`  AS `value8`,
  `siv9`.`siv_numeric_value`  AS `value9`,
  `siv10`.`siv_numeric_value` AS `value10`
FROM ((((((((((`stat_administration_item_view` `sai`
            LEFT JOIN `stat_item_value` `siv1`
              ON (((`siv1`.`sk_id` = 1)
                   AND (`siv1`.`i_id` = `sai`.`i_id`)
                   AND (`siv1`.`sa_id` = `sai`.`sa_id`))))
           LEFT JOIN `stat_item_value` `siv2`
             ON (((`siv2`.`sk_id` = 2)
                  AND (`siv2`.`i_id` = `sai`.`i_id`)
                  AND (`siv2`.`sa_id` = `sai`.`sa_id`))))
          LEFT JOIN `stat_item_value` `siv3`
            ON (((`siv3`.`sk_id` = 3)
                 AND (`siv3`.`i_id` = `sai`.`i_id`)
                 AND (`siv3`.`sa_id` = `sai`.`sa_id`))))
         LEFT JOIN `stat_item_value` `siv4`
           ON (((`siv4`.`sk_id` = 4)
                AND (`siv4`.`i_id` = `sai`.`i_id`)
                AND (`siv4`.`sa_id` = `sai`.`sa_id`))))
        LEFT JOIN `stat_item_value` `siv5`
          ON (((`siv5`.`sk_id` = 5)
               AND (`siv5`.`i_id` = `sai`.`i_id`)
               AND (`siv5`.`sa_id` = `sai`.`sa_id`))))
       LEFT JOIN `stat_item_value` `siv6`
         ON (((`siv6`.`sk_id` = 6)
              AND (`siv6`.`i_id` = `sai`.`i_id`)
              AND (`siv6`.`sa_id` = `sai`.`sa_id`))))
      LEFT JOIN `stat_item_value` `siv7`
        ON (((`siv7`.`sk_id` = 7)
             AND (`siv7`.`i_id` = `sai`.`i_id`)
             AND (`siv7`.`sa_id` = `sai`.`sa_id`))))
     LEFT JOIN `stat_item_value` `siv8`
       ON (((`siv8`.`sk_id` = 8)
            AND (`siv8`.`i_id` = `sai`.`i_id`)
            AND (`siv8`.`sa_id` = `sai`.`sa_id`))))
    LEFT JOIN `stat_item_value` `siv9`
      ON (((`siv9`.`sk_id` = 9)
           AND (`siv9`.`i_id` = `sai`.`i_id`)
           AND (`siv9`.`sa_id` = `sai`.`sa_id`))))
   LEFT JOIN `stat_item_value` `siv10`
     ON (((`siv10`.`sk_id` = 10)
          AND (`siv10`.`i_id` = `sai`.`i_id`)
          AND (`siv10`.`sa_id` = `sai`.`sa_id`))));
CREATE VIEW `stat_key_name_view` AS 
SELECT
  `sk1`.`sk_name`  AS `name1`,
  `sk2`.`sk_name`  AS `name2`,
  `sk3`.`sk_name`  AS `name3`,
  `sk4`.`sk_name`  AS `name4`,
  `sk5`.`sk_name`  AS `name5`,
  `sk6`.`sk_name`  AS `name6`,
  `sk7`.`sk_name`  AS `name7`,
  `sk8`.`sk_name`  AS `name8`,
  `sk9`.`sk_name`  AS `name9`,
  `sk10`.`sk_name` AS `name10`
FROM (((((((((`stat_key` `sk1`
           JOIN `stat_key` `sk2`)
          JOIN `stat_key` `sk3`)
         JOIN `stat_key` `sk4`)
        JOIN `stat_key` `sk5`)
       JOIN `stat_key` `sk6`)
      JOIN `stat_key` `sk7`)
     JOIN `stat_key` `sk8`)
    JOIN `stat_key` `sk9`)
   JOIN `stat_key` `sk10`)
WHERE ((`sk1`.`sk_id` = 1)
       AND (`sk2`.`sk_id` = 2)
       AND (`sk3`.`sk_id` = 3)
       AND (`sk4`.`sk_id` = 4)
       AND (`sk5`.`sk_id` = 5)
       AND (`sk6`.`sk_id` = 6)
       AND (`sk7`.`sk_id` = 7)
       AND (`sk8`.`sk_id` = 8)
       AND (`sk9`.`sk_id` = 9)
       AND (`sk10`.`sk_id` = 10));