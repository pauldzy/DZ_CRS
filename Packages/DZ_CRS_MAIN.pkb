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
      num_error   NUMBER;
      str_message VARCHAR2(4000 Char);
      
   BEGIN
   
      determine_srid(
          p_input          => p_input
         ,p_output         => num_output
         ,p_error_code     => num_error
         ,p_status_message => str_message
      );
      
      IF num_error = 0
      THEN
         RETURN num_output;
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'error ' || TO_CHAR(num_error) || ': ' || str_message
         );
         
      END IF;
      
   END determine_srid;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE determine_srid(
       p_input          IN  VARCHAR2
      ,p_output         OUT NUMBER
      ,p_error_code     OUT NUMBER
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
         p_error_code := 0;
         p_status_message := 'WARNING: Empty Input'; 
         RETURN;
         
      ELSIF p_input ='WKT'
      THEN
         p_output := num_default_srid;
         p_error_code := 0;
         p_status_message := NULL; 
         RETURN;
      
      ELSIF p_input ='WKT,SRID=8265'
      THEN
         p_output := 8265;
         p_error_code := 0;
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
            p_error_code    := -90;
            p_status_message := 'unable to parse SRID from ' || p_input || '.';
            RETURN;
            
         END IF;
         
         p_error_code    := 0;
         p_status_message := NULL;
         
      ELSIF UPPER(str_left_side) = 'SRSNAME'
      AND str_right_side IS NOT NULL
      THEN
         num_srid_output := srs2srid(str_right_side);
         IF num_srid_output IS NULL
         THEN
            p_output         := NULL;
            p_error_code    := -91;
            p_status_message := 'ERROR, unable to parse spatial reference from ' || p_input || '.';
            RETURN;
            
         END IF;
         
         p_error_code    := 0;
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
            p_error_code    := -92;
            p_status_message := 'unable to parse numeric EPSG code from ' || p_input || '.';
            RETURN;

         END IF;
         
         num_srid_output  := epsg2srid(num_srid_output);
         p_error_code    := 0;
         p_status_message := NULL;
         
      ELSIF UPPER(str_left_side) = 'SDO'
      AND str_right_side IS NOT NULL
      THEN
         num_srid_output := dz_crs_util.safe_to_number(str_right_side);
         IF num_srid_output IS NULL
         THEN
            p_output         := NULL;
            p_error_code    := -93;
            p_status_message := 'unable to parse numeric SDO code from ' || p_input || '.';
            RETURN;

         END IF;
         
         p_error_code    := 0;
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
         p_error_code    := -94;
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

