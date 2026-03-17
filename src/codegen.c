/*
 * codegen.c - Spinel AOT compiler: C code generation from Prism AST
 *
 * Two-pass approach:
 *   Pass 1 (type inference): Walk AST, infer types for all variables
 *   Pass 2 (codegen): Walk AST, emit C code using inferred types
 *
 * For proven types (Integer, Float, Boolean), generates unboxed C operations.
 * For String and unknown types, uses mrb_value with mruby API calls.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <assert.h>
#include <prism.h>
#include "codegen.h"

/* ------------------------------------------------------------------ */
/* Helper: dynamic string (for building C expressions)                */
/* ------------------------------------------------------------------ */

static char *str_dup(const char *s) {
    size_t len = strlen(s);
    char *r = malloc(len + 1);
    memcpy(r, s, len + 1);
    return r;
}

static char *str_fmt(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    int n = vsnprintf(NULL, 0, fmt, ap);
    va_end(ap);
    char *buf = malloc(n + 1);
    va_start(ap, fmt);
    vsnprintf(buf, n + 1, fmt, ap);
    va_end(ap);
    return buf;
}

/* ------------------------------------------------------------------ */
/* Constant pool helper                                               */
/* ------------------------------------------------------------------ */

/* Get constant string — returns pointer into source (NOT null-terminated).
 * Use cstr() for a null-terminated copy. */
static void constant_raw(codegen_ctx_t *ctx, pm_constant_id_t id,
                          const uint8_t **out_start, size_t *out_len) {
    pm_constant_t *c = &ctx->parser->constant_pool.constants[id - 1];
    *out_start = c->start;
    *out_len = c->length;
}

/* Return a heap-allocated null-terminated string. Caller must free. */
static char *cstr(codegen_ctx_t *ctx, pm_constant_id_t id) {
    const uint8_t *start;
    size_t len;
    constant_raw(ctx, id, &start, &len);
    char *buf = malloc(len + 1);
    memcpy(buf, start, len);
    buf[len] = '\0';
    return buf;
}

/* Check if a constant ID matches a given string (no allocation) */
static bool ceq(codegen_ctx_t *ctx, pm_constant_id_t id, const char *s) {
    const uint8_t *start;
    size_t len;
    constant_raw(ctx, id, &start, &len);
    return len == strlen(s) && memcmp(start, s, len) == 0;
}

/* ------------------------------------------------------------------ */
/* Variable table                                                     */
/* ------------------------------------------------------------------ */

static var_entry_t *var_lookup(codegen_ctx_t *ctx, const char *name) {
    for (int i = 0; i < ctx->var_count; i++) {
        if (strcmp(ctx->vars[i].name, name) == 0)
            return &ctx->vars[i];
    }
    return NULL;
}

static var_entry_t *var_declare(codegen_ctx_t *ctx, const char *name,
                                spinel_type_t type, bool is_constant) {
    var_entry_t *v = var_lookup(ctx, name);
    if (v) {
        if (v->type != type && v->type != SPINEL_TYPE_UNKNOWN) {
            if ((v->type == SPINEL_TYPE_INTEGER && type == SPINEL_TYPE_FLOAT) ||
                (v->type == SPINEL_TYPE_FLOAT && type == SPINEL_TYPE_INTEGER))
                v->type = SPINEL_TYPE_FLOAT;
            else if (v->type != type)
                v->type = SPINEL_TYPE_VALUE;
        } else {
            v->type = type;
        }
        return v;
    }
    assert(ctx->var_count < MAX_VARS);
    v = &ctx->vars[ctx->var_count++];
    snprintf(v->name, sizeof(v->name), "%s", name);
    v->type = type;
    v->declared = false;
    v->is_constant = is_constant;
    return v;
}

/* Get the C variable name for a Ruby variable. Uses var_entry_t's name. */
static char *make_cname(const char *ruby_name, bool is_constant) {
    return str_fmt("%s%s", is_constant ? "cv_" : "lv_", ruby_name);
}

/* ------------------------------------------------------------------ */
/* Output helpers                                                     */
/* ------------------------------------------------------------------ */

static void emit(codegen_ctx_t *ctx, const char *fmt, ...) {
    for (int i = 0; i < ctx->indent; i++)
        fprintf(ctx->out, "    ");
    va_list ap;
    va_start(ap, fmt);
    vfprintf(ctx->out, fmt, ap);
    va_end(ap);
}

static void emit_raw(codegen_ctx_t *ctx, const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    vfprintf(ctx->out, fmt, ap);
    va_end(ap);
}

const char *spinel_type_cname(spinel_type_t type) {
    switch (type) {
    case SPINEL_TYPE_INTEGER: return "mrb_int";
    case SPINEL_TYPE_FLOAT:   return "mrb_float";
    case SPINEL_TYPE_BOOLEAN: return "mrb_bool";
    default:                  return "mrb_value";
    }
}

/* ------------------------------------------------------------------ */
/* Forward declarations                                               */
/* ------------------------------------------------------------------ */

static spinel_type_t infer_type(codegen_ctx_t *ctx, pm_node_t *node);
static void infer_pass(codegen_ctx_t *ctx, pm_node_t *node);
static char *codegen_expr(codegen_ctx_t *ctx, pm_node_t *node);
static void codegen_stmt(codegen_ctx_t *ctx, pm_node_t *node);
static void codegen_stmts(codegen_ctx_t *ctx, pm_node_t *node);

/* ------------------------------------------------------------------ */
/* Type inference (Pass 1)                                            */
/* ------------------------------------------------------------------ */

