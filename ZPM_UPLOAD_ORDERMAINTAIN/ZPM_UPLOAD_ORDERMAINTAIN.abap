*&============================================================*
*& REPORT ZPM_UPLOAD_ORDERMAINTAIN
*&============================================================*
***************************************************************
* Programa        = ZPM_UPLOAD_ORDERMAINTAIN
* Titulo          = Reporte carga orden de trabajo
* Modulo          = PM
*-------------------------------------------------------------*
* Descripción:
* Se requiere un reporte que carga orden de trabajo
*&============================================================*
*& Histórico de modificaciones                                *
*&============================================================*
*&                                                            *
*& Autor:                                                     *
*& Fecha:                                                     *
*& Descripción la Modificación:                               *
*&                                                            *
*&============================================================*
REPORT zpm_upload_ordermaintain.

*&---------------------------------------------------------------------*
*& INCLUDES
*&---------------------------------------------------------------------*
INCLUDE  zpm_upload_ordermaintain_top.
INCLUDE  zpm_upload_ordermaintain_sel.
INCLUDE  zpm_upload_ordermaintain_lcl.
INCLUDE  zpm_upload_ordermaintain_f01.

*&---------------------------------------------------------------------*
*& INITIALIZATION
*&---------------------------------------------------------------------*
INITIALIZATION.
  PERFORM authority_checks.
*&---------------------------------------------------------------------*
*& START-OF-SELECTION
*&---------------------------------------------------------------------*
START-OF-SELECTION.
  lcl_report=>main( ).