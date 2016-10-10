CREATE OR REPLACE PACKAGE dz_crs_main
AUTHID CURRENT_USER
AS
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   header: DZ_CRS
     
   - Build ID: DZBUILDIDDZ
   - TFS Change Set: DZCHANGESETDZ
   
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

