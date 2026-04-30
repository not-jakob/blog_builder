main :: () {
    template_file_not_found_error := "Could not find %1 file in template directory. Did you delete it?";

    //
    // HTML vars defined in vars.txt.
    //

    html_vars: , ok: = read_entire_file("in/vars.txt");
    assert(ok, tprint("Could not find %0 file in 'in' directory.", "var.txt"));
    
    html_var_lines := split(html_vars, "\n");
    
    for html_var_lines {
        ok, var, value := split_from_left(it, "=");
        array_add(*html_var_list, .{tprint("\%%0\%" ,var), value});
    }
           
    // 
    // Template files.
    //
    
    header, ok = read_entire_file("in/templates/header.html");
    assert(ok, template_file_not_found_error, "header.html");
        
    head, ok = read_entire_file("in/templates/head.html");
    assert(ok, template_file_not_found_error, "head.html");
    
    footer, ok = read_entire_file("in/templates/footer.html");
    assert(ok, template_file_not_found_error, "footer.html");

    if file_exists("out") then delete_directory("out");
    make_directory_if_it_does_not_exist("out");

    //    
    // List directory.
    //

    list_directory_names : [..] string;
    list_visitor :: (info: *File_Visit_Info, user_data: *[..] string) {
        if info.is_directory {
            array_add(user_data, info.full_name);
        }
    }
    
    visit_files("in/lists", false, *list_directory_names, list_visitor, visit_directories = true, follow_directory_symlinks=false);

    for directory_name: list_directory_names {
        file_names: [..] string;
        list_visitor :: (info: *File_Visit_Info, user_data: *[..] string) {
            array_add(user_data, info.full_name);
        }
        
        visit_files(directory_name, false, *file_names, list_visitor, follow_directory_symlinks=false);
        
        found_links_file := false;
        list_template_string: string;
        links_template_string: string;
        
        list_template_vars: [..] HTMLVar;
        links_template_vars: [..] HTMLVar;
        
        list_var_name: string;
        links_name: string;
        list_title: string;

        _, _, list_folder := split_from_right(directory_name, "/");
        output_path := tprint("out/%1", list_folder);
        make_directory_if_it_does_not_exist(output_path);
        
        // Read variables in list file.
        list_file := tprint("%1/%2", directory_name, "list.html");
        
        ok := file_exists(list_file);
        assert(ok, "Could not find list.html file in '%1' directory.", directory_name);
        
        list_template_string = read_entire_file(list_file);
        
        list_template_vars = , no_formatting_errors, error := read_vars(list_template_string);
        assert(no_formatting_errors, error, list_file);
        
        _, _, list_template_string = split_from_right(list_template_string, "+++");
        
        found_list_name := false;
        found_list_title := false;
        
        for list_template_vars {
            if it.key == "%LIST_VAR%" { list_var_name = it.value; found_list_name = true; }
            if it.key == "%LIST_TITLE%" { list_title = it.value; found_list_title = true; }
        }
        
        assert(found_list_name, "Could not find 'LIST_VAR' in %1", list_file);
        assert(found_list_title, "Could not find 'LIST_TITLE' in %1", list_file);

        // Read variables in links file.
        links_file := tprint("%1/%2", directory_name, "links.html");
        found_links_file = file_exists(links_file);
        
        if found_links_file {        
            links_template_string = read_entire_file(links_file);
            links_template_vars, no_formatting_errors, error = read_vars(links_template_string);
            assert(no_formatting_errors, error, links_file);
            
            _, _, links_template_string = split_from_right(links_template_string, "+++");
            
            found_links_name := false;
            for links_template_vars {
                if it.key == "%LINKS_VAR%" { 
                    links_name = it.value; 
                    found_links_name = true; 
                }
            }
            
            assert(found_links_name, "Could not find LINKS_NAME variable in '%1' file.", links_file);
        }

        sorted_list: [..] SortedItem;
        sorted_links: [..] SortedItem;
        
        for file_names {
            if ends_with(it ,"/list.html") continue;
            if ends_with(it ,"/links.html") continue;

            list_item_string := read_entire_file(it);

            item_vars, no_formatting_error, error := read_vars(list_item_string);
            assert(no_formatting_error, error, it);

            _, _, short_file_name := split_from_right(it, "/");
            _, _, short_directory_name := split_from_right(directory_name, "/");
            
            item_link := tprint("%1/%2", short_directory_name, short_file_name);
            item_link = path_strip_extension(item_link);
            array_add(*item_vars, .{"%ITEM_LINK%", item_link});
            
            _, _, list_item_content := split_from_left(list_item_string, variable_wrapper);

            array_add(*item_vars, .{"%ITEM_CONTENT%", list_item_content});

            found_list_item_name := false;
            date: string;
            item_name: string;
            for item_vars {
                if it.key == "%ITEM_TITLE%" { 
                    found_list_item_name = true; 
                    item_name = it.value; 
                };
                
                if it.key == "%ITEM_DATE%" then date = it.value;
            }

            assert(found_list_item_name, "Could not find 'ITEM_TITLE' in %1", it);

            list_item := replace_vars(list_template_string, item_vars);
            
            date_split := split(date, "/");
            date_in_int: s64;
            if date_split.count == 3 {
                date_ordered := tprint("%3%2%1", date_split[0], date_split[1], date_split[2]);
                date_in_int = string_to_int(date_ordered);
            }
            
            _, _, file_name := split_from_right(it, "/"); 
            
            array_add(*sorted_list, .{item_name, file_name, list_item, date_in_int});

            if found_links_file {
                link_item := replace_vars(links_template_string, item_vars);
                array_add(*sorted_links, .{item_name, file_name, link_item, date_in_int});
            }
        }
        
        generate_var_from_list(sorted_list, list_var_name);
        
        if found_links_file {
            generate_var_from_list(sorted_links, links_name);
        }        

        for sorted_list {
            file_path := tprint("%1/%2", output_path, it.file_name);
            generate_html_page(it.content, list_title, file_path);
        }
    }

    //
    // Root directory.    
    //

    visitor :: (info: *File_Visit_Info, user_data: *[..] string) {
        array_add(user_data, info.full_name);
    }
    
    file_names: [..] string;    
    visit_files("in/root", false, *file_names , visitor, follow_directory_symlinks=false);
    
    root_file_content: [..] string;
    root_file_name:    [..] string;
    
    for file_names {
        s, ok :=  read_entire_file(it);
        assert(ok);
        array_add(*root_file_content, s);
        
        _, _, short_file_name := split_from_right(it, "/"); 
        
        array_add(*root_file_name, short_file_name);
    }
    
    for root_file_name {
        HTML_vars, no_formatting_errors, error := read_vars(root_file_content[it_index]);
        assert(no_formatting_errors, error, it);
        
        found_page_title := false;
        page_title: string;
        for HTML_vars {
            if it.key == "%PAGE_TITLE%" then { page_title = it.value; found_page_title = true; } 
        }
        
        assert(found_page_title, "Didn't find 'PAGE_TITLE' in 'root/%1' file.", it);
        
        _, _, content := split_from_right(root_file_content[it_index], "+++");
        
        generate_html_page(content, page_title, tprint("out/%1", it));
    }
    
    //
    // Other resource files.
    //
    
    array_reset(*file_names);
    directory_names: [..] string;
    
    visit_files("in", false, *file_names, visitor, follow_directory_symlinks=false);
    visit_files("in", false, *directory_names, visitor, visit_files = false, visit_directories = true, follow_directory_symlinks=false);

    for file_names {
        _, _, short_file_name := split_from_right(it, "/"); 
        file_out := tprint("out/%1", short_file_name);
    
        copy_file(it, file_out);
    }
    
    for directory_names {
        _, _, short_file_name:= split_from_right(it, "/"); 
        if short_file_name == "lists" || short_file_name == "templates" || short_file_name == "root" then continue; 
        
        file_out := tprint("out/%1", short_file_name);
        
        copy_directory(it, file_out);
    }
}

