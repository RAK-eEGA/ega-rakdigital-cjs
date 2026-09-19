CLASS zcl_rak_property_api DEFINITION
  PUBLIC
  INHERITING FROM zcl_rak_cj_api
  FINAL
  CREATE PUBLIC.

*&---------------------------------------------------------------------*
*& Parcels, properties and their owners, without the OData.
*&
*& This is what RAKPARCELSELECTOR actually is. The ShapeIt control looks
*& like a map widget, and the map is the part that is not the point: the
*& list beside it is ONE read of /PropertiesSet on the CUSTOMERJOURNEY
*& service, filtered by the citizen's partner guid and a role, and the
*& citizen's press writes one parcel id back into the journey. Everything
*& else in that control is presentation.
*&
*& READ OFF THE CONTROL AND THE DPC, NOT INFERRED. RAKPARCELSELECTOR.js
*& issues exactly one server read for its list -
*&
*&     this.models.doRead(this,"/PropertiesSet", T, true, "journey")
*&
*& with Partnerguid, Partnerrole and Type as server filters; Favourite,
*& ParcelId, SectorText and LandUse are applied CLIENT side to the already
*& fetched list, which is why they are search arguments here rather than
*& filters. PROPERTIESSET_GET_ENTITYSET reads exactly Partnerguid,
*& Partnerrole, Type, ApplType, ParcelId and Favourite and nothing else.
*&
*& FINDPARCELSET IS NOT THIS. It is tempting - the control is a parcel
*& selector and there is an entity set with 'FindParcel' in the name - and
*& it is wrong: FindParcel has no _GET_ENTITYSET at all. It is a
*& CREATE_DEEP_ENTITY target that opens a ZGCF case for the "I cannot find
*& my property" flow, refuses if one is already open, and takes
*& attachments. Binding a selector to it would have posted a case every
*& time a citizen looked at a list. This class does not touch it.
*&
*& PARTNERGUID IS THE IDENTITY AND IT IS MANDATORY. The DPC returns an
*& empty table if it is blank, silently - so a journey launched without a
*& partner guid would render an empty parcel list and look like a citizen
*& with no property. GUARD( ) turns that into a message instead. This is
*& the filter-based identity from ZCL_RAK_CJ_API: the DPC also calls
*& GET_BP( ) on the request headers, but only gates on it when SY-UNAME is
*& PORTAL1 or RAKDIGI_USER, which a CJS dialog user is not - so the empty
*& header table this layer supplies is not merely tolerated here, it is
*& read and correctly ignored.
*&
*& THE ROLE CODES ARE NOT INTERCHANGEABLE. TR0800 is ownership and
*& property management; YTR080 is grants, and the DPC translates it to
*& ZTR080 on the way in - so pass YTR080, the OData spelling, not the
*& table one. A journey in the GRANTS category selects with YTR080; every
*& other Municipality journey selects with TR0800.
*&
*& THE FULL-DETAILS DIALOG IS NOW HERE TOO - see DETAILS( ). This block
*& used to list it under "deliberately not here", behind an expand object
*& that could not be built from this environment. It turned out not to
*& need one: the six children are plain method calls on
*& ZCL_EGA_MUN_CJ_ODATA_API, which is what GET_EXPANDED_ENTITY itself
*& calls. The reasoning is at DETAILS( ) rather than repeated here.
*&
*& WHAT IS STILL DELIBERATELY NOT HERE.
*&   - FloorSet. It exists ONLY inside GET_EXPANDED_ENTITYSET - the
*&     PLURAL method - under iv_entity_name = gc_floor, and nothing in
*&     that branch resolves to a legacy class the way the Properties
*&     branch does. So RAK_FLOORUNIT still has no read to wrap, and it is
*&     the one place the expand-object question genuinely remains.
*&---------------------------------------------------------------------*

  PUBLIC SECTION.

*   A GENERATED MPC TABLE TYPE CANNOT TYPE A DATA OBJECT. The generator
*   writes them as `TT_X type standard table of TS_X .` with no key at
*   all, which leaves the key unspecified - and a table type with an
*   unspecified key is GENERIC: legal for a formal parameter or a field
*   symbol, rejected everywhere else. Activation says it in those words:
*   "TT_FEES is a generic type. Use this type only for typing field
*   symbols and formal parameters."
*
*   So the row type is taken FROM the MPC with LINE OF - never a guessed
*   TS_ name - and the table type is completed here. The DPC's own
*   ET_ENTITYSET keeps the generic type, and a standard table of the same
*   row type binds to it, so nothing on the call side changes.
*   AND IT CANNOT BE CALLED TT_PARTNER EITHER. This class inherits the
*   generated DPC, so every type that chain declares is already in scope
*   here - "There is already a type called TT_PARTNER" is what naming one
*   of them again costs. The local types therefore carry a _ROW / _ROWS
*   suffix that the generator never emits.
    TYPES ty_prop_row    TYPE LINE OF zcl_zega_cj_mpc=>tt_properties.
    TYPES ty_partner_row TYPE LINE OF zcl_zega_cj_mpc=>tt_partner.
    TYPES ty_mapurl_row  TYPE LINE OF zcl_zega_cj_mpc=>tt_mapurl.

    TYPES tt_prop_rows    TYPE STANDARD TABLE OF ty_prop_row    WITH DEFAULT KEY.
    TYPES tt_partner_rows TYPE STANDARD TABLE OF ty_partner_row WITH DEFAULT KEY.
    TYPES tt_mapurl_rows  TYPE STANDARD TABLE OF ty_mapurl_row  WITH DEFAULT KEY.

*   TOTAL IS THE COUNT BEFORE PAGING, not LINES( ROWS ). A pager needs to
*   know there are ninety parcels while holding six of them, and once the
*   read pages server side the table can no longer answer that. It is
*   filled only on the V3 path - the inherited DPC ignores paging
*   entirely, so on the legacy path ROWS is everything and TOTAL stays
*   zero. A caller that does not page can keep reading LINES( ROWS ).
    TYPES: BEGIN OF ty_prop_res,
             rows  TYPE tt_prop_rows,
             total TYPE i,
             msg   TYPE bapiret2_t,
           END OF ty_prop_res.

    TYPES: BEGIN OF ty_partner_res,
             rows TYPE tt_partner_rows,
             msg  TYPE bapiret2_t,
           END OF ty_partner_res.

    TYPES: BEGIN OF ty_map_res,
             url    TYPE string,
             gisurl TYPE string,
             token  TYPE string,
             msg    TYPE bapiret2_t,
           END OF ty_map_res.

*   The six child lists of one property, each an ANONYMOUS data object
*   holding a copy of what the legacy read returned.
*
*   REFERENCES, NOT TYPED TABLES, and CREATE DATA rather than GET
*   REFERENCE OF a local. Two reasons, and both are load-bearing.
*
*   The types are unknowable from here: the row structures live on
*   ZCL_EGA_MUN_CJ_ODATA_API's own method signatures, and naming them
*   would be six more generated shapes to get wrong - which this class's
*   header already records the cost of. DETAILS( ) never declares one; it
*   takes what the method returns with an inline DATA( ) and copies it
*   into an anonymous object of the same type via CREATE DATA ... LIKE.
*
*   And a reference to a local variable would DANGLE. Only anonymous data
*   objects are kept alive by the reference itself; a method's own locals
*   go when the method does, so GET REFERENCE OF one and handing it back
*   is a reference to reclaimed memory.
*
*   UNBOUND MEANS NOT READ, empty means read and genuinely nothing - a
*   distinction a tab needs, because "this parcel has no buildings" and
*   "we could not ask" are different sentences to show a citizen.
    TYPES: BEGIN OF ty_detail_res,
             partners TYPE REF TO data,   " ToPartner      get_partners( )
             landuse  TYPE REF TO data,   " ToLandUse      get_chars( )
             measure  TYPE REF TO data,   " ToMeasurement  get_meas( )
             develop  TYPE REF TO data,   " ToDevelopment  get_assobj( )
             project  TYPE REF TO data,   " ToProject      get_projects( )
             attach   TYPE REF TO data,   " ToAttachment   search_title_deed( )
             msg      TYPE bapiret2_t,
           END OF ty_detail_res.

*   ---- the documents row, and it is OURS ------------------------------
*   The DPC's GET_FILENET_DOCS( ) is PRIVATE, and so are the TY_FNDOC /
*   TT_FNDOC types it answers in - inheriting the class reaches none of
*   the three. So DETAILS( ) does what that method does rather than
*   calling it, and this is the shape it returns.
*
*   DECLARED HERE, WHICH IS THE POINT: every other type in this class is
*   either taken from the MPC with LINE OF or left to an inline DATA( ),
*   because a generated shape guessed at is what this file's header is
*   about. This one is not guessed - it is chosen, and the fields are the
*   Filenet property names the search returns.
*
*   DOCID IS THE HANDLE, NOT THE FILE. SAPDocId is what a later per-row
*   action hands to ZCL_EGA_FILENET_API to fetch content; the list itself
*   must never pull it, or opening a parcel's Documents tab drags every
*   document out of ECM as base64 to render a few numbers.
    TYPES: BEGIN OF ty_doc_row,
             number     TYPE string,   " TitleDeedNumberCO
             doctype    TYPE string,   " Title Deed of Parcel / of Unit
             department TYPE string,   " constant on the DPC, not a property
             issuedate  TYPE string,   " IssueDate
             validfrom  TYPE string,   " DateValidFrom
             validto    TYPE string,   " DateValidTo
             docid      TYPE string,   " SAPDocId
           END OF ty_doc_row.
    TYPES tt_doc_rows TYPE STANDARD TABLE OF ty_doc_row WITH DEFAULT KEY.

