*-----------------------------
* INCLUDES - Declaración datos
*-----------------------------


TYPES:BEGIN OF x_salida,
  filename          TYPE sdok_filnm,
  dokar             TYPE dokar,
  doknr             TYPE doknr,
  dokvr             TYPE dokvr,
  doktl             TYPE doktl_d,
  statusextern_ini  TYPE  stabk,
  wsapp             TYPE dappl,
  docfile1          TYPE  filep,
  statusextern_fin  TYPE  stabk,
*  dokob  TYPE dokob,
*  obzae  TYPE obzae,
*  objky  TYPE objky,
*  phio_id TYPE sdok_phid,
*  ph_class TYPE  sdok_phcl,
*  loio_id TYPE sdok_loid,
*  lo_class TYPE  sdok_locl,
*  fullpath TYPE string,
  END OF x_salida.

DATA: ls_salida TYPE x_salida,
      lt_salida TYPE TABLE OF x_salida.

DATA: ls_draw TYPE draw,
        lt_draw TYPE TABLE OF draw,
        ls_documentdata TYPE bapi_doc_draw2,
        ls_return TYPE bapiret2,
        it_documentdescriptions TYPE TABLE OF bapi_doc_drat,
        it_documentfiles TYPE TABLE OF  bapi_doc_files2,
        ls_documentfiles TYPE bapi_doc_files2,
        it_characteristicvalues TYPE TABLE OF bapi_characteristic_values,
        it_classallocations TYPE TABLE OF bapi_class_allocation,
        lv_pf_ftp_dest TYPE rfcdes-rfcdest.
"--- Seleccionar todos los documentos por tipo

DATA: lt_dms_doc2loio TYPE TABLE OF dms_doc2loio,
      ls_dms_doc2loio TYPE dms_doc2loio,
      lt_dms_ph_cd1 TYPE TABLE OF dms_ph_cd1,
      ls_dms_ph_cd1 TYPE dms_ph_cd1.
.
CONSTANTS : c_storage TYPE sdok_stcat VALUE 'ZDMS_OXIQ',
c_directoryname TYPE text60 VALUE 'Z_FTP',
c_uri_draw TYPE text40 VALUE '\respaldocontent\resultado\drawarchivos\',
c_uri TYPE text17 VALUE '\respaldocontent\',
c_uri_resultado TYPE c LENGTH 52 VALUE '\respaldocontent\resultado\SNPResultadomigracion.csv',
c_ec TYPE stabk VALUE 'EC',
c_li TYPE stabk VALUE 'LI',
c_ftp TYPE dirname_al11 VALUE 'C:\FTP\respaldo',
c_mensaje1 TYPE string VALUE 'Error al leer documento MF SCMS_DOC_READ, doknr=',
c_mensaje2 TYPE string VALUE 'Error al abrir archivo en AL11 OPEN DATASET ',
c_mensaje3 TYPE string VALUE 'Error al abrir el archivo en el servidor, doknr=',
c_mensaje4 TYPE string VALUE 'Se ha producido un error al obtener registro de DMS_DOC2LOIO, documento DOKNR=',
c_mensaje5 TYPE string VALUE 'Se ha producido un error al descargar documento DOKNR=',
c_mensaje6 TYPE string VALUE 'No se pudo abrir el archivo en el servidor (AL11) lv_filename='.




DATA: lt_access_info TYPE TABLE OF scms_acinf,
      ls_access_info TYPE scms_acinf,
      lt_content_txt TYPE TABLE OF sdokcntasc,
      lt_sdokcntbin TYPE TABLE OF sdokcntbin,
      ls_sdokcntbin TYPE sdokcntbin.
DATA lv_filename TYPE string.
DATA lv_mensaje TYPE string.
DATA: lv_filename_al11 TYPE string.
DATA lv_fullpath TYPE string.

DATA: lv_idcoc TYPE doknr,
      lv_momento TYPE tabname16,
      lv_type TYPE bapi_mtype,
      ld_id   TYPE symsgid,
      lv_number TYPE symsgno,
*      lv_mensaje TYPE bapi_msg.
lv_mensaje1 TYPE symsgv.

"PARAMETERS: p_ambien TYPE char3.



DATA lv1 TYPE c.
DATA id_log TYPE balloghndl.
DATA ls_bin      TYPE sdokcntbin.
DATA ls_output TYPE string.
*DATA: lv_directoryname TYPE text60.
DATA: ls_entry TYPE cst_rswatch01_alv.
DATA: lv_filename_csv TYPE string.
DATA: lt_output   TYPE STANDARD TABLE OF string.

FIELD-SYMBOLS <fs_line> TYPE any.
FIELD-SYMBOLS <fs_comp> TYPE any.
DATA lv_line TYPE string.
CLEAR ls_salida.


DATA: lv_val       TYPE char255,
      lv_index     TYPE i.

FIELD-SYMBOLS: <ls_row>.",    " fila de la tabla

DATA lx_root TYPE REF TO cx_root.
DATA: lx_err TYPE REF TO cx_root,
      lv_msg TYPE string.
DATA lv_tab  TYPE string VALUE cl_abap_char_utilities=>horizontal_tab.