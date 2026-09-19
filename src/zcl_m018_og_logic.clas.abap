class ZCL_M018_OG_LOGIC definition
  public
  inheriting from ZCL_RAK_GRANT_LOGIC
  final
  create public .

*&---------------------------------------------------------------------*
*& M018 Grant Request - the longest journey in the family.
*&
*&   STP1  NOG_1_1   Grant Information   type, beneficiary, BP list
*&   STP2  NOG_1_2   Family Details      wives and children
*&   STP3  NOG_1_3   Program Details     housing ref, loan
*&   STP4  NOG_1_4   Documents           seven uploads
*&   STP5  NOG_1_5   Fees & Payment
*&   ---   NOG_1_6   the CPG screen - PAY_SCREEN, never a CJS step
*&
*& TWO ATTACHMENT SCREENS, and ZEGA_T_CJ_UI_MAP says so: ATTACHMENT sits
*& on both NOG_1_1 and NOG_1_4. Step 1 has the identification document
*& inside the partner search; step 4 is the documents page. A feeder that
*& puts uploads on only one of them loses the other silently, because a
*& screen with no ATTACHMENT row never calls GET_ATTACHMENT( ).
*&
*& AND M018 IS THE ONE JOURNEY THE ABSTRACT SKIPS ATTACHMENTS FOR ON THE
*& CASE. CREATE_DUMMY_CASE( ) reads
*&
*&     IF mv_journeytype <> 'M018'.
*&       get_attachment( ... for_case = abap_true ... ).
*&
*& so its files stay against the draft and are NOT copied into the
*& container case as base64. That is deliberate on the backend side -
*& seven documents including a family book would be a large case payload
*& - and it means an uploaded file is still there, still readable, and
*& simply not duplicated. Do not "fix" it CJS-side by posting them again.
*&
*& THE BENEFICIARY TOGGLE DRIVES THE WHOLE OF STEP 1. Individual asks
*& for nothing more; Shared asks for a grantee COUNT and then a partner
*& list, and the count is what the citizen is held to. That rule is
*& below - it is the one thing the backend cannot check, because at the
*& time it validates it has the list but not the number the citizen
*& said.
*&---------------------------------------------------------------------*
public section.

*   ---- step 1: grant type and beneficiary -----------------------------
*   NAMES CONFIRMED FROM EXPORT_DEFIN.XLSX for NOG_1_1..NOG_1_4.
*   ONE EXCEPTION, deliberately: C_FLD_LOAN_STAT is RB1_LOAN, a CJS
*   name. The export calls the loan toggle RB1 on NOG_1_3 and the
*   beneficiary toggle RB1 on NOG_1_1 - legacy names are per SCREEN
*   and BUILD_MODEL( ) is flat per JOURNEY, so the two would have
*   shared one model component and each would have set the other.
*   The feeder gives that field TECH_NAME = RB1, which is what the
*   BAdI maps values by; only FIELD_CONTROL on it is lost, and a
*   CTRL_OF( ) miss now reads as no instruction rather than as
*   forced-optional. Do not "fix" this back to RB1.
  constants C_FLD_GRANT_TYPE type STRING value 'RB3' ##NO_TEXT.
  constants C_FLD_BENEF type STRING value 'RB1' ##NO_TEXT.
  constants C_FLD_GRANTEES type STRING value 'NUMINPUT' ##NO_TEXT.
*   The partner list the citizen builds with the search. A grid, so
*   GET_GRID_DATA( ) reaches it and GET_VAL( ) does not.
  constants C_FLD_BPLIST type STRING value 'TABLE_FETCHER' ##NO_TEXT.
*   ---- step 2: family details -----------------------------------------
*   Number of wives is a five-option radio (0..4) and the children count
*   per wife is a dropdown that appears once per wife the citizen
*   declared. Four carriers, only as many shown as the radio allows -
*   which is rule work in ZRAK_T_JNY_RULE, not code.
  constants C_FLD_WIVES type STRING value 'RB0' ##NO_TEXT.
  constants C_FLD_CHILD1 type STRING value 'CHILD1CB' ##NO_TEXT.
  constants C_FLD_CHILD2 type STRING value 'CHILD2CB' ##NO_TEXT.
  constants C_FLD_CHILD3 type STRING value 'CHILD3CB' ##NO_TEXT.
  constants C_FLD_CHILD4 type STRING value 'CHILD4CB' ##NO_TEXT.
