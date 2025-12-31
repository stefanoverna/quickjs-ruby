/*
 * QuickJS Native Ruby Extension
 * High-performance JavaScript sandbox for Ruby
 */

#include <ruby.h>
#include <ruby/encoding.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/time.h>

#include "quickjs.h"
#include "quickjs-libc.h"

// Ruby class references
static VALUE rb_cQuickJS;
static VALUE rb_cSandbox;
static VALUE rb_cResult;
static VALUE rb_eQuickJSSyntaxError;
static VALUE rb_eQuickJSJavascriptError;
static VALUE rb_eQuickJSMemoryLimitError;
static VALUE rb_eQuickJSTimeoutError;
static VALUE rb_eQuickJSHTTPBlockedError;
static VALUE rb_eQuickJSHTTPLimitError;
static VALUE rb_eQuickJSHTTPError;

// Context wrapper structure
typedef struct {
    JSRuntime *rt;
    JSContext *ctx;
    size_t mem_limit;
    int64_t start_time_ms;
    int64_t timeout_ms;
    int timed_out;
    char *console_output;
    size_t console_output_len;
    size_t console_output_capacity;
    size_t console_max_size;
    int console_truncated;
    VALUE rb_http_callback;  // Ruby callback for HTTP requests
    VALUE pending_ruby_exception;  // Ruby exception to re-raise after JS execution
} ContextWrapper;

// Thread-local storage for current wrapper
static __thread ContextWrapper *current_wrapper = NULL;

// Get current time in milliseconds
static int64_t get_time_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (int64_t)ts.tv_sec * 1000 + (ts.tv_nsec / 1000000);
}

// Interrupt handler for timeout
static int interrupt_handler(JSRuntime *rt, void *opaque) {
    ContextWrapper *wrapper = (ContextWrapper *)opaque;

    if (wrapper->timeout_ms > 0) {
        int64_t elapsed = get_time_ms() - wrapper->start_time_ms;
        if (elapsed > wrapper->timeout_ms) {
            wrapper->timed_out = 1;
            return 1;  // Interrupt execution
        }
    }

    return 0;  // Continue execution
}

// Append to console output buffer
static void append_console_output(ContextWrapper *wrapper, const char *str, size_t len) {
    if (!wrapper || !str || len == 0) return;

    // Check if we've already exceeded the limit
    if (wrapper->console_output_len >= wrapper->console_max_size) {
        wrapper->console_truncated = 1;
        return;
    }

    // Calculate how much we can actually append
    size_t available = wrapper->console_max_size - wrapper->console_output_len;
    size_t to_append = len < available ? len : available;

    if (to_append < len) {
        wrapper->console_truncated = 1;
    }

    // Ensure we have enough capacity
    if (wrapper->console_output_len + to_append > wrapper->console_output_capacity) {
        size_t new_capacity = wrapper->console_output_capacity * 2;
        if (new_capacity > wrapper->console_max_size) {
            new_capacity = wrapper->console_max_size;
        }
        if (new_capacity < wrapper->console_output_len + to_append) {
            new_capacity = wrapper->console_output_len + to_append;
        }

        char *new_buffer = realloc(wrapper->console_output, new_capacity + 1);
        if (new_buffer) {
            wrapper->console_output = new_buffer;
            wrapper->console_output_capacity = new_capacity;
        } else {
            return;
        }
    }

    // Append the string
    memcpy(wrapper->console_output + wrapper->console_output_len, str, to_append);
    wrapper->console_output_len += to_append;
    wrapper->console_output[wrapper->console_output_len] = '\0';
}

// console.log() implementation
static JSValue js_console_log(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    ContextWrapper *wrapper = current_wrapper;
    if (!wrapper) return JS_UNDEFINED;

    for (int i = 0; i < argc; i++) {
        if (i > 0) {
            append_console_output(wrapper, " ", 1);
        }

        const char *str = JS_ToCString(ctx, argv[i]);
        if (str) {
            append_console_output(wrapper, str, strlen(str));
            JS_FreeCString(ctx, str);
        }
    }
    append_console_output(wrapper, "\n", 1);

    return JS_UNDEFINED;
}

