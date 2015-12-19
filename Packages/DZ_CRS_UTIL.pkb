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