static spinel_type_t binop_result_type(spinel_type_t left, spinel_type_t right,
                                       const char *op) {
    if (strcmp(op, ">") == 0 || strcmp(op, "<") == 0 ||
        strcmp(op, ">=") == 0 || strcmp(op, "<=") == 0 ||
        strcmp(op, "==") == 0 || strcmp(op, "!=") == 0)
        return SPINEL_TYPE_BOOLEAN;

    if (strcmp(op, "<<") == 0 || strcmp(op, ">>") == 0 ||
        strcmp(op, "|") == 0 || strcmp(op, "&") == 0 ||
        strcmp(op, "^") == 0)
        return SPINEL_TYPE_INTEGER;

    if (left == SPINEL_TYPE_FLOAT || right == SPINEL_TYPE_FLOAT)
        return SPINEL_TYPE_FLOAT;
    if (left == SPINEL_TYPE_INTEGER && right == SPINEL_TYPE_INTEGER)
        return SPINEL_TYPE_INTEGER;

    return SPINEL_TYPE_VALUE;
}

static spinel_type_t infer_type(codegen_ctx_t *ctx, pm_node_t *node) {
    if (!node) return SPINEL_TYPE_NIL;

    switch (PM_NODE_TYPE(node)) {
    case PM_INTEGER_NODE:  return SPINEL_TYPE_INTEGER;
    case PM_FLOAT_NODE:    return SPINEL_TYPE_FLOAT;
    case PM_STRING_NODE:
    case PM_INTERPOLATED_STRING_NODE:
                           return SPINEL_TYPE_STRING;
    case PM_TRUE_NODE:
    case PM_FALSE_NODE:    return SPINEL_TYPE_BOOLEAN;
    case PM_NIL_NODE:      return SPINEL_TYPE_NIL;

    case PM_LOCAL_VARIABLE_READ_NODE: {
        pm_local_variable_read_node_t *n = (pm_local_variable_read_node_t *)node;
        char *name = cstr(ctx, n->name);
        var_entry_t *v = var_lookup(ctx, name);
        spinel_type_t t = v ? v->type : SPINEL_TYPE_VALUE;
        free(name);
        return t;
    }

    case PM_CONSTANT_READ_NODE: {
        pm_constant_read_node_t *n = (pm_constant_read_node_t *)node;
        char *name = cstr(ctx, n->name);
        var_entry_t *v = var_lookup(ctx, name);
        spinel_type_t t = v ? v->type : SPINEL_TYPE_VALUE;
        free(name);
        return t;
    }

    case PM_CALL_NODE: {
        pm_call_node_t *call = (pm_call_node_t *)node;
        char *method = cstr(ctx, call->name);
        spinel_type_t result = SPINEL_TYPE_VALUE;

        if (call->receiver && call->arguments &&
            call->arguments->arguments.size == 1) {
            spinel_type_t lt = infer_type(ctx, call->receiver);
            spinel_type_t rt = infer_type(ctx, call->arguments->arguments.nodes[0]);
            result = binop_result_type(lt, rt, method);
            free(method);
            return result;
        }

        if (call->receiver && !call->arguments && strcmp(method, "-@") == 0)
            result = infer_type(ctx, call->receiver);
        else if (strcmp(method, "chr") == 0 || strcmp(method, "to_s") == 0)
            result = SPINEL_TYPE_STRING;
        else if (strcmp(method, "to_i") == 0)
            result = SPINEL_TYPE_INTEGER;
        else if (strcmp(method, "to_f") == 0)
            result = SPINEL_TYPE_FLOAT;
        else if (strcmp(method, "puts") == 0 || strcmp(method, "print") == 0)
            result = SPINEL_TYPE_NIL;
        else if (strcmp(method, "size") == 0 || strcmp(method, "length") == 0)
            result = SPINEL_TYPE_INTEGER;

        free(method);
        return result;
    }

    case PM_IF_NODE: {
        pm_if_node_t *n = (pm_if_node_t *)node;
        spinel_type_t then_t = n->statements
            ? infer_type(ctx, (pm_node_t *)n->statements) : SPINEL_TYPE_NIL;
        spinel_type_t else_t = n->subsequent
            ? infer_type(ctx, (pm_node_t *)n->subsequent) : SPINEL_TYPE_NIL;
        if (then_t == else_t) return then_t;
        if ((then_t == SPINEL_TYPE_INTEGER && else_t == SPINEL_TYPE_FLOAT) ||
            (then_t == SPINEL_TYPE_FLOAT && else_t == SPINEL_TYPE_INTEGER))
            return SPINEL_TYPE_FLOAT;
        return SPINEL_TYPE_VALUE;
    }

    case PM_ELSE_NODE: {
        pm_else_node_t *n = (pm_else_node_t *)node;
        return n->statements ? infer_type(ctx, (pm_node_t *)n->statements) : SPINEL_TYPE_NIL;
    }

    case PM_STATEMENTS_NODE: {
        pm_statements_node_t *s = (pm_statements_node_t *)node;
        if (s->body.size == 0) return SPINEL_TYPE_NIL;
        return infer_type(ctx, s->body.nodes[s->body.size - 1]);
    }

    case PM_PARENTHESES_NODE: {
        pm_parentheses_node_t *n = (pm_parentheses_node_t *)node;
        return n->body ? infer_type(ctx, n->body) : SPINEL_TYPE_NIL;
    }

    default:
        return SPINEL_TYPE_VALUE;
    }
}

