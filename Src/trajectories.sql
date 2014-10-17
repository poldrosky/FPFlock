--
-- PostgreSQL database dump
--

-- Dumped from database version 9.1.7
-- Dumped by pg_dump version 9.3.5
-- Started on 2014-10-17 15:55:54 COT

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 240 (class 3079 OID 11721)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 3333 (class 0 OID 0)
-- Dependencies: 240
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- TOC entry 241 (class 3079 OID 374406)
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- TOC entry 3334 (class 0 OID 0)
-- Dependencies: 241
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


SET search_path = public, pg_catalog;

--
-- TOC entry 286 (class 1255 OID 296744)
-- Name: addgeometrycolumn(character varying, character varying, integer, character varying, integer); Type: FUNCTION; Schema: public; Owner: omar
--

CREATE FUNCTION addgeometrycolumn(character varying, character varying, integer, character varying, integer) RETURNS text
    LANGUAGE plpgsql STRICT
    AS $_$ 
DECLARE
	ret  text;
BEGIN
	SELECT AddGeometryColumn('','',$1,$2,$3,$4,$5) into ret;
	RETURN ret;
END;
$_$;


ALTER FUNCTION public.addgeometrycolumn(character varying, character varying, integer, character varying, integer) OWNER TO omar;

--
-- TOC entry 3335 (class 0 OID 0)
-- Dependencies: 286
-- Name: FUNCTION addgeometrycolumn(character varying, character varying, integer, character varying, integer); Type: COMMENT; Schema: public; Owner: omar
--

COMMENT ON FUNCTION addgeometrycolumn(character varying, character varying, integer, character varying, integer) IS 'args: table_name, column_name, srid, type, dimension - Adds a geometry column to an existing table of attributes.';


--
-- TOC entry 285 (class 1255 OID 296743)
-- Name: addgeometrycolumn(character varying, character varying, character varying, integer, character varying, integer); Type: FUNCTION; Schema: public; Owner: omar
--

CREATE FUNCTION addgeometrycolumn(character varying, character varying, character varying, integer, character varying, integer) RETURNS text
    LANGUAGE plpgsql STABLE STRICT
    AS $_$ 
DECLARE
	ret  text;
BEGIN
	SELECT AddGeometryColumn('',$1,$2,$3,$4,$5,$6) into ret;
	RETURN ret;
END;
$_$;


ALTER FUNCTION public.addgeometrycolumn(character varying, character varying, character varying, integer, character varying, integer) OWNER TO omar;

--
-- TOC entry 3336 (class 0 OID 0)
-- Dependencies: 285
-- Name: FUNCTION addgeometrycolumn(character varying, character varying, character varying, integer, character varying, integer); Type: COMMENT; Schema: public; Owner: omar
--

COMMENT ON FUNCTION addgeometrycolumn(character varying, character varying, character varying, integer, character varying, integer) IS 'args: schema_name, table_name, column_name, srid, type, dimension - Adds a geometry column to an existing table of attributes.';


--
-- TOC entry 284 (class 1255 OID 296742)
-- Name: addgeometrycolumn(character varying, character varying, character varying, character varying, integer, character varying, integer); Type: FUNCTION; Schema: public; Owner: omar
--

CREATE FUNCTION addgeometrycolumn(character varying, character varying, character varying, character varying, integer, character varying, integer) RETURNS text
    LANGUAGE plpgsql STRICT
    AS $_$
DECLARE
	catalog_name alias for $1;
	schema_name alias for $2;
	table_name alias for $3;
	column_name alias for $4;
	new_srid alias for $5;
	new_type alias for $6;
	new_dim alias for $7;
	rec RECORD;
	sr varchar;
	real_schema name;
	sql text;