*   ---- step 3: program details ----------------------------------------
  constants C_FLD_HOUSING type STRING value 'HOUSEREFINPUT' ##NO_TEXT.
  constants C_FLD_LOAN_STAT type STRING value 'RB1_LOAN' ##NO_TEXT. " CJS name; TECH_NAME is WITH_LOAN
  constants C_FLD_LOAN_VAL type STRING value 'LOANVALUEINPUT' ##NO_TEXT.
  constants C_FLD_LOAN_FROM type STRING value 'FROMDATE' ##NO_TEXT.
  constants C_FLD_LOAN_TO type STRING value 'TODATE' ##NO_TEXT.
  constants C_FLD_SEARCH type STRING value 'SHAERDID' ##NO_TEXT.
  constants C_FLD_GRID type STRING value 'TABLE_FETCHER' ##NO_TEXT.




*   The beneficiary values. SHARED is what turns the grantee count and
*   the partner list on.
*   The SHARED option key: the second member of the RB1/RB2 segmented
*   group, S_BENEFICIARY, whose FIELD_NAME is RB2 and whose LABEL_CON is
*   OG_SHARED. The key is RB2 - OG_SHARED is the label code.
*   ---- the Add Business Partner dialog --------------------------------
*   ONE POPUP ID AND THREE EVENTS. OPEN clears and shows it, FIND
*   resolves an Emirates ID to a partner and fills the read-only lines,
*   PICK adds the resolved partner to the grid. CANCEL is the base's.
  constants C_POP_BP type STRING value 'BPADD' ##NO_TEXT.
  constants C_EVT_OPEN type STRING value 'BPOPEN' ##NO_TEXT.
  constants C_EVT_FIND type STRING value 'BPFIND' ##NO_TEXT.
  constants C_EVT_PICK type STRING value 'BPPICK' ##NO_TEXT.
*   The dialog's own fields. Configured HIDDEN on STP1 - see the note in
*   ZRAK_M018_LOAD: without a ZRAK_T_JNY_FLD row each of these binds to
*   nothing and the dialog loses whatever is typed into it.
  constants C_POP_EID type STRING value 'POP_EID' ##NO_TEXT.
  constants C_POP_BPNO type STRING value 'POP_BPNO' ##NO_TEXT.
  constants C_POP_NAME type STRING value 'POP_BPNAME' ##NO_TEXT.
  constants C_POP_NAT type STRING value 'POP_NAT' ##NO_TEXT.
  constants C_POP_PHONE type STRING value 'POP_PHONE' ##NO_TEXT.

  constants C_BENEF_SHARED type STRING value 'RB2' ##NO_TEXT.

*   THE MIRROR OF ON_CHANGE( ), AND IT IS NOT OPTIONAL. Taking the
*   TECH_NAME off the four controls stops them posting a wrongly shaped
*   item - and also stops them being FILLED on the way back in, because
*   BACKEND_READ( ) matches a definition to a field by TECH_NAME. Only
*   the carriers come back now, so a resumed draft would redraw every
*   radio blank while the backend still held the answer. This reads the
*   carriers and puts the control back on the option they imply.
  methods ZIF_RAK_JOURNEY_LOGIC~ON_AFTER_READ
    redefinition .
*   WRITES THE RADIO CARRIERS. A legacy radio group is N boolean items,
*   one per button, and the backend tests each for 'X':
*
*       tpl_no_wives = COND #( WHEN WIFE1 = 'X' THEN '1' ... ).
*       IF GTYPE_G IS INITIAL AND GTYPE_N IS INITIAL AND GTYPE_P IS INITIAL.
*
*   CJS draws one RADIO per group and posts the chosen OPT_KEY - 'RB2',
*   never 'X' - so the controls carry no TECH_NAME and the hidden CY_*
*   fields carry the names instead. This sets exactly one per group and
*   clears its siblings, on every change, so a citizen who changes their
*   mind does not leave two of them set.
  methods ZIF_RAK_JOURNEY_LOGIC~ON_CHANGE
    redefinition .
  methods ZIF_RAK_JOURNEY_LOGIC~ON_CUSTOM_VALIDATE
    redefinition .
  methods ZIF_RAK_JOURNEY_LOGIC~ON_SEARCH
    redefinition .
protected section.

*   One group: clear every carrier, then set the one the chosen key maps
*   to. IT_MAP is key -> carrier field name.
  methods CARRY
    importing
      !IO_CTX type ref to ZIF_RAK_JOURNEY
      !IV_PICK type STRING
      !IT_MAP type ZIF_RAK_JOURNEY=>TT_KV .
*   The reverse: whichever carrier holds 'X' decides the control's value.
  methods UNCARRY
    importing
      !IO_CTX type ref to ZIF_RAK_JOURNEY
      !IV_CTL type STRING
      !IT_MAP type ZIF_RAK_JOURNEY=>TT_KV .