*   Partnerrole, in the spelling PROPERTIESSET_GET_ENTITYSET reads.
    CONSTANTS c_role_owner TYPE string VALUE 'TR0800'.
    CONSTANTS c_role_grant TYPE string VALUE 'YTR080'.

*   Type, as the control sends it. Blank is 'All' - the control removes the
*   filter rather than sending a third value, and so does this.
    CONSTANTS c_type_parcel TYPE string VALUE 'Parcel'.
    CONSTANTS c_type_unit   TYPE string VALUE 'Unit'.

*   The relationship a property manager holds over somebody else's
*   property. PARTNERSET_GET_ENTITYSET reads it as Role.
    CONSTANTS c_rel_manager TYPE string VALUE 'Z00008'.

*   The list behind a parcel selector.
*
*   IV_OWNER_GUID is for the property-management tab ONLY: the citizen is
*   acting for somebody else, so the guid filtered on is that owner's, not
*   their own. Blank means the citizen's own, which is the normal case.
*   ---- PAGING, SEARCH AND SORT ARE V3-ONLY, AND OPTIONAL -------------
*   THE INHERITED DPC IGNORES ALL THREE. IS_PAGING, IV_SEARCH_STRING and
*   IT_ORDER reach PROPERTIESSET_GET_ENTITYSET and are never read - which
*   is why the parcel control pages and searches in ABAP over the whole
*   list today, and why the whole list has to be read to show six cards.
*   The V3 path honours them; the legacy path still cannot, so a caller
*   that passes them on a journey that has not opted in gets the same
*   unpaged answer it gets now. Nothing silently half-pages: TOTAL is
*   zero when the read did not page.
*
*   IV_SEARCH matches the haystack the control's HITS( ) already builds -
*   parcel number, building, sector text and land use, upper-cased,
*   substring - so moving a journey to server-side search does not change
*   which cards match, only where the matching happens.
    METHODS properties
      IMPORTING iv_type       TYPE string OPTIONAL
                iv_role       TYPE string DEFAULT c_role_owner
                iv_appl_type  TYPE string OPTIONAL
                iv_favourite  TYPE abap_bool DEFAULT abap_false
                iv_owner_guid TYPE string OPTIONAL
                iv_search     TYPE string OPTIONAL
                iv_top        TYPE i DEFAULT 0
                iv_skip       TYPE i DEFAULT 0
                iv_sort       TYPE string OPTIONAL
      RETURNING VALUE(rs)     TYPE ty_prop_res.

*   PROPERTIES( ) with Type = Parcel. The one a PARCEL field calls.
*   IV_GRANTS picks the grants role, which is what the GRANTS category
*   does in the control - M018, M019 and M020 here.
    METHODS parcels
      IMPORTING iv_grants     TYPE abap_bool DEFAULT abap_false
                iv_owner_guid TYPE string OPTIONAL
                iv_search     TYPE string OPTIONAL
                iv_top        TYPE i DEFAULT 0
                iv_skip       TYPE i DEFAULT 0
                iv_sort       TYPE string OPTIONAL
      RETURNING VALUE(rs)     TYPE ty_prop_res.

*   PROPERTIES( ) with Type = Unit.
    METHODS units
      IMPORTING iv_owner_guid TYPE string OPTIONAL
      RETURNING VALUE(rs)     TYPE ty_prop_res.

*   Does this parcel number exist at all? A DIFFERENT code path in the
*   DPC: a ParcelId filter short-circuits everything above it, checks
*   VILMPL and answers one row carrying only PARCELID - no owner, no area,
*   no land use. Use it to validate a typed-in number, never to display a
*   parcel.
    METHODS parcel_exists
      IMPORTING iv_parcel_id  TYPE string
      RETURNING VALUE(rv)     TYPE abap_bool.

*   The owners whose property this citizen may act for. Feeds the
*   property-management dropdown; its selection becomes IV_OWNER_GUID
*   above. Keyed on the PARTNER NUMBER, not the guid - PARTNERSET reads ID.
    METHODS managed_owners
      RETURNING VALUE(rs) TYPE ty_partner_res.

*   The GIS viewer's url and its token, for a journey that draws the map.
*   Two reads in the control, one here: the token and the url come from
*   the same entity set.
    METHODS map_url
      IMPORTING iv_parcel TYPE string OPTIONAL
      RETURNING VALUE(rs) TYPE ty_map_res.

*   ---- the full-details dialog: six tabs, no expand object -----------
*   THE EXPAND OBJECT TURNED OUT TO BE AVOIDABLE, which is worth more
*   than solving it would have been.
*
*   The dialog's own URL is a GET_EXPANDED_ENTITY call - singular, a key
*   in the path - and that method looked like the only way in. It has two
*   hard requirements, both read off ZCL_ZEGA_CJ_DPC_EXT rather than
*   guessed. IT_KEY_TAB must carry 'Intreno' and 'Partnerguid' in exactly
*   that mixed-case spelling, because the DPC reads them with
*   `it_key_tab[ name = 'Intreno' ]` inside TRY/CATCH
*   CX_SY_ITAB_LINE_NOT_FOUND and RETURNS on a miss - no message, no
*   exception, an empty entity. And IO_EXPAND, though declared OPTIONAL,
*   is dereferenced unconditionally: `io_expand->get_children( )` runs
*   before any child is fetched, and every child is then gated on
*   `line_exists( lt_children[ tech_nav_prop_name = 'TOPARTNER' ] )`. So
*   an expand object is required AND has to report the six nav names -
*   an empty one returns an entity with every tab blank, which looks
*   exactly like a backend holding no data.
*
*   Building one needs the method list of /IWBEP/IF_MGW_ODATA_EXPAND, and
*   that is not readable here: not in the class, not in doc/, and no
*   implementer appears in any legacy source in this repository. Guessing
*   at it is precisely what cost ZCL_RAK_CJ_REQ_CTX three activation
*   rounds.
*
*   SO READ THE SAME SOURCES THE DPC READS. Its body shows every one of
*   the six children is a plain method call on a legacy class CJS can
*   instantiate for itself:
*
*       ToPartner      lo_obj->get_partners( intreno = ... )
*       ToMeasurement  lo_obj->get_meas( intreno = ... )
*       ToLandUse      lo_obj->get_chars( intreno = ... )
*       ToDevelopment  lo_obj->get_assobj( objnr = ... )
*       ToProject      lo_obj->get_projects( IMPORTING projects = ... )
*
*   where LO_OBJ is NEW ZCL_EGA_MUN_CJ_ODATA_API( partner = ... ).
*
*   THE SIXTH IS DIFFERENT, and this comment claimed otherwise until
*   activation refused it. ToAttachment comes from the DPC's own
*   GET_FILENET_DOCS( ), which is **PRIVATE** - `Instance Private
*   Method`, declared after `private section` - so inheriting the class
*   reaches it no better than not inheriting it, and neither does it
*   reach TY_FNDOC or TT_FNDOC. Only the _GET_ENTITYSET methods are
*   protected, which is what made the assumption plausible and wrong.
*
*   So that one is REPLICATED rather than called:
*   ZCL_EGA_FILENET_HNDLR->SEARCH_TITLE_DEED( ) for the documents, then
*   the same filter on the parcel number or the AOID, into TY_DOC_ROW -
*   a type declared in this class, so nothing about it is inferred.
*
*   All IO_EXPAND ever did inside GET_EXPANDED_ENTITY was let the method
*   decide WHICH children to fetch. Asking for all six directly needs no
*   such object, so the one piece that could not be built from here stops
*   being on the path at all.
*
*   READING A LEGACY CLASS IS NOT MODIFYING ONE. Nothing here writes to
*   the legacy namespace; it calls it, exactly as the whole QNV bridge
*   does.
*
*   WHAT THIS GIVES UP is the flat half of the entity - PARCELID,
*   AREATEXT, ADDRESS, TYPE and the rest - which GET_EXPANDED_ENTITY
*   would have returned alongside the children. That costs nothing: the
*   caller already holds those on the row its card was drawn from, and
*   ZCL_RAK_CJ_PARCEL->GENERAL_TAB( ) fills the General tab from exactly
*   that row.
*
*   IV_PARCEL and IV_AOID are for the attachments only - GET_FILENET_DOCS
*   keys on the parcel number and the AOID, never on the intreno.
    METHODS details
      IMPORTING iv_intreno    TYPE string
                iv_parcel     TYPE string OPTIONAL
                iv_aoid       TYPE string OPTIONAL
                iv_owner_guid TYPE string OPTIONAL
      RETURNING VALUE(rs)     TYPE ty_detail_res.

  PROTECTED SECTION.

