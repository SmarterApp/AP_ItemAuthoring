/* 
view originally created for passages report
can be used anywhere to simplify retrieval of passage characterization data 
*/

CREATE VIEW `characterization_for_passage_view` AS 
SELECT
  `p`.`p_id`          AS `p_id`,
  `p2`.`oc_int_value` AS `content_area`,
  `p3`.`oc_int_value` AS `grade_level`,
  `p5`.`oc_int_value` AS `grade_span_start`,
  `p6`.`oc_int_value` AS `grade_span_end`
FROM ((((`passage` `p`
      LEFT JOIN `object_characterization` `p2`
        ON (((`p`.`p_id` = `p2`.`oc_object_id`)
             AND (`p2`.`oc_characteristic` = 2))))
     LEFT JOIN `object_characterization` `p3`
       ON (((`p`.`p_id` = `p3`.`oc_object_id`)
            AND (`p3`.`oc_characteristic` = 3))))
    LEFT JOIN `object_characterization` `p5`
      ON (((`p`.`p_id` = `p5`.`oc_object_id`)
           AND (`p5`.`oc_characteristic` = 5))))
   LEFT JOIN `object_characterization` `p6`
     ON (((`p`.`p_id` = `p6`.`oc_object_id`)
          AND (`p6`.`oc_characteristic` = 6))));