
open Simple_java_syntax
open CustomMaps

(*
 * Print a simple Java programm from Syntax tree
 *)

let indent = ref 0

let inc_indent () =
    indent := !indent + 4

let dec_indent () =
    indent := !indent - 4

let print_indent () =
    print_string (String.make !indent ' ')

let print_info info loc =
    try
        let s = LocMap.find loc info in
        if s = "" then raise Not_found;
        print_indent ();
        Printf.printf "// %s\n" s
    with Not_found -> ()

(*
 * Interpret variable access
 *)
let print_var var = 
    var.s_var_name

(*
 * Interpret unary operators
 *)
let rec print_unary op e = 
    match op with
    | Su_neg -> Printf.sprintf "!%s" (print_expr e)

(*
 * Interpret binary operators
 *)
    and print_binary op a b =
    let compute_op op va vb =
        Printf.sprintf "%s %s %s" va
        (match op with
            | Sb_add -> "+"
            | Sb_sub -> "-"
            | Sb_mul -> "*"
            | Sb_div -> "/"
            | Sb_lt  -> "<"
            | _ -> failwith "Should not happen"
            )
            vb
    in
    match op with
        | Sb_or -> Printf.sprintf "%s || %s" (print_expr a) (print_expr b)
        | _     -> compute_op op (print_expr a) (print_expr b)

(*
 * Interpret expressions
 *)
    and print_expr (expr, ext) = 
        match expr with
        | Se_const (Sc_int e)  -> Printf.sprintf "%s" (Int64.to_string e)
        | Se_const (Sc_bool e) -> Printf.sprintf "%s" (if e then "True" else "False")
        | Se_random (a,b)      -> Printf.sprintf "Support.random(%s,%s)" (Int64.to_string a) (Int64.to_string b) 
        | Se_var var           -> print_var var
        | Se_unary (op, e)     -> print_unary op e
        | Se_binary (op, a, b) -> print_binary op a b

(*
 * Interpret variable assignment
 *)
let print_assign var expr =
    print_indent ();
    Printf.printf "%s = %s;\n" var.s_var_name (print_expr expr)

(* 
 * Interpret conditions
 *)
let rec print_condition info cond blk1 blk2 =
    print_indent ();
    Printf.printf "if(%s){\n" (print_expr cond);
    inc_indent();
    print_block info blk1;
    dec_indent();
    print_indent ();
    Printf.printf "}\n";
    if(blk2 <> []) then
    begin
        print_indent ();
        Printf.printf "else {\n";
        inc_indent();
        print_block info blk2;
        dec_indent();
        print_indent ();
        Printf.printf "}\n"
    end;
    print_newline ()

(*
 * Interpret loops
 *)
and print_loop info cond blk = 
    print_newline ();
    print_indent ();
    Printf.printf "while(%s){\n" (print_expr cond);
    inc_indent();
    print_block info blk;
    dec_indent();
    print_indent ();
    Printf.printf "}\n"

(*
 * Interpret procedure call
 *)
and print_proc proc = 
    print_indent ();
    Printf.printf "%s();\n" proc.s_proc_call_name

(*
 * Interpret assert
 *)
and print_assert expr =
    print_indent();
    Printf.printf "assert (%s);\n" (print_expr expr)

(*
 * Interpret instructions
 *)
and print_command info (cmd, loc) =
    print_info info loc;
    match cmd with
    | Sc_assign (var, expr)    -> print_assign var expr
    | Sc_if (cond, blk1, blk2) -> print_condition info cond blk1 blk2
    | Sc_while (cond, blk)     -> print_loop info cond blk
    | Sc_proc_call proc        -> print_proc proc
    | Sc_assert expr           -> print_assert expr

(*
 * Interpret block of instructions
 *)
and print_block info blk =
    match blk with
    | []            -> ()
    | cmd::q -> print_command info cmd; print_block info q

(*
 * List and initialize variable declaration
 *)
let print_var_decl info (var,init) =
    print_info info var.s_var_extent;
    print_indent ();
    Printf.printf "%s %s%s;\n"
    (match var.s_var_type with
    | St_bool -> "boolean"
    | St_int  -> "int"
    | St_void -> failwith "Should not happend")
    var.s_var_name
    (match init with
    | None -> ""
    | Some e -> Printf.sprintf " = %s" (print_expr e))

(*
 * List and store functions
 *)
let print_proc_decl info className p = 
    print_newline();
    print_indent ();
    Printf.printf "void %s () {\n" p.s_proc_name;
    inc_indent();
    print_block info p.s_proc_body;
    dec_indent();
    print_indent ();
    Printf.printf "}\n\n"

(*
 * Interpret class definitions
 *)
let print_class info c = 
    let rec readClassDeclaration l = match l with
    | []    -> ()
    | h::q  -> (match h with
        | Sd_var v      -> print_var_decl info v
        | Sd_function p -> print_proc_decl info c.s_class_name p
    );
    readClassDeclaration q
    in
    print_indent ();
    Printf.printf "class %s {\n\n" c.s_class_name;
    inc_indent();
    readClassDeclaration c.s_class_body;
    dec_indent();
    print_indent ();
    Printf.printf "}\n\n"


exception Found of s_block

(*
 * Interpret a program
 *)

let print_program_with_prop (p:s_program) info : unit =
    (* Read all declration in the program *)
    let rec readDeclarations l = match l with
    | []   -> ()
    | h::q -> print_class info h; readDeclarations q
    in readDeclarations p;
    print_info info (Localizing.extent_unknown())
    
let print_program (p:s_program) : unit =
    print_program_with_prop p (LocMap.empty)