BEGIN

	-- Verify geometry type
	IF ( NOT ( (new_type = 'GEOMETRY') OR
			   (new_type = 'GEOMETRYCOLLECTION') OR
			   (new_type = 'POINT') OR
			   (new_type = 'MULTIPOINT') OR
			   (new_type = 'POLYGON') OR
			   (new_type = 'MULTIPOLYGON') OR
			   (new_type = 'LINESTRING') OR
			   (new_type = 'MULTILINESTRING') OR
			   (new_type = 'GEOMETRYCOLLECTIONM') OR
			   (new_type = 'POINTM') OR
			   (new_type = 'MULTIPOINTM') OR
			   (new_type = 'POLYGONM') OR
			   (new_type = 'MULTIPOLYGONM') OR
			   (new_type = 'LINESTRINGM') OR
			   (new_type = 'MULTILINESTRINGM') OR
			   (new_type = 'CIRCULARSTRING') OR
			   (new_type = 'CIRCULARSTRINGM') OR
			   (new_type = 'COMPOUNDCURVE') OR
			   (new_type = 'COMPOUNDCURVEM') OR
			   (new_type = 'CURVEPOLYGON') OR
			   (new_type = 'CURVEPOLYGONM') OR
			   (new_type = 'MULTICURVE') OR
			   (new_type = 'MULTICURVEM') OR
			   (new_type = 'MULTISURFACE') OR
			   (new_type = 'MULTISURFACEM')) )
	THEN
		RAISE EXCEPTION 'Invalid type name - valid ones are:
	POINT, MULTIPOINT,
	LINESTRING, MULTILINESTRING,
	POLYGON, MULTIPOLYGON,
	CIRCULARSTRING, COMPOUNDCURVE, MULTICURVE,
	CURVEPOLYGON, MULTISURFACE,
	GEOMETRY, GEOMETRYCOLLECTION,
	POINTM, MULTIPOINTM,
	LINESTRINGM, MULTILINESTRINGM,
	POLYGONM, MULTIPOLYGONM,
	CIRCULARSTRINGM, COMPOUNDCURVEM, MULTICURVEM
	CURVEPOLYGONM, MULTISURFACEM,
	or GEOMETRYCOLLECTIONM';
		RETURN 'fail';
	END IF;


	-- Verify dimension
	IF ( (new_dim >4) OR (new_dim <0) ) THEN
		RAISE EXCEPTION 'invalid dimension';
		RETURN 'fail';
	END IF;

	IF ( (new_type LIKE '%M') AND (new_dim!=3) ) THEN
		RAISE EXCEPTION 'TypeM needs 3 dimensions';
		RETURN 'fail';
	END IF;


	-- Verify SRID
	IF ( new_srid != -1 ) THEN
		SELECT SRID INTO sr FROM spatial_ref_sys WHERE SRID = new_srid;
		IF NOT FOUND THEN
			RAISE EXCEPTION 'AddGeometryColumns() - invalid SRID';
			RETURN 'fail';
		END IF;
	END IF;


	-- Verify schema
	IF ( schema_name IS NOT NULL AND schema_name != '' ) THEN
		sql := 'SELECT nspname FROM pg_namespace ' ||
			'WHERE text(nspname) = ' || quote_literal(schema_name) ||
			'LIMIT 1';
		RAISE DEBUG '%', sql;
		EXECUTE sql INTO real_schema;

		IF ( real_schema IS NULL ) THEN
			RAISE EXCEPTION 'Schema % is not a valid schemaname', quote_literal(schema_name);
			RETURN 'fail';
		END IF;
	END IF;

	IF ( real_schema IS NULL ) THEN
		RAISE DEBUG 'Detecting schema';
		sql := 'SELECT n.nspname AS schemaname ' ||
			'FROM pg_catalog.pg_class c ' ||
			  'JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace ' ||
			'WHERE c.relkind = ' || quote_literal('r') ||
			' AND n.nspname NOT IN (' || quote_literal('pg_catalog') || ', ' || quote_literal('pg_toast') || ')' ||
			' AND pg_catalog.pg_table_is_visible(c.oid)' ||
			' AND c.relname = ' || quote_literal(table_name);
		RAISE DEBUG '%', sql;
		EXECUTE sql INTO real_schema;

		IF ( real_schema IS NULL ) THEN
			RAISE EXCEPTION 'Table % does not occur in the search_path', quote_literal(table_name);
			RETURN 'fail';
		END IF;
	END IF;
	

	-- Add geometry column to table
	sql := 'ALTER TABLE ' ||
		quote_ident(real_schema) || '.' || quote_ident(table_name)
		|| ' ADD COLUMN ' || quote_ident(column_name) ||
		' geometry ';
	RAISE DEBUG '%', sql;
	EXECUTE sql;


	-- Delete stale record in geometry_columns (if any)
	sql := 'DELETE FROM geometry_columns WHERE
		f_table_catalog = ' || quote_literal('') ||
		' AND f_table_schema = ' ||
		quote_literal(real_schema) ||
		' AND f_table_name = ' || quote_literal(table_name) ||
		' AND f_geometry_column = ' || quote_literal(column_name);
	RAISE DEBUG '%', sql;
	EXECUTE sql;


	-- Add record in geometry_columns
	sql := 'INSERT INTO geometry_columns (f_table_catalog,f_table_schema,f_table_name,' ||
										  'f_geometry_column,coord_dimension,srid,type)' ||
		' VALUES (' ||
		quote_literal('') || ',' ||
		quote_literal(real_schema) || ',' ||
		quote_literal(table_name) || ',' ||
		quote_literal(column_name) || ',' ||
		new_dim::text || ',' ||
		new_srid::text || ',' ||
		quote_literal(new_type) || ')';
	RAISE DEBUG '%', sql;
	EXECUTE sql;


	-- Add table CHECKs
	sql := 'ALTER TABLE ' ||
		quote_ident(real_schema) || '.' || quote_ident(table_name)
		|| ' ADD CONSTRAINT '
		|| quote_ident('enforce_srid_' || column_name)
		|| ' CHECK (ST_SRID(' || quote_ident(column_name) ||
		') = ' || new_srid::text || ')' ;
	RAISE DEBUG '%', sql;
	EXECUTE sql;

	sql := 'ALTER TABLE ' ||
		quote_ident(real_schema) || '.' || quote_ident(table_name)
		|| ' ADD CONSTRAINT '
		|| quote_ident('enforce_dims_' || column_name)
		|| ' CHECK (ST_NDims(' || quote_ident(column_name) ||
		') = ' || new_dim::text || ')' ;
	RAISE DEBUG '%', sql;
	EXECUTE sql;

	IF ( NOT (new_type = 'GEOMETRY')) THEN
		sql := 'ALTER TABLE ' ||
			quote_ident(real_schema) || '.' || quote_ident(table_name) || ' ADD CONSTRAINT ' ||
			quote_ident('enforce_geotype_' || column_name) ||
			' CHECK (GeometryType(' ||
			quote_ident(column_name) || ')=' ||
			quote_literal(new_type) || ' OR (' ||
			quote_ident(column_name) || ') is null)';
		RAISE DEBUG '%', sql;
		EXECUTE sql;
	END IF;

	RETURN
		real_schema || '.' ||
		table_name || '.' || column_name ||
		' SRID:' || new_srid::text ||
		' TYPE:' || new_type ||
		' DIMS:' || new_dim::text || ' ';
END;
$_$;


ALTER FUNCTION public.addgeometrycolumn(character varying, character varying, character varying, character varying, integer, character varying, integer) OWNER TO omar;

--
-- TOC entry 3337 (class 0 OID 0)
-- Dependencies: 284
-- Name: FUNCTION addgeometrycolumn(character varying, character varying, character varying, character varying, integer, character varying, integer); Type: COMMENT; Schema: public; Owner: omar
--

COMMENT ON FUNCTION addgeometrycolumn(character varying, character varying, character varying, character varying, integer, character varying, integer) IS 'args: catalog_name, schema_name, table_name, column_name, srid, type, dimension - Adds a geometry column to an existing table of attributes.';


--
-- TOC entry 364 (class 1255 OID 296837)
-- Name: fix_geometry_columns(); Type: FUNCTION; Schema: public; Owner: omar
--

CREATE FUNCTION fix_geometry_columns() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
	mislinked record;
	result text;
	linked integer;
	deleted integer;
	foundschema integer;
BEGIN

	-- Since 7.3 schema support has been added.
	-- Previous postgis versions used to put the database name in
	-- the schema column. This needs to be fixed, so we try to 
	-- set the correct schema for each geometry_colums record
	-- looking at table, column, type and srid.
	UPDATE geometry_columns SET f_table_schema = n.nspname
		FROM pg_namespace n, pg_class c, pg_attribute a,
			pg_constraint sridcheck, pg_constraint typecheck
	        WHERE ( f_table_schema is NULL
		OR f_table_schema = ''
	        OR f_table_schema NOT IN (
	                SELECT nspname::varchar
	                FROM pg_namespace nn, pg_class cc, pg_attribute aa
	                WHERE cc.relnamespace = nn.oid
	                AND cc.relname = f_table_name::name
	                AND aa.attrelid = cc.oid
	                AND aa.attname = f_geometry_column::name))
	        AND f_table_name::name = c.relname
	        AND c.oid = a.attrelid
	        AND c.relnamespace = n.oid
	        AND f_geometry_column::name = a.attname

	        AND sridcheck.conrelid = c.oid
		AND sridcheck.consrc LIKE '(srid(% = %)'
	        AND sridcheck.consrc ~ textcat(' = ', srid::text)

	        AND typecheck.conrelid = c.oid
		AND typecheck.consrc LIKE
		'((geometrytype(%) = ''%''::text) OR (% IS NULL))'
	        AND typecheck.consrc ~ textcat(' = ''', type::text)

	        AND NOT EXISTS (
	                SELECT oid FROM geometry_columns gc
	                WHERE c.relname::varchar = gc.f_table_name
	                AND n.nspname::varchar = gc.f_table_schema
	                AND a.attname::varchar = gc.f_geometry_column
	        );

	GET DIAGNOSTICS foundschema = ROW_COUNT;

	-- no linkage to system table needed
	return 'fixed:'||foundschema::text;