*   How many partners the citizen has actually added. Zero for a journey
*   with no grid, which is why the caller checks the beneficiary toggle
*   first rather than reading this on its own.
  methods ZIF_RAK_JOURNEY_LOGIC~ON_RENDER_BEFORE_FIELD redefinition .
  methods ZIF_RAK_JOURNEY_LOGIC~ON_RENDER_POPUP redefinition .
  methods ZIF_RAK_JOURNEY_LOGIC~ON_POPUP_EVENT redefinition .

  methods POP_CLEAR
    importing
      !IO_CTX type ref to ZIF_RAK_JOURNEY .
  methods POP_FIND
    importing
      !IO_CTX type ref to ZIF_RAK_JOURNEY
    returning
      value(RS) type ZCL_ZEGA_BP_MPC_EXT=>TS_BUSINESSPARTNER .
  methods BP_ROWS
    importing
      !IO_CTX type ref to ZIF_RAK_JOURNEY
    returning
      value(RV) type I .
  methods ALREADY_ADDED
    importing
      !IO_CTX type ref to ZIF_RAK_JOURNEY
      !IV_BP type STRING
    returning
      value(RV) type ABAP_BOOL .
  methods ADD_ROW
    importing
      !IO_CTX type ref to ZIF_RAK_JOURNEY
      !IS_BP type ZCL_ZEGA_BP_MPC_EXT=>TS_BUSINESSPARTNER .
  methods PICK
    importing
      !IS_BP type ZCL_ZEGA_BP_MPC_EXT=>TS_BUSINESSPARTNER
      !IV_NAMES type STRING
    returning
      value(RV) type STRING .
private section.
ENDCLASS.



CLASS ZCL_M018_OG_LOGIC IMPLEMENTATION.


  METHOD pop_clear.
    io_ctx->set_val( iv_name = c_pop_eid   iv_value = `` ).
    io_ctx->set_val( iv_name = c_pop_bpno  iv_value = `` ).
    io_ctx->set_val( iv_name = c_pop_name  iv_value = `` ).
    io_ctx->set_val( iv_name = c_pop_nat   iv_value = `` ).
    io_ctx->set_val( iv_name = c_pop_phone iv_value = `` ).
  ENDMETHOD.


  METHOD pop_find.

*   THE SAME READ ON_SEARCH( ) ALREADY MAKES, and deliberately the same
*   one: the dialog is a second door onto the partner the inline search
*   found, not a second way of finding partners. NO_MOI_CALL is set for
*   the reason it is set there - the federal lookup is not wanted for a
*   list the citizen is assembling by hand.
    DATA(lv_eid) = condense( io_ctx->get_val( c_pop_eid ) ).
    CHECK lv_eid IS NOT INITIAL.

    DATA ls_req TYPE zcl_rak_bp_search=>ty_req.
    ls_req-idtype      = 'EID'.
    ls_req-eid         = lv_eid.
    ls_req-no_moi_call = abap_true.

    DATA(ls_res) = NEW zcl_rak_bp_search( )->search( is_req = ls_req ).
    READ TABLE ls_res-rows INTO rs INDEX 1.
    IF sy-subrc <> 0.
      CLEAR rs.
    ENDIF.

  ENDMETHOD.


  METHOD zif_rak_journey_logic~on_render_before_field.

*   ---- THE BUTTON SITS ON THE LIST, NOT ON THE STEP -------------------
*   ON_RENDER_START( ) would put it at the top of step 1, above the grant
*   type. The live screen has it on the Business Partner list heading, to
*   the right, which is what ON_RENDER_BEFORE_FIELD on the grid gives -
*   the hook fires immediately before that one field is drawn.
    CHECK to_upper( is_field-name ) = c_fld_bplist.

*   AND ONLY WHEN THE LIST ITSELF IS THERE. R02 shows the grid for a
*   SHARED grant only; an Add button over a hidden grid would offer to
*   fill a list the citizen cannot see.
    CHECK io_ctx->get_val( c_fld_benef ) = c_benef_shared.

    DATA(lo_bar) = io_view->hbox( justifycontent = 'End'
                                  class          = 'sapUiTinyMarginBottom' ).
    lo_bar->button(
      text  = COND string( WHEN sy-langu = 'A'
                           THEN `+ شريك تجاري` ELSE `+ Business Partner` )
      icon  = 'sap-icon://add'
      type  = 'Transparent'
      press = io_ctx->event( c_evt_open ) ).

  ENDMETHOD.


  METHOD zif_rak_journey_logic~on_render_popup.

    CHECK iv_id = c_pop_bp.