// Helper struct for protected HTTP callback
struct http_callback_args {
    VALUE callback;
    VALUE method;
    VALUE url;
    VALUE body;
    VALUE headers;
};

// Protected callback function
static VALUE http_callback_wrapper(VALUE arg) {
    struct http_callback_args *args = (struct http_callback_args *)arg;
    return rb_funcall(args->callback, rb_intern("call"), 4,
                      args->method, args->url, args->body, args->headers);
}

// fetch() implementation
static JSValue js_fetch(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    ContextWrapper *wrapper = current_wrapper;
    if (!wrapper) {
        return JS_ThrowTypeError(ctx, "fetch() called outside sandbox context");
    }

    if (wrapper->rb_http_callback == Qnil) {
        return JS_ThrowTypeError(ctx, "fetch() is not enabled - HTTP callback not configured");
    }

    // Parse arguments
    if (argc < 1) {
        return JS_ThrowTypeError(ctx, "fetch() requires at least 1 argument (url)");
    }

    // Get URL
    const char *url = JS_ToCString(ctx, argv[0]);
    if (!url) {
        return JS_ThrowTypeError(ctx, "fetch() url must be a string");
    }

    // Parse options (second argument)
    const char *method_str = NULL;
    const char *body_str = NULL;
    VALUE rb_headers = rb_hash_new();

    if (argc >= 2 && !JS_IsUndefined(argv[1]) && !JS_IsNull(argv[1])) {
        // Get method
        JSValue method_val = JS_GetPropertyStr(ctx, argv[1], "method");
        if (!JS_IsUndefined(method_val) && !JS_IsNull(method_val)) {
            method_str = JS_ToCString(ctx, method_val);
        }
        JS_FreeValue(ctx, method_val);

        // Get body
        JSValue body_val = JS_GetPropertyStr(ctx, argv[1], "body");
        if (!JS_IsUndefined(body_val) && !JS_IsNull(body_val)) {
            body_str = JS_ToCString(ctx, body_val);
        }
        JS_FreeValue(ctx, body_val);
    }

    // Call Ruby HTTP executor with exception protection
    VALUE rb_url = rb_str_new2(url);
    VALUE rb_method = method_str ? rb_str_new2(method_str) : rb_str_new2("GET");
    VALUE rb_body = body_str ? rb_str_new2(body_str) : Qnil;

    struct http_callback_args args = {
        .callback = wrapper->rb_http_callback,
        .method = rb_method,
        .url = rb_url,
        .body = rb_body,
        .headers = rb_headers
    };

    int state = 0;
    VALUE rb_response = rb_protect(http_callback_wrapper, (VALUE)&args, &state);

    // Free C strings
    JS_FreeCString(ctx, url);
    if (method_str) JS_FreeCString(ctx, method_str);
    if (body_str) JS_FreeCString(ctx, body_str);

    // Check if an exception was raised
    if (state) {
        VALUE exception = rb_errinfo();
        rb_set_errinfo(Qnil);  // Clear the error

        // Store the exception to re-raise after JS execution completes
        // We cannot call rb_exc_raise here because it would longjmp
        // out of QuickJS's call stack, leaving objects in an inconsistent state
        wrapper->pending_ruby_exception = exception;

        // Return a JavaScript exception so QuickJS can clean up properly
        return JS_ThrowInternalError(ctx, "HTTP request failed");
    }

    // Extract response fields from Ruby hash
    VALUE rb_status = rb_hash_aref(rb_response, ID2SYM(rb_intern("status")));
    VALUE rb_status_text = rb_hash_aref(rb_response, ID2SYM(rb_intern("statusText")));
    VALUE rb_response_body = rb_hash_aref(rb_response, ID2SYM(rb_intern("body")));

    int status = NIL_P(rb_status) ? 200 : NUM2INT(rb_status);
    const char *status_text = NIL_P(rb_status_text) ? "OK" : StringValueCStr(rb_status_text);
    const char *response_body = NIL_P(rb_response_body) ? "" : StringValueCStr(rb_response_body);

    // Create Response object
    JSValue response_obj = JS_NewObject(ctx);

    // Add properties
    JS_SetPropertyStr(ctx, response_obj, "status", JS_NewInt32(ctx, status));
    JS_SetPropertyStr(ctx, response_obj, "statusText", JS_NewString(ctx, status_text));
    JS_SetPropertyStr(ctx, response_obj, "ok", JS_NewBool(ctx, status >= 200 && status < 300));
    JS_SetPropertyStr(ctx, response_obj, "body", JS_NewString(ctx, response_body));

    // Add headers object
    JSValue headers_obj = JS_NewObject(ctx);
    JS_SetPropertyStr(ctx, response_obj, "headers", headers_obj);

    return response_obj;
}

