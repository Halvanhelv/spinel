/*
 * codegen.h - Spinel AOT compiler: C code generation from Prism AST
 *
 * Walks the Prism AST and generates C source code that uses the mruby
 * runtime. For proven types (Integer, Float, Boolean), generates unboxed
 * C operations. For unresolved types, falls back to mrb_funcall.
 */

#ifndef SPINEL_CODEGEN_H
#define SPINEL_CODEGEN_H

#include <stdio.h>
#include <stdbool.h>
#include <prism.h>

/* Inferred type for an expression or variable */
typedef enum {
    SPINEL_TYPE_UNKNOWN = 0,
    SPINEL_TYPE_INTEGER,
    SPINEL_TYPE_FLOAT,
    SPINEL_TYPE_BOOLEAN,
    SPINEL_TYPE_STRING,
    SPINEL_TYPE_NIL,
    SPINEL_TYPE_VALUE,  /* boxed mrb_value (fallback) */
} spinel_type_t;

/* Variable entry in the variable table */
typedef struct {
    char name[64];          /* Ruby name */
    spinel_type_t type;     /* inferred type */
    bool declared;          /* has been emitted as C declaration */
    bool is_constant;       /* Ruby constant (ITER, LIMIT_SQUARED) */
} var_entry_t;

#define MAX_VARS 256

/* Code generation context */
typedef struct {
    pm_parser_t *parser;    /* Prism parser (for constant pool) */
    FILE *out;              /* output C file */
    int indent;             /* current indentation level */
    var_entry_t vars[MAX_VARS];
    int var_count;
    int temp_counter;       /* for temporary variable names */
    int for_depth;          /* nesting depth of for loops (for break) */
} codegen_ctx_t;

/* Initialize the codegen context */
void codegen_init(codegen_ctx_t *ctx, pm_parser_t *parser, FILE *out);

/* Run the full codegen pipeline:
 *   1. Type inference pass (walk AST, infer variable types)
 *   2. Emit C file header (includes, main() opening, variable decls)
 *   3. Code generation pass (walk AST, emit C statements)
 *   4. Emit C file footer (mrb_close, return)
 */
void codegen_program(codegen_ctx_t *ctx, pm_node_t *root);

/* Get the C type name for a spinel_type_t */
const char *spinel_type_cname(spinel_type_t type);

#endif /* SPINEL_CODEGEN_H */