/* Walk AST to register all variables and infer their types */
static void infer_pass(codegen_ctx_t *ctx, pm_node_t *node) {
    if (!node) return;

    switch (PM_NODE_TYPE(node)) {
    case PM_PROGRAM_NODE: {
        pm_program_node_t *p = (pm_program_node_t *)node;
        infer_pass(ctx, (pm_node_t *)p->statements);
        break;
    }

    case PM_STATEMENTS_NODE: {
        pm_statements_node_t *s = (pm_statements_node_t *)node;
        for (size_t i = 0; i < s->body.size; i++)
            infer_pass(ctx, s->body.nodes[i]);
        break;
    }

    case PM_LOCAL_VARIABLE_WRITE_NODE: {
        pm_local_variable_write_node_t *n = (pm_local_variable_write_node_t *)node;
        infer_pass(ctx, n->value);
        char *name = cstr(ctx, n->name);
        spinel_type_t type = infer_type(ctx, n->value);
        var_declare(ctx, name, type, false);
        free(name);
        break;
    }

    case PM_LOCAL_VARIABLE_OPERATOR_WRITE_NODE: {
        pm_local_variable_operator_write_node_t *n =
            (pm_local_variable_operator_write_node_t *)node;
        infer_pass(ctx, n->value);
        char *name = cstr(ctx, n->name);
        if (!var_lookup(ctx, name)) {
            spinel_type_t type = infer_type(ctx, n->value);
            var_declare(ctx, name, type, false);
        }
        free(name);
        break;
    }

    case PM_CONSTANT_WRITE_NODE: {
        pm_constant_write_node_t *n = (pm_constant_write_node_t *)node;
        infer_pass(ctx, n->value);
        char *name = cstr(ctx, n->name);
        spinel_type_t type = infer_type(ctx, n->value);
        var_declare(ctx, name, type, true);
        free(name);
        break;
    }

    case PM_WHILE_NODE: {
        pm_while_node_t *n = (pm_while_node_t *)node;
        infer_pass(ctx, n->predicate);
        if (n->statements) infer_pass(ctx, (pm_node_t *)n->statements);
        break;
    }

    case PM_FOR_NODE: {
        pm_for_node_t *n = (pm_for_node_t *)node;
        infer_pass(ctx, n->collection);
        if (PM_NODE_TYPE(n->collection) == PM_RANGE_NODE) {
            pm_range_node_t *range = (pm_range_node_t *)n->collection;
            spinel_type_t lt = range->left ? infer_type(ctx, range->left) : SPINEL_TYPE_INTEGER;
            spinel_type_t rt = range->right ? infer_type(ctx, range->right) : SPINEL_TYPE_INTEGER;
            spinel_type_t iter_type = (lt == SPINEL_TYPE_FLOAT || rt == SPINEL_TYPE_FLOAT)
                ? SPINEL_TYPE_FLOAT : SPINEL_TYPE_INTEGER;
            if (PM_NODE_TYPE(n->index) == PM_LOCAL_VARIABLE_TARGET_NODE) {
                pm_local_variable_target_node_t *target =
                    (pm_local_variable_target_node_t *)n->index;
                char *name = cstr(ctx, target->name);
                var_declare(ctx, name, iter_type, false);
                free(name);
            }
        }
        if (n->statements) infer_pass(ctx, (pm_node_t *)n->statements);
        break;
    }

    case PM_IF_NODE: {
        pm_if_node_t *n = (pm_if_node_t *)node;
        infer_pass(ctx, n->predicate);
        if (n->statements) infer_pass(ctx, (pm_node_t *)n->statements);
        if (n->subsequent) infer_pass(ctx, (pm_node_t *)n->subsequent);
        break;
    }

    case PM_ELSE_NODE: {
        pm_else_node_t *n = (pm_else_node_t *)node;
        if (n->statements) infer_pass(ctx, (pm_node_t *)n->statements);
        break;
    }

    case PM_MULTI_WRITE_NODE: {
        pm_multi_write_node_t *n = (pm_multi_write_node_t *)node;
        infer_pass(ctx, n->value);
        if (PM_NODE_TYPE(n->value) == PM_ARRAY_NODE) {
            pm_array_node_t *ary = (pm_array_node_t *)n->value;
            for (size_t i = 0; i < n->lefts.size && i < ary->elements.size; i++) {
                if (PM_NODE_TYPE(n->lefts.nodes[i]) == PM_LOCAL_VARIABLE_TARGET_NODE) {
                    pm_local_variable_target_node_t *target =
                        (pm_local_variable_target_node_t *)n->lefts.nodes[i];
                    char *name = cstr(ctx, target->name);
                    spinel_type_t type = infer_type(ctx, ary->elements.nodes[i]);
                    var_declare(ctx, name, type, false);
                    free(name);
                }
            }
        }
        break;
    }

    case PM_CALL_NODE: {
        pm_call_node_t *call = (pm_call_node_t *)node;
        if (call->receiver) infer_pass(ctx, call->receiver);
        if (call->arguments) {
            for (size_t i = 0; i < call->arguments->arguments.size; i++)
                infer_pass(ctx, call->arguments->arguments.nodes[i]);
        }
        break;
    }

    default:
        break;
    }
}

/* ------------------------------------------------------------------ */
/* Expression codegen (Pass 2)                                        */
/* Returns a malloc'd C expression string.                            */
/* ------------------------------------------------------------------ */

