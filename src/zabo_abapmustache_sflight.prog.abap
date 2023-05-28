*&---------------------------------------------------------------------*
*& Report ZABO_ABAPMUSTACHE_SFLIGHT
*&---------------------------------------------------------------------*
*& Manifests for given flights: plane types and pax lists
*&---------------------------------------------------------------------*
REPORT zabo_abapmustache_sflight.


TYPES:
  BEGIN OF ty_sflight,
    carrid    TYPE s_carr_id,
    connid    TYPE s_conn_id,
    fldate    TYPE s_date,
    planetype TYPE s_planetye,
    producer  TYPE s_prod,
  END OF ty_sflight,
  BEGIN OF ty_sbook,
    bookid    TYPE  s_book_id,
    customid  TYPE  s_customer,
    cancelled TYPE  s_cancel,
    reserved  TYPE  s_reserv,
    passname  TYPE  s_passname,
  END OF ty_sbook,
  ty_sbook_tt TYPE STANDARD TABLE OF ty_sbook WITH NON-UNIQUE DEFAULT KEY.
TYPES: BEGIN OF ty_manifest.
         INCLUDE TYPE ty_sflight.
TYPES:   paxlist TYPE ty_sbook_tt.
TYPES END OF ty_manifest.
TYPES ty_manifest_tt TYPE STANDARD TABLE OF ty_manifest.


TABLES: sflight, saplane, sbook.


SELECT-OPTIONS: s_carrid FOR sflight-carrid DEFAULT 'LH',
                s_connid FOR sflight-connid DEFAULT '0400',
                s_fldate FOR sflight-fldate DEFAULT '20161118'.


START-OF-SELECTION.
  DATA lo_mustache TYPE REF TO zcl_mustache.
  DATA lt_manifest TYPE ty_manifest_tt.
  DATA wa_sflight TYPE ty_sflight.
  DATA lv_text TYPE string.
  DATA lt_text TYPE string_table.

  SELECT *
    FROM sflight AS f
    INNER JOIN saplane AS p ON f~planetype = p~planetype
    INTO CORRESPONDING FIELDS OF wa_sflight
    WHERE carrid IN s_carrid
      AND connid IN s_connid
      AND fldate IN s_fldate.
    APPEND INITIAL LINE TO lt_manifest ASSIGNING FIELD-SYMBOL(<fs_manifest>).
    MOVE-CORRESPONDING wa_sflight TO <fs_manifest>.
    SELECT *
      FROM sbook
      INTO CORRESPONDING FIELDS OF TABLE <fs_manifest>-paxlist
      WHERE carrid = <fs_manifest>-carrid
        AND connid = <fs_manifest>-connid
        AND fldate = <fs_manifest>-fldate
        AND cancelled = abap_false
        AND passname <> ''.
  ENDSELECT.

  lo_mustache = zcl_mustache=>create(
    'Flight manifest for {{carrid}} flight {{connid}} on {{fldate}} operated using {{planetype}} made by {{producer}}' && cl_abap_char_utilities=>newline &&
    '{{#paxlist}}' &&
    '* ID: {{customid}} / Name: {{passname}}' && cl_abap_char_utilities=>newline &&
    '{{/paxlist}}' && cl_abap_char_utilities=>newline
   ).

* Table with separate lines
  lt_text = lo_mustache->render_tt( lt_manifest ).
  cl_demo_output=>write( lt_text ).

* One long string with embedded newlines
*  lv_text = lo_mustache->render( lt_manifest ).
*  cl_demo_output=>write( lv_text ).

  cl_demo_output=>display( ).
