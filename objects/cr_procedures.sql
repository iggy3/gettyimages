CREATE OR REPLACE PROCEDURE  "WRITE_BLOB_TO_FILE" ( p_image_name IN VARCHAR2)
IS
  -- p_file_id   IN NUMBER
  --,p_dir       IN VARCHAR2
  -- p_file_id    NUMBER;
   p_dir        VARCHAR2(400);
   l_blob            BLOB;
   l_blob_length     INTEGER;
   l_out_file        UTL_FILE.file_type;
   l_buffer          RAW (32767);
   l_chunk_size      BINARY_INTEGER := 32767;
   l_blob_position   INTEGER := 1;
   l_file_name       getty_images_blob.image_name%TYPE;
BEGIN
-- created this to hold the images dumped by the following
--CREATE OR REPLACE DIRECTORY BLOBS AS 'c:\tmp\ora_apex_dir\blob_dump_from_db\';
   p_dir := 'BLOBS';
   -- Retrieve the BLOB for reading
   SELECT data, image_name
     INTO l_blob, l_file_name
     FROM getty_images_blob
     -- IGGY 21SEP2015 changed from jpg to eps
    WHERE image_name = p_image_name||'.jpg'; --p_file_id;
    --WHERE image_name = p_image_name||'.eps'; --p_file_id;
   -- Retrieve the SIZE of the BLOB
   l_blob_length := DBMS_LOB.getlength (l_blob);
   -- Open a handle to the location where you are going to write the BLOB 
   -- to file.
   -- NOTE: The 'wb' parameter means "write in byte mode" and is only
   --       available in the UTL_FILE package with Oracle 10g or later
   l_out_file :=
      UTL_FILE.fopen (
         p_dir
        ,l_file_name
        ,'wb' -- important. If ony w then extra carriage return/line brake
        ,l_chunk_size
      );
   -- Write the BLOB to file in chunks
   WHILE l_blob_position <= l_blob_length
   LOOP
      IF l_blob_position + l_chunk_size - 1 > l_blob_length
      THEN
         l_chunk_size := l_blob_length - l_blob_position + 1;
      END IF;
      DBMS_LOB.read (
         l_blob
        ,l_chunk_size
        ,l_blob_position
        ,l_buffer
      );
      UTL_FILE.put_raw (l_out_file, l_buffer, TRUE);
      l_blob_position := l_blob_position + l_chunk_size;
   END LOOP;
   -- Close the file handle
   UTL_FILE.fclose (l_out_file);
   -- check to see if we need to run it again
  --getty_images_downld_dr_pulse;
  
END write_blob_to_file;
/

CREATE OR REPLACE PROCEDURE  "IR_TEST_HTTP" 
/*
( p_room_id in varchar2
, p_party_size in number
)
*/
 is
  req utl_http.req;
  res utl_http.resp;
  url varchar2(4000) := 'https://api.gettyimages.com/oauth2/token';
  name varchar2(4000);
  buffer varchar2(4000); 
  --content varchar2(4000) := '{"room":"'||p_room_id||'", "partySize":"'||p_party_Size||'"}';
  content varchar2(4000) ;
begin
  req := utl_http.begin_request(url, 'POST',' HTTP/1.1');
  utl_http.set_header(req, 'user-agent', 'mozilla/4.0'); 
  utl_http.set_header(req, 'content-type', 'application/json'); 
  utl_http.set_header(req, 'Content-Length', length(content));
  utl_http.set_header(req, 'grant_type', 'client_credentials');
  utl_http.set_header(req, 'client_id', '<ENTER_YOUR_API_KEY_HERE>');
  utl_http.set_header(req, 'client_secret', '<ENTER_YOUR_CLIENT_SECRET_HERE');
  utl_http.write_text(req, content);
  res := utl_http.get_response(req);
  -- process the response from the HTTP call
  begin
    loop
      utl_http.read_line(res, buffer);
      dbms_output.put_line(buffer);
    end loop;
    utl_http.end_response(res);
  exception
    when utl_http.end_of_body 
    then
      utl_http.end_response(res);
  end;
end ir_test_http;
/

CREATE OR REPLACE  PROCEDURE  "IR_TEST" (p_id number)
as
	CURSOR ir_cur is
with data1
as
(
	SELECT distinct ID,
       		USERNAME,
       		ARTIST,
       		ASSET_FAMILY,
       		CAPTION,
       		COLLECTION_CODE,
       		COLLECTION_ID,
       		COLLECTION_NAME,
       		LINKS_URI,
       		LICENSE_MODEL,
       		MAX_DIMENSIONS,
       		TITLE,
 		--      IR_KEYWORDS_TEXT,
       		DISPLAY_SIZES_NAME
  	FROM GETTY_API
  	WHERE display_sizes_name like  '%comp%'
  	AND id = p_id --95104724
), data2
as
(
	SELECT distinct ID,
       		IR_KEYWORDS_TEXT d2_ir_keywords_text
  	FROM GETTY_API
  	WHERE ir_keywords_text is not null
  	AND id = p_id --95104724
)
	SELECT distinct --d1.*,