*   The partner guid this call should filter on, and a message when there
*   is none. Every read here needs one and the DPC answers blank without
*   saying why, so the check belongs in one place.
    METHODS guard
      IMPORTING iv_owner_guid TYPE string OPTIONAL
      EXPORTING ev_guid       TYPE string
      CHANGING  ct_msg        TYPE bapiret2_t.

*   ---- one Filenet property, by name, or blank -----------------------
*   A document from SEARCH_TITLE_DEED( ) carries its metadata as a table
*   of name/values pairs, so every field is a lookup rather than a
*   component.
*
*   THIS EXISTS TO AVOID THE DPC'S OWN SHAPE. It reads them as
*
*       VALUE #( <fs_d>-property_to[ property_name = 'SAPDocId' ]-values[ 1 ] OPTIONAL )
*
*   and OPTIONAL there guards only the LAST subscript - so a document
*   that simply lacks that property raises CX_SY_ITAB_LINE_NOT_FOUND on
*   the OUTER one. It holds for the documents that service returns today
*   and is not a pattern to copy.
*
*   ANY TABLE and ASSIGN COMPONENT, because PROPERTY_TO's row type is
*   whatever ZCL_EGA_FILENET_HNDLR declares and naming it would be
*   another guess. A structure without PROPERTY_NAME or VALUES answers
*   blank rather than raising.
    METHODS fn_prop
      IMPORTING it_prop   TYPE ANY TABLE
                iv_name   TYPE string
      RETURNING VALUE(rv) TYPE string.

*   ---- THE CJS READ PATH, AND WHY IT IS A REDEFINITION ---------------
*   THE ODATA SERVICE NEVER SEES THIS. Gateway instantiates
*   ZCL_ZEGA_CJ_DPC_EXT itself; this class is a SUBCLASS of it, reached
*   only because CJS calls the entityset method in process - see the
*   class header. So redefining here changes what CJS gets and nothing
*   else: the legacy service keeps calling the inherited body, which is
*   untouched, and no MPC, metadata or filter property changes.
*
*   IT IS A NARROW FAST PATH WITH A SUPER FALLBACK, not a replacement.
*   FAST_ROWS( ) answers only the shape the parcel selector actually
*   asks for - a partner guid that resolves in BUT000, no ParcelId, not
*   LEASE or POA, not a Tasheel relationship - and reports EV_DONE when
*   it did. Everything else, including every branch nobody has measured,
*   goes to SUPER->, which IS the legacy code. A case that is not
*   understood is therefore not a case that is reimplemented.
*
*   OFF UNTIL A JOURNEY ASKS FOR IT. PROPERTIES( ) adds the CJSENGINE
*   filter only for the journeys in C_V3_JOURNEYS, so nothing changes for
*   a journey that is not listed, and removing a journey from that list
*   is the whole rollback. The filter rides along to SUPER-> on the slow
*   path and is ignored there: the DPC reads its filters BY NAME and has
*   never heard of this one.
    METHODS propertiesset_get_entityset REDEFINITION.


  PRIVATE SECTION.

*   The opt-in list. A journey id here reads through
*   ZCL_EGA_MUN_CJ_ODATA_API_V3; every other journey reads exactly as it
*   does today. Comma separated with a leading and trailing comma so a
*   CS test cannot match a prefix - ',M01,' does not find ',M011,'.
    CONSTANTS c_v3_journeys TYPE string VALUE ',,'.
    CONSTANTS c_engine_prop TYPE string VALUE `CjsEngine`.
    CONSTANTS c_engine_v3   TYPE string VALUE `V3`.

    TYPES: BEGIN OF ty_addr,
             plno    TYPE relmplno,
             address TYPE string,
           END OF ty_addr.
    TYPES tt_addr TYPE SORTED TABLE OF ty_addr WITH UNIQUE KEY plno.
    TYPES: BEGIN OF ty_plkey,
             plno TYPE relmplno,
           END OF ty_plkey.
    TYPES tt_plkey TYPE SORTED TABLE OF ty_plkey WITH UNIQUE KEY plno.

*   V3 for this journey, or blank. FILTER( ) drops a blank value, so a
*   journey that is not opted in sends no engine filter at all.
    METHODS engine_for
      RETURNING VALUE(rv) TYPE string.

*   Did the caller ask for V3 - the filter PROPERTIES( ) attaches.
    METHODS engine_asked
      IMPORTING it_filter TYPE /iwbep/t_mgw_select_option
      RETURNING VALUE(rv) TYPE abap_bool.

*   The CJS read. EV_DONE is false for every shape this does not handle,
*   and the caller then takes SUPER->.
    METHODS fast_rows
      IMPORTING it_filter    TYPE /iwbep/t_mgw_select_option
                io_ctx       TYPE REF TO /iwbep/if_mgw_req_entityset
                iv_search    TYPE string
                is_paging    TYPE /iwbep/s_mgw_paging
                it_order     TYPE /iwbep/t_mgw_sorting_order
      EXPORTING et_entityset TYPE tt_prop_rows
                ev_count     TYPE i
                ev_done      TYPE abap_bool.

*   The haystack HITS( ) builds, built once per row here instead.
    METHODS matches
      IMPORTING is_row    TYPE ty_prop_row
                iv_term   TYPE string
      RETURNING VALUE(rv) TYPE abap_bool.

*   BAPI_RE_PL_GET_DETAIL once per DISTINCT parcel rather than once per
*   ROW. The DPC calls PARCEL_ADDRESS( ) inside both VALUE constructors,
*   so a parcel with twelve units pays for thirteen BAPI calls to build
*   one address. Units take their parent parcel's address, so the map is
*   keyed on the parcel number and every row reads it.
    METHODS addr_map
      IMPORTING it_plno   TYPE tt_plkey
      RETURNING VALUE(rt) TYPE tt_addr.

*   Replicas of the DPC's own PARCEL_ADDRESS( ) and CTT( ), which are
*   PRIVATE there - see GET_FILENET_DOCS( )'s note above, only the
*   _GET_ENTITYSET methods are protected - so inheriting reaches neither.
*   Copied from ZCL_EGA_CJ_Z2UI5_M030, which already carries the same two
*   for the same reason, so there is one shape to keep in step and not a
*   fresh guess at what the DPC does.
    METHODS pl_addr
      IMPORTING iv_parcel     TYPE relmplno
      RETURNING VALUE(rv)     TYPE string.
    METHODS to_ts
      IMPORTING iv_d      TYPE dats
      RETURNING VALUE(rv) TYPE timestamp.
ENDCLASS.



CLASS zcl_rak_property_api IMPLEMENTATION.


  METHOD engine_for.
*   A JOURNEY THAT IS NOT LISTED GETS NOTHING BACK, and FILTER( ) drops a
*   blank, so the engine filter is simply absent and the redefinition
*   hands the call to SUPER->. That is the default and it is the current
*   behaviour, unchanged.
    IF ms_ctx-journey IS INITIAL.
      RETURN.
    ENDIF.
    IF c_v3_journeys CS |,{ ms_ctx-journey },|.
      rv = c_engine_v3.
    ENDIF.
  ENDMETHOD.


  METHOD engine_asked.
    rv = xsdbool( VALUE string(
           it_filter[ property = c_engine_prop ]-select_options[ 1 ]-low OPTIONAL ) = c_engine_v3 ).
  ENDMETHOD.


  METHOD propertiesset_get_entityset.

*   ---- WHO ANSWERS THIS CALL -----------------------------------------
*   THE ORDER OF THESE TWO TESTS IS THE SAFETY. The engine filter is
*   asked FIRST, so a journey that has not opted in cannot reach any of
*   the new code however its other filters look; and FAST_ROWS( ) then
*   refuses anything it does not recognise rather than guessing, which is
*   what EV_DONE is for.
    IF engine_asked( it_filter_select_options ) = abap_true.

      fast_rows(
        EXPORTING it_filter    = it_filter_select_options
                  io_ctx       = io_tech_request_context
                  iv_search    = iv_search_string
                  is_paging    = is_paging
                  it_order     = it_order
        IMPORTING et_entityset = et_entityset
                  ev_count     = DATA(lv_count)
                  ev_done      = DATA(lv_done) ).

      IF lv_done = abap_true.
*       THE COUNT BEFORE PAGING. Gateway's own channel for it, so a real
*       OData consumer asking for $inlinecount would be answered too -
*       except that no OData consumer reaches this code at all.
        es_response_context-inlinecount = lv_count.
        RETURN.
      ENDIF.

*     NOT HANDLED, SO NOTHING PARTIAL IS KEPT. FAST_ROWS( ) can have
*     written rows before it discovered a shape it does not own, and
*     SUPER-> is about to produce the whole answer itself.
      CLEAR et_entityset.

    ENDIF.

