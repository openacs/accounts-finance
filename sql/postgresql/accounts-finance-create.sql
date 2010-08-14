-- accounts-finance-create.sql
--
-- @author Dekka Corp.
-- @cvs-id
--

CREATE SEQUENCE qaf_id start 10000;
SELECT nextval ('qaf_id');

-- model output is separate from case, even though it is one-to-one
-- for easier abstractions of output without associating case for 
-- multple case processing, such as double blind study simulations, using outputs for 
-- other case inputs etc etc.
-- think calculator wiki with revisions

CREATE TABLE qaf_case (
    id int DEFAULT nextval ( 'qaf_id' ),  
    code varchar(30),
    title varchar(30),
    description text,
    init_condition_id int,
    model_id int,
    log_points_id int,
    postcompute_process_id int,
    model_output_id int,
    iterations_requested int,
    iterations_completed int,
    instance_id integer,
        -- object_id of mounted instance (context_id)
    user_id integer,
    time_created timestamptz,
    last_modified timestamptz,
    trashed_p boolean default 'f',
    time_closed timestamptz
);

-- this table associates old ids with cases
-- multiple cases may be associated with various ids
-- no type is set for old id, since this will likely be joined with
-- another table
CREATE TABLE qaf_case_log (
    case_id int,
    other_qaf_id int
);


CREATE TABLE qaf_initial_conditions (
    id int DEFAULT nextval ( 'qaf_id' ),  
    code varchar(30),
    title varchar(30),
    user_id integer,
    time_created timestamptz,
    trashed_p boolean default 'f',
    description text
);

CREATE TABLE qaf_model (
    id int DEFAULT nextval ( 'qaf_id' ),  
    code varchar(30),
    title varchar(30),
    user_id integer,
    time_created timestamptz,
    trashed_p boolean default 'f',
    description text,
    program text
);


CREATE TABLE qaf_log_points (
    id int DEFAULT nextval ( 'qaf_id' ),  
    code varchar(30),
    title varchar(30),
    user_id integer,
    time_created timestamptz,
    trashed_p boolean default 'f',
    description text
);

CREATE TABLE qaf_postcompute_process (
    id int DEFAULT nextval ( 'qaf_id' ),  
    code varchar(30),
    title varchar(30),
    user_id integer,
    time_created timestamptz,
    trashed_p boolean default 'f',
    description text
);

-- qaf_model_output.compute_log will contain a tcl list of lists
-- until we can reference a spreadsheet table, and
-- insert there.
CREATE TABLE qaf_model_output (
    id int DEFAULT nextval ( 'qaf_id' ),
    code varchar(30),
    title varchar(30),
    user_id integer,
    time_created timestamptz,
    trashed_p boolean default 'f',
    description text,
    compute_log text,
    notes text
);

CREATE index qaf_case_id_key on qaf_case(id);
CREATE index qaf_case_log_case_id_key on qaf_case_log(case_id);
CREATE index qaf_case_log_other_qaf_id_key on qaf_case_log(other_qaf_id);
CREATE index qaf_initial_conditions_id_key on qaf_initial_conditions(id);
CREATE index qaf_model_id_key on qaf_model(id);
CREATE index qaf_log_points_id_key on qaf_log_points(id);
CREATE index qaf_postcompute_process_id_key on qaf_postcompute_process(id);
CREATE index qaf_model_output_id_key on qaf_model_output(id);
