# @api private
# FFI bindings
module Redland

  class << self

    def mri?
      defined?(RUBY_DESCRIPTION) && (/^ruby/ =~ RUBY_DESCRIPTION)
    end

    def jruby?
      defined?(RUBY_PLATFORM) && ("java" == RUBY_PLATFORM)
    end

    def rubinius?
      defined?(RUBY_ENGINE) && ("rbx" == RUBY_ENGINE)
    end

    # @api_private
    # Determine FFI constant for this ruby engine.
    def find_ffi
      if defined?(RUBY_ENGINE) && RUBY_ENGINE == "rbx"
        if const_defined? "::Rubinius::FFI"
          ::Rubinius::FFI
        elsif const_defined? "::FFI"
          ::FFI
        else
          require "ffi"
          ::FFI
        end
      else # mri, jruby, etc
        require "ffi"
        ::FFI
      end
    end

    # @api_private
    # Extend with the correct ffi implementation.
    def load_ffi
      ffi_module = Redland::find_ffi
      extend ffi_module::Library
      ffi_module
    end

    # @api_private
    # Loads the librdf shared library.
    def load_librdf
      begin
        ffi_lib "rdf"
      rescue LoadError
        ffi_lib "librdf.so.0"
      end
    end

    # @api_private
    # Loads the libraptor shared library.
    def load_raptor
      begin
        ffi_lib "raptor2"
      rescue LoadError
        ffi_lib "libraptor2.so.0"
      end
    end
  end

  # Constant holding the FFI module for this ruby engine.
  FFI = Redland::load_ffi
  Redland::load_raptor

  # Defines raptor2 enum raptor_world_flag
  enum :raptor_world_flag, [
    :RAPTOR_WORLD_FLAG_LIBXML_GENERIC_ERROR_SAVE, 1,
    :RAPTOR_WORLD_FLAG_LIBXML_STRUCTURED_ERROR_SAVE, 2,
    :RAPTOR_WORLD_FLAG_URI_INTERNING, 3,
    :RAPTOR_WORLD_FLAG_WWW_SKIP_INIT_FINISH, 4
  ]

  # Raptor
  attach_variable :raptor_version_decimal, :int
  attach_function :raptor_new_world_internal, [:int], :pointer
  attach_function :raptor_world_set_flag, [:pointer, :raptor_world_flag, :int], :int

  Redland::load_librdf

  # World
  attach_function :librdf_new_world, [], :pointer
  attach_function :librdf_free_world, [:pointer], :void
  attach_function :librdf_world_open, [:pointer], :void
  attach_function :librdf_world_set_raptor, [:pointer, :pointer], :void

  # Storage
  attach_function :librdf_new_storage, [:pointer, :string, :string, :string], :pointer
  attach_function :librdf_free_storage, [:pointer], :void

  # Model
  attach_function :librdf_new_model, [:pointer, :pointer, :string], :pointer
  attach_function :librdf_free_model, [:pointer], :void
  attach_function :librdf_model_as_stream, [:pointer], :pointer
  attach_function :librdf_model_size, [:pointer], :int
  attach_function :librdf_model_find_statements, [:pointer, :pointer], :pointer
  attach_function :librdf_model_add_statement, [:pointer, :pointer], :int
  attach_function :librdf_model_add_statements, [:pointer, :pointer], :int
  attach_function :librdf_model_remove_statement, [:pointer, :pointer], :int
  attach_function :librdf_model_transaction_start, [:pointer], :int
  attach_function :librdf_model_transaction_commit, [:pointer], :int
  attach_function :librdf_model_transaction_rollback, [:pointer], :int
  attach_function :librdf_model_query_execute, [:pointer, :pointer], :pointer

  # Statement
  attach_function :librdf_free_statement, [:pointer], :void
  attach_function :librdf_new_statement_from_nodes, [:pointer, :pointer, :pointer, :pointer], :pointer
  attach_function :librdf_new_statement_from_statement, [:pointer], :pointer
  attach_function :librdf_statement_get_subject, [:pointer], :pointer
  attach_function :librdf_statement_get_predicate, [:pointer], :pointer
  attach_function :librdf_statement_get_object, [:pointer], :pointer
  attach_function :librdf_statement_set_subject, [:pointer, :pointer], :void
  attach_function :librdf_statement_set_predicate, [:pointer, :pointer], :void
  attach_function :librdf_statement_set_object, [:pointer, :pointer], :void
  attach_function :librdf_statement_to_string, [:pointer], :string

  # Node
  attach_function :librdf_free_node, [:pointer], :void
  attach_function :librdf_new_node_from_blank_identifier, [:pointer, :string], :pointer
  attach_function :librdf_new_node_from_uri_string, [:pointer, :string], :pointer
  attach_function :librdf_new_node_from_node, [:pointer], :pointer
  attach_function :librdf_new_node_from_typed_literal, [:pointer, :string, :string, :pointer], :pointer
  attach_function :librdf_node_is_resource, [:pointer], :int
  attach_function :librdf_node_is_literal, [:pointer], :int
  attach_function :librdf_node_is_blank, [:pointer], :int
  attach_function :librdf_node_get_literal_value, [:pointer], :string
  attach_function :librdf_node_get_literal_value_datatype_uri, [:pointer], :pointer
  attach_function :librdf_node_equals, [:pointer, :pointer], :int
  attach_function :librdf_node_to_string, [:pointer], :string
  attach_function :librdf_node_get_uri, [:pointer], :pointer
  attach_function :librdf_node_get_blank_identifier, [:pointer], :string
  attach_function :librdf_node_get_literal_value_language, [:pointer], :string

  # Stream
  attach_function :librdf_free_stream, [:pointer], :void
  attach_function :librdf_stream_end, [:pointer], :int
  attach_function :librdf_stream_next, [:pointer], :int
  attach_function :librdf_stream_get_object, [:pointer], :pointer

  # Serializer
  attach_function :librdf_new_serializer, [:pointer, :string, :string, :pointer], :pointer
  attach_function :librdf_free_serializer, [:pointer], :void
  attach_function :librdf_serializer_serialize_model_to_string, [:pointer, :pointer, :pointer], :string
  attach_function :librdf_serializer_serialize_model_to_file, [:pointer, :string, :pointer, :pointer], :int

  # Parser
  attach_function :librdf_new_parser, [:pointer, :string, :string, :pointer], :pointer
  attach_function :librdf_free_parser, [:pointer], :void
  attach_function :librdf_parser_parse_into_model, [:pointer, :pointer, :pointer, :pointer], :int
  attach_function :librdf_parser_parse_string_into_model, [:pointer, :string, :pointer, :pointer], :int
  attach_function :librdf_parser_parse_as_stream, [:pointer, :pointer, :pointer], :pointer
  attach_function :librdf_parser_parse_string_as_stream, [:pointer, :string, :pointer], :pointer

  # URI
  attach_function :librdf_new_uri, [:pointer, :string], :pointer
  attach_function :librdf_new_uri_from_uri, [:pointer], :pointer
  attach_function :librdf_free_uri, [:pointer], :void
  attach_function :librdf_uri_to_string, [:pointer], :string
  attach_function :librdf_uri_equals, [:pointer, :pointer], :int

  # Query
  attach_function :librdf_new_query, [:pointer, :string, :pointer, :string, :pointer], :pointer
  attach_function :librdf_free_query, [:pointer], :void
  attach_function :librdf_query_get_limit, [:pointer], :int
  attach_function :librdf_query_set_limit, [:pointer, :int], :int
  attach_function :librdf_query_get_offset, [:pointer], :int
  attach_function :librdf_query_set_offset, [:pointer, :int], :int
  attach_function :librdf_query_results_is_bindings, [:pointer], :int
  attach_function :librdf_query_results_is_boolean, [:pointer], :int
  attach_function :librdf_query_results_is_graph, [:pointer], :int
  attach_function :librdf_query_results_is_syntax, [:pointer], :int
  attach_function :librdf_query_results_get_binding_name, [:pointer, :int], :string
  attach_function :librdf_query_results_get_binding_value, [:pointer, :int], :pointer
  attach_function :librdf_query_results_get_binding_value_by_name, [:pointer, :string], :pointer
  attach_function :librdf_query_results_get_bindings_count, [:pointer], :int
  attach_function :librdf_query_results_get_boolean, [:pointer], :int
  attach_function :librdf_query_results_as_stream, [:pointer], :pointer
  attach_function :librdf_query_results_next, [:pointer], :int
  attach_function :librdf_query_results_finished, [:pointer], :int
  attach_function :librdf_query_results_get_count, [:pointer], :int
  attach_function :librdf_free_query_results, [:pointer], :void
end