*   THE LEGACY BODY, UNCHANGED. Lease, POA, ParcelId, Tasheel, the
*   PORTAL1 header guard and every journey that has not opted in arrive
*   here, and what they get is what they get today.
    super->propertiesset_get_entityset(
      EXPORTING
        iv_entity_name           = iv_entity_name
        iv_entity_set_name       = iv_entity_set_name
        iv_source_name           = iv_source_name
        it_filter_select_options = it_filter_select_options
        is_paging                = is_paging
        it_key_tab               = it_key_tab
        it_navigation_path       = it_navigation_path
        it_order                 = it_order
        iv_filter_string         = iv_filter_string
        iv_search_string         = iv_search_string
        io_tech_request_context  = io_tech_request_context
      IMPORTING
        et_entityset             = et_entityset
        es_response_context      = es_response_context ).

  ENDMETHOD.


  METHOD fast_rows.

    DATA: lv_temp   TYPE string,
          lv_guid   TYPE bu_partner_guid,
          lt_plkey  TYPE tt_plkey,
          ls_row    TYPE ty_prop_row,
          lt_out    TYPE tt_prop_rows.

*   ---- THE SHAPES THIS DOES NOT OWN ----------------------------------
*   Each of these is a branch of the DPC that runs BEFORE the read this
*   method replaces, and each is left to it. A ParcelId call is the
*   existence check ZCL_RAK_PROPERTY_API makes before a map pick; LEASE
*   and POA go to LEASE_PROPERTIESSET( ), which is PRIVATE there and
*   cannot be called from here anyway.
    IF VALUE string( it_filter[ property = 'ParcelId' ]-select_options[ 1 ]-low OPTIONAL ) IS NOT INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_appl) = VALUE string( it_filter[ property = 'ApplType' ]-select_options[ 1 ]-low OPTIONAL ).
    IF lv_appl = 'LEASE' OR lv_appl = 'POA'.
      RETURN.
    ENDIF.

*   THE PORTAL HEADER GUARD, REPLICATED RATHER THAN SKIPPED. It reads the
*   same request context CJS already hands the DPC, so the inputs are
*   identical and so is the answer. Skipping it would return rows on the
*   one path the DPC deliberately answers blank.
    DATA(lt_hdr) = io_ctx->get_request_headers( ).
    READ TABLE lt_hdr TRANSPORTING NO FIELDS WITH KEY name = 'x-custom1'.
    DATA(lv_new) = xsdbool( sy-subrc = 0 ).

    zcl_zega_cj_utility_dpc_ext=>get_bp(
      EXPORTING io_tech_request_context = io_ctx
      IMPORTING user                    = DATA(lv_user)
                partner                 = DATA(lv_xpartner) ).

    IF sy-uname = 'PORTAL1' OR sy-uname = 'RAKDIGI_USER'.
      IF lv_new = abap_true AND lv_user IS INITIAL.
        ev_done = abap_true.
        RETURN.
      ENDIF.
    ENDIF.

    lv_temp = VALUE #( it_filter[ property = 'Partnerguid' ]-select_options[ 1 ]-low OPTIONAL ).
    TRANSLATE lv_temp TO UPPER CASE.
    lv_guid = lv_temp.
    IF lv_guid IS INITIAL.
      ev_done = abap_true.
      RETURN.
    ENDIF.

*   BUT000 ONLY. A guid that resolves through ZEGA_T_CJ_BP_REL instead is
*   the Tasheel branch, which filters the property list against
*   ZEGA_T_CJ_OBJREL and forces role TR0800 - a different read, not a
*   faster one, so it goes to SUPER->.
    SELECT SINGLE partner FROM but000
      WHERE partner_guid = @lv_guid
      INTO @DATA(lv_partner).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    DATA(lv_role) = VALUE string( it_filter[ property = 'Partnerrole' ]-select_options[ 1 ]-low OPTIONAL ).
    DATA(lv_fav)  = VALUE string( it_filter[ property = 'Favourite' ]-select_options[ 1 ]-low OPTIONAL ).
    DATA(lv_type) = VALUE string( it_filter[ property = 'Type' ]-select_options[ 1 ]-low OPTIONAL ).
    IF lv_role = 'YTR080'.
      lv_role = 'ZTR080'.
    ENDIF.

*   ---- THE ONE LINE THIS WHOLE REDEFINITION EXISTS FOR ----------------
    DATA(lo_obj) = NEW zcl_ega_mun_cj_odata_api_v3( partner = lv_partner
                                                    role    = CONV #( lv_role ) ).

    SELECT * FROM zega_t_cj_favlog
      WHERE partner = @lv_partner
      INTO TABLE @DATA(lt_log).
    SORT lt_log BY intreno.

*   DECIDED THEN SWEPT, not deleted inside the loop. The DPC runs DELETE
*   PROPERTIES WHERE INTRENO while looping PROPERTIES, which drops rows
*   the loop has not reached and can skip the row after each deletion, so
*   which rows survived depended on where they sat. This applies the rule
*   the code expresses, to every row.
    IF lv_fav = abap_true.
      DATA lt_keep TYPE zcl_ega_mun_cj_odata_api_v3=>tt_properties.
      LOOP AT lo_obj->properties ASSIGNING FIELD-SYMBOL(<fs_pr>).
        READ TABLE lt_log TRANSPORTING NO FIELDS
             WITH KEY intreno = <fs_pr>-intreno BINARY SEARCH.
        IF sy-subrc = 0.
          APPEND <fs_pr> TO lt_keep.
        ENDIF.
      ENDLOOP.
      lo_obj->properties = lt_keep.
    ENDIF.

    LOOP AT lo_obj->properties ASSIGNING <fs_pr>.
      READ TABLE lt_log TRANSPORTING NO FIELDS
           WITH KEY intreno = <fs_pr>-intreno BINARY SEARCH.
      IF sy-subrc = 0.
        <fs_pr>-favourite = abap_true.
      ENDIF.
    ENDLOOP.

    DATA(lt_prop) = lo_obj->properties.
    DATA(lt_pl)   = lo_obj->get_pl_header( ).
    DATA(lt_ao)   = lo_obj->get_ao_header( ).
    DATA(lt_loc)  = lo_obj->get_location( ).
    DATA(lt_st)   = lo_obj->get_status( ).

*   ---- INDEXED ONCE INSTEAD OF SCANNED PER FIELD ----------------------
*   The DPC's VALUE constructors reach MT_PROPERTIES[ INTRENO = ... ]
*   eight times for a parcel row and six more for a unit, and each one is
*   a linear scan of every property the citizen holds. Same for STATUS
*   and LOCATION. Sorted copies turn the whole mapping from quadratic
*   into one binary search per field.
    DATA lt_pidx TYPE SORTED TABLE OF zcl_ega_mun_cj_odata_api_v3=>ty_properties
                      WITH NON-UNIQUE KEY intreno.
    lt_pidx = lt_prop.
    SORT lt_st BY objnr.
    SORT lt_loc BY intreno.

*   LT_PL IS NOT SORTED, AND THAT IS DELIBERATE. The parcel rows are
*   appended in GET_PL_HEADER( )'s own order, which is the order the DPC
*   emits them and therefore the order the card list pages through -
*   sorting it here would quietly reshuffle which parcels land on page
*   one. The lookup the unit rows need gets its own sorted copy instead.
    DATA lt_plx TYPE SORTED TABLE OF zcl_ega_mun_cj_odata_api_v3=>ty_pl_header
                     WITH NON-UNIQUE KEY intreno.
    lt_plx = lt_pl.

    LOOP AT lt_pl ASSIGNING FIELD-SYMBOL(<fs_wa>).
      INSERT VALUE #( plno = <fs_wa>-plno ) INTO TABLE lt_plkey.
    ENDLOOP.
    DATA(lt_addr) = addr_map( lt_plkey ).

*   ---- PARCEL ROWS ----------------------------------------------------
    LOOP AT lt_pl ASSIGNING <fs_wa>.

      CLEAR ls_row.
      READ TABLE lt_pidx ASSIGNING FIELD-SYMBOL(<fs_pi>)
           WITH KEY intreno = <fs_wa>-intreno.
      DATA(lv_has) = xsdbool( sy-subrc = 0 ).

      ls_row-parcelid        = <fs_wa>-plno.
      ls_row-parceldesc      = <fs_wa>-xpl.
      ls_row-locationdesc    = <fs_wa>-xpl.
      ls_row-landuse         = <fs_wa>-xfixfitcharact.
      ls_row-type            = 'Parcel'.
      ls_row-intreno         = <fs_wa>-intreno.
      ls_row-departmentcode  = 'MUN'.
      ls_row-departmentname  = COND #( WHEN sy-langu = 'E' THEN 'Municipality'
                                                           ELSE 'بلدية رأس الخيمة' ).

      IF <fs_wa>-validfrom IS NOT INITIAL.
        ls_row-parcelvalidfrom = to_ts( <fs_wa>-validfrom ).
      ENDIF.

