assert_agenix_env_files_live() {
    local encrypted_file secret_name secret_path

    for encrypted_file in "${DOTFILES_DIR}/secrets/env"/*.age; do
        [[ -e "${encrypted_file}" ]] || continue
        secret_name="${encrypted_file##*/}"
        secret_name="${secret_name%.age}"

        secret_path="${HOME}/.config/zsh/env/${secret_name}"

        if [[ ! -L "${secret_path}" || ! -f "${secret_path}" ]]; then
            printf 'agenix environment secret is unavailable: %s\n' "${secret_name}" >&2
            return 1
        fi
    done
}