static char *codegen_expr(codegen_ctx_t *ctx, pm_node_t *node) {
    if (!node) return str_dup("mrb_nil_value()");

    switch (PM_NODE_TYPE(node)) {

    case PM_INTEGER_NODE: {
        pm_integer_node_t *n = (pm_integer_node_t *)node;
        if (n->value.length == 0) {
            int64_t val = (int64_t)n->value.value;
            if (n->value.negative) val = -val;
            return str_fmt("%lld", (long long)val);
        }
        return str_dup("0 /* TODO: large integer */");
    }

    case PM_FLOAT_NODE: {
        pm_float_node_t *n = (pm_float_node_t *)node;
        return str_fmt("%.17g", n->value);
    }

    case PM_STRING_NODE: {
        pm_string_node_t *n = (pm_string_node_t *)node;
        const uint8_t *src = pm_string_source(&n->unescaped);
        size_t len = pm_string_length(&n->unescaped);
        size_t bufsz = len * 4 + 64;
        char *buf = malloc(bufsz);
        int pos = snprintf(buf, bufsz, "mrb_str_new_lit(mrb, \"");
        for (size_t i = 0; i < len; i++) {
            uint8_t c = src[i];
            if (c == '"')       pos += snprintf(buf + pos, bufsz - pos, "\\\"");
            else if (c == '\\') pos += snprintf(buf + pos, bufsz - pos, "\\\\");
            else if (c == '\n') pos += snprintf(buf + pos, bufsz - pos, "\\n");
            else if (c == '\r') pos += snprintf(buf + pos, bufsz - pos, "\\r");
            else if (c == '\t') pos += snprintf(buf + pos, bufsz - pos, "\\t");
            else if (c >= 32 && c < 127)
                pos += snprintf(buf + pos, bufsz - pos, "%c", c);
            else
                pos += snprintf(buf + pos, bufsz - pos, "\\x%02x", c);
        }
        snprintf(buf + pos, bufsz - pos, "\")");
        return buf;
    }

    case PM_INTERPOLATED_STRING_NODE: {
        pm_interpolated_string_node_t *n = (pm_interpolated_string_node_t *)node;
        /* Emit temporary variables inside a block to avoid nested calls. */
        int str_id = ctx->temp_counter++;
        emit(ctx, "mrb_value _is%d; {\n", str_id);
        ctx->indent++;
        emit(ctx, "_is%d = mrb_str_new_cstr(mrb, \"\");\n", str_id);
        for (size_t i = 0; i < n->parts.size; i++) {
            pm_node_t *part = n->parts.nodes[i];
            if (PM_NODE_TYPE(part) == PM_STRING_NODE) {
                pm_string_node_t *sn = (pm_string_node_t *)part;
                const uint8_t *src = pm_string_source(&sn->unescaped);
                size_t len = pm_string_length(&sn->unescaped);
                emit(ctx, "mrb_str_cat_cstr(mrb, _is%d, \"", str_id);
                for (size_t j = 0; j < len; j++) {
                    uint8_t c = src[j];
                    if (c == '"')       emit_raw(ctx, "\\\"");
                    else if (c == '\\') emit_raw(ctx, "\\\\");
                    else if (c == '\n') emit_raw(ctx, "\\n");
                    else if (c == '\r') emit_raw(ctx, "\\r");
                    else if (c == '\t') emit_raw(ctx, "\\t");
                    else if (c >= 32 && c < 127)
                        emit_raw(ctx, "%c", c);
                    else
                        emit_raw(ctx, "\\x%02x", c);
                }
                emit_raw(ctx, "\");\n");
            } else if (PM_NODE_TYPE(part) == PM_EMBEDDED_STATEMENTS_NODE) {
                pm_embedded_statements_node_t *embed =
                    (pm_embedded_statements_node_t *)part;
                if (embed->statements && embed->statements->body.size > 0) {
                    pm_node_t *inner = embed->statements->body.nodes[0];
                    spinel_type_t it = infer_type(ctx, inner);
                    char *ie = codegen_expr(ctx, inner);
                    int tmp = ctx->temp_counter++;
                    if (it == SPINEL_TYPE_INTEGER) {
                        emit(ctx, "mrb_value _t%d = mrb_funcall(mrb, mrb_fixnum_value(%s), \"to_s\", 0);\n", tmp, ie);
                    } else if (it == SPINEL_TYPE_FLOAT) {
                        emit(ctx, "mrb_value _t%d = mrb_funcall(mrb, mrb_float_value(mrb, %s), \"to_s\", 0);\n", tmp, ie);
                    } else {
                        emit(ctx, "mrb_value _t%d = mrb_funcall(mrb, %s, \"to_s\", 0);\n", tmp, ie);
                    }
                    emit(ctx, "mrb_str_cat_str(mrb, _is%d, _t%d);\n", str_id, tmp);
                    free(ie);
                }
            }
        }
        ctx->indent--;
        emit(ctx, "}\n");
        return str_fmt("_is%d", str_id);
    }

    case PM_TRUE_NODE:  return str_dup("TRUE");
    case PM_FALSE_NODE: return str_dup("FALSE");
    case PM_NIL_NODE:   return str_dup("mrb_nil_value()");

    case PM_LOCAL_VARIABLE_READ_NODE: {
        pm_local_variable_read_node_t *n = (pm_local_variable_read_node_t *)node;
        char *name = cstr(ctx, n->name);
        char *cn = make_cname(name, false);
        free(name);
        return cn;
    }

    case PM_CONSTANT_READ_NODE: {
        pm_constant_read_node_t *n = (pm_constant_read_node_t *)node;
        char *name = cstr(ctx, n->name);
        char *cn = make_cname(name, true);
        free(name);
        return cn;
    }

    case PM_CALL_NODE: {
        pm_call_node_t *call = (pm_call_node_t *)node;
        char *method = cstr(ctx, call->name);

        /* Binary operators with proven numeric types → C operators */
        if (call->receiver && call->arguments &&
            call->arguments->arguments.size == 1) {
            spinel_type_t lt = infer_type(ctx, call->receiver);
            spinel_type_t rt = infer_type(ctx, call->arguments->arguments.nodes[0]);
            spinel_type_t rest = binop_result_type(lt, rt, method);

            const char *c_op = NULL;
            if (strcmp(method, "+") == 0)  c_op = "+";
            if (strcmp(method, "-") == 0)  c_op = "-";
            if (strcmp(method, "*") == 0)  c_op = "*";
            if (strcmp(method, "/") == 0)  c_op = "/";
            if (strcmp(method, "%") == 0)  c_op = "%";
            if (strcmp(method, "<") == 0)  c_op = "<";
            if (strcmp(method, ">") == 0)  c_op = ">";
            if (strcmp(method, "<=") == 0) c_op = "<=";
            if (strcmp(method, ">=") == 0) c_op = ">=";
            if (strcmp(method, "==") == 0) c_op = "==";
            if (strcmp(method, "!=") == 0) c_op = "!=";
            if (strcmp(method, "<<") == 0) c_op = "<<";
            if (strcmp(method, ">>") == 0) c_op = ">>";
            if (strcmp(method, "|") == 0)  c_op = "|";
            if (strcmp(method, "&") == 0)  c_op = "&";
            if (strcmp(method, "^") == 0)  c_op = "^";

            if (c_op &&
                (lt == SPINEL_TYPE_INTEGER || lt == SPINEL_TYPE_FLOAT ||
                 lt == SPINEL_TYPE_BOOLEAN) &&
                (rt == SPINEL_TYPE_INTEGER || rt == SPINEL_TYPE_FLOAT ||
                 rt == SPINEL_TYPE_BOOLEAN)) {
                char *left = codegen_expr(ctx, call->receiver);
                char *right = codegen_expr(ctx, call->arguments->arguments.nodes[0]);

                if (rest == SPINEL_TYPE_FLOAT) {
                    if (lt == SPINEL_TYPE_INTEGER) {
                        char *t = str_fmt("((mrb_float)%s)", left);
                        free(left); left = t;
                    }
                    if (rt == SPINEL_TYPE_INTEGER) {
                        char *t = str_fmt("((mrb_float)%s)", right);
                        free(right); right = t;
                    }
                }

                char *r = str_fmt("(%s %s %s)", left, c_op, right);
                free(left); free(right); free(method);
                return r;
            }
        }

        /* Receiver-less calls (Kernel methods) — in expr context */
        if (!call->receiver) {
            if (call->arguments && call->arguments->arguments.size > 0) {
                char *arg = codegen_expr(ctx, call->arguments->arguments.nodes[0]);
                char *r = str_fmt("mrb_funcall(mrb, mrb_top_self(mrb), \"%s\", 1, %s)",
                                  method, arg);
                free(arg); free(method);
                return r;
            }
            char *r = str_fmt("mrb_funcall(mrb, mrb_top_self(mrb), \"%s\", 0)", method);
            free(method);
            return r;
        }

        /* Method calls — fallback to mrb_funcall */
        {
            spinel_type_t recv_type = infer_type(ctx, call->receiver);
            char *recv_raw = codegen_expr(ctx, call->receiver);
            char *recv_boxed;

            if (recv_type == SPINEL_TYPE_INTEGER)
                recv_boxed = str_fmt("mrb_fixnum_value(%s)", recv_raw);
            else if (recv_type == SPINEL_TYPE_FLOAT)
                recv_boxed = str_fmt("mrb_float_value(mrb, %s)", recv_raw);
            else if (recv_type == SPINEL_TYPE_BOOLEAN)
                recv_boxed = str_fmt("mrb_bool_value(%s)", recv_raw);
            else
                recv_boxed = str_dup(recv_raw);
            free(recv_raw);

            int argc = call->arguments ? (int)call->arguments->arguments.size : 0;
            if (argc == 0) {
                char *r = str_fmt("mrb_funcall(mrb, %s, \"%s\", 0)", recv_boxed, method);
                free(recv_boxed); free(method);
                return r;
            }

            /* Build comma-separated boxed arguments */
            char *args = str_dup("");
            for (int i = 0; i < argc; i++) {
                pm_node_t *a = call->arguments->arguments.nodes[i];
                spinel_type_t at = infer_type(ctx, a);
                char *ar = codegen_expr(ctx, a);
                char *ab;
                if (at == SPINEL_TYPE_INTEGER)
                    ab = str_fmt("mrb_fixnum_value(%s)", ar);
                else if (at == SPINEL_TYPE_FLOAT)
                    ab = str_fmt("mrb_float_value(mrb, %s)", ar);
                else if (at == SPINEL_TYPE_BOOLEAN)
                    ab = str_fmt("mrb_bool_value(%s)", ar);
                else
                    ab = str_dup(ar);
                free(ar);
                char *na = str_fmt("%s, %s", args, ab);
                free(args); free(ab);
                args = na;
            }
            char *r = str_fmt("mrb_funcall(mrb, %s, \"%s\", %d%s)",
                              recv_boxed, method, argc, args);
            free(recv_boxed); free(args); free(method);
            return r;
        }
    }

    case PM_IF_NODE: {
        /* Expression context: ternary */
        pm_if_node_t *n = (pm_if_node_t *)node;
        char *cond = codegen_expr(ctx, n->predicate);
        spinel_type_t ct = infer_type(ctx, n->predicate);

        char *then_e;
        if (n->statements && ((pm_statements_node_t *)n->statements)->body.size > 0)
            then_e = codegen_expr(ctx, ((pm_statements_node_t *)n->statements)->body.nodes[0]);
        else
            then_e = str_dup("mrb_nil_value()");

        char *else_e;
        if (n->subsequent) {
            if (PM_NODE_TYPE(n->subsequent) == PM_ELSE_NODE) {
                pm_else_node_t *el = (pm_else_node_t *)n->subsequent;
                if (el->statements && el->statements->body.size > 0)
                    else_e = codegen_expr(ctx, el->statements->body.nodes[0]);
                else
                    else_e = str_dup("mrb_nil_value()");
            } else {
                else_e = codegen_expr(ctx, (pm_node_t *)n->subsequent);
            }
        } else {
            else_e = str_dup("mrb_nil_value()");
        }

        char *r;
        if (ct == SPINEL_TYPE_BOOLEAN)
            r = str_fmt("(%s ? %s : %s)", cond, then_e, else_e);
        else
            r = str_fmt("(mrb_test(%s) ? %s : %s)", cond, then_e, else_e);
        free(cond); free(then_e); free(else_e);
        return r;
    }

    case PM_PARENTHESES_NODE: {
        pm_parentheses_node_t *n = (pm_parentheses_node_t *)node;
        if (n->body) {
            if (PM_NODE_TYPE(n->body) == PM_STATEMENTS_NODE) {
                pm_statements_node_t *s = (pm_statements_node_t *)n->body;
                if (s->body.size > 0)
                    return codegen_expr(ctx, s->body.nodes[s->body.size - 1]);
            }
            return codegen_expr(ctx, n->body);
        }
        return str_dup("mrb_nil_value()");
    }

    case PM_STATEMENTS_NODE: {
        pm_statements_node_t *s = (pm_statements_node_t *)node;
        if (s->body.size > 0)
            return codegen_expr(ctx, s->body.nodes[s->body.size - 1]);
        return str_dup("mrb_nil_value()");
    }

    default:
        return str_fmt("mrb_nil_value() /* TODO: expr node type %d */",
                        PM_NODE_TYPE(node));
    }
}