*     THE GRANT PARCEL DATES ITSELF FROM THE CONTRACT, not from VILMPL -
*     the DPC's own COND, kept whole because a grant that has run out has
*     to read as run out on the card.
      IF lv_has = abap_true AND <fs_pi>-is_grant = 'X'.
        IF <fs_pi>-validto IS NOT INITIAL.
          ls_row-parcelvalidto = to_ts( CONV #( <fs_pi>-validto ) ).
        ENDIF.
      ELSEIF <fs_wa>-validto IS NOT INITIAL.
        ls_row-parcelvalidto = to_ts( <fs_wa>-validto ).
      ENDIF.

      IF lv_has = abap_true.
        READ TABLE lt_st ASSIGNING FIELD-SYMBOL(<fs_stx>)
             WITH KEY objnr = <fs_pi>-objnr BINARY SEARCH.
        IF sy-subrc = 0.
          ls_row-parcelstatus = <fs_stx>-txt30.
        ENDIF.
        ls_row-favourite     = <fs_pi>-favourite.
        ls_row-ownershiptype = <fs_pi>-ownershpmthd.
        ls_row-granttype     = <fs_pi>-granttype.
      ENDIF.

      READ TABLE lt_loc ASSIGNING FIELD-SYMBOL(<fs_lo>)
           WITH KEY intreno = <fs_wa>-intreno BINARY SEARCH.
      IF sy-subrc = 0.
        ls_row-sector     = <fs_lo>-sector.
        ls_row-sectortext = <fs_lo>-sectortext.
        ls_row-area       = <fs_lo>-area.
        ls_row-areatext   = <fs_lo>-areatext.
      ENDIF.

      READ TABLE lt_addr ASSIGNING FIELD-SYMBOL(<fs_ad>)
           WITH TABLE KEY plno = <fs_wa>-plno.
      IF sy-subrc = 0.
        ls_row-address = <fs_ad>-address.
      ENDIF.

      APPEND ls_row TO lt_out.

    ENDLOOP.

*   ---- THE I8912 EXCLUSION, BEFORE THE UNITS ARE ADDED ----------------
*   Order matters and it is the DPC's. This runs against the parcel rows
*   only; units are appended after it and are not tested.
    IF lt_st IS NOT INITIAL AND lt_out IS NOT INITIAL.
      SELECT a~objnr, b~plno
        FROM jest AS a
        INNER JOIN vilmpl AS b ON a~objnr = b~objnr
        FOR ALL ENTRIES IN @lt_st
        WHERE a~objnr = @lt_st-objnr AND a~stat = 'I8912' AND a~inact = @abap_false
        INTO TABLE @DATA(lt_na).
      IF lt_na IS NOT INITIAL.
        SORT lt_na BY plno.
        DATA lt_ok TYPE tt_prop_rows.
        LOOP AT lt_out ASSIGNING FIELD-SYMBOL(<fs_o>).
          READ TABLE lt_na TRANSPORTING NO FIELDS
               WITH KEY plno = <fs_o>-parcelid BINARY SEARCH.
          IF sy-subrc <> 0.
            APPEND <fs_o> TO lt_ok.
          ENDIF.
        ENDLOOP.
        lt_out = lt_ok.
      ENDIF.
    ENDIF.

*   ---- UNIT ROWS ------------------------------------------------------
    LOOP AT lt_ao ASSIGNING FIELD-SYMBOL(<fs_wa1>).

      CLEAR ls_row.
      READ TABLE lt_pidx ASSIGNING <fs_pi> WITH KEY intreno = <fs_wa1>-intreno.
      lv_has = xsdbool( sy-subrc = 0 ).

      ls_row-aoid           = <fs_wa1>-aoid.
      ls_row-aoname         = <fs_wa1>-xao.
      ls_row-aotype         = <fs_wa1>-xmaotype.
      ls_row-aofunction     = <fs_wa1>-xmaofunction.
      ls_row-intreno        = <fs_wa1>-intreno.
      ls_row-type           = 'Unit'.
      ls_row-floor          = <fs_wa1>-flraoid.
      ls_row-floorname      = <fs_wa1>-flrxao.
      ls_row-building       = <fs_wa1>-bldaoid.
      ls_row-buildingname   = <fs_wa1>-bldxao.
      ls_row-externalunitno = <fs_wa1>-zzold_unnr.
      ls_row-fewa           = <fs_wa1>-zzfewa_acc.
      ls_row-departmentcode = 'MUN'.
      ls_row-departmentname = COND #( WHEN sy-langu = 'E' THEN 'Municipality'
                                                          ELSE 'بلدية رأس الخيمة' ).

      IF <fs_wa1>-validfrom IS NOT INITIAL.
        ls_row-aovalidfrom = to_ts( <fs_wa1>-validfrom ).
      ENDIF.
      IF <fs_wa1>-validto IS NOT INITIAL.
        ls_row-aovalidto = to_ts( <fs_wa1>-validto ).
      ENDIF.

      IF lv_has = abap_true.

        ls_row-parcelid  = <fs_pi>-parentid.
        ls_row-favourite = <fs_pi>-favourite.

        READ TABLE lt_st ASSIGNING <fs_stx>
             WITH KEY objnr = <fs_pi>-objnr BINARY SEARCH.
        IF sy-subrc = 0.
          ls_row-aostatus = <fs_stx>-txt30.
        ENDIF.

*       A UNIT TAKES ITS LOCATION AND ITS ADDRESS FROM THE PARENT PARCEL,
*       through INTRENO_P - the unit's own INTRENO has no location row.
        READ TABLE lt_loc ASSIGNING <fs_lo>
             WITH KEY intreno = <fs_pi>-intreno_p BINARY SEARCH.
        IF sy-subrc = 0.
          ls_row-sector     = <fs_lo>-sector.
          ls_row-sectortext = <fs_lo>-sectortext.
          ls_row-area       = <fs_lo>-area.
          ls_row-areatext   = <fs_lo>-areatext.
        ENDIF.

        READ TABLE lt_plx ASSIGNING FIELD-SYMBOL(<fs_pp>)
             WITH KEY intreno = <fs_pi>-intreno_p.
        IF sy-subrc = 0.
          READ TABLE lt_addr ASSIGNING <fs_ad> WITH TABLE KEY plno = <fs_pp>-plno.
          IF sy-subrc = 0.
            ls_row-address = <fs_ad>-address.
          ENDIF.
        ENDIF.

      ENDIF.

      APPEND ls_row TO lt_out.

    ENDLOOP.

    IF lv_type IS NOT INITIAL.
      DELETE lt_out WHERE type <> lv_type.
    ENDIF.

*   ---- SEARCH, THEN SORT, THEN COUNT, THEN PAGE -----------------------
*   THE ORDER OF THESE FOUR IS THE WHOLE CONTRACT. Searching after paging
*   would page the unsearched list and then filter the page, so page one
*   of a search for SUHAILAH would hold whichever of the first six
*   parcels happened to match. Counting after paging would report the
*   page size. Sorting after paging would sort a page.
*
*   THE SAME HAYSTACK THE CONTROL BUILDS - parcel number, building,
*   sector text, land use, upper-cased, substring - so a journey moving
*   from the control's HITS( ) to this finds exactly the same cards.
    IF iv_search IS NOT INITIAL.
      DATA(lv_term) = to_upper( condense( iv_search ) ).
      DATA lt_hit TYPE tt_prop_rows.
      LOOP AT lt_out ASSIGNING FIELD-SYMBOL(<fs_h>).
        IF matches( is_row = <fs_h> iv_term = lv_term ) = abap_true.
          APPEND <fs_h> TO lt_hit.
        ENDIF.
      ENDLOOP.
      lt_out = lt_hit.
    ENDIF.

*   ONE PROPERTY, AND AN UNKNOWN NAME LEAVES THE ORDER ALONE rather than
*   dumping: IT_ORDER carries whatever a caller typed, and SORT BY a
*   component that does not exist is a short dump, not a message.
    LOOP AT it_order ASSIGNING FIELD-SYMBOL(<fs_ord>).
      DATA(lv_comp) = to_upper( condense( CONV string( <fs_ord>-property ) ) ).
      ASSIGN COMPONENT lv_comp OF STRUCTURE ls_row TO FIELD-SYMBOL(<fs_probe>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      IF to_upper( CONV string( <fs_ord>-order ) ) = `DESC`.
        SORT lt_out BY (lv_comp) DESCENDING.
      ELSE.
        SORT lt_out BY (lv_comp) ASCENDING.
      ENDIF.
      EXIT.
    ENDLOOP.

    ev_count = lines( lt_out ).

*   TOP = 0 MEANS NO PAGING, which is what every caller that has not
*   asked for it sends, so the whole list comes back exactly as before.
*   SKIP past the end answers empty rather than the last page.
    IF is_paging-top > 0 OR is_paging-skip > 0.
      DATA(lv_from) = is_paging-skip + 1.
      DATA(lv_to)   = COND i( WHEN is_paging-top > 0
                              THEN is_paging-skip + is_paging-top
                              ELSE lines( lt_out ) ).
      DATA lt_page TYPE tt_prop_rows.
      LOOP AT lt_out ASSIGNING <fs_h> FROM lv_from TO lv_to.
        APPEND <fs_h> TO lt_page.
      ENDLOOP.
      lt_out = lt_page.
    ENDIF.

    et_entityset = lt_out.
    ev_done      = abap_true.

  ENDMETHOD.


  METHOD matches.

    rv = abap_true.
    IF iv_term IS INITIAL.
      RETURN.
    ENDIF.
    IF to_upper( |{ is_row-parcelid } { is_row-building } { is_row-sectortext } { is_row-landuse }| )
       NS iv_term.
      CLEAR rv.
    ENDIF.

  ENDMETHOD.


  METHOD addr_map.

    LOOP AT it_plno ASSIGNING FIELD-SYMBOL(<fs_k>).
      IF <fs_k>-plno IS INITIAL.
        CONTINUE.
      ENDIF.
      INSERT VALUE #( plno    = <fs_k>-plno
                      address = pl_addr( <fs_k>-plno ) ) INTO TABLE rt.
    ENDLOOP.

  ENDMETHOD.


  METHOD pl_addr.

    DATA: lv_plno   TYPE bapi_re_parcel_land_key-parcel_of_land_number,
          ls_pl     TYPE bapi_re_parcel_land,
          lt_addr   TYPE STANDARD TABLE OF bapi_re_multi_addr,
          lt_return TYPE STANDARD TABLE OF bapiret2.

    lv_plno = iv_parcel.

    CALL FUNCTION 'BAPI_RE_PL_GET_DETAIL'
      EXPORTING
        locationhierarchy  = ' '
        subdivisionnumber  = ' '
        parceloflandnumber = lv_plno
      IMPORTING
        parcel_of_land     = ls_pl
      TABLES
        address            = lt_addr
        return             = lt_return.

    DATA(ls_a) = VALUE bapi_re_multi_addr( lt_addr[ 1 ] OPTIONAL ).

    rv = ls_a-house_no    && COND #( WHEN ls_a-house_no    IS NOT INITIAL THEN ',' )
      && ls_a-street_lng  && COND #( WHEN ls_a-street_lng  IS NOT INITIAL THEN ',' )
      && ls_a-str_suppl1  && COND #( WHEN ls_a-str_suppl1  IS NOT INITIAL THEN ',' )
      && ls_a-str_suppl2  && COND #( WHEN ls_a-str_suppl2  IS NOT INITIAL THEN ',' )
      && ls_a-str_suppl3  && COND #( WHEN ls_a-str_suppl3  IS NOT INITIAL THEN ',' )
      && ls_a-location    && COND #( WHEN ls_a-location    IS NOT INITIAL THEN ',' )
      && ls_a-district.

  ENDMETHOD.


  METHOD to_ts.

