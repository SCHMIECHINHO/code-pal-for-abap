CLASS y_check_number_methods DEFINITION
  PUBLIC
  INHERITING FROM y_check_base
  CREATE PUBLIC .

  PUBLIC SECTION.

    CONSTANTS c_myname TYPE sci_chk VALUE 'Y_CHECK_NUMBER_METHODS' ##NO_TEXT.

    METHODS constructor .
  PROTECTED SECTION.

    METHODS execute_check
        REDEFINITION .
    METHODS inspect_tokens
        REDEFINITION .
  PRIVATE SECTION.
    DATA method_counter TYPE i VALUE 0.

    METHODS checkif_error
      IMPORTING index TYPE i.
ENDCLASS.



CLASS Y_CHECK_NUMBER_METHODS IMPLEMENTATION.


  METHOD checkif_error.
    DATA(check_configuration) = detect_check_configuration( threshold = method_counter
                                                            include = get_include( p_level = statement_for_message-level ) ).
    IF check_configuration IS INITIAL.
      RETURN.
    ENDIF.

    IF method_counter > check_configuration-threshold.
      raise_error( p_sub_obj_type = c_type_include
                   p_level        = statement_for_message-level
                   p_position     = index
                   p_from         = statement_for_message-from
                   p_kind         = check_configuration-prio
                   p_test         = me->myname
                   p_code         = get_code( check_configuration-prio )
                   p_param_1      = |{ method_counter }|
                   p_param_2      = |{ check_configuration-threshold }| ).
    ENDIF.
  ENDMETHOD.


  METHOD constructor.
    super->constructor( ).
    description = 'Number of Methods'(001).
    category    = 'Y_CHECK_CATEGORY'.
    version     = '0000'.
    position    = '660'.
    has_documentation = abap_true.

    check_name = c_myname.

    settings-pseudo_comment = '"#EC NUMBER_METHODS' ##NO_TEXT.
    settings-threshold = 20.
    settings-documentation = |{ c_docs_path-checks }number-methods.md|.

    y_message_registration=>add_message(
      EXPORTING
        check_name     = me->myname
        text           = '[Clean Code]: &1 methods, exceeding threshold of &2'(102)
        pseudo_comment = settings-pseudo_comment
      CHANGING
        messages       = me->scimessages ).
  ENDMETHOD.


  METHOD execute_check.
    LOOP AT ref_scan_manager->get_structures( ) ASSIGNING FIELD-SYMBOL(<structure>)
      WHERE stmnt_type EQ scan_struc_stmnt_type-class_definition OR
            stmnt_type EQ scan_struc_stmnt_type-interface.

      is_testcode = test_code_detector->is_testcode( <structure> ).

      TRY.
          DATA(check_configuration) = check_configurations[ apply_on_testcode = abap_true ].
        CATCH cx_sy_itab_line_not_found.
          IF is_testcode EQ abap_true.
            CONTINUE.
          ENDIF.
      ENDTRY.

      READ TABLE ref_scan_manager->get_statements( ) INTO statement_for_message
        INDEX <structure>-stmnt_from.
      method_counter = 0.

      LOOP AT ref_scan_manager->get_statements( ) ASSIGNING FIELD-SYMBOL(<statement>)
        FROM <structure>-stmnt_from TO <structure>-stmnt_to.

        inspect_tokens( statement = <statement> ).
      ENDLOOP.

      checkif_error( <structure>-stmnt_from ).
    ENDLOOP.
  ENDMETHOD.


  METHOD inspect_tokens.
    CASE get_token_abs( statement-from ).
      WHEN 'METHODS' OR 'CLASS-METHODS'.
        ADD 1 TO method_counter.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
