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