*   THE DPC PASSES I_T = '000000' AND NO C_T at every one of these four
*   calls, so the date-format branch of its CTT( ) is never reached from
*   this path and is not carried here. UTC, like the original.
    CALL FUNCTION 'IB_CONVERT_INTO_TIMESTAMP'
      EXPORTING
        i_datlo     = iv_d
        i_timlo     = '000000'
        i_tzone     = 'UTC'
      IMPORTING
        e_timestamp = rv.

  ENDMETHOD.


  METHOD guard.
    CLEAR ev_guid.

    ev_guid = COND string( WHEN iv_owner_guid IS NOT INITIAL
                           THEN iv_owner_guid
                           ELSE ms_ctx-partnerguid ).
    IF ev_guid IS NOT INITIAL.
      RETURN.
    ENDIF.

*   Not an exception: the caller is a renderer, and a field that cannot be
*   filled has to say so on the screen rather than take the journey down.
    APPEND VALUE bapiret2(
        type       = 'E'
        id         = 'ZMSG_EGA_CJ'
        number     = '000'
        message    = COND #( WHEN sy-langu = 'E'
                             THEN 'No partner is known for this journey, so no property can be listed'
                             ELSE 'لا يوجد شريك معروف لهذه الرحلة، لذلك لا يمكن عرض العقارات' ) )
      TO ct_msg.
  ENDMETHOD.


  METHOD properties.
    DATA lt_flt TYPE /iwbep/t_mgw_select_option.

    guard( EXPORTING iv_owner_guid = iv_owner_guid
           IMPORTING ev_guid       = DATA(lv_guid)
           CHANGING  ct_msg        = rs-msg ).
    IF lv_guid IS INITIAL.
      RETURN.
    ENDIF.

    filter( EXPORTING iv_property = `Partnerguid` iv_value = lv_guid      CHANGING ct_filter = lt_flt ).
    filter( EXPORTING iv_property = `Partnerrole` iv_value = iv_role      CHANGING ct_filter = lt_flt ).
    filter( EXPORTING iv_property = `ApplType`    iv_value = iv_appl_type CHANGING ct_filter = lt_flt ).

*   Type is omitted, not sent blank, for 'All'. FILTER( ) already drops a
*   blank value, so passing IV_TYPE through covers both.
    filter( EXPORTING iv_property = `Type`        iv_value = iv_type      CHANGING ct_filter = lt_flt ).

    IF iv_favourite = abap_true.
      filter( EXPORTING iv_property = `Favourite` iv_value = `X` CHANGING ct_filter = lt_flt ).
    ENDIF.

*   ---- WHICH READ ANSWERS THIS, AND ONLY FOR THE LISTED JOURNEYS ------
*   ENGINE_FOR( ) returns V3 for a journey in C_V3_JOURNEYS and blank for
*   every other, and FILTER( ) drops a blank - so an unlisted journey
*   sends no engine filter and the redefinition below hands it straight
*   to the inherited DPC body, exactly as today.
*
*   A FILTER RATHER THAN A METHOD PARAMETER because this call is IN
*   PROCESS. Nothing between here and the redefinition validates filter
*   property names - there is no Gateway in the path - so the flag costs
*   no MPC change, no metadata change and nothing the OData service can
*   see. Over HTTP the same idea would have needed the property adding to
*   the entity type and the model regenerating.
    filter( EXPORTING iv_property = c_engine_prop iv_value = engine_for( )
            CHANGING  ct_filter   = lt_flt ).

*   IV_SORT IS ONE PROPERTY NAME, optionally suffixed ` desc`, because
*   that is all any caller has wanted and IT_ORDER's shape is a table of
*   exactly that pair. Blank leaves the order the read produced, which is
*   GET_PL_HEADER( )'s and is what the list shows today.
    DATA lt_ord TYPE /iwbep/t_mgw_sorting_order.
    IF iv_sort IS NOT INITIAL.
      SPLIT condense( iv_sort ) AT ` ` INTO DATA(lv_ordp) DATA(lv_ordd).
      APPEND VALUE #( property = lv_ordp
                      order    = COND #( WHEN to_upper( lv_ordd ) = `DESC`
                                         THEN `desc` ELSE `asc` ) ) TO lt_ord.
    ENDIF.

    TRY.
        propertiesset_get_entityset(
          EXPORTING
            iv_entity_name           = `Properties`
            iv_entity_set_name       = `PropertiesSet`
            iv_source_name           = ``
            it_filter_select_options = lt_flt
            is_paging                = VALUE #( top = iv_top skip = iv_skip )
            it_key_tab               = VALUE #( )
            it_navigation_path       = VALUE #( )
            it_order                 = lt_ord
            iv_filter_string         = ``
            iv_search_string         = iv_search
            io_tech_request_context  = mo_req
          IMPORTING
            et_entityset             = rs-rows
            es_response_context      = DATA(ls_resp) ).
        rs-total = ls_resp-inlinecount.
      CATCH cx_root INTO DATA(lx).
        to_msg( EXPORTING io_exc = lx CHANGING ct_msg = rs-msg ).
    ENDTRY.
  ENDMETHOD.


  METHOD parcels.
    rs = properties(
           iv_type       = c_type_parcel
           iv_role       = COND string( WHEN iv_grants = abap_true
                                        THEN c_role_grant ELSE c_role_owner )
           iv_owner_guid = iv_owner_guid
           iv_search     = iv_search
           iv_top        = iv_top
           iv_skip       = iv_skip
           iv_sort       = iv_sort ).
  ENDMETHOD.


  METHOD units.
    rs = properties( iv_type       = c_type_unit
                     iv_owner_guid = iv_owner_guid ).
  ENDMETHOD.


  METHOD parcel_exists.
    DATA lt_flt TYPE /iwbep/t_mgw_select_option.
    DATA lt_row TYPE tt_prop_rows.

    IF iv_parcel_id IS INITIAL.
      RETURN.
    ENDIF.

*   ParcelId alone. Deliberately no Partnerguid: this path runs BEFORE the
*   partner is read in the DPC and returns before reaching it, so adding
*   one would suggest an ownership test this does not perform.
    filter( EXPORTING iv_property = `ParcelId` iv_value = iv_parcel_id CHANGING ct_filter = lt_flt ).

    TRY.
        propertiesset_get_entityset(
          EXPORTING
            iv_entity_name           = `Properties`
            iv_entity_set_name       = `PropertiesSet`
            iv_source_name           = ``
            it_filter_select_options = lt_flt
            is_paging                = VALUE #( )
            it_key_tab               = VALUE #( )
            it_navigation_path       = VALUE #( )
            it_order                 = VALUE #( )
            iv_filter_string         = ``
            iv_search_string         = ``
            io_tech_request_context  = mo_req
          IMPORTING
            et_entityset             = lt_row ).
      CATCH cx_root.
*       An unreadable answer is not a proven absence. Say no, and let the
*       caller's own required check speak - never accept on a failed read.
        RETURN.
    ENDTRY.

    rv = xsdbool( lt_row IS NOT INITIAL ).
  ENDMETHOD.


  METHOD managed_owners.
    DATA lt_flt TYPE /iwbep/t_mgw_select_option.

    IF ms_ctx-partner IS INITIAL.
      APPEND VALUE bapiret2(
          type    = 'E'
          id      = 'ZMSG_EGA_CJ'
          number  = '000'
          message = COND #( WHEN sy-langu = 'E'
                            THEN 'No partner is known for this journey, so no managed owners can be listed'
                            ELSE 'لا يوجد شريك معروف لهذه الرحلة، لذلك لا يمكن عرض المالكين' ) )
        TO rs-msg.
      RETURN.
    ENDIF.