/* ------------------------------------------------------------------ */
/* Statement codegen (Pass 2)                                         */
/* ------------------------------------------------------------------ */

/* Detect pattern: print <expr>.chr where <expr> is Integer → putchar */
static bool try_print_chr(codegen_ctx_t *ctx, pm_call_node_t *call) {
    if (!ceq(ctx, call->name, "print")) return false;
    if (!call->arguments || call->arguments->arguments.size != 1) return false;

    pm_node_t *arg = call->arguments->arguments.nodes[0];
    if (PM_NODE_TYPE(arg) != PM_CALL_NODE) return false;

    pm_call_node_t *inner = (pm_call_node_t *)arg;
    if (!ceq(ctx, inner->name, "chr")) return false;
    if (!inner->receiver) return false;
    if (infer_type(ctx, inner->receiver) != SPINEL_TYPE_INTEGER) return false;

    char *ie = codegen_expr(ctx, inner->receiver);
    emit(ctx, "putchar((int)%s);\n", ie);
    free(ie);
    return true;
}

static void codegen_stmt(codegen_ctx_t *ctx, pm_node_t *node) {
    if (!node) return;

    switch (PM_NODE_TYPE(node)) {

    case PM_LOCAL_VARIABLE_WRITE_NODE: {
        pm_local_variable_write_node_t *n = (pm_local_variable_write_node_t *)node;
        char *name = cstr(ctx, n->name);
        char *cn = make_cname(name, false);
        char *val = codegen_expr(ctx, n->value);
        emit(ctx, "%s = %s;\n", cn, val);
        free(name); free(cn); free(val);
        break;
    }

    case PM_LOCAL_VARIABLE_OPERATOR_WRITE_NODE: {
        pm_local_variable_operator_write_node_t *n =
            (pm_local_variable_operator_write_node_t *)node;
        char *name = cstr(ctx, n->name);
        char *cn = make_cname(name, false);
        char *op = cstr(ctx, n->binary_operator);
        char *val = codegen_expr(ctx, n->value);
        emit(ctx, "%s %s= %s;\n", cn, op, val);
        free(name); free(cn); free(op); free(val);
        break;
    }

    case PM_CONSTANT_WRITE_NODE: {
        pm_constant_write_node_t *n = (pm_constant_write_node_t *)node;
        char *name = cstr(ctx, n->name);
        char *cn = make_cname(name, true);
        char *val = codegen_expr(ctx, n->value);
        emit(ctx, "%s = %s;\n", cn, val);
        free(name); free(cn); free(val);
        break;
    }

    case PM_WHILE_NODE: {
        pm_while_node_t *n = (pm_while_node_t *)node;
        char *cond = codegen_expr(ctx, n->predicate);
        spinel_type_t ct = infer_type(ctx, n->predicate);

        if (ct == SPINEL_TYPE_BOOLEAN || ct == SPINEL_TYPE_INTEGER)
            emit(ctx, "while (%s) {\n", cond);
        else
            emit(ctx, "while (mrb_test(%s)) {\n", cond);
        free(cond);

        ctx->indent++;
        ctx->for_depth++;
        if (n->statements) codegen_stmts(ctx, (pm_node_t *)n->statements);
        ctx->for_depth--;
        ctx->indent--;
        emit(ctx, "}\n");
        break;
    }

    case PM_FOR_NODE: {
        pm_for_node_t *n = (pm_for_node_t *)node;
        if (PM_NODE_TYPE(n->collection) == PM_RANGE_NODE &&
            PM_NODE_TYPE(n->index) == PM_LOCAL_VARIABLE_TARGET_NODE) {
            pm_range_node_t *range = (pm_range_node_t *)n->collection;
            pm_local_variable_target_node_t *target =
                (pm_local_variable_target_node_t *)n->index;
            char *vname = cstr(ctx, target->name);
            char *cn = make_cname(vname, false);
            char *start = codegen_expr(ctx, range->left);
            char *end = codegen_expr(ctx, range->right);
            bool exclusive = (PM_NODE_FLAG_P(node, PM_RANGE_FLAGS_EXCLUDE_END) != 0);
            const char *cmp = exclusive ? "<" : "<=";
            emit(ctx, "for (%s = %s; %s %s %s; %s++) {\n",
                 cn, start, cn, cmp, end, cn);
            free(vname); free(cn); free(start); free(end);
            ctx->indent++;
            ctx->for_depth++;
            if (n->statements) codegen_stmts(ctx, (pm_node_t *)n->statements);
            ctx->for_depth--;
            ctx->indent--;
            emit(ctx, "}\n");
        } else {
            emit(ctx, "/* TODO: for with non-range collection */\n");
        }
        break;
    }

    case PM_IF_NODE: {
        pm_if_node_t *n = (pm_if_node_t *)node;
        char *cond = codegen_expr(ctx, n->predicate);
        spinel_type_t ct = infer_type(ctx, n->predicate);

        if (ct == SPINEL_TYPE_BOOLEAN || ct == SPINEL_TYPE_INTEGER || ct == SPINEL_TYPE_FLOAT)
            emit(ctx, "if (%s) {\n", cond);
        else
            emit(ctx, "if (mrb_test(%s)) {\n", cond);
        free(cond);

        ctx->indent++;
        if (n->statements) codegen_stmts(ctx, (pm_node_t *)n->statements);
        ctx->indent--;

        if (n->subsequent) {
            if (PM_NODE_TYPE(n->subsequent) == PM_IF_NODE) {
                pm_if_node_t *ei = (pm_if_node_t *)n->subsequent;
                char *ec = codegen_expr(ctx, ei->predicate);
                spinel_type_t ect = infer_type(ctx, ei->predicate);
                if (ect == SPINEL_TYPE_BOOLEAN || ect == SPINEL_TYPE_INTEGER || ect == SPINEL_TYPE_FLOAT)
                    emit(ctx, "} else if (%s) {\n", ec);
                else
                    emit(ctx, "} else if (mrb_test(%s)) {\n", ec);
                free(ec);
                ctx->indent++;
                if (ei->statements) codegen_stmts(ctx, (pm_node_t *)ei->statements);
                ctx->indent--;
                if (ei->subsequent) {
                    emit(ctx, "} else {\n");
                    ctx->indent++;
                    codegen_stmt(ctx, (pm_node_t *)ei->subsequent);
                    ctx->indent--;
                }
                emit(ctx, "}\n");
            } else if (PM_NODE_TYPE(n->subsequent) == PM_ELSE_NODE) {
                emit(ctx, "} else {\n");
                ctx->indent++;
                pm_else_node_t *el = (pm_else_node_t *)n->subsequent;
                if (el->statements) codegen_stmts(ctx, (pm_node_t *)el->statements);
                ctx->indent--;
                emit(ctx, "}\n");
            } else {
                emit(ctx, "}\n");
            }
        } else {
            emit(ctx, "}\n");
        }
        break;
    }

    case PM_MULTI_WRITE_NODE: {
        pm_multi_write_node_t *n = (pm_multi_write_node_t *)node;
        if (PM_NODE_TYPE(n->value) == PM_ARRAY_NODE) {
            pm_array_node_t *ary = (pm_array_node_t *)n->value;
            size_t count = n->lefts.size < ary->elements.size
                ? n->lefts.size : ary->elements.size;
            emit(ctx, "{\n");
            ctx->indent++;
            for (size_t i = 0; i < count; i++) {
                spinel_type_t rt = infer_type(ctx, ary->elements.nodes[i]);
                char *rhs = codegen_expr(ctx, ary->elements.nodes[i]);
                emit(ctx, "%s _mw_%d = %s;\n", spinel_type_cname(rt), (int)i, rhs);
                free(rhs);
            }
            for (size_t i = 0; i < count; i++) {
                if (PM_NODE_TYPE(n->lefts.nodes[i]) == PM_LOCAL_VARIABLE_TARGET_NODE) {
                    pm_local_variable_target_node_t *target =
                        (pm_local_variable_target_node_t *)n->lefts.nodes[i];
                    char *vname = cstr(ctx, target->name);
                    char *cn = make_cname(vname, false);
                    emit(ctx, "%s = _mw_%d;\n", cn, (int)i);
                    free(vname); free(cn);
                }
            }
            ctx->indent--;
            emit(ctx, "}\n");
        }
        break;
    }

    case PM_BREAK_NODE:
        emit(ctx, "break;\n");
        break;

    case PM_CALL_NODE: {
        pm_call_node_t *call = (pm_call_node_t *)node;

        /* print integer.chr → putchar */
        if (!call->receiver && try_print_chr(ctx, call))
            break;

        char *method = cstr(ctx, call->name);

        /* puts */
        if (!call->receiver && strcmp(method, "puts") == 0) {
            if (call->arguments && call->arguments->arguments.size > 0) {
                pm_node_t *arg = call->arguments->arguments.nodes[0];
                spinel_type_t at = infer_type(ctx, arg);
                char *ae = codegen_expr(ctx, arg);
                if (at == SPINEL_TYPE_STRING) {
                    emit(ctx, "{\n");
                    ctx->indent++;
                    emit(ctx, "mrb_value _s = %s;\n", ae);
                    emit(ctx, "fwrite(RSTRING_PTR(_s), 1, RSTRING_LEN(_s), stdout);\n");
                    emit(ctx, "putchar('\\n');\n");
                    ctx->indent--;
                    emit(ctx, "}\n");
                } else {
                    emit(ctx, "mrb_funcall(mrb, mrb_top_self(mrb), \"puts\", 1, %s);\n", ae);
                }
                free(ae);
            } else {
                emit(ctx, "putchar('\\n');\n");
            }
            free(method);
            break;
        }

        /* print */
        if (!call->receiver && strcmp(method, "print") == 0) {
            if (call->arguments && call->arguments->arguments.size > 0) {
                pm_node_t *arg = call->arguments->arguments.nodes[0];
                spinel_type_t at = infer_type(ctx, arg);
                char *ae = codegen_expr(ctx, arg);
                if (at == SPINEL_TYPE_STRING) {
                    emit(ctx, "{\n");
                    ctx->indent++;
                    emit(ctx, "mrb_value _s = %s;\n", ae);
                    emit(ctx, "fwrite(RSTRING_PTR(_s), 1, RSTRING_LEN(_s), stdout);\n");
                    ctx->indent--;
                    emit(ctx, "}\n");
                } else {
                    emit(ctx, "mrb_funcall(mrb, mrb_top_self(mrb), \"print\", 1, %s);\n", ae);
                }
                free(ae);
            }
            free(method);
            break;
        }

        /* General call as statement */
        {
            char *expr = codegen_expr(ctx, node);
            emit(ctx, "%s;\n", expr);
            free(expr); free(method);
        }
        break;
    }

    case PM_ELSE_NODE: {
        pm_else_node_t *n = (pm_else_node_t *)node;
        if (n->statements) codegen_stmts(ctx, (pm_node_t *)n->statements);
        break;
    }

    default:
        emit(ctx, "/* TODO: stmt node type %d */\n", PM_NODE_TYPE(node));
        break;
    }
}