*   TWO STATES, ONE DIALOG. Before a partner is resolved the primary
*   button SEARCHES; once POP_BPNO carries one it ADDS. The alternative -
*   a Search button of its own beside the field - is not something
*   DIALOG_FORM( ) draws, and a dialog that needs its own layout is a
*   dialog that stops matching every other one in the journey.
    DATA(lv_found) = xsdbool( io_ctx->get_val( c_pop_bpno ) IS NOT INITIAL ).

    dialog_form(
      io_ctx     = io_ctx
      io_popup   = io_popup
      iv_title   = COND string( WHEN sy-langu = 'A'
                                THEN `إضافة شريك تجاري` ELSE `Add Business Partner` )
      iv_ok_text = COND string(
                     WHEN lv_found = abap_true
                     THEN COND string( WHEN sy-langu = 'A' THEN `إضافة` ELSE `Add` )
                     ELSE COND string( WHEN sy-langu = 'A' THEN `بحث` ELSE `Search` ) )
      iv_ok_evt  = COND string( WHEN lv_found = abap_true THEN c_evt_pick ELSE c_evt_find )
      it_fields  = VALUE #(
        ( name  = c_pop_eid
          label = COND string( WHEN sy-langu = 'A' THEN `رقم الهوية` ELSE `Emirates ID` ) )
        ( name  = c_pop_bpno
          label = COND string( WHEN sy-langu = 'A' THEN `رقم الشريك` ELSE `BP number` ) )
        ( name  = c_pop_name
          label = COND string( WHEN sy-langu = 'A' THEN `الاسم` ELSE `Name` ) )
        ( name  = c_pop_nat
          label = COND string( WHEN sy-langu = 'A' THEN `الجنسية` ELSE `Nationality` ) )
        ( name  = c_pop_phone
          label = COND string( WHEN sy-langu = 'A' THEN `رقم الهاتف` ELSE `Phone Number` ) ) ) ).

  ENDMETHOD.


  METHOD zif_rak_journey_logic~on_popup_event.

    CASE iv_event.

      WHEN c_evt_open.
        pop_clear( io_ctx ).
        io_ctx->open_popup( c_pop_bp ).

      WHEN c_evt_find.
        DATA(ls_bp) = pop_find( io_ctx ).
        IF ls_bp-partner IS INITIAL.
          io_ctx->add_msg( iv_type = 'Warning'
                           iv_text = COND string(
                             WHEN sy-langu = 'A'
                             THEN `لم يتم العثور على شريك بهذه الهوية.`
                             ELSE `No business partner found for that Emirates ID.` ) ).
*         LEFT OPEN ON PURPOSE. A dialog that closes on a miss makes the
*         citizen reopen it and retype the number they just typed.
          RETURN.
        ENDIF.
        io_ctx->set_val( iv_name = c_pop_bpno  iv_value = CONV string( ls_bp-partner ) ).
        io_ctx->set_val( iv_name = c_pop_name  iv_value = pick( is_bp    = ls_bp
                                                                iv_names = `FULLNAME,NAME,NAME1` ) ).
        io_ctx->set_val( iv_name = c_pop_nat   iv_value = pick( is_bp    = ls_bp
                                                                iv_names = `NATIONALITY,NATIO,COUNTRY` ) ).
        io_ctx->set_val( iv_name = c_pop_phone iv_value = pick( is_bp    = ls_bp
                                                                iv_names = `MOBILE,PHONE,TELNR` ) ).

      WHEN c_evt_pick.
        DATA(lv_bp) = io_ctx->get_val( c_pop_bpno ).
        IF lv_bp IS INITIAL.
          RETURN.
        ENDIF.
        IF already_added( io_ctx = io_ctx iv_bp = lv_bp ) = abap_true.
          io_ctx->add_msg( iv_type = 'Warning'
                           iv_text = COND string(
                             WHEN sy-langu = 'A'
                             THEN `هذا الشريك مضاف بالفعل إلى القائمة.`
                             ELSE `That partner is already on the list.` ) ).
          pop_clear( io_ctx ).
          io_ctx->close_popup( ).
          RETURN.
        ENDIF.

*       RESOLVED AGAIN RATHER THAN CARRIED. ADD_ROW( ) takes the whole
*       TS_BUSINESSPARTNER, and rebuilding one from four strings in the
*       model would fill the four the dialog shows and leave every other
*       component blank - the grid is four columns today and will not
*       always be. One more read of a partner the citizen just looked at
*       is the cheaper mistake.
        DATA(ls_add) = pop_find( io_ctx ).
        IF ls_add-partner IS INITIAL.
          io_ctx->add_msg( iv_type = 'Warning'
                           iv_text = COND string(
                             WHEN sy-langu = 'A'
                             THEN `تعذر إضافة الشريك. يرجى المحاولة مرة أخرى.`
                             ELSE `That partner could not be added. Try again.` ) ).
          RETURN.
        ENDIF.
        add_row( io_ctx = io_ctx is_bp = ls_add ).
        pop_clear( io_ctx ).
        io_ctx->close_popup( ).

      WHEN OTHERS.