--        	d1.ID,
--        	d1.USERNAME,
--        	d1.ARTIST,
--        	d1.ASSET_FAMILY,
--        	d1.CAPTION,
--        	d1.COLLECTION_CODE,
--        	d1.COLLECTION_ID,
--        	d1.COLLECTION_NAME,
--        	d1.LINKS_URI,
--        	d1.LICENSE_MODEL,
--        	d1.MAX_DIMENSIONS,
--        	d1.TITLE,
--		d1.IR_KEYWORDS_TEXT,
--        	d1.DISPLAY_SIZES_NAME,
--       	d2.d2_ir_keywords_text,
		--trim(regexp_substr(d2.d2_ir_keywords_text, '[^,]+', 1, LEVEL)) str,
		'"C:\box_file\WIP\S DEC 2015\IPTC\DL\exiv2-0.25-win\exiv2" -M "add Iptc.Application2.Keywords String '||trim(regexp_substr(d2.d2_ir_keywords_text, '[^,]+', 1, LEVEL))||'" "C:\box_file\WIP\S DEC 2015\IPTC\'||d1.ID||'.jpg"' ir_keywords
	FROM data1 d1
	JOIN data2 d2 on d1.id = d2.id
	WHERE d1.id = p_id --95104724
	CONNECT BY instr(d2.d2_ir_keywords_text, ',', 1, LEVEL - 1) > 0;
BEGIN
   FOR ir_rec in ir_cur LOOP
   dbms_output.put_line( ir_rec.ir_keywords);
   END LOOP;
end;
/

CREATE OR REPLACE  PROCEDURE  "HOST_COMMAND" (p_command  IN  VARCHAR2)
AS LANGUAGE JAVA
NAME 'Host.executeCommand (java.lang.String)';
/

CREATE OR REPLACE  PROCEDURE  "GETTY_IMAGES_LOAD_BIN_URL" (p_url  IN  VARCHAR2, p_image_id IN VARCHAR2 ) AS
  l_blob           BLOB;
  --
   l_file      UTL_FILE.FILE_TYPE;
 l_buffer    RAW(32767);
 l_amount    BINARY_INTEGER := 32767;
 l_pos       INTEGER := 1;
-- l_blob      BLOB;
 --l_blob      varchar2(100);
 l_blob_len  INTEGER;
 l_image_name  varchar2(200);
 -- check to see if image already exists
 l_file_cnt     varchar2(100);
--p_image_id varchar2(100);
l_stmt varchar2(2000);
l_stmt2 varchar2(2000);
BEGIN
  utl_http.set_wallet ( 'file:C:\u01\app\orainstall\admin\odev\wallet', '<ENTER_YOUR_WALLET_PASSWORD_HERE>');
  l_blob := HTTPURITYPE.createuri(p_url).getblob();
  
  -- move files to archive if it currently exists
  -- select count(*)
  -- INTO l_file_cnt
  -- FROM getty_images_blob
 --  WHERE image_name = p_image_id||'.jpg';
   
--   IF l_file_cnt > 0 THEN 
  --  l_stmt := 'INSERT INTO getty_images_blob_arch (ID, URL, DATA, IMAGE_NAME, MODIFIED_DATE) select ID, URL, DATA, IMAGE_NAME, MODIFIE
--D_DATE from getty_images_blob where image_name = '''||p_image_id||'''.jpg ';
    l_stmt2 := 'DELETE FROM getty_images_blob WHERE image_name like '''||p_image_id||'%''';
   -- execute immediate l_stmt;
  --  commit;
    execute immediate l_stmt2;
    commit;
  
  -- END IF;
  
  -- Insert the data into the table.
  INSERT INTO getty_images_blob (id, url, data,image_name, modified_date)
  -- IGGY 21SEP2015 updating to go to eps instead of jpg
  VALUES (getty_images_blob_sq.NEXTVAL, p_url, l_blob, p_image_id||'.jpg',sysdate);
 -- VALUES (getty_images_blob_sq.NEXTVAL, p_url, l_blob, p_image_id||'.eps',sysdate);
  COMMIT;
  
  write_blob_to_file ( p_image_id);
  COMMIT;
END getty_images_load_bin_url;
/

CREATE OR REPLACE  PROCEDURE  "GETTY_IMAGES_DOWNLOAD_DRIVER" 
as
        lc_entire_msg  CLOB;
        lv_url         LONG; -- VARCHAR2(32000);
        lv_url_1         LONG; -- VARCHAR2(32000);
        lv_url_2         number; -- VARCHAR2(32000);
        lv_url_3         LONG; -- VARCHAR2(32000);
        lr_request              utl_http.req;
        lr_response     utl_http.resp;
        lv_msg          VARCHAR2(80);
        l_http_request  UTL_HTTP.req;
       p_id          varchar2(255);
       p_asset_family                varchar2(255);
       p_caption             varchar2(255);
       p_collection_code             varchar2(255);
        j       apex_json.t_values;
        CURSOR ir_cur1 is SELECT distinct master_id
                    FROM getty_user_downloads
        WHERE load_date is not null
        AND image_download_date is null
        --AND REGEXP_LIKE(master_id, '^[[:digit:]]+$')
        AND master_id is not null
 AND rownum < 501
        --      and master_id in ( '97403995')
        order by master_id ;
       TYPE api_call_typ is varray(13) of varchar2(4000);
            v_api_call_typ      api_call_typ;
        --
        -- concat the image ids
        lv_imageid_pin  varchar2(32000);
        lv_imageid_next varchar2(32000);
        -- check how many have been processed
        lv_processed_cnt        number;
   -- refresh token addition
   l_token  varchar2(1000);
   BEGIN
   --select token into l_token from getty_token where rownum < 2;
   -- pulling external tab
   --select ir_token into l_token from tokens_ext where rownum < 2;
   select replace(REGEXP_SUBSTR(ir_token, '(.*?)(:|$)', 1, 2, NULL, 1),'"','') ir_token into l_token from tokens_ext where rownum < 2;
    FOR ir_rec1 in ir_cur1
    LOOP
   --dbms_output.put_line(ir_rec1.master_id);
  -- ir_rec1.master_id := ir_rec1.master_id||'.jpg';
  ---- refresh token addition
    INSERT INTO getty_images_run_history values (null,ir_rec1.master_id,sysdate,null);
    commit;
	getty_images_download(ir_rec1.master_id, l_token);
    UPDATE getty_user_downloads set image_download_date = SYSDATE where master_id = ir_rec1.master_id;
    COMMIT;
    UPDATE getty_images_run_history set end_image_pull = sysdate where image_id = ir_rec1.master_id;
    COMMIT;
