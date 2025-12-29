*&---------------------------------------------------------------------*
*&  Include           ZPM_UPLOAD_ORDERMAINTAIN_LCL
*&---------------------------------------------------------------------*
*----------------------------------------------------------------------*
*       CLASS lcl_report DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_report DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      main.
    METHODS:
      constructor,
      process_files,
      read_directory,
      upload_to_dms IMPORTING iv_filename  TYPE string
                              iv_order_num TYPE aufnr
                    RETURNING value(rv_success) TYPE abap_bool,
      validate_order IMPORTING iv_order_num      TYPE aufnr
                    RETURNING value(rv_exists)   TYPE abap_bool,
      delete_file   IMPORTING iv_filename        TYPE string,
      create_log.
  PRIVATE SECTION.
    DATA: mt_files TYPE TABLE OF ty_file.
*  ------------------------
*  PUBLIC SECTION.
*    CLASS-METHODS:
*      main.
*    METHODS:
*      get_data,
*      display_alv
*        CHANGING
*          ct_alv TYPE tt_alv,
*      set_catalog
*        RETURNING
*          VALUE(rt_fieldcat) TYPE lvc_t_fcat. "slis_t_fieldcat_alv.
ENDCLASS.                    "lcl_report DEFINITION

*----------------------------------------------------------------------*
*       CLASS lcl_report IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_report IMPLEMENTATION.
  METHOD main.
    DATA: lo_report TYPE REF TO lcl_report.

    " Crear una instancia de la clase
    CREATE OBJECT lo_report.

    " Llamar a los métodos de instancia
    " Proceso principal
    lo_report->read_directory( ).
    lo_report->process_files( ).
    lo_report->create_log( ).


  ENDMETHOD.                    "main

  METHOD constructor.
    " Inicialización
  ENDMETHOD.                    "constructor

  METHOD read_directory.
    DATA: lt_dir_list TYPE TABLE OF eps2fili,
          ls_file     TYPE eps2fili,
          lv_dir      TYPE eps2filnam.

    lv_dir = p_dir.
*   Lista los archivos del directorio
    CALL FUNCTION 'EPS2_GET_DIRECTORY_LISTING'
      EXPORTING
        iv_dir_name            = lv_dir
      TABLES
        dir_list               = lt_dir_list
      EXCEPTIONS
        invalid_eps_subdir     = 1
        sapgparam_failed       = 2
        build_directory_failed = 3
        no_authorization       = 4
        read_directory_failed  = 5
        too_many_read_errors   = 6
        empty_directory_list   = 7
        OTHERS                 = 8.


    IF sy-subrc = 0.
      LOOP AT lt_dir_list INTO ls_file WHERE name NE '.' AND name NE '..'.
        CLEAR gw_file.
        " Validar formato del nombre del archivo (_NNNNNN.xxx) [OBTIENE N°Orden]
        FIND REGEX '_(\d{6,})\..*' IN ls_file-name SUBMATCHES gw_file-order_num. "'_(\d{6,})\..*'
        IF sy-subrc = 0.
          gw_file-filename = ls_file-name.
          gw_file-path = p_dir.
          APPEND gw_file TO gt_files.
        ENDIF.
      ENDLOOP.
    ELSE.
      " Manejar error de lectura de directorio
      MESSAGE e000(00) WITH 'Error al leer directorio:' p_dir.
    ENDIF.
  ENDMETHOD.                    "read_directory

  METHOD process_files.
    DATA: lv_success TYPE abap_bool.

    LOOP AT gt_files INTO gw_file.
      " Validar existencia de la OT
      IF validate_order( gw_file-order_num ) = abap_true.
        " Cargar archivo al DMS
        lv_success = upload_to_dms(
                                    iv_filename  = gw_file-filename
                                    iv_order_num = gw_file-order_num
                                   ).

        IF lv_success = abap_true.
          " Si no es modo test, eliminar archivo
          IF p_test = abap_false.
            delete_file( gw_file-filename ).
            gw_file-error_msg = 'Se crea documento en modo test'.
          ELSE.
            gw_file-error_msg = 'Se crea documento, se elimina Arch. en AL11'.
          ENDIF.
          gw_file-processed = abap_true.
        ELSE.
          gw_file-processed = abap_false.
          gw_file-error_msg = 'Error al cargar archivo al DMS'.
        ENDIF.
      ELSE.
        gw_file-processed = abap_false.
        gw_file-error_msg = 'Orden de trabajo no existe'.
      ENDIF.
      MODIFY gt_files FROM gw_file.
    ENDLOOP.
  ENDMETHOD.                    "process_files

  METHOD upload_to_dms.
    DATA: lt_files      TYPE TABLE OF bapi_doc_files2,
          ls_files      TYPE bapi_doc_files2.
    DATA: lv_doctype    TYPE bapi_doc_aux-doctype,
          lv_docnumber  TYPE bapi_doc_aux-docnumber,
          lv_docpart    TYPE bapi_doc_aux-docpart,
          lv_docversion TYPE bapi_doc_aux-docversion,
          lv_status     TYPE bapi_doc_draw-statusextern,
          ls_return     TYPE bapiret2.

    DATA: ls_document TYPE bapi_doc_draw2,
          lt_documentdescriptions TYPE TABLE OF bapi_doc_drat,
          ls_documentdescriptions TYPE bapi_doc_drat,
          lt_objectlinks          TYPE TABLE OF bapi_doc_drad,
          ls_objectlinks          TYPE bapi_doc_drad,
          lt_documentfiles        TYPE TABLE OF bapi_doc_files2,
          ls_documentfiles        TYPE bapi_doc_files2,
          lv_content  TYPE xstring.
