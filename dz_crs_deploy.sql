WHENEVER SQLERROR EXIT -99;
WHENEVER OSERROR  EXIT -98;
SET DEFINE OFF;

--******************************--
PROMPT Packages/DZ_CRS_UTIL.pks 

CREATE OR REPLACE PACKAGE dz_crs_util
AUTHID CURRENT_USER
AS
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION gz_split(
       p_str              IN  VARCHAR2
      ,p_regex            IN  VARCHAR2
      ,p_match            IN  VARCHAR2 DEFAULT NULL
      ,p_end              IN  NUMBER   DEFAULT 0
      ,p_trim             IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN MDSYS.SDO_STRING2_ARRAY DETERMINISTIC;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION strings2numbers(
      p_input             IN  MDSYS.SDO_STRING2_ARRAY
   ) RETURN MDSYS.SDO_NUMBER_ARRAY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION safe_to_number(
       p_input            IN  VARCHAR2
      ,p_null_replacement IN  NUMBER DEFAULT NULL
   ) RETURN NUMBER;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE simple_dual_split(
       p_input            IN  VARCHAR2
      ,p_delimiter        IN  VARCHAR2
      ,p_output_left      OUT VARCHAR2
      ,p_output_right     OUT VARCHAR
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION condense_whitespace(
       p_input            IN  VARCHAR2
      ,p_character        IN  VARCHAR2 DEFAULT ' '
   ) RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE point2coordinates(
       p_input             IN  MDSYS.SDO_GEOMETRY
      ,p_x                 OUT NUMBER
      ,p_y                 OUT NUMBER
      ,p_z                 OUT NUMBER
      ,p_m                 OUT NUMBER
   );

END dz_crs_util;
/

GRANT EXECUTE ON dz_crs_util TO PUBLIC;

--******************************--
PROMPT Packages/DZ_CRS_UTIL.pkb 

CREATE OR REPLACE PACKAGE BODY dz_crs_util
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION gz_split(
       p_str         IN  VARCHAR2
      ,p_regex       IN  VARCHAR2
      ,p_match       IN  VARCHAR2 DEFAULT NULL
      ,p_end         IN  NUMBER   DEFAULT 0
      ,p_trim        IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN MDSYS.SDO_STRING2_ARRAY DETERMINISTIC 
   AS
      int_delim      PLS_INTEGER;
      int_position   PLS_INTEGER := 1;
      int_counter    PLS_INTEGER := 1;
      ary_output     MDSYS.SDO_STRING2_ARRAY;
      num_end        NUMBER      := p_end;
      str_trim       VARCHAR2(5 Char) := UPPER(p_trim);
      
      FUNCTION trim_varray(
         p_input            IN MDSYS.SDO_STRING2_ARRAY
      ) RETURN MDSYS.SDO_STRING2_ARRAY
      AS
         ary_output MDSYS.SDO_STRING2_ARRAY := MDSYS.SDO_STRING2_ARRAY();
         int_index  PLS_INTEGER := 1;
         str_check  VARCHAR2(4000 Char);
         
      BEGIN

         --------------------------------------------------------------------------
         -- Step 10
         -- Exit if input is empty
         --------------------------------------------------------------------------
         IF p_input IS NULL
         OR p_input.COUNT = 0
         THEN
            RETURN ary_output;
            
         END IF;

         --------------------------------------------------------------------------
         -- Step 20
         -- Trim the strings removing anything utterly trimmed away
         --------------------------------------------------------------------------
         FOR i IN 1 .. p_input.COUNT
         LOOP
            str_check := TRIM(p_input(i));
            
            IF str_check IS NULL
            OR str_check = ''
            THEN
               NULL;
               
            ELSE
               ary_output.EXTEND(1);
               ary_output(int_index) := str_check;
               int_index := int_index + 1;
               
            END IF;

         END LOOP;

         --------------------------------------------------------------------------
         -- Step 10
         -- Return the results
         --------------------------------------------------------------------------
         RETURN ary_output;

      END trim_varray;

   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Create the output array and check parameters
      --------------------------------------------------------------------------
      ary_output := MDSYS.SDO_STRING2_ARRAY();

      IF str_trim IS NULL
      THEN
         str_trim := 'FALSE';
         
      ELSIF str_trim NOT IN ('TRUE','FALSE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;

      IF num_end IS NULL
      THEN
         num_end := 0;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- Exit early if input is empty
      --------------------------------------------------------------------------
      IF p_str IS NULL
      OR p_str = ''
      THEN
         RETURN ary_output;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 30
      -- Account for weird instance of pure character breaking
      --------------------------------------------------------------------------
      IF p_regex IS NULL
      OR p_regex = ''
      THEN
         FOR i IN 1 .. LENGTH(p_str)
         LOOP
            ary_output.EXTEND(1);
            ary_output(i) := SUBSTR(p_str,i,1);
            
         END LOOP;
         
         RETURN ary_output;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 40
      -- Break string using the usual REGEXP functions
      --------------------------------------------------------------------------
      LOOP
         EXIT WHEN int_position = 0;
         int_delim  := REGEXP_INSTR(p_str,p_regex,int_position,1,0,p_match);
         
         IF  int_delim = 0
         THEN
            -- no more matches found
            ary_output.EXTEND(1);
            ary_output(int_counter) := SUBSTR(p_str,int_position);
            int_position  := 0;
            
         ELSE
            IF int_counter = num_end
            THEN
               -- take the rest as is
               ary_output.EXTEND(1);
               ary_output(int_counter) := SUBSTR(p_str,int_position);
               int_position  := 0;
               
            ELSE
               --dbms_output.put_line(ary_output.COUNT);
               ary_output.EXTEND(1);
               ary_output(int_counter) := SUBSTR(p_str,int_position,int_delim-int_position);
               int_counter := int_counter + 1;
               int_position := REGEXP_INSTR(p_str,p_regex,int_position,1,1,p_match);
               
            END IF;
            
         END IF;
         
      END LOOP;

      --------------------------------------------------------------------------
      -- Step 50
      -- Trim results if so desired
      --------------------------------------------------------------------------
      IF str_trim = 'TRUE'
      THEN
         RETURN trim_varray(
            p_input => ary_output
         );
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 60
      -- Cough out the results
      --------------------------------------------------------------------------
      RETURN ary_output;
      
   END gz_split;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION strings2numbers(
      p_input            IN MDSYS.SDO_STRING2_ARRAY
   ) RETURN MDSYS.SDO_NUMBER_ARRAY
   AS
      ary_output MDSYS.SDO_NUMBER_ARRAY := MDSYS.SDO_NUMBER_ARRAY();
      num_tester NUMBER;
      int_index  PLS_INTEGER := 1;

   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Exit if input is empty
      --------------------------------------------------------------------------
      IF p_input IS NULL
      OR p_input.COUNT = 0
      THEN
         RETURN ary_output;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- Convert anything that is a valid number to a number, dump the rest
      --------------------------------------------------------------------------
      FOR i IN 1 .. p_input.COUNT
      LOOP
         IF p_input(i) IS NOT NULL
         THEN
            num_tester := safe_to_number(
               p_input => p_input(i)
            );
            
            IF num_tester IS NOT NULL
            THEN
               ary_output.EXTEND();
               ary_output(int_index) := num_tester;
               int_index := int_index + 1;
               
            END IF;
            
         END IF;
         
      END LOOP;

      RETURN ary_output;

   END strings2numbers;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION safe_to_number(
       p_input            IN VARCHAR2
      ,p_null_replacement IN NUMBER DEFAULT NULL
   ) RETURN NUMBER
   AS
   BEGIN
      RETURN TO_NUMBER(
         REPLACE(
            REPLACE(
               p_input,
               CHR(10),
               ''
            ),
            CHR(13),
            ''
         ) 
      );
      
   EXCEPTION
      WHEN VALUE_ERROR
      THEN
         RETURN p_null_replacement;
         
   END safe_to_number;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE simple_dual_split(
       p_input           IN  VARCHAR2
      ,p_delimiter       IN  VARCHAR2
      ,p_output_left     OUT VARCHAR2
      ,p_output_right    OUT VARCHAR
   )
   AS
      ary_splits  MDSYS.SDO_STRING2_ARRAY;
      
   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Exit early if input is empty
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         RETURN;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- Split the input, one split only
      --------------------------------------------------------------------------
      ary_splits := gz_split(
         p_str   => p_input,
         p_regex => p_delimiter,
         p_end   => 2
      );
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Figure out the results
      --------------------------------------------------------------------------
      IF ary_splits.COUNT = 1
      THEN
         p_output_left  := ary_splits(1);
         p_output_right := NULL;
         
      ELSIF ary_splits.COUNT = 2
      THEN
         p_output_left  := ary_splits(1);
         p_output_right := ary_splits(2);
         
      ELSE
         RAISE_APPLICATION_ERROR(-20001,'parsing input');
         
      END IF;

   END simple_dual_split;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION condense_whitespace(
       p_input        IN  VARCHAR2
      ,p_character    IN  VARCHAR2 DEFAULT ' '
   ) RETURN VARCHAR2
   AS
      str_output    VARCHAR2(4000 Char);
      str_character VARCHAR2(1 Char) := p_character;
      boo_check     BOOLEAN;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF str_character IS NULL
      THEN
         str_character := ' ';
         
      END IF;
      
      IF p_input IS NULL
      THEN
         RETURN NULL;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20 
      -- Loop through the string and replace stuttering whitespace
      --------------------------------------------------------------------------
      str_output := '';
      boo_check  := FALSE;
      
      FOR i IN 1 .. LENGTH(p_input)
      LOOP
         IF SUBSTR(p_input,i,1) = str_character
         THEN
            IF boo_check = FALSE
            THEN
               str_output := str_output || str_character;
               
            END IF;
            
            boo_check := TRUE;
            
         ELSE
            boo_check := FALSE;
            str_output := str_output || SUBSTR(p_input,i,1);
            
         END IF; 
       
      END LOOP;
      
      --------------------------------------------------------------------------
      -- Step 30 
      -- Return results
      --------------------------------------------------------------------------
      RETURN str_output;
      
   END condense_whitespace;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE point2coordinates(
      p_input   IN  MDSYS.SDO_GEOMETRY,
      p_x       OUT NUMBER,
      p_y       OUT NUMBER,
      p_z       OUT NUMBER,
      p_m       OUT NUMBER
   )
   AS
      int_gtype     PLS_INTEGER;
      int_dims      PLS_INTEGER;
      int_lrs       PLS_INTEGER;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      int_gtype := p_input.get_gtype();
      int_dims  := p_input.get_dims();
      int_lrs   := p_input.get_lrs_dim();
      
      IF int_gtype != 1
      THEN
         RAISE_APPLICATION_ERROR(-20001,'input must be a single point');
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Unload the ordinates
      --------------------------------------------------------------------------
      IF p_input.SDO_POINT IS NULL
      THEN
         p_x := p_input.SDO_ORDINATES(1);
         p_y := p_input.SDO_ORDINATES(2);
         
         IF int_dims > 2
         THEN
            IF int_lrs = 3
            THEN
               p_m := p_input.SDO_ORDINATES(3);
               
            ELSE
               p_z := p_input.SDO_ORDINATES(3);
               
            END IF;
            
         END IF;
         
         IF int_dims > 3
         THEN
            IF int_lrs IN (4,0)
            THEN
               p_m := p_input.SDO_ORDINATES(4);
               
            ELSE
               p_z := p_input.SDO_ORDINATES(4);
               
            END IF;
            
         END IF;
         
      ELSE
      
         p_x := p_input.SDO_POINT.X;
         p_y := p_input.SDO_POINT.Y;
         
         IF int_dims > 2
         THEN
            IF int_lrs = 3
            THEN
               p_m := p_input.SDO_POINT.Z;
               
            ELSE
               p_z := p_input.SDO_POINT.Z;
               
            END IF;
            
         END IF;
         
      END IF;
      
   END point2coordinates;
   
END dz_crs_util;
/

--******************************--
PROMPT Packages/DZ_CRS_MAIN.pks 

CREATE OR REPLACE PACKAGE dz_crs_main
AUTHID CURRENT_USER
AS
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   header: DZ_CRS
     
   - Release: 
   - Commit Date: Mon Oct 10 16:39:58 2016 -0400
   
   Utilities for the management and manipulation of Oracle Spatial and Graph 
   transformations and grids.
   
   */
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_crs_main.geodetic_XY_diminfo

   Function to quickly return a "default" geodetic dimensional info array.

   Parameters:

      None
      
   Returns:

      MDSYS.SDO_DIM_ARRAY collection
      
   Notes:
   
   - Assumes 5 centimeter tolerance for all geodetic spatial information. 

   */
   FUNCTION geodetic_XY_diminfo
   RETURN MDSYS.SDO_DIM_ARRAY;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_crs_main.geodetic_XYZ_diminfo

   Function to quickly return a "default" 3D geodetic dimensional info array.

   Parameters:

      p_z_lower_bound - optional override for lower Z bound (default -15000)
      p_z_upper_bound - optional override for upper Z bound (default 15000)
      p_z_tolerance   - optional override for Z tolerance (default 0.001 units)
      
   Returns:

      MDSYS.SDO_DIM_ARRAY collection
      
   Notes:
   
   - Assumes 5 centimeter tolerance for all geodetic spatial information. 

   */
   FUNCTION geodetic_XYZ_diminfo(
       p_z_lower_bound  IN NUMBER DEFAULT -15000
      ,p_z_upper_bound  IN NUMBER DEFAULT 15000
      ,p_z_tolerance    IN NUMBER DEFAULT 0.001
   ) RETURN MDSYS.SDO_DIM_ARRAY;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_crs_main.geodetic_XYM_diminfo

   Function to quickly return a "default" LRS geodetic dimensional info array.

   Parameters:

      p_m_lower_bound - optional override for lower M bound (default 0)
      p_m_upper_bound - optional override for upper M bound (default 100)
      p_m_tolerance   - optional override for M tolerance (default 0.00001 units)
      
   Returns:

      MDSYS.SDO_DIM_ARRAY collection
      
   Notes:
   
   - Assumes 5 centimeter tolerance for all geodetic spatial information. 
   
   - M defaults represent common reach measure system used in the US National
     hydrology dataset.

   */
   FUNCTION geodetic_XYM_diminfo(
       p_m_lower_bound  IN NUMBER DEFAULT 0
      ,p_m_upper_bound  IN NUMBER DEFAULT 100
      ,p_m_tolerance    IN NUMBER DEFAULT 0.00001
   ) RETURN MDSYS.SDO_DIM_ARRAY;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_crs_main.geodetic_XYZM_diminfo

   Function to quickly return a "default" 3D LRS geodetic dimensional info array.

   Parameters:

      p_z_lower_bound - optional override for lower Z bound (default -15000)
      p_z_upper_bound - optional override for upper Z bound (default 15000)
      p_z_tolerance   - optional override for Z tolerance (default 0.001 units)
      p_m_lower_bound - optional override for lower M bound (default 0)
      p_m_upper_bound - optional override for upper M bound (default 100)
      p_m_tolerance   - optional override for M tolerance (default 0.00001 units)
      
   Returns:

      MDSYS.SDO_DIM_ARRAY collection
      
   Notes:
   
   - Assumes 5 centimeter tolerance for all geodetic spatial information. 
   
   - M defaults represent common reach measure system used in the US National
     hydrology dataset.

   */
   FUNCTION geodetic_XYZM_diminfo(
       p_z_lower_bound  IN NUMBER DEFAULT -15000
      ,p_z_upper_bound  IN NUMBER DEFAULT 15000
      ,p_z_tolerance    IN NUMBER DEFAULT 0.001
      ,p_m_lower_bound  IN NUMBER DEFAULT 0
      ,p_m_upper_bound  IN NUMBER DEFAULT 100
      ,p_m_tolerance    IN NUMBER DEFAULT 0.00001
   ) RETURN MDSYS.SDO_DIM_ARRAY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_crs_main.generic_common_mbr

   Function to return a minumum bounding rectangle geometry surrounding a given
   named region.

   Parameters:

      p_input - region keyword
      p_srid - optional SRID override, default is 8265
      
   Returns:

      MDSYS.SDO_GEOMETRY MBR surrounding desired region.
      
   Notes:
   
   - Current regions include CONUS, ALASKA, HAWAII, PR/VI and PACTERR.  Note the 
     Alaska and Pacific Trust Territory MBRs are split into two polygons and thus
     do not cross the 180.  In theory Oracle spatial should have no problems with
     a polygon crossing the 180 but at the end of the day its always safer to
     break on the 180.
   
   - The srid override does not test if a user provided srid is in fact geodetic.
     Make sure you always use a geodetic srid.

   */
   FUNCTION generic_common_mbr(
       p_input          IN  VARCHAR2
      ,p_srid           IN  NUMBER DEFAULT 8265
   ) RETURN MDSYS.SDO_GEOMETRY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_crs_main.query_generic_common_mbr

   Function to return the region keyword (if any) associated with a given geometry.

   Parameters:

      p_input - input geomety to examine
      p_tolerance - optional tolerance override, default is 0.05
      p_check_earth - optional test to verify that input geometry
      is in fact geodetic.  Useful in cases where raw input may be of 
      dubious quality.
      
   Returns:

      VARCHAR2 string text region keyword or NULL if no regions .
      
   Notes:
   
   - Current regions include CONUS, ALASKA, HAWAII, PR/VI and PACTERR.
   
   - For geometries other than points, the first set of vertices in the geometry
     are used for the test.
     
   - Any geometry input srid may be utilized as test mbrs are transformed to the
     input geometry srid if they do not match (default is 8265).

   */
   FUNCTION query_generic_common_mbr(
       p_input          IN  MDSYS.SDO_GEOMETRY
      ,p_tolerance      IN  NUMBER   DEFAULT 0.05
      ,p_check_earth    IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_crs_main.nadcon_grid

   Function to determine the appropriate NAD27 transformation method for a given
   geometry location.  

   Parameters:

      p_input - input geomety to examine
      p_tolerance - optional tolerance override, default is 0.05
      
   Returns:

      NUMBER of NADCON grid covering the location in question or -2 to indicate
      no grid coverage.
      
   Notes:
   
   - An answer of -2 would indicate to use a Molodensky transformation for NAD27
     conversions.

   */
   FUNCTION nadcon_grid(
       p_input          IN  MDSYS.SDO_GEOMETRY
      ,p_tolerance      IN  NUMBER DEFAULT 0.05
   ) RETURN NUMBER;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_crs_main.nadcon_4267_to_8265

   Utility to automate the transformation of NAD27 geometry to NAD83.  Utility 
   will utilize NADCON grids where possible or Molodensky where not.  

   Parameters:

      p_input - input NAD27 geomety to transform
      p_identifier - optional NADCON grid keyword to avoid the overhead of
      testing the input for the correct grid.  Force NULL to use Molodensky.
      p_tolerance - optional tolerance override, default is 0.05
      
   Returns:

      MDSYS.SDO_GEOMETRY in NAD83
      
   Notes:
    
      - NADCON grid keywords include CONUS, HAWAII, PR/VI, ALASKA,
        ST. LAWRENCE ISLAND, ST. PAUL ISLAND and ST. GEORGE ISLAND
        
   */
   FUNCTION nadcon_4267_to_8265(
       p_input          IN  MDSYS.SDO_GEOMETRY
      ,p_tolerance      IN  NUMBER DEFAULT 0.05
   ) RETURN MDSYS.SDO_GEOMETRY;
   
   FUNCTION nadcon_4267_to_8265(
       p_input          IN  MDSYS.SDO_GEOMETRY
      ,p_identifier     IN  VARCHAR2
      ,p_tolerance      IN  NUMBER DEFAULT 0.05
   ) RETURN MDSYS.SDO_GEOMETRY;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_crs_main.determine_srid

   Somewhat specific utility intended to interpret and convert to an Oracle
   Spatial srid a variety of coordinate system naming inputs.  

   Parameters:

      p_input - input coordinate reference system 
      
   Returns:

      NUMBER of best matching SDO_SRID
      
   Notes:
   
     - SRID=1234 will return 1234
   
     - SRSNAME=SDO:1234 or SDO:1234 will return 1234

     - SRSNAME=EPSG:1234 or EPSG:1234 will return 1234

     - A limited number of SRSNAME urns are supported such as
       urn:ogc:def:crs:OGC:*:crs84 returns 8307
       urn:ogc:def:crs:OGC:*:crs83 returns 8265
       urn:ogc:def:crs:EPSG:*:1234 returns 1234
       
     - All derived SRIDs are then tested against the local Oracle Spatial
       installation for validity.
       
     - For more detailed feedback on any problems encountered utilize the
       procedure version which provides an error code and detailed status message.

   */
   FUNCTION determine_srid(
      p_input           IN  VARCHAR2
   ) RETURN NUMBER;
   
   PROCEDURE determine_srid(
       p_input          IN  VARCHAR2
      ,p_output         OUT NUMBER
      ,p_return_code    OUT NUMBER
      ,p_status_message OUT VARCHAR2
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_crs_main.parse_ogc_urn

   Simple utility to quickly parse an OGC urn into component parts.

   Parameters:

      p_input - input urn to decompose
      
   Returns:

      p_urn - first component
      p_ogc - second component
      p_def - third component
      p_objectType - fourth component
      p_authority - fifth component
      p_version - sixth component
      p_code - seventh component
      
   */
   PROCEDURE parse_ogc_urn(
       p_input          IN  VARCHAR2
      ,p_urn            OUT VARCHAR2
      ,p_ogc            OUT VARCHAR2
      ,p_def            OUT VARCHAR2
      ,p_objectType     OUT VARCHAR2
      ,p_authority      OUT VARCHAR2
      ,p_version        OUT VARCHAR2
      ,p_code           OUT VARCHAR2
   );

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_crs_main.epsg2srid

   Simply utility to convert epsg style srids to old Oracle equivalents  

   Parameters:

      p_input - input epsg srid
      
   Returns:

      NUMBER of old Oracle Spatial srid
      
   Notes:
   
     - Used to quickly swap 4269 for 8265 and 4326 to 8307.
       
     - Any unknown srids are just returned in the output.

   */
   FUNCTION epsg2srid(
      p_input           IN  NUMBER
   ) RETURN NUMBER;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_crs_main.srs2srid

   Utility to convert SRS coordinate system identifiers into Oracle Spatials srids.

   Parameters:

      p_input - input SRS identifier
      
   Returns:

      NUMBER of old Oracle Spatial srid
      
   Notes:
   
     - As SRS identifiers may provide critical information as to the order of the 
       axes in a given spatial dataset, utilize the procedure version which returns
       an additional p_axes_latlong parameter of TRUE/FALSE indicating the whether 
       the axes are reversed with latitude first.

   */
   FUNCTION srs2srid(
      p_input           IN  VARCHAR2
   ) RETURN NUMBER;
   
   PROCEDURE srs2srid(
       p_input          IN  VARCHAR2
      ,p_srid           OUT NUMBER
      ,p_axes_latlong   OUT VARCHAR2
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_crs_main.srid2srs

   Simplistic utility to return srs values for a very limited number of Oracle 
   Spatial srids.

   Parameters:

      p_input - input srid
      
   Returns:

      VARCHAR2 SRS value

   */
   FUNCTION srid2srs(
      p_input           IN  NUMBER
   ) RETURN VARCHAR2;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_crs_main.smart_transform

   Somewhat obnoxiously named wrapper to avoid running transformations on srid
   equivalents and also will force spherical math transformations when srid 
   3785 is utilized.

   Parameters:

      p_input - input geometry to transform
      p_srid - srid to use for transformation
      
   Returns:

      MDSYS.SDO_GEOMETRY 

   */
   FUNCTION smart_transform(
       p_input          IN  MDSYS.SDO_GEOMETRY
      ,p_srid           IN  NUMBER
   ) RETURN MDSYS.SDO_GEOMETRY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Procedure: dz_crs_main.grid_clob_to_header

   Utility to extract from a NADCOD grid the header information.

   Parameters:

      p_clob - NADCON grid
      
   Returns:

      p_col_count - grid column count
      p_row_count - grid row count
      p_z_count - grid z count
      p_min_long - grid minimum longitude
      p_long_cell -grid longitude cell value
      p_min_lat - grid minimum latitude
      p_lat_cell - grid latitude cell value

   */
   PROCEDURE grid_clob_to_header(
       p_clob           IN  CLOB
      ,p_col_count      OUT NUMBER
      ,p_row_count      OUT NUMBER
      ,p_z_count        OUT NUMBER
      ,p_min_long       OUT NUMBER
      ,p_long_cell      OUT NUMBER
      ,p_min_lat        OUT NUMBER
      ,p_lat_cell       OUT NUMBER
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_crs_main.grid_to_mbr

   Utility to extract from a NADCON grid the MBR surrounding it.

   Parameters:

      p_coord_op_param - coordinate op number of a given grid
      
   Returns:

      MDSYS.SDO_GEOMETRY 

   */
   FUNCTION grid_to_mbr(
      p_coord_op_param  IN  NUMBER
   ) RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Procedure: dz_crs_main.unwrap_etype3

   Utility to extract from a Oracle Spatial optimized rectangle (MBR) the min
   and max point.  Includes option to remove third and fourth dimensions.

   Parameters:

      p_input - optimized rectangle geometry to decompose
      p_2d_flag - optional TRUE/FALSE flag to remove any third or fourth 
      dimensions
      
   Returns:

      p_min_point - minimum (lower left) MBR vertice
      p_max_point - maximum (upper right) MBR vertice

   */
   PROCEDURE unwrap_etype3(
       p_input          IN  MDSYS.SDO_GEOMETRY
      ,p_min_point      OUT MDSYS.SDO_GEOMETRY
      ,p_max_point      OUT MDSYS.SDO_GEOMETRY
      ,p_2d_flag        IN  VARCHAR2 DEFAULT 'FALSE'
   );

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Procedure: dz_crs_main.wrap_etype3

   Utility to build an optimized rectangle (MBR) from two input points.  
   Includes option to remove third and fourth dimensions.

   Parameters:

      p_min_point - minimum (lower left) MBR vertice
      p_max_point - maximum (upper right) MBR vertice
      p_2d_flag - optional TRUE/FALSE flag to remove any third or fourth 
      dimensions
      
   Returns:

      p_output - optimized rectangle geometry
      
   */
   PROCEDURE wrap_etype3(
       p_output         OUT MDSYS.SDO_GEOMETRY
      ,p_min_point      IN  MDSYS.SDO_GEOMETRY
      ,p_max_point      IN  MDSYS.SDO_GEOMETRY
      ,p_2d_flag        IN  VARCHAR2 DEFAULT 'FALSE'
   );

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_crs_main.transform_etype3

   Utility to allow the direct transformation of an optimized rectangle into a
   another coordinate reference system.  When using SDO_TRANSFORM directly upon
   a geodetic optimized rectangle, the rectangle will be converted to a densified
   polygon which may not be desired.  This utility decomposes the rectangle into
   components points, transforms those points, and then puts the rectangle back
   together.

   Parameters:

      p_input - optimized rectangle geometry to transform
      p_output_srid - srid to use in transformation
      p_2d_flag - optional TRUE/FALSE flag to remove any third or fourth 
      dimensions
      
   Returns:

      MDSYS.SDO_GEOMETRY 

   */
   FUNCTION transform_etype3(
       p_input          IN  MDSYS.SDO_GEOMETRY
      ,p_output_srid    IN  NUMBER
      ,p_2d_flag        IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN MDSYS.SDO_GEOMETRY;

END dz_crs_main;
/

GRANT EXECUTE ON dz_crs_main TO public;

--******************************--
PROMPT Packages/DZ_CRS_MAIN.pkb 

CREATE OR REPLACE PACKAGE BODY dz_crs_main
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION geodetic_XY_diminfo
   RETURN MDSYS.SDO_DIM_ARRAY
   AS
   BEGIN
      RETURN MDSYS.SDO_DIM_ARRAY(
          MDSYS.SDO_DIM_ELEMENT(
              'X'
             ,-180
             ,180
             ,0.05
          )
         ,MDSYS.SDO_DIM_ELEMENT(
              'Y'
             ,-90
             ,90
             ,0.05
          )
      );
      
   END geodetic_XY_diminfo;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION geodetic_XYZ_diminfo(
       p_z_lower_bound NUMBER DEFAULT -15000
      ,p_z_upper_bound NUMBER DEFAULT 15000
      ,p_z_tolerance   NUMBER DEFAULT 0.001
   ) RETURN MDSYS.SDO_DIM_ARRAY
   AS
   BEGIN
      RETURN MDSYS.SDO_DIM_ARRAY(
          MDSYS.SDO_DIM_ELEMENT(
              'X'
             ,-180
             ,180
             ,.05
          )
         ,MDSYS.SDO_DIM_ELEMENT(
              'Y'
             ,-90
             ,90
             ,.05
          )
         ,MDSYS.SDO_DIM_ELEMENT(
              'Z'
             ,p_z_lower_bound
             ,p_z_upper_bound
             ,p_z_tolerance
          )
      );
      
   END geodetic_XYZ_diminfo;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION geodetic_XYM_diminfo(
       p_m_lower_bound NUMBER DEFAULT 0
      ,p_m_upper_bound NUMBER DEFAULT 100
      ,p_m_tolerance   NUMBER DEFAULT 0.00001
   ) RETURN MDSYS.SDO_DIM_ARRAY
   AS
   BEGIN
      RETURN MDSYS.SDO_DIM_ARRAY(
          MDSYS.SDO_DIM_ELEMENT(
              'X'
             ,-180
             ,180
             ,.05
          )
         ,MDSYS.SDO_DIM_ELEMENT(
              'Y'
             ,-90
             ,90
             ,.05
          )
         ,MDSYS.SDO_DIM_ELEMENT(
              'M'
             ,p_m_lower_bound
             ,p_m_upper_bound
             ,p_m_tolerance
          )
      );
      
   END geodetic_XYM_diminfo;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION geodetic_XYZM_diminfo(
       p_z_lower_bound NUMBER DEFAULT -15000
      ,p_z_upper_bound NUMBER DEFAULT 15000
      ,p_z_tolerance   NUMBER DEFAULT 0.001
      ,p_m_lower_bound NUMBER DEFAULT 0
      ,p_m_upper_bound NUMBER DEFAULT 100
      ,p_m_tolerance   NUMBER DEFAULT 0.00001
   ) RETURN MDSYS.SDO_DIM_ARRAY
   AS
   BEGIN
      RETURN MDSYS.SDO_DIM_ARRAY(
          MDSYS.SDO_DIM_ELEMENT(
              'X'
             ,-180
             ,180
             ,.05
          )
         ,MDSYS.SDO_DIM_ELEMENT(
              'Y'
             ,-90
             ,90
             ,.05
          )
         ,MDSYS.SDO_DIM_ELEMENT(
              'Z'
             ,p_z_lower_bound
             ,p_z_upper_bound
             ,p_z_tolerance
          )
         ,MDSYS.SDO_DIM_ELEMENT(
              'M'
             ,p_m_lower_bound
             ,p_m_upper_bound
             ,p_m_tolerance
          )
      );
      
   END geodetic_XYZM_diminfo;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION generic_common_mbr(
       p_input      IN  VARCHAR2
      ,p_srid       IN  NUMBER DEFAULT 8265
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
      str_input VARCHAR2(4000 Char) := UPPER(p_input);
      num_srid  NUMBER := p_srid;
      
   BEGIN
   
      -------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      -------------------------------------------------------------------------
      IF num_srid IS NULL
      THEN
         num_srid := 8265;
         
      END IF;
      
      -------------------------------------------------------------------------
      -- Step 20
      -- Return mbr around the area in question
      -------------------------------------------------------------------------
      IF str_input IN ('CONUS','US','USA')
      THEN
         RETURN MDSYS.SDO_GEOMETRY(
             2003
            ,num_srid
            ,NULL
            ,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,3)
            ,MDSYS.SDO_ORDINATE_ARRAY(-128,23,-64,52)
         );
         
      ELSIF str_input IN ('AK','ALASKA')
      THEN
         RETURN MDSYS.SDO_GEOMETRY(
             2007
            ,num_srid
            ,NULL
            ,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,3,5,1003,3)
            ,MDSYS.SDO_ORDINATE_ARRAY(-180,48,-128,90,168,48,180,90)
         );
         
      ELSIF str_input IN ('HI','HAWAII')
      THEN
         RETURN MDSYS.SDO_GEOMETRY(
             2003
            ,num_srid
            ,NULL
            ,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,3)
            ,MDSYS.SDO_ORDINATE_ARRAY(-180,10,-146,35)
         );
         
      ELSIF str_input IN ('PR','VI','PR/VI','PRVI')
      THEN
         RETURN MDSYS.SDO_GEOMETRY(
             2003
            ,num_srid
            ,NULL
            ,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,3)
            ,MDSYS.SDO_ORDINATE_ARRAY(-69,16,-63,20)
         );
         
      ELSIF str_input IN ('PACTRUST','PACTERR','PACIFIC')
      THEN
         RETURN MDSYS.SDO_GEOMETRY(
             2007
            ,num_srid
            ,NULL
            ,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,3,5,1003,3)
            ,MDSYS.SDO_ORDINATE_ARRAY(136,8,154,25,-178,-20,-163,-5)
         );
           
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'unknown generic mbr code'
         );
         
      END IF;
   
   END generic_common_mbr;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION query_generic_common_mbr(
       p_input       IN  MDSYS.SDO_GEOMETRY
      ,p_tolerance   IN  NUMBER   DEFAULT 0.05
      ,p_check_earth IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN VARCHAR2
   AS
      sdo_point       MDSYS.SDO_GEOMETRY;
      num_tolerance   NUMBER := p_tolerance;
      str_check_earth VARCHAR2(4000 Char) := UPPER(p_check_earth);
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check incoming parameters
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         RETURN NULL;
         
      END IF;
      
      IF num_tolerance IS NULL
      THEN
         num_tolerance := 0.05;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Skim off a representative point
      --------------------------------------------------------------------------
      IF p_input.SDO_POINT IS NOT NULL
      THEN
         sdo_point := MDSYS.SDO_GEOMETRY(
             2001
            ,p_input.SDO_SRID
            ,MDSYS.SDO_POINT_TYPE(
                 p_input.SDO_POINT.x
                ,p_input.SDO_POINT.y
                ,NULL
             )
            ,NULL
            ,NULL
         );
         
      ELSE
         sdo_point := MDSYS.SDO_GEOMETRY(
             2001
            ,p_input.SDO_SRID
            ,MDSYS.SDO_POINT_TYPE(
                 p_input.SDO_ORDINATES(1)
                ,p_input.SDO_ORDINATES(2)
                ,NULL
             )
            ,NULL
            ,NULL
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- check the boxes
      --------------------------------------------------------------------------
      IF MDSYS.SDO_GEOM.RELATE(
         geom1   => sdo_point,
         mask    => 'DETERMINE',
         geom2   => smart_transform(
            p_input => generic_common_mbr(p_input => 'CONUS'),
            p_srid  => sdo_point.SDO_SRID
         ),
         tol     => num_tolerance
      ) = 'INSIDE'
      THEN
         RETURN 'CONUS';
      
      ELSIF MDSYS.SDO_GEOM.RELATE(
         geom1   => sdo_point,
         mask    => 'DETERMINE',
         geom2   => smart_transform(
            p_input => generic_common_mbr(p_input => 'HI'),
            p_srid  => sdo_point.SDO_SRID
         ),
         tol     => num_tolerance
      ) = 'INSIDE'
      THEN
         RETURN 'HI';
         
      ELSIF MDSYS.SDO_GEOM.RELATE(
         geom1   => sdo_point,
         mask    => 'DETERMINE',
         geom2   => smart_transform(
            p_input => generic_common_mbr(p_input => 'PRVI'),
            p_srid  => sdo_point.SDO_SRID
         ),
         tol     => num_tolerance
      ) = 'INSIDE'
      THEN
         RETURN 'PRVI';
         
      ELSIF MDSYS.SDO_GEOM.RELATE(
         geom1   => sdo_point,
         mask    => 'DETERMINE',
         geom2   => smart_transform(
            p_input => generic_common_mbr(p_input => 'AK'),
            p_srid  => sdo_point.SDO_SRID
         ),
         tol     => num_tolerance
      ) = 'INSIDE'
      THEN
         RETURN 'AK';
         
      ELSIF MDSYS.SDO_GEOM.RELATE(
         geom1   => sdo_point,
         mask    => 'DETERMINE',
         geom2   => smart_transform(
            p_input => generic_common_mbr(p_input => 'PACTERR'),
            p_srid  => sdo_point.SDO_SRID
         ),
         tol     => num_tolerance
      ) = 'INSIDE'
      THEN
         RETURN 'PACTERR';

      END IF;
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Check globe for CS mismatch
      --------------------------------------------------------------------------
      IF str_check_earth = 'TRUE'
      THEN
         sdo_point := smart_transform(
             p_input => sdo_point
            ,p_srid  => 8265
         );
         
         IF sdo_point.SDO_POINT.X > 180 
         OR sdo_point.SDO_POINT.X < -180
         OR sdo_point.SDO_POINT.Y > 90
         OR sdo_point.SDO_POINT.Y < -90
         THEN
            RETURN 'CSERR';
            
         END IF;

      END IF;
      
      RETURN NULL;
   
   END query_generic_common_mbr;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION nadcon_grid(
       p_input      IN  MDSYS.SDO_GEOMETRY
      ,p_tolerance  IN  NUMBER DEFAULT 0.05
   ) RETURN NUMBER
   AS
      num_tolerance    NUMBER       := p_tolerance;
   
      num_molodensky   NUMBER       := -2;
      num_nad27_conus  NUMBER       := 1241;
      sdo_nad27_conus  MDSYS.SDO_GEOMETRY := grid_to_mbr(num_nad27_conus);
      num_nad27_alaska NUMBER       := 1243;
      sdo_nad27_alaska MDSYS.SDO_GEOMETRY := grid_to_mbr(num_nad27_alaska);
      num_nad27_stlaw  NUMBER       := 1455;
      sdo_nad27_stlaw  MDSYS.SDO_GEOMETRY := grid_to_mbr(num_nad27_stlaw);
      num_nad27_stpaul NUMBER       := 1456;
      sdo_nad27_stpaul MDSYS.SDO_GEOMETRY := grid_to_mbr(num_nad27_stpaul);
      num_nad27_stgeo  NUMBER       := 1457;
      sdo_nad27_stgeo  MDSYS.SDO_GEOMETRY := grid_to_mbr(num_nad27_stgeo);
      num_nad27_hawaii NUMBER       := 1454;
      sdo_nad27_hawaii MDSYS.SDO_GEOMETRY := grid_to_mbr(num_nad27_hawaii);
      num_nad27_prvi   NUMBER       := 1461;
      sdo_nad27_prvi   MDSYS.SDO_GEOMETRY := grid_to_mbr(num_nad27_prvi);
   
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 20
      -- Determine what grid operation to use
      --------------------------------------------------------------------------
      -- Assume that things are probably conus
      IF MDSYS.SDO_GEOM.RELATE(
          geom1 => sdo_nad27_conus
         ,mask  => 'ANYINTERACT'
         ,geom2 => p_input
         ,tol   => num_tolerance
      ) = 'TRUE'
      THEN
         RETURN num_nad27_conus;
         
      -- then try Hawaii
      ELSIF MDSYS.SDO_GEOM.RELATE(
          geom1 => sdo_nad27_hawaii
         ,mask  => 'ANYINTERACT'
         ,geom2 => p_input
         ,tol   => num_tolerance
      ) = 'TRUE'
      THEN
         RETURN num_nad27_hawaii;
         
      -- then try PR/VI
      ELSIF MDSYS.SDO_GEOM.RELATE(
          geom1 => sdo_nad27_prvi
         ,mask  => 'ANYINTERACT'
         ,geom2 => p_input
         ,tol   => num_tolerance
      ) = 'TRUE'
      THEN
         RETURN num_nad27_prvi;
         
      -- then try St. Lawrence
      ELSIF MDSYS.SDO_GEOM.RELATE(
          geom1 => sdo_nad27_stlaw
         ,mask  => 'ANYINTERACT'
         ,geom2 => p_input
         ,tol   => num_tolerance
      ) = 'TRUE'
      THEN
         RETURN num_nad27_stlaw;
         
      -- then try St. Paul
      ELSIF MDSYS.SDO_GEOM.RELATE(
          geom1 => sdo_nad27_stpaul
         ,mask  => 'ANYINTERACT'
         ,geom2 => p_input
         ,tol   => num_tolerance
      ) = 'TRUE'
      THEN
         RETURN num_nad27_stpaul;
         
      -- then try St. George
      ELSIF MDSYS.SDO_GEOM.RELATE(
          geom1 => sdo_nad27_stgeo
         ,mask  => 'ANYINTERACT'
         ,geom2 => p_input
         ,tol   => num_tolerance
      ) = 'TRUE'
      THEN
         RETURN num_nad27_stgeo;
         
      -- then try Alaska itself
      ELSIF MDSYS.SDO_GEOM.RELATE(
          geom1 => sdo_nad27_alaska
         ,mask  => 'ANYINTERACT'
         ,geom2 => p_input
         ,tol   => num_tolerance
      ) = 'TRUE'
      THEN
         RETURN num_nad27_alaska;
         
      -- Thus its somewhere outside the NADCON grid system so use molodensky
      ELSE
         RETURN num_molodensky;
         
      END IF;
   
   END nadcon_grid;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION nadcon_4267_to_8265(
       p_input      IN  MDSYS.SDO_GEOMETRY
      ,p_tolerance  IN  NUMBER DEFAULT 0.05
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
      sdo_output       MDSYS.SDO_GEOMETRY;
      num_tolerance    NUMBER := p_tolerance;
      tfm_results      MDSYS.TFM_PLAN;
      num_operation    NUMBER;

   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         RETURN NULL;
         
      END IF;
      
      IF p_input.SDO_SRID != 4267
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input geometry must have srid 4267'
         );
         
      END IF;
      
      IF num_tolerance IS NULL
      THEN
         num_tolerance := 0.05;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Determine what grid operation to use
      --------------------------------------------------------------------------
      num_operation := nadcon_grid(
          p_input     => p_input
         ,p_tolerance => num_tolerance
      );
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Transform the geometry
      --------------------------------------------------------------------------
      tfm_results := MDSYS.TFM_PLAN();
      tfm_results.the_plan := MDSYS.SDO_TFM_CHAIN(4267,num_operation,4269);
      sdo_output := MDSYS.SDO_CS.TRANSFORM(
          geom     => p_input
         ,use_plan => tfm_results
      );
      
      sdo_output.SDO_SRID := 8265;
      
      RETURN sdo_output;

   END nadcon_4267_to_8265;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION nadcon_4267_to_8265(
       p_input      IN  MDSYS.SDO_GEOMETRY
      ,p_identifier IN  VARCHAR2
      ,p_tolerance  IN  NUMBER DEFAULT 0.05
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
      sdo_output       MDSYS.SDO_GEOMETRY;
      num_tolerance    NUMBER       := p_tolerance;
      str_identifier   VARCHAR2(4000 Char) := UPPER(p_identifier);
      
      num_molodensky   NUMBER       := -2;
      num_nad27_conus  NUMBER       := 1241;
      num_nad27_alaska NUMBER       := 1243;
      num_nad27_stlaw  NUMBER       := 1455;
      num_nad27_stpaul NUMBER       := 1456;
      num_nad27_stgeo  NUMBER       := 1457;
      num_nad27_hawaii NUMBER       := 1454;
      num_nad27_prvi   NUMBER       := 1461;
      tfm_results      MDSYS.TFM_PLAN;
      num_operation    NUMBER;

   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         RETURN NULL;
         
      END IF;
      
      IF p_input.SDO_SRID != 4267
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input geometry must have srid 4267'
         );
         
      END IF;
      
      IF num_tolerance IS NULL
      THEN
         num_tolerance := 0.05;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Determine what grid operation to use
      --------------------------------------------------------------------------
      IF str_identifier IN ('CONUS','48','LOWER48')
      THEN
         num_operation := num_nad27_conus;
         
      ELSIF str_identifier IN ('HI','HAWAII')
      THEN
         num_operation := num_nad27_hawaii;
         
      ELSIF str_identifier IN ('PRVI','PR','VI','PR/VI','VIPR','VI/PR','PUERTO RICO','VIRGIN ISLANDS')
      THEN
         num_operation := num_nad27_prvi;
         
      ELSIF str_identifier IN ('STLRNC','ST. LAWRENCE','ST. LAWRENCE ISLAND')
      THEN
         num_operation := num_nad27_stlaw;
         
      ELSIF str_identifier IN ('STPAUL','ST. PAUL','ST. PAUL ISLAND')
      THEN
         num_operation := num_nad27_stpaul;
         
      ELSIF str_identifier IN ('STGEORG','ST. GEORGE','ST. GEORGE ISLAND')
      THEN
         num_operation := num_nad27_stgeo;
         
      ELSIF str_identifier IN ('ALASKA','AK')
      THEN
         num_operation := num_nad27_alaska;
         
      ELSE
         num_operation := num_molodensky;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Transform the geometry
      --------------------------------------------------------------------------
      tfm_results := MDSYS.TFM_PLAN();
      tfm_results.the_plan := MDSYS.SDO_TFM_CHAIN(4267,num_operation,4269);
      sdo_output := MDSYS.SDO_CS.TRANSFORM(
          geom     => p_input
         ,use_plan => tfm_results
      );
      
      sdo_output.SDO_SRID := 8265;
      
      RETURN sdo_output;

   END nadcon_4267_to_8265;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION determine_srid(
      p_input   IN  VARCHAR2
   ) RETURN NUMBER
   AS
      num_output  NUMBER;
      num_return  NUMBER;
      str_message VARCHAR2(4000 Char);
      
   BEGIN
   
      determine_srid(
          p_input          => p_input
         ,p_output         => num_output
         ,p_return_code    => num_return
         ,p_status_message => str_message
      );
      
      IF num_return = 0
      THEN
         RETURN num_output;
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'error ' || TO_CHAR(num_return) || ': ' || str_message
         );
         
      END IF;
      
   END determine_srid;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE determine_srid(
       p_input          IN  VARCHAR2
      ,p_output         OUT NUMBER
      ,p_return_code    OUT NUMBER
      ,p_status_message OUT VARCHAR2
   )
   AS
      num_default_srid  NUMBER := 8265;  -- default SRID
      str_left_side     VARCHAR2(4000 Char);
      str_right_side    VARCHAR2(4000 Char);
      num_srid_output   NUMBER;
      num_check         NUMBER;

   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Exit early if input is empty or "the usual"
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         p_output := num_default_srid;
         p_return_code := 0;
         p_status_message := 'WARNING: Empty Input'; 
         RETURN;
         
      ELSIF p_input ='WKT'
      THEN
         p_output := num_default_srid;
         p_return_code := 0;
         p_status_message := NULL; 
         RETURN;
      
      ELSIF p_input ='WKT,SRID=8265'
      THEN
         p_output := 8265;
         p_return_code := 0;
         p_status_message := NULL; 
         RETURN;
      
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- First check for the SRID= and SRSNAME= formats
      --------------------------------------------------------------------------
      dz_crs_util.simple_dual_split(
         p_input           => p_input,
         p_delimiter       => '=',
         p_output_left     => str_left_side,
         p_output_right    => str_right_side
      );

      IF UPPER(str_left_side) = 'SRID'
      AND str_right_side IS NOT NULL
      THEN
         num_srid_output := dz_crs_util.safe_to_number(str_right_side);
         IF num_srid_output IS NULL
         THEN
            p_output         := NULL;
            p_return_code    := -90;
            p_status_message := 'unable to parse SRID from ' || p_input || '.';
            RETURN;
            
         END IF;
         
         p_return_code    := 0;
         p_status_message := NULL;
         
      ELSIF UPPER(str_left_side) = 'SRSNAME'
      AND str_right_side IS NOT NULL
      THEN
         num_srid_output := srs2srid(str_right_side);
         IF num_srid_output IS NULL
         THEN
            p_output         := NULL;
            p_return_code    := -91;
            p_status_message := 'ERROR, unable to parse spatial reference from ' || p_input || '.';
            RETURN;
            
         END IF;
         
         p_return_code    := 0;
         p_status_message := NULL;
      
      END IF;

      --------------------------------------------------------------------------
      -- Step 30
      -- Next check for the EPSG: and SDO: formats
      --------------------------------------------------------------------------
      dz_crs_util.simple_dual_split(
         p_input           => p_input,
         p_delimiter       => ':',
         p_output_left     => str_left_side,
         p_output_right    => str_right_side
      );

      IF UPPER(str_left_side) = 'EPSG'
      AND str_right_side IS NOT NULL
      THEN
         num_srid_output := dz_crs_util.safe_to_number(str_right_side);
         IF num_srid_output IS NULL
         THEN
            p_output         := NULL;
            p_return_code    := -92;
            p_status_message := 'unable to parse numeric EPSG code from ' || p_input || '.';
            RETURN;

         END IF;
         
         num_srid_output  := epsg2srid(num_srid_output);
         p_return_code    := 0;
         p_status_message := NULL;
         
      ELSIF UPPER(str_left_side) = 'SDO'
      AND str_right_side IS NOT NULL
      THEN
         num_srid_output := dz_crs_util.safe_to_number(str_right_side);
         IF num_srid_output IS NULL
         THEN
            p_output         := NULL;
            p_return_code    := -93;
            p_status_message := 'unable to parse numeric SDO code from ' || p_input || '.';
            RETURN;

         END IF;
         
         p_return_code    := 0;
         p_status_message := NULL;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 40
      -- Return quickly if results are reasonable, bulk up this list if possible
      --------------------------------------------------------------------------
      IF num_srid_output IN (8265,8307)
      THEN
         p_output := num_srid_output;
         RETURN;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Verify that the SRID is in Oracle
      --------------------------------------------------------------------------
      SELECT
      COUNT(*)
      INTO num_check
      FROM
      mdsys.sdo_coord_ref_sys a
      WHERE
      a.srid = num_srid_output;
      
      IF num_check IS NULL
      OR num_check != 1
      THEN
         p_output         := NULL;
         p_return_code    := -94;
         p_status_message := 'host Oracle instance has no spatial reference for ' || num_srid_output || ' as derived from ' || p_input || '.';
         RETURN;
         
      ELSE
         p_output := num_srid_output;
         RETURN;
         
      END IF;
      
   END determine_srid;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE parse_ogc_urn(
       p_input          IN  VARCHAR2
      ,p_urn            OUT VARCHAR2
      ,p_ogc            OUT VARCHAR2
      ,p_def            OUT VARCHAR2
      ,p_objectType     OUT VARCHAR2
      ,p_authority      OUT VARCHAR2
      ,p_version        OUT VARCHAR2
      ,p_code           OUT VARCHAR2
   )
   AS
      ary_string MDSYS.SDO_STRING2_ARRAY;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         RETURN;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Split by colons
      --------------------------------------------------------------------------
      ary_string := dz_crs_util.gz_split(p_input,':');
      IF ary_string.COUNT != 7
      THEN
         RETURN;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Assign results
      --------------------------------------------------------------------------
      p_urn        := ary_string(1);
      p_ogc        := ary_string(2);
      p_def        := ary_string(3);
      p_objectType := ary_string(4);
      p_authority  := ary_string(5);
      p_version    := ary_string(6);
      p_code       := ary_string(7);
      RETURN;
   
   END parse_ogc_urn;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION epsg2srid(
      p_input   IN  NUMBER
   ) RETURN NUMBER
   AS
   BEGIN

      IF p_input = 4269
      THEN
         RETURN 8265;
       
      ELSIF p_input = 4326
      THEN
         RETURN 8307;
         
      ELSE
         RETURN p_input;
         
      END IF;

   END epsg2srid;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION srs2srid(
      p_input     IN  VARCHAR2
   ) RETURN NUMBER
   AS
      num_srid         NUMBER;
      str_axes_latlong VARCHAR2(4000 Char);
      
   BEGIN
      
      --------------------------------------------------------------------------
      --- Note we are not taking into account reverse axis issues!
      --------------------------------------------------------------------------
      
      --------------------------------------------------------------------------
      -- Step 10
      -- Run the procedure
      --------------------------------------------------------------------------
      srs2srid(
          p_input        => p_input
         ,p_srid         => num_srid
         ,p_axes_latlong => str_axes_latlong
      );
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Return what we got
      --------------------------------------------------------------------------
      RETURN num_srid;
   
   END srs2srid;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE srs2srid(
       p_input        IN  VARCHAR2
      ,p_srid         OUT NUMBER
      ,p_axes_latlong OUT VARCHAR2
   )
   AS
      str_input      VARCHAR2(4000 Char) := UPPER(p_input);
      str_urn        VARCHAR2(4000 Char);
      str_ogc        VARCHAR2(4000 Char);
      str_def        VARCHAR2(4000 Char);
      str_objectType VARCHAR2(4000 Char);
      str_authority  VARCHAR2(4000 Char);
      str_version    VARCHAR2(4000 Char);
      str_code       VARCHAR2(4000 Char);
      
   BEGIN
      
      --------------------------------------------------------------------------
      --- Note we are not taking into account reverse axis issues!
      --------------------------------------------------------------------------
      
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF str_input IS NULL
      THEN
         RETURN;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Check for SDO: and EPSG: patterns - valid but not wanted
      -- Note that leaving p_axes_latlong NULL means we just don't know
      --------------------------------------------------------------------------
      IF SUBSTR(str_input,1,4) = 'SDO:'
      THEN
         p_srid :=  dz_crs_util.safe_to_number(
             SUBSTR(str_input,5)
         );
         RETURN;
         
      ELSIF SUBSTR(str_input,1,5) = 'EPSG:'
      THEN
         p_srid := dz_crs_util.safe_to_number(
             epsg2srid(SUBSTR(str_input,6))
         );
         RETURN;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Assume is OGC urn at this point
      --------------------------------------------------------------------------
      parse_ogc_urn(
          p_input      => str_input
         ,p_urn        => str_urn
         ,p_ogc        => str_ogc
         ,p_def        => str_def
         ,p_objectType => str_objectType
         ,p_authority  => str_authority
         ,p_version    => str_version
         ,p_code       => str_code
      );
      
      IF str_urn IS NULL
      THEN
         RETURN;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Okay try to make some sense of things
      --------------------------------------------------------------------------
      IF str_urn = 'URN'
      AND str_ogc = 'OGC'
      AND str_def = 'DEF'
      AND str_objectType = 'CRS'
      THEN
         IF str_authority = 'OGC'
         AND str_code = 'CRS84'
         THEN
            p_srid := 8307;
            p_axes_latlong := 'FALSE';
            
         ELSIF str_authority = 'OGC'
         AND str_code = 'CRS83'
         THEN
            p_srid := 8265;
            p_axes_latlong := 'FALSE';
            
         ELSIF str_authority = 'EPSG'
         THEN
            p_srid := dz_crs_util.safe_to_number(
               epsg2srid(str_code)
            );
            p_axes_latlong := 'TRUE';
            
         END IF;

      ELSE
         RETURN;
         
      END IF;
   
   END srs2srid;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION srid2srs(
      p_input     IN  NUMBER
   ) RETURN VARCHAR2
   AS
   
   BEGIN
   
      IF p_input IS NULL
      THEN
         RETURN 'SDO:';
         
      ELSIF p_input = 8265
      THEN
         RETURN 'urn:ogc:def:crs:OGC::CRS83';
          
      ELSIF p_input = 8307
      THEN
         RETURN 'urn:ogc:def:crs:OGC::CRS84';
         
      ELSE
         RETURN 'SDO:' || TO_CHAR(p_input);
         
      END IF;
   
   END srid2srs;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION smart_transform(
       p_input     IN  MDSYS.SDO_GEOMETRY
      ,p_srid      IN  NUMBER
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
      sdo_output     MDSYS.SDO_GEOMETRY;
      
      -- preferred SRIDs
      num_wgs84_pref NUMBER := 4326;
      num_nad83_pref NUMBER := 8265;
      
   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Check incoming parameters
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         RETURN p_input;
         
      END IF;

      IF p_srid IS NULL
      THEN
         RAISE_APPLICATION_ERROR(-20001,'function requires srid in parameter 2');
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- Check if SRID values match
      --------------------------------------------------------------------------
      IF p_srid = p_input.SDO_SRID
      THEN
         RETURN p_input;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 30
      -- Check for equivalents and adjust geometry SRID if required
      --------------------------------------------------------------------------
      IF  p_srid IN (4269,8265)
      AND p_input.SDO_SRID IN (4269,8265)
      THEN
         sdo_output := p_input;
         sdo_output.SDO_SRID := num_nad83_pref;
         RETURN sdo_output;
         
      ELSIF p_srid IN (4326,8307)
      AND   p_input.SDO_SRID IN (4326,8307)
      THEN
         sdo_output := p_input;
         sdo_output.SDO_SRID := num_wgs84_pref;
         RETURN sdo_output;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 40
      -- Run the transformation then
      --------------------------------------------------------------------------
      IF p_srid = 3785
      THEN
         sdo_output := MDSYS.SDO_CS.TRANSFORM(
            geom     => p_input,
            use_case => 'USE_SPHERICAL',
            to_srid  => p_srid
         );
         
      ELSE
         sdo_output := MDSYS.SDO_CS.TRANSFORM(
            geom     => p_input,
            to_srid  => p_srid
         );
      
      END IF;
      
      RETURN sdo_output;

   END smart_transform;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE grid_clob_to_header(
       p_clob       IN  CLOB
      ,p_col_count  OUT NUMBER
      ,p_row_count  OUT NUMBER
      ,p_z_count    OUT NUMBER
      ,p_min_long   OUT NUMBER
      ,p_long_cell  OUT NUMBER
      ,p_min_lat    OUT NUMBER
      ,p_lat_cell   OUT NUMBER
   )
   AS
      str_header  VARCHAR2(4000 Char);
      int_row_cnt PLS_INTEGER;
      ary_results MDSYS.SDO_NUMBER_ARRAY;
      
   BEGIN
      
      --------------------------------------------------------------------------
      -- Step 10
      -- Read the CLOB to get the second header line
      --------------------------------------------------------------------------
      str_header := '';
      int_row_cnt := 0;
      FOR i IN 1 .. LENGTH(p_clob)
      LOOP
         IF SUBSTR(p_clob,i,1) IN (CHR(13),CHR(10))
         THEN
            int_row_cnt := int_row_cnt + 1;
            
         ELSE
            IF int_row_cnt = 2
            THEN
               str_header := str_header || SUBSTR(p_clob,i,1);
               
            ELSIF int_row_cnt > 2
            THEN
               EXIT;
               
            END IF;
            
         END IF;
         
      END LOOP;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Split the results by space delimited
      --------------------------------------------------------------------------
      str_header := dz_crs_util.condense_whitespace(str_header);
      ary_results := dz_crs_util.strings2numbers(
         dz_crs_util.gz_split(str_header,' ')
      );
      IF ary_results.COUNT != 8
      THEN
         RAISE_APPLICATION_ERROR(-20001,'NADCON grid header must have eight elements.'
         || ' Found ' || ary_results.COUNT || ' instead.');
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Assign the output values
      --------------------------------------------------------------------------
      p_col_count := ary_results(1);
      p_row_count := ary_results(2);
      p_z_count   := ary_results(3);
      p_min_long  := ary_results(4);
      p_long_cell := ary_results(5);
      p_min_lat   := ary_results(6);
      p_lat_cell  := ary_results(7);
      
   END grid_clob_to_header;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION grid_to_mbr(
      p_coord_op_param IN  NUMBER
   ) RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC
   AS
      clb_grid_long  CLOB;
      clb_grid_lat   CLOB;
      num_col_count  NUMBER;
      num_row_count  NUMBER;
      num_z_count    NUMBER;
      num_min_long   NUMBER;
      num_long_cell  NUMBER;
      num_min_lat    NUMBER;
      num_lat_cell   NUMBER;
      num_x_min_long NUMBER;
      num_x_max_long NUMBER;
      num_y_min_lat  NUMBER;
      num_y_max_lat  NUMBER;
      
   BEGIN
      
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Check if the option exists and if both grids have content
      --------------------------------------------------------------------------
      BEGIN        
         SELECT
         a.param_value_file
         INTO clb_grid_long
         FROM 
         mdsys.sdo_coord_op_param_vals a 
         WHERE 
         a.coord_op_id = p_coord_op_param AND 
         a.param_value_file_ref like '%.los';
         
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            RAISE_APPLICATION_ERROR(-20001,'cannot find longitude NADCON grid for coord op id = ' || TO_CHAR(p_coord_op_param));
         WHEN OTHERS
         THEN
            RAISE;
            
      END;
      
      BEGIN        
         SELECT 
         a.param_value_file
         INTO clb_grid_lat
         FROM 
         mdsys.sdo_coord_op_param_vals a 
         WHERE
         a.coord_op_id = p_coord_op_param AND 
         a.param_value_file_ref like '%.las';
              
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            RAISE_APPLICATION_ERROR(-20001,'cannot find latitude NADCON grid for coord op id = ' || TO_CHAR(p_coord_op_param));
         WHEN OTHERS
         THEN
            RAISE;
      END;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Extract the header information from the long grid
      --------------------------------------------------------------------------
      grid_clob_to_header(
          p_clob       => clb_grid_long
         ,p_col_count  => num_col_count
         ,p_row_count  => num_row_count
         ,p_z_count    => num_z_count
         ,p_min_long   => num_min_long
         ,p_long_cell  => num_long_cell
         ,p_min_lat    => num_min_lat
         ,p_lat_cell   => num_lat_cell
      );
      
      num_x_min_long := num_min_long;
      num_y_min_lat  := num_min_lat;
      num_x_max_long := num_min_long + (num_col_count * num_long_cell);
      num_y_max_lat  := num_min_lat + (num_row_count * num_lat_cell);
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Check for crossing the 180th meridian
      --------------------------------------------------------------------------
      IF num_x_min_long < -180 
      THEN
         num_x_min_long := 180 + (num_x_min_long + 180);
         
      END IF;
      
      IF num_x_max_long < -180 
      THEN
         num_x_max_long := 180 + (num_x_max_long + 180);
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Return what we got
      --------------------------------------------------------------------------
      RETURN MDSYS.SDO_GEOMETRY(
         2003,
         4267,
         NULL,
         MDSYS.SDO_ELEM_INFO_ARRAY(
            1,
            1003,
            3
         ),
         MDSYS.SDO_ORDINATE_ARRAY(
            num_x_min_long, num_y_min_lat,
            num_x_max_long, num_y_max_lat
         )
      );

   END grid_to_mbr;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE unwrap_etype3(
       p_input              IN  MDSYS.SDO_GEOMETRY
      ,p_min_point          OUT MDSYS.SDO_GEOMETRY
      ,p_max_point          OUT MDSYS.SDO_GEOMETRY
      ,p_2d_flag            IN  VARCHAR2 DEFAULT 'FALSE'
   )
   AS
      str_2d_flag      VARCHAR2(5 Char) := UPPER(p_2d_flag);
      int_gtype        PLS_INTEGER;
      int_dims         PLS_INTEGER;
      int_output_gtype PLS_INTEGER;
      num_min_x        NUMBER;
      num_min_y        NUMBER;
      num_min_z        NUMBER;
      num_max_x        NUMBER;
      num_max_y        NUMBER;
      num_max_z        NUMBER;

   BEGIN

      IF str_2d_flag IS NULL
      THEN
         str_2d_flag := 'FALSE';
         
      ELSIF str_2d_flag NOT IN ('TRUE','FALSE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'boolean error!');
         
      END IF;

      int_gtype := p_input.get_gtype();
      int_dims  := p_input.get_dims();

      IF int_gtype != 3
      THEN
         RAISE_APPLICATION_ERROR(-20001,'procedure requires a polygon as input');
         
      END IF;

      IF p_input.SDO_ELEM_INFO.COUNT != 3
      OR p_input.SDO_ELEM_INFO(3) != 3
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'procedure requires a polygon with etype 3 as input'
         );
         
      END IF;

      IF int_dims = 2
      THEN
         num_min_x := p_input.SDO_ORDINATES(1);
         num_min_y := p_input.SDO_ORDINATES(2);
         num_min_z := NULL;
         num_max_x := p_input.SDO_ORDINATES(3);
         num_max_y := p_input.SDO_ORDINATES(4);
         num_max_z := NULL;
         
      ELSIF int_dims = 3
      THEN
         num_min_x := p_input.SDO_ORDINATES(1);
         num_min_y := p_input.SDO_ORDINATES(2);
         num_min_z := p_input.SDO_ORDINATES(3);
         num_max_x := p_input.SDO_ORDINATES(4);
         num_max_y := p_input.SDO_ORDINATES(5);
         num_max_z := p_input.SDO_ORDINATES(6);
         
      ELSIF int_dims = 4
      THEN
         num_min_x := p_input.SDO_ORDINATES(1);
         num_min_y := p_input.SDO_ORDINATES(2);
         num_min_z := p_input.SDO_ORDINATES(3);
         num_max_x := p_input.SDO_ORDINATES(5);
         num_max_y := p_input.SDO_ORDINATES(6);
         num_max_z := p_input.SDO_ORDINATES(7);
         
      END IF;

      IF str_2d_flag = 'TRUE'
      THEN
         num_min_z := NULL;
         num_max_z := NULL;
         
      END IF;

      int_output_gtype := TO_NUMBER(TO_CHAR(int_dims) || '001');

      p_min_point := MDSYS.SDO_GEOMETRY(
         int_output_gtype,
         p_input.SDO_SRID,
         MDSYS.SDO_POINT_TYPE(
            num_min_x,
            num_min_y,
            num_min_z
         ),
         NULL,
         NULL
      );

      p_max_point := MDSYS.SDO_GEOMETRY(
         int_output_gtype,
         p_input.SDO_SRID,
         MDSYS.SDO_POINT_TYPE(
            num_max_x,
            num_max_y,
            num_max_z
         ),
         NULL,
         NULL
      );

   END unwrap_etype3;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE wrap_etype3(
       p_output             OUT MDSYS.SDO_GEOMETRY
      ,p_min_point          IN  MDSYS.SDO_GEOMETRY
      ,p_max_point          IN  MDSYS.SDO_GEOMETRY
      ,p_2d_flag            IN  VARCHAR2 DEFAULT 'FALSE'
   )
   AS
      str_2d_flag      VARCHAR2(5 Char) := UPPER(p_2d_flag);
      int_gtype_min    PLS_INTEGER;
      int_dims_min     PLS_INTEGER;
      int_gtype_max    PLS_INTEGER;
      int_dims_max     PLS_INTEGER;
      num_min_x        NUMBER;
      num_min_y        NUMBER;
      num_min_z        NUMBER;
      num_max_x        NUMBER;
      num_max_y        NUMBER;
      num_max_z        NUMBER;
      num_dummy1       NUMBER;
      num_dummy2       NUMBER;

   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Check incoming parameters
      --------------------------------------------------------------------------
      IF str_2d_flag IS NULL
      THEN
         str_2d_flag := 'FALSE';
         
      ELSIF str_2d_flag NOT IN ('TRUE','FALSE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 10
      -- Check incoming points
      --------------------------------------------------------------------------
      int_gtype_min := p_min_point.get_gtype();
      int_dims_min  := p_min_point.get_dims();
      int_gtype_max := p_max_point.get_gtype();
      int_dims_max  := p_max_point.get_dims();

      IF int_gtype_min <> 1
      OR int_gtype_max <> 1
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'procedure requires points as input'
         );
         
      END IF;

      IF int_dims_min != int_dims_max
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'incoming points must have same number of dimensions'
         );
         
      END IF;

      IF p_min_point.SDO_SRID != p_max_point.SDO_SRID
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'incoming points must have same coordinate systems'
         );
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 30
      -- Extract values
      --------------------------------------------------------------------------
      dz_crs_util.point2coordinates(
         p_min_point,
         num_min_x,
         num_min_y,
         num_min_z,
         num_dummy1
      );
      
      dz_crs_util.point2coordinates(
         p_max_point,
         num_max_x,
         num_max_y,
         num_max_z,
         num_dummy2
      );

      --------------------------------------------------------------------------
      -- Step 40
      -- Build New Polygon
      --------------------------------------------------------------------------
      IF int_dims_min = 2
      OR str_2d_flag = 'TRUE'
      THEN
         p_output := MDSYS.SDO_GEOMETRY(
             2003
            ,p_min_point.SDO_SRID
            ,NULL
            ,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,3)
            ,MDSYS.SDO_ORDINATE_ARRAY(num_min_x,num_min_y,num_max_x,num_max_y)
         );
         
      ELSIF int_dims_min IN (3,4)
      THEN
         p_output := MDSYS.SDO_GEOMETRY(
             3003
            ,p_min_point.SDO_SRID
            ,NULL
            ,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,3)
            ,MDSYS.SDO_ORDINATE_ARRAY(num_min_x,num_min_y,num_min_z,num_max_x,num_max_y,num_max_z)
         );
         
      END IF;

   END wrap_etype3;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION transform_etype3(
       p_input              IN  MDSYS.SDO_GEOMETRY
      ,p_output_srid        IN  NUMBER
      ,p_2d_flag            IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
      sdo_min    MDSYS.SDO_GEOMETRY;
      sdo_max    MDSYS.SDO_GEOMETRY;
      sdo_output MDSYS.SDO_GEOMETRY;
      
   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Check incoming parameters
      --------------------------------------------------------------------------
      IF p_output_srid IS NULL
      THEN
         RAISE_APPLICATION_ERROR(-20001,'output srid cannot be NULL');
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- Exit if nothing needs to be done
      --------------------------------------------------------------------------
      IF p_output_srid = p_input.SDO_SRID
      THEN
         RETURN p_input;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 30
      -- Get the points
      --------------------------------------------------------------------------
      unwrap_etype3(
          p_input     => p_input
         ,p_min_point => sdo_min
         ,p_max_point => sdo_max
         ,p_2d_flag   => p_2d_flag
      );

      --------------------------------------------------------------------------
      -- Step 40
      -- Transform the points
      --------------------------------------------------------------------------
      sdo_min := MDSYS.SDO_CS.TRANSFORM(sdo_min,p_output_srid);
      sdo_max := MDSYS.SDO_CS.TRANSFORM(sdo_max,p_output_srid);

      --------------------------------------------------------------------------
      -- Step 50
      -- Return the etype 3 rectangle
      --------------------------------------------------------------------------
      wrap_etype3(
          p_output    => sdo_output
         ,p_min_point => sdo_min
         ,p_max_point => sdo_max
      );

      RETURN sdo_output;

   END transform_etype3;

END dz_crs_main;
/

--******************************--
PROMPT Packages/DZ_CRS_TEST.pks 

CREATE OR REPLACE PACKAGE dz_crs_test
AUTHID DEFINER
AS

   C_GITRELEASE    CONSTANT VARCHAR2(255 Char) := '';
   C_GITCOMMIT     CONSTANT VARCHAR2(255 Char) := '66aa7722eeba8cb53552f6a05e5b12f876147670';
   C_GITCOMMITDATE CONSTANT VARCHAR2(255 Char) := 'Mon Oct 10 16:39:58 2016 -0400';
   C_GITCOMMITAUTH CONSTANT VARCHAR2(255 Char) := 'Paul Dziemiela';
   
   C_PREREQUISITES CONSTANT MDSYS.SDO_STRING2_ARRAY := MDSYS.SDO_STRING2_ARRAY(
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prerequisites
   RETURN NUMBER;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION version
   RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION inmemory_test
   RETURN NUMBER;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION scratch_test
   RETURN NUMBER;
      
END dz_crs_test;
/

GRANT EXECUTE ON dz_crs_test TO public;

--******************************--
PROMPT Packages/DZ_CRS_TEST.pkb 

CREATE OR REPLACE PACKAGE BODY dz_crs_test
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prerequisites
   RETURN NUMBER
   AS
      num_check NUMBER;
      
   BEGIN
      
      FOR i IN 1 .. C_PREREQUISITES.COUNT
      LOOP
         SELECT 
         COUNT(*)
         INTO num_check
         FROM 
         user_objects a
         WHERE 
             a.object_name = C_PREREQUISITES(i) || '_TEST'
         AND a.object_type = 'PACKAGE';
         
         IF num_check <> 1
         THEN
            RETURN 1;
         
         END IF;
      
      END LOOP;
      
      RETURN 0;
   
   END prerequisites;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION version
   RETURN VARCHAR2
   AS
   BEGIN
      RETURN '{'
      || ' "GITRELEASE":"'    || C_GITRELEASE    || '"'
      || ',"GITCOMMIT":"'     || C_GITCOMMIT     || '"'
      || ',"GITCOMMITDATE":"' || C_GITCOMMITDATE || '"'
      || ',"GITCOMMITAUTH":"' || C_GITCOMMITAUTH || '"'
      || '}';
      
   END version;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION inmemory_test
   RETURN NUMBER
   AS
   BEGIN
      RETURN 0;
      
   END inmemory_test;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION scratch_test
   RETURN NUMBER
   AS
   BEGIN
      RETURN 0;
      
   END scratch_test;

END dz_crs_test;
/

SHOW ERROR;

DECLARE
   l_num_errors PLS_INTEGER;

BEGIN

   SELECT
   COUNT(*)
   INTO l_num_errors
   FROM
   user_errors a
   WHERE
   a.name LIKE 'DZ_CRS%';

   IF l_num_errors <> 0
   THEN
      RAISE_APPLICATION_ERROR(-20001,'COMPILE ERROR');

   END IF;

   l_num_errors := DZ_CRS_TEST.inmemory_test();

   IF l_num_errors <> 0
   THEN
      RAISE_APPLICATION_ERROR(-20001,'INMEMORY TEST ERROR');

   END IF;

END;
/

EXIT;
SET DEFINE OFF;

