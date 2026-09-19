CLASS zcl_ega_mun_cj_odata_api_v3 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_pl_header,
        intreno        TYPE recaintreno,
        plno           TYPE relmplno,
        xpl            TYPE relmxpl,
        xfixfitcharact TYPE rebdxfixfitcharact,
        validfrom      TYPE relmplvalidfrom,
        validto        TYPE relmplvalidto,
      END OF ty_pl_header .
    TYPES:
      tt_pl_header TYPE TABLE OF ty_pl_header WITH DEFAULT KEY .
    TYPES:
      BEGIN OF ty_ao_header,
        intreno      TYPE recaintreno,
        aoid         TYPE rebdaoid,
        xao          TYPE rebdxao,
        bldaoid      TYPE rebdaoid,
        bldxao       TYPE rebdxao,
        flraoid      TYPE rebdaoid,
        flrxao       TYPE rebdxao,
        aonr         TYPE rebdaonr,
        zzold_unnr   TYPE zold_unnr,
        zzfewa_acc   TYPE zzfewa_acc,
        xmaotype     TYPE rebdxmaotype,
        xmaofunction TYPE rebdxmaofunction,
        validfrom    TYPE rebdobjvalidfrom,
        validto      TYPE rebdobjvalidto,
      END OF ty_ao_header .
    TYPES:
      tt_ao_header TYPE TABLE OF ty_ao_header WITH DEFAULT KEY .
    TYPES:
      BEGIN OF ty_location,
        intreno    TYPE recaintreno,
        sector     TYPE rebdlochier,
        sectortext TYPE rebdxlochier,
        area       TYPE rebdlochier,
        areatext   TYPE rebdxlochier,
      END OF ty_location .
    TYPES:
      tt_location TYPE TABLE OF ty_location WITH DEFAULT KEY .
    TYPES:
      BEGIN OF ty_status,
        objnr TYPE recaobjnr,
        txt04 TYPE j_txt04,
        txt30 TYPE j_txt30,
      END OF ty_status .
    TYPES:
      tt_status TYPE TABLE OF ty_status WITH DEFAULT KEY .
    TYPES:
      BEGIN OF ty_partner,
        partner         TYPE bu_partner,
        zzreferencea    TYPE zbu_00q3mwci,
        zzfull_name_eng TYPE zde_full_name_eng,
        role            TYPE rebprole,
        rltitl          TYPE bu_partnerroletitl,
        validfrom       TYPE rebpvalidfrom,
        validto         TYPE rebpvalidto,
      END OF ty_partner .
    TYPES:
      tt_partner TYPE TABLE OF ty_partner WITH DEFAULT KEY .
    TYPES:
      BEGIN OF ty_meas,
        intreno   TYPE recaintreno,
        meas      TYPE rebdmeas,
        xmmeas    TYPE rebdxmmeas,
        measvalue TYPE rebdmeasvalue,
        measunit  TYPE rebdmeasunit,
        validfrom TYPE rebdmeasvalidfrom,
        validto   TYPE rebdmeasvalidto,
      END OF ty_meas .
    TYPES:
      tt_meas TYPE TABLE OF ty_meas WITH DEFAULT KEY .
    TYPES:
      BEGIN OF ty_char,
        intreno        TYPE recaintreno,
        fixfitcharact  TYPE rebdfixfitcharact,
        xfixfitcharact TYPE rebdxfixfitcharact,
        rlragrpchct    TYPE reajrlragrpchct,
        xrlragrpchct   TYPE reajxrlragrpchct,
        validfrom      TYPE rebdvalidfrom,
        validto        TYPE rebdvalidto,
      END OF ty_char .
    TYPES:
      tt_char TYPE TABLE OF ty_char WITH DEFAULT KEY .
    TYPES:
      BEGIN OF ty_asso,
        objnrtrg  TYPE recaobjnr,
        aoid      TYPE rebdaoid,
        xmaotype  TYPE rebdxmaotype,
        xao       TYPE rebdxao,
        validfrom TYPE rebdrelvalidfrom,
        validto   TYPE rebdrelvalidto,
      END OF ty_asso .
    TYPES:
      tt_asso TYPE TABLE OF ty_asso WITH DEFAULT KEY .
    TYPES:
      BEGIN OF ty_draft,
        smenr     TYPE rebdrono,
        sgrnr     TYPE sgrnr,
        xmetxt    TYPE rebdxro,
        intreno   TYPE recaintreno,
        derf      TYPE rebdvalidfrom,
        validto   TYPE rebdvalidto,
        measvalue TYPE rebdmeasvalue,
        txt30     TYPE txt30,
        partner   TYPE bu_partner,
        dbear     TYPE dbear,
      END OF ty_draft .
    TYPES:
      tt_draft TYPE TABLE OF ty_draft WITH DEFAULT KEY .
    TYPES:
      BEGIN OF ty_properties,
        intreno      TYPE recaintreno,
        objnr        TYPE recaobjnr,
        objid        TYPE recabusobjid,
        objtype      TYPE recabusobjtype,
        parentid     TYPE relmplno,
        intreno_p    TYPE recaintreno,
        objnr_p      TYPE recaobjnr,
        partner      TYPE bu_partner,
        role         TYPE rebprole,
        is_mortgaged TYPE boolean,
        is_grant     TYPE boolean,
        granttype    TYPE string,
        validto      TYPE recncnendabs,
        ownershpmthd TYPE string,
        favourite    TYPE boolean,
      END OF ty_properties .
    TYPES:
      tt_properties TYPE TABLE OF ty_properties WITH DEFAULT KEY .
    TYPES:
      BEGIN OF ty_projhead,
        owner   TYPE string,
        ao      TYPE string,
        address TYPE string,
        icon    TYPE string,
      END OF ty_projhead .
    TYPES:
      BEGIN OF ty_project,
        case TYPE TABLE OF scmg_t_case_attr WITH DEFAULT KEY.
        INCLUDE TYPE scmg_t_case_attr.
        INCLUDE TYPE ty_projhead.
    TYPES END OF ty_project .
    TYPES:
      tt_projects TYPE TABLE OF ty_project WITH DEFAULT KEY .

    DATA properties TYPE tt_properties .

    METHODS get_pl_header
      RETURNING
        VALUE(details) TYPE tt_pl_header .
    METHODS get_ao_header
      RETURNING
        VALUE(details) TYPE tt_ao_header .
    METHODS get_location
      RETURNING
        VALUE(details) TYPE tt_location .
    METHODS get_status
      RETURNING
        VALUE(details) TYPE tt_status .
    METHODS get_partners
      IMPORTING
        !intreno       TYPE recaintreno
      RETURNING
        VALUE(details) TYPE tt_partner .
    METHODS get_meas
      IMPORTING
        !intreno       TYPE recaintreno
      RETURNING
        VALUE(details) TYPE tt_meas .
    METHODS get_chars
      IMPORTING
        !intreno       TYPE recaintreno OPTIONAL
      RETURNING
        VALUE(details) TYPE tt_char .
    METHODS get_assobj
      IMPORTING
        !objnr         TYPE recaobjnr
      RETURNING
        VALUE(details) TYPE tt_asso .
    METHODS get_draft
      IMPORTING
        !partner       TYPE bu_partner
      RETURNING
        VALUE(details) TYPE tt_draft .
    METHODS constructor
      IMPORTING
        !partner TYPE bu_partner OPTIONAL
        !role    TYPE rebprole OPTIONAL
        !deed    TYPE relmlrvolumeno OPTIONAL
        !year    TYPE relmlrpageno OPTIONAL .
    CLASS-METHODS get_bp_relationships .
    METHODS get_projects
      EXPORTING
        !projects TYPE tt_projects .
    CLASS-METHODS get_contract
      IMPORTING
        !aoid         TYPE rebdaoid
      RETURNING
        VALUE(status) TYPE abap_boolean .

  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_aokey,
        aoid TYPE rebdaoid,
      END OF ty_aokey .
    TYPES tt_aokey TYPE SORTED TABLE OF ty_aokey WITH UNIQUE KEY aoid .
    TYPES:
      BEGIN OF ty_intkey,
        intreno TYPE recaintreno,
      END OF ty_intkey .
    TYPES tt_intkey TYPE SORTED TABLE OF ty_intkey WITH UNIQUE KEY intreno .
    TYPES:
      BEGIN OF ty_objkey,
        objnr TYPE recaobjnr,
      END OF ty_objkey .
    TYPES tt_objkey TYPE SORTED TABLE OF ty_objkey WITH UNIQUE KEY objnr .
    TYPES:
      BEGIN OF ty_node,
        aoid  TYPE rebdaoid,
        node  TYPE rebdaoid,
        objnr TYPE recaobjnr,
        xao   TYPE rebdxao,
      END OF ty_node .
    TYPES tt_node TYPE SORTED TABLE OF ty_node WITH UNIQUE KEY aoid .

    CLASS-METHODS is_target
      IMPORTING
        !iv_aotype   TYPE clike
        !iv_floor    TYPE abap_bool
      RETURNING
        VALUE(rv_is) TYPE abap_bool .
    CLASS-METHODS resolve_nodes
      IMPORTING
        !it_aoid        TYPE tt_aokey
        !iv_floor       TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(rt_nodes) TYPE tt_node .
    METHODS get_building
      IMPORTING
        !aoid         TYPE rebdaoid
      EXPORTING
        !building     TYPE rebdaoid
        !objnr        TYPE recaobjnr
        !buildingdesc TYPE rebdxao .
    METHODS get_floor
      IMPORTING
        !aoid      TYPE rebdaoid
      EXPORTING
        !floor     TYPE rebdaoid
        !objnr     TYPE recaobjnr
        !floordesc TYPE rebdxao .