*   ID is the partner NUMBER here, not the guid - PARTNERSET_GET_ENTITYSET
*   reads BU_PARTNER off it. The guid is what PropertiesSet wants; the two
*   are not interchangeable and this is the one read that takes the number.
    filter( EXPORTING iv_property = `ID`   iv_value = ms_ctx-partner CHANGING ct_filter = lt_flt ).
    filter( EXPORTING iv_property = `Role` iv_value = c_rel_manager  CHANGING ct_filter = lt_flt ).

    TRY.
        partnerset_get_entityset(
          EXPORTING
            iv_entity_name           = `Partner`
            iv_entity_set_name       = `PartnerSet`
            iv_source_name           = ``
            it_filter_select_options = lt_flt
            is_paging                = VALUE #( )
            it_key_tab               = VALUE #( )
            it_navigation_path       = VALUE #( )
            it_order                 = VALUE #( )
            iv_filter_string         = ``
            iv_search_string         = ``
            io_tech_request_context  = mo_req
          IMPORTING
            et_entityset             = rs-rows ).
      CATCH cx_root INTO DATA(lx).
        to_msg( EXPORTING io_exc = lx CHANGING ct_msg = rs-msg ).
    ENDTRY.
  ENDMETHOD.


  METHOD map_url.
    DATA lt_flt TYPE /iwbep/t_mgw_select_option.
    DATA lt_row TYPE tt_mapurl_rows.

    guard( IMPORTING ev_guid = DATA(lv_guid)
           CHANGING  ct_msg  = rs-msg ).
    IF lv_guid IS INITIAL.
      RETURN.
    ENDIF.

    filter( EXPORTING iv_property = `Partnerguid` iv_value = lv_guid   CHANGING ct_filter = lt_flt ).
    filter( EXPORTING iv_property = `Parcel`      iv_value = iv_parcel CHANGING ct_filter = lt_flt ).

    TRY.
        mapurlset_get_entityset(
          EXPORTING
            iv_entity_name           = `MapUrl`
            iv_entity_set_name       = `MapUrlSet`
            iv_source_name           = ``
            it_filter_select_options = lt_flt
            is_paging                = VALUE #( )
            it_key_tab               = VALUE #( )
            it_navigation_path       = VALUE #( )
            it_order                 = VALUE #( )
            iv_filter_string         = ``
            iv_search_string         = ``
            io_tech_request_context  = mo_req
          IMPORTING
            et_entityset             = lt_row ).
      CATCH cx_root INTO DATA(lx).
        to_msg( EXPORTING io_exc = lx CHANGING ct_msg = rs-msg ).
        RETURN.
    ENDTRY.

*   The control reads results[0] for both, and the DPC answers one row.
    READ TABLE lt_row INTO DATA(ls_row) INDEX 1.
    IF sy-subrc = 0.
      rs-url    = ls_row-url.
      rs-gisurl = ls_row-gisurl.
      rs-token  = ls_row-token.
    ENDIF.
  ENDMETHOD.


  METHOD fn_prop.
    FIELD-SYMBOLS <lv_nm>  TYPE any.
    FIELD-SYMBOLS <lt_val> TYPE ANY TABLE.
    FIELD-SYMBOLS <lv_v>   TYPE any.

    LOOP AT it_prop ASSIGNING FIELD-SYMBOL(<ls_p>).

      UNASSIGN <lv_nm>.
      ASSIGN COMPONENT 'PROPERTY_NAME' OF STRUCTURE <ls_p> TO <lv_nm>.
      IF <lv_nm> IS NOT ASSIGNED.
        RETURN.
      ENDIF.

*     CASE-INSENSITIVE on the name. The property names are mixed case in
*     the DPC - 'TitleDeedNumberCO', 'DateValidFrom' - so comparing
*     against a to_upper( ) form would match nothing, and comparing
*     exactly makes every caller carry the exact casing. Both sides are
*     folded instead.
      IF to_upper( CONV string( <lv_nm> ) ) <> to_upper( iv_name ).
        CONTINUE.
      ENDIF.

      UNASSIGN <lt_val>.
      ASSIGN COMPONENT 'VALUES' OF STRUCTURE <ls_p> TO <lt_val>.
      IF <lt_val> IS NOT ASSIGNED.
        RETURN.
      ENDIF.

*     THE FIRST VALUE ONLY, which is what the DPC takes ( values[ 1 ] ).
*     A property with several is not something these six read, and
*     silently joining them would invent a value.
      LOOP AT <lt_val> ASSIGNING <lv_v>.
        rv = condense( CONV string( <lv_v> ) ).
        RETURN.
      ENDLOOP.

      RETURN.
    ENDLOOP.
  ENDMETHOD.


  METHOD details.

*   IDENTITY STILL GOES THROUGH GUARD( ), even though nothing below
*   filters on the guid. It is the one place that says "this journey was
*   launched without a partner" in words rather than by returning nothing,
*   and a details dialog with no partner behind it is the same defect as a
*   parcel list with none.
    guard( EXPORTING iv_owner_guid = iv_owner_guid
           IMPORTING ev_guid       = DATA(lv_guid)
           CHANGING  ct_msg        = rs-msg ).
    IF lv_guid IS INITIAL.
      RETURN.
    ENDIF.

    IF iv_intreno IS INITIAL.
      APPEND VALUE #( type = 'E' message =
        `Property details need the Intreno of the parcel. The parcel list ` &&
        `returns it on every row - carry it through with the parcel id.` )
        TO rs-msg.
      RETURN.
    ENDIF.

*   ---- the partner, as the legacy class wants it ----------------------
*   MS_CTX-PARTNER, not a BUT000 lookup. The DPC re-derives the partner
*   number from the guid because it is handed only a guid; CJS already
*   holds the number - ZCL_RAK_CJ_CTX puts the engine's MV_LOGINBP there -
*   so going back to BUT000 would mean converting the guid string to
*   BU_PARTNER_GUID, which is a raw16 and not something a 32-character hex
*   string assigns to cleanly.
*
*   TYPED BU_PARTNER, and ALPHA-padded into it. The DPC passes the value
*   straight out of a BUT000 SELECT, so that is the type the constructor
*   was written against - and it pads its own before passing one
*   elsewhere in the same class, which says the class expects the padded
*   form.
    DATA lv_bp TYPE bu_partner.
    lv_bp = |{ ms_ctx-partner ALPHA = IN }|.
    IF lv_bp IS INITIAL.
      APPEND VALUE #( type = 'E' message =
        `Property details need the business partner number, and the ` &&
        `journey context carries none. It comes from the launch ` &&
        `parameters through ZCL_RAK_CJ_CTX.` )
        TO rs-msg.
      RETURN.
    ENDIF.

*   ONE TRY AROUND THE WHOLE THING, and every child inside it. These are
*   six reads against RE-FX, FI and ECM through a legacy class this
*   environment cannot compile against - so an exception is a message,
*   never a dump in a dialog the citizen opened to look at a parcel.
*   Partial results are kept deliberately: five tabs filled and one
*   explained beats six blank ones.
    TRY.
        DATA(lo_obj) = NEW zcl_ega_mun_cj_odata_api( partner = lv_bp ).

*       NARROW TO THIS PARCEL FIRST, exactly as the DPC does. The
*       constructor loads every property the partner holds, and
*       GET_PROJECTS( ) has no intreno parameter - it works off whatever
*       is left in PROPERTIES. Without this the Active Projects count is
*       every project on every parcel the citizen owns.
        DELETE lo_obj->properties WHERE intreno <> iv_intreno.

