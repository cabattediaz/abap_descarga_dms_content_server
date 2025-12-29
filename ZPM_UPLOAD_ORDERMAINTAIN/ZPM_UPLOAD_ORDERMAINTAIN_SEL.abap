*&---------------------------------------------------------------------*
*&  Include           ZPM_UPLOAD_ORDERMAINTAIN_SEL
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE text-t01.
*
PARAMETERS: p_dir type string modif id gen lower case,
            p_test  as checkbox user-command gen.
SELECTION-SCREEN END OF BLOCK blk1.
*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_dir.
  IF p_dir IS INITIAL.
    p_dir = |C:/FTP/CARGA_ORDENESPM/|.
  ENDIF.

AT SELECTION-SCREEN OUTPUT.
   IF p_dir IS INITIAL.
    p_dir = |C:/FTP/CARGA_ORDENESPM/|.
  ENDIF.
*
    loop at screen.
      if screen-group1 = 'GEN'.
        screen-input = '0'.
*        screen-active    = '0'.
        modify screen.
      endif.
    endloop.