ENDCLASS.



CLASS zcl_ega_mun_cj_odata_api_v3 IMPLEMENTATION.


  METHOD is_target.

    IF iv_floor = abap_true.
      IF iv_aotype = '20FL' OR iv_aotype = '20IF'.
        rv_is = abap_true.
      ENDIF.
    ELSE.
      IF iv_aotype = '10IB' OR iv_aotype = '10BU' OR iv_aotype = '10CV'
         OR iv_aotype = '10SF' OR iv_aotype = '10SU' OR iv_aotype = '10SB'
         OR iv_aotype = '10DE'.
        rv_is = abap_true.
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD resolve_nodes.

    TYPES:
      BEGIN OF ty_work,
        aoid    TYPE rebdaoid,
        intreno TYPE recaintreno,
      END OF ty_work.
    TYPES:
      BEGIN OF ty_hit,
        aoid   TYPE rebdaoid,
        parent TYPE recaintreno,
      END OF ty_hit.

    DATA: lt_work  TYPE STANDARD TABLE OF ty_work,
          lt_next  TYPE STANDARD TABLE OF ty_work,
          lt_hit   TYPE STANDARD TABLE OF ty_hit,
          lt_pkey  TYPE tt_intkey,
          lv_depth TYPE i.

    IF it_aoid IS INITIAL.
      RETURN.
    ENDIF.

    SELECT intreno, aoid, aotype, objnr, xao, zzbuild_stat
      FROM vibdao
      FOR ALL ENTRIES IN @it_aoid
      WHERE aoid = @it_aoid-aoid
      INTO TABLE @DATA(lt_ao).

    IF iv_floor = abap_false.
      DELETE lt_ao WHERE zzbuild_stat = '05' OR zzbuild_stat = '06'.
    ENDIF.

    LOOP AT lt_ao INTO DATA(ls_ao).
      IF is_target( iv_aotype = ls_ao-aotype iv_floor = iv_floor ) = abap_true.
        INSERT VALUE #( aoid  = ls_ao-aoid
                        node  = ls_ao-aoid
                        objnr = ls_ao-objnr
                        xao   = ls_ao-xao ) INTO TABLE rt_nodes.
      ELSE.
        APPEND VALUE #( aoid = ls_ao-aoid intreno = ls_ao-intreno ) TO lt_work.
      ENDIF.
    ENDLOOP.

    WHILE lt_work IS NOT INITIAL AND lv_depth < 50.

      lv_depth = lv_depth + 1.
      CLEAR: lt_next, lt_hit, lt_pkey.

      SELECT intreno, parent, aotype_pa
        FROM vibdnode
        FOR ALL ENTRIES IN @lt_work
        WHERE intreno = @lt_work-intreno
        INTO TABLE @DATA(lt_node).

      SORT lt_node BY intreno.

      LOOP AT lt_work INTO DATA(ls_work).
        READ TABLE lt_node INTO DATA(ls_node)
             WITH KEY intreno = ls_work-intreno BINARY SEARCH.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.
        IF is_target( iv_aotype = ls_node-aotype_pa iv_floor = iv_floor ) = abap_true.
          APPEND VALUE #( aoid = ls_work-aoid parent = ls_node-parent ) TO lt_hit.
          INSERT VALUE #( intreno = ls_node-parent ) INTO TABLE lt_pkey.
        ELSEIF ls_node-aotype_pa IS INITIAL.
          CONTINUE.
        ELSE.
          APPEND VALUE #( aoid = ls_work-aoid intreno = ls_node-parent ) TO lt_next.
        ENDIF.
      ENDLOOP.

      IF lt_pkey IS NOT INITIAL.
        SELECT intreno, aoid, objnr, xao
          FROM vibdao
          FOR ALL ENTRIES IN @lt_pkey
          WHERE intreno = @lt_pkey-intreno
          INTO TABLE @DATA(lt_pao).
        SORT lt_pao BY intreno.
        LOOP AT lt_hit INTO DATA(ls_hit).
          READ TABLE lt_pao INTO DATA(ls_pao)
               WITH KEY intreno = ls_hit-parent BINARY SEARCH.
          IF sy-subrc = 0.
            INSERT VALUE #( aoid  = ls_hit-aoid
                            node  = ls_pao-aoid
                            objnr = ls_pao-objnr
                            xao   = ls_pao-xao ) INTO TABLE rt_nodes.
          ENDIF.
        ENDLOOP.
      ENDIF.

      lt_work = lt_next.

    ENDWHILE.

  ENDMETHOD.


  METHOD get_building.

    DATA lt_key TYPE tt_aokey.

    DATA(lv_aoid) = aoid.
    INSERT VALUE #( aoid = lv_aoid ) INTO TABLE lt_key.

    DATA(lt_res) = resolve_nodes( it_aoid = lt_key iv_floor = abap_false ).

    READ TABLE lt_res INTO DATA(ls_res) WITH TABLE KEY aoid = lv_aoid.
    IF sy-subrc = 0.
      building     = ls_res-node.
      objnr        = ls_res-objnr.
      buildingdesc = ls_res-xao.
    ENDIF.

  ENDMETHOD.


  METHOD get_floor.

    DATA lt_key TYPE tt_aokey.

    DATA(lv_aoid) = aoid.
    INSERT VALUE #( aoid = lv_aoid ) INTO TABLE lt_key.

    DATA(lt_res) = resolve_nodes( it_aoid = lt_key iv_floor = abap_true ).

    READ TABLE lt_res INTO DATA(ls_res) WITH TABLE KEY aoid = lv_aoid.
    IF sy-subrc = 0.
      floor     = ls_res-node.
      objnr     = ls_res-objnr.
      floordesc = ls_res-xao.
    ENDIF.

  ENDMETHOD.


  METHOD constructor.

    TYPES:
      BEGIN OF ty_building,
        aoid     TYPE rebdaoid,
        building TYPE rebdaoid,
        objnr_bu TYPE recaobjnr,
      END OF ty_building.
    TYPES:
      BEGIN OF ty_partner_k,
        partner2 TYPE bu_partner,
      END OF ty_partner_k.
    TYPES:
      BEGIN OF ty_aorel,
        intreno   TYPE recaintreno,
        objnr     TYPE recaobjnr,
        aoid      TYPE rebdaoid,
        partner   TYPE bu_partner,
        role      TYPE rebprole,
        validfrom TYPE rebpvalidfrom,
        validto   TYPE rebpvalidto,
      END OF ty_aorel.
    TYPES:
      BEGIN OF ty_plrel,
        intreno   TYPE recaintreno,
        objnr     TYPE recaobjnr,
        plno      TYPE relmplno,
        partner   TYPE bu_partner,
        role      TYPE rebprole,
        validfrom TYPE rebpvalidfrom,
        validto   TYPE rebpvalidto,
      END OF ty_plrel.
    TYPES:
      BEGIN OF ty_parent,
        plno     TYPE relmplno,
        intreno  TYPE recaintreno,
        objnr    TYPE recaobjnr,
        objnrtrg TYPE recaobjnr,
      END OF ty_parent.
    TYPES:
      BEGIN OF ty_lr,
        idx     TYPE i,
        intreno TYPE recaintreno,
        objnr   TYPE recaobjnr,
      END OF ty_lr.
    TYPES:
      BEGIN OF ty_omkey,
        own_mth TYPE zown_mth,
      END OF ty_omkey.
    TYPES:
      BEGIN OF ty_gtkey,
        grt_type TYPE zgrt_type,
      END OF ty_gtkey.

    DATA: ls_property TYPE ty_properties,
          lt_partner  TYPE STANDARD TABLE OF ty_partner_k,
          lt_ao       TYPE STANDARD TABLE OF ty_aorel,
          lt_parcel   TYPE STANDARD TABLE OF ty_plrel,
          lt_building TYPE STANDARD TABLE OF ty_building
                           WITH NON-UNIQUE SORTED KEY k_aoid COMPONENTS aoid,
          lt_parent   TYPE STANDARD TABLE OF ty_parent
                           WITH NON-UNIQUE SORTED KEY k_trg COMPONENTS objnrtrg,
          lt_aokey    TYPE tt_aokey,
          lt_bad      TYPE tt_intkey,
          lt_keep     TYPE tt_properties,
          lt_lr       TYPE STANDARD TABLE OF ty_lr,
          lt_lrkey    TYPE tt_objkey,
          lt_gobj     TYPE tt_objkey,
          lt_gint     TYPE tt_intkey,
          lt_mkey     TYPE tt_objkey,
          lv_parcel   TYPE relmplno,
          lv_aoid     TYPE rebdaoid,
          lv_count    TYPE i,
          lv_objnr_lr TYPE recaobjnr,
          lv_ownmthd  TYPE zown_mth.

    IF ( partner IS INITIAL AND deed IS INITIAL AND year IS INITIAL ).
      RETURN.
    ENDIF.

    IF deed IS NOT INITIAL.

      SELECT SINGLE intreno, objnr
        FROM vilmlr
        WHERE lrvolumeno = @deed AND lrpageno = @year
        INTO @DATA(ls_lr).

      SELECT SINGLE plobjnr
        FROM vilmrg
        WHERE intreno = @ls_lr-intreno
        INTO @DATA(lv_plobjnr).

      IF lv_plobjnr IS NOT INITIAL.
        SELECT SINGLE objnrtrg
          FROM zdt_refx_objas
          WHERE objnrsrc = @ls_lr-objnr
          INTO @DATA(lv_aoobjnr).
        IF sy-subrc <> 0.
          RETURN.
        ENDIF.
      ENDIF.

      IF lv_aoobjnr IS NOT INITIAL.

        SELECT a~intreno, a~objnr, a~aoid, b~partner, b~role, b~validfrom, b~validto
          FROM vibdao AS a
          INNER JOIN vibpobjrel AS b ON a~intreno = b~intreno
          WHERE a~objnr = @lv_aoobjnr
            AND b~validfrom <= @sy-datum AND b~validto >= @sy-datum
          INTO TABLE @lt_ao.
        IF sy-subrc <> 0.
          RETURN.
        ENDIF.

        CLEAR lt_aokey.
        LOOP AT lt_ao ASSIGNING FIELD-SYMBOL(<fs_ao>).
          INSERT VALUE #( aoid = <fs_ao>-aoid ) INTO TABLE lt_aokey.
        ENDLOOP.

        DATA(lt_bld) = resolve_nodes( it_aoid = lt_aokey iv_floor = abap_false ).

        LOOP AT lt_ao ASSIGNING <fs_ao>.
          READ TABLE lt_bld INTO DATA(ls_bld) WITH TABLE KEY aoid = <fs_ao>-aoid.
          IF sy-subrc = 0.
            APPEND VALUE #( aoid     = <fs_ao>-aoid
                            building = ls_bld-node
                            objnr_bu = ls_bld-objnr ) TO lt_building.
          ELSE.
            APPEND VALUE #( aoid = <fs_ao>-aoid ) TO lt_building.
          ENDIF.
        ENDLOOP.

        IF lt_building IS NOT INITIAL.
          SELECT a~plno, a~intreno, a~objnr, b~objnrtrg
            FROM vilmpl AS a
            INNER JOIN vibdobjass AS b ON a~objnr = b~objnrsrc
              AND b~objasstype = '20'
              AND b~validfrom <= @sy-datum AND b~validto >= @sy-datum
            FOR ALL ENTRIES IN @lt_building
            WHERE b~objnrtrg = @lt_building-objnr_bu
            INTO TABLE @lt_parent.
        ENDIF.

      ENDIF.

      IF lv_plobjnr IS NOT INITIAL.
        SELECT a~intreno, a~objnr, a~plno, b~partner, b~role, b~validfrom, b~validto
          FROM vilmpl AS a
          INNER JOIN vibpobjrel AS b ON a~intreno = b~intreno
          INNER JOIN jest AS c ON a~objnr = c~objnr
          WHERE a~objnr = @lv_plobjnr
            AND b~validfrom <= @sy-datum AND b~validto >= @sy-datum
            AND c~stat IN ( 'E0011' , 'E0012' , 'E0013' )
          INTO TABLE @lt_parcel.
        IF sy-subrc <> 0.
          RETURN.
        ENDIF.
      ENDIF.

      LOOP AT lt_parcel ASSIGNING FIELD-SYMBOL(<fs_pl>).
        CLEAR ls_property.
        ls_property-intreno   = <fs_pl>-intreno.
        ls_property-intreno_p = <fs_pl>-intreno.
        ls_property-objnr     = <fs_pl>-objnr.
        ls_property-objnr_p   = <fs_pl>-objnr.
        ls_property-objid     = <fs_pl>-plno.
        ls_property-objtype   = 'I8'.
        ls_property-parentid  = <fs_pl>-plno.
        ls_property-partner   = <fs_pl>-partner.
        ls_property-role      = <fs_pl>-role.
        APPEND ls_property TO properties.
      ENDLOOP.

      LOOP AT lt_ao ASSIGNING <fs_ao>.
        READ TABLE lt_building ASSIGNING FIELD-SYMBOL(<fs_building>)
             WITH KEY k_aoid COMPONENTS aoid = <fs_ao>-aoid.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.
        READ TABLE lt_parent ASSIGNING FIELD-SYMBOL(<fs_parent>)
             WITH KEY k_trg COMPONENTS objnrtrg = <fs_building>-objnr_bu.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.
        CLEAR ls_property.
        ls_property-intreno   = <fs_ao>-intreno.
        ls_property-intreno_p = <fs_parent>-intreno.
        ls_property-objnr     = <fs_ao>-objnr.
        ls_property-objnr_p   = <fs_parent>-objnr.
        ls_property-objid     = <fs_ao>-aoid.
        ls_property-objtype   = 'I0'.
        ls_property-parentid  = <fs_parent>-plno.
        ls_property-partner   = <fs_ao>-partner.
        ls_property-role      = <fs_ao>-role.
        APPEND ls_property TO properties.
      ENDLOOP.

      IF line_exists( properties[ role = 'TR0800' ] ).

        SELECT SINGLE COUNT( * )
          FROM jest
          WHERE objnr = @ls_lr-objnr AND inact = @space
            AND stat IN ( 'E0003' , 'E0004' )
          INTO @lv_count.

        IF lv_count <> 2.
          CLEAR lt_bad.
          LOOP AT properties ASSIGNING FIELD-SYMBOL(<fs_property>) WHERE role = 'TR0800'.
            INSERT VALUE #( intreno = <fs_property>-intreno ) INTO TABLE lt_bad.
          ENDLOOP.
          CLEAR lt_keep.
          LOOP AT properties ASSIGNING <fs_property>.
            IF NOT line_exists( lt_bad[ intreno = <fs_property>-intreno ] ).
              APPEND <fs_property> TO lt_keep.
            ENDIF.
          ENDLOOP.
          properties = lt_keep.
        ELSE.
          SELECT SINGLE zzown_mth
            FROM vilmlr
            WHERE objnr = @ls_lr-objnr
            INTO @lv_ownmthd.
          SELECT SINGLE description
            FROM zdt_refx_ownmtt
            WHERE own_mth = @lv_ownmthd AND spras = @sy-langu
            INTO @DATA(lv_owndesc).
          IF sy-subrc = 0.
            LOOP AT properties ASSIGNING <fs_property> WHERE role = 'TR0800'.
              <fs_property>-ownershpmthd = lv_owndesc.
            ENDLOOP.
          ENDIF.
        ENDIF.

      ENDIF.

    ELSE.

      APPEND VALUE #( partner2 = partner ) TO lt_partner.

      IF role IS INITIAL.
        SELECT a~intreno, a~objnr, a~aoid, b~partner, b~role, b~validfrom, b~validto
          FROM vibdao AS a
          INNER JOIN vibpobjrel AS b ON a~intreno = b~intreno
          FOR ALL ENTRIES IN @lt_partner
          WHERE b~partner = @lt_partner-partner2
            AND b~role IN ( 'TR0800' , 'ZTR080' )
            AND b~validfrom <= @sy-datum AND b~validto >= @sy-datum
          INTO TABLE @lt_ao.
      ELSE.
        SELECT a~intreno, a~objnr, a~aoid, b~partner, b~role, b~validfrom, b~validto
          FROM vibdao AS a
          INNER JOIN vibpobjrel AS b ON a~intreno = b~intreno
          FOR ALL ENTRIES IN @lt_partner
          WHERE b~partner = @lt_partner-partner2
            AND b~role = @role
            AND b~validfrom <= @sy-datum AND b~validto >= @sy-datum
          INTO TABLE @lt_ao.
      ENDIF.

      CLEAR lt_aokey.
      LOOP AT lt_ao ASSIGNING <fs_ao>.
        INSERT VALUE #( aoid = <fs_ao>-aoid ) INTO TABLE lt_aokey.
      ENDLOOP.

      DATA(lt_bld2) = resolve_nodes( it_aoid = lt_aokey iv_floor = abap_false ).

      LOOP AT lt_ao ASSIGNING <fs_ao>.
        READ TABLE lt_bld2 INTO DATA(ls_bld2) WITH TABLE KEY aoid = <fs_ao>-aoid.
        IF sy-subrc = 0.
          APPEND VALUE #( aoid     = <fs_ao>-aoid
                          building = ls_bld2-node
                          objnr_bu = ls_bld2-objnr ) TO lt_building.
        ELSE.
          APPEND VALUE #( aoid = <fs_ao>-aoid ) TO lt_building.
        ENDIF.
      ENDLOOP.

      IF role IS INITIAL.
        SELECT a~intreno, a~objnr, a~plno, b~partner, b~role, b~validfrom, b~validto
          FROM vilmpl AS a
          INNER JOIN vibpobjrel AS b ON a~intreno = b~intreno
          INNER JOIN jest AS c ON a~objnr = c~objnr
          FOR ALL ENTRIES IN @lt_partner
          WHERE b~partner = @lt_partner-partner2
            AND b~role IN ( 'TR0800' , 'ZTR080' )
            AND b~validfrom <= @sy-datum AND b~validto >= @sy-datum
            AND c~stat IN ( 'E0011' , 'E0012' , 'E0013' )
          INTO TABLE @lt_parcel.
      ELSE.
        SELECT a~intreno, a~objnr, a~plno, b~partner, b~role, b~validfrom, b~validto
          FROM vilmpl AS a
          INNER JOIN vibpobjrel AS b ON a~intreno = b~intreno
          INNER JOIN jest AS c ON a~objnr = c~objnr
          FOR ALL ENTRIES IN @lt_partner
          WHERE b~partner = @lt_partner-partner2
            AND b~role = @role
            AND b~validfrom <= @sy-datum AND b~validto >= @sy-datum
            AND c~stat IN ( 'E0011' , 'E0012' , 'E0013' )
          INTO TABLE @lt_parcel.
      ENDIF.

      IF lt_building IS NOT INITIAL.
        SELECT a~plno, a~intreno, a~objnr, b~objnrtrg
          FROM vilmpl AS a
          INNER JOIN vibdobjass AS b ON a~objnr = b~objnrsrc
            AND b~objasstype = '20'
            AND b~validfrom <= @sy-datum AND b~validto >= @sy-datum
          FOR ALL ENTRIES IN @lt_building
          WHERE b~objnrtrg = @lt_building-objnr_bu
          INTO TABLE @lt_parent.
      ENDIF.

      LOOP AT lt_parcel ASSIGNING <fs_pl>.
        CLEAR ls_property.
        ls_property-intreno   = <fs_pl>-intreno.
        ls_property-intreno_p = <fs_pl>-intreno.
        ls_property-objnr     = <fs_pl>-objnr.
        ls_property-objnr_p   = <fs_pl>-objnr.
        ls_property-objid     = <fs_pl>-plno.
        ls_property-objtype   = 'I8'.
        ls_property-parentid  = <fs_pl>-plno.
        ls_property-partner   = <fs_pl>-partner.
        ls_property-role      = <fs_pl>-role.
        APPEND ls_property TO properties.
      ENDLOOP.

      LOOP AT lt_ao ASSIGNING <fs_ao>.
        READ TABLE lt_building ASSIGNING <fs_building>
             WITH KEY k_aoid COMPONENTS aoid = <fs_ao>-aoid.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.
        READ TABLE lt_parent ASSIGNING <fs_parent>
             WITH KEY k_trg COMPONENTS objnrtrg = <fs_building>-objnr_bu.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.
        CLEAR ls_property.
        ls_property-intreno   = <fs_ao>-intreno.
        ls_property-intreno_p = <fs_parent>-intreno.
        ls_property-objnr     = <fs_ao>-objnr.
        ls_property-objnr_p   = <fs_parent>-objnr.
        ls_property-objid     = <fs_ao>-aoid.
        ls_property-objtype   = 'I0'.
        ls_property-parentid  = <fs_parent>-plno.
        ls_property-partner   = <fs_ao>-partner.
        ls_property-role      = <fs_ao>-role.
        APPEND ls_property TO properties.
      ENDLOOP.

      CLEAR: lt_lr, lt_lrkey.
      LOOP AT properties ASSIGNING <fs_property> WHERE role = 'TR0800'.
        lv_parcel = COND #( WHEN <fs_property>-objtype = 'I8' THEN <fs_property>-objid ).
        lv_aoid   = COND #( WHEN <fs_property>-objtype = 'I0' THEN <fs_property>-objid ).
        CLEAR lv_objnr_lr.
        zcl_ega_cs_re_pl_abs=>get_landreg(
          EXPORTING
            iv_parcel = lv_parcel
            iv_aoid   = lv_aoid
          IMPORTING
            ev_lrno   = lv_objnr_lr ).
        APPEND VALUE #( idx     = sy-tabix
                        intreno = <fs_property>-intreno
                        objnr   = lv_objnr_lr ) TO lt_lr.
        INSERT VALUE #( objnr = lv_objnr_lr ) INTO TABLE lt_lrkey.
      ENDLOOP.

      IF lt_lrkey IS NOT INITIAL.

        SELECT objnr, stat
          FROM jest
          FOR ALL ENTRIES IN @lt_lrkey
          WHERE objnr = @lt_lrkey-objnr AND inact = @space
            AND stat IN ( 'E0003' , 'E0004' )
          INTO TABLE @DATA(lt_jest).
        SORT lt_jest BY objnr.

        SELECT objnr, zzown_mth
          FROM vilmlr
          FOR ALL ENTRIES IN @lt_lrkey
          WHERE objnr = @lt_lrkey-objnr
          INTO TABLE @DATA(lt_lrown).
        SORT lt_lrown BY objnr.

        DATA lt_omkey TYPE SORTED TABLE OF ty_omkey WITH UNIQUE KEY own_mth.
        CLEAR lt_omkey.
        LOOP AT lt_lrown INTO DATA(ls_lrown).
          INSERT VALUE #( own_mth = ls_lrown-zzown_mth ) INTO TABLE lt_omkey.
        ENDLOOP.

        IF lt_omkey IS NOT INITIAL.
          SELECT own_mth, description
            FROM zdt_refx_ownmtt
            FOR ALL ENTRIES IN @lt_omkey
            WHERE own_mth = @lt_omkey-own_mth AND spras = @sy-langu
            INTO TABLE @DATA(lt_omt).
          SORT lt_omt BY own_mth.
        ENDIF.

        CLEAR lt_bad.
        LOOP AT lt_lr INTO DATA(ls_lr2).
          lv_count = 0.
          LOOP AT lt_jest TRANSPORTING NO FIELDS WHERE objnr = ls_lr2-objnr.
            lv_count = lv_count + 1.
          ENDLOOP.
          IF lv_count <> 2.
            INSERT VALUE #( intreno = ls_lr2-intreno ) INTO TABLE lt_bad.
            CONTINUE.
          ENDIF.
          READ TABLE properties ASSIGNING <fs_property> INDEX ls_lr2-idx.
          IF sy-subrc <> 0.
            CONTINUE.
          ENDIF.
          READ TABLE lt_lrown INTO ls_lrown WITH KEY objnr = ls_lr2-objnr BINARY SEARCH.
          IF sy-subrc <> 0.
            CONTINUE.
          ENDIF.
          READ TABLE lt_omt INTO DATA(ls_omt)
               WITH KEY own_mth = ls_lrown-zzown_mth BINARY SEARCH.
          IF sy-subrc = 0.
            <fs_property>-ownershpmthd = ls_omt-description.
          ENDIF.
        ENDLOOP.

        IF lt_bad IS NOT INITIAL.
          CLEAR lt_keep.
          LOOP AT properties ASSIGNING <fs_property>.
            IF NOT line_exists( lt_bad[ intreno = <fs_property>-intreno ] ).
              APPEND <fs_property> TO lt_keep.
            ENDIF.
          ENDLOOP.
          properties = lt_keep.
        ENDIF.

      ENDIF.

      CLEAR: lt_gobj, lt_gint.
      LOOP AT properties ASSIGNING FIELD-SYMBOL(<fs_properties>) WHERE role = 'ZTR080'.
        INSERT VALUE #( objnr = <fs_properties>-objnr ) INTO TABLE lt_gobj.
        INSERT VALUE #( intreno = <fs_properties>-intreno ) INTO TABLE lt_gint.
      ENDLOOP.

      IF lt_gobj IS NOT INITIAL.

        SELECT b~objnrtrg, a~recnendabs
          FROM vicncn AS a
          INNER JOIN vibdobjass AS b ON a~objnr = b~objnrsrc
          INNER JOIN vibpobjrel AS c ON a~intreno = c~intreno
          FOR ALL ENTRIES IN @lt_gobj
          WHERE b~objnrtrg = @lt_gobj-objnr
            AND a~recntype = 'GR01' AND b~objasstype = '10'
            AND c~role = 'ZTR080' AND c~partner = @partner
            AND c~appl = '0036'
            AND c~validfrom <= @sy-datum AND c~validto >= @sy-datum
            AND a~recnendabs >= @sy-datum
          INTO TABLE @DATA(lt_grant).
        SORT lt_grant BY objnrtrg.

        SELECT intreno, zzgrt_type
          FROM vilmpl
          FOR ALL ENTRIES IN @lt_gint
          WHERE intreno = @lt_gint-intreno
          INTO TABLE @DATA(lt_gtype).
        SORT lt_gtype BY intreno.

        DATA lt_gtkey TYPE SORTED TABLE OF ty_gtkey WITH UNIQUE KEY grt_type.
        CLEAR lt_gtkey.
        LOOP AT lt_gtype INTO DATA(ls_gtype).
          INSERT VALUE #( grt_type = ls_gtype-zzgrt_type ) INTO TABLE lt_gtkey.
        ENDLOOP.

        IF lt_gtkey IS NOT INITIAL.
          SELECT grt_type, description
            FROM zdt_refx_grttyt
            FOR ALL ENTRIES IN @lt_gtkey
            WHERE grt_type = @lt_gtkey-grt_type AND spars = @sy-langu
            INTO TABLE @DATA(lt_gtt).
          SORT lt_gtt BY grt_type.
        ENDIF.

        CLEAR lt_bad.
        LOOP AT properties ASSIGNING <fs_properties> WHERE role = 'ZTR080'.
          READ TABLE lt_grant INTO DATA(ls_grant)
               WITH KEY objnrtrg = <fs_properties>-objnr BINARY SEARCH.
          IF sy-subrc <> 0.
            INSERT VALUE #( intreno = <fs_properties>-intreno ) INTO TABLE lt_bad.
            CONTINUE.
          ENDIF.
          <fs_properties>-is_grant = abap_true.
          <fs_properties>-validto  = ls_grant-recnendabs.
          READ TABLE lt_gtype INTO ls_gtype
               WITH KEY intreno = <fs_properties>-intreno BINARY SEARCH.
          IF sy-subrc <> 0.
            CONTINUE.
          ENDIF.
          READ TABLE lt_gtt INTO DATA(ls_gtt)
               WITH KEY grt_type = ls_gtype-zzgrt_type BINARY SEARCH.
          IF sy-subrc = 0.
            <fs_properties>-granttype = ls_gtt-description.
          ENDIF.
        ENDLOOP.

        IF lt_bad IS NOT INITIAL.
          CLEAR lt_keep.
          LOOP AT properties ASSIGNING <fs_properties>.
            IF NOT line_exists( lt_bad[ intreno = <fs_properties>-intreno ] ).
              APPEND <fs_properties> TO lt_keep.
            ENDIF.
          ENDLOOP.
          properties = lt_keep.
        ENDIF.

      ENDIF.

      IF properties IS NOT INITIAL.

        CLEAR lt_mkey.
        LOOP AT properties ASSIGNING <fs_properties>.
          INSERT VALUE #( objnr = <fs_properties>-objnr ) INTO TABLE lt_mkey.
        ENDLOOP.

        SELECT c~objnrtrg
          FROM vicncn AS a
          INNER JOIN jest AS b ON a~objnr = b~objnr
          INNER JOIN vibdobjass AS c ON a~objnr = c~objnrsrc
          FOR ALL ENTRIES IN @lt_mkey
          WHERE c~objnrtrg = @lt_mkey-objnr
            AND b~stat = 'E0006' AND a~recntype = 'L001'
          INTO TABLE @DATA(lt_mortgage).

        IF lt_mortgage IS NOT INITIAL.
          SORT lt_mortgage BY objnrtrg.
          LOOP AT properties ASSIGNING <fs_properties>.
            READ TABLE lt_mortgage TRANSPORTING NO FIELDS
                 WITH KEY objnrtrg = <fs_properties>-objnr BINARY SEARCH.
            IF sy-subrc = 0.
              <fs_properties>-is_mortgaged = abap_true.
            ENDIF.
          ENDLOOP.
        ENDIF.

      ENDIF.

    ENDIF.

  ENDMETHOD.


  METHOD get_ao_header.

    DATA lt_ikey TYPE tt_intkey.
    DATA lt_akey TYPE tt_aokey.

    IF properties IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT properties ASSIGNING FIELD-SYMBOL(<fs_p>).
      INSERT VALUE #( intreno = <fs_p>-intreno ) INTO TABLE lt_ikey.
    ENDLOOP.

    SELECT a~intreno, a~aoid, a~xao, a~validfrom, a~validto,
           b~xmaotype, c~xmaofunction,
           a~aonr, a~zzold_unnr, a~zzfewa_acc
      FROM vibdao AS a
      INNER JOIN tivbdarobjtypet AS b ON a~aotype = b~aotype AND b~spras = @sy-langu
      INNER JOIN tivbdarfunct AS c ON a~aofunction = c~aofunction
                                  AND a~aotype = c~aotype AND c~spras = @sy-langu
      FOR ALL ENTRIES IN @lt_ikey
      WHERE a~intreno = @lt_ikey-intreno
      INTO CORRESPONDING FIELDS OF TABLE @details.

    IF details IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT details ASSIGNING FIELD-SYMBOL(<fs_detail>).
      INSERT VALUE #( aoid = <fs_detail>-aoid ) INTO TABLE lt_akey.
    ENDLOOP.

    DATA(lt_bld) = resolve_nodes( it_aoid = lt_akey iv_floor = abap_false ).
    DATA(lt_flr) = resolve_nodes( it_aoid = lt_akey iv_floor = abap_true ).

    LOOP AT details ASSIGNING <fs_detail>.
      READ TABLE lt_bld INTO DATA(ls_bld) WITH TABLE KEY aoid = <fs_detail>-aoid.
      IF sy-subrc = 0.
        <fs_detail>-bldaoid = ls_bld-node.
      ENDIF.
      READ TABLE lt_flr INTO DATA(ls_flr) WITH TABLE KEY aoid = <fs_detail>-aoid.
      IF sy-subrc = 0.
        <fs_detail>-flraoid = ls_flr-node.
        <fs_detail>-flrxao  = ls_flr-xao.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_assobj.

    SELECT a~objnrtrg, a~validfrom, a~validto, b~aoid, b~xao, c~xmaotype
      FROM vibdobjass AS a
      INNER JOIN vibdao AS b ON a~objnrtrg = b~objnr
      INNER JOIN tivbdarobjtypet AS c ON b~aotype = c~aotype AND c~spras = @sy-langu
      WHERE a~objnrsrc = @objnr
        AND a~validfrom <= @sy-datum AND a~validto >= @sy-datum
      INTO CORRESPONDING FIELDS OF TABLE @details.

  ENDMETHOD.


  METHOD get_bp_relationships.
  ENDMETHOD.


  METHOD get_chars.

    DATA lt_ikey TYPE tt_intkey.

    IF intreno IS INITIAL.

      IF properties IS INITIAL.
        RETURN.
      ENDIF.

      LOOP AT properties ASSIGNING FIELD-SYMBOL(<fs_p>).
        INSERT VALUE #( intreno = <fs_p>-intreno_p ) INTO TABLE lt_ikey.
      ENDLOOP.

      SELECT a~intreno, a~fixfitcharact, a~validfrom, a~validto,
             b~xfixfitcharact, c~rlragrpchct, d~xrlragrpchct
        FROM vibdcharact AS a
        INNER JOIN tivbdcharactt AS b ON a~fixfitcharact = b~fixfitcharact
                                     AND b~spras = @sy-langu
        INNER JOIN tivajrlrasrch AS c ON a~fixfitcharact = c~fixfitcharact
        INNER JOIN tivajchctgroupt AS d ON c~rlragrpchct = d~rlragrpchct
                                       AND d~spras = @sy-langu
        FOR ALL ENTRIES IN @lt_ikey
        WHERE a~intreno = @lt_ikey-intreno
          AND a~fixfitcharact IN ( 'L300' , 'L301' , 'L302' , 'L303' , 'L304' ,
                                   'L305' , 'L306' , 'L307' , 'L308' , 'L309' , 'L310' )
          AND a~validfrom <= @sy-datum
          AND a~validto >= @sy-datum
        INTO CORRESPONDING FIELDS OF TABLE @details.

    ELSE.

      SELECT a~intreno, a~fixfitcharact, a~validfrom, a~validto,
             b~xfixfitcharact, c~rlragrpchct, d~xrlragrpchct
        FROM vibdcharact AS a
        INNER JOIN tivbdcharactt AS b ON a~fixfitcharact = b~fixfitcharact
                                     AND b~spras = @sy-langu
        INNER JOIN tivajrlrasrch AS c ON a~fixfitcharact = c~fixfitcharact
        INNER JOIN tivajchctgroupt AS d ON c~rlragrpchct = d~rlragrpchct
                                       AND d~spras = @sy-langu
        WHERE a~intreno = @intreno
          AND a~fixfitcharact IN ( 'L300' , 'L301' , 'L302' , 'L303' , 'L304' ,
                                   'L305' , 'L306' , 'L307' , 'L308' , 'L309' , 'L310' )
          AND a~validfrom <= @sy-datum
          AND a~validto >= @sy-datum
        INTO CORRESPONDING FIELDS OF TABLE @details.

    ENDIF.

  ENDMETHOD.


  METHOD get_contract.

    SELECT SINGLE COUNT( * )
      FROM vibdao
      INNER JOIN vibpobjrel ON vibdao~intreno = vibpobjrel~intreno
      WHERE vibdao~aoid = @aoid AND vibpobjrel~role = 'ZLESEE'
        AND vibpobjrel~validfrom <= @sy-datum
        AND vibpobjrel~validto >= @sy-datum
      INTO @DATA(lv_cnt).

    IF sy-subrc = 0.
      status = 'X'.
    ENDIF.

  ENDMETHOD.


  METHOD get_draft.

    DATA: draftdate TYPE dats.

    draftdate = sy-datum - 30.

    SELECT b~smenr, b~sgrnr, b~intreno, b~xmetxt, b~derf, b~dbear, b~validto
      FROM vibdro AS b
      INNER JOIN jest AS c ON b~objnr = c~objnr AND c~inact = @space
                          AND c~stat IN ( 'E0005' , 'E0002' , 'E0012' )
      INNER JOIN vibdcharact AS d ON b~intreno = d~intreno
      WHERE b~swenr = 'CJMUN'
        AND d~fixfitcharact IN ( 'CJ03' , 'CJ04' )
        AND d~supplementinfo = @partner
        AND b~derf >= @draftdate
      INTO CORRESPONDING FIELDS OF TABLE @details.

    IF details IS INITIAL.
      RETURN.
    ENDIF.

    DATA lt_ikey TYPE tt_intkey.
    LOOP AT details ASSIGNING FIELD-SYMBOL(<fs_d>).
      INSERT VALUE #( intreno = <fs_d>-intreno ) INTO TABLE lt_ikey.
    ENDLOOP.

    SELECT intreno
      FROM vibdcharact
      FOR ALL ENTRIES IN @lt_ikey
      WHERE intreno = @lt_ikey-intreno
        AND fixfitcharact = 'CJ12'
        AND supplementinfo <> @space
      INTO TABLE @DATA(lt_cases).

    IF lt_cases IS NOT INITIAL.
      DATA lt_ckey TYPE tt_intkey.
      LOOP AT lt_cases INTO DATA(ls_case).
        INSERT VALUE #( intreno = ls_case-intreno ) INTO TABLE lt_ckey.
      ENDLOOP.
      DATA lt_keep TYPE tt_draft.
      LOOP AT details ASSIGNING <fs_d>.
        IF NOT line_exists( lt_ckey[ intreno = <fs_d>-intreno ] ).
          APPEND <fs_d> TO lt_keep.
        ENDIF.
      ENDLOOP.
      details = lt_keep.
    ENDIF.

    SORT details BY intreno ASCENDING.
    DELETE ADJACENT DUPLICATES FROM details.

  ENDMETHOD.


  METHOD get_location.

    DATA ls_details TYPE LINE OF tt_location.
    DATA lt_ikey TYPE tt_intkey.

    IF properties IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT properties ASSIGNING FIELD-SYMBOL(<fs_p>).
      INSERT VALUE #( intreno = <fs_p>-intreno_p ) INTO TABLE lt_ikey.
    ENDLOOP.

    SELECT intreno, lochier
      FROM vibdlochier
      FOR ALL ENTRIES IN @lt_ikey
      WHERE intreno = @lt_ikey-intreno
      INTO TABLE @DATA(lt_lochier).

    IF lt_lochier IS INITIAL.
      RETURN.
    ENDIF.

    SELECT lochier, xlochier, locitem01
      FROM tivbdlochier
      FOR ALL ENTRIES IN @lt_lochier
      WHERE lochier = @lt_lochier-lochier
      INTO TABLE @DATA(lt_area).

    SORT lt_area BY lochier.

    LOOP AT lt_lochier ASSIGNING FIELD-SYMBOL(<fs_lochier>).
      CLEAR ls_details.
      ls_details-intreno = <fs_lochier>-intreno.
      ls_details-area    = <fs_lochier>-lochier.
      READ TABLE lt_area ASSIGNING FIELD-SYMBOL(<fs_area>)
           WITH KEY lochier = <fs_lochier>-lochier BINARY SEARCH.
      IF sy-subrc = 0.
        ls_details-areatext   = <fs_area>-xlochier.
        ls_details-sector     = <fs_area>-locitem01.
        ls_details-sectortext = <fs_area>-xlochier.
      ENDIF.
      APPEND ls_details TO details.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_meas.

    SELECT a~intreno, a~meas, a~measvalue, a~measunit, a~validfrom, a~validto, b~xmmeas
      FROM vibdmeas AS a
      INNER JOIN tivbdmeast AS b ON a~meas = b~meas AND b~spras = @sy-langu
      WHERE a~intreno = @intreno
      INTO CORRESPONDING FIELDS OF TABLE @details.

  ENDMETHOD.


  METHOD get_partners.

    SELECT a~partner, a~role, a~validfrom, a~validto,
           b~zzreferencea, b~zzfull_name_eng, c~rltitl
      FROM vibpobjrel AS a
      INNER JOIN but000 AS b ON a~partner = b~partner
      INNER JOIN tb003t AS c ON a~role = c~role AND c~spras = @sy-langu
      WHERE a~intreno = @intreno
        AND c~role IN ( 'TR0800' , 'TR0823' , 'ZLESEE' , 'ZLESOR' )
        AND a~validfrom <= @sy-datum AND a~validto >= @sy-datum
      INTO CORRESPONDING FIELDS OF TABLE @details.

  ENDMETHOD.


  METHOD get_pl_header.

    DATA lt_ikey TYPE tt_intkey.

    IF properties IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT properties ASSIGNING FIELD-SYMBOL(<fs_p>).
      INSERT VALUE #( intreno = <fs_p>-intreno ) INTO TABLE lt_ikey.
    ENDLOOP.

    SELECT intreno, plno, xpl, validfrom, validto
      FROM vilmpl
      FOR ALL ENTRIES IN @lt_ikey
      WHERE intreno = @lt_ikey-intreno
      INTO CORRESPONDING FIELDS OF TABLE @details.

    IF details IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lt_char) = get_chars( ).

    DATA lt_usage TYPE SORTED TABLE OF ty_char
                       WITH NON-UNIQUE KEY intreno rlragrpchct.
    LOOP AT lt_char INTO DATA(ls_char) WHERE rlragrpchct = 'USAGE'.
      INSERT ls_char INTO TABLE lt_usage.
    ENDLOOP.

    LOOP AT details ASSIGNING FIELD-SYMBOL(<fs_properties>).
      READ TABLE lt_usage INTO ls_char
           WITH KEY intreno = <fs_properties>-intreno rlragrpchct = 'USAGE'.
      IF sy-subrc = 0.
        <fs_properties>-xfixfitcharact = ls_char-xfixfitcharact.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_projects.

    DATA: objid TYPE RANGE OF zde_ega_object_id,
          const TYPE char36 VALUE '                                    '.
    DATA lt_ikey TYPE tt_intkey.

    IF properties IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT properties ASSIGNING FIELD-SYMBOL(<fs_p>).
      INSERT VALUE #( intreno = <fs_p>-intreno ) INTO TABLE lt_ikey.
    ENDLOOP.

    SELECT plno
      FROM vilmpl
      FOR ALL ENTRIES IN @lt_ikey
      WHERE intreno = @lt_ikey-intreno
      INTO TABLE @DATA(parcel).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    SORT parcel ASCENDING BY plno.
    DELETE ADJACENT DUPLICATES FROM parcel COMPARING plno.

    LOOP AT parcel ASSIGNING FIELD-SYMBOL(<fs_parcel>).
      CONCATENATE '&!' <fs_parcel>-plno INTO DATA(lv_string) SEPARATED BY const.
      APPEND VALUE #( sign = 'I' option = 'EQ' low = lv_string ) TO objid.
    ENDLOOP.

    IF objid IS INITIAL.
      RETURN.
    ENDIF.

    SELECT case_guid, bo_id
      FROM zdt_ega_cs_2_bo
      WHERE bo_id IN @objid AND case_type = 'ZP00'
      INTO TABLE @DATA(lt_bo).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    SORT lt_bo ASCENDING BY case_guid.
    DELETE ADJACENT DUPLICATES FROM lt_bo COMPARING case_guid.

    IF lt_bo IS NOT INITIAL.
      SELECT *
        FROM scmg_t_case_attr
        FOR ALL ENTRIES IN @lt_bo
        WHERE case_guid = @lt_bo-case_guid
          AND stat_orderno IN ( '10' , '20' )
        INTO TABLE @DATA(lt_project).
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
    ENDIF.

    MOVE-CORRESPONDING lt_project TO projects.

  ENDMETHOD.


  METHOD get_status.

    DATA lt_okey TYPE tt_objkey.

    IF properties IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT properties ASSIGNING FIELD-SYMBOL(<fs_p>).
      INSERT VALUE #( objnr = <fs_p>-objnr ) INTO TABLE lt_okey.
    ENDLOOP.

    SELECT a~objnr, b~txt04, b~txt30
      FROM jest AS a
      INNER JOIN tj02t AS b ON a~stat = b~istat AND b~spras = @sy-langu
      FOR ALL ENTRIES IN @lt_okey
      WHERE a~objnr = @lt_okey-objnr
      INTO CORRESPONDING FIELDS OF TABLE @details.

  ENDMETHOD.
ENDCLASS.