--                        getty_images_API_pull(trim(leading ',' from lv_imageid_pin));
/*
        v_api_call_typ := api_call_typ(ir_rec1.master_id);
        v_api_call_typ.extend;
        v_api_call_typ(v_api_call_typ.last) := 'NULL';
                FOR i IN v_api_call_typ.first..v_api_call_typ.last -1
                LOOP
                        lv_imageid_next := v_api_call_typ(i);
update getty_user_downloads set load_date = sysdate where master_id = lv_imageid_next;
                        lv_imageid_pin := lv_imageid_pin||','||lv_imageid_next;
                     --   DBMS_OUTPUT.PUT_LINE('v_api_call_typ(i): '||v_api_call_typ(i));
    --                    getty_images_API_pull(v_api_call_typ(i));
                END LOOP;
    END LOOP;
--                      dbms_output.put_line(trim(leading ',' from lv_imageid_pin));
                        getty_images_API_pull(trim(leading ',' from lv_imageid_pin));
*/
end loop;
commit;
END;
/

CREATE OR REPLACE  PROCEDURE  "GETTY_IMAGES_DOWNLOAD" (p_image_id IN VARCHAR2, p_token IN VARCHAR2)
as
        lc_entire_msg  CLOB;
        lv_url         LONG; -- VARCHAR2(32000);
        lv_url_1         varchar2(4000); -- VARCHAR2(32000);
        lv_url_2         varchar2(4000); -- VARCHAR2(32000);
        lv_url_3         varchar2(4000); -- VARCHAR2(32000);
        lr_request              utl_http.req;
        lr_response     utl_http.resp;
        lv_msg          VARCHAR2(4000);
        --l_http_request  UTL_HTTP.req;
  	--p_id          varchar2(4000);
  	--p_asset_family                varchar2(4000);
  	--p_caption             varchar2(4000);
  	--p_collection_code             varchar2(4000);
  	--j       apex_json.t_values;
 	------------
   	-- roll it
 	------------
   lv_null_cnt	number;
	--lv_final_cnt	number;
 	------------
    	-- check to keep running proc
 	------------
    	--l_null_load_date    number;
 	------------
	-- create job 
 	------------
	l_run_id		NUMBER(10);
	--l_job_run		NUMBER;
	l_stmt			varchar2(4000);
l_1 varchar2(4000);
l_2 varchar2(4000);
l_3 varchar2(4000);
l_pin varchar2(4000);
BEGIN
      /*
      || create a JSON request / response
      */
        utl_http.set_wallet ( 'file:C:\u01\app\orainstall\admin\odev\wallet', '<ENTER_YOUR_WALLET_PASSWORD_HERE>');
     	--lv_url_1 := 'https://api.gettyimages.com:443/v3/images?ids=';
     	lv_url_1 := 'https://api.gettyimages.com:443/v3/downloads/images/';
     	--lv_url_2 := 464559154; --p_image_id;
     	lv_url_2 := p_image_id;
     	--lv_url_3 := '?auto_download=false';
        -- commenting out and changing to eps for matt 18SEP2015
        lv_url_3 := '?auto_download=false&file_type=jpg';
        --lv_url_3 := '?auto_download=false&file_type=eps';
     	lv_url := lv_url_1||lv_url_2||lv_url_3;
      /*
      || send http request and get response
      */
        lr_request := utl_http.begin_request(url => lv_url, method => 'POST');
        UTL_HTTP.set_header(lr_request, 'Api-key', '<ENTER_YOUR_API_KEY_HERE>');
      /*
      || add extra authorizations
      */
      -- you have to leave the below commened out if you use the getty_token table to hold the access key
----- refresh addition
----- added p_token to pass in from driver
          UTL_HTTP.set_header(lr_request, 'Authorization', 'Bearer '||p_token||' ');