END;
$$;


ALTER FUNCTION public.fix_geometry_columns() OWNER TO omar;

--
-- TOC entry 440 (class 1255 OID 296953)
-- Name: populate_geometry_columns(); Type: FUNCTION; Schema: public; Owner: omar
--

CREATE FUNCTION populate_geometry_columns() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
	inserted    integer;
	oldcount    integer;
	probed      integer;
	stale       integer;
	gcs         RECORD;
	gc          RECORD;
	gsrid       integer;
	gndims      integer;
	gtype       text;
	query       text;
	gc_is_valid boolean;
	
BEGIN
	SELECT count(*) INTO oldcount FROM geometry_columns;
	inserted := 0;

	EXECUTE 'TRUNCATE geometry_columns';

	-- Count the number of geometry columns in all tables and views
	SELECT count(DISTINCT c.oid) INTO probed
	FROM pg_class c, 
	     pg_attribute a, 
	     pg_type t, 
	     pg_namespace n
	WHERE (c.relkind = 'r' OR c.relkind = 'v')
	AND t.typname = 'geometry'
	AND a.attisdropped = false
	AND a.atttypid = t.oid
	AND a.attrelid = c.oid
	AND c.relnamespace = n.oid
	AND n.nspname NOT ILIKE 'pg_temp%';

	-- Iterate through all non-dropped geometry columns
	RAISE DEBUG 'Processing Tables.....';

	FOR gcs IN 
	SELECT DISTINCT ON (c.oid) c.oid, n.nspname, c.relname
	    FROM pg_class c, 
	         pg_attribute a, 
	         pg_type t, 
	         pg_namespace n
	    WHERE c.relkind = 'r'
	    AND t.typname = 'geometry'
	    AND a.attisdropped = false
	    AND a.atttypid = t.oid
	    AND a.attrelid = c.oid
	    AND c.relnamespace = n.oid
	    AND n.nspname NOT ILIKE 'pg_temp%'
	LOOP
	
	inserted := inserted + populate_geometry_columns(gcs.oid);
	END LOOP;
	
	-- Add views to geometry columns table
	RAISE DEBUG 'Processing Views.....';
	FOR gcs IN 
	SELECT DISTINCT ON (c.oid) c.oid, n.nspname, c.relname
	    FROM pg_class c, 
	         pg_attribute a, 
	         pg_type t, 
	         pg_namespace n
	    WHERE c.relkind = 'v'
	    AND t.typname = 'geometry'
	    AND a.attisdropped = false
	    AND a.atttypid = t.oid
	    AND a.attrelid = c.oid
	    AND c.relnamespace = n.oid
	LOOP            
	    
	inserted := inserted + populate_geometry_columns(gcs.oid);
	END LOOP;

	IF oldcount > inserted THEN
	stale = oldcount-inserted;
	ELSE
	stale = 0;
	END IF;

	RETURN 'probed:' ||probed|| ' inserted:'||inserted|| ' conflicts:'||probed-inserted|| ' deleted:'||stale;
END

$$;


ALTER FUNCTION public.populate_geometry_columns() OWNER TO omar;

--
-- TOC entry 3338 (class 0 OID 0)
-- Dependencies: 440
-- Name: FUNCTION populate_geometry_columns(); Type: COMMENT; Schema: public; Owner: omar
--

COMMENT ON FUNCTION populate_geometry_columns() IS 'Ensures geometry columns have appropriate spatial constraints and exist in the geometry_columns table.';


--
-- TOC entry 441 (class 1255 OID 296954)
-- Name: populate_geometry_columns(oid); Type: FUNCTION; Schema: public; Owner: omar
--

CREATE FUNCTION populate_geometry_columns(tbl_oid oid) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	gcs         RECORD;
	gc          RECORD;
	gsrid       integer;
	gndims      integer;
	gtype       text;
	query       text;
	gc_is_valid boolean;
	inserted    integer;
	