// Forward declaration
static VALUE js_to_ruby(JSContext *ctx, JSValue val);
static JSValue ruby_to_js(JSContext *ctx, VALUE rb_val);

// Convert JavaScript value to Ruby value
static VALUE js_to_ruby(JSContext *ctx, JSValue val) {
    // Null
    if (JS_IsNull(val)) {
        return Qnil;
    }

    // Undefined
    if (JS_IsUndefined(val)) {
        return Qnil;
    }

    // Boolean
    if (JS_IsBool(val)) {
        return JS_ToBool(ctx, val) ? Qtrue : Qfalse;
    }

    // Number
    if (JS_IsNumber(val)) {
        double d;
        if (JS_ToFloat64(ctx, &d, val) == 0) {
            // Check if it's an integer
            if (d == (int64_t)d && d >= FIXNUM_MIN && d <= FIXNUM_MAX) {
                return LONG2FIX((long)d);
            }
            return DBL2NUM(d);
        }
    }

    // String
    if (JS_IsString(val)) {
        const char *str = JS_ToCString(ctx, val);
        if (str) {
            VALUE rb_str = rb_str_new2(str);
            rb_enc_associate(rb_str, rb_utf8_encoding());
            JS_FreeCString(ctx, str);
            return rb_str;
        }
    }

    // Array
    if (JS_IsArray(ctx, val)) {
        VALUE rb_array = rb_ary_new();
        JSValue len_val = JS_GetPropertyStr(ctx, val, "length");
        uint32_t len = 0;
        JS_ToUint32(ctx, &len, len_val);
        JS_FreeValue(ctx, len_val);

        for (uint32_t i = 0; i < len; i++) {
            JSValue elem = JS_GetPropertyUint32(ctx, val, i);
            VALUE rb_elem = js_to_ruby(ctx, elem);
            rb_ary_push(rb_array, rb_elem);
            JS_FreeValue(ctx, elem);
        }
        return rb_array;
    }

    // Object
    if (JS_IsObject(val)) {
        VALUE rb_hash = rb_hash_new();
        JSPropertyEnum *props;
        uint32_t prop_count;

        if (JS_GetOwnPropertyNames(ctx, &props, &prop_count, val,
                                   JS_GPN_STRING_MASK | JS_GPN_ENUM_ONLY) == 0) {
            for (uint32_t i = 0; i < prop_count; i++) {
                JSAtom atom = props[i].atom;
                const char *key = JS_AtomToCString(ctx, atom);

                if (key) {
                    JSValue prop_val = JS_GetProperty(ctx, val, atom);
                    VALUE rb_val = js_to_ruby(ctx, prop_val);
                    VALUE rb_key = rb_str_new2(key);
                    rb_enc_associate(rb_key, rb_utf8_encoding());
                    rb_hash_aset(rb_hash, rb_key, rb_val);
                    JS_FreeValue(ctx, prop_val);
                    JS_FreeCString(ctx, key);
                }
                JS_FreeAtom(ctx, atom);
            }
            js_free(ctx, props);
        }
        return rb_hash;
    }

    return Qnil;
}

// Helper struct for hash iteration
struct hash_iter_data {
    JSContext *ctx;
    JSValue obj;
    int has_error;
};

