*&---------------------------------------------------------------------*
*&  Include           ZPM_UPLOAD_ORDERMAINTAIN_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  AUTHORITY_CHECKS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM authority_checks .
  AUTHORITY-CHECK OBJECT 'S_TCODE'
             ID 'TCD' FIELD sy-tcode.
  IF sy-subrc <> 0.
    MESSAGE e172(00) WITH sy-tcode.
    RETURN.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  BUILD_LOG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GT_MESSTAB  text
*----------------------------------------------------------------------*
FORM build_log   TABLES   messtab  STRUCTURE  bdcmsgcoll.
*Variables del log
  DATA: gt_balmi1  LIKE balmi OCCURS 0 WITH HEADER LINE,
        gt_balmi2  LIKE balmi OCCURS 0 WITH HEADER LINE,
        gt_balnri  LIKE balnri OCCURS 0 WITH HEADER LINE,
        gs_balhdri LIKE balhdri.
  DATA: lv_subobj TYPE balhdr-subobject,
        lv_txt    TYPE string.

  lv_subobj = 'ZPM_ORDMD'.
  lv_txt    = 'Crea Orden de Trabajo'.


* Inicializa Log
  CALL FUNCTION 'APPL_LOG_INIT'
    EXPORTING
      object              = 'ZPM_ORDM'
      subobject           = lv_subobj
    EXCEPTIONS
      object_not_found    = 1
      subobject_not_found = 2
      OTHERS              = 3.
  IF sy-subrc = 0.
    CALL FUNCTION 'APPL_LOG_INIT_MESSAGES'
      EXPORTING
        object              = 'ZPM_ORDM'
        subobject           = lv_subobj
      EXCEPTIONS
        object_not_found    = 1
        subobject_not_found = 2
        OTHERS              = 3.
    IF sy-subrc = 0.

    ENDIF.
  ENDIF.
*

* Incorporación del Log
  LOOP AT messtab.
    CLEAR gt_balmi1.
    gt_balmi1-msgty = messtab-msgtyp.
    gt_balmi1-msgid = 00."messtab-msgid. "'ZBW_ACT'. "TX SE91
    gt_balmi1-msgno = 00."messtab-msgnr.
    gt_balmi1-msgv1 = |Actualizado { messtab-msgv1(49) }|.
    gt_balmi1-msgv2 = messtab-msgv2(49).
    APPEND gt_balmi1.
  ENDLOOP.
*
  DATA ld_titulo.

  IF NOT gt_balmi1[] IS INITIAL.
*   Se graba cabecera de log
    gs_balhdri-object    = 'ZPM_ORDM'.
    gs_balhdri-subobject = lv_subobj.
*
    gs_balhdri-aldate = sy-datlo.
    gs_balhdri-altime = sy-timlo.
    gs_balhdri-aluser = sy-uname.
    gs_balhdri-altcode = sy-tcode.
    CONCATENATE 'Tx ' messtab-tcode ' tiene mensajes'  INTO ld_titulo SEPARATED BY space.
    gs_balhdri-altext  = ld_titulo.

*   Se genera solo una cabecera
    CALL FUNCTION 'APPL_LOG_WRITE_HEADER'
      EXPORTING
        header              = gs_balhdri
      EXCEPTIONS
        object_not_found    = 1
        subobject_not_found = 2
        error               = 3
        OTHERS              = 4.
    IF sy-subrc = 0.
*     Detalle
      CALL FUNCTION 'APPL_LOG_WRITE_MESSAGES'
        EXPORTING
          object              = 'ZPM_ORDM'
          subobject           = lv_subobj
          update_or_insert    = 'I'
        TABLES
          messages            = gt_balmi1
        EXCEPTIONS
          object_not_found    = 1
          subobject_not_found = 2
          OTHERS              = 3.
      IF sy-subrc = 0.
        CALL FUNCTION 'APPL_LOG_WRITE_DB'
          TABLES
            object_with_lognumber = gt_balnri
          EXCEPTIONS
            object_not_found      = 1
            subobject_not_found   = 2
            internal_error        = 3
            OTHERS                = 4.
        IF sy-subrc <> 0.
        ENDIF.
      ENDIF.
    ENDIF.

  ELSE.

*   Se graba cabecera de log
    gs_balhdri-object    = 'ZPM_ORDM'.
    gs_balhdri-subobject = lv_subobj.
*
    gs_balhdri-aldate = sy-datlo.
    gs_balhdri-altime = sy-timlo.
    gs_balhdri-aluser = sy-uname.
    gs_balhdri-altcode = sy-tcode.
    CONCATENATE 'Tx ' sy-tcode ' No obtuvo datos'  INTO ld_titulo SEPARATED BY space.
    gs_balhdri-altext  = ld_titulo.

*   Se genera solo una cabecera
    CALL FUNCTION 'APPL_LOG_WRITE_HEADER'
      EXPORTING
        header              = gs_balhdri
      EXCEPTIONS
        object_not_found    = 1
        subobject_not_found = 2
        error               = 3
        OTHERS              = 4.
    IF sy-subrc = 0.
      CLEAR gt_balmi1.
      gt_balmi1-msgty = 'E'.
      gt_balmi1-msgid = 00. "'ZPM_ORDM'. "TX SE91
      gt_balmi1-msgno = 00.
      CONCATENATE lv_txt 'no fue efectivo' INTO lv_txt SEPARATED BY space.
      gt_balmi1-msgv1 = lv_txt.
      gt_balmi1-msgv2 = ', verifique parametros'.
      APPEND gt_balmi1.
*     Detalle
      CALL FUNCTION 'APPL_LOG_WRITE_MESSAGES'
        EXPORTING
          object              = 'ZPM_ORDM'
          subobject           = lv_subobj
          update_or_insert    = 'I'
        TABLES
          messages            = gt_balmi1
        EXCEPTIONS
          object_not_found    = 1
          subobject_not_found = 2
          OTHERS              = 3.
      IF sy-subrc = 0.
        CALL FUNCTION 'APPL_LOG_WRITE_DB'
          TABLES
            object_with_lognumber = gt_balnri
          EXCEPTIONS
            object_not_found      = 1
            subobject_not_found   = 2
            internal_error        = 3
            OTHERS                = 4.
        IF sy-subrc <> 0.
        ENDIF.
      ENDIF.
    ENDIF.

  ENDIF.

ENDFORM.