replace_vars :: (s: string, vars: [..] HTMLVar) -> string {
    mod_s := copy_string(s);
    for vars {
        mod_s = replace(mod_s, it.key, it.value);
    }
    return mod_s;
}

read_vars :: (s: string) -> [..] HTMLVar, formatting_ok: bool, string {
    html_vars: [..] HTMLVar;
    
    ok, vars_lines, _ := split_from_left(s, variable_wrapper);
    
    if !ok {
        error := tprint("Didn't find separator '%1' for variables in %2 file.", variable_wrapper, "%1");
        return html_vars, ok, error;
    }
    
    vars := split(vars_lines, "\n");
    
    for vars {
        html_var: HTMLVar;
        ok, html_var.key, html_var.value = split_from_left(it, "=");
        
        if html_var.key == "" then continue; 
        html_var.key = tprint("\%%1\%", html_var.key);
        
        array_add(*html_vars, html_var);
    }
    
    return html_vars, true, "";
}

generate_var_from_list :: (list: [..] SortedItem, var_name: string) {
    quick_sort(list, x => -x.date_in_number);
    
    builder: String_Builder;
    init_string_builder(*builder);
    
    for list {
        append(*builder, it.content);
    }
    
    final_items := builder_to_string(*builder);

    array_add(*html_var_list, .{tprint("\%%1\%", var_name), final_items});
}

generate_html_page :: (content: string, page_title: string, file_name: string) {
    if !html_builder.initialized init_string_builder(*html_builder);
    ok, _, short_file_name := split_from_right(file_name, "/");
    short_file_name = path_strip_extension(short_file_name);
    
    append(*html_builder, head);
    append(*html_builder, "\n<body>\n");

    header_cp := copy_string(header);    
    header_cp = replace_vars(header_cp, html_var_list);

    // Search for active header link.
    header_lines := split(header_cp, "\n");

    // Disable <a> tags if the link is the same as the current page.    
    for * header_lines {
        href := tprint(" href=\"/%1\"", short_file_name);
        if contains(it.*, href) {
            it.* = replace(it.*, "a_header", "a_header_active");
            it.* = replace(it.*, href, "");
        }
        
        append(*html_builder, "\n",);  
        append(*html_builder, header_lines[it_index]);  
    }
    
    append(*html_builder, "\n<main>\n");
    
    mod_content := replace_vars(content, html_var_list);

    append(*html_builder, mod_content);
    append(*html_builder, "\n</main>\n\n");
    
    footer = replace_vars(footer, html_var_list);
    append(*html_builder, footer);

    append(*html_builder, "\n\n</body>\n</html>");
    
    final_page := builder_to_string(*html_builder);
    final_page = replace(final_page, "%PAGE_TITLE%", page_title);
    
    write_entire_file(file_name, final_page);
    reset(*html_builder);
}

formatting_error :: "Wrong formatting in file %1. The File has to start with +++";
variable_wrapper :: "+++";

html_builder: String_Builder;
head: string;
header: string;
footer: string;

html_var_list: [..] HTMLVar;
HTMLVar :: struct {
    key: string;
    value: string;
}

SortedItem :: struct {
    title: string;
    file_name: string;
    content: string;
    date_in_number: s64;
}

#import "Sort";
#import "File_Utilities";
#import "Text_File_Handler";
#import "Basic";
#import "File";
#import "String";