// Callback for hash iteration
static int hash_foreach_cb(VALUE key, VALUE val, VALUE arg) {
    struct hash_iter_data *data = (struct hash_iter_data *)arg;

    if (data->has_error) {
        return ST_STOP;
    }

    // Convert key to string (symbols and strings are common)
    const char *key_str;
    VALUE key_str_val;

    if (TYPE(key) == T_SYMBOL) {
        key_str = rb_id2name(SYM2ID(key));
    } else if (TYPE(key) == T_STRING) {
        key_str = StringValueCStr(key);
    } else {
        // Convert other types to string
        key_str_val = rb_funcall(key, rb_intern("to_s"), 0);
        key_str = StringValueCStr(key_str_val);
    }

    // Convert value
    JSValue js_val = ruby_to_js(data->ctx, val);

    if (JS_IsException(js_val)) {
        data->has_error = 1;
        return ST_STOP;
    }

    // Set property
    JS_SetPropertyStr(data->ctx, data->obj, key_str, js_val);

    return ST_CONTINUE;
}

// Convert Ruby value to JavaScript value
static JSValue ruby_to_js(JSContext *ctx, VALUE rb_val) {
    // nil -> null
    if (NIL_P(rb_val)) {
        return JS_NULL;
    }

    // Boolean -> true/false
    if (rb_val == Qtrue) {
        return JS_TRUE;
    }
    if (rb_val == Qfalse) {
        return JS_FALSE;
    }

    // Get Ruby type
    int type = TYPE(rb_val);

    // Integer -> number
    if (type == T_FIXNUM) {
        long val = FIX2LONG(rb_val);
        return JS_NewInt64(ctx, val);
    }

    // Bignum -> number
    if (type == T_BIGNUM) {
        double val = NUM2DBL(rb_val);
        return JS_NewFloat64(ctx, val);
    }

    // Float -> number
    if (type == T_FLOAT) {
        double val = NUM2DBL(rb_val);
        return JS_NewFloat64(ctx, val);
    }

    // String -> string
    if (type == T_STRING) {
        const char *str = StringValueCStr(rb_val);
        return JS_NewString(ctx, str);
    }

    // Symbol -> string
    if (type == T_SYMBOL) {
        const char *str = rb_id2name(SYM2ID(rb_val));
        return JS_NewString(ctx, str);
    }

    // Array -> array
    if (type == T_ARRAY) {
        long len = RARRAY_LEN(rb_val);
        JSValue arr = JS_NewArray(ctx);

        for (long i = 0; i < len; i++) {
            VALUE elem = rb_ary_entry(rb_val, i);
            JSValue js_elem = ruby_to_js(ctx, elem);
            if (JS_IsException(js_elem)) {
                JS_FreeValue(ctx, arr);
                return js_elem;
            }
            JS_SetPropertyUint32(ctx, arr, i, js_elem);
        }

        return arr;
    }

    // Hash -> object
    if (type == T_HASH) {
        JSValue obj = JS_NewObject(ctx);

        struct hash_iter_data data = {
            .ctx = ctx,
            .obj = obj,
            .has_error = 0
        };

        rb_hash_foreach(rb_val, hash_foreach_cb, (VALUE)&data);

        if (data.has_error) {
            JS_FreeValue(ctx, obj);
            return JS_EXCEPTION;
        }

        return obj;
    }

    // Fallback: convert to string
    VALUE str_val = rb_funcall(rb_val, rb_intern("to_s"), 0);
    const char *str = StringValueCStr(str_val);
    return JS_NewString(ctx, str);
}

// Ruby C API helper functions
static void sandbox_free(void *ptr) {
    ContextWrapper *wrapper = (ContextWrapper *)ptr;
    if (wrapper) {
        if (wrapper->ctx) {
            // Free context first
            JS_FreeContext(wrapper->ctx);
            wrapper->ctx = NULL;
        }
        if (wrapper->rt) {
            JS_FreeRuntime(wrapper->rt);
            wrapper->rt = NULL;
        }
        if (wrapper->console_output) {
            free(wrapper->console_output);
            wrapper->console_output = NULL;
        }
        free(wrapper);
    }
}