*       PAYNOW, PAYPOLL AND CANCEL ARE THE BASE'S. Swallowing them here
*       would take the payment step's own events with them.
        super->zif_rak_journey_logic~on_popup_event(
          io_ctx   = io_ctx
          iv_id    = iv_id
          iv_event = iv_event ).

    ENDCASE.

  ENDMETHOD.


  METHOD bp_rows.
*   GET_GRID_DATA( ), never GET_VAL( ). The interface is explicit that
*   GET_VAL( ) answers BLANK for a grid - the model member is a JSON
*   string and the accessor refuses it - so reading the list as a scalar
*   would report an empty table as confidently as a full one.
    rv = lines( io_ctx->get_grid_data( c_fld_bplist )-rows ).
  ENDMETHOD.


  METHOD zif_rak_journey_logic~on_custom_validate.

*   SUPER FIRST, AND BEFORE ANY `CHECK`. The chain is the engine's PAID
*   gate, then ZCL_RAK_MUN_LOGIC's parcel rule, then the grants base.
    rt = super->zif_rak_journey_logic~on_custom_validate( io_ctx  = io_ctx
                                                          iv_step = iv_step ).

*   ---- SHARED means the list must match the number promised ----------
*   THE BACKEND CANNOT CHECK THIS. By the time
*   ZCL_EGA_CJ_FW_RO_GRANT_ABS_V1 validates, it has the party list in
*   note CJ03 and it does not have the count the citizen typed - that is
*   a screen field, not a characteristic it stores. So the only place the
*   two can be compared is here.
*
*   AND GETTING IT WRONG IS EXPENSIVE THE QUIET WAY: a Shared grant that
*   posts with one grantee creates a case, raises a fee and takes a
*   payment for a grant that will then be rejected on review.
    DATA(lv_benef) = to_upper( condense( io_ctx->get_val( c_fld_benef ) ) ).

    IF lv_benef = c_benef_shared.

      DATA(lv_said) = condense( io_ctx->get_val( c_fld_grantees ) ).
      DATA(lv_have) = bp_rows( io_ctx ).

*     A BLANK COUNT IS THE CONFIGURED REQUIRED CHECK'S BUSINESS, not
*     this one's - VALIDATE_STEP( ) refuses Next on step 1 without it.
*     Reaching submit with it blank means the field is not configured
*     required, and saying so here is more useful than a comparison
*     against nothing.
      IF lv_said IS INITIAL.
        rt = VALUE #( BASE rt
          ( type = 'Error'
            text = COND string(
              WHEN sy-langu = 'A'
              THEN `يرجى تحديد عدد المستفيدين المشتركين.`
              ELSE `State the number of shared grantees before submitting.` ) ) ).
        RETURN.
      ENDIF.

      DATA lv_want TYPE i.
      TRY.
          lv_want = CONV i( lv_said ).
        CATCH cx_root.
*         A count that will not convert is a configuration problem, not
*         a citizen one - the field should be numeric. Reported rather
*         than silently treated as zero, which would let any list pass.
          rt = VALUE #( BASE rt
            ( type = 'Error'
              text = |The number of shared grantees ({ lv_said }) is not a number. | &&
                     |{ c_fld_grantees } should be configured as a numeric field.| ) ).
          RETURN.
      ENDTRY.

      IF lv_want > 0 AND lv_have <> lv_want.
        rt = VALUE #( BASE rt
          ( type = 'Error'
            text = COND string(
              WHEN sy-langu = 'A'
              THEN |تم تحديد { lv_want } من المستفيدين المشتركين، وتمت إضافة { lv_have }. |
                && |يرجى مطابقة القائمة مع العدد المحدد.|
              ELSE |You said { lv_want } shared grantee(s) and added { lv_have }. |
                && |Add or remove partners so the list matches the number.| ) ) ).
      ENDIF.

    ENDIF.

*   ---- the loan section, when there is a loan -------------------------
*   LOAN_INCOMPLETE( ) is on the grants base because M019 draws the same
*   three fields; only the names differ, so they are passed in. It
*   answers false unless the toggle actually says With Loan, which is
*   what keeps a Without Loan application from being blocked by fields
*   the backend has hidden.
    IF loan_incomplete( io_ctx    = io_ctx
                        iv_status = c_fld_loan_stat
                        iv_value  = c_fld_loan_val
                        iv_from   = c_fld_loan_from
                        iv_to     = c_fld_loan_to ) = abap_true.
      rt = VALUE #( BASE rt
        ( type = 'Error'
          text = COND string(
            WHEN sy-langu = 'A'
            THEN `عند اختيار "بقرض" يجب إدخال قيمة القرض وتاريخي البداية والنهاية.`
            ELSE `With Loan needs the loan value and both dates.` ) ) ).
    ENDIF.

  ENDMETHOD.


  METHOD carry.
