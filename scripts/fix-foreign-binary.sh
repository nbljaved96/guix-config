#!/usr/bin/env bash

## Example usage
# ./fix-foreign-binary.sh path-to-problematic-executable

#
## Initial Checks
#

if ! command -v gum &>/dev/null; then
  echo 'Install gum using `go install github.com/charmbracelet/gum@latest`' >&2
  exit 1
fi

if ! command -v patchelf &>/dev/null; then
  gum log --structured --level error 'Install patchelf with `guix install patchelf`'
  exit 1
fi

if ! command -v file &>/dev/null; then
  gum log --structured --level error 'Install file with `guix install file`'
  exit 1
fi

gum log --structured --level info "Based on https://zie87.github.io/posts/guix-foreign-binaries/"

if ! [ -e "$1" ]; then
  gum log --structured --level error "'$1' is not a valid path or does not exist."
  exit 1
fi

path=$(realpath "$1")
gum log --structured --level info "Looking at file" file $path

if ! file -b -- "$path" | grep -q "ELF" &> /dev/null; then
    gum log --structured --level error "'$path' is not an ELF executable, nothing to be done. Exiting."
    exit 1
fi

#
## Checking for interpreter problem
#
echo
error_output=$($path 2>&1 > /dev/null)
if [ -n "$error_output" ] ; then
    gum log --structured --level debug "$error_output"
fi
if echo $error_output | grep -iq "No such file or directory"; then
    #gum log --structured --level error "No such file or directory"
    interpreter_path=$(patchelf --print-interpreter "$path")
    gum log --structured --level error "Not found interpreter for our file:" interpreter_path "$interpreter_path"

    echo;
    new_interpreter_path=$(patchelf --print-interpreter "$(realpath "$(which sh)")")
    gum log --structured --level info "Patching new interpreter:" new_interpreter_path "$new_interpreter_path"
    gum spin --spinner dot --title "Patching ..." -- patchelf --set-interpreter "$new_interpreter_path" "$path"
fi

# No interpreter problem now
interpreter_path=$(patchelf --print-interpreter "$path")
gum log --structured --level info "Interpreter is ok:" interpreter_path "$interpreter_path" file "$path"

#
## Fix 'missing' libraries
#
echo
gum log --structured --level info "Checking for missing 'shared library dependencies'"
gum spin --spinner dot --title "Looking..." -- guix shell gcc-toolchain -- ldd --version

not_found_libs=()
while IFS= read -r line; do
    if echo "$line" | grep -iq "not found" &> /dev/null; then
        gum log --structured --level error "$line"
        not_found_libs+=("$line")
    else
        gum log --structured --level debug "$line"
    fi
done < <(guix shell gcc-toolchain -- ldd "$path") # | grep 'not found' | awk '{print $1}')

if [ "${#not_found_libs[@]}" -eq 0 ]; then
    gum log --structured --level info "You are good to go ! "
    exit 0
fi

echo
gum log --structured --level error "Found missing libraries"
choice=$(gum choose \
             --header "Before looking for missing libraries do you want to do update the library database's index ?" \
             {yes,no})
if [ "$choice" == "yes" ]; then
    gum spin --spinner dot --title "Updating..." \
        -- guix locate --update && gum log --structured --level info "Updated database"
fi

for lib in "${not_found_libs[@]}"; do
    lib=$(echo "$lib" | awk '{print $1}')
    gum log --structured --level debug "Finding path of" library "$lib"
    # # Get the first line of guix locate output, extract the path, then get its directory
    libraries=$(guix locate "$lib")
    library=$(echo "$libraries" | gum choose)
    library_search_path=$(echo "$library" | awk '{print $2}' | xargs dirname)
    gum log --structured --level debug "Selected runtime search path: " library_search_path "$library_search_path"

    # # You can now act on $lib_path_dir, e.g., add it to LD_LIBRARY_PATH if needed
    gum log --structured --level debug "Adding search path to file: " library_search_path "$library_search_path" file "$path"
    gum spin --spinner dot --title "Adding..." -- \
        patchelf --add-rpath "$library_search_path" "$path" && \
        gum log --structured --level info "Added search path"

done