static void codegen_stmts(codegen_ctx_t *ctx, pm_node_t *node) {
    if (!node) return;
    if (PM_NODE_TYPE(node) == PM_STATEMENTS_NODE) {
        pm_statements_node_t *s = (pm_statements_node_t *)node;
        for (size_t i = 0; i < s->body.size; i++)
            codegen_stmt(ctx, s->body.nodes[i]);
    } else {
        codegen_stmt(ctx, node);
    }
}

/* ------------------------------------------------------------------ */
/* Top-level program generation                                       */
/* ------------------------------------------------------------------ */

static void emit_header(codegen_ctx_t *ctx) {
    emit_raw(ctx, "/* Generated by Spinel AOT compiler */\n");
    emit_raw(ctx, "#include <mruby.h>\n");
    emit_raw(ctx, "#include <mruby/string.h>\n");
    emit_raw(ctx, "#include <mruby/compile.h>\n");
    emit_raw(ctx, "#include <stdio.h>\n\n");
    emit_raw(ctx, "int main(int argc, char **argv) {\n");
    emit_raw(ctx, "    mrb_state *mrb = mrb_open();\n");
    emit_raw(ctx, "    if (!mrb) { fprintf(stderr, \"mrb_open failed\\n\"); return 1; }\n\n");
}

