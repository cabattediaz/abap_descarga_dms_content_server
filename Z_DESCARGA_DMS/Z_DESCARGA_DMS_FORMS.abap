*----------------------------------------------------------------------*
***INCLUDE Z_DESCARGA_DMS_FORMS.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  GET_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->p_lt_drad         text
*      -->p_lt_dms_doc2loio text
*      -->p_lt_dms_ph_cd1   text
*----------------------------------------------------------------------*
FORM get_data  TABLES   p_lt_draw
                        p_lt_dms_doc2loio .

*        READ TABLE lt_dms_doc2loio INTO ls_dms_doc2loio WITH KEY doknr = ls_drad-doknr.


  SELECT * INTO TABLE lt_draw
      FROM draw
*    INNER JOIN dms_doc2loio as b
**    on a~dokar = lt_drad-dokar
       WHERE dokar IN ('ZM1', 'ZM2', 'ZM3').

  SELECT *
  INTO TABLE   p_lt_dms_doc2loio
    FROM dms_doc2loio
    FOR ALL ENTRIES IN lt_draw

    WHERE dokar = lt_draw-dokar
    AND doknr = lt_draw-doknr.






ENDFORM.                    " GET_DATA

*&---------------------------------------------------------------------*
*&      Form  INICIA_LOG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM inicia_log CHANGING ch_log_handle TYPE balloghndl.
*--- 1. Crear log (solo una vez)
  DATA: ls_log      TYPE bal_s_log.
  DATA lv_log_handle TYPE  balloghndl.
  ls_log-object    = 'ZLOGEXPORT' .
  ls_log-subobject = 'DMS'.
*  ls_log-extnumber = 'PROCESO_XYZ'. "Opcional

  CALL FUNCTION 'BAL_LOG_CREATE'
    EXPORTING
      i_s_log      = ls_log
    IMPORTING
      e_log_handle = ch_log_handle.

ENDFORM.                    " INICIA_LOG

*&---------------------------------------------------------------------*
*&      Form  REGISTRAR_LOG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM registrar_log USING pi_ls_access_info  TYPE scms_acinf
                        pi_ls_draw          TYPE draw
                        pi_ls_dms_ph_cd1    TYPE dms_ph_cd1
                        pi_mensaje.

*  DATA: lo_log      TYPE REF TO cl_bal_log,

  DATA: ls_log      TYPE bal_s_log,
  lv_log_handle TYPE balloghndl.
  DATA lv_mensaje_concatenado TYPE bapi_msg.
  CONCATENATE 'Se ha producido un error al obtener registro de SCMS_DOC_READ, :'
               ', categoria DOKAR=' pi_ls_draw-dokar
               ', documento DOKNR=' pi_ls_draw-doknr

                INTO lv_mensaje_concatenado.


  DATA lo_msg TYPE bal_s_msg.

  lo_msg-msgty  = 'E'.              "I: info, W: warning, E: error
  lo_msg-msgid  = 'ZMSG'.           "Mensaje propio o estándar
  lo_msg-msgno  = '001'.
  lo_msg-msgv1  = lv_mensaje_concatenado.



  CALL FUNCTION 'BAL_LOG_MSG_ADD'
    EXPORTING
      i_log_handle = lv_log_handle
      i_s_msg      = lo_msg.


ENDFORM.                    " REGISTRAR_LOG

*&---------------------------------------------------------------------*
*&      Form  guardar_log
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->PI_LOG_HANDLE  text
*----------------------------------------------------------------------*
FORM guardar_log USING pi_log_handle.

  DATA: lt_log_handle TYPE bal_t_logh .


  APPEND pi_log_handle TO lt_log_handle.


*--- 3. Guardar el log (solo una vez)
  CALL FUNCTION 'BAL_DB_SAVE'
    EXPORTING
      i_t_log_handle = lt_log_handle.

  COMMIT WORK.

ENDFORM.                    "guardar_log