DROP VIEW IF EXISTS `characterization_for_item_view`; 

CREATE VIEW `characterization_for_item_view` AS 
SELECT
  `i`.`i_id`      AS `i_id`,
  `i1`.`ic_value` AS `item_standard`,
  `i2`.`ic_value` AS `content_area`,
  `i3`.`ic_value` AS `grade_level`,
  `i5`.`ic_value` AS `grade_span_start`,
  `i6`.`ic_value` AS `grade_span_end`,
  `i7`.`ic_value` AS `points`,
  `i8`.`ic_value` AS `depth_of_knowledge`
FROM (((((((`item` `i`
         LEFT JOIN `item_characterization` `i1`
           ON (((`i`.`i_id` = `i1`.`i_id`)
                AND (`i1`.`ic_type` = 1))))
        LEFT JOIN `item_characterization` `i2`
          ON (((`i`.`i_id` = `i2`.`i_id`)
               AND (`i2`.`ic_type` = 2))))
       LEFT JOIN `item_characterization` `i3`
         ON (((`i`.`i_id` = `i3`.`i_id`)
              AND (`i3`.`ic_type` = 3))))
      LEFT JOIN `item_characterization` `i5`
        ON (((`i`.`i_id` = `i5`.`i_id`)
             AND (`i5`.`ic_type` = 5))))
     LEFT JOIN `item_characterization` `i6`
       ON (((`i`.`i_id` = `i6`.`i_id`)
            AND (`i6`.`ic_type` = 6))))
    LEFT JOIN `item_characterization` `i7`
      ON (((`i`.`i_id` = `i7`.`i_id`)
           AND (`i7`.`ic_type` = 7))))
   LEFT JOIN `item_characterization` `i8`
     ON (((`i`.`i_id` = `i8`.`i_id`)
          AND (`i8`.`ic_type` = 8))));