*
*   " Preparar datos para BAPI_DOCUMENT_CREATE2
    ls_document-documenttype     = 'ZM2'.
    ls_document-documentnumber   = ''.
    ls_document-documentversion  = '00'.
    ls_document-documentpart     = '000'.
    ls_document-description      = 'Carga masiva en ordenes de trabajo'.
    ls_document-username         = sy-uname.
    ls_document-statusextern     = 'LI'.
    ls_document-statusintern     = 'FR'.
*
    DATA lv_aufnr TYPE aufnr.
    lv_aufnr = iv_order_num.
*
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = lv_aufnr
      IMPORTING
        output = lv_aufnr.

*   ls_documentdescriptions-deletevalue     = ''.
    ls_documentdescriptions-language        = 'ES'.
    ls_documentdescriptions-language_iso    = 'ES'.
    ls_documentdescriptions-description     = 'Carga masiva en ordenes de trabajo'.
*    ls_documentdescriptions-textindicator   = ''.
    APPEND ls_documentdescriptions TO lt_documentdescriptions.

    ls_objectlinks-deletevalue        = ''.
    ls_objectlinks-objecttype         = 'PMAUFK'.
    ls_objectlinks-objectkey          = lv_aufnr.
    ls_objectlinks-documentdirection  = ''.
    ls_objectlinks-objectdescription  = ''.
    ls_objectlinks-objectlinkid       = ''.
    ls_objectlinks-addobjecttype      = ''.
    ls_objectlinks-addobjectkey       = ''.
    ls_objectlinks-cad_pos            = ''.
    APPEND ls_objectlinks TO lt_objectlinks.

    DATA: lv_extension TYPE string,
          lv_ext       TYPE c LENGTH 3.

    " Extensión del archivo: Capturar todo después del último punto
    FIND REGEX '\.([^\.]+)$' IN gw_file-filename SUBMATCHES lv_extension.
    TRANSLATE lv_extension TO LOWER CASE.
    CONDENSE lv_extension.
*   "Busca Aplicación según extensión del archivo
    SELECT SINGLE dappl INTO lv_ext
      FROM tdwp
      WHERE appsfx EQ lv_extension.
    IF sy-subrc EQ 0.
      TRANSLATE lv_ext TO UPPER CASE.
      CONDENSE lv_ext.
    ELSE.
      DATA: lv_where TYPE string.

      CONCATENATE 'dateifrmt LIKE ''%' lv_extension '%''' INTO lv_where.
      SELECT SINGLE dappl INTO lv_ext
        FROM tdwp
        WHERE (lv_where).
      IF sy-subrc EQ 0.
        TRANSLATE lv_ext TO UPPER CASE.
        CONDENSE lv_ext.
      ENDIF.
    ENDIF.

*   ls_documentfiles-deletevalue            = ''.
*   ls_documentfiles-documenttype           = ''.
*   ls_documentfiles-documentnumber         = ''.
*   ls_documentfiles-documentpart           = ''.
*   ls_documentfiles-documentversion        = ''.
    ls_documentfiles-originaltype           = '1'.
*   ls_documentfiles-sourcedatacarrier      = ''.
    ls_documentfiles-storagecategory        = 'ZDMS_OXIQ'.
    ls_documentfiles-wsapplication          = lv_ext. "'WWI'.
    ls_documentfiles-docpath                = gw_file-path.
    ls_documentfiles-docfile                = gw_file-filename.