*   CLEAR EVERY SIBLING FIRST, then set the one that was picked. Without
*   the clear a citizen who answers, goes back and answers differently
*   leaves both carriers set, and the backend's COND takes whichever it
*   tests first - which is not the one on screen.
    LOOP AT it_map INTO DATA(ls_m).
      io_ctx->set_val( iv_name = ls_m-value iv_value = `` ).
    ENDLOOP.

    IF iv_pick IS INITIAL.
      RETURN.
    ENDIF.

    READ TABLE it_map INTO DATA(ls_hit) WITH KEY key = iv_pick.
    IF sy-subrc = 0.
      io_ctx->set_val( iv_name = ls_hit-value iv_value = 'X' ).
    ENDIF.
  ENDMETHOD.


  METHOD zif_rak_journey_logic~on_change.
*   SUPER FIRST. The base body is empty today, but ZCL_RAK_MUN_LOGIC and
*   ZCL_RAK_GRANT_LOGIC sit between this class and it, and a rule added
*   to either later would be silently dropped by an unchained
*   redefinition - which is exactly how E128 lost its PAID gate twice.
    super->zif_rak_journey_logic~on_change( io_ctx = io_ctx iv_field = iv_field ).

    DATA lt_map TYPE zif_rak_journey=>tt_kv.
    DATA(lv_f) = to_upper( iv_field ).

    CASE lv_f.
*     Grant type. RB3/RB4/RB5 are the export's own field names for the
*     three buttons and GTYPE_N/_G/_P their TECHNICAL_NAMEs -
*     OG_1_1/RB4 reads TECHNICAL_NAME GTYPE_G, LABEL_CON OG_HOUSING,
*     which is what settles Housing as G rather than P.
      WHEN c_fld_grant_type.
        lt_map = VALUE #( ( key = 'RB3' value = 'CY_GTYPE_N' )
                          ( key = 'RB4' value = 'CY_GTYPE_G' )
                          ( key = 'RB5' value = 'CY_GTYPE_P' ) ).

*     Beneficiary. RB1 individual, RB2 shared - C_BENEF_SHARED already
*     names the second one and is used by the grantee-count rule.
      WHEN c_fld_benef.
        lt_map = VALUE #( ( key = 'RB1' value = 'CY_BENEF_I' )
                          ( key = c_benef_shared value = 'CY_BENEF_S' ) ).

*     Number of wives. The option TEXTS are literally 0,1,2,3,4, so the
*     key order is the count and there is nothing to infer.
      WHEN c_fld_wives.
        lt_map = VALUE #( ( key = 'RB0' value = 'CY_WIFE0' )
                          ( key = 'RB1' value = 'CY_WIFE1' )
                          ( key = 'RB2' value = 'CY_WIFE2' )
                          ( key = 'RB3' value = 'CY_WIFE3' )
                          ( key = 'RB4' value = 'CY_WIFE4' ) ).

*     Loan status. RB1 with a loan, RB2 without.
      WHEN c_fld_loan_stat.
        lt_map = VALUE #( ( key = 'RB1' value = 'CY_WITH_LOAN' )
                          ( key = 'RB2' value = 'CY_NO_LOAN' ) ).

      WHEN OTHERS.
        RETURN.
    ENDCASE.

    carry( io_ctx  = io_ctx
           iv_pick = to_upper( io_ctx->get_val( lv_f ) )
           it_map  = lt_map ).
  ENDMETHOD.


  METHOD uncarry.