static void emit_var_decls(codegen_ctx_t *ctx) {
    emit_raw(ctx, "    /* Variable declarations */\n");
    for (int i = 0; i < ctx->var_count; i++) {
        var_entry_t *v = &ctx->vars[i];
        const char *ctype = spinel_type_cname(v->type);
        char *cn = make_cname(v->name, v->is_constant);
        const char *init;
        switch (v->type) {
        case SPINEL_TYPE_INTEGER: init = " = 0"; break;
        case SPINEL_TYPE_FLOAT:   init = " = 0.0"; break;
        case SPINEL_TYPE_BOOLEAN: init = " = FALSE"; break;
        default:                  init = " = mrb_nil_value()"; break;
        }
        emit_raw(ctx, "    %s %s%s;\n", ctype, cn, init);
        free(cn);
    }
    emit_raw(ctx, "\n");
}

static void emit_footer(codegen_ctx_t *ctx) {
    emit_raw(ctx, "\n    mrb_close(mrb);\n");
    emit_raw(ctx, "    return 0;\n");
    emit_raw(ctx, "}\n");
}

void codegen_init(codegen_ctx_t *ctx, pm_parser_t *parser, FILE *out) {
    memset(ctx, 0, sizeof(*ctx));
    ctx->parser = parser;
    ctx->out = out;
    ctx->indent = 1;
}

void codegen_program(codegen_ctx_t *ctx, pm_node_t *root) {
    assert(PM_NODE_TYPE(root) == PM_PROGRAM_NODE);
    pm_program_node_t *prog = (pm_program_node_t *)root;

    /* Pass 1: type inference */
    infer_pass(ctx, root);

    /* Emit C file */
    emit_header(ctx);
    emit_var_decls(ctx);
    codegen_stmts(ctx, (pm_node_t *)prog->statements);
    emit_footer(ctx);
}
