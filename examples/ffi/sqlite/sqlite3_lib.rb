# Minimal SQLite3 FFI bindings for Spinel.
#
# Only the surface area the blog demo needs:
#   - open / close
#   - exec for DDL + INSERT/UPDATE/DELETE
#   - prepare_v2 / step / finalize + column accessors for SELECT
#
# Strings are passed inline into SQL; bind_text would also work but
# requires the SQLITE_TRANSIENT destructor sentinel which the Spinel FFI
# can't construct as a `:ptr` value yet. For string columns we escape
# single quotes ourselves (`Sql.q`).
module SQL
  ffi_lib "sqlite3"

  ffi_const :OK,   0
  ffi_const :ROW,  100
  ffi_const :DONE, 101

  # Core API.
  ffi_func :sqlite3_open,              [:str, :ptr],                          :int
  ffi_func :sqlite3_close,             [:ptr],                                :int
  ffi_func :sqlite3_exec,              [:ptr, :str, :ptr, :ptr, :ptr],        :int
  ffi_func :sqlite3_prepare_v2,        [:ptr, :str, :int, :ptr, :ptr],        :int
  ffi_func :sqlite3_step,              [:ptr],                                :int
  ffi_func :sqlite3_finalize,          [:ptr],                                :int
  ffi_func :sqlite3_column_int,        [:ptr, :int],                          :int
  ffi_func :sqlite3_column_text,       [:ptr, :int],                          :str
  ffi_func :sqlite3_column_count,      [:ptr],                                :int
  ffi_func :sqlite3_errmsg,            [:ptr],                                :str
  ffi_func :sqlite3_last_insert_rowid, [:ptr],                                :long
  ffi_func :sqlite3_changes,           [:ptr],                                :int

  # Out-params — sqlite3_open writes the db handle here, prepare_v2
  # writes the stmt handle.
  ffi_buffer :db_out,   8
  ffi_buffer :stmt_out, 8
  ffi_read_ptr :read_ptr, 0
end

# Tiny helper module. Quote-escapes single quotes for inline SQL —
# good enough for the demo's well-known input strings.
module Sql
  def self.q(s)
    s.gsub("'", "''")
  end
end