static size_t sandbox_memsize(const void *ptr) {
    const ContextWrapper *wrapper = (const ContextWrapper *)ptr;
    return sizeof(ContextWrapper) + (wrapper ? wrapper->mem_limit : 0);
}

static const rb_data_type_t sandbox_type = {
    "QuickJS::NativeSandbox",
    {NULL, sandbox_free, sandbox_memsize,},
    NULL, NULL,
    RUBY_TYPED_FREE_IMMEDIATELY,
};

// Allocate function for Ruby object
static VALUE sandbox_alloc(VALUE klass) {
    ContextWrapper *wrapper = malloc(sizeof(ContextWrapper));
    memset(wrapper, 0, sizeof(ContextWrapper));
    return TypedData_Wrap_Struct(klass, &sandbox_type, wrapper);
}

// Initialize sandbox
static VALUE sandbox_initialize(VALUE self, VALUE options) {
    ContextWrapper *wrapper;
    TypedData_Get_Struct(self, ContextWrapper, &sandbox_type, wrapper);

    // Get options
    VALUE rb_mem_limit = rb_hash_aref(options, ID2SYM(rb_intern("memory_limit")));
    VALUE rb_timeout = rb_hash_aref(options, ID2SYM(rb_intern("timeout_ms")));
    VALUE rb_console_max = rb_hash_aref(options, ID2SYM(rb_intern("console_log_max_size")));

    wrapper->mem_limit = NIL_P(rb_mem_limit) ? 1000000 : NUM2SIZET(rb_mem_limit);
    wrapper->timeout_ms = NIL_P(rb_timeout) ? 5000 : NUM2LL(rb_timeout);
    wrapper->console_max_size = NIL_P(rb_console_max) ? 10000 : NUM2SIZET(rb_console_max);
    wrapper->rb_http_callback = Qnil;
    wrapper->pending_ruby_exception = Qnil;

    // Initialize console output buffer
    wrapper->console_output_capacity = 1024;
    wrapper->console_output = malloc(wrapper->console_output_capacity);
    wrapper->console_output[0] = '\0';
    wrapper->console_output_len = 0;
    wrapper->console_truncated = 0;

    // Create runtime
    wrapper->rt = JS_NewRuntime();
    if (!wrapper->rt) {
        rb_raise(rb_eRuntimeError, "Failed to create JavaScript runtime");
    }

    JS_SetInterruptHandler(wrapper->rt, interrupt_handler, wrapper);

    // Create context
    wrapper->ctx = JS_NewContext(wrapper->rt);
    if (!wrapper->ctx) {
        JS_FreeRuntime(wrapper->rt);
        wrapper->rt = NULL;
        rb_raise(rb_eRuntimeError, "Failed to create JavaScript context");
    }

    // Set up console object
    JSValue global = JS_GetGlobalObject(wrapper->ctx);
    JSValue console = JS_NewObject(wrapper->ctx);
    JS_SetPropertyStr(wrapper->ctx, console, "log",
                     JS_NewCFunction(wrapper->ctx, js_console_log, "log", 1));
    JS_SetPropertyStr(wrapper->ctx, console, "error",
                     JS_NewCFunction(wrapper->ctx, js_console_log, "error", 1));
    JS_SetPropertyStr(wrapper->ctx, console, "warn",
                     JS_NewCFunction(wrapper->ctx, js_console_log, "warn", 1));
    JS_SetPropertyStr(wrapper->ctx, global, "console", console);

    // Always add fetch() function to global scope (will error if HTTP not enabled)
    JS_SetPropertyStr(wrapper->ctx, global, "fetch",
                     JS_NewCFunction(wrapper->ctx, js_fetch, "fetch", 2));

    JS_FreeValue(wrapper->ctx, global);

    // Set memory limit AFTER context is created and initialized
    // This ensures QuickJS has enough memory to initialize its internal structures
    JS_SetMemoryLimit(wrapper->rt, wrapper->mem_limit);

    return self;
}