BEGIN
	inserted := 0;
	
	-- Iterate through all geometry columns in this table
	FOR gcs IN 
	SELECT n.nspname, c.relname, a.attname
	    FROM pg_class c, 
	         pg_attribute a, 
	         pg_type t, 
	         pg_namespace n
	    WHERE c.relkind = 'r'
	    AND t.typname = 'geometry'
	    AND a.attisdropped = false
	    AND a.atttypid = t.oid
	    AND a.attrelid = c.oid
	    AND c.relnamespace = n.oid
	    AND n.nspname NOT ILIKE 'pg_temp%'
	    AND c.oid = tbl_oid
	LOOP
	
	RAISE DEBUG 'Processing table %.%.%', gcs.nspname, gcs.relname, gcs.attname;

	DELETE FROM geometry_columns 
	  WHERE f_table_schema = quote_ident(gcs.nspname) 
	  AND f_table_name = quote_ident(gcs.relname)
	  AND f_geometry_column = quote_ident(gcs.attname);
	
	gc_is_valid := true;
	
	-- Try to find srid check from system tables (pg_constraint)
	gsrid := 
	    (SELECT replace(replace(split_part(s.consrc, ' = ', 2), ')', ''), '(', '') 
	     FROM pg_class c, pg_namespace n, pg_attribute a, pg_constraint s 
	     WHERE n.nspname = gcs.nspname 
	     AND c.relname = gcs.relname 
	     AND a.attname = gcs.attname 
	     AND a.attrelid = c.oid
	     AND s.connamespace = n.oid
	     AND s.conrelid = c.oid
	     AND a.attnum = ANY (s.conkey)
	     AND s.consrc LIKE '%srid(% = %');
	IF (gsrid IS NULL) THEN 
	    -- Try to find srid from the geometry itself
	    EXECUTE 'SELECT public.srid(' || quote_ident(gcs.attname) || ') 
	             FROM ONLY ' || quote_ident(gcs.nspname) || '.' || quote_ident(gcs.relname) || ' 
	             WHERE ' || quote_ident(gcs.attname) || ' IS NOT NULL LIMIT 1' 
	        INTO gc;
	    gsrid := gc.srid;
	    
	    -- Try to apply srid check to column
	    IF (gsrid IS NOT NULL) THEN
	        BEGIN
	            EXECUTE 'ALTER TABLE ONLY ' || quote_ident(gcs.nspname) || '.' || quote_ident(gcs.relname) || ' 
	                     ADD CONSTRAINT ' || quote_ident('enforce_srid_' || gcs.attname) || ' 
	                     CHECK (srid(' || quote_ident(gcs.attname) || ') = ' || gsrid || ')';
	        EXCEPTION
	            WHEN check_violation THEN
	                RAISE WARNING 'Not inserting ''%'' in ''%.%'' into geometry_columns: could not apply constraint CHECK (srid(%) = %)', quote_ident(gcs.attname), quote_ident(gcs.nspname), quote_ident(gcs.relname), quote_ident(gcs.attname), gsrid;
	                gc_is_valid := false;
	        END;
	    END IF;
	END IF;
	
	-- Try to find ndims check from system tables (pg_constraint)
	gndims := 
	    (SELECT replace(split_part(s.consrc, ' = ', 2), ')', '') 
	     FROM pg_class c, pg_namespace n, pg_attribute a, pg_constraint s 
	     WHERE n.nspname = gcs.nspname 
	     AND c.relname = gcs.relname 
	     AND a.attname = gcs.attname 
	     AND a.attrelid = c.oid
	     AND s.connamespace = n.oid
	     AND s.conrelid = c.oid
	     AND a.attnum = ANY (s.conkey)
	     AND s.consrc LIKE '%ndims(% = %');
	IF (gndims IS NULL) THEN
	    -- Try to find ndims from the geometry itself
	    EXECUTE 'SELECT public.ndims(' || quote_ident(gcs.attname) || ') 
	             FROM ONLY ' || quote_ident(gcs.nspname) || '.' || quote_ident(gcs.relname) || ' 
	             WHERE ' || quote_ident(gcs.attname) || ' IS NOT NULL LIMIT 1' 
	        INTO gc;
	    gndims := gc.ndims;
	    
	    -- Try to apply ndims check to column
	    IF (gndims IS NOT NULL) THEN
	        BEGIN
	            EXECUTE 'ALTER TABLE ONLY ' || quote_ident(gcs.nspname) || '.' || quote_ident(gcs.relname) || ' 
	                     ADD CONSTRAINT ' || quote_ident('enforce_dims_' || gcs.attname) || ' 
	                     CHECK (ndims(' || quote_ident(gcs.attname) || ') = '||gndims||')';
	        EXCEPTION
	            WHEN check_violation THEN
	                RAISE WARNING 'Not inserting ''%'' in ''%.%'' into geometry_columns: could not apply constraint CHECK (ndims(%) = %)', quote_ident(gcs.attname), quote_ident(gcs.nspname), quote_ident(gcs.relname), quote_ident(gcs.attname), gndims;
	                gc_is_valid := false;
	        END;
	    END IF;
	END IF;
	
	-- Try to find geotype check from system tables (pg_constraint)
	gtype := 
	    (SELECT replace(split_part(s.consrc, '''', 2), ')', '') 
	     FROM pg_class c, pg_namespace n, pg_attribute a, pg_constraint s 
	     WHERE n.nspname = gcs.nspname 
	     AND c.relname = gcs.relname 
	     AND a.attname = gcs.attname 
	     AND a.attrelid = c.oid
	     AND s.connamespace = n.oid
	     AND s.conrelid = c.oid
	     AND a.attnum = ANY (s.conkey)
	     AND s.consrc LIKE '%geometrytype(% = %');
	IF (gtype IS NULL) THEN
	    -- Try to find geotype from the geometry itself
	    EXECUTE 'SELECT public.geometrytype(' || quote_ident(gcs.attname) || ') 
	             FROM ONLY ' || quote_ident(gcs.nspname) || '.' || quote_ident(gcs.relname) || ' 
	             WHERE ' || quote_ident(gcs.attname) || ' IS NOT NULL LIMIT 1' 
	        INTO gc;
	    gtype := gc.geometrytype;
	    --IF (gtype IS NULL) THEN
	    --    gtype := 'GEOMETRY';
	    --END IF;
	    
	    -- Try to apply geometrytype check to column
	    IF (gtype IS NOT NULL) THEN
	        BEGIN
	            EXECUTE 'ALTER TABLE ONLY ' || quote_ident(gcs.nspname) || '.' || quote_ident(gcs.relname) || ' 
	            ADD CONSTRAINT ' || quote_ident('enforce_geotype_' || gcs.attname) || ' 
	            CHECK ((geometrytype(' || quote_ident(gcs.attname) || ') = ' || quote_literal(gtype) || ') OR (' || quote_ident(gcs.attname) || ' IS NULL))';
	        EXCEPTION
	            WHEN check_violation THEN
	                -- No geometry check can be applied. This column contains a number of geometry types.
	                RAISE WARNING 'Could not add geometry type check (%) to table column: %.%.%', gtype, quote_ident(gcs.nspname),quote_ident(gcs.relname),quote_ident(gcs.attname);
	        END;
	    END IF;
	END IF;
	        
	IF (gsrid IS NULL) THEN             
	    RAISE WARNING 'Not inserting ''%'' in ''%.%'' into geometry_columns: could not determine the srid', quote_ident(gcs.attname), quote_ident(gcs.nspname), quote_ident(gcs.relname);
	ELSIF (gndims IS NULL) THEN
	    RAISE WARNING 'Not inserting ''%'' in ''%.%'' into geometry_columns: could not determine the number of dimensions', quote_ident(gcs.attname), quote_ident(gcs.nspname), quote_ident(gcs.relname);
	ELSIF (gtype IS NULL) THEN
	    RAISE WARNING 'Not inserting ''%'' in ''%.%'' into geometry_columns: could not determine the geometry type', quote_ident(gcs.attname), quote_ident(gcs.nspname), quote_ident(gcs.relname);
	ELSE
	    -- Only insert into geometry_columns if table constraints could be applied.
	    IF (gc_is_valid) THEN
	        INSERT INTO geometry_columns (f_table_catalog,f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) 
	        VALUES ('', gcs.nspname, gcs.relname, gcs.attname, gndims, gsrid, gtype);
	        inserted := inserted + 1;
	    END IF;
	END IF;
	END LOOP;

	-- Add views to geometry columns table
	FOR gcs IN 
	SELECT n.nspname, c.relname, a.attname
	    FROM pg_class c, 
	         pg_attribute a, 
	         pg_type t, 
	         pg_namespace n
	    WHERE c.relkind = 'v'
	    AND t.typname = 'geometry'
	    AND a.attisdropped = false
	    AND a.atttypid = t.oid
	    AND a.attrelid = c.oid
	    AND c.relnamespace = n.oid
	    AND n.nspname NOT ILIKE 'pg_temp%'
	    AND c.oid = tbl_oid
	LOOP            
	    RAISE DEBUG 'Processing view %.%.%', gcs.nspname, gcs.relname, gcs.attname;

	    EXECUTE 'SELECT public.ndims(' || quote_ident(gcs.attname) || ') 
	             FROM ' || quote_ident(gcs.nspname) || '.' || quote_ident(gcs.relname) || ' 
	             WHERE ' || quote_ident(gcs.attname) || ' IS NOT NULL LIMIT 1' 
	        INTO gc;
	    gndims := gc.ndims;
	    
	    EXECUTE 'SELECT public.srid(' || quote_ident(gcs.attname) || ') 
	             FROM ' || quote_ident(gcs.nspname) || '.' || quote_ident(gcs.relname) || ' 
	             WHERE ' || quote_ident(gcs.attname) || ' IS NOT NULL LIMIT 1' 
	        INTO gc;
	    gsrid := gc.srid;
	    
	    EXECUTE 'SELECT public.geometrytype(' || quote_ident(gcs.attname) || ') 
	             FROM ' || quote_ident(gcs.nspname) || '.' || quote_ident(gcs.relname) || ' 
	             WHERE ' || quote_ident(gcs.attname) || ' IS NOT NULL LIMIT 1' 
	        INTO gc;
	    gtype := gc.geometrytype;
	    
	    IF (gndims IS NULL) THEN
	        RAISE WARNING 'Not inserting ''%'' in ''%.%'' into geometry_columns: could not determine ndims', quote_ident(gcs.attname), quote_ident(gcs.nspname), quote_ident(gcs.relname);
	    ELSIF (gsrid IS NULL) THEN
	        RAISE WARNING 'Not inserting ''%'' in ''%.%'' into geometry_columns: could not determine srid', quote_ident(gcs.attname), quote_ident(gcs.nspname), quote_ident(gcs.relname);
	    ELSIF (gtype IS NULL) THEN
	        RAISE WARNING 'Not inserting ''%'' in ''%.%'' into geometry_columns: could not determine gtype', quote_ident(gcs.attname), quote_ident(gcs.nspname), quote_ident(gcs.relname);
	    ELSE
	        query := 'INSERT INTO geometry_columns (f_table_catalog,f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) ' ||
	                 'VALUES ('''', ' || quote_literal(gcs.nspname) || ',' || quote_literal(gcs.relname) || ',' || quote_literal(gcs.attname) || ',' || gndims || ',' || gsrid || ',' || quote_literal(gtype) || ')';
	        EXECUTE query;
	        inserted := inserted + 1;
	    END IF;
	END LOOP;
	
	RETURN inserted;
END

$$;


ALTER FUNCTION public.populate_geometry_columns(tbl_oid oid) OWNER TO omar;

--
-- TOC entry 3339 (class 0 OID 0)
-- Dependencies: 441
-- Name: FUNCTION populate_geometry_columns(tbl_oid oid); Type: COMMENT; Schema: public; Owner: omar
--

COMMENT ON FUNCTION populate_geometry_columns(tbl_oid oid) IS 'args: relation_oid - Ensures geometry columns have appropriate spatial constraints and exist in the geometry_columns table.';


--
-- TOC entry 445 (class 1255 OID 296968)
-- Name: probe_geometry_columns(); Type: FUNCTION; Schema: public; Owner: omar
--

CREATE FUNCTION probe_geometry_columns() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
	inserted integer;
	oldcount integer;
	probed integer;
	stale integer;
BEGIN

	SELECT count(*) INTO oldcount FROM geometry_columns;

	SELECT count(*) INTO probed
		FROM pg_class c, pg_attribute a, pg_type t, 
			pg_namespace n,
			pg_constraint sridcheck, pg_constraint typecheck

		WHERE t.typname = 'geometry'
		AND a.atttypid = t.oid
		AND a.attrelid = c.oid
		AND c.relnamespace = n.oid
		AND sridcheck.connamespace = n.oid
		AND typecheck.connamespace = n.oid
		AND sridcheck.conrelid = c.oid
		AND sridcheck.consrc LIKE '(srid('||a.attname||') = %)'
		AND typecheck.conrelid = c.oid
		AND typecheck.consrc LIKE
		'((geometrytype('||a.attname||') = ''%''::text) OR (% IS NULL))'
		;

	INSERT INTO geometry_columns SELECT
		''::varchar as f_table_catalogue,
		n.nspname::varchar as f_table_schema,
		c.relname::varchar as f_table_name,
		a.attname::varchar as f_geometry_column,
		2 as coord_dimension,
		trim(both  ' =)' from 
			replace(replace(split_part(
				sridcheck.consrc, ' = ', 2), ')', ''), '(', ''))::integer AS srid,
		trim(both ' =)''' from substr(typecheck.consrc, 
			strpos(typecheck.consrc, '='),
			strpos(typecheck.consrc, '::')-
			strpos(typecheck.consrc, '=')
			))::varchar as type
		FROM pg_class c, pg_attribute a, pg_type t, 
			pg_namespace n,
			pg_constraint sridcheck, pg_constraint typecheck
		WHERE t.typname = 'geometry'
		AND a.atttypid = t.oid
		AND a.attrelid = c.oid
		AND c.relnamespace = n.oid
		AND sridcheck.connamespace = n.oid
		AND typecheck.connamespace = n.oid
		AND sridcheck.conrelid = c.oid
		AND sridcheck.consrc LIKE '(st_srid('||a.attname||') = %)'
		AND typecheck.conrelid = c.oid
		AND typecheck.consrc LIKE
		'((geometrytype('||a.attname||') = ''%''::text) OR (% IS NULL))'

	        AND NOT EXISTS (
	                SELECT oid FROM geometry_columns gc
	                WHERE c.relname::varchar = gc.f_table_name
	                AND n.nspname::varchar = gc.f_table_schema
	                AND a.attname::varchar = gc.f_geometry_column
	        );

	GET DIAGNOSTICS inserted = ROW_COUNT;

	IF oldcount > probed THEN
		stale = oldcount-probed;
	ELSE
		stale = 0;
	END IF;

	RETURN 'probed:'||probed::text||
		' inserted:'||inserted::text||
		' conflicts:'||(probed-inserted)::text||
		' stale:'||stale::text;
END

$$;


ALTER FUNCTION public.probe_geometry_columns() OWNER TO omar;

--
-- TOC entry 3340 (class 0 OID 0)
-- Dependencies: 445
-- Name: FUNCTION probe_geometry_columns(); Type: COMMENT; Schema: public; Owner: omar
--

COMMENT ON FUNCTION probe_geometry_columns() IS 'Scans all tables with PostGIS geometry constraints and adds them to the geometry_columns table if they are not there.';


--
-- TOC entry 448 (class 1255 OID 296972)
-- Name: rename_geometry_table_constraints(); Type: FUNCTION; Schema: public; Owner: omar
--

CREATE FUNCTION rename_geometry_table_constraints() RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
SELECT 'rename_geometry_table_constraint() is obsoleted'::text
$$;


ALTER FUNCTION public.rename_geometry_table_constraints() OWNER TO omar;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 232 (class 1259 OID 397862)
-- Name: beijing_alternative; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE beijing_alternative (
    oid integer,
    otime integer,
    lan double precision,
    lon double precision
);


ALTER TABLE public.beijing_alternative OWNER TO omar;

--
-- TOC entry 235 (class 1259 OID 398010)
-- Name: beijing_original; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE beijing_original (
    oid integer,
    otime integer,
    lan double precision,
    lon double precision
);


ALTER TABLE public.beijing_original OWNER TO omar;

--
-- TOC entry 161 (class 1259 OID 297223)
-- Name: diskname; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE diskname (
    did integer NOT NULL,
    tag character varying(100) NOT NULL,
    CONSTRAINT diskname_tag_check CHECK (((tag)::text <> ''::text))
);


ALTER TABLE public.diskname OWNER TO omar;

--
-- TOC entry 162 (class 1259 OID 297227)
-- Name: diskname_did_seq; Type: SEQUENCE; Schema: public; Owner: omar
--

CREATE SEQUENCE diskname_did_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.diskname_did_seq OWNER TO omar;

--
-- TOC entry 163 (class 1259 OID 297229)
-- Name: diskname_did_seq1; Type: SEQUENCE; Schema: public; Owner: omar
--

CREATE SEQUENCE diskname_did_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.diskname_did_seq1 OWNER TO omar;

--
-- TOC entry 3341 (class 0 OID 0)
-- Dependencies: 163
-- Name: diskname_did_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: omar
--

ALTER SEQUENCE diskname_did_seq1 OWNED BY diskname.did;


--
-- TOC entry 164 (class 1259 OID 297231)
-- Name: disks; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE disks (
    "time" integer,
    cid integer,
    gids character varying
);


ALTER TABLE public.disks OWNER TO omar;

--
-- TOC entry 165 (class 1259 OID 297237)
-- Name: flickr; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE flickr (
    id integer,
    photo_id double precision,
    owner_id character(510),
    owner_uname character(510),
    dates_taken timestamp without time zone,
    loc_lon double precision,
    loc_lat double precision
);


ALTER TABLE public.flickr OWNER TO omar;

--
-- TOC entry 239 (class 1259 OID 463363)
-- Name: flocklines; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE flocklines (
    fid integer,
    started integer,
    ended integer,
    members character varying,
    line character varying
);


ALTER TABLE public.flocklines OWNER TO omar;

--
-- TOC entry 166 (class 1259 OID 297249)
-- Name: flocklines_beijing; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE flocklines_beijing (
    id integer,
    started integer,
    ended integer,
    members character varying,
    line character varying,
    followers character varying
);


ALTER TABLE public.flocklines_beijing OWNER TO omar;

--
-- TOC entry 167 (class 1259 OID 297255)
-- Name: flocklines_followers; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE flocklines_followers (
    id integer,
    started integer,
    ended integer,
    members character varying,
    line character varying,
    followers character varying
);


ALTER TABLE public.flocklines_followers OWNER TO omar;

--
-- TOC entry 168 (class 1259 OID 297261)
-- Name: flockpoints; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE flockpoints (
    id integer,
    "time" integer,
    point character varying
);


ALTER TABLE public.flockpoints OWNER TO omar;

--
-- TOC entry 169 (class 1259 OID 297267)
-- Name: flocks; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE flocks (
    id integer,
    started integer,
    ended integer,
    members character varying,
    route character varying,
    disks character varying
);


ALTER TABLE public.flocks OWNER TO omar;

--
-- TOC entry 213 (class 1259 OID 373182)
-- Name: flocksbfe; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE flocksbfe (
    fid integer,
    started integer,
    ended integer,
    members character varying
);


ALTER TABLE public.flocksbfe OWNER TO omar;

--
-- TOC entry 236 (class 1259 OID 414222)
-- Name: flocksfp; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE flocksfp (
    fid integer,
    started integer,
    ended integer,
    members character varying
);


ALTER TABLE public.flocksfp OWNER TO omar;

--
-- TOC entry 237 (class 1259 OID 447273)
-- Name: flocksfponline; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE flocksfponline (
    fid integer,
    started integer,
    ended integer,
    members character varying
);


ALTER TABLE public.flocksfponline OWNER TO omar;

--
-- TOC entry 208 (class 1259 OID 356940)
-- Name: flocksj10000t100t500freal; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE flocksj10000t100t500freal (
    fid integer,
    started integer,
    ended integer,
    members character varying
);


ALTER TABLE public.flocksj10000t100t500freal OWNER TO omar;

--
-- TOC entry 209 (class 1259 OID 364990)
-- Name: flocksj12500t100t500freal; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE flocksj12500t100t500freal (
    fid integer,
    started integer,
    ended integer,
    members character varying
);


ALTER TABLE public.flocksj12500t100t500freal OWNER TO omar;

--
-- TOC entry 210 (class 1259 OID 364996)
-- Name: flocksj15000t100t500freal; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE flocksj15000t100t500freal (
    fid integer,
    started integer,
    ended integer,
    members character varying
);


ALTER TABLE public.flocksj15000t100t500freal OWNER TO omar;

--
-- TOC entry 211 (class 1259 OID 365002)
-- Name: flocksj17500t100t500freal; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE flocksj17500t100t500freal (
    fid integer,
    started integer,
    ended integer,
    members character varying
);


ALTER TABLE public.flocksj17500t100t500freal OWNER TO omar;

--
-- TOC entry 212 (class 1259 OID 365008)
-- Name: flocksj20000t100t500freal; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE flocksj20000t100t500freal (
    fid integer,
    started integer,
    ended integer,
    members character varying
);


ALTER TABLE public.flocksj20000t100t500freal OWNER TO omar;

--
-- TOC entry 205 (class 1259 OID 356921)
-- Name: flocksj2500t100t500freal; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE flocksj2500t100t500freal (
    fid integer,
    started integer,
    ended integer,
    members character varying
);


ALTER TABLE public.flocksj2500t100t500freal OWNER TO omar;

--
-- TOC entry 201 (class 1259 OID 356897)
-- Name: flocksj5000t100t100freal; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE flocksj5000t100t100freal (
    fid integer,
    started integer,
    ended integer,
    members character varying
);


ALTER TABLE public.flocksj5000t100t100freal OWNER TO omar;

--
-- TOC entry 202 (class 1259 OID 356903)
-- Name: flocksj5000t100t200freal; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE flocksj5000t100t200freal (
    fid integer,
    started integer,
    ended integer,
    members character varying
);


ALTER TABLE public.flocksj5000t100t200freal OWNER TO omar;

--
-- TOC entry 203 (class 1259 OID 356909)
-- Name: flocksj5000t100t300freal; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE flocksj5000t100t300freal (
    fid integer,
    started integer,
    ended integer,
    members character varying
);


ALTER TABLE public.flocksj5000t100t300freal OWNER TO omar;

--
-- TOC entry 204 (class 1259 OID 356915)
-- Name: flocksj5000t100t400freal; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE flocksj5000t100t400freal (
    fid integer,
    started integer,
    ended integer,
    members character varying
);


ALTER TABLE public.flocksj5000t100t400freal OWNER TO omar;

--
-- TOC entry 206 (class 1259 OID 356927)
-- Name: flocksj5000t100t500freal; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE flocksj5000t100t500freal (
    fid integer,
    started integer,
    ended integer,
    members character varying
);


ALTER TABLE public.flocksj5000t100t500freal OWNER TO omar;

--
-- TOC entry 207 (class 1259 OID 356933)
-- Name: flocksj7500t100t500freal; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE flocksj7500t100t500freal (
    fid integer,
    started integer,
    ended integer,
    members character varying
);


ALTER TABLE public.flocksj7500t100t500freal OWNER TO omar;

--
-- TOC entry 238 (class 1259 OID 455446)
-- Name: flockslcm; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE flockslcm (
    fid integer,
    started integer,
    ended integer,
    members character varying
);


ALTER TABLE public.flockslcm OWNER TO omar;

--
-- TOC entry 170 (class 1259 OID 297273)
-- Name: flocksmfi; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE flocksmfi (
    fid integer,
    started integer,
    ended integer,
    members character varying
);


ALTER TABLE public.flocksmfi OWNER TO omar;

--
-- TOC entry 171 (class 1259 OID 297279)
-- Name: flocksmfi2; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE flocksmfi2 (
    fid integer,
    t integer,
    members character varying
);


ALTER TABLE public.flocksmfi2 OWNER TO omar;

--
-- TOC entry 172 (class 1259 OID 297285)
-- Name: flocksmfi3; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE flocksmfi3 (
    fid integer,
    started integer,
    ended integer,
    members character varying
);


ALTER TABLE public.flocksmfi3 OWNER TO omar;

--
-- TOC entry 173 (class 1259 OID 297291)
-- Name: fromgenerator; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE fromgenerator (
    name character varying,
    id integer,
    seq integer,
    class integer,
    "time" integer,
    lat double precision,
    lon double precision,
    speed double precision,
    x integer,
    y integer
);


ALTER TABLE public.fromgenerator OWNER TO omar;

--
-- TOC entry 174 (class 1259 OID 297297)
-- Name: gdisks; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE gdisks (
    "time" integer,
    p1 integer,
    p2 integer,
    point1 character varying,
    point2 character varying
);


ALTER TABLE public.gdisks OWNER TO omar;

--
-- TOC entry 229 (class 1259 OID 389691)
-- Name: geolife; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE geolife (
    tid integer,
    ttime timestamp without time zone,
    lat numeric,
    lon numeric
);


ALTER TABLE public.geolife OWNER TO omar;

--
-- TOC entry 230 (class 1259 OID 389697)
-- Name: geolife2; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE geolife2 (
    tid integer,
    ttime timestamp without time zone,
    lat numeric,
    lon numeric,
    the_geom geometry
);


ALTER TABLE public.geolife2 OWNER TO omar;

--
-- TOC entry 233 (class 1259 OID 397976)
-- Name: geolife3; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE geolife3 (
    oid integer,
    otime integer,
    lat numeric,
    lon numeric
);


ALTER TABLE public.geolife3 OWNER TO omar;

--
-- TOC entry 234 (class 1259 OID 398007)
-- Name: geolife4; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE geolife4 (
    oid integer,
    otime integer,
    lan double precision,
    lon double precision
);


ALTER TABLE public.geolife4 OWNER TO omar;

--
-- TOC entry 175 (class 1259 OID 297321)
-- Name: geolife5; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE geolife5 (
    tid integer,
    ttime integer,
    lat numeric,
    lon numeric
);


ALTER TABLE public.geolife5 OWNER TO omar;

--
-- TOC entry 176 (class 1259 OID 297327)
-- Name: geolife6; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE geolife6 (
    tid integer,
    ttime integer,
    lat numeric,
    lon numeric
);


ALTER TABLE public.geolife6 OWNER TO omar;

--
-- TOC entry 177 (class 1259 OID 297333)
-- Name: geolife7; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE geolife7 (
    tid integer,
    ttime integer,
    lat numeric,
    lon numeric
);


ALTER TABLE public.geolife7 OWNER TO omar;

--
-- TOC entry 178 (class 1259 OID 297339)
-- Name: geolife8; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE geolife8 (
    tid integer,
    ttime integer,
    lat numeric,
    lon numeric
);


ALTER TABLE public.geolife8 OWNER TO omar;

--
-- TOC entry 179 (class 1259 OID 297345)
-- Name: geolife9; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE geolife9 (
    tid integer,
    ttime integer,
    lat numeric,
    lon numeric
);


ALTER TABLE public.geolife9 OWNER TO omar;

--
-- TOC entry 180 (class 1259 OID 297357)
-- Name: gfdisks; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE gfdisks (
    "time" integer,
    nmembers integer,
    members character varying,
    point1 character varying
);


ALTER TABLE public.gfdisks OWNER TO omar;

--
-- TOC entry 181 (class 1259 OID 297363)
-- Name: gflocks; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE gflocks (
    id integer,
    started integer,
    ended integer,
    members character varying
);


ALTER TABLE public.gflocks OWNER TO omar;

--
-- TOC entry 200 (class 1259 OID 322194)
-- Name: gflocks2; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE gflocks2 (
    id integer,
    started integer,
    ended integer,
    members character varying
);


ALTER TABLE public.gflocks2 OWNER TO omar;

--
-- TOC entry 182 (class 1259 OID 297369)
-- Name: gflocks_lines; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE gflocks_lines (
    members character varying,
    started integer,
    ended integer,
    line character varying
);


ALTER TABLE public.gflocks_lines OWNER TO omar;

--
-- TOC entry 183 (class 1259 OID 297375)
-- Name: grid; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE grid (
    "time" integer,
    index character varying,
    point character varying
);


ALTER TABLE public.grid OWNER TO omar;

--
-- TOC entry 184 (class 1259 OID 297381)
-- Name: iceberg_to_remove; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE iceberg_to_remove (
    gid integer,
    iceberg character varying(255),
    date numeric(10,0)
);


ALTER TABLE public.iceberg_to_remove OWNER TO omar;

--
-- TOC entry 185 (class 1259 OID 297384)
-- Name: icebergs06; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE icebergs06 (
    tid integer,
    "time" integer,
    x double precision,
    y double precision
);


ALTER TABLE public.icebergs06 OWNER TO omar;

--
-- TOC entry 186 (class 1259 OID 297387)
-- Name: icebergs2; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE icebergs2 (
    tid integer,
    "time" integer,
    x double precision,
    y double precision
);


ALTER TABLE public.icebergs2 OWNER TO omar;

--
-- TOC entry 187 (class 1259 OID 297390)
-- Name: icebergs3; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE icebergs3 (
    tid integer,
    "time" integer,
    x double precision,
    y double precision
);


ALTER TABLE public.icebergs3 OWNER TO omar;

--
-- TOC entry 188 (class 1259 OID 297393)
-- Name: icebergs_all_quadrants_gid_seq; Type: SEQUENCE; Schema: public; Owner: omar
--

CREATE SEQUENCE icebergs_all_quadrants_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.icebergs_all_quadrants_gid_seq OWNER TO omar;

--
-- TOC entry 189 (class 1259 OID 297395)
-- Name: lines; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE lines (
    "time" integer,
    line character varying
);


ALTER TABLE public.lines OWNER TO omar;

--
-- TOC entry 199 (class 1259 OID 305807)
-- Name: oldenburg; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE oldenburg (
    oid integer,
    otime integer,
    lat real,
    lon real
);


ALTER TABLE public.oldenburg OWNER TO omar;

--
-- TOC entry 190 (class 1259 OID 297401)
-- Name: pairs; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE pairs (
    "time" integer,
    p1 integer,
    p2 integer,
    line character varying
);


ALTER TABLE public.pairs OWNER TO omar;

--
-- TOC entry 191 (class 1259 OID 297407)
-- Name: results_beijing; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE results_beijing (
    id integer,
    started integer,
    ended integer,
    members character varying,
    line character varying,
    followers character varying
);


ALTER TABLE public.results_beijing OWNER TO omar;

--
-- TOC entry 192 (class 1259 OID 297413)
-- Name: sanjoaquin; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE sanjoaquin (
    gid integer,
    "time" integer,
    traj character varying
);


ALTER TABLE public.sanjoaquin OWNER TO omar;

--
-- TOC entry 193 (class 1259 OID 297425)
-- Name: tags; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE tags (
    code integer NOT NULL,
    tag text
);


ALTER TABLE public.tags OWNER TO omar;

--
-- TOC entry 194 (class 1259 OID 297431)
-- Name: tags_code_seq; Type: SEQUENCE; Schema: public; Owner: omar
--

CREATE SEQUENCE tags_code_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tags_code_seq OWNER TO omar;

--
-- TOC entry 3342 (class 0 OID 0)
-- Dependencies: 194
-- Name: tags_code_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: omar
--

ALTER SEQUENCE tags_code_seq OWNED BY tags.code;


--
-- TOC entry 215 (class 1259 OID 373311)
-- Name: tapas; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE tapas (
    oid integer,
    otime integer,
    lat real,
    lon real
);


ALTER TABLE public.tapas OWNER TO omar;

--
-- TOC entry 231 (class 1259 OID 397827)
-- Name: tapas2; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE tapas2 (
    oid integer,
    otime integer,
    lat real,
    lon real
);


ALTER TABLE public.tapas2 OWNER TO omar;

--
-- TOC entry 214 (class 1259 OID 373191)
-- Name: test; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE test (
    dataset character varying,
    epsilon integer,
    mu integer,
    delta integer,
    timetest real,
    flocks integer,
    tag character varying
);


ALTER TABLE public.test OWNER TO omar;

--
-- TOC entry 195 (class 1259 OID 297433)
-- Name: trans; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE trans (
    tid integer,
    centre character varying
);


ALTER TABLE public.trans OWNER TO omar;

--
-- TOC entry 196 (class 1259 OID 297439)
-- Name: transactions; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE transactions (
    pid integer,
    cid character varying,
    point character varying
);


ALTER TABLE public.transactions OWNER TO omar;

--
-- TOC entry 197 (class 1259 OID 297445)
-- Name: tt; Type: TABLE; Schema: public; Owner: omar; Tablespace: 
--

CREATE TABLE tt (
    tid integer,
    cid integer,
    cname character varying
);


ALTER TABLE public.tt OWNER TO omar;

--
-- TOC entry 198 (class 1259 OID 297451)
-- Name: world_gid_seq; Type: SEQUENCE; Schema: public; Owner: omar
--

CREATE SEQUENCE world_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.world_gid_seq OWNER TO omar;

--
-- TOC entry 3208 (class 2604 OID 297453)
-- Name: did; Type: DEFAULT; Schema: public; Owner: omar
--

ALTER TABLE ONLY diskname ALTER COLUMN did SET DEFAULT nextval('diskname_did_seq1'::regclass);


--
-- TOC entry 3210 (class 2604 OID 297454)
-- Name: code; Type: DEFAULT; Schema: public; Owner: omar
--

ALTER TABLE ONLY tags ALTER COLUMN code SET DEFAULT nextval('tags_code_seq'::regclass);


--
-- TOC entry 3212 (class 1259 OID 297462)
-- Name: geolife5_tid_ttime; Type: INDEX; Schema: public; Owner: omar; Tablespace: 
--

CREATE INDEX geolife5_tid_ttime ON geolife5 USING btree (tid, ttime);


--
-- TOC entry 3213 (class 1259 OID 297463)
-- Name: geolife6_tid_ttime; Type: INDEX; Schema: public; Owner: omar; Tablespace: 
--

CREATE INDEX geolife6_tid_ttime ON geolife6 USING btree (tid, ttime);


--
-- TOC entry 3214 (class 1259 OID 297464)
-- Name: geolife7_tid_ttime; Type: INDEX; Schema: public; Owner: omar; Tablespace: 
--

CREATE INDEX geolife7_tid_ttime ON geolife7 USING btree (tid, ttime);


--
-- TOC entry 3215 (class 1259 OID 297465)
-- Name: geolife8_tid_ttime; Type: INDEX; Schema: public; Owner: omar; Tablespace: 
--

CREATE INDEX geolife8_tid_ttime ON geolife8 USING btree (tid, ttime);


--
-- TOC entry 3216 (class 1259 OID 297466)
-- Name: geolife9_tid_ttime; Type: INDEX; Schema: public; Owner: omar; Tablespace: 
--

CREATE INDEX geolife9_tid_ttime ON geolife9 USING btree (tid, ttime);


--
-- TOC entry 3217 (class 1259 OID 297467)
-- Name: tid_time_icebergs2; Type: INDEX; Schema: public; Owner: omar; Tablespace: 
--

CREATE INDEX tid_time_icebergs2 ON icebergs2 USING btree (tid, "time");


--
-- TOC entry 3332 (class 0 OID 0)
-- Dependencies: 6
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2014-10-17 15:55:55 COT

--
-- PostgreSQL database dump complete
--

