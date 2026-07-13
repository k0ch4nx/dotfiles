let
  yubikey = "age1yubikey1qv4j58tmzzfvtu03zn0mmfwtp7e9p0324lf0u22hkd6raveqlascczcwtly";
  backup = "age1kleelkfhfkqc2mysqsu0x0e6atczl97xx7mrssvm726qnh8n6p0sdmrj3q";
in
{
  "env/mem0-api-key.age" = {
    publicKeys = [
      yubikey
      backup
    ];
    armor = true;
  };
  "env/skillsmp-api-key.age" = {
    publicKeys = [
      yubikey
      backup
    ];
    armor = true;
  };
  "ssh/id_ed25519.age" = {
    publicKeys = [
      yubikey
      backup
    ];
    armor = true;
  };
  "ssh/id_ed25519_gh_work.age" = {
    publicKeys = [
      yubikey
      backup
    ];
    armor = true;
  };
  "ssh/id_ed25519_sk.age" = {
    publicKeys = [
      yubikey
      backup
    ];
    armor = true;
  };
  "ssh/id_ed25519_sk_gh_auth_pers.age" = {
    publicKeys = [
      yubikey
      backup
    ];
    armor = true;
  };
  "ssh/id_ed25519_sk_gh_sign_pers.age" = {
    publicKeys = [
      yubikey
      backup
    ];
    armor = true;
  };
}