*       ---- ToPartner ----------------------------------------------
*       CONV #( ) because the formal parameter is a DDIC type and
*       IV_INTRENO is a string: parameters here bind BY REFERENCE, so a
*       string against a CHAR13 is a syntax error rather than a
*       conversion. The DPC writes CONV #( ) at the same call for the
*       same reason.
        DATA(lt_bp) = lo_obj->get_partners( intreno = CONV #( iv_intreno ) ).
        CREATE DATA rs-partners LIKE lt_bp.
        ASSIGN rs-partners->* TO FIELD-SYMBOL(<lt_bp>).
        IF <lt_bp> IS ASSIGNED.
          <lt_bp> = lt_bp.
        ENDIF.

*       ---- ToMeasurement ------------------------------------------
        DATA(lt_ms) = lo_obj->get_meas( intreno = CONV #( iv_intreno ) ).
        CREATE DATA rs-measure LIKE lt_ms.
        ASSIGN rs-measure->* TO FIELD-SYMBOL(<lt_ms>).
        IF <lt_ms> IS ASSIGNED.
          <lt_ms> = lt_ms.
        ENDIF.

*       ---- ToLandUse ----------------------------------------------
        DATA(lt_ch) = lo_obj->get_chars( intreno = CONV #( iv_intreno ) ).
        CREATE DATA rs-landuse LIKE lt_ch.
        ASSIGN rs-landuse->* TO FIELD-SYMBOL(<lt_ch>).
        IF <lt_ch> IS ASSIGNED.
          <lt_ch> = lt_ch.
        ENDIF.

*       ---- ToDevelopment ------------------------------------------
*       KEYED ON OBJNR, NOT INTRENO - the one child that is, and the DPC
*       resolves it with this same SELECT. A parcel with no VILMPL row
*       leaves the tab empty rather than reading somebody else's
*       buildings, which is what passing an initial OBJNR would risk.
        SELECT SINGLE objnr FROM vilmpl INTO @DATA(lv_objnr)
          WHERE intreno = @iv_intreno.
        IF sy-subrc = 0 AND lv_objnr IS NOT INITIAL.
          DATA(lt_dv) = lo_obj->get_assobj( objnr = lv_objnr ).
          CREATE DATA rs-develop LIKE lt_dv.
          ASSIGN rs-develop->* TO FIELD-SYMBOL(<lt_dv>).
          IF <lt_dv> IS ASSIGNED.
            <lt_dv> = lt_dv.
          ENDIF.
        ENDIF.

*       ---- ToProject ----------------------------------------------
*       EXPORTING-only, so the variable is declared rather than inlined
*       in the call - an inline DATA( ) in the IMPORTING part of a
*       functional call that is itself an assignment source is refused,
*       and this shape sidesteps that whole question.
*
*       INLINE DATA( ), AND NOT A TYPE OF MY CHOOSING. This was written
*       as `DATA lt_pj TYPE ztt_ega_ao_list` first, on the strength of an
*       `aos TYPE ztt_ega_ao_list` declaration sitting near the call in
*       the DPC - but the DPC does not pass AOS here. It writes
*       `IMPORTING projects = DATA(proj)`, so that type was a guess about
*       a shape this environment cannot read, which is the one mistake
*       this file's header is entirely about.
*
*       The inline form takes whatever the method declares and needs to
*       know nothing. CLAUDE.md's inline-DATA trap does not apply: it is
*       about an inline declaration in the IMPORTING part of a FUNCTIONAL
*       call that is itself an assignment's source, and this is a plain
*       method call statement - which is exactly how the DPC writes it.
        TRY.
            lo_obj->get_projects( IMPORTING projects = DATA(lt_pj) ).
            CREATE DATA rs-project LIKE lt_pj.
            ASSIGN rs-project->* TO FIELD-SYMBOL(<lt_pj>).
            IF <lt_pj> IS ASSIGNED.
              <lt_pj> = lt_pj.
            ENDIF.
          CATCH cx_root INTO DATA(lx_pj).
*           ITS OWN CATCH. GET_PROJECTS( ) reaches furthest of the six -
*           ZDT_EGA_CAAT_PRM, the case table and ZP00( ) - so it is the
*           most likely to raise, and one failure there should not cost
*           the five tabs already filled above.
            to_msg( EXPORTING io_exc = lx_pj CHANGING ct_msg = rs-msg ).
        ENDTRY.
*       ---- ToAttachment -------------------------------------------
*       GET_FILENET_DOCS IS **PRIVATE**, NOT PROTECTED, and this block
*       said otherwise and would not activate: "Method GET_FILENET_DOCS
*       is unknown or PROTECTED or PRIVATE". The DPC's own signature
*       comment says `Instance Private Method`, and its declaration sits
*       after `private section` - so inheriting the class buys nothing
*       here, unlike the _GET_ENTITYSET methods, which really are
*       protected.
*
*       SO DO WHAT IT DOES. The method is a thin one and every piece of
*       it is reachable: ZCL_EGA_FILENET_HNDLR->SEARCH_TITLE_DEED( ) for
*       the documents, then a filter on the parcel number or the AOID.
*       The two GET_PL_HEADER( ) / GET_AO_HEADER( ) cross-checks it also
*       does are dropped deliberately - they verify the document belongs
*       to a parcel the partner holds, and IV_PARCEL here came from the
*       partner's own list, so it is a check against a fact already
*       established.
*
*       AND THE ROW TYPE IS OURS. TT_FNDOC and TY_FNDOC are private on
*       the DPC too, so there is nothing to reuse - TY_DOC_ROW is
*       declared in this class, which means nothing about it is a guess.
        IF iv_parcel IS NOT INITIAL OR iv_aoid IS NOT INITIAL.

*         ALPHA-PADDED, because the document carries the padded form.
*         The DPC pads the value it reads off the document
*         ( parcel = |{ parcel ALPHA = IN }| ) before comparing, so the
*         value compared against has to be padded the same way or a
*         nine-digit card id never matches a twenty-character key.
          DATA lv_pcl TYPE string.
          IF iv_parcel IS NOT INITIAL.
            lv_pcl = |{ iv_parcel ALPHA = IN }|.
          ENDIF.

          TRY.
              DATA lt_dc TYPE tt_doc_rows.

              NEW zcl_ega_filenet_hndlr( )->search_title_deed(
                EXPORTING businesspartner = VALUE #( ( CONV #( lv_bp ) ) )
                IMPORTING out             = DATA(ls_fn) ).

              LOOP AT ls_fn-document ASSIGNING FIELD-SYMBOL(<ls_d>).

*               EVERY PROPERTY READ THROUGH ONE GUARDED HELPER. The DPC
*               reaches into these with chained table expressions -
*               `<fs_d>-property_to[ property_name = 'SAPDocId' ]-values[ 1 ]`
*               - and OPTIONAL there covers only the LAST subscript, so a
*               document missing that property raises
*               CX_SY_ITAB_LINE_NOT_FOUND on the outer one. It happens to
*               hold for the documents that service returns today; it is
*               not something to copy.
                DATA(lv_aoi) = fn_prop( it_prop = <ls_d>-property_to iv_name = `AOID` ).

                DATA(lv_kind) = ``.
                IF lv_aoi IS NOT INITIAL.
*                 A UNIT'S DEED. Compared unpadded - the DPC does not pad
*                 the AOID, only the parcel number.
                  IF lv_aoi <> iv_aoid OR iv_aoid IS INITIAL.
                    CONTINUE.
                  ENDIF.
                  lv_kind = COND string( WHEN ms_ctx-langu = 'A'
                                         THEN `وثيقة تملك وحدة`
                                         ELSE `Title Deed of Unit` ).
                ELSE.
                  DATA(lv_pn) = fn_prop( it_prop = <ls_d>-property_to iv_name = `ParcelNumber` ).
                  IF lv_pn IS NOT INITIAL.
                    lv_pn = |{ lv_pn ALPHA = IN }|.
                  ENDIF.
                  IF lv_pn IS INITIAL OR lv_pn <> lv_pcl.
                    CONTINUE.
                  ENDIF.
                  lv_kind = COND string( WHEN ms_ctx-langu = 'A'
                                         THEN `وثيقة تملك قسيمة`
                                         ELSE `Title Deed of Parcel` ).
                ENDIF.

                APPEND VALUE #(
                  number     = fn_prop( it_prop = <ls_d>-property_to iv_name = `TitleDeedNumberCO` )
                  doctype    = lv_kind
*                 THE DEPARTMENT IS A CONSTANT, not a read. The DPC sets
*                 departmentcode 'MUN' and the name by language on every
*                 row it builds - it is not a property on the document.
                  department = COND string( WHEN ms_ctx-langu = 'A'
                                            THEN `بلدية رأس الخيمة`
                                            ELSE `Municipality` )
                  issuedate  = fn_prop( it_prop = <ls_d>-property_to iv_name = `IssueDate` )
                  validfrom  = fn_prop( it_prop = <ls_d>-property_to iv_name = `DateValidFrom` )
                  validto    = fn_prop( it_prop = <ls_d>-property_to iv_name = `DateValidTo` )
*                 THE ID ONLY, NEVER THE FILE. SAPDocId is what a later
*                 per-row action would hand to ZCL_EGA_FILENET_API to
*                 fetch the content; fetching it here would pull every
*                 document out of ECM as base64 just to draw a list of
*                 numbers.
                  docid      = fn_prop( it_prop = <ls_d>-property_to iv_name = `SAPDocId` ) )
                  TO lt_dc.
              ENDLOOP.

              CREATE DATA rs-attach LIKE lt_dc.
              ASSIGN rs-attach->* TO FIELD-SYMBOL(<lt_dc>).
              IF <lt_dc> IS ASSIGNED.
                <lt_dc> = lt_dc.
              ENDIF.

            CATCH cx_root INTO DATA(lx_dc).
*             ITS OWN CATCH, and for a sharper reason than projects: this
*             one leaves the system. SEARCH_TITLE_DEED( ) is an ECM call,
*             so a slow or unreachable Filenet must not take the five
*             local tabs with it.
              to_msg( EXPORTING io_exc = lx_dc CHANGING ct_msg = rs-msg ).
          ENDTRY.
        ENDIF.

      CATCH cx_root INTO DATA(lx).
        to_msg( EXPORTING io_exc = lx CHANGING ct_msg = rs-msg ).
    ENDTRY.
  ENDMETHOD.


ENDCLASS.
