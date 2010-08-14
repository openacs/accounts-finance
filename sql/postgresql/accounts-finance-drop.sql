-- accounts-finance-drop.sql
--
-- @author Dekka Corp.
-- @cvs-id
--

DROP index qaf_case_id_key;
DROP index qaf_case_log_case_id_key;
DROP index qaf_case_log_other_qaf_id_key;
DROP index qaf_initial_conditions_id_key;
DROP index qaf_model_id_key;
DROP index qaf_log_points_id_key;
DROP index qaf_postcompute_process_id_key;
DROP index qaf_model_output_id_key;

DROP TABLE qaf_case;
DROP TABLE qaf_case_log;
DROP TABLE qaf_initial_conditions;
DROP TABLE qaf_model;
DROP TABLE qaf_log_points;
DROP TABLE qaf_postcompute_process;
DROP TABLE qaf_model_output;

DROP SEQUENCE qaf_id;