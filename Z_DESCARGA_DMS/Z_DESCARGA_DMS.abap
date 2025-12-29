*&---------------------------------------------------------------------*
*& Report  Z_DESCARGA_DMS
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT z_descarga_dms.

INCLUDE z_descarga_dms_top.
INCLUDE z_descarga_dms_forms.

START-OF-SELECTION.


  ls_entry-dirname = c_ftp.

  "Obtener metadatos de adjuntos
  PERFORM get_data TABLES lt_draw
                          lt_dms_doc2loio.
*
  PERFORM inicia_log CHANGING id_log.
*
  LOOP AT lt_draw INTO ls_draw .

    CALL FUNCTION 'BAPI_DOCUMENT_GETDETAIL2'
      EXPORTING
        documenttype         = ls_draw-dokar
        documentnumber       = ls_draw-doknr
        documentpart         = ls_draw-doktl
        documentversion      = ls_draw-dokvr
        getcomponents        = abap_true
        getdocdescriptions   = abap_true
        getdocfiles          = abap_true
        getclassification    = abap_true
      IMPORTING
        documentdata         = ls_documentdata
        return               = ls_return
      TABLES
        documentdescriptions = it_documentdescriptions
        documentfiles        = it_documentfiles
        characteristicvalues = it_characteristicvalues
        classallocations     = it_classallocations.


    READ TABLE it_documentfiles INTO ls_documentfiles INDEX 1.

    ls_salida-statusextern_ini  = c_ec.
    ls_salida-wsapp             = ls_documentfiles-wsapplication.
    ls_salida-docfile1          = ls_documentdata-docfile1.
    ls_salida-statusextern_fin  = c_li.

    CALL FUNCTION 'BAPI_DOCUMENT_CHECKOUTVIEW2'
      EXPORTING
        documenttype    = ls_draw-dokar
        documentnumber  = ls_draw-doknr
        documentpart    = ls_draw-doktl
        documentversion = ls_draw-dokvr
        documentfile    = ls_documentfiles
        getstructure    = '1'
        getheader       = abap_true
        pf_ftp_dest     = 'SAPFTPA'
      IMPORTING
        return          = ls_return
      TABLES
        documentfiles   = it_documentfiles.

    READ TABLE it_documentfiles INTO ls_documentfiles INDEX 1.

    TRY.
        CALL FUNCTION 'SCMS_DOC_READ'
          EXPORTING
            mandt               = sy-mandt
            stor_cat            = c_storage
            doc_id              = ls_documentfiles-file_id
          TABLES
            access_info         = lt_access_info
            content_bin         = lt_sdokcntbin
          EXCEPTIONS
            bad_storage_type    = 1
            bad_request         = 2
            unauthorized        = 3
            not_found           = 4
            communication_error = 5
            error_http          = 6
            OTHERS              = 7.

        IF sy-subrc <> 0.
          CONCATENATE c_mensaje1
                   ls_salida-doknr
              INTO lv_mensaje.

          PERFORM registrar_log USING ls_access_info
                                      ls_draw
                                      ls_dms_ph_cd1
                                      lv_mensaje.
        ELSE.

          READ TABLE lt_access_info INTO ls_access_info INDEX 1.

          CONCATENATE ls_entry-dirname
                      c_uri_draw
                      ls_draw-dokar
                      ls_draw-doknr
                      ls_draw-doktl
                      ls_draw-dokvr
                      '.txt'
                 INTO lv_fullpath.

          OPEN DATASET lv_fullpath FOR OUTPUT IN BINARY MODE.
          IF sy-subrc <> 0.

            CONCATENATE c_mensaje2
                        lv_fullpath
                        ' FOR OUTPUT IN BINARY MODE'
                        ls_salida-doknr
                  INTO lv_mensaje.

            PERFORM registrar_log USING ls_access_info
                                        ls_draw
                                        ls_dms_ph_cd1
                                        lv_mensaje.
          ENDIF.

          LOOP AT lt_sdokcntbin INTO ls_sdokcntbin.
            TRANSFER ls_sdokcntbin-line TO lv_fullpath.
          ENDLOOP.

          CLOSE DATASET lv_fullpath.

        ENDIF.

        " Ruta destino AL11 "
        CONCATENATE ls_entry-dirname
                    c_uri
                    ls_access_info-comp_id
               INTO lv_filename.