*   FIRST CARRIER HOLDING 'X' WINS. CARRY( ) clears the siblings before
*   it sets one, so exactly one can be set - but a case created before
*   this handler existed, or touched by the back office, can hold more
*   than one, and picking the first is at least deterministic.
    LOOP AT it_map INTO DATA(ls_m).
      IF to_upper( condense( io_ctx->get_val( ls_m-value ) ) ) = 'X'.
        io_ctx->set_val( iv_name = iv_ctl iv_value = ls_m-key ).
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_rak_journey_logic~on_after_read.
    super->zif_rak_journey_logic~on_after_read( io_ctx ).

    uncarry( io_ctx = io_ctx iv_ctl = c_fld_grant_type
             it_map = VALUE #( ( key = 'RB3' value = 'CY_GTYPE_N' )
                               ( key = 'RB4' value = 'CY_GTYPE_G' )
                               ( key = 'RB5' value = 'CY_GTYPE_P' ) ) ).

    uncarry( io_ctx = io_ctx iv_ctl = c_fld_benef
             it_map = VALUE #( ( key = 'RB1'           value = 'CY_BENEF_I' )
                               ( key = c_benef_shared  value = 'CY_BENEF_S' ) ) ).

    uncarry( io_ctx = io_ctx iv_ctl = c_fld_wives
             it_map = VALUE #( ( key = 'RB0' value = 'CY_WIFE0' )
                               ( key = 'RB1' value = 'CY_WIFE1' )
                               ( key = 'RB2' value = 'CY_WIFE2' )
                               ( key = 'RB3' value = 'CY_WIFE3' )
                               ( key = 'RB4' value = 'CY_WIFE4' ) ) ).

    uncarry( io_ctx = io_ctx iv_ctl = c_fld_loan_stat
             it_map = VALUE #( ( key = 'RB1' value = 'CY_WITH_LOAN' )
                               ( key = 'RB2' value = 'CY_NO_LOAN' ) ) ).
  ENDMETHOD.


  METHOD add_row.

*   ---- THE CELL ORDER IS THE CONTRACT --------------------------------
*   SET_GRID_DATA( ) maps by name, but the COLUMNS handed back to it came
*   straight out of GET_GRID_DATA( ), so the map is an identity map and
*   cell N lands in configured column N. A cell appended out of order is
*   written to the neighbouring column; one appended past the last
*   configured column is dropped. Neither raises anything.
*
*   The order lives in ZRAK_T_JNY_COL for CONSULTANTS, seeded by
*   ZRAK_M029_LOAD, and it is:
*
*       10 COMPANY   20 ADDRESS   30 GRADE   40 BPID   50 EMAIL
*
*   Read that report before adding or reordering a column here.
    DATA(ls_grid) = io_ctx->get_grid_data( c_fld_grid ).

    DATA lt_cell TYPE zif_rak_journey=>tt_string.

*   COMPANY. The organisation name in the session language, falling back
*   to the other one - a blank English name with an Arabic name present
*   is a real shape for a local consultancy, and an empty first column
*   reads as a broken row.


*   ADDRESS, GRADE and EMAIL are all read through PICK( ) - see the class
*   header. None of the three is among the four components an existing
*   caller has confirmed, so naming one directly would be a guess with a
*   class-wide syntax error behind it.
*    APPEND pick( is_bp    = is_bp
*                 iv_names = 'ADDRESS,STREET,CITY1,ZZADDRESS,ADDRESS_TEXT' ) TO lt_cell.
*    APPEND pick( is_bp    = is_bp
*                 iv_names = 'GRADE,ZZGRADE,CLASSIFICATION,CATEGORY' ) TO lt_cell.
*    APPEND CONV string( is_bp-partner ) TO lt_cell.
*    APPEND pick( is_bp    = is_bp
*                 iv_names = 'SMTP_ADDR,EMAIL,E_MAIL,EMAILADDRESS,EMAIL_ADDRESS,ZZEMAIL' ) TO lt_cell.


    APPEND CONV string( is_bp-partner ) TO lt_cell.

    DATA(lv_name) = COND string(
      WHEN sy-langu = 'A' AND is_bp-arabic_full_name IS NOT INITIAL
      THEN CONV string( is_bp-arabic_full_name )
      WHEN is_bp-english_full_name IS NOT INITIAL
      THEN CONV string( is_bp-english_full_name )
      ELSE CONV string( is_bp-arabic_full_name ) ).


    APPEND lv_name TO lt_cell.

    DATA(lv_nationality) = is_bp-nationality_desc.
    APPEND lv_nationality TO lt_cell.

    DATA(lv_phone) = is_bp-mobile_number.
    APPEND lv_phone TO lt_cell.


    APPEND lt_cell TO ls_grid-rows.
    io_ctx->set_grid_data( iv_field = c_fld_grid is_data = ls_grid ).



  ENDMETHOD.


  method ALREADY_ADDED.

**   Column 4 is BPID - see the order note in ADD_ROW( ).
*   INTO A VARIABLE FIRST. A functional method call is not reliably
*   accepted as the source of a LOOP AT on this release, and a syntax
*   error in one method takes the WHOLE class down at load - which
*   surfaces at every caller as "Method X is unknown or PROTECTED or
*   PRIVATE" and points nowhere near the cause.
    CHECK iv_bp IS NOT INITIAL.
    DATA(ls_grid) = io_ctx->get_grid_data( c_fld_grid ).
    LOOP AT ls_grid-rows INTO DATA(lt_row).
      READ TABLE lt_row INTO DATA(lv_cell) INDEX 1.
      IF sy-subrc = 0 AND condense( lv_cell ) = condense( iv_bp ).
        rv = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.

  endmethod.


  method PICK.

