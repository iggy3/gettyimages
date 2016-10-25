CREATE OR REPLACE DIRECTORY ext_tab_data AS 'c:\TEMP\ext_table';
/


CREATE TABLE tokens_ext (
  ir_token  VARCHAR2(4000)
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY ext_tab_data
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    FIELDS TERMINATED BY ','
    MISSING FIELD VALUES ARE NULL
    (
      ir_token  CHAR(4000)
    )
  )
  LOCATION ('tokens1.txt','tokens2.txt')
)
PARALLEL 5
REJECT LIMIT UNLIMITED
/





CREATE DIRECTORY xt_dir AS 'c:\TEMP\ext_table';
/


GRANT READ, WRITE ON DIRECTORY xt_dir TO gettyimages
/


CREATE DIRECTORY bin_dir AS 'c:\TEMP\ext_table\bin'
/

GRANT EXECUTE ON DIRECTORY bin_dir TO gettyimages
/


connect gettyimages

CREATE TABLE files_xt
    ( file_date VARCHAR2(50)
    , file_time VARCHAR2(50)
    , file_size VARCHAR2(50)
    , file_name VARCHAR2(255)
    )
    ORGANIZATION EXTERNAL
    (
      TYPE ORACLE_LOADER
     DEFAULT DIRECTORY xt_dir
     ACCESS PARAMETERS
     (
        RECORDS DELIMITED BY NEWLINE
        LOAD WHEN file_size != '<DIR>'
        PREPROCESSOR bin_dir: 'list_files.bat'
        FIELDS TERMINATED BY WHITESPACE
     )
     LOCATION ('sticky.txt')
   )
   REJECT LIMIT UNLIMITED
/