*    --- Abrir archivo en el application server ---
        OPEN DATASET lv_filename FOR OUTPUT IN BINARY MODE.
        IF sy-subrc <> 0.
          CONCATENATE c_mensaje3
                    ls_salida-doknr
               INTO lv_mensaje.

          PERFORM registrar_log USING ls_access_info
                                      ls_draw
                                      ls_dms_ph_cd1
                                      lv_mensaje.
        ENDIF.

        "--- Escribir contenido ---
        LOOP AT lt_sdokcntbin INTO ls_bin.
          TRANSFER ls_bin-line TO lv_filename.
        ENDLOOP.

        CLOSE DATASET lv_filename.

      CATCH cx_root INTO lx_err.
        " Captura de errores no declarados
        lv_mensaje = lx_err->get_text( ).

        PERFORM registrar_log USING ls_access_info
                                    ls_draw
                                    ls_dms_ph_cd1
                                    lv_mensaje.
    ENDTRY.

    IF sy-subrc = 0.
      READ TABLE lt_dms_doc2loio INTO ls_dms_doc2loio WITH KEY doknr = ls_draw-doknr.
      IF sy-subrc EQ 0.
*        READ TABLE lt_dms_ph_cd1 INTO ls_dms_ph_cd1 WITH KEY loio_id = ls_dms_doc2loio-lo_objid.
*        IF sy-subrc EQ 0.
          ls_salida-filename          = ls_access_info-comp_id.
          ls_salida-dokar             = ls_draw-dokar.
          ls_salida-doknr             = ls_draw-doknr.
          ls_salida-dokvr             = ls_draw-dokvr.
          ls_salida-doktl             = ls_draw-doktl.
*          ls_salida-dokob     = ls_draw-dokob.
*          ls_salida-obzae     = ls_draw-obzae.
*          ls_salida-objky     = ls_draw-objky.
*          ls_salida-phio_id   = ls_dms_ph_cd1-phio_id.
*          ls_salida-ph_class  = ls_dms_ph_cd1-ph_class.
*          ls_salida-loio_id   = ls_dms_ph_cd1-loio_id.
*          ls_salida-lo_class  = ls_dms_ph_cd1-lo_class.
*          ls_salida-fullpath  = lv_fullpath.
          APPEND ls_salida TO lt_salida.
*        ELSE.
*          CONCATENATE 'Se ha producido un error al obtener registro de DMS_PH_CD1, documento DOKNR='
*                      ls_draw-doknr
*                      ', loio_id='
*                      ls_dms_doc2loio-lo_objid
*                 INTO lv_mensaje.
*          PERFORM registrar_log USING ls_access_info
*                                      ls_draw
*                                      ls_dms_ph_cd1
*                                      lv_mensaje.
**        ENDIF.
      ELSE.
        CONCATENATE c_mensaje4
                    ls_draw-doknr
               INTO lv_mensaje.

        PERFORM registrar_log USING ls_access_info
                                    ls_draw
                                    ls_dms_ph_cd1
                                    lv_mensaje.

      ENDIF.


    ELSE.
      CONCATENATE c_mensaje5
                  ls_draw-doknr
             INTO lv_mensaje.

      PERFORM registrar_log USING ls_access_info
                                  ls_draw
                                  ls_dms_ph_cd1
                                  lv_mensaje.
    ENDIF.

    CLEAR: lv_filename, lv_mensaje, lv_fullpath,
           ls_documentdata, ls_return, ls_documentfiles, ls_salida, ls_draw.
    REFRESH:  it_documentdescriptions, it_documentfiles, it_characteristicvalues, it_classallocations,
              lt_access_info, lt_sdokcntbin.


  ENDLOOP.

  "Exportar datos recorridos en txt final
  " Construir nombre de archivo en AL11
  CLEAR: lv_filename.

  CONCATENATE ls_entry-dirname c_uri_resultado INTO lv_filename.

  " Recorrer la tabla y convertir cada fila a una línea CSV separada por ';'
  LOOP AT lt_salida ASSIGNING <ls_row>.
    CLEAR lv_line.
    lv_index = 1.

    DO.
      ASSIGN COMPONENT lv_index OF STRUCTURE <ls_row> TO <fs_comp>.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.

      " Convertir el componente a texto
      CLEAR lv_val.

      WRITE <fs_comp> TO lv_val.
      CONDENSE lv_val.
      IF lv_line IS INITIAL.
        lv_line = lv_val.
      ELSE.
        CONCATENATE lv_line lv_val INTO lv_line SEPARATED BY lv_tab.
      ENDIF.

      lv_index = lv_index + 1.
    ENDDO.


    APPEND lv_line TO lt_output.
  ENDLOOP.

  " Escribir fichero en AL11 (server)
  OPEN DATASET lv_filename FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  IF sy-subrc <> 0.

    CONCATENATE c_mensaje6
                lv_filename
           INTO lv_mensaje.

    PERFORM registrar_log USING ls_access_info
                                ls_draw
                                ls_dms_ph_cd1
                                lv_mensaje.
  ENDIF.

  LOOP AT lt_output INTO ls_output.

    TRANSFER ls_output TO lv_filename.
  ENDLOOP.

  CLOSE DATASET lv_filename.


  PERFORM guardar_log USING id_log.