*   ASSIGN COMPONENT over a candidate list, first non-blank wins. The
*   structure cannot be opened from this repository, so this is how its
*   optional components are read - see the class header.
*
*   ASSIGN COMPONENT, NEVER ASSIGN (name). ZIF_EGA_FW_CJI~MAPPER's
*   assign-by-name is what dumped every DOK journey with
*   MOVE_TO_LIT_NOTALLOWED_NODATA when a technical name resolved to the
*   function module's own IMPORTING parameter. Component assignment
*   cannot reach outside the structure.
    SPLIT iv_names AT ',' INTO TABLE DATA(lt_name).
    LOOP AT lt_name INTO DATA(lv_name).
      ASSIGN COMPONENT condense( to_upper( lv_name ) )
             OF STRUCTURE is_bp TO FIELD-SYMBOL(<val>).
      IF sy-subrc = 0 AND <val> IS NOT INITIAL.
        rv = condense( CONV string( <val> ) ).
        RETURN.
      ENDIF.
    ENDLOOP.

  endmethod.


  METHOD zif_rak_journey_logic~on_search.

    CHECK to_upper( iv_field ) = c_fld_search.

    DATA(lv_term) = condense( io_ctx->get_val( c_fld_search ) ).
    IF lv_term IS INITIAL.
      io_ctx->add_msg( iv_type = 'Warning'
                       iv_text = COND string(
                         WHEN sy-langu = 'A'
                         THEN `يرجى إدخال قيمة للبحث.`
                         ELSE `Enter a value to search for.` ) ).
      RETURN.
    ENDIF.

    DATA ls_req TYPE zcl_rak_bp_search=>ty_req.
    DATA(lv_by) = to_upper( io_ctx->get_val( |{ c_fld_search }_IDTYPE| ) ).

    CASE lv_by.
      WHEN 'YFS002' OR 'PARTNER' OR 'BUSINESS_PARTNER'.
*        ls_req-partner       = lv_term.
        ls_req-idtype = 'EID'.
        ls_req-eid = lv_term.

      WHEN OTHERS.
*       Trade licence is the default because it is the first entry on the
*       live dropdown and the one the walkthrough uses.
        ls_req-trade_licence = lv_term.
    ENDCASE.

    ls_req-no_moi_call = abap_true.

    DATA(ls_res) = NEW zcl_rak_bp_search( )->search( is_req = ls_req ).

*   Every message reaches the citizen, and an error STOPS - an expired
*   licence must not become an added consultant.
****    DATA(lv_err) = abap_false.
****    LOOP AT ls_res-msg INTO DATA(ls_m).
****      io_ctx->add_msg(
****        iv_type = COND #( WHEN ls_m-type = 'E' OR ls_m-type = 'A' THEN 'Error'
****                          WHEN ls_m-type = 'W' THEN 'Warning'
****                          ELSE 'Information' )
****        iv_text = CONV string( ls_m-message ) ).
****      IF ls_m-type = 'E' OR ls_m-type = 'A'.
****        lv_err = abap_true.
****      ENDIF.
****    ENDLOOP.
****    IF lv_err = abap_true.
****      RETURN.
****    ENDIF.


    READ TABLE ls_res-rows INTO DATA(ls_bp) INDEX 1.
    IF sy-subrc <> 0.
      io_ctx->add_msg( iv_type = 'Warning'
                       iv_text = COND string(
                         WHEN sy-langu = 'A'
                         THEN `لم يتم العثور على استشاري بهذه البيانات.`
                         ELSE `No consultant found for that value.` ) ).
      RETURN.
    ENDIF.

    DATA(lv_bp) = CONV string( ls_bp-partner ).
    IF already_added( io_ctx = io_ctx iv_bp = lv_bp ) = abap_true.
      io_ctx->add_msg( iv_type = 'Warning'
                       iv_text = COND string(
                         WHEN sy-langu = 'A'
                         THEN `تمت إضافة الشريك التجاري بالفعل.`
                         ELSE `The Business Partner has already been added.` ) ).
      RETURN.
    ENDIF.

*    bp_rows( io_ctx = io_ctx is_bp = ls_bp ).
    add_row( io_ctx = io_ctx is_bp = ls_bp ).

*   Clear the search box so the next Add starts from an empty field
*   rather than re-adding what is already in the grid on a stray press.
    io_ctx->set_val( iv_name = c_fld_search iv_value = `` ).




  ENDMETHOD.
ENDCLASS.
