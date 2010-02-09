let get_first_line_tokens text =
  let n = String.length text in
  let rec first_line_tokens i =
    if i = n then
      []
    else
      match text.[i] with
        'A'..'Z'|'a'..'z'|'0'..'9'|'_' -> ident_token i (i + 1)
      | ' '|'\t' -> first_line_tokens (i + 1)
      | '\r'|'\n' -> []
      | c -> Printf.sprintf "%c" c::first_line_tokens (i + 1)
  and ident_token start i =
    match if i = n then None else Some text.[i] with
      Some ('A'..'Z'|'a'..'z'|'0'..'9'|'_') -> ident_token start (i + 1)
    | _ -> String.sub text start (i - start)::first_line_tokens i
  in
  first_line_tokens 0

type file_options = {file_opt_annot_char: char; file_opt_tab_size: int}

let get_file_options text =
  let tokens = get_first_line_tokens text in
  let rec iter annotChar tabSize toks =
    match toks with
      "verifast_annotation_char"::":"::c::toks when String.length c = 1 -> iter c.[0] tabSize toks
    | "tab_size"::":"::n::toks ->
      begin
        try
          iter annotChar (int_of_string n) toks
        with Failure "int_of_string" -> iter annotChar tabSize toks
      end
    | tok::toks -> iter annotChar tabSize toks
    | [] -> {file_opt_annot_char=annotChar; file_opt_tab_size=tabSize}
  in
  iter '@' 8 tokens

let readFile chan =
  let count = ref 0 in
  let rec iter () =
    let buf = String.create 60000 in
    let result = input chan buf 0 60000 in
    count := !count + result;
    if result = 0 then [] else (buf, result)::iter()
  in
  let chunks = iter() in
  let s = String.create !count in
  let rec iter2 chunks offset =
    match chunks with
      [] -> ()
    | (buf, size)::chunks ->
      String.blit buf 0 s offset size;
      iter2 chunks (offset + size)
  in
  iter2 chunks 0;
  s

let strip_annotations fin fout =
  let text = readFile fin in
  let n = String.length text in
  let {file_opt_annot_char=annotChar} = get_file_options text in
  let rec iter i0 white i =
    if i = n then
      output fout text i0 (n - i0)
    else
      match text.[i] with
        '/' when i + 3 <= n && (text.[i + 1] = '/' || text.[i + 1] = '*') && text.[i + 2] = annotChar ->
        begin match text.[i + 1] with
          '/' ->
          let after_annot eol j =
            if white > 0 && text.[white - 1] <> '\n' && text.[white - 1] <> '\r' then iter eol eol eol else iter j j j
          in
          let rec eat_annot j =
            if j = n then
              output fout text i0 (white - i0)
            else
              match text.[j] with
                '\r' ->
                let j' =
                  if j + 1 < n && text.[j + 1] = '\n' then j + 2 else j + 1
                in
                output fout text i0 (white - i0);
                after_annot j j'
              | '\n' ->
                output fout text i0 (white - i0);
                after_annot j (j + 1)
              | _ -> eat_annot (j + 1)
          in
          eat_annot (i + 3)
        | '*' ->
          let rec eat_trailing_white_lines j0 =
            let rec iter' j =
              if j = n then
                output fout text i0 (white - i0)
              else
                match text.[j] with
                  ' ' | '\t' -> iter' (j + 1)
                | '\r' | '\n' -> eat_trailing_white_lines (j + 1)
                | _ -> output fout text i0 (white - i0); iter j0 j0 j
            in
            iter' j0
          in
          let rec eat_annot j =
            if j = n then
              output fout text i0 (white - i0)
            else
              match text.[j] with
                c when c = annotChar && j + 3 <= n && text.[j + 1] = '*' && text.[j + 2] = '/' ->
                eat_trailing_white_lines (j + 3)
              | _ -> eat_annot (j + 1)
          in
          eat_annot (i + 3)
        end
      | ' ' | '\t' -> iter i0 white (i + 1)
      | _ -> let i = i + 1 in iter i0 i i
  in
  iter 0 0 0

let () =
  match Sys.argv with
    [| _ |] -> strip_annotations stdin stdout
  | _ ->
    print_endline "vfstrip: Copies stdin to stdout, removing all VeriFast annotations";
    print_endline "Usage: vfstrip < inputfile > outputfile"