// Evaluate JavaScript code
static VALUE sandbox_eval(VALUE self, VALUE code) {
    ContextWrapper *wrapper;
    TypedData_Get_Struct(self, ContextWrapper, &sandbox_type, wrapper);

    // Reset console output and pending exception
    wrapper->console_output_len = 0;
    wrapper->console_output[0] = '\0';
    wrapper->console_truncated = 0;
    wrapper->timed_out = 0;
    wrapper->pending_ruby_exception = Qnil;

    // Set start time
    wrapper->start_time_ms = get_time_ms();

    // Set current wrapper for console.log
    current_wrapper = wrapper;

    // Evaluate code
    const char *code_str = StringValueCStr(code);
    JSValue result = JS_Eval(wrapper->ctx, code_str, strlen(code_str), "<eval>",
                            JS_EVAL_TYPE_GLOBAL);

    // Clear current wrapper
    current_wrapper = NULL;

    // Prepare console output for all return paths
    VALUE console_output = rb_str_new(wrapper->console_output, wrapper->console_output_len);
    VALUE console_truncated = wrapper->console_truncated ? Qtrue : Qfalse;

    // Check for timeout
    if (wrapper->timed_out) {
        JS_FreeValue(wrapper->ctx, result);
        VALUE argv[3] = {
            rb_str_new2("JavaScript execution timeout exceeded"),
            console_output,
            console_truncated
        };
        rb_exc_raise(rb_class_new_instance(3, argv, rb_eQuickJSTimeoutError));
    }

    // Check for exception
    if (JS_IsException(result)) {
        JSValue exception = JS_GetException(wrapper->ctx);

        // Check if there's a pending Ruby exception (from HTTP callback)
        // This must be re-raised AFTER QuickJS has cleaned up
        if (wrapper->pending_ruby_exception != Qnil) {
            VALUE pending = wrapper->pending_ruby_exception;
            wrapper->pending_ruby_exception = Qnil;

            // Free the JS exception and run GC to clean up
            JS_FreeValue(wrapper->ctx, exception);
            JS_RunGC(wrapper->rt);

            // Now re-raise the Ruby exception with console output
            VALUE exc_class = rb_obj_class(pending);
            VALUE message = rb_funcall(pending, rb_intern("message"), 0);

            // Check if this is one of our HTTP error classes
            if (exc_class == rb_eQuickJSHTTPBlockedError ||
                exc_class == rb_eQuickJSHTTPLimitError ||
                exc_class == rb_eQuickJSHTTPError) {
                // Create new exception with console output
                VALUE argv[3] = { message, console_output, console_truncated };
                VALUE new_exception = rb_class_new_instance(3, argv, exc_class);
                rb_exc_raise(new_exception);
            } else {
                // Re-raise original exception
                rb_exc_raise(pending);
            }
        }

        // Regular JavaScript exception handling
        // Try to get error message - QuickJS provides js_error_to_string
        const char *exception_str = JS_ToCString(wrapper->ctx, exception);

        VALUE rb_message;
        VALUE rb_stack;
        int is_syntax = 0;

        if (exception_str) {
            // Check if it's a syntax error
            is_syntax = (strncmp(exception_str, "SyntaxError", 11) == 0);
            rb_message = rb_str_new2(exception_str);
            rb_stack = rb_str_new2("");  // Will try to get stack separately
            JS_FreeCString(wrapper->ctx, exception_str);
        } else {
            rb_message = rb_str_new2("Unknown JavaScript error");
            rb_stack = rb_str_new2("");
        }

        // Try to get stack trace if available
        if (JS_IsObject(exception)) {
            JSValue stack_val = JS_GetPropertyStr(wrapper->ctx, exception, "stack");
            if (!JS_IsUndefined(stack_val) && !JS_IsNull(stack_val)) {
                const char *stack = JS_ToCString(wrapper->ctx, stack_val);
                if (stack) {
                    rb_stack = rb_str_new2(stack);
                    JS_FreeCString(wrapper->ctx, stack);
                }
            }
            JS_FreeValue(wrapper->ctx, stack_val);
        }

        JS_FreeValue(wrapper->ctx, exception);

        if (is_syntax) {
            VALUE argv[4] = { rb_message, rb_stack, console_output, console_truncated };
            rb_exc_raise(rb_class_new_instance(4, argv, rb_eQuickJSSyntaxError));
        } else {
            VALUE argv[4] = { rb_message, rb_stack, console_output, console_truncated };
            rb_exc_raise(rb_class_new_instance(4, argv, rb_eQuickJSJavascriptError));
        }
    }

    // Convert result to Ruby
    VALUE rb_result = js_to_ruby(wrapper->ctx, result);
    JS_FreeValue(wrapper->ctx, result);

    // Run garbage collection to clean up any temporary objects created during evaluation
    // This is especially important for fetch() responses and other complex objects
    JS_RunGC(wrapper->rt);

    // Return Result object
    VALUE rb_http_requests = rb_ary_new();  // Empty array for HTTP requests (tracked by Ruby layer)
    VALUE argv[4] = { rb_result, console_output, console_truncated, rb_http_requests };
    return rb_class_new_instance(4, argv, rb_cResult);
}

