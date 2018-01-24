--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: intarray; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS intarray WITH SCHEMA public;


--
-- Name: EXTENSION intarray; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION intarray IS 'functions, operators, and index support for 1-D arrays of integers';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: access_control_lists; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE access_control_lists (
    id integer NOT NULL,
    user_group_id integer,
    roles character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    resource_id integer,
    resource_type character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: access_control_lists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE access_control_lists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: access_control_lists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE access_control_lists_id_seq OWNED BY access_control_lists.id;


--
-- Name: aggregations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE aggregations (
    id integer NOT NULL,
    workflow_id integer,
    subject_id integer,
    aggregation jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: aggregations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE aggregations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: aggregations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE aggregations_id_seq OWNED BY aggregations.id;


--
-- Name: authorizations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE authorizations (
    id integer NOT NULL,
    user_id integer,
    provider character varying,
    uid character varying,
    token character varying,
    expires_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: authorizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE authorizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: authorizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE authorizations_id_seq OWNED BY authorizations.id;


--
-- Name: classification_export_rows; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE classification_export_rows (
    id integer NOT NULL,
    classification_id integer NOT NULL,
    project_id integer NOT NULL,
    workflow_id integer NOT NULL,
    user_id integer,
    user_name character varying,
    user_ip character varying,
    workflow_name character varying,
    workflow_version character varying,
    classification_created_at timestamp without time zone,
    gold_standard boolean,
    expert character varying,
    metadata jsonb,
    annotations jsonb,
    subject_data jsonb,
    subject_ids character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: classification_export_rows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE classification_export_rows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: classification_export_rows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE classification_export_rows_id_seq OWNED BY classification_export_rows.id;


--
-- Name: classification_subjects; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE classification_subjects (
    classification_id integer NOT NULL,
    subject_id integer NOT NULL
);


--
-- Name: classifications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE classifications (
    id integer NOT NULL,
    project_id integer,
    user_id integer,
    workflow_id integer,
    annotations jsonb DEFAULT '{}'::jsonb,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_group_id integer,
    user_ip inet,
    completed boolean DEFAULT true NOT NULL,
    gold_standard boolean,
    expert_classifier integer,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    workflow_version text,
    lifecycled_at timestamp without time zone
);


--
-- Name: classifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE classifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: classifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE classifications_id_seq OWNED BY classifications.id;


--
-- Name: code_experiment_configs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE code_experiment_configs (
    id integer NOT NULL,
    name character varying NOT NULL,
    enabled_rate double precision DEFAULT 0.0 NOT NULL,
    always_enabled_for_admins boolean DEFAULT true NOT NULL
);


--
-- Name: code_experiment_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE code_experiment_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: code_experiment_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE code_experiment_configs_id_seq OWNED BY code_experiment_configs.id;


--
-- Name: collections; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE collections (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    activated_state integer DEFAULT 0 NOT NULL,
    display_name character varying,
    private boolean DEFAULT true NOT NULL,
    lock_version integer DEFAULT 0,
    slug character varying DEFAULT ''::character varying,
    favorite boolean DEFAULT false NOT NULL,
    project_ids integer[] DEFAULT '{}'::integer[],
    default_subject_id integer,
    description text DEFAULT ''::text
);


--
-- Name: collections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE collections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: collections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE collections_id_seq OWNED BY collections.id;


--
-- Name: collections_projects; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE collections_projects (
    collection_id integer NOT NULL,
    project_id integer NOT NULL
);


--
-- Name: collections_subjects; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE collections_subjects (
    subject_id integer NOT NULL,
    collection_id integer NOT NULL,
    id integer NOT NULL
);


--
-- Name: collections_subjects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE collections_subjects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: collections_subjects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE collections_subjects_id_seq OWNED BY collections_subjects.id;


--
-- Name: field_guides; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE field_guides (
    id integer NOT NULL,
    items json DEFAULT '[]'::json,
    language text,
    project_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: field_guides_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE field_guides_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: field_guides_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE field_guides_id_seq OWNED BY field_guides.id;


--
-- Name: flipper_features; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE flipper_features (
    id integer NOT NULL,
    key character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: flipper_features_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE flipper_features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flipper_features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE flipper_features_id_seq OWNED BY flipper_features.id;


--
-- Name: flipper_gates; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE flipper_gates (
    id integer NOT NULL,
    feature_key character varying NOT NULL,
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: flipper_gates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE flipper_gates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flipper_gates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE flipper_gates_id_seq OWNED BY flipper_gates.id;


--
-- Name: gold_standard_annotations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE gold_standard_annotations (
    id integer NOT NULL,
    project_id integer,
    workflow_id integer,
    subject_id integer,
    user_id integer,
    classification_id integer,
    annotations json NOT NULL,
    metadata json NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: gold_standard_annotations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE gold_standard_annotations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gold_standard_annotations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE gold_standard_annotations_id_seq OWNED BY gold_standard_annotations.id;


--
-- Name: media; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE media (
    id integer NOT NULL,
    type character varying,
    linked_id integer,
    linked_type character varying,
    content_type character varying,
    src text,
    path_opts text[] DEFAULT '{}'::text[],
    private boolean DEFAULT false,
    external_link boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    metadata jsonb,
    put_expires integer,
    get_expires integer,
    content_disposition character varying
);


--
-- Name: media_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE media_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: media_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE media_id_seq OWNED BY media.id;


--
-- Name: memberships; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE memberships (
    id integer NOT NULL,
    state integer DEFAULT 2 NOT NULL,
    user_group_id integer,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    roles character varying[] DEFAULT '{group_member}'::character varying[] NOT NULL,
    identity boolean DEFAULT false NOT NULL
);


--
-- Name: memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE memberships_id_seq OWNED BY memberships.id;


--
-- Name: oauth_access_grants; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE oauth_access_grants (
    id integer NOT NULL,
    resource_owner_id integer NOT NULL,
    application_id integer NOT NULL,
    token character varying NOT NULL,
    expires_in integer NOT NULL,
    redirect_uri text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    revoked_at timestamp without time zone,
    scopes character varying
);


--
-- Name: oauth_access_grants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE oauth_access_grants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_access_grants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE oauth_access_grants_id_seq OWNED BY oauth_access_grants.id;


--
-- Name: oauth_access_tokens; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE oauth_access_tokens (
    id integer NOT NULL,
    resource_owner_id integer,
    application_id integer,
    token text NOT NULL,
    refresh_token character varying,
    expires_in integer,
    revoked_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    scopes character varying,
    previous_refresh_token character varying
);


--
-- Name: oauth_access_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE oauth_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE oauth_access_tokens_id_seq OWNED BY oauth_access_tokens.id;


--
-- Name: oauth_applications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE oauth_applications (
    id integer NOT NULL,
    name character varying NOT NULL,
    uid character varying NOT NULL,
    secret character varying NOT NULL,
    redirect_uri text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    owner_id integer,
    owner_type character varying,
    trust_level integer DEFAULT 1 NOT NULL,
    default_scope character varying[] DEFAULT '{}'::character varying[],
    scopes character varying DEFAULT ''::character varying NOT NULL
);


--
-- Name: oauth_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE oauth_applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE oauth_applications_id_seq OWNED BY oauth_applications.id;


--
-- Name: organization_contents; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE organization_contents (
    id integer NOT NULL,
    title character varying NOT NULL,
    description character varying NOT NULL,
    introduction text DEFAULT ''::text,
    language character varying NOT NULL,
    organization_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    url_labels jsonb DEFAULT '{}'::jsonb,
    announcement character varying DEFAULT ''::character varying
);


--
-- Name: organization_contents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE organization_contents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organization_contents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE organization_contents_id_seq OWNED BY organization_contents.id;


--
-- Name: organization_pages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE organization_pages (
    id integer NOT NULL,
    url_key character varying,
    title text,
    language character varying,
    content text,
    organization_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: organization_pages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE organization_pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organization_pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE organization_pages_id_seq OWNED BY organization_pages.id;


--
-- Name: organizations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE organizations (
    id integer NOT NULL,
    display_name character varying,
    slug character varying DEFAULT ''::character varying,
    primary_language character varying NOT NULL,
    listed_at timestamp without time zone,
    activated_state integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    urls jsonb DEFAULT '[]'::jsonb,
    listed boolean DEFAULT false NOT NULL,
    categories character varying[] DEFAULT '{}'::character varying[]
);


--
-- Name: organizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE organizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE organizations_id_seq OWNED BY organizations.id;


--
-- Name: project_contents; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE project_contents (
    id integer NOT NULL,
    project_id integer,
    language character varying,
    title character varying DEFAULT ''::character varying,
    description text DEFAULT ''::text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    introduction text DEFAULT ''::text,
    url_labels jsonb DEFAULT '{}'::jsonb,
    workflow_description text DEFAULT ''::text,
    researcher_quote text DEFAULT ''::text
);


--
-- Name: project_contents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE project_contents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_contents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE project_contents_id_seq OWNED BY project_contents.id;


--
-- Name: project_pages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE project_pages (
    id integer NOT NULL,
    url_key character varying,
    title text,
    language character varying,
    content text,
    project_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: project_pages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE project_pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE project_pages_id_seq OWNED BY project_pages.id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE projects (
    id integer NOT NULL,
    name character varying,
    display_name character varying,
    user_count integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    classifications_count integer DEFAULT 0 NOT NULL,
    activated_state integer DEFAULT 0 NOT NULL,
    primary_language character varying,
    private boolean,
    lock_version integer DEFAULT 0,
    configuration jsonb,
    live boolean DEFAULT false NOT NULL,
    urls jsonb DEFAULT '[]'::jsonb,
    migrated boolean DEFAULT false,
    classifiers_count integer DEFAULT 0,
    slug character varying DEFAULT ''::character varying,
    redirect text DEFAULT ''::text,
    launch_requested boolean DEFAULT false,
    launch_approved boolean DEFAULT false,
    beta_requested boolean DEFAULT false,
    beta_approved boolean DEFAULT false,
    launched_row_order integer,
    beta_row_order integer,
    experimental_tools character varying[] DEFAULT '{}'::character varying[],
    launch_date timestamp without time zone,
    completeness double precision DEFAULT 0.0 NOT NULL,
    activity integer DEFAULT 0 NOT NULL,
    tsv tsvector,
    state integer,
    organization_id integer,
    mobile_friendly boolean DEFAULT false NOT NULL,
    featured boolean DEFAULT false NOT NULL
);


--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE projects_id_seq OWNED BY projects.id;


--
-- Name: recents; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE recents (
    id integer NOT NULL,
    classification_id integer,
    subject_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    project_id integer,
    workflow_id integer,
    user_id integer,
    user_group_id integer
);


--
-- Name: recents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE recents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: recents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE recents_id_seq OWNED BY recents.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: set_member_subjects; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE set_member_subjects (
    id integer NOT NULL,
    subject_set_id integer,
    subject_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    priority numeric,
    lock_version integer DEFAULT 0,
    random numeric NOT NULL
);


--
-- Name: set_member_subjects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE set_member_subjects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: set_member_subjects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE set_member_subjects_id_seq OWNED BY set_member_subjects.id;


--
-- Name: subject_sets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE subject_sets (
    id integer NOT NULL,
    display_name character varying,
    project_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    set_member_subjects_count integer DEFAULT 0 NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb,
    lock_version integer DEFAULT 0,
    expert_set boolean
);


--
-- Name: subject_sets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE subject_sets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subject_sets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE subject_sets_id_seq OWNED BY subject_sets.id;


--
-- Name: subject_sets_workflows; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE subject_sets_workflows (
    id integer NOT NULL,
    workflow_id integer,
    subject_set_id integer
);


--
-- Name: subject_sets_workflows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE subject_sets_workflows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subject_sets_workflows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE subject_sets_workflows_id_seq OWNED BY subject_sets_workflows.id;


--
-- Name: subject_workflow_counts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE subject_workflow_counts (
    id integer NOT NULL,
    workflow_id integer,
    classifications_count integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    retired_at timestamp without time zone,
    subject_id integer NOT NULL,
    retirement_reason integer
);


--
-- Name: subject_workflow_counts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE subject_workflow_counts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subject_workflow_counts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE subject_workflow_counts_id_seq OWNED BY subject_workflow_counts.id;


--
-- Name: subjects; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE subjects (
    id integer NOT NULL,
    zooniverse_id character varying,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    project_id integer,
    migrated boolean,
    lock_version integer DEFAULT 0,
    upload_user_id integer,
    activated_state integer DEFAULT 0 NOT NULL
);


--
-- Name: subjects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE subjects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subjects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE subjects_id_seq OWNED BY subjects.id;


--
-- Name: tagged_resources; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tagged_resources (
    id integer NOT NULL,
    resource_id integer,
    resource_type character varying,
    tag_id integer
);


--
-- Name: tagged_resources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tagged_resources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tagged_resources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tagged_resources_id_seq OWNED BY tagged_resources.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tags (
    id integer NOT NULL,
    name text NOT NULL,
    tagged_resources_count integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tags_id_seq OWNED BY tags.id;


--
-- Name: translations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE translations (
    id integer NOT NULL,
    translated_id integer,
    translated_type character varying,
    language character varying NOT NULL,
    strings jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: translations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE translations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: translations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE translations_id_seq OWNED BY translations.id;


--
-- Name: tutorials; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tutorials (
    id integer NOT NULL,
    steps json DEFAULT '[]'::json,
    language text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    project_id integer NOT NULL,
    kind character varying,
    display_name text DEFAULT ''::text
);


--
-- Name: tutorials_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tutorials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tutorials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tutorials_id_seq OWNED BY tutorials.id;


--
-- Name: user_collection_preferences; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_collection_preferences (
    id integer NOT NULL,
    preferences jsonb DEFAULT '{}'::jsonb,
    user_id integer,
    collection_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: user_collection_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_collection_preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_collection_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_collection_preferences_id_seq OWNED BY user_collection_preferences.id;


--
-- Name: user_groups; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_groups (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    classifications_count integer DEFAULT 0 NOT NULL,
    activated_state integer DEFAULT 0 NOT NULL,
    display_name character varying,
    private boolean DEFAULT true NOT NULL,
    lock_version integer DEFAULT 0,
    join_token character varying
);


--
-- Name: user_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_groups_id_seq OWNED BY user_groups.id;


--
-- Name: user_project_preferences; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_project_preferences (
    id integer NOT NULL,
    user_id integer,
    project_id integer,
    email_communication boolean,
    preferences jsonb DEFAULT '{}'::jsonb,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    activity_count integer,
    legacy_count jsonb DEFAULT '{}'::jsonb,
    settings jsonb DEFAULT '{}'::jsonb
);


--
-- Name: user_project_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_project_preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_project_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_project_preferences_id_seq OWNED BY user_project_preferences.id;


--
-- Name: user_seen_subjects; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_seen_subjects (
    id integer NOT NULL,
    user_id integer,
    workflow_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    subject_ids integer[] DEFAULT '{}'::integer[] NOT NULL
);


--
-- Name: user_seen_subjects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_seen_subjects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_seen_subjects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_seen_subjects_id_seq OWNED BY user_seen_subjects.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    email character varying DEFAULT ''::character varying,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    hash_func character varying DEFAULT 'bcrypt'::character varying,
    password_salt character varying,
    display_name character varying,
    zooniverse_id character varying,
    credited_name character varying,
    classifications_count integer DEFAULT 0 NOT NULL,
    activated_state integer DEFAULT 0 NOT NULL,
    languages character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    global_email_communication boolean,
    project_email_communication boolean,
    admin boolean DEFAULT false NOT NULL,
    banned boolean DEFAULT false NOT NULL,
    migrated boolean DEFAULT false,
    valid_email boolean DEFAULT true NOT NULL,
    project_id integer,
    beta_email_communication boolean,
    login character varying NOT NULL,
    unsubscribe_token character varying,
    api_key character varying,
    ouroboros_created boolean DEFAULT false,
    subject_limit integer,
    private_profile boolean DEFAULT true,
    tsv tsvector,
    upload_whitelist boolean DEFAULT false NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE versions (
    id integer NOT NULL,
    item_type character varying NOT NULL,
    item_id integer NOT NULL,
    event character varying NOT NULL,
    whodunnit character varying,
    object text,
    created_at timestamp without time zone,
    object_changes text
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE versions_id_seq OWNED BY versions.id;


--
-- Name: workflow_contents; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE workflow_contents (
    id integer NOT NULL,
    workflow_id integer,
    language character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    strings json DEFAULT '{}'::json NOT NULL,
    current_version_number character varying
);


--
-- Name: workflow_contents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE workflow_contents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflow_contents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE workflow_contents_id_seq OWNED BY workflow_contents.id;


--
-- Name: workflow_tutorials; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE workflow_tutorials (
    id integer NOT NULL,
    workflow_id integer,
    tutorial_id integer
);


--
-- Name: workflow_tutorials_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE workflow_tutorials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflow_tutorials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE workflow_tutorials_id_seq OWNED BY workflow_tutorials.id;


--
-- Name: workflows; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE workflows (
    id integer NOT NULL,
    display_name character varying,
    tasks jsonb DEFAULT '{}'::jsonb,
    project_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    classifications_count integer DEFAULT 0 NOT NULL,
    pairwise boolean DEFAULT false NOT NULL,
    grouped boolean DEFAULT false NOT NULL,
    prioritized boolean DEFAULT false NOT NULL,
    primary_language character varying,
    first_task character varying,
    tutorial_subject_id integer,
    lock_version integer DEFAULT 0,
    retired_set_member_subjects_count integer DEFAULT 0,
    retirement jsonb DEFAULT '{}'::jsonb,
    active boolean DEFAULT true,
    aggregation jsonb DEFAULT '{}'::jsonb NOT NULL,
    display_order integer,
    configuration jsonb DEFAULT '{}'::jsonb NOT NULL,
    public_gold_standard boolean DEFAULT false,
    finished_at timestamp without time zone,
    completeness double precision DEFAULT 0.0 NOT NULL,
    activity integer DEFAULT 0 NOT NULL,
    current_version_number character varying,
    activated_state integer DEFAULT 0 NOT NULL,
    subject_selection_strategy integer DEFAULT 0,
    mobile_friendly boolean DEFAULT false NOT NULL
);


--
-- Name: workflows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE workflows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE workflows_id_seq OWNED BY workflows.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_control_lists ALTER COLUMN id SET DEFAULT nextval('access_control_lists_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY aggregations ALTER COLUMN id SET DEFAULT nextval('aggregations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY authorizations ALTER COLUMN id SET DEFAULT nextval('authorizations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY classification_export_rows ALTER COLUMN id SET DEFAULT nextval('classification_export_rows_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY classifications ALTER COLUMN id SET DEFAULT nextval('classifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY code_experiment_configs ALTER COLUMN id SET DEFAULT nextval('code_experiment_configs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY collections ALTER COLUMN id SET DEFAULT nextval('collections_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY collections_subjects ALTER COLUMN id SET DEFAULT nextval('collections_subjects_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY field_guides ALTER COLUMN id SET DEFAULT nextval('field_guides_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY flipper_features ALTER COLUMN id SET DEFAULT nextval('flipper_features_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY flipper_gates ALTER COLUMN id SET DEFAULT nextval('flipper_gates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY gold_standard_annotations ALTER COLUMN id SET DEFAULT nextval('gold_standard_annotations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY media ALTER COLUMN id SET DEFAULT nextval('media_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY memberships ALTER COLUMN id SET DEFAULT nextval('memberships_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_access_grants ALTER COLUMN id SET DEFAULT nextval('oauth_access_grants_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_access_tokens ALTER COLUMN id SET DEFAULT nextval('oauth_access_tokens_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_applications ALTER COLUMN id SET DEFAULT nextval('oauth_applications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY organization_contents ALTER COLUMN id SET DEFAULT nextval('organization_contents_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY organization_pages ALTER COLUMN id SET DEFAULT nextval('organization_pages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY organizations ALTER COLUMN id SET DEFAULT nextval('organizations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_contents ALTER COLUMN id SET DEFAULT nextval('project_contents_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_pages ALTER COLUMN id SET DEFAULT nextval('project_pages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects ALTER COLUMN id SET DEFAULT nextval('projects_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY recents ALTER COLUMN id SET DEFAULT nextval('recents_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY set_member_subjects ALTER COLUMN id SET DEFAULT nextval('set_member_subjects_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY subject_sets ALTER COLUMN id SET DEFAULT nextval('subject_sets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY subject_sets_workflows ALTER COLUMN id SET DEFAULT nextval('subject_sets_workflows_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY subject_workflow_counts ALTER COLUMN id SET DEFAULT nextval('subject_workflow_counts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY subjects ALTER COLUMN id SET DEFAULT nextval('subjects_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tagged_resources ALTER COLUMN id SET DEFAULT nextval('tagged_resources_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tags ALTER COLUMN id SET DEFAULT nextval('tags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY translations ALTER COLUMN id SET DEFAULT nextval('translations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tutorials ALTER COLUMN id SET DEFAULT nextval('tutorials_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_collection_preferences ALTER COLUMN id SET DEFAULT nextval('user_collection_preferences_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_groups ALTER COLUMN id SET DEFAULT nextval('user_groups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_project_preferences ALTER COLUMN id SET DEFAULT nextval('user_project_preferences_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_seen_subjects ALTER COLUMN id SET DEFAULT nextval('user_seen_subjects_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions ALTER COLUMN id SET DEFAULT nextval('versions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflow_contents ALTER COLUMN id SET DEFAULT nextval('workflow_contents_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflow_tutorials ALTER COLUMN id SET DEFAULT nextval('workflow_tutorials_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflows ALTER COLUMN id SET DEFAULT nextval('workflows_id_seq'::regclass);


--
-- Name: access_control_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY access_control_lists
    ADD CONSTRAINT access_control_lists_pkey PRIMARY KEY (id);


--
-- Name: aggregations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY aggregations
    ADD CONSTRAINT aggregations_pkey PRIMARY KEY (id);


--
-- Name: authorizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY authorizations
    ADD CONSTRAINT authorizations_pkey PRIMARY KEY (id);


--
-- Name: classification_export_rows_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY classification_export_rows
    ADD CONSTRAINT classification_export_rows_pkey PRIMARY KEY (id);


--
-- Name: classifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY classifications
    ADD CONSTRAINT classifications_pkey PRIMARY KEY (id);


--
-- Name: code_experiment_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY code_experiment_configs
    ADD CONSTRAINT code_experiment_configs_pkey PRIMARY KEY (id);


--
-- Name: collections_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY collections
    ADD CONSTRAINT collections_pkey PRIMARY KEY (id);


--
-- Name: collections_subjects_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY collections_subjects
    ADD CONSTRAINT collections_subjects_pkey PRIMARY KEY (id);


--
-- Name: field_guides_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY field_guides
    ADD CONSTRAINT field_guides_pkey PRIMARY KEY (id);


--
-- Name: flipper_features_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY flipper_features
    ADD CONSTRAINT flipper_features_pkey PRIMARY KEY (id);


--
-- Name: flipper_gates_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY flipper_gates
    ADD CONSTRAINT flipper_gates_pkey PRIMARY KEY (id);


--
-- Name: gold_standard_annotations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY gold_standard_annotations
    ADD CONSTRAINT gold_standard_annotations_pkey PRIMARY KEY (id);


--
-- Name: media_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY media
    ADD CONSTRAINT media_pkey PRIMARY KEY (id);


--
-- Name: memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY memberships
    ADD CONSTRAINT memberships_pkey PRIMARY KEY (id);


--
-- Name: oauth_access_grants_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY oauth_access_grants
    ADD CONSTRAINT oauth_access_grants_pkey PRIMARY KEY (id);


--
-- Name: oauth_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY oauth_access_tokens
    ADD CONSTRAINT oauth_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: oauth_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY oauth_applications
    ADD CONSTRAINT oauth_applications_pkey PRIMARY KEY (id);


--
-- Name: organization_contents_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY organization_contents
    ADD CONSTRAINT organization_contents_pkey PRIMARY KEY (id);


--
-- Name: organization_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY organization_pages
    ADD CONSTRAINT organization_pages_pkey PRIMARY KEY (id);


--
-- Name: organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: project_contents_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY project_contents
    ADD CONSTRAINT project_contents_pkey PRIMARY KEY (id);


--
-- Name: project_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY project_pages
    ADD CONSTRAINT project_pages_pkey PRIMARY KEY (id);


--
-- Name: projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: recents_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY recents
    ADD CONSTRAINT recents_pkey PRIMARY KEY (id);


--
-- Name: set_member_subjects_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY set_member_subjects
    ADD CONSTRAINT set_member_subjects_pkey PRIMARY KEY (id);


--
-- Name: subject_sets_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY subject_sets
    ADD CONSTRAINT subject_sets_pkey PRIMARY KEY (id);


--
-- Name: subject_sets_workflows_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY subject_sets_workflows
    ADD CONSTRAINT subject_sets_workflows_pkey PRIMARY KEY (id);


--
-- Name: subject_workflow_counts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY subject_workflow_counts
    ADD CONSTRAINT subject_workflow_counts_pkey PRIMARY KEY (id);


--
-- Name: subjects_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY subjects
    ADD CONSTRAINT subjects_pkey PRIMARY KEY (id);


--
-- Name: tagged_resources_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tagged_resources
    ADD CONSTRAINT tagged_resources_pkey PRIMARY KEY (id);


--
-- Name: tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: translations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY translations
    ADD CONSTRAINT translations_pkey PRIMARY KEY (id);


--
-- Name: tutorials_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tutorials
    ADD CONSTRAINT tutorials_pkey PRIMARY KEY (id);


--
-- Name: user_collection_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_collection_preferences
    ADD CONSTRAINT user_collection_preferences_pkey PRIMARY KEY (id);


--
-- Name: user_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_groups
    ADD CONSTRAINT user_groups_pkey PRIMARY KEY (id);


--
-- Name: user_project_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_project_preferences
    ADD CONSTRAINT user_project_preferences_pkey PRIMARY KEY (id);


--
-- Name: user_seen_subjects_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_seen_subjects
    ADD CONSTRAINT user_seen_subjects_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: workflow_contents_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY workflow_contents
    ADD CONSTRAINT workflow_contents_pkey PRIMARY KEY (id);


--
-- Name: workflow_tutorials_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY workflow_tutorials
    ADD CONSTRAINT workflow_tutorials_pkey PRIMARY KEY (id);


--
-- Name: workflows_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY workflows
    ADD CONSTRAINT workflows_pkey PRIMARY KEY (id);


--
-- Name: classification_subjects_pk; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX classification_subjects_pk ON classification_subjects USING btree (classification_id, subject_id);


--
-- Name: idx_lower_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX idx_lower_email ON users USING btree (lower((email)::text));


--
-- Name: idx_translations_on_translated_type+id_and_language; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX "idx_translations_on_translated_type+id_and_language" ON translations USING btree (translated_type, translated_id, language);


--
-- Name: index_access_control_lists_on_resource_id_and_resource_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_access_control_lists_on_resource_id_and_resource_type ON access_control_lists USING btree (resource_id, resource_type);


--
-- Name: index_access_control_lists_on_user_group_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_access_control_lists_on_user_group_id ON access_control_lists USING btree (user_group_id);


--
-- Name: index_aggregations_on_subject_id_and_workflow_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_aggregations_on_subject_id_and_workflow_id ON aggregations USING btree (subject_id, workflow_id);


--
-- Name: index_aggregations_on_workflow_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_aggregations_on_workflow_id ON aggregations USING btree (workflow_id);


--
-- Name: index_authorizations_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_authorizations_on_user_id ON authorizations USING btree (user_id);


--
-- Name: index_classification_export_rows_on_classification_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_classification_export_rows_on_classification_id ON classification_export_rows USING btree (classification_id);


--
-- Name: index_classification_export_rows_on_project_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_classification_export_rows_on_project_id ON classification_export_rows USING btree (project_id);


--
-- Name: index_classification_export_rows_on_workflow_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_classification_export_rows_on_workflow_id ON classification_export_rows USING btree (workflow_id);


--
-- Name: index_classification_subjects_on_subject_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_classification_subjects_on_subject_id ON classification_subjects USING btree (subject_id);


--
-- Name: index_classifications_on_completed; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_classifications_on_completed ON classifications USING btree (completed) WHERE (completed IS FALSE);


--
-- Name: index_classifications_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_classifications_on_created_at ON classifications USING btree (created_at);


--
-- Name: index_classifications_on_gold_standard; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_classifications_on_gold_standard ON classifications USING btree (gold_standard) WHERE (gold_standard IS TRUE);


--
-- Name: index_classifications_on_lifecycled_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_classifications_on_lifecycled_at ON classifications USING btree (lifecycled_at) WHERE (lifecycled_at IS NULL);


--
-- Name: index_classifications_on_project_id_and_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_classifications_on_project_id_and_id ON classifications USING btree (project_id, id);


--
-- Name: index_classifications_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_classifications_on_user_id ON classifications USING btree (user_id);


--
-- Name: index_classifications_on_workflow_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_classifications_on_workflow_id ON classifications USING btree (workflow_id);


--
-- Name: index_code_experiment_configs_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_code_experiment_configs_on_name ON code_experiment_configs USING btree (name);


--
-- Name: index_collections_display_name_trgrm; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_collections_display_name_trgrm ON collections USING gin ((COALESCE((display_name)::text, ''::text)) gin_trgm_ops);


--
-- Name: index_collections_on_activated_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_collections_on_activated_state ON collections USING btree (activated_state);


--
-- Name: index_collections_on_display_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_collections_on_display_name ON collections USING btree (display_name);


--
-- Name: index_collections_on_favorite; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_collections_on_favorite ON collections USING btree (favorite);


--
-- Name: index_collections_on_private; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_collections_on_private ON collections USING btree (private);


--
-- Name: index_collections_on_project_ids; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_collections_on_project_ids ON collections USING gin (project_ids);


--
-- Name: index_collections_on_slug; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_collections_on_slug ON collections USING btree (slug);


--
-- Name: index_collections_projects_on_collection_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_collections_projects_on_collection_id ON collections_projects USING btree (collection_id);


--
-- Name: index_collections_subjects_on_collection_id_and_subject_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_collections_subjects_on_collection_id_and_subject_id ON collections_subjects USING btree (collection_id, subject_id);


--
-- Name: index_collections_subjects_on_subject_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_collections_subjects_on_subject_id ON collections_subjects USING btree (subject_id);


--
-- Name: index_field_guides_on_language; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_field_guides_on_language ON field_guides USING btree (language);


--
-- Name: index_field_guides_on_project_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_field_guides_on_project_id ON field_guides USING btree (project_id);


--
-- Name: index_flipper_features_on_key; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_flipper_features_on_key ON flipper_features USING btree (key);


--
-- Name: index_flipper_gates_on_feature_key_and_key_and_value; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_flipper_gates_on_feature_key_and_key_and_value ON flipper_gates USING btree (feature_key, key, value);


--
-- Name: index_gold_standard_annotations_on_subject_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_gold_standard_annotations_on_subject_id ON gold_standard_annotations USING btree (subject_id);


--
-- Name: index_gold_standard_annotations_on_workflow_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_gold_standard_annotations_on_workflow_id ON gold_standard_annotations USING btree (workflow_id);


--
-- Name: index_media_on_linked_id_and_linked_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_media_on_linked_id_and_linked_type ON media USING btree (linked_id, linked_type);


--
-- Name: index_media_on_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_media_on_type ON media USING btree (type);


--
-- Name: index_memberships_on_user_group_id_and_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_memberships_on_user_group_id_and_user_id ON memberships USING btree (user_group_id, user_id);


--
-- Name: index_memberships_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_memberships_on_user_id ON memberships USING btree (user_id);


--
-- Name: index_oauth_access_grants_on_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_oauth_access_grants_on_token ON oauth_access_grants USING btree (token);


--
-- Name: index_oauth_access_tokens_on_app_id_and_owner_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_oauth_access_tokens_on_app_id_and_owner_id ON oauth_access_tokens USING btree (application_id, resource_owner_id);


--
-- Name: index_oauth_access_tokens_on_refresh_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_oauth_access_tokens_on_refresh_token ON oauth_access_tokens USING btree (refresh_token);


--
-- Name: index_oauth_access_tokens_on_resource_owner_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_oauth_access_tokens_on_resource_owner_id ON oauth_access_tokens USING btree (resource_owner_id);


--
-- Name: index_oauth_access_tokens_on_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_oauth_access_tokens_on_token ON oauth_access_tokens USING btree (token);


--
-- Name: index_oauth_applications_on_uid; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_oauth_applications_on_uid ON oauth_applications USING btree (uid);


--
-- Name: index_organization_pages_on_language; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_organization_pages_on_language ON organization_pages USING btree (language);


--
-- Name: index_organization_pages_on_organization_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_organization_pages_on_organization_id ON organization_pages USING btree (organization_id);


--
-- Name: index_organizations_on_activated_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_organizations_on_activated_state ON organizations USING btree (activated_state);


--
-- Name: index_organizations_on_display_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_organizations_on_display_name ON organizations USING btree (display_name);


--
-- Name: index_organizations_on_listed; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_organizations_on_listed ON organizations USING btree (listed);


--
-- Name: index_organizations_on_listed_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_organizations_on_listed_at ON organizations USING btree (listed_at);


--
-- Name: index_organizations_on_slug; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_organizations_on_slug ON organizations USING btree (slug);


--
-- Name: index_organizations_on_updated_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_organizations_on_updated_at ON organizations USING btree (updated_at);


--
-- Name: index_project_contents_on_project_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_project_contents_on_project_id ON project_contents USING btree (project_id);


--
-- Name: index_project_pages_on_language; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_project_pages_on_language ON project_pages USING btree (language);


--
-- Name: index_project_pages_on_project_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_project_pages_on_project_id ON project_pages USING btree (project_id);


--
-- Name: index_projects_display_name_trgrm; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_projects_display_name_trgrm ON projects USING gin ((COALESCE((display_name)::text, ''::text)) gin_trgm_ops);


--
-- Name: index_projects_on_activated_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_projects_on_activated_state ON projects USING btree (activated_state);


--
-- Name: index_projects_on_beta_approved; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_projects_on_beta_approved ON projects USING btree (beta_approved);


--
-- Name: index_projects_on_beta_requested; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_projects_on_beta_requested ON projects USING btree (beta_requested) WHERE (beta_requested = true);


--
-- Name: index_projects_on_beta_row_order; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_projects_on_beta_row_order ON projects USING btree (beta_row_order);


--
-- Name: index_projects_on_featured; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_projects_on_featured ON projects USING btree (featured);


--
-- Name: index_projects_on_launch_approved; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_projects_on_launch_approved ON projects USING btree (launch_approved);


--
-- Name: index_projects_on_launch_requested; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_projects_on_launch_requested ON projects USING btree (launch_requested) WHERE (launch_requested = true);


--
-- Name: index_projects_on_launched_row_order; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_projects_on_launched_row_order ON projects USING btree (launched_row_order);


--
-- Name: index_projects_on_live; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_projects_on_live ON projects USING btree (live);


--
-- Name: index_projects_on_migrated; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_projects_on_migrated ON projects USING btree (migrated) WHERE (migrated = true);


--
-- Name: index_projects_on_mobile_friendly; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_projects_on_mobile_friendly ON projects USING btree (mobile_friendly);


--
-- Name: index_projects_on_organization_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_projects_on_organization_id ON projects USING btree (organization_id);


--
-- Name: index_projects_on_private; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_projects_on_private ON projects USING btree (private);


--
-- Name: index_projects_on_slug; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_projects_on_slug ON projects USING btree (slug);


--
-- Name: index_projects_on_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_projects_on_state ON projects USING btree (state) WHERE (state IS NOT NULL);


--
-- Name: index_projects_on_tsv; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_projects_on_tsv ON projects USING gin (tsv);


--
-- Name: index_recents_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_recents_on_created_at ON recents USING btree (created_at);


--
-- Name: index_recents_on_project_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_recents_on_project_id ON recents USING btree (project_id);


--
-- Name: index_recents_on_subject_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_recents_on_subject_id ON recents USING btree (subject_id);


--
-- Name: index_recents_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_recents_on_user_id ON recents USING btree (user_id);


--
-- Name: index_recents_on_workflow_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_recents_on_workflow_id ON recents USING btree (workflow_id);


--
-- Name: index_set_member_subjects_on_random; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_set_member_subjects_on_random ON set_member_subjects USING btree (random);


--
-- Name: index_set_member_subjects_on_subject_id_and_subject_set_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_set_member_subjects_on_subject_id_and_subject_set_id ON set_member_subjects USING btree (subject_id, subject_set_id);


--
-- Name: index_set_member_subjects_on_subject_set_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_set_member_subjects_on_subject_set_id ON set_member_subjects USING btree (subject_set_id);


--
-- Name: index_subject_sets_on_metadata; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_subject_sets_on_metadata ON subject_sets USING gin (metadata);


--
-- Name: index_subject_sets_on_project_id_and_display_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_subject_sets_on_project_id_and_display_name ON subject_sets USING btree (project_id, display_name);


--
-- Name: index_subject_sets_workflows_on_subject_set_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_subject_sets_workflows_on_subject_set_id ON subject_sets_workflows USING btree (subject_set_id);


--
-- Name: index_subject_sets_workflows_on_workflow_id_and_subject_set_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_subject_sets_workflows_on_workflow_id_and_subject_set_id ON subject_sets_workflows USING btree (workflow_id, subject_set_id);


--
-- Name: index_subject_workflow_counts_on_subject_id_and_workflow_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_subject_workflow_counts_on_subject_id_and_workflow_id ON subject_workflow_counts USING btree (subject_id, workflow_id);


--
-- Name: index_subject_workflow_counts_on_workflow_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_subject_workflow_counts_on_workflow_id ON subject_workflow_counts USING btree (workflow_id);


--
-- Name: index_subjects_on_project_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_subjects_on_project_id ON subjects USING btree (project_id);


--
-- Name: index_subjects_on_upload_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_subjects_on_upload_user_id ON subjects USING btree (upload_user_id);


--
-- Name: index_tagged_resources_on_resource_id_and_resource_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tagged_resources_on_resource_id_and_resource_type ON tagged_resources USING btree (resource_id, resource_type);


--
-- Name: index_tagged_resources_on_tag_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tagged_resources_on_tag_id ON tagged_resources USING btree (tag_id);


--
-- Name: index_tags_name_trgrm; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tags_name_trgrm ON tags USING gin ((COALESCE(name, ''::text)) gin_trgm_ops);


--
-- Name: index_tags_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_tags_on_name ON tags USING btree (name);


--
-- Name: index_tutorials_on_kind; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tutorials_on_kind ON tutorials USING btree (kind);


--
-- Name: index_tutorials_on_language; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tutorials_on_language ON tutorials USING btree (language);


--
-- Name: index_tutorials_on_project_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tutorials_on_project_id ON tutorials USING btree (project_id);


--
-- Name: index_user_collection_preferences_on_collection_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_user_collection_preferences_on_collection_id ON user_collection_preferences USING btree (collection_id);


--
-- Name: index_user_collection_preferences_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_user_collection_preferences_on_user_id ON user_collection_preferences USING btree (user_id);


--
-- Name: index_user_groups_display_name_trgrm; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_user_groups_display_name_trgrm ON user_groups USING gin ((COALESCE((display_name)::text, ''::text)) gin_trgm_ops);


--
-- Name: index_user_groups_on_activated_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_user_groups_on_activated_state ON user_groups USING btree (activated_state);


--
-- Name: index_user_groups_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_user_groups_on_name ON user_groups USING btree (lower((name)::text));


--
-- Name: index_user_groups_on_private; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_user_groups_on_private ON user_groups USING btree (private);


--
-- Name: index_user_project_preferences_on_user_id_and_project_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_user_project_preferences_on_user_id_and_project_id ON user_project_preferences USING btree (user_id, project_id);


--
-- Name: index_user_seen_subjects_on_user_id_and_workflow_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_user_seen_subjects_on_user_id_and_workflow_id ON user_seen_subjects USING btree (user_id, workflow_id);


--
-- Name: index_users_on_activated_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_activated_state ON users USING btree (activated_state);


--
-- Name: index_users_on_beta_email_communication; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_beta_email_communication ON users USING btree (beta_email_communication) WHERE (beta_email_communication = true);


--
-- Name: index_users_on_display_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_display_name ON users USING btree (lower((display_name)::text));


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_global_email_communication; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_global_email_communication ON users USING btree (global_email_communication) WHERE (global_email_communication = true);


--
-- Name: index_users_on_login; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_login ON users USING btree (lower((login)::text));


--
-- Name: index_users_on_login_with_case; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_login_with_case ON users USING btree (login);


--
-- Name: index_users_on_lower_names; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_lower_names ON users USING btree (lower((login)::text) text_pattern_ops, lower((display_name)::text) text_pattern_ops);


--
-- Name: index_users_on_private_profile; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_private_profile ON users USING btree (private_profile) WHERE (private_profile = false);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: index_users_on_tsv; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_tsv ON users USING gin (tsv);


--
-- Name: index_users_on_unsubscribe_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_unsubscribe_token ON users USING btree (unsubscribe_token);


--
-- Name: index_users_on_zooniverse_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_zooniverse_id ON users USING btree (zooniverse_id);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_versions_on_item_type_and_item_id ON versions USING btree (item_type, item_id);


--
-- Name: index_workflow_contents_on_workflow_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workflow_contents_on_workflow_id ON workflow_contents USING btree (workflow_id);


--
-- Name: index_workflow_tutorials_on_tutorial_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workflow_tutorials_on_tutorial_id ON workflow_tutorials USING btree (tutorial_id);


--
-- Name: index_workflow_tutorials_on_workflow_id_and_tutorial_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_workflow_tutorials_on_workflow_id_and_tutorial_id ON workflow_tutorials USING btree (workflow_id, tutorial_id);


--
-- Name: index_workflows_on_activated_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workflows_on_activated_state ON workflows USING btree (activated_state);


--
-- Name: index_workflows_on_aggregation; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workflows_on_aggregation ON workflows USING btree (((aggregation ->> 'public'::text)));


--
-- Name: index_workflows_on_display_order; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workflows_on_display_order ON workflows USING btree (display_order);


--
-- Name: index_workflows_on_mobile_friendly; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workflows_on_mobile_friendly ON workflows USING btree (mobile_friendly);


--
-- Name: index_workflows_on_project_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workflows_on_project_id ON workflows USING btree (project_id);


--
-- Name: index_workflows_on_public_gold_standard; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workflows_on_public_gold_standard ON workflows USING btree (public_gold_standard) WHERE (public_gold_standard IS TRUE);


--
-- Name: index_workflows_on_tutorial_subject_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workflows_on_tutorial_subject_id ON workflows USING btree (tutorial_subject_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: users_idx_trgm_login; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_idx_trgm_login ON users USING gin ((COALESCE((login)::text, ''::text)) gin_trgm_ops);


--
-- Name: tsvectorupdate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tsvectorupdate BEFORE INSERT OR UPDATE ON projects FOR EACH ROW EXECUTE PROCEDURE tsvector_update_trigger('tsv', 'pg_catalog.english', 'display_name');


--
-- Name: tsvectorupdate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tsvectorupdate BEFORE INSERT OR UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE tsvector_update_trigger('tsv', 'pg_catalog.english', 'login');


--
-- Name: fk_rails_02f2e5d7ed; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_collection_preferences
    ADD CONSTRAINT fk_rails_02f2e5d7ed FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_038f6f9f13; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY subject_sets_workflows
    ADD CONSTRAINT fk_rails_038f6f9f13 FOREIGN KEY (workflow_id) REFERENCES workflows(id);


--
-- Name: fk_rails_06fc22e4c3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gold_standard_annotations
    ADD CONSTRAINT fk_rails_06fc22e4c3 FOREIGN KEY (classification_id) REFERENCES classifications(id);


--
-- Name: fk_rails_082b4f1af7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gold_standard_annotations
    ADD CONSTRAINT fk_rails_082b4f1af7 FOREIGN KEY (project_id) REFERENCES projects(id);


--
-- Name: fk_rails_0be1922a0e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_control_lists
    ADD CONSTRAINT fk_rails_0be1922a0e FOREIGN KEY (user_group_id) REFERENCES user_groups(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_0ca158de43; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflow_tutorials
    ADD CONSTRAINT fk_rails_0ca158de43 FOREIGN KEY (tutorial_id) REFERENCES tutorials(id) ON DELETE CASCADE;


--
-- Name: fk_rails_0e782fcb3c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gold_standard_annotations
    ADD CONSTRAINT fk_rails_0e782fcb3c FOREIGN KEY (subject_id) REFERENCES subjects(id);


--
-- Name: fk_rails_107209726e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflow_contents
    ADD CONSTRAINT fk_rails_107209726e FOREIGN KEY (workflow_id) REFERENCES workflows(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_1be0872ee9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collections_projects
    ADD CONSTRAINT fk_rails_1be0872ee9 FOREIGN KEY (collection_id) REFERENCES collections(id);


--
-- Name: fk_rails_1d218ca624; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gold_standard_annotations
    ADD CONSTRAINT fk_rails_1d218ca624 FOREIGN KEY (workflow_id) REFERENCES workflows(id);


--
-- Name: fk_rails_1e54468460; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY recents
    ADD CONSTRAINT fk_rails_1e54468460 FOREIGN KEY (classification_id) REFERENCES classifications(id);


--
-- Name: fk_rails_2001a01c81; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY subject_workflow_counts
    ADD CONSTRAINT fk_rails_2001a01c81 FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE RESTRICT;


--
-- Name: fk_rails_27ae8e8a0d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY aggregations
    ADD CONSTRAINT fk_rails_27ae8e8a0d FOREIGN KEY (workflow_id) REFERENCES workflows(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_28a7ada458; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY aggregations
    ADD CONSTRAINT fk_rails_28a7ada458 FOREIGN KEY (subject_id) REFERENCES subjects(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_305e6d8bf1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_contents
    ADD CONSTRAINT fk_rails_305e6d8bf1 FOREIGN KEY (project_id) REFERENCES projects(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_330c32d8d9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_access_grants
    ADD CONSTRAINT fk_rails_330c32d8d9 FOREIGN KEY (resource_owner_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_382d2c48c7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflows
    ADD CONSTRAINT fk_rails_382d2c48c7 FOREIGN KEY (project_id) REFERENCES projects(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_489b3ea925; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_pages
    ADD CONSTRAINT fk_rails_489b3ea925 FOREIGN KEY (project_id) REFERENCES projects(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_4a73c0f7f5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY subject_workflow_counts
    ADD CONSTRAINT fk_rails_4a73c0f7f5 FOREIGN KEY (workflow_id) REFERENCES workflows(id);


--
-- Name: fk_rails_4da2a0f9d6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_project_preferences
    ADD CONSTRAINT fk_rails_4da2a0f9d6 FOREIGN KEY (project_id) REFERENCES projects(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_4e8620169e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_project_preferences
    ADD CONSTRAINT fk_rails_4e8620169e FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_4ecef5b8c5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY authorizations
    ADD CONSTRAINT fk_rails_4ecef5b8c5 FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_5244e2cc55; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY recents
    ADD CONSTRAINT fk_rails_5244e2cc55 FOREIGN KEY (subject_id) REFERENCES subjects(id);


--
-- Name: fk_rails_670188dbc7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_collection_preferences
    ADD CONSTRAINT fk_rails_670188dbc7 FOREIGN KEY (collection_id) REFERENCES collections(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_732cb83ab7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_access_tokens
    ADD CONSTRAINT fk_rails_732cb83ab7 FOREIGN KEY (application_id) REFERENCES oauth_applications(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_7c8fb1018a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY classification_subjects
    ADD CONSTRAINT fk_rails_7c8fb1018a FOREIGN KEY (classification_id) REFERENCES classifications(id);


--
-- Name: fk_rails_82e4d0479b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tutorials
    ADD CONSTRAINT fk_rails_82e4d0479b FOREIGN KEY (project_id) REFERENCES projects(id);


--
-- Name: fk_rails_895b025564; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collections_projects
    ADD CONSTRAINT fk_rails_895b025564 FOREIGN KEY (project_id) REFERENCES projects(id);


--
-- Name: fk_rails_93073bf3b1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY set_member_subjects
    ADD CONSTRAINT fk_rails_93073bf3b1 FOREIGN KEY (subject_id) REFERENCES subjects(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_937b47dc37; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gold_standard_annotations
    ADD CONSTRAINT fk_rails_937b47dc37 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_960d10a3c6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY subject_sets
    ADD CONSTRAINT fk_rails_960d10a3c6 FOREIGN KEY (project_id) REFERENCES projects(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_991d5ad7ab; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collections
    ADD CONSTRAINT fk_rails_991d5ad7ab FOREIGN KEY (default_subject_id) REFERENCES subjects(id);


--
-- Name: fk_rails_99326fb65d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY memberships
    ADD CONSTRAINT fk_rails_99326fb65d FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_9aee26923d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT fk_rails_9aee26923d FOREIGN KEY (organization_id) REFERENCES organizations(id);


--
-- Name: fk_rails_9c86377aa8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_seen_subjects
    ADD CONSTRAINT fk_rails_9c86377aa8 FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_9dd81aaaa3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY memberships
    ADD CONSTRAINT fk_rails_9dd81aaaa3 FOREIGN KEY (user_group_id) REFERENCES user_groups(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_a1b35288b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY field_guides
    ADD CONSTRAINT fk_rails_a1b35288b8 FOREIGN KEY (project_id) REFERENCES projects(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_b029d72783; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflows
    ADD CONSTRAINT fk_rails_b029d72783 FOREIGN KEY (tutorial_subject_id) REFERENCES subjects(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_b08d342668; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY subject_sets_workflows
    ADD CONSTRAINT fk_rails_b08d342668 FOREIGN KEY (subject_set_id) REFERENCES subject_sets(id);


--
-- Name: fk_rails_b4b53e07b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_access_grants
    ADD CONSTRAINT fk_rails_b4b53e07b8 FOREIGN KEY (application_id) REFERENCES oauth_applications(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_bbb4bf5489; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY set_member_subjects
    ADD CONSTRAINT fk_rails_bbb4bf5489 FOREIGN KEY (subject_set_id) REFERENCES subject_sets(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_bcabfcd540; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflow_tutorials
    ADD CONSTRAINT fk_rails_bcabfcd540 FOREIGN KEY (workflow_id) REFERENCES workflows(id) ON DELETE CASCADE;


--
-- Name: fk_rails_d6fe15ec78; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tagged_resources
    ADD CONSTRAINT fk_rails_d6fe15ec78 FOREIGN KEY (tag_id) REFERENCES tags(id);


--
-- Name: fk_rails_d80672ecd1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY organization_contents
    ADD CONSTRAINT fk_rails_d80672ecd1 FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;


--
-- Name: fk_rails_dff7cd1e07; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collections_subjects
    ADD CONSTRAINT fk_rails_dff7cd1e07 FOREIGN KEY (collection_id) REFERENCES collections(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_e881fca299; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_seen_subjects
    ADD CONSTRAINT fk_rails_e881fca299 FOREIGN KEY (workflow_id) REFERENCES workflows(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_e9323f2e30; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collections_subjects
    ADD CONSTRAINT fk_rails_e9323f2e30 FOREIGN KEY (subject_id) REFERENCES subjects(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_ee63f25419; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_access_tokens
    ADD CONSTRAINT fk_rails_ee63f25419 FOREIGN KEY (resource_owner_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_f1e22b77bf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY subjects
    ADD CONSTRAINT fk_rails_f1e22b77bf FOREIGN KEY (upload_user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_f26c409132; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY subjects
    ADD CONSTRAINT fk_rails_f26c409132 FOREIGN KEY (project_id) REFERENCES projects(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_fc0cd14ebe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY classification_subjects
    ADD CONSTRAINT fk_rails_fc0cd14ebe FOREIGN KEY (subject_id) REFERENCES subjects(id);


--
-- Name: fk_rails_fedc809cf8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk_rails_fedc809cf8 FOREIGN KEY (project_id) REFERENCES projects(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('20150210025312');

INSERT INTO schema_migrations (version) VALUES ('20150216192914');

INSERT INTO schema_migrations (version) VALUES ('20150216192936');

INSERT INTO schema_migrations (version) VALUES ('20150220000430');

INSERT INTO schema_migrations (version) VALUES ('20150223194424');

INSERT INTO schema_migrations (version) VALUES ('20150223200017');

INSERT INTO schema_migrations (version) VALUES ('20150224161921');

INSERT INTO schema_migrations (version) VALUES ('20150224211450');

INSERT INTO schema_migrations (version) VALUES ('20150224223657');

INSERT INTO schema_migrations (version) VALUES ('20150225181828');

INSERT INTO schema_migrations (version) VALUES ('20150227223423');

INSERT INTO schema_migrations (version) VALUES ('20150309171224');

INSERT INTO schema_migrations (version) VALUES ('20150317180911');

INSERT INTO schema_migrations (version) VALUES ('20150318132024');

INSERT INTO schema_migrations (version) VALUES ('20150318174012');

INSERT INTO schema_migrations (version) VALUES ('20150318221605');

INSERT INTO schema_migrations (version) VALUES ('20150327184058');

INSERT INTO schema_migrations (version) VALUES ('20150406095027');

INSERT INTO schema_migrations (version) VALUES ('20150409130306');

INSERT INTO schema_migrations (version) VALUES ('20150421161901');

INSERT INTO schema_migrations (version) VALUES ('20150421191603');

INSERT INTO schema_migrations (version) VALUES ('20150427171257');

INSERT INTO schema_migrations (version) VALUES ('20150427181152');

INSERT INTO schema_migrations (version) VALUES ('20150427204917');

INSERT INTO schema_migrations (version) VALUES ('20150429163442');

INSERT INTO schema_migrations (version) VALUES ('20150430084746');

INSERT INTO schema_migrations (version) VALUES ('20150430132128');

INSERT INTO schema_migrations (version) VALUES ('20150501162020');

INSERT INTO schema_migrations (version) VALUES ('20150504171133');

INSERT INTO schema_migrations (version) VALUES ('20150504185433');

INSERT INTO schema_migrations (version) VALUES ('20150504193426');

INSERT INTO schema_migrations (version) VALUES ('20150505181642');

INSERT INTO schema_migrations (version) VALUES ('20150506195759');

INSERT INTO schema_migrations (version) VALUES ('20150506195817');

INSERT INTO schema_migrations (version) VALUES ('20150507120651');

INSERT INTO schema_migrations (version) VALUES ('20150507212315');

INSERT INTO schema_migrations (version) VALUES ('20150511151058');

INSERT INTO schema_migrations (version) VALUES ('20150512012101');

INSERT INTO schema_migrations (version) VALUES ('20150512123559');

INSERT INTO schema_migrations (version) VALUES ('20150512223346');

INSERT INTO schema_migrations (version) VALUES ('20150517015229');

INSERT INTO schema_migrations (version) VALUES ('20150521160726');

INSERT INTO schema_migrations (version) VALUES ('20150522155815');

INSERT INTO schema_migrations (version) VALUES ('20150523190207');

INSERT INTO schema_migrations (version) VALUES ('20150526180444');

INSERT INTO schema_migrations (version) VALUES ('20150527200052');

INSERT INTO schema_migrations (version) VALUES ('20150527223732');

INSERT INTO schema_migrations (version) VALUES ('20150602140836');

INSERT INTO schema_migrations (version) VALUES ('20150602160633');

INSERT INTO schema_migrations (version) VALUES ('20150604214129');

INSERT INTO schema_migrations (version) VALUES ('20150605103339');

INSERT INTO schema_migrations (version) VALUES ('20150610200133');

INSERT INTO schema_migrations (version) VALUES ('20150615153138');

INSERT INTO schema_migrations (version) VALUES ('20150616113453');

INSERT INTO schema_migrations (version) VALUES ('20150616113526');

INSERT INTO schema_migrations (version) VALUES ('20150616113559');

INSERT INTO schema_migrations (version) VALUES ('20150616155130');

INSERT INTO schema_migrations (version) VALUES ('20150622085848');

INSERT INTO schema_migrations (version) VALUES ('20150624131746');

INSERT INTO schema_migrations (version) VALUES ('20150624135643');

INSERT INTO schema_migrations (version) VALUES ('20150624155122');

INSERT INTO schema_migrations (version) VALUES ('20150625043821');

INSERT INTO schema_migrations (version) VALUES ('20150625045214');

INSERT INTO schema_migrations (version) VALUES ('20150625160224');

INSERT INTO schema_migrations (version) VALUES ('20150629192248');

INSERT INTO schema_migrations (version) VALUES ('20150630144332');

INSERT INTO schema_migrations (version) VALUES ('20150706100343');

INSERT INTO schema_migrations (version) VALUES ('20150706133624');

INSERT INTO schema_migrations (version) VALUES ('20150706185722');

INSERT INTO schema_migrations (version) VALUES ('20150709191011');

INSERT INTO schema_migrations (version) VALUES ('20150710184447');

INSERT INTO schema_migrations (version) VALUES ('20150715134211');

INSERT INTO schema_migrations (version) VALUES ('20150716161318');

INSERT INTO schema_migrations (version) VALUES ('20150717123631');

INSERT INTO schema_migrations (version) VALUES ('20150721221349');

INSERT INTO schema_migrations (version) VALUES ('20150722180408');

INSERT INTO schema_migrations (version) VALUES ('20150727212724');

INSERT INTO schema_migrations (version) VALUES ('20150729165415');

INSERT INTO schema_migrations (version) VALUES ('20150730160541');

INSERT INTO schema_migrations (version) VALUES ('20150811202500');

INSERT INTO schema_migrations (version) VALUES ('20150817145756');

INSERT INTO schema_migrations (version) VALUES ('20150827124834');

INSERT INTO schema_migrations (version) VALUES ('20150901222924');

INSERT INTO schema_migrations (version) VALUES ('20150902000226');

INSERT INTO schema_migrations (version) VALUES ('20150908162042');

INSERT INTO schema_migrations (version) VALUES ('20150908193654');

INSERT INTO schema_migrations (version) VALUES ('20150916161203');

INSERT INTO schema_migrations (version) VALUES ('20150916162320');

INSERT INTO schema_migrations (version) VALUES ('20150921130111');

INSERT INTO schema_migrations (version) VALUES ('20151005093746');

INSERT INTO schema_migrations (version) VALUES ('20151007161139');

INSERT INTO schema_migrations (version) VALUES ('20151007193849');

INSERT INTO schema_migrations (version) VALUES ('20151009145251');

INSERT INTO schema_migrations (version) VALUES ('20151012162248');

INSERT INTO schema_migrations (version) VALUES ('20151013181750');

INSERT INTO schema_migrations (version) VALUES ('20151023103228');

INSERT INTO schema_migrations (version) VALUES ('20151024080849');

INSERT INTO schema_migrations (version) VALUES ('20151026142554');

INSERT INTO schema_migrations (version) VALUES ('20151027134345');

INSERT INTO schema_migrations (version) VALUES ('20151106172531');

INSERT INTO schema_migrations (version) VALUES ('20151110101156');

INSERT INTO schema_migrations (version) VALUES ('20151110135415');

INSERT INTO schema_migrations (version) VALUES ('20151111154310');

INSERT INTO schema_migrations (version) VALUES ('20151116143407');

INSERT INTO schema_migrations (version) VALUES ('20151117154126');

INSERT INTO schema_migrations (version) VALUES ('20151120104454');

INSERT INTO schema_migrations (version) VALUES ('20151120161458');

INSERT INTO schema_migrations (version) VALUES ('20151125153712');

INSERT INTO schema_migrations (version) VALUES ('20151127150019');

INSERT INTO schema_migrations (version) VALUES ('20151201102135');

INSERT INTO schema_migrations (version) VALUES ('20151207111508');

INSERT INTO schema_migrations (version) VALUES ('20151207145728');

INSERT INTO schema_migrations (version) VALUES ('20151210134819');

INSERT INTO schema_migrations (version) VALUES ('20151231123306');

INSERT INTO schema_migrations (version) VALUES ('20160103142817');

INSERT INTO schema_migrations (version) VALUES ('20160104131622');

INSERT INTO schema_migrations (version) VALUES ('20160106120927');

INSERT INTO schema_migrations (version) VALUES ('20160107143209');

INSERT INTO schema_migrations (version) VALUES ('20160111112417');

INSERT INTO schema_migrations (version) VALUES ('20160113120732');

INSERT INTO schema_migrations (version) VALUES ('20160113132540');

INSERT INTO schema_migrations (version) VALUES ('20160113133848');

INSERT INTO schema_migrations (version) VALUES ('20160113143609');

INSERT INTO schema_migrations (version) VALUES ('20160114135531');

INSERT INTO schema_migrations (version) VALUES ('20160114141909');

INSERT INTO schema_migrations (version) VALUES ('20160202155708');

INSERT INTO schema_migrations (version) VALUES ('20160303163658');

INSERT INTO schema_migrations (version) VALUES ('20160323101942');

INSERT INTO schema_migrations (version) VALUES ('20160329144922');

INSERT INTO schema_migrations (version) VALUES ('20160330142609');

INSERT INTO schema_migrations (version) VALUES ('20160406151657');

INSERT INTO schema_migrations (version) VALUES ('20160408104326');

INSERT INTO schema_migrations (version) VALUES ('20160412125332');

INSERT INTO schema_migrations (version) VALUES ('20160414151041');

INSERT INTO schema_migrations (version) VALUES ('20160425190129');

INSERT INTO schema_migrations (version) VALUES ('20160427150421');

INSERT INTO schema_migrations (version) VALUES ('20160506182308');

INSERT INTO schema_migrations (version) VALUES ('20160512181921');

INSERT INTO schema_migrations (version) VALUES ('20160525103520');

INSERT INTO schema_migrations (version) VALUES ('20160527140046');

INSERT INTO schema_migrations (version) VALUES ('20160527162831');

INSERT INTO schema_migrations (version) VALUES ('20160601162035');

INSERT INTO schema_migrations (version) VALUES ('20160613074506');

INSERT INTO schema_migrations (version) VALUES ('20160613074514');

INSERT INTO schema_migrations (version) VALUES ('20160613074521');

INSERT INTO schema_migrations (version) VALUES ('20160613074534');

INSERT INTO schema_migrations (version) VALUES ('20160613074550');

INSERT INTO schema_migrations (version) VALUES ('20160613074559');

INSERT INTO schema_migrations (version) VALUES ('20160613074613');

INSERT INTO schema_migrations (version) VALUES ('20160613074625');

INSERT INTO schema_migrations (version) VALUES ('20160613074633');

INSERT INTO schema_migrations (version) VALUES ('20160613074640');

INSERT INTO schema_migrations (version) VALUES ('20160613074658');

INSERT INTO schema_migrations (version) VALUES ('20160613074711');

INSERT INTO schema_migrations (version) VALUES ('20160613074718');

INSERT INTO schema_migrations (version) VALUES ('20160613074730');

INSERT INTO schema_migrations (version) VALUES ('20160613074745');

INSERT INTO schema_migrations (version) VALUES ('20160613074746');

INSERT INTO schema_migrations (version) VALUES ('20160613074754');

INSERT INTO schema_migrations (version) VALUES ('20160613074924');

INSERT INTO schema_migrations (version) VALUES ('20160613074934');

INSERT INTO schema_migrations (version) VALUES ('20160613075003');

INSERT INTO schema_migrations (version) VALUES ('20160628165038');

INSERT INTO schema_migrations (version) VALUES ('20160630150419');

INSERT INTO schema_migrations (version) VALUES ('20160630170502');

INSERT INTO schema_migrations (version) VALUES ('20160810140805');

INSERT INTO schema_migrations (version) VALUES ('20160810195152');

INSERT INTO schema_migrations (version) VALUES ('20160819134413');

INSERT INTO schema_migrations (version) VALUES ('20160824101413');

INSERT INTO schema_migrations (version) VALUES ('20160901100944');

INSERT INTO schema_migrations (version) VALUES ('20160901141903');

INSERT INTO schema_migrations (version) VALUES ('20161017135917');

INSERT INTO schema_migrations (version) VALUES ('20161017141439');

INSERT INTO schema_migrations (version) VALUES ('20161125123824');

INSERT INTO schema_migrations (version) VALUES ('20161128193435');

INSERT INTO schema_migrations (version) VALUES ('20161205203956');

INSERT INTO schema_migrations (version) VALUES ('20161207111319');

INSERT INTO schema_migrations (version) VALUES ('20161212205412');

INSERT INTO schema_migrations (version) VALUES ('20161221203241');

INSERT INTO schema_migrations (version) VALUES ('20170112163747');

INSERT INTO schema_migrations (version) VALUES ('20170113113532');

INSERT INTO schema_migrations (version) VALUES ('20170116134142');

INSERT INTO schema_migrations (version) VALUES ('20170118141452');

INSERT INTO schema_migrations (version) VALUES ('20170202200131');

INSERT INTO schema_migrations (version) VALUES ('20170202202724');

INSERT INTO schema_migrations (version) VALUES ('20170206161946');

INSERT INTO schema_migrations (version) VALUES ('20170210163241');

INSERT INTO schema_migrations (version) VALUES ('20170215105309');

INSERT INTO schema_migrations (version) VALUES ('20170215151802');

INSERT INTO schema_migrations (version) VALUES ('20170310131642');

INSERT INTO schema_migrations (version) VALUES ('20170316170501');

INSERT INTO schema_migrations (version) VALUES ('20170320203350');

INSERT INTO schema_migrations (version) VALUES ('20170325135953');

INSERT INTO schema_migrations (version) VALUES ('20170403194826');

INSERT INTO schema_migrations (version) VALUES ('20170420095703');

INSERT INTO schema_migrations (version) VALUES ('20170425110939');

INSERT INTO schema_migrations (version) VALUES ('20170426162708');

INSERT INTO schema_migrations (version) VALUES ('20170519181110');

INSERT INTO schema_migrations (version) VALUES ('20170523135118');

INSERT INTO schema_migrations (version) VALUES ('20170524205300');

INSERT INTO schema_migrations (version) VALUES ('20170524210302');

INSERT INTO schema_migrations (version) VALUES ('20170525151142');

INSERT INTO schema_migrations (version) VALUES ('20170727142122');

INSERT INTO schema_migrations (version) VALUES ('20170808130619');

INSERT INTO schema_migrations (version) VALUES ('20170824165411');

INSERT INTO schema_migrations (version) VALUES ('20171019115705');

INSERT INTO schema_migrations (version) VALUES ('20171120222438');

INSERT INTO schema_migrations (version) VALUES ('20171121120455');

INSERT INTO schema_migrations (version) VALUES ('20171208141841');

INSERT INTO schema_migrations (version) VALUES ('20171208142645');

INSERT INTO schema_migrations (version) VALUES ('20171213144807');

INSERT INTO schema_migrations (version) VALUES ('20171214121332');

INSERT INTO schema_migrations (version) VALUES ('20180110133833');

INSERT INTO schema_migrations (version) VALUES ('20180115214144');

INSERT INTO schema_migrations (version) VALUES ('20180122134607');