*   ls_documentfiles-statusintern           = ''.
*   ls_documentfiles-statusextern           = ''.
*   ls_documentfiles-statuslog              = ''.
*   ls_documentfiles-application_id         = ''.
*   ls_documentfiles-file_id                = ''.
*   ls_documentfiles-description            = ''.
    ls_documentfiles-language               = 'ES'.
    ls_documentfiles-checkedin              = 'X'.
    ls_documentfiles-active_version         = 'X'.
    ls_documentfiles-created_at             = sy-datum.
*   ls_documentfiles-changed_at             = sy-datum.
    ls_documentfiles-created_by             = sy-uname.
*   ls_documentfiles-changed_by             = sy-uname.
    ls_documentfiles-content_description    = sy-uname.
    APPEND ls_documentfiles TO lt_documentfiles.

*   " Crear documento
    CALL FUNCTION 'BAPI_DOCUMENT_CREATE2'
      EXPORTING
        documentdata         = ls_document
        pf_ftp_dest          = 'SAPFTPA'
        pf_http_dest         = 'SAPHTTPA'
        defaultclass         = 'X'
      IMPORTING
        documenttype         = lv_doctype
        documentnumber       = lv_docnumber
        documentpart         = lv_docpart
        documentversion      = lv_docversion
        return               = ls_return
      TABLES
        documentdescriptions = lt_documentdescriptions
        objectlinks          = lt_objectlinks
        documentfiles        = lt_documentfiles.

    IF ls_return-type NE 'E'.

      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = abap_true.

      rv_success = abap_true.

    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK' .
      rv_success = abap_false.
    ENDIF.

*    APPEND LINES OF lt_return TO gt_log.
  ENDMETHOD.                    "upload_to_dms

  METHOD validate_order.
    DATA lv_aufnr TYPE aufk-aufnr.
    DATA: ls_header TYPE bapi_alm_order_header_e.
    DATA: lt_operations TYPE TABLE OF bapi_alm_order_operation_e,
          lt_srule      TYPE TABLE OF bapi_alm_order_srule_e,
          lt_return     TYPE TABLE OF bapiret2.
*
    lv_aufnr = iv_order_num.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = lv_aufnr
      IMPORTING
        output = lv_aufnr.

*
    CALL FUNCTION 'BAPI_ALM_ORDER_GET_DETAIL'
      EXPORTING
        number        = lv_aufnr
      IMPORTING
        es_header     = ls_header
      TABLES
        et_operations = lt_operations
        et_srules     = lt_srule
        return        = lt_return.

    IF sy-subrc EQ 0 AND ls_header IS NOT INITIAL.
      rv_exists = abap_true.
    ELSE.
      rv_exists = abap_false.
    ENDIF.
  ENDMETHOD.                    "validate_order

  METHOD delete_file.
    DATA: lv_full_path TYPE string.

    " Concatenar path y filename si vienen por separado
    lv_full_path = gw_file-path && gw_file-filename.

    " Primero verificar si existe
    OPEN DATASET lv_full_path FOR INPUT IN BINARY MODE.
    IF sy-subrc = 0.
      CLOSE DATASET lv_full_path.

      " Si existe, intentar borrarlo
      DELETE DATASET lv_full_path.
      IF sy-subrc <> 0.
        " Manejo del error
        MESSAGE e000(00) WITH 'Error al borrar archivo:' sy-subrc.
      ENDIF.
    ELSE.
      MESSAGE e000(00) WITH 'Archivo no encontrado:' lv_full_path.
    ENDIF.

  ENDMETHOD.                    "delete_file
*
  METHOD create_log.
* "Variable para el control del log
    DATA: lv_msgv1   TYPE syst-msgv1,
          lv_msgv2   TYPE syst-msgv2,
          lv_msgv3   TYPE syst-msgv3,
          lv_msgv4   TYPE syst-msgv4,
          lv_msgnr   TYPE smesgx-txtnr,
          ls_messtab TYPE bdcmsgcoll.
*   Despliega archivo procesados.
    LOOP AT gt_files INTO gw_file.
      ls_messtab-msgid  = '00'.
      IF gw_file-processed = abap_false.
        ls_messtab-msgtyp = 'E'.
      ELSE.
        ls_messtab-msgtyp = 'I'.
      ENDIF.
*      ls_messtab-msgspra.
      ls_messtab-msgnr = '000'.
      ls_messtab-msgv1 = |'Archivo ' { gw_file-filename }|.
      ls_messtab-msgv2 = |'Orden N° '{ gw_file-order_num }|.
      ls_messtab-msgv2 = |{ gw_file-error_msg }|.
      APPEND ls_messtab TO gt_messtab.
      PERFORM build_log TABLES gt_messtab.
    ENDLOOP.
  ENDMETHOD.                    "create_log
*
ENDCLASS.                    "lcl_report IMPLEMENTATION