// Set a global variable
static VALUE sandbox_set_variable(VALUE self, VALUE name, VALUE value) {
    ContextWrapper *wrapper;
    TypedData_Get_Struct(self, ContextWrapper, &sandbox_type, wrapper);

    const char *var_name = StringValueCStr(name);

    // Validate variable name is not empty
    if (var_name == NULL || strlen(var_name) == 0) {
        rb_raise(rb_eArgError, "Variable name cannot be empty");
    }

    JSValue global = JS_GetGlobalObject(wrapper->ctx);
    JSValue js_val = ruby_to_js(wrapper->ctx, value);

    JS_SetPropertyStr(wrapper->ctx, global, var_name, js_val);
    JS_FreeValue(wrapper->ctx, global);

    return Qnil;
}

// Set HTTP callback
static VALUE sandbox_set_http_callback(VALUE self, VALUE callback) {
    ContextWrapper *wrapper;
    TypedData_Get_Struct(self, ContextWrapper, &sandbox_type, wrapper);

    wrapper->rb_http_callback = callback;

    return Qnil;
}

// Module initialization
void Init_quickjs_native(void) {
    // Get reference to QuickJS module (should already exist from Ruby files)
    rb_cQuickJS = rb_const_get(rb_cObject, rb_intern("QuickJS"));

    // Define NativeSandbox class
    rb_cSandbox = rb_define_class_under(rb_cQuickJS, "NativeSandbox", rb_cObject);
    rb_define_alloc_func(rb_cSandbox, sandbox_alloc);
    rb_define_method(rb_cSandbox, "initialize", sandbox_initialize, 1);
    rb_define_method(rb_cSandbox, "eval", sandbox_eval, 1);
    rb_define_method(rb_cSandbox, "set_variable", sandbox_set_variable, 2);
    rb_define_method(rb_cSandbox, "http_callback=", sandbox_set_http_callback, 1);

    // Get reference to Result class (defined in result.rb)
    rb_cResult = rb_const_get(rb_cQuickJS, rb_intern("Result"));

    // Get references to error classes (defined in errors.rb)
    rb_eQuickJSSyntaxError = rb_const_get(rb_cQuickJS, rb_intern("SyntaxError"));
    rb_eQuickJSJavascriptError = rb_const_get(rb_cQuickJS, rb_intern("JavascriptError"));
    rb_eQuickJSMemoryLimitError = rb_const_get(rb_cQuickJS, rb_intern("MemoryLimitError"));
    rb_eQuickJSTimeoutError = rb_const_get(rb_cQuickJS, rb_intern("TimeoutError"));
    rb_eQuickJSHTTPBlockedError = rb_const_get(rb_cQuickJS, rb_intern("HTTPBlockedError"));
    rb_eQuickJSHTTPLimitError = rb_const_get(rb_cQuickJS, rb_intern("HTTPLimitError"));
    rb_eQuickJSHTTPError = rb_const_get(rb_cQuickJS, rb_intern("HTTPError"));
}
