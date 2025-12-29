*&---------------------------------------------------------------------*
*&  Include           ZPM_UPLOAD_ORDERMAINTAIN_TOP
*&---------------------------------------------------------------------*

* Tipos de datos
TYPES: BEGIN OF ty_file,
         filename    TYPE string,
         order_num   TYPE aufnr,
         path        TYPE string,
         processed   TYPE abap_bool,
         error_msg   TYPE string,
       END OF ty_file.

* Tablas internas
DATA: gt_files      TYPE TABLE OF ty_file,
      gt_log        TYPE TABLE OF bapiret2,
      gw_file       TYPE ty_file,
      gv_filestring TYPE string.

DATA gt_messtab TYPE STANDARD TABLE OF bdcmsgcoll.