/*
          l_1 := 'UTL_HTTP.set_header(lr_request, ''Authorization'', ''Bearer ';
          l_2 := p_token;
          l_3 := ''')';
       l_pin := l_1||l_2||l_3;
       execute immediate l_pin;
*/
       lr_response := utl_http.get_response(r => lr_request);
      /*
      || Loop through the response and add it to the clob
      */
        BEGIN
            LOOP
                utl_http.read_text(r => lr_response, data => lv_msg);
                lc_entire_msg := lc_entire_msg || lv_msg;
            END LOOP;
        EXCEPTION
            WHEN utl_http.end_of_body THEN
                utl_http.end_response(lr_response);
            WHEN others THEN
                utl_tcp.close_all_connections;
        END;
        -- Parse the clob containing the JSON respolnse
       apex_json.parse(lc_entire_msg);
     /*
     || massaging the variable
     */
    	-- remove all characaters up to the first "h
    	lc_entire_msg := SUBSTR(lc_entire_msg, INSTR(lc_entire_msg, '"h')+1);
    	-- remove all characters of {} and "
    	lc_entire_msg := translate(lc_entire_msg,'{}"','0');
    	-- remove carraige returns
    	lc_entire_msg := replace(lc_entire_msg,chr(10),'');
     /*
     || prep variable for job creation
     */
    	--l_stmt := 'begin getty_images_load_bin_url('''||lc_entire_msg||''');END;';
        l_stmt := 'begin getty_images_load_bin_url('''||lc_entire_msg||''','''||p_image_id||''');END;';
     /*
     || create a job to pull down the file
     */
	begin
  		dbms_job.submit(
		job => l_run_id , 
		--what => 'begin getty_images_load_bin_url('''||lc_entire_msg||'''); commit; END;', 
        what => 'begin getty_images_load_bin_url('''||lc_entire_msg||''','''||p_image_id||'''); commit; END;',
		--what => l_stmt,
		next_date => sysdate,
		interval => 'null'
		);
	commit;
    	--dbms_output.put_line('lc_entire_msg : '|| lc_entire_msg);
	end;
 -- commenting out this moving to a job based call above
 -- getty_images_load_bin_url(lc_entire_msg,p_image_id);
 -- iggy add 07SEP2016 to keep image downloads running until complete
 --------------------------------
/*
-- test to keep running
	SELECT count(*) INTO lv_null_cnt
	FROM getty_user_downloads
	WHERE load_date is not null 
    and image_download_date is null
    AND master_id is not null;
	IF lv_null_cnt > 0 THEN
    getty_images_downld_dr_pulse;
	END IF;
*/
 --   GETTY_images_downld_dr_pulse;

COMMIT;
--------------------------------
/*
   EXCEPTION
       WHEN no_data_found THEN
      null;
      WHEN others THEN
        null;
 */
   -- determine if proc should run again
END;
/

CREATE OR REPLACE  PROCEDURE  "GETTY_IMAGES_DOWNLD_DR_PULSE" 
/*
|| the getty images download driver pulse to check when to keep going or stop 
*/
IS
    l_run_id number(10);
    l_job_run           number;
    l_loaddate_check    number;
BEGIN
    /*
	SELECT count(*)
        INTO l_loaddate_check
        FROM getty_user_downloads
        WHERE load_date is not null
        AND image_download_date is null
        AND master_id is not null;
       */ 
        
        SELECT count(*)
        INTO l_loaddate_check
        FROM getty_images_run_history
        WHERE  end_image_pull is null;
        
        
        
        IF l_loaddate_check = 0 THEN
            dbms_job.submit( l_run_id, 'getty_images_download_driver;',sysdate,null);
	    COMMIT;
        END IF;
          --  dbms_job.submit( l_run_id, 'getty_eps_pkg.getty_eps_images_API_driver;',sysdate);
	  --  COMMIT;
END GETTY_images_downld_dr_pulse;
/

CREATE OR REPLACE  PROCEDURE  "GETTY_IMAGES_DEMO_IMAGES" (image_id IN NUMBER)
AS
 l_mime        VARCHAR2 (255);
 l_length      NUMBER;
 l_file_name   VARCHAR2 (2000);
 lob_loc       BLOB;
BEGIN
       SELECT i.MIME_TYPE, i.CONTENT, DBMS_LOB.getlength (i.CONTENT), i.FILENAME
       INTO l_mime, lob_loc, l_length, l_file_name
       FROM gettyimages_demo_imageblobs i
       WHERE i.ID = image_id;  
       OWA_UTIL.mime_header (NVL (l_mime, 'application/octet'), FALSE);
       htp.p('Content-length: ' || l_length);
       htp.p('Content-Disposition:  filename="' || SUBSTR(l_file_name, INSTR(l_file_name, '/') + 1) || '"');
       owa_util.http_header_close;
       wpg_docload.download_file(Lob_loc);
END getty_images_demo_images;
/

CREATE OR REPLACE  PROCEDURE  "GETTY_IMAGES_API_PULL" (p_image_id IN VARCHAR2, p_token VARCHAR2)
as
        lc_entire_msg  CLOB;
        lv_url         LONG; -- VARCHAR2(32000);
        lv_url_1         varchar2(4000); -- VARCHAR2(32000);
        lv_url_2         varchar2(4000); -- VARCHAR2(32000);
        lv_url_3         varchar2(4000); -- VARCHAR2(32000);
        lr_request              utl_http.req;
        lr_response     utl_http.resp;
        lv_msg          VARCHAR2(4000);
        l_http_request  UTL_HTTP.req;
  p_id          varchar2(4000);
  p_asset_family                varchar2(4000);
  p_caption             varchar2(4000);
  p_collection_code             varchar2(4000);
  j       apex_json.t_values;
   -- roll it
    	lv_null_cnt	number;
	lv_final_cnt	number;
    -- check to keep running proc
    l_null_load_date    number;
BEGIN
delete from json;
commit;
        -- create a demo JSON request / response
        utl_http.set_wallet ( 'file:C:\u01\app\orainstall\admin\odev\wallet', '<ENTER_YOUR_WALLET_PASSWORD_HERE>');
     lv_url_1 := 'https://api.gettyimages.com:443/v3/images?ids=';
     lv_url_2 := p_image_id;
     lv_url_3 := 'fields=allowed_use%2Cartist%2Cartist_title%2Casset_family%2Ccall_for_image%2Ccaption%2Ccity%2Ccollection_code%2Ccollection_id%2Ccollection_name%2Ccolor_type%2Ccomp%2Ccopyright%2Ccountry%2Ccredit_line%2Cdate_created%2Cdate_submitted%2Cdetail_set%2Cdisplay_set%2Cdownload_sizes%2Ceditorial_segments%2Cevent_ids%2Cgraphical_style%2Cid%2Ckeywords%2Clicense_model%2Clinks%2Cmax_dimensions%2Corientation%2Cpeople%2Cprestige%2Cpreview%2Cproduct_types%2Cquality_rank%2Creferral_destinations%2Cstate_province%2Csummary_set%2Cthumb%2Ctitle%2Curi_oembed';
     lv_url := lv_url_1||lv_url_2||'&'||lv_url_3;
--
--
        -- send http request and get response
        lr_request := utl_http.begin_request(url => lv_url, method => 'GET');
        UTL_HTTP.set_header(lr_request, 'Api-key', '<ENTER_YOUR_API_KEY_HERE>');
        -- add extra authorizations
      UTL_HTTP.set_header(lr_request, 'Authorization', 'Bearer '||p_token||' ');
      
      
      lr_response := utl_http.get_response(r => lr_request);
        -- Loop through the response and add it to the clob
        BEGIN
            LOOP
                utl_http.read_text(r => lr_response, data => lv_msg);
                lc_entire_msg := lc_entire_msg || lv_msg;
            END LOOP;
        EXCEPTION
            WHEN utl_http.end_of_body THEN
                utl_http.end_response(lr_response);
            WHEN others THEN
                utl_tcp.close_all_connections;
        END;
        -- Parse the clob containing the JSON respolnse
       apex_json.parse(lc_entire_msg);
--    dbms_output.put_line(lc_entire_msg);
   insert into json values (lc_entire_msg);
commit;
--------------------------------
insert into getty_api 
(id, username, artist, asset_family, caption,collection_code, collection_id, collection_name,links_uri,license_model, max_dimensions, title, ir_keywords_text, display_sizes_name)
select
         id
,username
        , artist
        , asset_family
        , caption
        , collection_code
        , collection_id
        , collection_name
        , display_sizes_uri links_uri
        , license_model
        , max_dimensions
        , title
        , ir_keywords_text
        , display_sizes_name
from (
select   distinct
gid.username
        , jt.id
/*  these are differet than nested I need to figure this one out
        , jt.how_can_i_use_it allowed_use_how_can_i_use_it
        , jt.release_info allowed_use_release_info
        , jt.usage_restrictions allowed_use_usage_restrictions
*/
        , jt.artist
        , jt.asset_family
        , jt.caption
        , jt.collection_code
        , jt.collection_id
        , jt.collection_name
        --, jt.display_sizes
   ----     , jt.is_watermarked display_sizes_is_watermarked
        ,  jt.name display_sizes_name
        ,  jt.uri  display_sizes_uri
        , jt.license_model
        , jt.max_dimensions
        , jt.title
        , listagg(jt.keyword_id, ',') WITHIN GROUP (order by jt.id)  keywords_keyword_id
        , listagg(jt.text, ', ') WITHIN GROUP (order by jt.id)  ir_keywords_text
--        , jt.text keywords_text
     ----   , jt.type keywords_type
     ----   , jt.relevance keywords_relevance
 --       , jt.images_not_found
from json ,
    json_table(doc, '$.images[*]'
                COLUMNS( id varchar(4000) path '$.id'
/*  this one is different I need to figure this one out
                        , NESTED          PATH '$.allowed_use[*]'
                                COLUMNS (how_can_i_use_it       VARCHAR(4000) path '$.how_can_i_use_it'
                                         ,release_info  VARCHAR(4000) path '$.release_info'
                                         ,usage_restrictions    VARCHAR(4000) path '$.usage_restrictions'
                                        )
*/
                        , artist varchar(4000) path '$.artist'
                        , asset_family varchar(4000) path '$.asset_family'
                        , caption VARCHAR2(4000) path '$.caption'
                        , collection_code  VARCHAR2(4000) path '$.collection_code'
                        , collection_id VARCHAR2(4000) path '$.collection_id'
                        , collection_name VARCHAR2(4000) path '$.collection_name'
                        , NESTED                        PATH '$.display_sizes[*]'
                                COLUMNS (is_watermarked VARCHAR2(4000) path '$.is_watermarked'
                                         , name VARCHAR2(4000) PATH '$.name'
                                         , uri VARCHAR2(4000) PATH '$.uri'
                                        )
                        , license_model VARCHAR2(4000) path '$.license_model'
                        , max_dimensions VARCHAR2(4000) path '$.max_dimensions'
                        , title VARCHAR2(4000) path '$.title'
                        , NESTED        PATH '$.keywords[*]'
                                COLUMNS (keyword_id     VARCHAR2(4000) path '$.keyword_id'
                                         , text         VARCHAR2(4000) path '$.text'
                                         , type         VARCHAR2(4000) path '$.type'
                                         , relevance    VARCHAR2(4000) path '$.relevance'
                                        )
     ----                   , images_not_found VARCHAR2(4000) path '$.images_not_found'
                        )
                ) as jt
    left  JOIN getty_user_downloads gid on  jt.id = gid.master_id
--WHERE UPPER(jt.name) like '%COMP%'
--   where jt.id like '%511936823%'
--and rownum < 2
group by
         jt.id
,gid.username
        , jt.artist
        , jt.asset_family
        , jt.caption
        , jt.collection_code
        , jt.collection_id
        , jt.collection_name
        , jt.license_model
        , jt.max_dimensions
        , jt.title
--        , jt.text
	, jt.uri 
	, jt.name
);
commit;
--------------------------------
-- test to keep running
	SELECT count(*) INTO lv_null_cnt
	FROM getty_user_downloads
	WHERE load_date is null 
    AND master_id is not null;
	IF lv_null_cnt > 0 THEN
	getty_driver_pulse;
	END IF;
COMMIT;
--------------------------------
   EXCEPTION
        WHEN no_data_found THEN
        null;
        WHEN others THEN
        null;
   -- determine if proc should run again
END;
/

CREATE OR REPLACE  PROCEDURE  "GETTY_IMAGES_API_DRIVER" 
AS
        lc_entire_msg  CLOB;
        lv_url         LONG; -- VARCHAR2(32000);
        lv_url_1         LONG; -- VARCHAR2(32000);
        lv_url_2         number; -- VARCHAR2(32000);
        lv_url_3         LONG; -- VARCHAR2(32000);
        lr_request              utl_http.req;
        lr_response     utl_http.resp;
        lv_msg          VARCHAR2(80);
        l_http_request  UTL_HTTP.req;
       p_id          varchar2(255);
       p_asset_family                varchar2(255);
       p_caption             varchar2(255);
       p_collection_code             varchar2(255);
        j       apex_json.t_values;
        CURSOR ir_cur1 is SELECT distinct master_id
                    FROM getty_user_downloads
        WHERE load_date is null
	--AND REGEXP_LIKE(master_id, '^[[:digit:]]+$')
        AND master_id is not null
        AND rownum < 50
        --      and master_id in ( '97403995')
	order by master_id ;
       TYPE api_call_typ is varray(13) of varchar2(4000);
            v_api_call_typ      api_call_typ;
	--
	-- concat the image ids
     	lv_imageid_pin	varchar2(32000);
	lv_imageid_next varchar2(32000);
        -- check how many have been processed
        lv_processed_cnt 	number;
    l_token  varchar2(1000);
   BEGIN
   --select token into l_token from getty_token where rownum < 2;
   -- pulling external tab
   --select ir_token into l_token from tokens_ext where rownum < 2;
   select replace(REGEXP_SUBSTR(ir_token, '(.*?)(:|$)', 1, 2, NULL, 1),'"','') ir_token into l_token from tokens_ext where rownum < 2;
delete from json;
commit;
    FOR ir_rec1 in ir_cur1
    LOOP
        -- create a demo JSON request / response
        v_api_call_typ := api_call_typ(ir_rec1.master_id);
        v_api_call_typ.extend;
        v_api_call_typ(v_api_call_typ.last) := 'NULL';
                FOR i IN v_api_call_typ.first..v_api_call_typ.last -1
                LOOP
			        lv_imageid_next := v_api_call_typ(i);
                    update getty_user_downloads set load_date = sysdate where master_id = lv_imageid_next;
			        lv_imageid_pin := lv_imageid_pin||','||lv_imageid_next;
                     --   DBMS_OUTPUT.PUT_LINE('v_api_call_typ(i): '||v_api_call_typ(i));
    --              getty_images_API_pull(v_api_call_typ(i));
                END LOOP;
    END LOOP;
--			dbms_output.put_line(trim(leading ',' from lv_imageid_pin));
                    --    getty_images_API_pull(trim(leading ',' from lv_imageid_pin));
    getty_images_API_pull(trim(leading ',' from lv_imageid_pin),l_token);
commit;
END;
/

CREATE OR REPLACE  PROCEDURE  "GETTY_DRIVER_PULSE" 
AS
    l_run_id number(10);
    l_job_run           number;
    l_loaddate_check    number;
BEGIN
    select count(*)
    into l_loaddate_check
    from getty_user_downloads
    where load_date is null;
        IF l_loaddate_check > 0 THEN
      --  null;
            dbms_job.submit( l_run_id, 'getty_images_API_driver;',sysdate,null);
	    COMMIT;
        END IF;
          --  dbms_job.submit( l_run_id, 'getty_images_API_driver;',sysdate);
	  --  COMMIT;
END;
/

CREATE OR REPLACE  PROCEDURE  "GETTY_ADD_TITLE" (p_id varchar2)
as
	CURSOR ir_cur is
with data1
as
(
	SELECT distinct ID,
       		USERNAME,
       		ARTIST,
       		ASSET_FAMILY,
       		CAPTION,
       		COLLECTION_CODE,
       		COLLECTION_ID,
       		COLLECTION_NAME,
       		LINKS_URI,
       		LICENSE_MODEL,
       		MAX_DIMENSIONS,
       		TITLE,
 		--      IR_KEYWORDS_TEXT,
       		DISPLAY_SIZES_NAME
  	FROM GETTY_API
  	WHERE display_sizes_name like  '%comp%'
  	AND id = p_id --95104724
), data2
as
(
	SELECT distinct ID,
       		IR_KEYWORDS_TEXT d2_ir_keywords_text
  	FROM GETTY_API
  	WHERE ir_keywords_text is not null
  	AND id = p_id --95104724
)
	SELECT distinct --d1.*,
        	d1.ID,
--        	d1.USERNAME,
--        	d1.ARTIST,
--        	d1.ASSET_FAMILY,
--        	d1.CAPTION,
--        	d1.COLLECTION_CODE,
--        	d1.COLLECTION_ID,
--        	d1.COLLECTION_NAME,
--        	d1.LINKS_URI,
--        	d1.LICENSE_MODEL,
--        	d1.MAX_DIMENSIONS,
        	d1.TITLE,
--		d1.IR_KEYWORDS_TEXT,
--        	d1.DISPLAY_SIZES_NAME,
--       	d2.d2_ir_keywords_text,
		--trim(regexp_substr(d2.d2_ir_keywords_text, '[^,]+', 1, LEVEL)) str,
	--	'"C:\box_file\WIP\S DEC 2015\IPTC\DL\exiv2-0.25-win\exiv2" -M "add Iptc.Application2.Keywords String '||trim(regexp_substr(d2.d2_ir_keywords_text, '[^,]+', 1, LEVEL))||'" "C:\box_file\WIP\S DEC 2015\IPTC\'||d1.ID||'.jpg"' ir_keywords
	'"C:\box_file\WIP\S DEC 2015\IPTC\DL\exiv2-0.25-win\exiv2" -M "add Iptc.Application2.Caption String '||trim(regexp_substr(d1.title, '[^,]+', 1, LEVEL))||'" "C:\tmp\ora_apex_dir\blob_dump_from_db\'||d1.ID||'.jpg"' ir_title
    FROM data1 d1
	JOIN data2 d2 on d1.id = d2.id
	WHERE d1.id = p_id --95104724
	CONNECT BY instr(d1.title, ',', 1, LEVEL - 1) > 0;
BEGIN
   FOR ir_rec in ir_cur LOOP
   	INSERT INTO getty_iptc_commands values (null,'TITLE',ir_rec.ir_title,null,ir_rec.id);
   --dbms_output.put_line( ir_rec.ir_title);
   COMMIT;
   END LOOP;
   COMMIT;
end;
/

CREATE OR REPLACE  PROCEDURE  "GETTY_ADD_KEYWORDS_PULSE" 
AS
    l_run_id number(10);
    l_job_run           number;
    l_loaddate_check    number;
BEGIN
    select count(*)
    into l_loaddate_check
    from getty_api
    where load_date is null;
        IF l_loaddate_check > 0 THEN
     --   null;
            dbms_job.submit( l_run_id, 'getty_add_keywords_driver;',sysdate,null);
	    COMMIT;
        
        END IF;
          --  dbms_job.submit( l_run_id, 'getty_add_keywords_driver;',sysdate);
	    COMMIT;
END;
/

CREATE OR REPLACE  PROCEDURE  "GETTY_ADD_KEYWORDS_DRIVER" 
is
        CURSOR ir_cur is  SELECT distinct a.id
                        FROM GETTY_API a
                        -- adding join to only add iptc tags on images downloaded but not yet run against
                        JOIN getty_iptc_commands b
                            on a.id = b.master_id
                        WHERE a.ir_keywords_text is not null
                        and b.cmd_run_date is  null
                       -- where id <> 104737335          
			and rownum < 501
            and a.load_date is null
            order by 1;
                        --and id = 95104724;
 BEGIN
        FOR ir_rec in ir_cur LOOP
                getty_add_keywords(ir_rec.id);
       commit;
 --      update getty_api set load_date = sysdate where id = ir_rec.id and load_date is null;
         UPDATE getty_user_downloads set keywords_load_date = SYSDATE where master_id = ir_rec.id and keywords_load_date is null;
     --  commit;
        END LOOP;
       commit;
END;
/

CREATE OR REPLACE  PROCEDURE  "GETTY_ADD_KEYWORDS" (p_id varchar2)
as
    lv_null_cnt    number;
	CURSOR ir_cur is
with data1
as
(
	SELECT distinct ID,
       		USERNAME,
       		ARTIST,
       		ASSET_FAMILY,
       		CAPTION,
       		COLLECTION_CODE,
       		COLLECTION_ID,
       		COLLECTION_NAME,
       		LINKS_URI,
       		LICENSE_MODEL,
       		MAX_DIMENSIONS,
       		TITLE,
 		--      IR_KEYWORDS_TEXT,
       		DISPLAY_SIZES_NAME
  	FROM GETTY_API
  	WHERE display_sizes_name like  '%comp%'
  	AND id = p_id --95104724
), data2
as
(
	SELECT distinct ID,
       		IR_KEYWORDS_TEXT d2_ir_keywords_text
  	FROM GETTY_API
  	WHERE ir_keywords_text is not null
  	AND id = p_id --95104724
)
	SELECT distinct --d1.*,
        	d1.ID,
--        	d1.USERNAME,
--        	d1.ARTIST,
--        	d1.ASSET_FAMILY,
--        	d1.CAPTION,
--        	d1.COLLECTION_CODE,
--        	d1.COLLECTION_ID,
--        	d1.COLLECTION_NAME,
--        	d1.LINKS_URI,
--        	d1.LICENSE_MODEL,
--        	d1.MAX_DIMENSIONS,
--        	d1.TITLE,
--		d1.IR_KEYWORDS_TEXT,
--        	d1.DISPLAY_SIZES_NAME,
       	d2.d2_ir_keywords_text,
		--trim(regexp_substr(d2.d2_ir_keywords_text, '[^,]+', 1, LEVEL)) str,
	--	'"C:\box_file\WIP\S DEC 2015\IPTC\DL\exiv2-0.25-win\exiv2" -M "add Iptc.Application2.Keywords String '||trim(regexp_substr(d2.d2_ir_keywords_text, '[^,]+', 1, LEVEL))||'" "C:\box_file\WIP\S DEC 2015\IPTC\'||d1.ID||'.jpg"' ir_keywords
	'"C:\box_file\WIP\S DEC 2015\IPTC\DL\exiv2-0.25-win\exiv2" -M "add Iptc.Application2.Keywords String '||trim(regexp_substr(d2.d2_ir_keywords_text, '[^,]+', 1, LEVEL))||'" "C:\tmp\ora_apex_dir\blob_dump_from_db\'||d1.ID||'.jpg"' ir_keywords
    FROM data1 d1
	JOIN data2 d2 on d1.id = d2.id
	WHERE d1.id = p_id --95104724
	CONNECT BY instr(d2.d2_ir_keywords_text, ',', 1, LEVEL - 1) > 0;
BEGIN
   FOR ir_rec in ir_cur LOOP
   	INSERT INTO getty_iptc_commands values (null,'KEYWORDS',ir_rec.ir_keywords,null,ir_rec.id);
   --dbms_output.put_line( ir_rec.ir_keywords);
 --  commit;
  --  update getty_api set load_date = sysdate where id = p_id and load_date is null and ir_keywords_text =  ir_rec.d2_ir_keywords_text;
   --   UPDATE getty_user_downloads set keywords_load_date = SYSDATE where to_char(master_id) = to_char(p_id) and load_date is null;
commit;
   END LOOP;
   commit;
   --------------------------------
-- test to keep running
--	SELECT count(*) INTO lv_null_cnt
--	FROM getty_api
--	WHERE load_date is null;
--	IF lv_null_cnt > 0 THEN
--	getty_add_keywords_pulse;
--	END IF;
--COMMIT;
--------------------------------
end;
/

CREATE OR REPLACE  PROCEDURE  "EXECUTECOMMAND" (in_command IN VARCHAR2)
 AS
   LANGUAGE JAVA
   NAME 'ClientHost.executeCommand (java.lang.String) ';
/

CREATE OR REPLACE  PROCEDURE  "AWS_GET_SQSM" (p_message_name in varchar2)
as
        lc_entire_msg  CLOB;
        lv_url         LONG; -- VARCHAR2(32000);
        lv_url_1         varchar2(4000); -- VARCHAR2(32000);
        lv_url_2         varchar2(4000); -- VARCHAR2(32000);
        lv_url_3         varchar2(4000); -- VARCHAR2(32000);
        lr_request              utl_http.req;
        lr_response     utl_http.resp;
        lv_msg          VARCHAR2(4000);
        l_http_request  UTL_HTTP.req;
  p_id          varchar2(4000);
  p_asset_family                varchar2(4000);
  p_caption             varchar2(4000);
  p_collection_code             varchar2(4000);
  j       apex_json.t_values;
   -- roll it
    	lv_null_cnt	number;
	lv_final_cnt	number;
    -- check to keep running proc
    l_null_load_date    number;
-------
 t_http_req  utl_http.req;
  t_http_resp  utl_http.resp; 
  t_response_text VARCHAR2 (2000);
BEGIN
--delete from json;
----commit;
        utl_http.set_wallet ( 'file:C:\TEMP\my_certs', '<ENTER_YOUR_WALLET_PASSWORD_HERE>');
     lv_url_1 := 'https://sqs.us-west-2.amazonaws.com/403500184417/ir_test01?Action=ReceiveMessage';
     lv_url_2 := 'Version=2011-10-01'; 
     lv_url_3 := 'MessageBody='; --example';
--lv_url := lv_url_1;
     lv_url := lv_url_1||'&'||lv_url_2||'&'||lv_url_3||p_message_name;
--
--
--t_http_req:= utl_http.begin_request('https://sqs.us-west-2.amazonaws.com/403500184417/ir_test01?Action=ReceiveMessage');
t_http_req:= utl_http.begin_request(url => lv_url,method => 'GET');
  t_http_resp:= utl_http.get_response(r => t_http_req);
  --UTL_HTTP.read_text(t_http_resp, t_response_text);
  UTL_HTTP.read_text( r => t_http_resp, data => t_response_text);
  DBMS_OUTPUT.put_line('Response> status_code: "' || t_http_resp.status_code || '"');
  DBMS_OUTPUT.put_line('Response> reason_phrase: "' ||t_http_resp.reason_phrase || '"');    
  DBMS_OUTPUT.put_line('Response> data:' ||t_response_text); 
        apex_json.parse(lc_entire_msg);
        insert into aws_json values (lc_entire_msg);
  utl_http.end_response(t_http_resp);
/*
        -- send http request and get response
        lr_request := utl_http.begin_request(url => lv_url,method => 'GET');
      lr_response := utl_http.get_response(r => lr_request);
*/
        -- Loop through the response and add it to the clob
--        BEGIN
--            LOOP
--lr_request := utl_http.begin_request(url => lv_url,method => 'GET');
--lr_response := utl_http.get_response(r => t_http_req);
--utl_http.read_text(r => lr_response, data => lv_msg);
--                lc_entire_msg := lc_entire_msg || lv_msg;
--            END LOOP;
--        EXCEPTION
--            WHEN utl_http.end_of_body THEN
--                utl_http.end_response(lr_response);
--            WHEN others THEN
--                utl_tcp.close_all_connections;
--        END;
        -- Parse the clob containing the JSON respolnse
--       apex_json.parse(lc_entire_msg);
--dbms_output.put_line(lr_request);
--dbms_output.put_line(lv_url);
--dbms_output.put_line(lv_msg);
--    dbms_output.put_line(lc_entire_msg);
--   insert into aws_json values (lc_entire_msg);
--commit;
--------------------------------
/*
   EXCEPTION
        WHEN no_data_found THEN
        null;
        WHEN others THEN
        null;
   -- determine if proc should run again
*/
END;
/
